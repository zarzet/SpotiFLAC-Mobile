package com.zarz.spotiflac

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import gobackend.Gobackend
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.zarz.spotiflac/backend"
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
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }
}
