package com.zarz.spotiflac

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import gobackend.Gobackend
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.Locale

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.zarz.spotiflac/backend"
    private val DOWNLOAD_PROGRESS_STREAM_CHANNEL =
        "com.zarz.spotiflac/download_progress_stream"
    private val LIBRARY_SCAN_PROGRESS_STREAM_CHANNEL =
        "com.zarz.spotiflac/library_scan_progress_stream"
    private val DOWNLOAD_PROGRESS_STREAM_POLLING_INTERVAL_MS = 1200L
    private val LIBRARY_SCAN_PROGRESS_STREAM_POLLING_INTERVAL_MS = 200L
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var pendingSafTreeResult: MethodChannel.Result? = null
    private val safScanLock = Any()
    private val safDirLock = Any()
    private var safScanProgress = SafScanProgress()
    private var downloadProgressStreamJob: Job? = null
    private var downloadProgressEventSink: EventChannel.EventSink? = null
    private var lastDownloadProgressPayload: String? = null
    private var libraryScanProgressStreamJob: Job? = null
    private var libraryScanProgressEventSink: EventChannel.EventSink? = null
    private var lastLibraryScanProgressPayload: String? = null
    private var flutterBackCallback: OnBackPressedCallback? = null
    @Volatile private var safScanCancel = false
    @Volatile private var safScanActive = false
    /** Tri-state: null = untested, true = works, false = fails (Samsung SELinux). */
    @Volatile private var procSelfFdReadable: Boolean? = null
    private val safTreeLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { activityResult ->
        val result = pendingSafTreeResult ?: return@registerForActivityResult
        pendingSafTreeResult = null

        if (activityResult.resultCode != Activity.RESULT_OK) {
            result.success(null)
            return@registerForActivityResult
        }

        val data = activityResult.data
        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return@registerForActivityResult
        }

        val takeFlags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            contentResolver.takePersistableUriPermission(uri, takeFlags)
        } catch (e: Exception) {
            android.util.Log.w("SpotiFLAC", "Failed to persist SAF permission: ${e.message}")
        }

        val payload = JSONObject()
        payload.put("tree_uri", uri.toString())
        payload.put("display_name", resolveSafDisplayPath(uri))
        result.success(payload.toString())
    }

    /**
     * Resolve a SAF tree URI to a human-readable path.
     * e.g. "content://...tree/primary%3AMusic" -> "/storage/emulated/0/Music"
     *      "content://...tree/1234-5678%3AMusic" -> "SD Card/Music"
     */
    private fun resolveSafDisplayPath(treeUri: Uri): String {
        try {
            val docId = android.provider.DocumentsContract.getTreeDocumentId(treeUri)
            if (docId.isNullOrEmpty()) return treeUri.toString()

            val parts = docId.split(":", limit = 2)
            val storageId = parts.getOrNull(0) ?: return docId
            val subPath = parts.getOrNull(1) ?: ""

            val prefix = if (storageId == "primary") {
                "/storage/emulated/0"
            } else {
                "SD Card"
            }

            return if (subPath.isEmpty()) prefix else "$prefix/$subPath"
        } catch (e: Exception) {
            android.util.Log.w("SpotiFLAC", "Failed to resolve SAF display path: ${e.message}")
            return treeUri.toString()
        }
    }

    private fun buildStableLibraryId(filePath: String): String {
        val digest = MessageDigest.getInstance("SHA-1")
        val bytes = digest.digest(filePath.toByteArray(Charsets.UTF_8))
        val hex = bytes.joinToString("") { "%02x".format(it) }
        return "lib_$hex"
    }

    data class SafScanProgress(
        var totalFiles: Int = 0,
        var scannedFiles: Int = 0,
        var currentFile: String = "",
        var errorCount: Int = 0,
        var progressPct: Double = 0.0,
        var isComplete: Boolean = false,
    )

    companion object {
        private const val SAFE_API_FOR_IMPELLER = 29

        private val PROBLEMATIC_GPU_PATTERNS = listOf(
            "adreno (tm) 3",
            "adreno (tm) 4",
            "mali-4",
            "mali-t6",
            "mali-t7",
            "powervr sgx",
            "powervr ge8320",
            "gc1000",
            "gc2000",
        )

        private val PROBLEMATIC_CHIPSETS = listOf(
            "mt6762",
            "mt6765",
            "mt8768",
            "mp0873",
            "msm8974",
            "msm8226",
            "msm8926",
            "apq8084",
        )

        private val PROBLEMATIC_MODELS = listOf(
            "sm-t220",
            "sm-t225",
            "hammerhead",
        )
        private fun shouldDisableImpeller(): Boolean {
            val hardware = Build.HARDWARE.lowercase(Locale.ROOT)
            val board = Build.BOARD.lowercase(Locale.ROOT)
            val model = Build.MODEL.lowercase(Locale.ROOT)
            val device = Build.DEVICE.lowercase(Locale.ROOT)

            for (problematicModel in PROBLEMATIC_MODELS) {
                if (model.contains(problematicModel) || device.contains(problematicModel)) {
                    android.util.Log.i("SpotiFLAC", "Matched problematic model: $problematicModel")
                    return true
                }
            }

            for (chipset in PROBLEMATIC_CHIPSETS) {
                if (hardware.contains(chipset) || board.contains(chipset)) {
                    android.util.Log.i("SpotiFLAC", "Matched problematic chipset: $chipset")
                    return true
                }
            }

            if (Build.VERSION.SDK_INT < SAFE_API_FOR_IMPELLER) {
                val gpuRenderer = getGpuRenderer().lowercase(Locale.ROOT)

                for (pattern in PROBLEMATIC_GPU_PATTERNS) {
                    if (gpuRenderer.contains(pattern)) {
                        android.util.Log.i("SpotiFLAC", "Matched problematic GPU on old Android: $pattern")
                        return true
                    }
                }

                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    android.util.Log.i("SpotiFLAC", "Android < 8.0, using Skia for safety")
                    return true
                }
            }

            val gpuRenderer = getGpuRenderer().lowercase(Locale.ROOT)
            for (pattern in PROBLEMATIC_GPU_PATTERNS) {
                if (gpuRenderer.contains(pattern)) {
                    android.util.Log.i("SpotiFLAC", "Matched problematic GPU: $pattern")
                    return true
                }
            }

            return false
        }

    /**
     * Note: This may return empty on some devices before OpenGL context is created.
     */
        private fun getGpuRenderer(): String {
            return try {
                android.opengl.GLES20.glGetString(android.opengl.GLES20.GL_RENDERER) ?: ""
            } catch (e: Exception) {
                ""
            }
        }
    }

    class ImpellerAwareFlutterFragment : FlutterFragment() {
        override fun getFlutterShellArgs(): FlutterShellArgs {
            val args = super.getFlutterShellArgs()
            if (shouldDisableImpeller()) {
                android.util.Log.w("SpotiFLAC", "Legacy/problematic GPU detected for ${Build.MODEL}")
                android.util.Log.w("SpotiFLAC", "Device: ${Build.MANUFACTURER} ${Build.MODEL}, SDK: ${Build.VERSION.SDK_INT}")
                android.util.Log.w("SpotiFLAC", "Hardware: ${Build.HARDWARE}, Board: ${Build.BOARD}")
                args.add("--enable-impeller=false")
            } else {
                android.util.Log.i("SpotiFLAC", "Using Impeller renderer for ${Build.MODEL}")
            }
            return args
        }
    }

    override fun createFlutterFragment(): FlutterFragment {
        val backgroundMode = getBackgroundMode()
        val renderMode = getRenderMode()
        val transparencyMode =
            if (backgroundMode == BackgroundMode.opaque) TransparencyMode.opaque else TransparencyMode.transparent
        val shouldDelayFirstAndroidViewDraw = renderMode == RenderMode.surface

        getCachedEngineId()?.let { cachedEngineId ->
            return FlutterFragment.CachedEngineFragmentBuilder(
                ImpellerAwareFlutterFragment::class.java,
                cachedEngineId
            )
                .renderMode(renderMode)
                .transparencyMode(transparencyMode)
                .handleDeeplinking(shouldHandleDeeplinking())
                .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
                .destroyEngineWithFragment(shouldDestroyEngineWithHost())
                .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
                .shouldAutomaticallyHandleOnBackPressed(true)
                .build()
        }

        getCachedEngineGroupId()?.let { cachedEngineGroupId ->
            return FlutterFragment.NewEngineInGroupFragmentBuilder(
                ImpellerAwareFlutterFragment::class.java,
                cachedEngineGroupId
            )
                .dartEntrypoint(getDartEntrypointFunctionName())
                .initialRoute(getInitialRoute())
                .handleDeeplinking(shouldHandleDeeplinking())
                .renderMode(renderMode)
                .transparencyMode(transparencyMode)
                .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
                .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
                .shouldAutomaticallyHandleOnBackPressed(true)
                .build()
        }

        return FlutterFragment.NewEngineFragmentBuilder(ImpellerAwareFlutterFragment::class.java)
            .dartEntrypoint(getDartEntrypointFunctionName())
            .dartLibraryUri(getDartEntrypointLibraryUri() ?: "")
            .dartEntrypointArgs(getDartEntrypointArgs() ?: emptyList())
            .initialRoute(getInitialRoute())
            .appBundlePath(getAppBundlePath())
            .flutterShellArgs(FlutterShellArgs.fromIntent(intent))
            .handleDeeplinking(shouldHandleDeeplinking())
            .renderMode(renderMode)
            .transparencyMode(transparencyMode)
            .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
            .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
            .shouldAutomaticallyHandleOnBackPressed(true)
            .build()
    }

    private fun normalizeExt(ext: String?): String {
        if (ext.isNullOrBlank()) return ""
        return if (ext.startsWith(".")) ext.lowercase(Locale.ROOT) else ".${ext.lowercase(Locale.ROOT)}"
    }

    private fun mimeTypeForExt(ext: String?): String {
        return when (normalizeExt(ext)) {
            ".m4a" -> "audio/mp4"
            ".mp3" -> "audio/mpeg"
            ".opus" -> "audio/ogg"
            ".flac" -> "audio/flac"
            ".lrc" -> "application/octet-stream"
            else -> "application/octet-stream"
        }
    }

    private fun sanitizeFilename(name: String): String {
        var sanitized = name
            .replace("/", " ")
            .replace(Regex("[\\\\:*?\"<>|]"), " ")
            .filter { ch ->
                val code = ch.code
                !((code < 0x20 && ch != '\t' && ch != '\n' && ch != '\r') ||
                    code == 0x7F ||
                    (Character.isISOControl(ch) && ch != '\t' && ch != '\n' && ch != '\r'))
            }
            .trim()
            .trim('.', ' ')

        sanitized = sanitized
            .replace(Regex("\\s+"), " ")
            .replace(Regex("_+"), "_")
            .trim('_', ' ')

        return if (sanitized.isBlank()) "Unknown" else sanitized
    }

    private fun sanitizeRelativeDir(relativeDir: String): String {
        if (relativeDir.isBlank()) return ""
        return relativeDir
            .split("/")
            .map { sanitizeFilename(it) }
            .filter { it.isNotBlank() && it != "." && it != ".." }
            .joinToString("/")
    }

    private fun ensureDocumentDir(treeUri: Uri, relativeDir: String): DocumentFile? {
        val safeRelativeDir = sanitizeRelativeDir(relativeDir)
        if (safeRelativeDir.isBlank()) {
            return DocumentFile.fromTreeUri(this, treeUri)
        }

        // Synchronize to prevent concurrent downloads from creating duplicate
        // directories with (1), (2) suffixes via SAF's auto-rename behavior.
        synchronized(safDirLock) {
            var current = DocumentFile.fromTreeUri(this, treeUri) ?: return null

            val parts = safeRelativeDir.split("/").filter { it.isNotBlank() }
            for (part in parts) {
                val existing = current.findFile(part)
                current = if (existing != null && existing.isDirectory) {
                    existing
                } else {
                    val created = current.createDirectory(part) ?: return null
                    // SAF may auto-rename to "part (1)" if another thread just created it.
                    // Re-check: if the created name differs, delete it and use the original.
                    val createdName = created.name ?: part
                    if (createdName != part) {
                        // Another thread won the race; delete the duplicate and use theirs.
                        created.delete()
                        current.findFile(part) ?: return null
                    } else {
                        created
                    }
                }
            }
            return current
        }
    }

    private fun findDocumentDir(treeUri: Uri, relativeDir: String): DocumentFile? {
        var current = DocumentFile.fromTreeUri(this, treeUri) ?: return null
        val safeRelativeDir = sanitizeRelativeDir(relativeDir)
        if (safeRelativeDir.isBlank()) return current

        val parts = safeRelativeDir.split("/").filter { it.isNotBlank() }
        for (part in parts) {
            val existing = current.findFile(part)
            if (existing == null || !existing.isDirectory) return null
            current = existing
        }
        return current
    }

    private fun resetSafScanProgress() {
        synchronized(safScanLock) {
            safScanProgress = SafScanProgress()
        }
        // Allow re-probing /proc/self/fd readability on every new scan session.
        procSelfFdReadable = null
    }

    private fun updateSafScanProgress(block: (SafScanProgress) -> Unit) {
        synchronized(safScanLock) {
            block(safScanProgress)
        }
    }

    private fun safProgressToJson(): String {
        val snapshot = synchronized(safScanLock) { safScanProgress.copy() }
        val obj = JSONObject()
        obj.put("total_files", snapshot.totalFiles)
        obj.put("scanned_files", snapshot.scannedFiles)
        obj.put("current_file", snapshot.currentFile)
        obj.put("error_count", snapshot.errorCount)
        obj.put("progress_pct", snapshot.progressPct)
        obj.put("is_complete", snapshot.isComplete)
        return obj.toString()
    }

    private fun readLibraryScanProgressJsonForStream(): String {
        return if (safScanActive) {
            safProgressToJson()
        } else {
            Gobackend.getLibraryScanProgressJSON()
        }
    }

    private fun parseJsonValue(value: Any?): Any? {
        return when (value) {
            null, JSONObject.NULL -> null
            is JSONObject -> {
                val map = LinkedHashMap<String, Any?>()
                val keys = value.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    map[key] = parseJsonValue(value.opt(key))
                }
                map
            }
            is JSONArray -> {
                val list = ArrayList<Any?>()
                for (i in 0 until value.length()) {
                    list.add(parseJsonValue(value.opt(i)))
                }
                list
            }
            is Number, is Boolean, is String -> value
            else -> value.toString()
        }
    }

    private fun parseJsonPayload(payload: String): Any {
        return try {
            parseJsonValue(JSONTokener(payload).nextValue()) ?: payload
        } catch (_: Exception) {
            payload
        }
    }

    private fun startDownloadProgressStream(sink: EventChannel.EventSink) {
        stopDownloadProgressStream()
        downloadProgressEventSink = sink
        lastDownloadProgressPayload = null
        downloadProgressStreamJob = scope.launch {
            while (isActive && downloadProgressEventSink === sink) {
                try {
                    val payload = withContext(Dispatchers.IO) {
                        Gobackend.getAllDownloadProgress()
                    }
                    if (payload != lastDownloadProgressPayload) {
                        lastDownloadProgressPayload = payload
                        sink.success(parseJsonPayload(payload))
                    }
                } catch (e: Exception) {
                    android.util.Log.w(
                        "SpotiFLAC",
                        "Download progress stream poll failed: ${e.message}",
                    )
                }
                delay(DOWNLOAD_PROGRESS_STREAM_POLLING_INTERVAL_MS)
            }
        }
    }

    private fun stopDownloadProgressStream() {
        downloadProgressStreamJob?.cancel()
        downloadProgressStreamJob = null
        downloadProgressEventSink = null
        lastDownloadProgressPayload = null
    }

    private fun startLibraryScanProgressStream(sink: EventChannel.EventSink) {
        stopLibraryScanProgressStream()
        libraryScanProgressEventSink = sink
        lastLibraryScanProgressPayload = null
        libraryScanProgressStreamJob = scope.launch {
            try {
                val initialPayload = withContext(Dispatchers.IO) {
                    readLibraryScanProgressJsonForStream()
                }
                lastLibraryScanProgressPayload = initialPayload
                sink.success(parseJsonPayload(initialPayload))
            } catch (e: Exception) {
                android.util.Log.w(
                    "SpotiFLAC",
                    "Library scan progress initial poll failed: ${e.message}",
                )
            }
            while (isActive && libraryScanProgressEventSink === sink) {
                try {
                    val payload = withContext(Dispatchers.IO) {
                        readLibraryScanProgressJsonForStream()
                    }
                    if (payload != lastLibraryScanProgressPayload) {
                        lastLibraryScanProgressPayload = payload
                        sink.success(parseJsonPayload(payload))
                    }
                } catch (e: Exception) {
                    android.util.Log.w(
                        "SpotiFLAC",
                        "Library scan progress stream poll failed: ${e.message}",
                    )
                }
                delay(LIBRARY_SCAN_PROGRESS_STREAM_POLLING_INTERVAL_MS)
            }
        }
    }

    private fun stopLibraryScanProgressStream() {
        libraryScanProgressStreamJob?.cancel()
        libraryScanProgressStreamJob = null
        libraryScanProgressEventSink = null
        lastLibraryScanProgressPayload = null
    }

    private fun loadExistingFilesJsonFromSnapshot(snapshotPath: String): String {
        if (snapshotPath.isBlank()) {
            return "{}"
        }

        val snapshotFile = File(snapshotPath)
        if (!snapshotFile.exists()) {
            return "{}"
        }

        val result = JSONObject()
        snapshotFile.forEachLine { line ->
            if (line.isBlank()) return@forEachLine
            val separatorIndex = line.indexOf('\t')
            if (separatorIndex <= 0 || separatorIndex >= line.length - 1) {
                return@forEachLine
            }
            val modTime = line.substring(0, separatorIndex).toLongOrNull() ?: 0L
            val filePath = line.substring(separatorIndex + 1)
            if (filePath.isNotEmpty()) {
                result.put(filePath, modTime)
            }
        }
        return result.toString()
    }

    private fun resolveSafFile(treeUriStr: String, relativeDir: String, fileName: String): String {
        val obj = JSONObject()
        if (treeUriStr.isBlank() || fileName.isBlank()) {
            obj.put("uri", "")
            obj.put("relative_dir", "")
            return obj.toString()
        }
        val safeRelativeDir = sanitizeRelativeDir(relativeDir)
        val safeFileName = sanitizeFilename(fileName)
        if (safeFileName.isBlank()) {
            obj.put("uri", "")
            obj.put("relative_dir", "")
            return obj.toString()
        }

        val treeUri = Uri.parse(treeUriStr)
        val targetDir = findDocumentDir(treeUri, safeRelativeDir)
        if (targetDir != null) {
            val direct = targetDir.findFile(safeFileName)
            if (direct != null && direct.isFile) {
                obj.put("uri", direct.uri.toString())
                obj.put("relative_dir", safeRelativeDir)
                return obj.toString()
            }
        }

        val root = DocumentFile.fromTreeUri(this, treeUri) ?: run {
            obj.put("uri", "")
            obj.put("relative_dir", "")
            return obj.toString()
        }

        val queue: ArrayDeque<Pair<DocumentFile, String>> = ArrayDeque()
        queue.add(root to "")
        var visited = 0
        val maxVisited = 20000

        while (queue.isNotEmpty()) {
            if (visited > maxVisited) break
            val (dir, path) = queue.removeFirst()
            for (child in dir.listFiles()) {
                visited++
                if (child.isDirectory) {
                    val childName = child.name ?: continue
                    val childPath = if (path.isBlank()) childName else "$path/$childName"
                    queue.add(child to childPath)
                } else if (child.isFile) {
                    if (child.name == safeFileName) {
                        obj.put("uri", child.uri.toString())
                        obj.put("relative_dir", path)
                        return obj.toString()
                    }
                }
            }
        }

        obj.put("uri", "")
        obj.put("relative_dir", "")
        return obj.toString()
    }

    private fun buildSafFileName(req: JSONObject, outputExt: String): String {
        val provided = req.optString("saf_file_name", "")
        if (provided.isNotBlank()) return sanitizeFilename(provided)

        val trackName = req.optString("track_name", "track")
        val artistName = req.optString("artist_name", "")
        val baseName = if (artistName.isNotBlank()) "$artistName - $trackName" else trackName
        return sanitizeFilename(baseName) + outputExt
    }

    private fun errorJson(message: String): String {
        val obj = JSONObject()
        obj.put("success", false)
        obj.put("error", message)
        obj.put("message", message)
        return obj.toString()
    }

    /**
     * Detect whether a content URI belongs to the MediaStore provider.
     * Samsung One UI may return MediaStore URIs from SAF tree traversal,
     * which require READ_MEDIA_AUDIO / READ_EXTERNAL_STORAGE permission
     * instead of SAF tree permission.
     */
    private fun isMediaStoreUri(uri: Uri): Boolean {
        val authority = uri.authority ?: return false
        return authority == "media" ||
               authority.startsWith("media.") ||
               authority.contains("media")
    }

    /**
     * Resolve extension from a MediaStore URI by querying DISPLAY_NAME or MIME_TYPE.
     */
    private fun resolveMediaStoreExt(uri: Uri, fallbackExt: String?): String {
        try {
            contentResolver.query(uri, arrayOf(android.provider.MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val name = cursor.getString(0)?.lowercase(Locale.ROOT) ?: ""
                    val ext = extFromFileName(name)
                    if (ext.isNotBlank()) return ext
                }
            }
        } catch (_: Exception) {}

        try {
            val mime = contentResolver.getType(uri)
            val ext = extFromMimeType(mime)
            if (ext.isNotBlank()) return ext
        } catch (_: Exception) {}

        return fallbackExt ?: ""
    }

    private fun extFromFileName(name: String): String {
        return when {
            name.endsWith(".m4a") -> ".m4a"
            name.endsWith(".mp3") -> ".mp3"
            name.endsWith(".opus") -> ".opus"
            name.endsWith(".flac") -> ".flac"
            name.endsWith(".ogg") -> ".ogg"
            else -> ""
        }
    }

    private fun extFromMimeType(mime: String?): String {
        return when (mime) {
            "audio/mp4" -> ".m4a"
            "audio/mpeg" -> ".mp3"
            "audio/ogg" -> ".opus"
            "audio/flac" -> ".flac"
            else -> ""
        }
    }

    private fun copyUriToTemp(uri: Uri, fallbackExt: String? = null): String? {
        var tempFile: File? = null
        var success = false

        try {
            val mime = try { contentResolver.getType(uri) } catch (_: Exception) { null }
            val nameHint = (
                try { DocumentFile.fromSingleUri(this, uri)?.name } catch (_: Exception) { null }
                    ?: uri.lastPathSegment
                    ?: ""
            ).lowercase(Locale.ROOT)
            val extFromName = extFromFileName(nameHint)
            val extFromMime = extFromMimeType(mime)
            val ext = if (extFromName.isNotBlank()) extFromName else if (extFromMime.isNotBlank()) extFromMime else (fallbackExt ?: "")
            val suffix: String? = if (ext.isNotBlank()) ext else null
            tempFile = File.createTempFile("saf_", suffix, cacheDir)

            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(tempFile).use { output ->
                    input.copyTo(output)
                }
            } ?: return null

            success = true
            return tempFile.absolutePath
        } catch (e: SecurityException) {
            // SAF permission denied - try MediaStore fallback for Samsung One UI
            // which may return MediaStore URIs from SAF tree traversal
            if (isMediaStoreUri(uri)) {
                android.util.Log.d(
                    "SpotiFLAC",
                    "SAF denied for MediaStore URI, trying MediaStore fallback: $uri",
                )
                val result = copyMediaStoreUriToTemp(uri, fallbackExt)
                if (result != null) {
                    success = true
                    return result
                }
            }
            android.util.Log.w(
                "SpotiFLAC",
                "SAF read denied for $uri: ${e.message}",
            )
            return null
        } catch (e: Exception) {
            android.util.Log.w(
                "SpotiFLAC",
                "Failed copying SAF uri $uri to temp: ${e.message}",
            )
            return null
        } finally {
            if (!success) {
                try {
                    tempFile?.delete()
                } catch (_: Exception) {}
            }
        }
    }

    /**
     * Fallback for Samsung One UI: read a MediaStore content URI using
     * READ_MEDIA_AUDIO / READ_EXTERNAL_STORAGE permission instead of SAF.
     * This handles the case where SAF tree traversal returns MediaStore URIs
     * that the SAF document provider cannot access.
     */
    private fun copyMediaStoreUriToTemp(uri: Uri, fallbackExt: String?): String? {
        var tempFile: File? = null
        try {
            val ext = resolveMediaStoreExt(uri, fallbackExt)
            val suffix: String? = if (ext.isNotBlank()) ext else null
            tempFile = File.createTempFile("ms_", suffix, cacheDir)

            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(tempFile).use { output ->
                    input.copyTo(output)
                }
            } ?: run {
                tempFile.delete()
                return null
            }

            android.util.Log.d(
                "SpotiFLAC",
                "MediaStore fallback succeeded for $uri",
            )
            return tempFile.absolutePath
        } catch (e: Exception) {
            android.util.Log.w(
                "SpotiFLAC",
                "MediaStore fallback also failed for $uri: ${e.message}",
            )
            try { tempFile?.delete() } catch (_: Exception) {}
            return null
        }
    }

    private fun buildUriDisplayName(
        uri: Uri,
        displayNameHint: String? = null,
        fallbackExt: String? = null,
    ): String {
        val explicitName = displayNameHint?.trim().orEmpty()
        if (explicitName.isNotEmpty()) return explicitName

        val docName = try { DocumentFile.fromSingleUri(this, uri)?.name } catch (_: Exception) { null }
        val uriName = uri.lastPathSegment
        val resolvedName = (docName ?: uriName ?: "").trim()
        if (resolvedName.isNotEmpty()) return resolvedName

        val ext = when {
            fallbackExt.isNullOrBlank().not() -> fallbackExt
            isMediaStoreUri(uri) -> resolveMediaStoreExt(uri, fallbackExt)
            else -> ""
        }
        return if (ext.isNullOrBlank()) "audio" else "audio$ext"
    }

    private fun buildLibraryCoverCacheKey(stablePath: String, lastModified: Long): String {
        val normalizedPath = stablePath.trim()
        if (normalizedPath.isEmpty()) return ""
        return if (lastModified > 0L) "$normalizedPath|$lastModified" else normalizedPath
    }

    private fun readAudioMetadataFromUri(
        uri: Uri,
        displayNameHint: String? = null,
        fallbackExt: String? = null,
        coverCacheKey: String = "",
    ): JSONObject? {
        val displayName = buildUriDisplayName(uri, displayNameHint, fallbackExt)

        // Skip /proc/self/fd/ attempt when known to fail (e.g. Samsung SELinux).
        if (procSelfFdReadable != false) {
            try {
                contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                    val directPath = "/proc/self/fd/${pfd.fd}"
                    val metadataJson = Gobackend.readAudioMetadataWithHintAndCoverCacheKeyJSON(
                        directPath,
                        displayName,
                        coverCacheKey,
                    )
                    if (metadataJson.isNotBlank()) {
                        val obj = JSONObject(metadataJson)
                        val filenameFallback = obj.optBoolean("metadataFromFilename", false)
                        if (!obj.has("error") && !filenameFallback) {
                            procSelfFdReadable = true
                            return obj
                        }
                        // Go could not read real metadata from the fd path –
                        // remember so we skip the attempt for remaining files.
                        if (procSelfFdReadable == null) {
                            procSelfFdReadable = false
                            android.util.Log.d(
                                "SpotiFLAC",
                                "Direct /proc/self/fd read not usable on this device, " +
                                    "using temp-file fallback for remaining files",
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                if (procSelfFdReadable == null) {
                    procSelfFdReadable = false
                    android.util.Log.d(
                        "SpotiFLAC",
                        "Direct /proc/self/fd read not usable on this device, " +
                            "using temp-file fallback for remaining files",
                    )
                }
            }
        }

        val tempPath = try {
            copyUriToTemp(uri, fallbackExt)
        } catch (e: Exception) {
            android.util.Log.w(
                "SpotiFLAC",
                "SAF metadata fallback copy failed for $uri: ${e.message}",
            )
            null
        } ?: return null

        try {
            val metadataJson = Gobackend.readAudioMetadataWithHintAndCoverCacheKeyJSON(
                tempPath,
                displayName,
                coverCacheKey,
            )
            if (metadataJson.isBlank()) return null
            val obj = JSONObject(metadataJson)
            return if (obj.has("error")) null else obj
        } catch (e: Exception) {
            android.util.Log.w(
                "SpotiFLAC",
                "SAF metadata temp read failed for $uri: ${e.message}",
            )
            return null
        } finally {
            try {
                File(tempPath).delete()
            } catch (_: Exception) {}
        }
    }

    private fun writeUriFromPath(uri: Uri, srcPath: String): Boolean {
        val srcFile = File(srcPath)
        if (!srcFile.exists()) return false
        contentResolver.openOutputStream(uri, "wt")?.use { output ->
            FileInputStream(srcFile).use { input ->
                input.copyTo(output)
            }
        } ?: return false
        return true
    }

    private fun handleSafDownload(requestJson: String, downloader: (String) -> String): String {
        val req = JSONObject(requestJson)
        val storageMode = req.optString("storage_mode", "")
        val treeUriStr = req.optString("saf_tree_uri", "")
        if (storageMode != "saf" || treeUriStr.isBlank()) {
            return downloader(requestJson)
        }

        val treeUri = Uri.parse(treeUriStr)
        val relativeDir = sanitizeRelativeDir(req.optString("saf_relative_dir", ""))
        val outputExt = normalizeExt(req.optString("saf_output_ext", ""))
        val mimeType = mimeTypeForExt(outputExt)
        val fileName = buildSafFileName(req, outputExt)

        val existingDir = findDocumentDir(treeUri, relativeDir)
        if (existingDir != null) {
            val existing = existingDir.findFile(fileName)
            if (existing != null && existing.isFile && existing.length() > 0) {
                val obj = JSONObject()
                obj.put("success", true)
                obj.put("message", "File already exists")
                obj.put("file_path", existing.uri.toString())
                obj.put("file_name", existing.name ?: fileName)
                obj.put("already_exists", true)
                return obj.toString()
            }
        }

        val targetDir = ensureDocumentDir(treeUri, relativeDir)
            ?: return errorJson("Failed to access SAF directory")

        val existingFile = targetDir.findFile(fileName)
        val document = existingFile ?: targetDir.createFile(mimeType, fileName)
            ?: return errorJson("Failed to create SAF file")

        val pfd = contentResolver.openFileDescriptor(document.uri, "rw")
            ?: return errorJson("Failed to open SAF file")

        var detachedFd: Int? = null
        try {
            // Prefer handing off a detached FD directly to Go.
            // Some devices/providers reject re-opening /proc/self/fd/* with permission denied.
            detachedFd = pfd.detachFd()
            req.put("output_path", "")
            req.put("output_fd", detachedFd)
            req.put("output_ext", outputExt)
            val response = downloader(req.toString())
            val respObj = JSONObject(response)
            if (respObj.optBoolean("success", false)) {
                // Extension providers write to a local temp path instead of the SAF FD.
                val goFilePath = respObj.optString("file_path", "")
                if (goFilePath.isNotEmpty() &&
                    !goFilePath.startsWith("content://") &&
                    !goFilePath.startsWith("/proc/self/fd/")
                ) {
                    try {
                        val srcFile = java.io.File(goFilePath)
                        if (!srcFile.exists() || srcFile.length() <= 0) {
                            throw IllegalStateException("extension output missing or empty: $goFilePath")
                        }
                        contentResolver.openOutputStream(document.uri, "wt")?.use { output ->
                            srcFile.inputStream().use { input ->
                                input.copyTo(output)
                            }
                        } ?: throw IllegalStateException("failed to open SAF output stream")
                        srcFile.delete()
                    } catch (e: Exception) {
                        document.delete()
                        android.util.Log.w("SpotiFLAC", "Failed to copy extension output to SAF: ${e.message}")
                        return errorJson("Failed to copy extension output to SAF: ${e.message}")
                    }
                }
                respObj.put("file_path", document.uri.toString())
                respObj.put("file_name", document.name ?: fileName)
            } else {
                document.delete()
            }
            return respObj.toString()
        } catch (e: Exception) {
            document.delete()
            return errorJson("SAF download failed: ${e.message}")
        } finally {
            // If detachFd() failed before handoff, close original ParcelFileDescriptor.
            // Otherwise Go owns the detached raw FD and is responsible for closing it.
            if (detachedFd == null) {
                try {
                    pfd.close()
                } catch (_: Exception) {}
            }
        }
    }

    /**
     * Get the parent DocumentFile directory for a SAF document URI.
     * The child URI must be a tree-based document URI (e.g. from SAF tree scan).
     * Returns a DocumentFile that supports findFile() for sibling lookup.
     */
    private fun safParentDir(childUri: Uri): DocumentFile? {
        try {
            val docId = android.provider.DocumentsContract.getDocumentId(childUri)
            if (docId.isNullOrEmpty()) return null
            val lastSlash = docId.lastIndexOf('/')
            if (lastSlash <= 0) return null

            val parentDocId = docId.substring(0, lastSlash)
            val treeDocId = android.provider.DocumentsContract.getTreeDocumentId(childUri)
            if (treeDocId.isNullOrEmpty()) return null

            val parentUri = android.provider.DocumentsContract.buildDocumentUriUsingTree(
                childUri, parentDocId
            )
            return DocumentFile.fromTreeUri(this, parentUri)
                ?: DocumentFile.fromSingleUri(this, parentUri)
        } catch (e: Exception) {
            android.util.Log.w("SpotiFLAC", "Failed to get SAF parent dir: ${e.message}")
            return null
        }
    }

    /**
     * Extract the audio filename referenced by a CUE sheet file.
     * Reads the FILE "name" TYPE line from the .cue text.
     * Returns just the filename (no path), or null if not found.
     */
    private fun extractCueAudioFileName(cueTempPath: String): String? {
        try {
            val lines = File(cueTempPath).readLines()
            for (line in lines) {
                val trimmed = line.trim().let { l ->
                    if (l.startsWith("\uFEFF")) l.removePrefix("\uFEFF").trim() else l
                }
                if (trimmed.uppercase(Locale.ROOT).startsWith("FILE ")) {
                    val rest = trimmed.substring(5).trim()
                    val filename = if (rest.startsWith("\"")) {
                        val endQuote = rest.indexOf('"', 1)
                        if (endQuote > 0) rest.substring(1, endQuote) else rest
                    } else {
                        val parts = rest.split("\\s+".toRegex())
                        if (parts.size >= 2) parts.dropLast(1).joinToString(" ") else rest
                    }
                    return filename.substringAfterLast("/").substringAfterLast("\\")
                }
            }
        } catch (e: Exception) {
            android.util.Log.w("SpotiFLAC", "Failed to extract audio filename from CUE: ${e.message}")
        }
        return null
    }

    private val cueSiblingAudioExtensions = listOf(
        ".flac", ".wav", ".ape", ".mp3", ".ogg", ".wv", ".m4a"
    )

    private fun getSafChildFileLookup(
        dir: DocumentFile,
        cache: MutableMap<String, Map<String, DocumentFile>>,
    ): Map<String, DocumentFile> {
        val dirKey = dir.uri.toString()
        return cache.getOrPut(dirKey) {
            try {
                buildMap {
                    for (child in dir.listFiles()) {
                        if (!child.isFile) continue
                        val childName = child.name?.trim().orEmpty()
                        if (childName.isBlank()) continue
                        put(childName.lowercase(Locale.ROOT), child)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w(
                    "SpotiFLAC",
                    "Failed to build SAF child lookup for $dirKey: ${e.message}",
                )
                emptyMap()
            }
        }
    }

    private fun resolveCueAudioSibling(
        parentDir: DocumentFile,
        cueName: String,
        audioFileName: String?,
        childLookupCache: MutableMap<String, Map<String, DocumentFile>>,
    ): DocumentFile? {
        val childLookup = getSafChildFileLookup(parentDir, childLookupCache)

        val directMatch = audioFileName
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.substringAfterLast("/")
            ?.substringAfterLast("\\")
            ?.lowercase(Locale.ROOT)
            ?.let(childLookup::get)
        if (directMatch != null) {
            return directMatch
        }

        val cueBaseName = cueName.substringBeforeLast('.').trim()
        if (cueBaseName.isBlank()) {
            return null
        }

        val cueBaseKey = cueBaseName.lowercase(Locale.ROOT)
        for (ext in cueSiblingAudioExtensions) {
            childLookup["$cueBaseKey$ext"]?.let { return it }
        }
        return null
    }

    private fun scanSafTree(treeUriStr: String): String {
        if (treeUriStr.isBlank()) return "[]"

        val treeUri = Uri.parse(treeUriStr)
        val root = DocumentFile.fromTreeUri(this, treeUri) ?: return "[]"

        resetSafScanProgress()
        safScanCancel = false
        safScanActive = true
        updateSafScanProgress {
            it.currentFile = "Scanning folders..."
        }

        val supportedAudioExt = setOf(".flac", ".m4a", ".mp3", ".opus", ".ogg")
        val audioFiles = mutableListOf<Pair<DocumentFile, String>>()
        val cueFiles = mutableListOf<Pair<DocumentFile, DocumentFile>>()
        val visitedDirUris = mutableSetOf<String>()
        val safChildLookupCache = mutableMapOf<String, Map<String, DocumentFile>>()
        var traversalErrors = 0

        val queue: ArrayDeque<Pair<DocumentFile, String>> = ArrayDeque()
        queue.add(root to "")

        while (queue.isNotEmpty()) {
            if (safScanCancel) {
                updateSafScanProgress { it.isComplete = true }
                return "[]"
            }

            val (dir, path) = queue.removeFirst()
            val dirUri = dir.uri.toString()
            if (!visitedDirUris.add(dirUri)) {
                continue
            }

            val children = try {
                dir.listFiles()
            } catch (e: Exception) {
                traversalErrors++
                updateSafScanProgress { it.errorCount = traversalErrors }
                android.util.Log.w(
                    "SpotiFLAC",
                    "SAF scan: failed listing directory $dirUri: ${e.message}",
                )
                continue
            }

            for (child in children) {
                if (safScanCancel) {
                    updateSafScanProgress { it.isComplete = true }
                    return "[]"
                }

                try {
                    if (child.isDirectory) {
                        val childName = child.name ?: continue
                        val childPath = if (path.isBlank()) childName else "$path/$childName"
                        val childUri = child.uri.toString()
                        if (childUri == dirUri || visitedDirUris.contains(childUri)) {
                            continue
                        }
                        queue.add(child to childPath)
                    } else if (child.isFile) {
                        val name = child.name ?: continue
                        val ext = name.substringAfterLast('.', "").lowercase(Locale.ROOT)
                        if (ext == "cue") {
                            cueFiles.add(child to dir)
                        } else if (ext.isNotBlank() && supportedAudioExt.contains(".$ext")) {
                            audioFiles.add(child to path)
                        }
                    }
                } catch (e: Exception) {
                    traversalErrors++
                    updateSafScanProgress { it.errorCount = traversalErrors }
                    android.util.Log.w(
                        "SpotiFLAC",
                        "SAF scan: skipped child under $dirUri: ${e.message}",
                    )
                }
            }
        }

        val totalItems = audioFiles.size + cueFiles.size
        updateSafScanProgress {
            it.totalFiles = totalItems
        }

        if (audioFiles.isEmpty() && cueFiles.isEmpty()) {
            updateSafScanProgress {
                it.isComplete = true
                it.progressPct = 100.0
            }
            return "[]"
        }

        val results = JSONArray()
        var scanned = 0
        var errors = traversalErrors

        val cueReferencedAudioUris = mutableSetOf<String>()

        for ((cueDoc, parentDir) in cueFiles) {
            if (safScanCancel) {
                updateSafScanProgress { it.isComplete = true }
                return "[]"
            }

            val cueName = try { cueDoc.name ?: "" } catch (_: Exception) { "" }
            updateSafScanProgress { it.currentFile = cueName }

            var tempCuePath: String? = null
            var tempAudioPath: String? = null
            try {
                tempCuePath = copyUriToTemp(cueDoc.uri, ".cue")
                if (tempCuePath == null) {
                    errors++
                    android.util.Log.w("SpotiFLAC", "SAF scan: failed to copy CUE ${cueDoc.uri}")
                    scanned++
                    continue
                }

                val audioFileName = extractCueAudioFileName(tempCuePath)

                val audioDoc = resolveCueAudioSibling(
                    parentDir = parentDir,
                    cueName = cueName,
                    audioFileName = audioFileName,
                    childLookupCache = safChildLookupCache,
                )

                if (audioDoc == null) {
                    android.util.Log.w("SpotiFLAC", "SAF scan: no audio file found for CUE $cueName")
                    errors++
                    scanned++
                    continue
                }

                cueReferencedAudioUris.add(audioDoc.uri.toString())

                val tempDir = File(tempCuePath).parent ?: cacheDir.absolutePath
                val audioName = try { audioDoc.name ?: "audio.flac" } catch (_: Exception) { "audio.flac" }
                val audioExt = audioName.substringAfterLast('.', "").lowercase(Locale.ROOT)
                val fallbackAudioExt = if (audioExt.isNotBlank()) ".$audioExt" else null
                val audioLastModified = try { audioDoc.lastModified() } catch (_: Exception) { cueDoc.lastModified() }
                val coverCacheKey = buildLibraryCoverCacheKey(
                    audioDoc.uri.toString(),
                    audioLastModified,
                )

                tempAudioPath = copyUriToTemp(audioDoc.uri, fallbackAudioExt)
                if (tempAudioPath == null) {
                    android.util.Log.w("SpotiFLAC", "SAF scan: failed to copy audio for CUE $cueName")
                    errors++
                    scanned++
                    continue
                }

                val renamedAudio = File(tempDir, audioName)
                val tempAudioFile = File(tempAudioPath)
                if (renamedAudio.absolutePath != tempAudioFile.absolutePath) {
                    tempAudioFile.renameTo(renamedAudio)
                    tempAudioPath = renamedAudio.absolutePath
                }

                val cueLastModified = try { cueDoc.lastModified() } catch (_: Exception) { 0L }

                val cueResultsJson = Gobackend.scanCueSheetForLibraryWithCoverCacheKey(
                    tempCuePath,
                    tempDir,
                    cueDoc.uri.toString(),
                    cueLastModified,
                    coverCacheKey,
                )

                val cueArray = JSONArray(cueResultsJson)
                for (j in 0 until cueArray.length()) {
                    results.put(cueArray.getJSONObject(j))
                }

                android.util.Log.d(
                    "SpotiFLAC",
                    "SAF scan: CUE $cueName -> ${cueArray.length()} tracks"
                )
            } catch (e: Exception) {
                errors++
                android.util.Log.w("SpotiFLAC", "SAF scan: error processing CUE $cueName: ${e.message}")
            } finally {
                try { tempCuePath?.let { File(it).delete() } } catch (_: Exception) {}
                try { tempAudioPath?.let { File(it).delete() } } catch (_: Exception) {}
            }

            scanned++
            val pct = scanned.toDouble() / totalItems.toDouble() * 100.0
            updateSafScanProgress {
                it.scannedFiles = scanned
                it.errorCount = errors
                it.progressPct = pct
            }
        }

        for ((doc, _) in audioFiles) {
            if (safScanCancel) {
                updateSafScanProgress { it.isComplete = true }
                return "[]"
            }

            if (cueReferencedAudioUris.contains(doc.uri.toString())) {
                scanned++
                val pct = scanned.toDouble() / totalItems.toDouble() * 100.0
                updateSafScanProgress {
                    it.scannedFiles = scanned
                    it.progressPct = pct
                }
                continue
            }

            val name = try { doc.name ?: "" } catch (_: Exception) { "" }
            updateSafScanProgress {
                it.currentFile = name
            }

            val ext = name.substringAfterLast('.', "").lowercase(Locale.ROOT)
            val fallbackExt = if (ext.isNotBlank()) ".${ext}" else null
            val lastModified = try { doc.lastModified() } catch (_: Exception) { 0L }
            val stableUri = doc.uri.toString()
            val coverCacheKey = buildLibraryCoverCacheKey(stableUri, lastModified)
            val metadataObj = readAudioMetadataFromUri(
                doc.uri,
                name,
                fallbackExt,
                coverCacheKey,
            )
            if (metadataObj == null) {
                errors++
            } else {
                try {
                    metadataObj.put("id", buildStableLibraryId(stableUri))
                    metadataObj.put("filePath", stableUri)
                    metadataObj.put("fileModTime", lastModified)
                    results.put(metadataObj)
                } catch (_: Exception) {
                    errors++
                }
            }

            scanned++
            val pct = scanned.toDouble() / totalItems.toDouble() * 100.0
            updateSafScanProgress {
                it.scannedFiles = scanned
                it.errorCount = errors
                it.progressPct = pct
            }
        }

        updateSafScanProgress {
            it.isComplete = true
            it.progressPct = 100.0
        }

        return results.toString()
    }

    /**
     * Incremental SAF tree scan - only scans new or modified files.
     * Supports .cue sheets: expands them into virtual track entries and
     * deduplicates audio files referenced by CUE sheets.
     * @param treeUriStr The SAF tree URI to scan
     * @param existingFilesJson JSON object mapping file URI -> lastModified timestamp
     * @return JSON object with new/changed files and removed URIs
     */
    private fun scanSafTreeIncremental(treeUriStr: String, existingFilesJson: String): String {
        if (treeUriStr.isBlank()) {
            val result = JSONObject()
            result.put("files", JSONArray())
            result.put("removedUris", JSONArray())
            result.put("skippedCount", 0)
            result.put("totalFiles", 0)
            return result.toString()
        }

        val treeUri = Uri.parse(treeUriStr)
        val root = DocumentFile.fromTreeUri(this, treeUri) ?: run {
            val result = JSONObject()
            result.put("files", JSONArray())
            result.put("removedUris", JSONArray())
            result.put("skippedCount", 0)
            result.put("totalFiles", 0)
            return result.toString()
        }

        val existingFiles = mutableMapOf<String, Long>()
        try {
            val obj = JSONObject(existingFilesJson)
            val keys = obj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                existingFiles[key] = obj.optLong(key, 0)
            }
        } catch (_: Exception) {}

        resetSafScanProgress()
        safScanCancel = false
        safScanActive = true
        updateSafScanProgress {
            it.currentFile = "Scanning folders..."
        }

        val supportedAudioExt = setOf(".flac", ".m4a", ".mp3", ".opus", ".ogg")
        val audioFiles = mutableListOf<Triple<DocumentFile, String, Long>>()
        val cueFilesToScan = mutableListOf<Triple<DocumentFile, DocumentFile, Long>>()
        val unchangedCueFiles = mutableListOf<Pair<DocumentFile, DocumentFile>>()
        val currentUris = mutableSetOf<String>()
        val visitedDirUris = mutableSetOf<String>()
        val safChildLookupCache = mutableMapOf<String, Map<String, DocumentFile>>()
        var traversalErrors = 0

        val existingCueVirtualPaths = mutableMapOf<String, MutableList<String>>()
        for (key in existingFiles.keys) {
            val hashIdx = key.indexOf("#track")
            if (hashIdx > 0) {
                val baseCueUri = key.substring(0, hashIdx)
                existingCueVirtualPaths.getOrPut(baseCueUri) { mutableListOf() }.add(key)
            }
        }

        val queue: ArrayDeque<Pair<DocumentFile, String>> = ArrayDeque()
        queue.add(root to "")

        while (queue.isNotEmpty()) {
            if (safScanCancel) {
                updateSafScanProgress { it.isComplete = true }
                val result = JSONObject()
                result.put("files", JSONArray())
                result.put("removedUris", JSONArray())
                result.put("skippedCount", 0)
                result.put("totalFiles", 0)
                result.put("cancelled", true)
                return result.toString()
            }

            val (dir, path) = queue.removeFirst()
            val dirUri = dir.uri.toString()
            if (!visitedDirUris.add(dirUri)) {
                continue
            }

            val children = try {
                dir.listFiles()
            } catch (e: Exception) {
                traversalErrors++
                updateSafScanProgress { it.errorCount = traversalErrors }
                android.util.Log.w(
                    "SpotiFLAC",
                    "SAF incremental scan: failed listing directory $dirUri: ${e.message}",
                )
                continue
            }

            for (child in children) {
                if (safScanCancel) {
                    updateSafScanProgress { it.isComplete = true }
                    val result = JSONObject()
                    result.put("files", JSONArray())
                    result.put("removedUris", JSONArray())
                    result.put("skippedCount", 0)
                    result.put("totalFiles", 0)
                    result.put("cancelled", true)
                    return result.toString()
                }

                try {
                    if (child.isDirectory) {
                        val childName = child.name ?: continue
                        val childPath = if (path.isBlank()) childName else "$path/$childName"
                        val childUri = child.uri.toString()
                        if (childUri == dirUri || visitedDirUris.contains(childUri)) {
                            continue
                        }
                        queue.add(child to childPath)
                    } else if (child.isFile) {
                        val uriStr = child.uri.toString()
                        currentUris.add(uriStr)

                        val name = child.name ?: continue
                        val ext = name.substringAfterLast('.', "").lowercase(Locale.ROOT)

                        if (ext == "cue") {
                            val lastModified = try {
                                child.lastModified()
                            } catch (_: Exception) { 0L }

                            val virtualPaths = existingCueVirtualPaths[uriStr]
                            val existingModified = virtualPaths?.firstOrNull()?.let { existingFiles[it] }

                            if (existingModified != null && existingModified == lastModified) {
                                unchangedCueFiles.add(child to dir)
                                for (vp in virtualPaths) {
                                    currentUris.add(vp)
                                }
                            } else {
                                cueFilesToScan.add(Triple(child, dir, lastModified))
                            }
                        } else if (ext.isNotBlank() && supportedAudioExt.contains(".$ext")) {
                            val existingModified = existingFiles[uriStr]
                            val lastModified = try {
                                child.lastModified()
                            } catch (_: Exception) {
                                existingModified ?: 0L
                            }

                            if (existingModified == null || existingModified != lastModified) {
                                audioFiles.add(Triple(child, path, lastModified))
                            }
                        }
                    }
                } catch (e: Exception) {
                    traversalErrors++
                    updateSafScanProgress { it.errorCount = traversalErrors }
                    android.util.Log.w(
                        "SpotiFLAC",
                        "SAF incremental scan: skipped child under $dirUri: ${e.message}",
                    )
                }
            }
        }

        val removedUris = existingFiles.keys.filter { !currentUris.contains(it) }
        val totalFiles = currentUris.size
        val filesToProcess = audioFiles.size + cueFilesToScan.size
        val skippedCount = (totalFiles - filesToProcess).coerceAtLeast(0)

        updateSafScanProgress {
            it.totalFiles = totalFiles
        }

        if (audioFiles.isEmpty() && cueFilesToScan.isEmpty()) {
            updateSafScanProgress {
                it.isComplete = true
                it.scannedFiles = totalFiles
                it.progressPct = 100.0
            }
            val result = JSONObject()
            result.put("files", JSONArray())
            result.put("removedUris", JSONArray(removedUris))
            result.put("skippedCount", skippedCount)
            result.put("totalFiles", totalFiles)
            return result.toString()
        }

        val results = JSONArray()
        var scanned = 0
        var errors = traversalErrors

        val cueReferencedAudioUris = mutableSetOf<String>()

        for ((cueDoc, parentDir, cueLastModified) in cueFilesToScan) {
            if (safScanCancel) {
                updateSafScanProgress { it.isComplete = true }
                val result = JSONObject()
                result.put("files", JSONArray())
                result.put("removedUris", JSONArray())
                result.put("skippedCount", skippedCount)
                result.put("totalFiles", totalFiles)
                result.put("cancelled", true)
                return result.toString()
            }

            val cueName = try { cueDoc.name ?: "" } catch (_: Exception) { "" }
            updateSafScanProgress { it.currentFile = cueName }

            var tempCuePath: String? = null
            var tempAudioPath: String? = null
            try {
                tempCuePath = copyUriToTemp(cueDoc.uri, ".cue")
                if (tempCuePath == null) {
                    errors++
                    android.util.Log.w("SpotiFLAC", "SAF incremental scan: failed to copy CUE ${cueDoc.uri}")
                    scanned++
                    continue
                }

                val audioFileName = extractCueAudioFileName(tempCuePath)

                val audioDoc = resolveCueAudioSibling(
                    parentDir = parentDir,
                    cueName = cueName,
                    audioFileName = audioFileName,
                    childLookupCache = safChildLookupCache,
                )

                if (audioDoc == null) {
                    android.util.Log.w("SpotiFLAC", "SAF incremental scan: no audio file found for CUE $cueName")
                    errors++
                    scanned++
                    continue
                }

                cueReferencedAudioUris.add(audioDoc.uri.toString())

                val tempDir = File(tempCuePath).parent ?: cacheDir.absolutePath
                val audioName = try { audioDoc.name ?: "audio.flac" } catch (_: Exception) { "audio.flac" }
                val audioExt = audioName.substringAfterLast('.', "").lowercase(Locale.ROOT)
                val fallbackAudioExt = if (audioExt.isNotBlank()) ".$audioExt" else null
                val audioLastModified = try { audioDoc.lastModified() } catch (_: Exception) { cueLastModified }
                val coverCacheKey = buildLibraryCoverCacheKey(
                    audioDoc.uri.toString(),
                    audioLastModified,
                )

                tempAudioPath = copyUriToTemp(audioDoc.uri, fallbackAudioExt)
                if (tempAudioPath == null) {
                    android.util.Log.w("SpotiFLAC", "SAF incremental scan: failed to copy audio for CUE $cueName")
                    errors++
                    scanned++
                    continue
                }

                val renamedAudio = File(tempDir, audioName)
                val tempAudioFile = File(tempAudioPath)
                if (renamedAudio.absolutePath != tempAudioFile.absolutePath) {
                    tempAudioFile.renameTo(renamedAudio)
                    tempAudioPath = renamedAudio.absolutePath
                }

                val cueResultsJson = Gobackend.scanCueSheetForLibraryWithCoverCacheKey(
                    tempCuePath,
                    tempDir,
                    cueDoc.uri.toString(),
                    cueLastModified,
                    coverCacheKey,
                )

                val cueArray = JSONArray(cueResultsJson)
                for (j in 0 until cueArray.length()) {
                    val trackObj = cueArray.getJSONObject(j)
                    results.put(trackObj)
                    val virtualPath = trackObj.optString("filePath", "")
                    if (virtualPath.isNotBlank()) {
                        currentUris.add(virtualPath)
                    }
                }

                android.util.Log.d(
                    "SpotiFLAC",
                    "SAF incremental scan: CUE $cueName -> ${cueArray.length()} tracks"
                )
            } catch (e: Exception) {
                errors++
                android.util.Log.w("SpotiFLAC", "SAF incremental scan: error processing CUE $cueName: ${e.message}")
            } finally {
                try { tempCuePath?.let { File(it).delete() } } catch (_: Exception) {}
                try { tempAudioPath?.let { File(it).delete() } } catch (_: Exception) {}
            }

            scanned++
            val processed = skippedCount + scanned
            val pct = if (totalFiles > 0) {
                processed.toDouble() / totalFiles.toDouble() * 100.0
            } else {
                100.0
            }
            updateSafScanProgress {
                it.scannedFiles = processed
                it.errorCount = errors
                it.progressPct = pct
            }
        }

        for ((cueDoc, parentDir) in unchangedCueFiles) {
            var tempCue: String? = null
            try {
                tempCue = copyUriToTemp(cueDoc.uri, ".cue")
                if (tempCue != null) {
                    val audioFileName = extractCueAudioFileName(tempCue)
                    val cueName = try { cueDoc.name ?: "" } catch (_: Exception) { "" }
                    val audioDoc = resolveCueAudioSibling(
                        parentDir = parentDir,
                        cueName = cueName,
                        audioFileName = audioFileName,
                        childLookupCache = safChildLookupCache,
                    )
                    if (audioDoc != null) {
                        cueReferencedAudioUris.add(audioDoc.uri.toString())
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w("SpotiFLAC", "SAF incremental scan: failed to resolve audio for unchanged CUE: ${e.message}")
            } finally {
                try { tempCue?.let { File(it).delete() } } catch (_: Exception) {}
            }
        }

        for ((doc, _, lastModified) in audioFiles) {
            if (safScanCancel) {
                updateSafScanProgress { it.isComplete = true }
                val result = JSONObject()
                result.put("files", JSONArray())
                result.put("removedUris", JSONArray())
                result.put("skippedCount", skippedCount)
                result.put("totalFiles", totalFiles)
                result.put("cancelled", true)
                return result.toString()
            }

            if (cueReferencedAudioUris.contains(doc.uri.toString())) {
                scanned++
                val processed = skippedCount + scanned
                val pct = if (totalFiles > 0) {
                    processed.toDouble() / totalFiles.toDouble() * 100.0
                } else {
                    100.0
                }
                updateSafScanProgress {
                    it.scannedFiles = processed
                    it.progressPct = pct
                }
                continue
            }

            val name = try { doc.name ?: "" } catch (_: Exception) { "" }
            updateSafScanProgress {
                it.currentFile = name
            }

            val ext = name.substringAfterLast('.', "").lowercase(Locale.ROOT)
            val fallbackExt = if (ext.isNotBlank()) ".${ext}" else null
            val safeLastModified = try { doc.lastModified() } catch (_: Exception) { lastModified }
            val stableUri = doc.uri.toString()
            val coverCacheKey = buildLibraryCoverCacheKey(stableUri, safeLastModified)
            val metadataObj = readAudioMetadataFromUri(
                doc.uri,
                name,
                fallbackExt,
                coverCacheKey,
            )
            if (metadataObj == null) {
                errors++
            } else {
                try {
                    metadataObj.put("id", buildStableLibraryId(stableUri))
                    metadataObj.put("filePath", stableUri)
                    metadataObj.put("fileModTime", safeLastModified)
                    metadataObj.put("lastModified", safeLastModified)
                    results.put(metadataObj)
                } catch (_: Exception) {
                    errors++
                }
            }

            scanned++
            val processed = skippedCount + scanned
            val pct = if (totalFiles > 0) {
                processed.toDouble() / totalFiles.toDouble() * 100.0
            } else {
                100.0
            }
            updateSafScanProgress {
                it.scannedFiles = processed
                it.errorCount = errors
                it.progressPct = pct
            }
        }

        val finalRemovedUris = existingFiles.keys.filter { !currentUris.contains(it) }

        updateSafScanProgress {
            it.isComplete = true
            it.progressPct = 100.0
        }

        val result = JSONObject()
        result.put("files", results)
        result.put("removedUris", JSONArray(finalRemovedUris))
        result.put("skippedCount", skippedCount)
        result.put("totalFiles", totalFiles)
        return result.toString()
    }

    /**
     * Resolve SAF file last-modified values for a list of content URIs.
     * Returns JSON object mapping uri -> lastModified (unix millis).
     */
    private fun getSafFileModTimes(urisJson: String): String {
        val result = JSONObject()
        val uris = try {
            JSONArray(urisJson)
        } catch (_: Exception) {
            JSONArray()
        }

        for (i in 0 until uris.length()) {
            val uriStr = uris.optString(i, "")
            if (uriStr.isBlank()) continue
            try {
                val uri = Uri.parse(uriStr)
                val doc = DocumentFile.fromSingleUri(this, uri)
                if (doc != null && doc.exists()) {
                    result.put(uriStr, doc.lastModified())
                }
            } catch (_: Exception) {}
        }

        return result.toString()
    }

    private fun runPostProcessingSaf(fileUriStr: String, metadataJson: String): String {
        val uri = Uri.parse(fileUriStr)
        val doc = DocumentFile.fromSingleUri(this, uri)
            ?: return errorJson("SAF file not found")

        val tempInput = copyUriToTemp(uri) ?: return errorJson("Failed to copy SAF file to temp")
        val tempDir = File(tempInput).parentFile?.absolutePath ?: ""
        if (tempDir.isNotBlank()) {
            try {
                Gobackend.allowDownloadDir(tempDir)
            } catch (_: Exception) {}
        }

        val response = Gobackend.runPostProcessingJSON(tempInput, metadataJson)
        val respObj = JSONObject(response)
        if (!respObj.optBoolean("success", false)) {
            try {
                File(tempInput).delete()
            } catch (_: Exception) {}
            return response
        }

        val newPath = respObj.optString("new_file_path", "")
        val outputPath = if (newPath.isNotBlank()) newPath else tempInput
        val outputFile = File(outputPath)
        if (!outputFile.exists()) {
            try {
                File(tempInput).delete()
            } catch (_: Exception) {}
            respObj.put("success", false)
            respObj.put("error", "postProcess output not found")
            return respObj.toString()
        }

        val newName = outputFile.name
        if (!newName.isNullOrBlank() && doc.name != null && doc.name != newName) {
            try {
                doc.renameTo(newName)
            } catch (_: Exception) {}
        }

        val writeOk = writeUriFromPath(uri, outputFile.absolutePath)
        if (!writeOk) {
            respObj.put("success", false)
            respObj.put("error", "failed to write postProcess output to SAF")
            return respObj.toString()
        }

        try {
            if (outputPath != tempInput) {
                outputFile.delete()
            }
            File(tempInput).delete()
        } catch (_: Exception) {}

        respObj.put("new_file_path", uri.toString())
        respObj.put("file_path", uri.toString())
        return respObj.toString()
    }

    private fun runPostProcessingSafV2(fileUriStr: String, metadataJson: String): String {
        val uri = Uri.parse(fileUriStr)
        val doc = DocumentFile.fromSingleUri(this, uri)
            ?: return errorJson("SAF file not found")

        val tempInput = copyUriToTemp(uri) ?: return errorJson("Failed to copy SAF file to temp")
        val tempDir = File(tempInput).parentFile?.absolutePath ?: ""
        if (tempDir.isNotBlank()) {
            try {
                Gobackend.allowDownloadDir(tempDir)
            } catch (_: Exception) {}
        }

        val inputObj = JSONObject()
        inputObj.put("path", tempInput)
        inputObj.put("uri", fileUriStr)
        inputObj.put("name", doc.name ?: File(tempInput).name)
        inputObj.put("mime_type", doc.type ?: contentResolver.getType(uri) ?: "")
        inputObj.put("size", doc.length())
        inputObj.put("is_saf", true)

        val response = Gobackend.runPostProcessingV2JSON(inputObj.toString(), metadataJson)
        val respObj = JSONObject(response)
        if (!respObj.optBoolean("success", false)) {
            try {
                File(tempInput).delete()
            } catch (_: Exception) {}
            return response
        }

        val newPath = respObj.optString("new_file_path", "")
        val outputPath = if (newPath.isNotBlank()) newPath else tempInput
        val outputFile = File(outputPath)
        if (!outputFile.exists()) {
            try {
                File(tempInput).delete()
            } catch (_: Exception) {}
            respObj.put("success", false)
            respObj.put("error", "postProcess output not found")
            return respObj.toString()
        }

        val newName = outputFile.name
        if (!newName.isNullOrBlank() && doc.name != null && doc.name != newName) {
            try {
                doc.renameTo(newName)
            } catch (_: Exception) {}
        }

        val writeOk = writeUriFromPath(uri, outputFile.absolutePath)
        if (!writeOk) {
            respObj.put("success", false)
            respObj.put("error", "failed to write postProcess output to SAF")
            return respObj.toString()
        }

        try {
            if (outputPath != tempInput) {
                outputFile.delete()
            }
            File(tempInput).delete()
        } catch (_: Exception) {}

        respObj.put("new_file_path", uri.toString())
        respObj.put("file_path", uri.toString())
        return respObj.toString()
    }

    // Disable Flutter's built-in deep linking so that incoming ACTION_VIEW URLs
    // (Spotify, Deezer, Tidal, YouTube Music) are NOT forwarded to GoRouter.
    // We handle these URLs ourselves via receive_sharing_intent + ShareIntentService.
    override fun shouldHandleDeeplinking(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleExtensionOAuthIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleExtensionOAuthIntent(intent)
    }

    /**
     * Deliver Spotify (or other) OAuth authorization code to the extension runtime
     * and run its token exchange (e.g. completeSpotifyLogin). State must be the extension id.
     */
    private fun handleExtensionOAuthIntent(intent: Intent?) {
        val uri = intent?.data ?: return
        if (!uri.scheme.equals("spotiflac", ignoreCase = true)) {
            return
        }
        val host = (uri.host ?: "").lowercase(Locale.US)
        val path = (uri.path ?: "").lowercase(Locale.US)
        val isCallback =
            host == "callback" ||
                host == "spotify-callback" ||
                path.contains("callback")
        if (!isCallback) {
            return
        }
        val code = uri.getQueryParameter("code")?.trim().orEmpty()
        if (code.isEmpty()) {
            return
        }
        val extId = uri.getQueryParameter("state")?.trim().orEmpty()
        if (extId.isEmpty()) {
            android.util.Log.w("SpotiFLAC", "Extension OAuth redirect missing state (extension id)")
            return
        }
        intent.data = null
        scope.launch(Dispatchers.IO) {
            try {
                Gobackend.setExtensionAuthCodeByID(extId, code)
                val json = Gobackend.invokeExtensionActionJSON(extId, "completeSpotifyLogin")
                android.util.Log.i("SpotiFLAC", "Extension OAuth complete for $extId: $json")
            } catch (e: Exception) {
                android.util.Log.w("SpotiFLAC", "Extension OAuth failed: ${e.message}")
            }
        }
    }

    override fun onDestroy() {
        try {
            Gobackend.cleanupExtensions()
        } catch (e: Exception) {
            android.util.Log.w("SpotiFLAC", "Failed to cleanup extensions on destroy: ${e.message}")
        }
        stopDownloadProgressStream()
        stopLibraryScanProgressStream()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Gobackend.setAppVersion(BuildConfig.VERSION_NAME)

        // Always-enabled back callback to ensure back presses reach Flutter.
        // Nested tab navigators can incorrectly set frameworkHandlesBack(false),
        // which disables Flutter's own OnBackPressedCallback and causes the
        // system default (finish activity) to run. This callback guarantees
        // popRoute is always forwarded to Flutter, where PopScope handles it.
        flutterBackCallback = object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                flutterEngine.navigationChannel.popRoute()
            }
        }
        onBackPressedDispatcher.addCallback(this, flutterBackCallback!!)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        EventChannel(
            messenger,
            DOWNLOAD_PROGRESS_STREAM_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events != null) {
                        startDownloadProgressStream(events)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    stopDownloadProgressStream()
                }
            },
        )

        EventChannel(
            messenger,
            LIBRARY_SCAN_PROGRESS_STREAM_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events != null) {
                        startLibraryScanProgressStream(events)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    stopLibraryScanProgressStream()
                }
            },
        )

        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            scope.launch {
                try {
                    when (call.method) {
                        "exitApp" -> {
                            flutterBackCallback?.isEnabled = false
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                finishAndRemoveTask()
                            } else {
                                finish()
                            }
                            result.success(null)
                        }
                        "checkAvailability" -> {
                            val spotifyId = call.argument<String>("spotify_id") ?: ""
                            val isrc = call.argument<String>("isrc") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.checkAvailability(spotifyId, isrc)
                            }
                            result.success(response)
                        }
                        "downloadByStrategy" -> {
                            val requestJson = call.arguments as String
                            val response = withContext(Dispatchers.IO) {
                                handleSafDownload(requestJson) { json ->
                                    Gobackend.downloadByStrategy(json)
                                }
                            }
                            result.success(response)
                        }
                        "getDownloadProgress" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getDownloadProgress()
                            }
                            result.success(parseJsonPayload(response))
                        }
                        "getAllDownloadProgress" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getAllDownloadProgress()
                            }
                            result.success(parseJsonPayload(response))
                        }
                        "initItemProgress" -> {
                            val itemId = call.argument<String>("item_id") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.initItemProgress(itemId)
                            }
                            result.success(null)
                        }
                        "finishItemProgress" -> {
                            val itemId = call.argument<String>("item_id") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.finishItemProgress(itemId)
                            }
                            result.success(null)
                        }
                        "clearItemProgress" -> {
                            val itemId = call.argument<String>("item_id") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.clearItemProgress(itemId)
                            }
                            result.success(null)
                        }
                        "cancelDownload" -> {
                            val itemId = call.argument<String>("item_id") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.cancelDownload(itemId)
                            }
                            result.success(null)
                        }
                        "setDownloadDirectory" -> {
                            val path = call.argument<String>("path") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.setDownloadDirectory(path)
                            }
                            result.success(null)
                        }
                        "setNetworkCompatibilityOptions", "setSongLinkNetworkOptions" -> {
                            val allowHttp = call.argument<Boolean>("allow_http") ?: false
                            val insecureTls = call.argument<Boolean>("insecure_tls") ?: false
                            withContext(Dispatchers.IO) {
                                Gobackend.setNetworkCompatibilityOptions(allowHttp, insecureTls)
                            }
                            result.success(null)
                        }
                        "checkDuplicate" -> {
                            val outputDir = call.argument<String>("output_dir") ?: ""
                            val isrc = call.argument<String>("isrc") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.checkDuplicate(outputDir, isrc)
                            }
                            result.success(response)
                        }
                        "checkDuplicatesBatch" -> {
                            val outputDir = call.argument<String>("output_dir") ?: ""
                            val tracksJson = call.argument<String>("tracks") ?: "[]"
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.checkDuplicatesBatch(outputDir, tracksJson)
                            }
                            result.success(response)
                        }
                        "preBuildDuplicateIndex" -> {
                            val outputDir = call.argument<String>("output_dir") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.preBuildDuplicateIndex(outputDir)
                            }
                            result.success(null)
                        }
                        "invalidateDuplicateIndex" -> {
                            val outputDir = call.argument<String>("output_dir") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.invalidateDuplicateIndex(outputDir)
                            }
                            result.success(null)
                        }
                        "buildFilename" -> {
                            val template = call.argument<String>("template") ?: ""
                            val metadata = call.argument<String>("metadata") ?: "{}"
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.buildFilename(template, metadata)
                            }
                            result.success(response)
                        }
                        "sanitizeFilename" -> {
                            val filename = call.argument<String>("filename") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.sanitizeFilename(filename)
                            }
                            result.success(response)
                        }
                        "pickSafTree" -> {
                            if (pendingSafTreeResult != null) {
                                result.error("saf_pending", "SAF picker already active", null)
                                return@launch
                            }
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                            intent.addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                            )
                            val resolver = intent.resolveActivity(packageManager)
                            if (resolver == null) {
                                result.error("saf_unavailable", "No folder picker available on this device", null)
                                return@launch
                            }
                            pendingSafTreeResult = result
                            try {
                                android.util.Log.i("SpotiFLAC", "Launching SAF picker via $resolver")
                                safTreeLauncher.launch(intent)
                            } catch (e: Exception) {
                                pendingSafTreeResult = null
                                android.util.Log.e("SpotiFLAC", "Failed to launch SAF picker: ${e.message}", e)
                                result.error(
                                    "saf_launch_failed",
                                    e.message ?: "Failed to launch folder picker",
                                    null
                                )
                            }
                        }
                        "safExists" -> {
                            val uriStr = call.argument<String>("uri") ?: ""
                            val exists = withContext(Dispatchers.IO) {
                                val uri = Uri.parse(uriStr)
                                DocumentFile.fromSingleUri(this@MainActivity, uri)?.exists() == true
                            }
                            result.success(exists)
                        }
                        "safDelete" -> {
                            val uriStr = call.argument<String>("uri") ?: ""
                            val deleted = withContext(Dispatchers.IO) {
                                val uri = Uri.parse(uriStr)
                                DocumentFile.fromSingleUri(this@MainActivity, uri)?.delete() == true
                            }
                            result.success(deleted)
                        }
                        "safStat" -> {
                            val uriStr = call.argument<String>("uri") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                val uri = Uri.parse(uriStr)
                                val doc = DocumentFile.fromSingleUri(this@MainActivity, uri)
                                val obj = JSONObject()
                                if (doc != null && doc.exists()) {
                                    obj.put("exists", true)
                                    obj.put("size", doc.length())
                                    obj.put("modified", doc.lastModified())
                                    obj.put("mime_type", doc.type ?: contentResolver.getType(uri) ?: "")
                                } else {
                                    obj.put("exists", false)
                                    obj.put("size", 0)
                                    obj.put("modified", 0)
                                    obj.put("mime_type", "")
                                }
                                obj.toString()
                            }
                            result.success(response)
                        }
                        "resolveSafFile" -> {
                            val treeUriStr = call.argument<String>("tree_uri") ?: ""
                            val relativeDir = call.argument<String>("relative_dir") ?: ""
                            val fileName = call.argument<String>("file_name") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                resolveSafFile(treeUriStr, relativeDir, fileName)
                            }
                            result.success(response)
                        }
                        "safCopyToTemp" -> {
                            val uriStr = call.argument<String>("uri") ?: ""
                            val tempPath = withContext(Dispatchers.IO) {
                                copyUriToTemp(Uri.parse(uriStr))
                            }
                            result.success(tempPath)
                        }
                        "safReplaceFromPath" -> {
                            val uriStr = call.argument<String>("uri") ?: ""
                            val srcPath = call.argument<String>("src_path") ?: ""
                            val ok = withContext(Dispatchers.IO) {
                                writeUriFromPath(Uri.parse(uriStr), srcPath)
                            }
                            result.success(ok)
                        }
                        "safCreateFromPath" -> {
                            val treeUriStr = call.argument<String>("tree_uri") ?: ""
                            val relativeDir = call.argument<String>("relative_dir") ?: ""
                            val fileName = sanitizeFilename(call.argument<String>("file_name") ?: "")
                            val mimeType = call.argument<String>("mime_type") ?: "application/octet-stream"
                            val srcPath = call.argument<String>("src_path") ?: ""
                            val createdUri = withContext(Dispatchers.IO) {
                                if (treeUriStr.isBlank()) return@withContext null
                                if (fileName.isBlank()) return@withContext null
                                val dir = ensureDocumentDir(Uri.parse(treeUriStr), relativeDir) ?: return@withContext null
                                val existing = dir.findFile(fileName)
                                val createdNew = existing == null
                                val doc = existing ?: dir.createFile(mimeType, fileName) ?: return@withContext null
                                if (!writeUriFromPath(doc.uri, srcPath)) {
                                    if (createdNew) {
                                        doc.delete()
                                    }
                                    return@withContext null
                                }
                                doc.uri.toString()
                            }
                            result.success(createdUri)
                        }
                        "openContentUri" -> {
                            val uriStr = call.argument<String>("uri") ?: ""
                            val mimeType = call.argument<String>("mime_type") ?: ""
                            try {
                                val uri = Uri.parse(uriStr)
                                val type = if (mimeType.isNotBlank()) mimeType else contentResolver.getType(uri) ?: "*/*"
                                val intent = Intent(Intent.ACTION_VIEW).setDataAndType(uri, type)
                                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                startActivity(intent)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("open_failed", e.message, null)
                            }
                        }
                        "shareContentUri" -> {
                            val uriStr = call.argument<String>("uri") ?: ""
                            val title = call.argument<String>("title") ?: ""
                            try {
                                val uri = Uri.parse(uriStr)
                                val type = contentResolver.getType(uri) ?: "audio/*"
                                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    setType(type)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    if (title.isNotBlank()) {
                                        putExtra(Intent.EXTRA_SUBJECT, title)
                                    }
                                }
                                startActivity(Intent.createChooser(shareIntent, title.ifBlank { "Share" }))
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("share_failed", e.message, null)
                            }
                        }
                        "shareMultipleContentUris" -> {
                            val uriStrings = call.argument<List<String>>("uris") ?: emptyList()
                            val title = call.argument<String>("title") ?: ""
                            try {
                                val uris = ArrayList<Uri>(uriStrings.size)
                                for (s in uriStrings) {
                                    uris.add(Uri.parse(s))
                                }
                                val shareIntent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                                    setType("audio/*")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    if (title.isNotBlank()) {
                                        putExtra(Intent.EXTRA_SUBJECT, title)
                                    }
                                }
                                startActivity(Intent.createChooser(shareIntent, title.ifBlank { "Share" }))
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("share_failed", e.message, null)
                            }
                        }
                        "fetchLyrics" -> {
                            val spotifyId = call.argument<String>("spotify_id") ?: ""
                            val trackName = call.argument<String>("track_name") ?: ""
                            val artistName = call.argument<String>("artist_name") ?: ""
                            val durationMs = call.argument<Int>("duration_ms")?.toLong() ?: 0L
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.fetchLyrics(spotifyId, trackName, artistName, durationMs)
                            }
                            result.success(response)
                        }
                        "getLyricsLRC" -> {
                            val spotifyId = call.argument<String>("spotify_id") ?: ""
                            val trackName = call.argument<String>("track_name") ?: ""
                            val artistName = call.argument<String>("artist_name") ?: ""
                            val filePath = call.argument<String>("file_path") ?: ""
                            val durationMs = call.argument<Int>("duration_ms")?.toLong() ?: 0L
                            val response = withContext(Dispatchers.IO) {
                                if (filePath.startsWith("content://")) {
                                    val tempPath = copyUriToTemp(Uri.parse(filePath))
                                    if (tempPath == null) {
                                        ""
                                    } else {
                                        try {
                                            Gobackend.getLyricsLRC(spotifyId, trackName, artistName, tempPath, durationMs)
                                        } finally {
                                            try {
                                                File(tempPath).delete()
                                            } catch (_: Exception) {}
                                        }
                                    }
                                } else {
                                    Gobackend.getLyricsLRC(spotifyId, trackName, artistName, filePath, durationMs)
                                }
                            }
                            result.success(response)
                        }
                        "getLyricsLRCWithSource" -> {
                            val spotifyId = call.argument<String>("spotify_id") ?: ""
                            val trackName = call.argument<String>("track_name") ?: ""
                            val artistName = call.argument<String>("artist_name") ?: ""
                            val filePath = call.argument<String>("file_path") ?: ""
                            val durationMs = call.argument<Int>("duration_ms")?.toLong() ?: 0L
                            val response = withContext(Dispatchers.IO) {
                                if (filePath.startsWith("content://")) {
                                    val tempPath = copyUriToTemp(Uri.parse(filePath))
                                    if (tempPath == null) {
                                        """{"lyrics":"","source":"","sync_type":"","instrumental":false}"""
                                    } else {
                                        try {
                                            Gobackend.getLyricsLRCWithSource(spotifyId, trackName, artistName, tempPath, durationMs)
                                        } finally {
                                            try {
                                                File(tempPath).delete()
                                            } catch (_: Exception) {}
                                        }
                                    }
                                } else {
                                    Gobackend.getLyricsLRCWithSource(spotifyId, trackName, artistName, filePath, durationMs)
                                }
                            }
                            result.success(response)
                        }
                        "embedLyricsToFile" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val lyrics = call.argument<String>("lyrics") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                if (filePath.startsWith("content://")) {
                                    val uri = Uri.parse(filePath)
                                    val tempPath = copyUriToTemp(uri, ".flac")
                                        ?: return@withContext errorJson("Failed to copy SAF file to temp")
                                    try {
                                        val raw = Gobackend.embedLyricsToFile(tempPath, lyrics)
                                        val obj = JSONObject(raw)
                                        if (!obj.optBoolean("success", false)) {
                                            return@withContext raw
                                        }

                                        if (!writeUriFromPath(uri, tempPath)) {
                                            return@withContext errorJson("Failed to write embedded lyrics back to SAF file")
                                        }

                                        obj.put("file_path", filePath)
                                        obj.toString()
                                    } catch (e: Exception) {
                                        errorJson("Failed to embed lyrics to SAF file: ${e.message}")
                                    } finally {
                                        try {
                                            File(tempPath).delete()
                                        } catch (_: Exception) {}
                                    }
                                } else {
                                    Gobackend.embedLyricsToFile(filePath, lyrics)
                                }
                            }
                            result.success(response)
                        }
                        "rewriteSplitArtistTags" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val artist = call.argument<String>("artist") ?: ""
                            val albumArtist = call.argument<String>("album_artist") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                if (filePath.startsWith("content://")) {
                                    val uri = Uri.parse(filePath)
                                    val tempPath = copyUriToTemp(uri, ".flac")
                                        ?: return@withContext errorJson("Failed to copy SAF file to temp")
                                    try {
                                        val raw = Gobackend.rewriteSplitArtistTagsExport(tempPath, artist, albumArtist)
                                        val obj = JSONObject(raw)
                                        if (!obj.optBoolean("success", false)) {
                                            return@withContext raw
                                        }

                                        if (!writeUriFromPath(uri, tempPath)) {
                                            return@withContext errorJson("Failed to write rewritten tags back to SAF file")
                                        }

                                        obj.put("file_path", filePath)
                                        obj.toString()
                                    } catch (e: Exception) {
                                        errorJson("Failed to rewrite split artist tags in SAF file: ${e.message}")
                                    } finally {
                                        try {
                                            File(tempPath).delete()
                                        } catch (_: Exception) {}
                                    }
                                } else {
                                    Gobackend.rewriteSplitArtistTagsExport(filePath, artist, albumArtist)
                                }
                            }
                            result.success(response)
                        }
                        "cleanupConnections" -> {
                            withContext(Dispatchers.IO) {
                                Gobackend.cleanupConnections()
                            }
                            result.success(null)
                        }
                        "readFileMetadata" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    if (filePath.startsWith("content://")) {
                                        val uri = Uri.parse(filePath)
                                        val tempPath = copyUriToTemp(uri)
                                            ?: return@withContext """{"error":"Failed to copy SAF file to temp"}"""
                                        try {
                                            Gobackend.readFileMetadata(tempPath)
                                        } finally {
                                            try { File(tempPath).delete() } catch (_: Exception) {}
                                        }
                                    } else {
                                        Gobackend.readFileMetadata(filePath)
                                    }
                                } catch (e: Exception) {
                                    android.util.Log.e("SpotiFLAC", "readFileMetadata failed: ${e.message}", e)
                                    """{"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        "editFileMetadata" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val metadataJson = call.argument<String>("metadata_json") ?: "{}"
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    if (filePath.startsWith("content://")) {
                                        val uri = Uri.parse(filePath)
                                        val tempPath = copyUriToTemp(uri)
                                            ?: return@withContext """{"error":"Failed to copy SAF file to temp"}"""
                                        try {
                                            val raw = Gobackend.editFileMetadata(tempPath, metadataJson)
                                            val obj = JSONObject(raw)
                                            val method = obj.optString("method", "")
                                            if (method == "ffmpeg") {
                                                // MP3/Opus: Dart needs to FFmpeg the temp file, then call writeTempToSaf
                                                obj.put("temp_path", tempPath)
                                                obj.put("saf_uri", filePath)
                                                return@withContext obj.toString()
                                                // Note: temp file NOT deleted here - Dart will clean up after FFmpeg + writeTempToSaf
                                            }
                            // FLAC: Go wrote directly to temp, copy back now
                            if (!writeUriFromPath(uri, tempPath)) {
                                try { File(tempPath).delete() } catch (_: Exception) {}
                                return@withContext """{"error":"Failed to write metadata back to SAF file"}"""
                            }
                            try { File(tempPath).delete() } catch (_: Exception) {}
                            raw
                                        } catch (e: Exception) {
                                            try { File(tempPath).delete() } catch (_: Exception) {}
                                            throw e
                                        }
                                    } else {
                                        Gobackend.editFileMetadata(filePath, metadataJson)
                                    }
                                } catch (e: Exception) {
                                    android.util.Log.e("SpotiFLAC", "editFileMetadata failed: ${e.message}", e)
                                    """{"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        "writeTempToSaf" -> {
                            val tempPath = call.argument<String>("temp_path") ?: ""
                            val safUri = call.argument<String>("saf_uri") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    val uri = Uri.parse(safUri)
                                    if (writeUriFromPath(uri, tempPath)) {
                                        """{"success":true}"""
                                    } else {
                                        """{"success":false,"error":"Failed to write back to SAF"}"""
                                    }
                                } finally {
                                    try { File(tempPath).delete() } catch (_: Exception) {}
                                }
                            }
                            result.success(response)
                        }
                        "downloadCoverToFile" -> {
                            val coverUrl = call.argument<String>("cover_url") ?: ""
                            val outputPath = call.argument<String>("output_path") ?: ""
                            val maxQuality = call.argument<Boolean>("max_quality") ?: true
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    Gobackend.downloadCoverToFile(coverUrl, outputPath, maxQuality)
                                    """{"success":true}"""
                                } catch (e: Exception) {
                                    """{"success":false,"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        "extractCoverToFile" -> {
                            val audioPath = call.argument<String>("audio_path") ?: ""
                            val outputPath = call.argument<String>("output_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    if (audioPath.startsWith("content://")) {
                                        val uri = Uri.parse(audioPath)
                                        val tempPath = copyUriToTemp(uri)
                                            ?: return@withContext """{"success":false,"error":"Failed to copy SAF file to temp"}"""
                                        try {
                                            Gobackend.extractCoverToFile(tempPath, outputPath)
                                            """{"success":true}"""
                                        } finally {
                                            try { File(tempPath).delete() } catch (_: Exception) {}
                                        }
                                    } else {
                                        Gobackend.extractCoverToFile(audioPath, outputPath)
                                        """{"success":true}"""
                                    }
                                } catch (e: Exception) {
                                    """{"success":false,"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        "fetchAndSaveLyrics" -> {
                            val trackName = call.argument<String>("track_name") ?: ""
                            val artistName = call.argument<String>("artist_name") ?: ""
                            val spotifyId = call.argument<String>("spotify_id") ?: ""
                            val durationMs = call.argument<Number>("duration_ms")?.toLong() ?: 0L
                            val outputPath = call.argument<String>("output_path") ?: ""
                            val rawAudioFilePath = call.argument<String>("audio_file_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                var safAudioTemp: String? = null
                                try {
                                    // Resolve SAF content:// URI to a temp file the Go backend can read
                                    val audioFilePath = if (rawAudioFilePath.startsWith("content://")) {
                                        val uri = Uri.parse(rawAudioFilePath)
                                        val tempPath = copyUriToTemp(uri)
                                        safAudioTemp = tempPath
                                        tempPath ?: ""
                                    } else {
                                        rawAudioFilePath
                                    }
                                    Gobackend.fetchAndSaveLyrics(trackName, artistName, spotifyId, durationMs, outputPath, audioFilePath)
                                    """{"success":true}"""
                                } catch (e: Exception) {
                                    """{"success":false,"error":"${e.message?.replace("\"", "'")}"}"""
                                } finally {
                                    if (safAudioTemp != null) {
                                        try { File(safAudioTemp).delete() } catch (_: Exception) {}
                                    }
                                }
                            }
                            result.success(response)
                        }
                        "setLyricsProviders" -> {
                            val providersJson = call.argument<String>("providers_json") ?: "[]"
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    Gobackend.setLyricsProvidersJSON(providersJson)
                                    """{"success":true}"""
                                } catch (e: Exception) {
                                    """{"success":false,"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        "getLyricsProviders" -> {
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    Gobackend.getLyricsProvidersJSON()
                                } catch (e: Exception) {
                                    "[]"
                                }
                            }
                            result.success(response)
                        }
                        "getAvailableLyricsProviders" -> {
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    Gobackend.getAvailableLyricsProvidersJSON()
                                } catch (e: Exception) {
                                    "[]"
                                }
                            }
                            result.success(response)
                        }
                        "setLyricsFetchOptions" -> {
                            val optionsJson = call.argument<String>("options_json") ?: "{}"
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    Gobackend.setLyricsFetchOptionsJSON(optionsJson)
                                    """{"success":true}"""
                                } catch (e: Exception) {
                                    """{"success":false,"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        "getLyricsFetchOptions" -> {
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    Gobackend.getLyricsFetchOptionsJSON()
                                } catch (e: Exception) {
                                    "{}"
                                }
                            }
                            result.success(response)
                        }
                        "reEnrichFile" -> {
                            val requestJson = call.argument<String>("request_json") ?: "{}"
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    val reqObj = JSONObject(requestJson)
                                    val filePath = reqObj.optString("file_path", "")

                                    if (filePath.startsWith("content://")) {
                                        val uri = Uri.parse(filePath)
                                        val tempPath = copyUriToTemp(uri)
                                            ?: return@withContext """{"error":"Failed to copy SAF file to temp"}"""
                                        try {
                                            reqObj.put("file_path", tempPath)
                                            val raw = Gobackend.reEnrichFile(reqObj.toString())
                                            val obj = JSONObject(raw)

                                            if (obj.has("error")) {
                                                return@withContext raw
                                            }

                                            val method = obj.optString("method", "")
                                            if (method == "ffmpeg") {
                                                // MP3/Opus: Dart handles FFmpeg on temp file, then writes back
                                                obj.put("temp_path", tempPath)
                                                obj.put("saf_uri", filePath)
                                                return@withContext obj.toString()
                                                // temp file NOT deleted - Dart cleans up after FFmpeg + writeTempToSaf
                                            }

                                            // FLAC: Go wrote directly to temp, copy back now
                                            if (!writeUriFromPath(uri, tempPath)) {
                                                return@withContext """{"error":"Failed to write enriched metadata back to SAF file"}"""
                                            }
                                            raw
                                        } catch (e: Exception) {
                                            try { File(tempPath).delete() } catch (_: Exception) {}
                                            throw e
                                        }
                                    } else {
                                        Gobackend.reEnrichFile(requestJson)
                                    }
                                } catch (e: Exception) {
                                    """{"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        "startDownloadService" -> {
                            val trackName = call.argument<String>("track_name") ?: ""
                            val artistName = call.argument<String>("artist_name") ?: ""
                            val queueCount = call.argument<Int>("queue_count") ?: 0
                            DownloadService.start(this@MainActivity, trackName, artistName, queueCount)
                            result.success(null)
                        }
                        "stopDownloadService" -> {
                            DownloadService.stop(this@MainActivity)
                            result.success(null)
                        }
                        "updateDownloadServiceProgress" -> {
                            val trackName = call.argument<String>("track_name") ?: ""
                            val artistName = call.argument<String>("artist_name") ?: ""
                            val progress = call.argument<Long>("progress") ?: 0L
                            val total = call.argument<Long>("total") ?: 0L
                            val queueCount = call.argument<Int>("queue_count") ?: 0
                            DownloadService.updateProgress(this@MainActivity, trackName, artistName, progress, total, queueCount)
                            result.success(null)
                        }
                        "isDownloadServiceRunning" -> {
                            result.success(DownloadService.isServiceRunning())
                        }
                        "preWarmTrackCache" -> {
                            val tracksJson = call.argument<String>("tracks") ?: "[]"
                            withContext(Dispatchers.IO) {
                                Gobackend.preWarmTrackCacheJSON(tracksJson)
                            }
                            result.success(null)
                        }
                        "getTrackCacheSize" -> {
                            val size = withContext(Dispatchers.IO) {
                                Gobackend.getTrackCacheSize()
                            }
                            result.success(size.toInt())
                        }
                        "clearTrackCache" -> {
                            withContext(Dispatchers.IO) {
                                Gobackend.clearTrackIDCache()
                            }
                            result.success(null)
                        }
                        "searchTidalAll" -> {
                            val query = call.argument<String>("query") ?: ""
                            val trackLimit = call.argument<Int>("track_limit") ?: 15
                            val artistLimit = call.argument<Int>("artist_limit") ?: 2
                            val filter = call.argument<String>("filter") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchTidalAll(query, trackLimit.toLong(), artistLimit.toLong(), filter)
                            }
                            result.success(response)
                        }
                        "searchQobuzAll" -> {
                            val query = call.argument<String>("query") ?: ""
                            val trackLimit = call.argument<Int>("track_limit") ?: 15
                            val artistLimit = call.argument<Int>("artist_limit") ?: 2
                            val filter = call.argument<String>("filter") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchQobuzAll(query, trackLimit.toLong(), artistLimit.toLong(), filter)
                            }
                            result.success(response)
                        }
                        "getDeezerRelatedArtists" -> {
                            val artistId = call.argument<String>("artist_id") ?: ""
                            val limit = call.argument<Int>("limit") ?: 12
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getDeezerRelatedArtists(artistId, limit.toLong())
                            }
                            result.success(response)
                        }
                        "getDeezerMetadata" -> {
                            val resourceType = call.argument<String>("resource_type") ?: ""
                            val resourceId = call.argument<String>("resource_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getDeezerMetadata(resourceType, resourceId)
                            }
                            result.success(response)
                        }
                        "getQobuzMetadata" -> {
                            val resourceType = call.argument<String>("resource_type") ?: ""
                            val resourceId = call.argument<String>("resource_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getQobuzMetadata(resourceType, resourceId)
                            }
                            result.success(response)
                        }
                        "getTidalMetadata" -> {
                            val resourceType = call.argument<String>("resource_type") ?: ""
                            val resourceId = call.argument<String>("resource_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getTidalMetadata(resourceType, resourceId)
                            }
                            result.success(response)
                        }
                        "parseDeezerUrl" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.parseDeezerURLExport(url)
                            }
                            result.success(response)
                        }
                        "parseQobuzUrl" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.parseQobuzURLExport(url)
                            }
                            result.success(response)
                        }
                        "parseTidalUrl" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.parseTidalURLExport(url)
                            }
                            result.success(response)
                        }
                        "convertTidalToSpotifyDeezer" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.convertTidalToSpotifyDeezer(url)
                            }
                            result.success(response)
                        }
                        "searchDeezerByISRC" -> {
                            val isrc = call.argument<String>("isrc") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchDeezerByISRC(isrc)
                            }
                            result.success(response)
                        }
                        "getDeezerExtendedMetadata" -> {
                            val trackId = call.argument<String>("track_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getDeezerExtendedMetadata(trackId)
                            }
                            result.success(response)
                        }
                        "convertSpotifyToDeezer" -> {
                            val resourceType = call.argument<String>("resource_type") ?: ""
                            val spotifyId = call.argument<String>("spotify_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.convertSpotifyToDeezer(resourceType, spotifyId)
                            }
                            result.success(response)
                        }
                        "checkAvailabilityFromDeezerID" -> {
                            val deezerTrackId = call.argument<String>("deezer_track_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.checkAvailabilityFromDeezerID(deezerTrackId)
                            }
                            result.success(response)
                        }
                        "checkAvailabilityByPlatformID" -> {
                            val platform = call.argument<String>("platform") ?: ""
                            val entityType = call.argument<String>("entity_type") ?: ""
                            val entityId = call.argument<String>("entity_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.checkAvailabilityByPlatformID(platform, entityType, entityId)
                            }
                            result.success(response)
                        }
                        "getSpotifyIDFromDeezerTrack" -> {
                            val deezerTrackId = call.argument<String>("deezer_track_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getSpotifyIDFromDeezerTrack(deezerTrackId)
                            }
                            result.success(response)
                        }
                        "getTidalURLFromDeezerTrack" -> {
                            val deezerTrackId = call.argument<String>("deezer_track_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getTidalURLFromDeezerTrack(deezerTrackId)
                            }
                            result.success(response)
                        }
                        "getLogs" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getLogs()
                            }
                            result.success(response)
                        }
                        "getLogsSince" -> {
                            val index = call.argument<Int>("index") ?: 0
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getLogsSince(index.toLong())
                            }
                            result.success(response)
                        }
                        "clearLogs" -> {
                            withContext(Dispatchers.IO) {
                                Gobackend.clearLogs()
                            }
                            result.success(null)
                        }
                        "getLogCount" -> {
                            val count = withContext(Dispatchers.IO) {
                                Gobackend.getLogCount()
                            }
                            result.success(count.toInt())
                        }
                        "setLoggingEnabled" -> {
                            val enabled = call.argument<Boolean>("enabled") ?: false
                            withContext(Dispatchers.IO) {
                                Gobackend.setLoggingEnabled(enabled)
                            }
                            result.success(null)
                        }
                        "initExtensionSystem" -> {
                            val extensionsDir = call.argument<String>("extensions_dir") ?: ""
                            val dataDir = call.argument<String>("data_dir") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.initExtensionSystem(extensionsDir, dataDir)
                            }
                            result.success(null)
                        }
                        "loadExtensionsFromDir" -> {
                            val dirPath = call.argument<String>("dir_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.loadExtensionsFromDir(dirPath)
                            }
                            result.success(response)
                        }
                        "loadExtensionFromPath" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.loadExtensionFromPath(filePath)
                            }
                            result.success(response)
                        }
                        "unloadExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.unloadExtensionByID(extensionId)
                            }
                            result.success(null)
                        }
                        "removeExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.removeExtensionByID(extensionId)
                            }
                            result.success(null)
                        }
                        "upgradeExtension" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.upgradeExtensionFromPath(filePath)
                            }
                            result.success(response)
                        }
                        "checkExtensionUpgrade" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.checkExtensionUpgradeFromPath(filePath)
                            }
                            result.success(response)
                        }
                        "getInstalledExtensions" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getInstalledExtensions()
                            }
                            result.success(response)
                        }
                        "setExtensionEnabled" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val enabled = call.argument<Boolean>("enabled") ?: false
                            withContext(Dispatchers.IO) {
                                Gobackend.setExtensionEnabledByID(extensionId, enabled)
                            }
                            result.success(null)
                        }
                        "setProviderPriority" -> {
                            val priorityJson = call.argument<String>("priority") ?: "[]"
                            withContext(Dispatchers.IO) {
                                Gobackend.setProviderPriorityJSON(priorityJson)
                            }
                            result.success(null)
                        }
                        "getProviderPriority" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getProviderPriorityJSON()
                            }
                            result.success(response)
                        }
                        "setDownloadFallbackExtensionIds" -> {
                            val extensionIdsJson = call.argument<String>("extension_ids") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.setExtensionFallbackProviderIDsJSON(extensionIdsJson)
                            }
                            result.success(null)
                        }
                        "setMetadataProviderPriority" -> {
                            val priorityJson = call.argument<String>("priority") ?: "[]"
                            withContext(Dispatchers.IO) {
                                Gobackend.setMetadataProviderPriorityJSON(priorityJson)
                            }
                            result.success(null)
                        }
                        "getMetadataProviderPriority" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getMetadataProviderPriorityJSON()
                            }
                            result.success(response)
                        }
                        "getExtensionSettings" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getExtensionSettingsJSON(extensionId)
                            }
                            result.success(response)
                        }
                        "setExtensionSettings" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val settingsJson = call.argument<String>("settings") ?: "{}"
                            withContext(Dispatchers.IO) {
                                Gobackend.setExtensionSettingsJSON(extensionId, settingsJson)
                            }
                            result.success(null)
                        }
                        "invokeExtensionAction" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val actionName = call.argument<String>("action") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.invokeExtensionActionJSON(extensionId, actionName)
                            }
                            result.success(response)
                        }
                        "searchTracksWithExtensions" -> {
                            val query = call.argument<String>("query") ?: ""
                            val limit = call.argument<Int>("limit") ?: 20
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchTracksWithExtensionsJSON(query, limit.toLong())
                            }
                            result.success(response)
                        }
                        "searchTracksWithMetadataProviders" -> {
                            val query = call.argument<String>("query") ?: ""
                            val limit = call.argument<Int>("limit") ?: 20
                            val includeExtensions = call.argument<Boolean>("include_extensions") ?: true
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchTracksWithMetadataProvidersJSON(query, limit.toLong(), includeExtensions)
                            }
                            result.success(response)
                        }
                        "enrichTrackWithExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val trackJson = call.argument<String>("track") ?: "{}"
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.enrichTrackWithExtensionJSON(extensionId, trackJson)
                            }
                            result.success(response)
                        }
                        "cleanupExtensions" -> {
                            withContext(Dispatchers.IO) {
                                Gobackend.cleanupExtensions()
                            }
                            result.success(null)
                        }
                        "getExtensionPendingAuth" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getExtensionPendingAuthJSON(extensionId)
                            }
                            if (response.isNullOrEmpty()) {
                                result.success(null)
                            } else {
                                result.success(response)
                            }
                        }
                        "setExtensionAuthCode" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val authCode = call.argument<String>("auth_code") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.setExtensionAuthCodeByID(extensionId, authCode)
                            }
                            result.success(null)
                        }
                        "setExtensionTokens" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val accessToken = call.argument<String>("access_token") ?: ""
                            val refreshToken = call.argument<String>("refresh_token") ?: ""
                            val expiresIn = call.argument<Int>("expires_in") ?: 0
                            withContext(Dispatchers.IO) {
                                Gobackend.setExtensionTokensByID(extensionId, accessToken, refreshToken, expiresIn.toLong())
                            }
                            result.success(null)
                        }
                        "clearExtensionPendingAuth" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.clearExtensionPendingAuthByID(extensionId)
                            }
                            result.success(null)
                        }
                        "isExtensionAuthenticated" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val isAuth = withContext(Dispatchers.IO) {
                                Gobackend.isExtensionAuthenticatedByID(extensionId)
                            }
                            result.success(isAuth)
                        }
                        "getAllPendingAuthRequests" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getAllPendingAuthRequestsJSON()
                            }
                            result.success(response)
                        }
                        "getPendingFFmpegCommand" -> {
                            val commandId = call.argument<String>("command_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getPendingFFmpegCommandJSON(commandId)
                            }
                            if (response.isNullOrEmpty()) {
                                result.success(null)
                            } else {
                                result.success(response)
                            }
                        }
                        "setFFmpegCommandResult" -> {
                            val commandId = call.argument<String>("command_id") ?: ""
                            val success = call.argument<Boolean>("success") ?: false
                            val output = call.argument<String>("output") ?: ""
                            val error = call.argument<String>("error") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.setFFmpegCommandResultByID(commandId, success, output, error)
                            }
                            result.success(null)
                        }
                        "getAllPendingFFmpegCommands" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getAllPendingFFmpegCommandsJSON()
                            }
                            result.success(response)
                        }
                        "customSearchWithExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val query = call.argument<String>("query") ?: ""
                            val optionsJson = call.argument<String>("options") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.customSearchWithExtensionJSON(extensionId, query, optionsJson)
                            }
                            result.success(response)
                        }
                        "getSearchProviders" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getSearchProvidersJSON()
                            }
                            result.success(response)
                        }
                        "handleURLWithExtension" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.handleURLWithExtensionJSON(url)
                            }
                            result.success(response)
                        }
                        "findURLHandler" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.findURLHandlerJSON(url)
                            }
                            result.success(response)
                        }
                        "getURLHandlers" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getURLHandlersJSON()
                            }
                            result.success(response)
                        }
                        "getAlbumWithExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val albumId = call.argument<String>("album_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getAlbumWithExtensionJSON(extensionId, albumId)
                            }
                            result.success(response)
                        }
                        "getPlaylistWithExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val playlistId = call.argument<String>("playlist_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getPlaylistWithExtensionJSON(extensionId, playlistId)
                            }
                            result.success(response)
                        }
                        "getArtistWithExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val artistId = call.argument<String>("artist_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getArtistWithExtensionJSON(extensionId, artistId)
                            }
                            result.success(response)
                        }
                        "runPostProcessing" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val metadataJson = call.argument<String>("metadata") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                if (filePath.startsWith("content://")) {
                                    runPostProcessingSaf(filePath, metadataJson)
                                } else {
                                    Gobackend.runPostProcessingJSON(filePath, metadataJson)
                                }
                            }
                            result.success(response)
                        }
                        "runPostProcessingV2" -> {
                            val inputJson = call.argument<String>("input") ?: ""
                            val metadataJson = call.argument<String>("metadata") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                val inputObj = if (inputJson.isNotBlank()) JSONObject(inputJson) else JSONObject()
                                val uriStr = inputObj.optString("uri", "")
                                val pathStr = inputObj.optString("path", "")
                                val effectiveUri = when {
                                    uriStr.startsWith("content://") -> uriStr
                                    pathStr.startsWith("content://") -> pathStr
                                    else -> ""
                                }

                                if (effectiveUri.isNotBlank()) {
                                    runPostProcessingSafV2(effectiveUri, metadataJson)
                                } else {
                                    if (pathStr.isNotBlank()) {
                                        inputObj.put("name", File(pathStr).name)
                                        inputObj.put("is_saf", false)
                                    }
                                    Gobackend.runPostProcessingV2JSON(inputObj.toString(), metadataJson)
                                }
                            }
                            result.success(response)
                        }
                        "getPostProcessingProviders" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getPostProcessingProvidersJSON()
                            }
                            result.success(response)
                        }
                        "initExtensionStore" -> {
                            val cacheDir = call.argument<String>("cache_dir") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.initExtensionStoreJSON(cacheDir)
                            }
                            result.success(null)
                        }
                        "setStoreRegistryUrl" -> {
                            val registryUrl = call.argument<String>("registry_url") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.setStoreRegistryURLJSON(registryUrl)
                            }
                            result.success(null)
                        }
                        "getStoreRegistryUrl" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getStoreRegistryURLJSON()
                            }
                            result.success(response)
                        }
                        "clearStoreRegistryUrl" -> {
                            withContext(Dispatchers.IO) {
                                Gobackend.clearStoreRegistryURLJSON()
                            }
                            result.success(null)
                        }
                        "getStoreExtensions" -> {
                            val forceRefresh = call.argument<Boolean>("force_refresh") ?: false
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getStoreExtensionsJSON(forceRefresh)
                            }
                            result.success(response)
                        }
                        "searchStoreExtensions" -> {
                            val query = call.argument<String>("query") ?: ""
                            val category = call.argument<String>("category") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchStoreExtensionsJSON(query, category)
                            }
                            result.success(response)
                        }
                        "getStoreCategories" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getStoreCategoriesJSON()
                            }
                            result.success(response)
                        }
                        "downloadStoreExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val destDir = call.argument<String>("dest_dir") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.downloadStoreExtensionJSON(extensionId, destDir)
                            }
                            result.success(response)
                        }
                        "clearStoreCache" -> {
                            withContext(Dispatchers.IO) {
                                Gobackend.clearStoreCacheJSON()
                            }
                            result.success(null)
                        }
                        "getExtensionHomeFeed" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getExtensionHomeFeedJSON(extensionId)
                            }
                            result.success(response)
                        }
                        "getExtensionBrowseCategories" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getExtensionBrowseCategoriesJSON(extensionId)
                            }
                            result.success(response)
                        }
                        "setLibraryCoverCacheDir" -> {
                            val cacheDir = call.argument<String>("cache_dir") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.setLibraryCoverCacheDirJSON(cacheDir)
                            }
                            result.success(null)
                        }
                        "scanLibraryFolder" -> {
                            val folderPath = call.argument<String>("folder_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                safScanActive = false
                                Gobackend.scanLibraryFolderJSON(folderPath)
                            }
                            result.success(response)
                        }
                        "scanLibraryFolderIncremental" -> {
                            val folderPath = call.argument<String>("folder_path") ?: ""
                            val existingFiles = call.argument<String>("existing_files") ?: "{}"
                            val response = withContext(Dispatchers.IO) {
                                safScanActive = false
                                Gobackend.scanLibraryFolderIncrementalJSON(folderPath, existingFiles)
                            }
                            result.success(response)
                        }
                        "scanLibraryFolderIncrementalFromSnapshot" -> {
                            val folderPath = call.argument<String>("folder_path") ?: ""
                            val snapshotPath = call.argument<String>("snapshot_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                safScanActive = false
                                Gobackend.scanLibraryFolderIncrementalFromSnapshotJSON(
                                    folderPath,
                                    snapshotPath,
                                )
                            }
                            result.success(response)
                        }
                        "scanSafTree" -> {
                            val treeUri = call.argument<String>("tree_uri") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                scanSafTree(treeUri)
                            }
                            result.success(response)
                        }
                        "scanSafTreeIncremental" -> {
                            val treeUri = call.argument<String>("tree_uri") ?: ""
                            val existingFiles = call.argument<String>("existing_files") ?: "{}"
                            val response = withContext(Dispatchers.IO) {
                                scanSafTreeIncremental(treeUri, existingFiles)
                            }
                            result.success(response)
                        }
                        "scanSafTreeIncrementalFromSnapshot" -> {
                            val treeUri = call.argument<String>("tree_uri") ?: ""
                            val snapshotPath = call.argument<String>("snapshot_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                val existingFilesJson =
                                    loadExistingFilesJsonFromSnapshot(snapshotPath)
                                scanSafTreeIncremental(treeUri, existingFilesJson)
                            }
                            result.success(response)
                        }
                        "getSafFileModTimes" -> {
                            val uris = call.argument<String>("uris") ?: "[]"
                            val response = withContext(Dispatchers.IO) {
                                getSafFileModTimes(uris)
                            }
                            result.success(response)
                        }
                        "getLibraryScanProgress" -> {
                            val response = withContext(Dispatchers.IO) {
                                if (safScanActive) {
                                    safProgressToJson()
                                } else {
                                    Gobackend.getLibraryScanProgressJSON()
                                }
                            }
                            result.success(parseJsonPayload(response))
                        }
                        "cancelLibraryScan" -> {
                            withContext(Dispatchers.IO) {
                                safScanCancel = true
                                Gobackend.cancelLibraryScanJSON()
                            }
                            result.success(null)
                        }
                        "readAudioMetadata" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    if (filePath.startsWith("content://")) {
                                        val uri = Uri.parse(filePath)
                                        val metadata = readAudioMetadataFromUri(uri)
                                            ?: return@withContext """{"error":"Failed to read SAF audio metadata"}"""
                                        metadata.put("filePath", filePath)
                                        metadata.toString()
                                    } else {
                                        Gobackend.readAudioMetadataJSON(filePath)
                                    }
                                } catch (e: Exception) {
                                    """{"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        "parseCueSheet" -> {
                            val cuePath = call.argument<String>("cue_path") ?: ""
                            val audioDir = call.argument<String>("audio_dir") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                try {
                                    if (cuePath.startsWith("content://")) {
                                        val uri = Uri.parse(cuePath)
                                        val tempCuePath = copyUriToTemp(uri, ".cue")
                                            ?: return@withContext """{"error":"Failed to copy CUE file to temp"}"""
                                        var tempAudioPath: String? = null
                                        try {
                                            val audioFileName = extractCueAudioFileName(tempCuePath)

                                            var audioDoc: DocumentFile? = null
                                            val parentDir = safParentDir(uri)
                                            if (parentDir != null && !audioFileName.isNullOrBlank()) {
                                                audioDoc = try { parentDir.findFile(audioFileName) } catch (_: Exception) { null }
                                            }

                                            if (audioDoc == null && parentDir != null) {
                                                val cueName = try {
                                                    DocumentFile.fromSingleUri(this@MainActivity, uri)?.name ?: ""
                                                } catch (_: Exception) { "" }
                                                val cueBaseName = cueName.substringBeforeLast('.')
                                                if (cueBaseName.isNotBlank()) {
                                                    val commonExts = listOf(".flac", ".wav", ".ape", ".mp3", ".ogg", ".wv", ".m4a")
                                                    for (ext in commonExts) {
                                                        audioDoc = try { parentDir.findFile(cueBaseName + ext) } catch (_: Exception) { null }
                                                        if (audioDoc != null) break
                                                        audioDoc = try { parentDir.findFile(cueBaseName + ext.uppercase(Locale.ROOT)) } catch (_: Exception) { null }
                                                        if (audioDoc != null) break
                                                    }
                                                }
                                            }

                                            val tempDir = File(tempCuePath).parent ?: cacheDir.absolutePath
                                            if (audioDoc != null) {
                                                val audioName = try { audioDoc.name ?: "audio.flac" } catch (_: Exception) { "audio.flac" }
                                                val audioExt = audioName.substringAfterLast('.', "").lowercase(Locale.ROOT)
                                                val fallbackExt = if (audioExt.isNotBlank()) ".$audioExt" else null
                                                val copiedAudio = copyUriToTemp(audioDoc.uri, fallbackExt)
                                                if (copiedAudio != null) {
                                                    val renamedAudio = File(tempDir, audioName)
                                                    val copiedFile = File(copiedAudio)
                                                    if (renamedAudio.absolutePath != copiedFile.absolutePath) {
                                                        copiedFile.renameTo(renamedAudio)
                                                    }
                                                    tempAudioPath = renamedAudio.absolutePath
                                                }
                                            }

                                            val resultJson = Gobackend.parseCueSheet(tempCuePath, tempDir)

                                            if (audioDoc != null) {
                                                val resultObj = JSONObject(resultJson)
                                                resultObj.put("audio_path", audioDoc.uri.toString())
                                                resultObj.put("cue_path", cuePath)
                                                resultObj.toString()
                                            } else {
                                                resultJson
                                            }
                                        } finally {
                                            try { File(tempCuePath).delete() } catch (_: Exception) {}
                                            try { tempAudioPath?.let { File(it).delete() } } catch (_: Exception) {}
                                        }
                                    } else {
                                        Gobackend.parseCueSheet(cuePath, audioDir)
                                    }
                                } catch (e: Exception) {
                                    """{"error":"${e.message?.replace("\"", "'")}"}"""
                                }
                            }
                            result.success(response)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }
}
