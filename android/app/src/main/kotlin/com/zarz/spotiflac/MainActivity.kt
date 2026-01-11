package com.zarz.spotiflac

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import gobackend.Gobackend
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.zarz.spotiflac/backend"
    private val FFMPEG_CHANNEL = "com.zarz.spotiflac/ffmpeg"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

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
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.fetchLyrics(spotifyId, trackName, artistName)
                            }
                            result.success(response)
                        }
                        "getLyricsLRC" -> {
                            val spotifyId = call.argument<String>("spotify_id") ?: ""
                            val trackName = call.argument<String>("track_name") ?: ""
                            val artistName = call.argument<String>("artist_name") ?: ""
                            val filePath = call.argument<String>("file_path") ?: ""
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.getLyricsLRC(spotifyId, trackName, artistName, filePath)
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
                            val artistLimit = call.argument<Int>("artist_limit") ?: 3
                            val response = withContext(Dispatchers.IO) {
                                Gobackend.searchDeezerAll(query, trackLimit.toLong(), artistLimit.toLong())
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
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
        
        // FFmpeg method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FFMPEG_CHANNEL).setMethodCallHandler { call, result ->
            scope.launch {
                try {
                    when (call.method) {
                        "execute" -> {
                            val command = call.argument<String>("command") ?: ""
                            val session = withContext(Dispatchers.IO) {
                                FFmpegKit.execute(command)
                            }
                            val returnCode = session.returnCode
                            val output = session.output ?: ""
                            result.success(mapOf(
                                "success" to ReturnCode.isSuccess(returnCode),
                                "returnCode" to (returnCode?.value ?: -1),
                                "output" to output
                            ))
                        }
                        "getVersion" -> {
                            val session = withContext(Dispatchers.IO) {
                                FFmpegKit.execute("-version")
                            }
                            result.success(session.output ?: "unknown")
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("FFMPEG_ERROR", e.message, null)
                }
            }
        }
    }
}
