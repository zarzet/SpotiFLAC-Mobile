package com.zarz.spotiflac

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import gobackend.Gobackend
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.zarz.spotiflac/backend"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

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
    }

    /**
     * Override Flutter shell args to disable Impeller on problematic devices.
     * This is called before the Flutter engine starts.
     */
    override fun getFlutterShellArgs(): FlutterShellArgs {
        val args = super.getFlutterShellArgs()
        
        if (shouldDisableImpeller()) {
            // Log for debugging
            android.util.Log.i("SpotiFLAC", "Legacy/problematic GPU detected: Disabling Impeller for ${Build.MODEL}")
            android.util.Log.i("SpotiFLAC", "Device: ${Build.MANUFACTURER} ${Build.MODEL}, SDK: ${Build.VERSION.SDK_INT}")
            android.util.Log.i("SpotiFLAC", "Hardware: ${Build.HARDWARE}, Board: ${Build.BOARD}")
            
            // Disable Impeller, forcing Skia renderer
            args.add("--enable-impeller=false")
        } else {
            android.util.Log.i("SpotiFLAC", "Using Impeller renderer for ${Build.MODEL}")
        }
        
        return args
    }

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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Update the intent so receive_sharing_intent can access the new data
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
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
                                Gobackend.downloadTrack(requestJson)
                            }
                            result.success(response)
                        }
                        "downloadWithFallback" -> {
                            val requestJson = call.arguments as String
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.downloadWithFallback(requestJson)
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
                                Gobackend.getLyricsLRC(spotifyId, trackName, artistName, filePath, durationMs)
                            }
                            result.success(response)
                        }
                        "embedLyricsToFile" -> {
                            val filePath = call.argument<String>("file_path") ?: ""
                            val lyrics = call.argument<String>("lyrics") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.embedLyricsToFile(filePath, lyrics)
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
                                Gobackend.downloadWithExtensionsJSON(requestJson)
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
                        "removeExtension" -> {
                            val extensionId = call.argument<String>("extension_id") ?: ""
                            withContext(Dispatchers.IO) {
                                Gobackend.removeExtensionByID(extensionId)
                            }
                            result.success(null)
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
                                Gobackend.runPostProcessingJSON(filePath, metadataJson)
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
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }
}
