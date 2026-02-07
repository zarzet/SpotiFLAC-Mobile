package com.zarz.spotiflac

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodChannel
import gobackend.Gobackend
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.Locale

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.zarz.spotiflac/backend"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var pendingSafTreeResult: MethodChannel.Result? = null
    private val safScanLock = Any()
    private var safScanProgress = SafScanProgress()
    @Volatile private var safScanCancel = false
    @Volatile private var safScanActive = false
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

    data class SafScanProgress(
        var totalFiles: Int = 0,
        var scannedFiles: Int = 0,
        var currentFile: String = "",
        var errorCount: Int = 0,
        var progressPct: Double = 0.0,
        var isComplete: Boolean = false,
    )

    companion object {
        // Minimum API level we consider "safe" for Impeller (Android 10+)
        private const val SAFE_API_FOR_IMPELLER = 29
        
        // Known problematic GPU patterns (lowercase)
        private val PROBLEMATIC_GPU_PATTERNS = listOf(
            "adreno (tm) 3",   // Adreno 300 series (305, 320, 330, etc.) - old Qualcomm
            "adreno (tm) 4",   // Adreno 400 series - some have issues
            "mali-4",          // Mali-400 series - old ARM GPUs
            "mali-t6",         // Mali-T600 series
            "mali-t7",         // Mali-T700 series (some)
            "powervr sgx",     // PowerVR SGX series - old Imagination GPUs
            "powervr ge8320",  // PowerVR GE8320 - known issues
            "gc1000",          // Vivante GC1000
            "gc2000",          // Vivante GC2000
        )
        
        // Known problematic chipsets/hardware (lowercase)
        private val PROBLEMATIC_CHIPSETS = listOf(
            "mt6762",   // MediaTek Helio P22 with PowerVR GE8320
            "mt6765",   // MediaTek Helio P35 with PowerVR GE8320
            "mt8768",   // MediaTek tablet chip
            "mp0873",   // MediaTek variant
            "msm8974",  // Snapdragon 800/801 with Adreno 330
            "msm8226",  // Snapdragon 400 with Adreno 305
            "msm8926",  // Snapdragon 400 with Adreno 305
            "apq8084",  // Snapdragon 805 (some issues)
        )
        
        // Known problematic device models (lowercase)
        private val PROBLEMATIC_MODELS = listOf(
            "sm-t220",      // Samsung Tab A7 Lite
            "sm-t225",      // Samsung Tab A7 Lite LTE
            "hammerhead",   // Nexus 5 (Adreno 330)
        )
        /**
         * Check if device should use Skia instead of Impeller.
         * Returns true for devices with old/problematic GPUs or old Android versions.
         */
        private fun shouldDisableImpeller(): Boolean {
            val hardware = Build.HARDWARE.lowercase(Locale.ROOT)
            val board = Build.BOARD.lowercase(Locale.ROOT)
            val model = Build.MODEL.lowercase(Locale.ROOT)
            val device = Build.DEVICE.lowercase(Locale.ROOT)

            // 1. Check for explicitly problematic device models
            for (problematicModel in PROBLEMATIC_MODELS) {
                if (model.contains(problematicModel) || device.contains(problematicModel)) {
                    android.util.Log.i("SpotiFLAC", "Matched problematic model: $problematicModel")
                    return true
                }
            }

            // 2. Check for problematic chipsets
            for (chipset in PROBLEMATIC_CHIPSETS) {
                if (hardware.contains(chipset) || board.contains(chipset)) {
                    android.util.Log.i("SpotiFLAC", "Matched problematic chipset: $chipset")
                    return true
                }
            }

            // 3. For Android < 10 (API 29), be more aggressive about disabling Impeller
            if (Build.VERSION.SDK_INT < SAFE_API_FOR_IMPELLER) {
                // For older Android, check GPU renderer if available
                val gpuRenderer = getGpuRenderer().lowercase(Locale.ROOT)

                // Check for known problematic GPUs
                for (pattern in PROBLEMATIC_GPU_PATTERNS) {
                    if (gpuRenderer.contains(pattern)) {
                        android.util.Log.i("SpotiFLAC", "Matched problematic GPU on old Android: $pattern")
                        return true
                    }
                }

                // For very old Android (< 8.0), always use Skia as Vulkan support is spotty
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    android.util.Log.i("SpotiFLAC", "Android < 8.0, using Skia for safety")
                    return true
                }
            }

            // 4. For Android 10+, still check for known problematic GPUs
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
     * Try to get GPU renderer string.
     * Note: This may return empty on some devices before OpenGL context is created.
     */
        private fun getGpuRenderer(): String {
            return try {
                // This might not work before GL context is created,
                // but worth trying for additional detection
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
            else -> "application/octet-stream"
        }
    }

    private fun sanitizeFilename(name: String): String {
        return name.replace(Regex("[\\\\/:*?\"<>|]"), "_").trim()
    }

    private fun ensureDocumentDir(treeUri: Uri, relativeDir: String): DocumentFile? {
        var current = DocumentFile.fromTreeUri(this, treeUri) ?: return null
        if (relativeDir.isBlank()) return current

        val parts = relativeDir.split("/").filter { it.isNotBlank() }
        for (part in parts) {
            val existing = current.findFile(part)
            current = if (existing != null && existing.isDirectory) {
                existing
            } else {
                current.createDirectory(part) ?: return null
            }
        }
        return current
    }

    private fun findDocumentDir(treeUri: Uri, relativeDir: String): DocumentFile? {
        var current = DocumentFile.fromTreeUri(this, treeUri) ?: return null
        if (relativeDir.isBlank()) return current

        val parts = relativeDir.split("/").filter { it.isNotBlank() }
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

    private fun resolveSafFile(treeUriStr: String, relativeDir: String, fileName: String): String {
        val obj = JSONObject()
        if (treeUriStr.isBlank() || fileName.isBlank()) {
            obj.put("uri", "")
            obj.put("relative_dir", "")
            return obj.toString()
        }

        val treeUri = Uri.parse(treeUriStr)
        val targetDir = findDocumentDir(treeUri, relativeDir)
        if (targetDir != null) {
            val direct = targetDir.findFile(fileName)
            if (direct != null && direct.isFile) {
                obj.put("uri", direct.uri.toString())
                obj.put("relative_dir", relativeDir)
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
                    if (child.name == fileName) {
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
        if (provided.isNotBlank()) return provided

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

    private fun copyUriToTemp(uri: Uri, fallbackExt: String? = null): String? {
        val mime = contentResolver.getType(uri)
        val nameHint = (
            DocumentFile.fromSingleUri(this, uri)?.name
                ?: uri.lastPathSegment
                ?: ""
        ).lowercase(Locale.ROOT)
        val extFromName = when {
            nameHint.endsWith(".m4a") -> ".m4a"
            nameHint.endsWith(".mp3") -> ".mp3"
            nameHint.endsWith(".opus") -> ".opus"
            nameHint.endsWith(".flac") -> ".flac"
            else -> ""
        }
        val extFromMime = when (mime) {
            "audio/mp4" -> ".m4a"
            "audio/mpeg" -> ".mp3"
            "audio/ogg" -> ".opus"
            "audio/flac" -> ".flac"
            else -> ""
        }
        val ext = if (extFromName.isNotBlank()) extFromName else if (extFromMime.isNotBlank()) extFromMime else (fallbackExt ?: "")
        val suffix: String? = if (ext.isNotBlank()) ext else null
        val tempFile = File.createTempFile("saf_", suffix, cacheDir)
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(tempFile).use { output ->
                input.copyTo(output)
            }
        } ?: return null
        return tempFile.absolutePath
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
        val relativeDir = req.optString("saf_relative_dir", "")
        val outputExt = normalizeExt(req.optString("saf_output_ext", ""))
        val mimeType = mimeTypeForExt(outputExt)
        val targetDir = ensureDocumentDir(treeUri, relativeDir)
            ?: return errorJson("Failed to access SAF directory")

        val fileName = buildSafFileName(req, outputExt)
        val existing = targetDir.findFile(fileName)
        if (existing != null && existing.isFile && existing.length() > 0) {
            val obj = JSONObject()
            obj.put("success", true)
            obj.put("message", "File already exists")
            obj.put("file_path", existing.uri.toString())
            obj.put("file_name", existing.name ?: fileName)
            obj.put("already_exists", true)
            return obj.toString()
        }

        val document = existing ?: targetDir.createFile(mimeType, fileName)
            ?: return errorJson("Failed to create SAF file")

        val pfd = contentResolver.openFileDescriptor(document.uri, "rw")
            ?: return errorJson("Failed to open SAF file")
        var detachedFd: Int? = null

        try {
            detachedFd = pfd.detachFd()
            req.put("output_path", "/proc/self/fd/$detachedFd")
            req.put("output_fd", detachedFd)
            req.put("output_ext", outputExt)
            val response = downloader(req.toString())
            val respObj = JSONObject(response)
            if (respObj.optBoolean("success", false)) {
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
            if (detachedFd == null) {
                try {
                    pfd.close()
                } catch (_: Exception) {}
            }
        }
    }

    private fun scanSafTree(treeUriStr: String): String {
        if (treeUriStr.isBlank()) return "[]"

        val treeUri = Uri.parse(treeUriStr)
        val root = DocumentFile.fromTreeUri(this, treeUri) ?: return "[]"

        resetSafScanProgress()
        safScanCancel = false
        safScanActive = true

        val supportedExt = setOf(".flac", ".m4a", ".mp3", ".opus", ".ogg")
        val audioFiles = mutableListOf<Pair<DocumentFile, String>>()

        val queue: ArrayDeque<Pair<DocumentFile, String>> = ArrayDeque()
        queue.add(root to "")

        while (queue.isNotEmpty()) {
            if (safScanCancel) {
                updateSafScanProgress { it.isComplete = true }
                return "[]"
            }

            val (dir, path) = queue.removeFirst()
            for (child in dir.listFiles()) {
                if (safScanCancel) {
                    updateSafScanProgress { it.isComplete = true }
                    return "[]"
                }

                if (child.isDirectory) {
                    val childName = child.name ?: continue
                    val childPath = if (path.isBlank()) childName else "$path/$childName"
                    queue.add(child to childPath)
                } else if (child.isFile) {
                    val name = child.name ?: continue
                    val ext = name.substringAfterLast('.', "").lowercase(Locale.ROOT)
                    if (ext.isNotBlank() && supportedExt.contains(".$ext")) {
                        audioFiles.add(child to path)
                    }
                }
            }
        }

        updateSafScanProgress {
            it.totalFiles = audioFiles.size
        }

        if (audioFiles.isEmpty()) {
            updateSafScanProgress {
                it.isComplete = true
                it.progressPct = 100.0
            }
            return "[]"
        }

        val results = JSONArray()
        var scanned = 0
        var errors = 0

        for ((doc, _) in audioFiles) {
            if (safScanCancel) {
                updateSafScanProgress { it.isComplete = true }
                return "[]"
            }

            val name = doc.name ?: ""
            updateSafScanProgress {
                it.currentFile = name
            }

            val ext = name.substringAfterLast('.', "").lowercase(Locale.ROOT)
            val fallbackExt = if (ext.isNotBlank()) ".${ext}" else null
            val tempPath = copyUriToTemp(doc.uri, fallbackExt)
            if (tempPath == null) {
                errors++
            } else {
                try {
                    val metadataJson = Gobackend.readAudioMetadataJSON(tempPath)
                    if (metadataJson.isNotBlank()) {
                        val obj = JSONObject(metadataJson)
                        val lastModified = doc.lastModified()
                        obj.put("filePath", doc.uri.toString())
                        obj.put("fileModTime", lastModified)
                        results.put(obj)
                    } else {
                        errors++
                    }
                } catch (_: Exception) {
                    errors++
                } finally {
                    try {
                        File(tempPath).delete()
                    } catch (_: Exception) {}
                }
            }

            scanned++
            val pct = scanned.toDouble() / audioFiles.size.toDouble() * 100.0
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

        // Parse existing files map: URI -> lastModified
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

        val supportedExt = setOf(".flac", ".m4a", ".mp3", ".opus", ".ogg")
        val audioFiles = mutableListOf<Triple<DocumentFile, String, Long>>() // doc, path, lastModified
        val currentUris = mutableSetOf<String>()

        // Collect all audio files with lastModified
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
            for (child in dir.listFiles()) {
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

                if (child.isDirectory) {
                    val childName = child.name ?: continue
                    val childPath = if (path.isBlank()) childName else "$path/$childName"
                    queue.add(child to childPath)
                } else if (child.isFile) {
                    val name = child.name ?: continue
                    val ext = name.substringAfterLast('.', "").lowercase(Locale.ROOT)
                    if (ext.isNotBlank() && supportedExt.contains(".$ext")) {
                        val uriStr = child.uri.toString()
                        val lastModified = child.lastModified()
                        currentUris.add(uriStr)
                        
                        // Check if file is new or modified
                        val existingModified = existingFiles[uriStr]
                        if (existingModified == null || existingModified != lastModified) {
                            audioFiles.add(Triple(child, path, lastModified))
                        }
                    }
                }
            }
        }

        // Find removed files (in existing but not in current)
        val removedUris = existingFiles.keys.filter { !currentUris.contains(it) }
        val totalFiles = currentUris.size
        val skippedCount = (totalFiles - audioFiles.size).coerceAtLeast(0)

        updateSafScanProgress {
            it.totalFiles = totalFiles
        }

        if (audioFiles.isEmpty()) {
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
        var errors = 0

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

            val name = doc.name ?: ""
            updateSafScanProgress {
                it.currentFile = name
            }

            val ext = name.substringAfterLast('.', "").lowercase(Locale.ROOT)
            val fallbackExt = if (ext.isNotBlank()) ".${ext}" else null
            val tempPath = copyUriToTemp(doc.uri, fallbackExt)
            if (tempPath == null) {
                errors++
            } else {
                try {
                    val metadataJson = Gobackend.readAudioMetadataJSON(tempPath)
                    if (metadataJson.isNotBlank()) {
                        val obj = JSONObject(metadataJson)
                        obj.put("filePath", doc.uri.toString())
                        obj.put("fileModTime", lastModified)
                        obj.put("lastModified", lastModified)
                        results.put(obj)
                    } else {
                        errors++
                    }
                } catch (_: Exception) {
                    errors++
                } finally {
                    try {
                        File(tempPath).delete()
                    } catch (_: Exception) {}
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

        updateSafScanProgress {
            it.isComplete = true
            it.progressPct = 100.0
        }

        val result = JSONObject()
        result.put("files", results)
        result.put("removedUris", JSONArray(removedUris))
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Update the intent so receive_sharing_intent can access the new data
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            scope.launch {
                try {
                    when (call.method) {
                        "parseSpotifyUrl" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.parseSpotifyURL(url)
                            }
                            result.success(response)
                        }
                        "getSpotifyMetadata" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getSpotifyMetadata(url)
                            }
                            result.success(response)
                        }
                        "searchSpotify" -> {
                            val query = call.argument<String>("query") ?: ""
                            val limit = call.argument<Int>("limit") ?: 10
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchSpotify(query, limit.toLong())
                            }
                            result.success(response)
                        }
                        "searchSpotifyAll" -> {
                            val query = call.argument<String>("query") ?: ""
                            val trackLimit = call.argument<Int>("track_limit") ?: 15
                            val artistLimit = call.argument<Int>("artist_limit") ?: 3
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchSpotifyAll(query, trackLimit.toLong(), artistLimit.toLong())
                            }
                            result.success(response)
                        }
                        "checkAvailability" -> {
                            val spotifyId = call.argument<String>("spotify_id") ?: ""
                            val isrc = call.argument<String>("isrc") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.checkAvailability(spotifyId, isrc)
                            }
                            result.success(response)
                        }
                        "downloadTrack" -> {
                            val requestJson = call.arguments as String
                            val response = withContext(Dispatchers.IO) {
                                handleSafDownload(requestJson) { json ->
                                    Gobackend.downloadTrack(json)
                                }
                            }
                            result.success(response)
                        }
                        "downloadWithFallback" -> {
                            val requestJson = call.arguments as String
                            val response = withContext(Dispatchers.IO) {
                                handleSafDownload(requestJson) { json ->
                                    Gobackend.downloadWithFallback(json)
                                }
                            }
                            result.success(response)
                        }
                        "getDownloadProgress" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getDownloadProgress()
                            }
                            result.success(response)
                        }
                        "getAllDownloadProgress" -> {
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getAllDownloadProgress()
                            }
                            result.success(response)
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
                            pendingSafTreeResult = result
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                            intent.addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                            )
                            safTreeLauncher.launch(intent)
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
                            val fileName = call.argument<String>("file_name") ?: ""
                            val mimeType = call.argument<String>("mime_type") ?: "application/octet-stream"
                            val srcPath = call.argument<String>("src_path") ?: ""
                            val createdUri = withContext(Dispatchers.IO) {
                                if (treeUriStr.isBlank()) return@withContext null
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
                        "cleanupConnections" -> {
                            withContext(Dispatchers.IO) {
                                Gobackend.cleanupConnections()
                            }
                            result.success(null)
                        }
                        "readFileMetadata" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.readFileMetadata(filePath)
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
                        "setSpotifyCredentials" -> {
                            val clientId = call.argument<String>("client_id") ?: ""
                            val clientSecret = call.argument<String>("client_secret") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.setSpotifyAPICredentials(clientId, clientSecret)
                            }
                            result.success(null)
                        }
                        "hasSpotifyCredentials" -> {
                            val hasCredentials = withContext(Dispatchers.IO) {
                                Gobackend.checkSpotifyCredentials()
                            }
                            result.success(hasCredentials)
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
                        // Deezer API methods
                        "searchDeezerAll" -> {
                            val query = call.argument<String>("query") ?: ""
                            val trackLimit = call.argument<Int>("track_limit") ?: 15
                            val artistLimit = call.argument<Int>("artist_limit") ?: 2
                            val filter = call.argument<String>("filter") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchDeezerAll(query, trackLimit.toLong(), artistLimit.toLong(), filter)
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
                        "parseDeezerUrl" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.parseDeezerURLExport(url)
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
                        "getSpotifyMetadataWithFallback" -> {
                            val url = call.argument<String>("url") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getSpotifyMetadataWithDeezerFallback(url)
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
                        "getAmazonURLFromDeezerTrack" -> {
                            val deezerTrackId = call.argument<String>("deezer_track_id") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getAmazonURLFromDeezerTrack(deezerTrackId)
                            }
                            result.success(response)
                        }
                        // Log methods
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
                        // Extension System methods
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
                        "downloadWithExtensions" -> {
                            val requestJson = call.arguments as String
                            val response = withContext(Dispatchers.IO) {
                                handleSafDownload(requestJson) { json ->
                                    Gobackend.downloadWithExtensionsJSON(json)
                                }
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
                        // Extension Auth API methods
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
                        // Extension FFmpeg API
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
                        // Extension Custom Search API
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
                        // Extension URL Handler API
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
                        // Extension Post-Processing API
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
                        // Extension Store
                        "initExtensionStore" -> {
                            val cacheDir = call.argument<String>("cache_dir") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.initExtensionStoreJSON(cacheDir)
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
                        // Extension Home Feed (Explore)
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
                        // Local Library Scanning
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
                            result.success(response)
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
                                Gobackend.readAudioMetadataJSON(filePath)
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
