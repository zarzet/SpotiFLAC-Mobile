import Flutter
import UIKit
import Gobackend  // Import Go framework

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "com.zarz.spotiflac/backend"
    private let DOWNLOAD_PROGRESS_STREAM_CHANNEL = "com.zarz.spotiflac/download_progress_stream"
    private let LIBRARY_SCAN_PROGRESS_STREAM_CHANNEL = "com.zarz.spotiflac/library_scan_progress_stream"
    private let streamQueue = DispatchQueue(label: "com.zarz.spotiflac.progress_stream", qos: .utility)
    private var downloadProgressTimer: DispatchSourceTimer?
    private var downloadProgressEventSink: FlutterEventSink?
    private var lastDownloadProgressPayload: String?
    private var libraryScanProgressTimer: DispatchSourceTimer?
    private var libraryScanProgressEventSink: FlutterEventSink?
    private var lastLibraryScanProgressPayload: String?
    
    /// Currently accessed security-scoped URL for library folder
    private var activeSecurityScopedURL: URL?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            GobackendSetAppVersion(version)
        }
        
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        let downloadProgressEvents = FlutterEventChannel(
            name: DOWNLOAD_PROGRESS_STREAM_CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        let libraryScanProgressEvents = FlutterEventChannel(
            name: LIBRARY_SCAN_PROGRESS_STREAM_CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call: call, result: result)
        }
        downloadProgressEvents.setStreamHandler(
            ClosureStreamHandler(
                onListen: { [weak self] _, events in
                    self?.startDownloadProgressStream(events)
                    return nil
                },
                onCancel: { [weak self] _ in
                    self?.stopDownloadProgressStream()
                    return nil
                }
            )
        )
        libraryScanProgressEvents.setStreamHandler(
            ClosureStreamHandler(
                onListen: { [weak self] _, events in
                    self?.startLibraryScanProgressStream(events)
                    return nil
                },
                onCancel: { [weak self] _ in
                    self?.stopLibraryScanProgressStream()
                    return nil
                }
            )
        )
        
        GeneratedPluginRegistrant.register(with: self)
        if let url = launchOptions?[.url] as? URL {
            handleExtensionOAuthRedirect(url: url)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// PKCE OAuth return URL: spotiflac://callback?code=...&state=<extension_id>
    private func handleExtensionOAuthRedirect(url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "spotiflac" else { return }
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()
        let ok =
            host == "callback" || host == "spotify-callback" || path.contains("callback")
        guard ok else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        let q = components.queryItems ?? []
        let code =
            q.first { $0.name == "code" }?.value?.trimmingCharacters(
                in: .whitespacesAndNewlines) ?? ""
        let state =
            q.first { $0.name == "state" }?.value?.trimmingCharacters(
                in: .whitespacesAndNewlines) ?? ""
        if code.isEmpty { return }
        if state.isEmpty {
            NSLog("SpotiFLAC: Extension OAuth redirect missing state (extension id)")
            return
        }
        streamQueue.async {
            var err: NSError?
            GobackendSetExtensionAuthCodeByID(state, code)
            _ = GobackendInvokeExtensionActionJSON(state, "completeSpotifyLogin", &err)
            if let err = err {
                NSLog(
                    "SpotiFLAC: Extension OAuth complete failed: \(err.localizedDescription)")
            }
        }
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        handleExtensionOAuthRedirect(url: url)
        return super.application(app, open: url, options: options)
    }

    deinit {
        stopDownloadProgressStream()
        stopLibraryScanProgressStream()
    }

    private func startDownloadProgressStream(_ eventSink: @escaping FlutterEventSink) {
        stopDownloadProgressStream()
        downloadProgressEventSink = eventSink
        lastDownloadProgressPayload = nil

        let timer = DispatchSource.makeTimerSource(queue: streamQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(800))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let payload = GobackendGetAllDownloadProgress() as String? ?? "{}"
            if payload == self.lastDownloadProgressPayload {
                return
            }
            self.lastDownloadProgressPayload = payload
            DispatchQueue.main.async { [weak self] in
                self?.downloadProgressEventSink?(self?.parseJsonPayload(payload))
            }
        }
        downloadProgressTimer = timer
        timer.resume()
    }

    private func stopDownloadProgressStream() {
        downloadProgressTimer?.setEventHandler {}
        downloadProgressTimer?.cancel()
        downloadProgressTimer = nil
        downloadProgressEventSink = nil
        lastDownloadProgressPayload = nil
    }

    private func startLibraryScanProgressStream(_ eventSink: @escaping FlutterEventSink) {
        stopLibraryScanProgressStream()
        libraryScanProgressEventSink = eventSink
        lastLibraryScanProgressPayload = nil

        let timer = DispatchSource.makeTimerSource(queue: streamQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(800))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let payload = GobackendGetLibraryScanProgressJSON() as String? ?? "{}"
            if payload == self.lastLibraryScanProgressPayload {
                return
            }
            self.lastLibraryScanProgressPayload = payload
            DispatchQueue.main.async { [weak self] in
                self?.libraryScanProgressEventSink?(self?.parseJsonPayload(payload))
            }
        }
        libraryScanProgressTimer = timer
        timer.resume()
    }

    private func stopLibraryScanProgressStream() {
        libraryScanProgressTimer?.setEventHandler {}
        libraryScanProgressTimer?.cancel()
        libraryScanProgressTimer = nil
        libraryScanProgressEventSink = nil
        lastLibraryScanProgressPayload = nil
    }

    private func parseJsonPayload(_ payload: String) -> Any {
        guard let data = payload.data(using: .utf8) else {
            return payload
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            return payload
        }
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let response = try self.invokeGoMethod(call: call)
                DispatchQueue.main.async {
                    result(response)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func invokeGoMethod(call: FlutterMethodCall) throws -> Any? {
        var error: NSError?
        
        switch call.method {
        case "checkAvailability":
            let args = call.arguments as! [String: Any]
            let spotifyId = args["spotify_id"] as! String
            let isrc = args["isrc"] as! String
            let response = GobackendCheckAvailability(spotifyId, isrc, &error)
            if let error = error { throw error }
            return response
            
        case "downloadByStrategy":
            let requestJson = call.arguments as! String
            let response = GobackendDownloadByStrategy(requestJson, &error)
            if let error = error { throw error }
            return response

        case "getDownloadProgress":
            let response = GobackendGetDownloadProgress()
            return parseJsonPayload(response as String? ?? "{}")
            
        case "getAllDownloadProgress":
            let response = GobackendGetAllDownloadProgress()
            return parseJsonPayload(response as String? ?? "{}")
            
        case "initItemProgress":
            let args = call.arguments as! [String: Any]
            let itemId = args["item_id"] as! String
            GobackendInitItemProgress(itemId)
            return nil
            
        case "finishItemProgress":
            let args = call.arguments as! [String: Any]
            let itemId = args["item_id"] as! String
            GobackendFinishItemProgress(itemId)
            return nil
            
        case "clearItemProgress":
            let args = call.arguments as! [String: Any]
            let itemId = args["item_id"] as! String
            GobackendClearItemProgress(itemId)
            return nil

        case "cancelDownload":
            let args = call.arguments as! [String: Any]
            let itemId = args["item_id"] as! String
            GobackendCancelDownload(itemId)
            return nil
            
        case "setDownloadDirectory":
            let args = call.arguments as! [String: Any]
            let path = args["path"] as! String
            GobackendSetDownloadDirectory(path, &error)
            if let error = error { throw error }
            return nil

        case "setNetworkCompatibilityOptions", "setSongLinkNetworkOptions":
            let args = call.arguments as! [String: Any]
            let allowHTTP = args["allow_http"] as? Bool ?? false
            let insecureTLS = args["insecure_tls"] as? Bool ?? false
            GobackendSetNetworkCompatibilityOptions(allowHTTP, insecureTLS)
            return nil
            
        case "checkDuplicate":
            let args = call.arguments as! [String: Any]
            let outputDir = args["output_dir"] as! String
            let isrc = args["isrc"] as! String
            let response = GobackendCheckDuplicate(outputDir, isrc, &error)
            if let error = error { throw error }
            return response
            
        case "checkDuplicatesBatch":
            let args = call.arguments as! [String: Any]
            let outputDir = args["output_dir"] as! String
            let tracksJson = args["tracks"] as? String ?? "[]"
            let response = GobackendCheckDuplicatesBatch(outputDir, tracksJson, &error)
            if let error = error { throw error }
            return response
            
        case "preBuildDuplicateIndex":
            let args = call.arguments as! [String: Any]
            let outputDir = args["output_dir"] as! String
            GobackendPreBuildDuplicateIndex(outputDir, &error)
            if let error = error { throw error }
            return nil
            
        case "invalidateDuplicateIndex":
            let args = call.arguments as! [String: Any]
            let outputDir = args["output_dir"] as! String
            GobackendInvalidateDuplicateIndex(outputDir)
            return nil
            
        case "buildFilename":
            let args = call.arguments as! [String: Any]
            let template = args["template"] as! String
            let metadata = args["metadata"] as! String
            let response = GobackendBuildFilename(template, metadata, &error)
            if let error = error { throw error }
            return response
            
        case "sanitizeFilename":
            let args = call.arguments as! [String: Any]
            let filename = args["filename"] as! String
            let response = GobackendSanitizeFilename(filename)
            return response
            
        case "fetchLyrics":
            let args = call.arguments as! [String: Any]
            let spotifyId = args["spotify_id"] as! String
            let trackName = args["track_name"] as! String
            let artistName = args["artist_name"] as! String
            let durationMs = args["duration_ms"] as? Int64 ?? 0
            let response = GobackendFetchLyrics(spotifyId, trackName, artistName, durationMs, &error)
            if let error = error { throw error }
            return response
            
        case "getLyricsLRC":
            let args = call.arguments as! [String: Any]
            let spotifyId = args["spotify_id"] as! String
            let trackName = args["track_name"] as! String
            let artistName = args["artist_name"] as! String
            let filePath = args["file_path"] as? String ?? ""
            let durationMs = args["duration_ms"] as? Int64 ?? 0
            let response = GobackendGetLyricsLRC(spotifyId, trackName, artistName, filePath, durationMs, &error)
            if let error = error { throw error }
            return response

        case "getLyricsLRCWithSource":
            let args = call.arguments as! [String: Any]
            let spotifyId = args["spotify_id"] as! String
            let trackName = args["track_name"] as! String
            let artistName = args["artist_name"] as! String
            let filePath = args["file_path"] as? String ?? ""
            let durationMs = args["duration_ms"] as? Int64 ?? 0
            let response = GobackendGetLyricsLRCWithSource(spotifyId, trackName, artistName, filePath, durationMs, &error)
            if let error = error { throw error }
            return response
            
        case "embedLyricsToFile":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let lyrics = args["lyrics"] as! String
            let response = GobackendEmbedLyricsToFile(filePath, lyrics, &error)
            if let error = error { throw error }
            return response
            
        case "rewriteSplitArtistTags":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let artist = args["artist"] as! String
            let albumArtist = args["album_artist"] as! String
            let response = GobackendRewriteSplitArtistTagsExport(filePath, artist, albumArtist, &error)
            if let error = error { throw error }
            return response
            
        case "cleanupConnections":
            GobackendCleanupConnections()
            return nil

        case "downloadCoverToFile":
            let args = call.arguments as! [String: Any]
            let coverURL = args["cover_url"] as! String
            let outputPath = args["output_path"] as! String
            let maxQuality = args["max_quality"] as? Bool ?? true
            GobackendDownloadCoverToFile(coverURL, outputPath, maxQuality, &error)
            if let error = error { throw error }
            return "{\"success\":true}"

        case "extractCoverToFile":
            let args = call.arguments as! [String: Any]
            let audioPath = args["audio_path"] as! String
            let outputPath = args["output_path"] as! String
            GobackendExtractCoverToFile(audioPath, outputPath, &error)
            if let error = error { throw error }
            return "{\"success\":true}"

        case "fetchAndSaveLyrics":
            let args = call.arguments as! [String: Any]
            let trackName = args["track_name"] as! String
            let artistName = args["artist_name"] as! String
            let spotifyId = args["spotify_id"] as! String
            let durationMs = args["duration_ms"] as? Int64 ?? 0
            let outputPath = args["output_path"] as! String
            let audioFilePath = args["audio_file_path"] as? String ?? ""
            GobackendFetchAndSaveLyrics(trackName, artistName, spotifyId, durationMs, outputPath, audioFilePath, &error)
            if let error = error { throw error }
            return "{\"success\":true}"

        case "reEnrichFile":
            let args = call.arguments as! [String: Any]
            let requestJson = args["request_json"] as? String ?? "{}"
            let response = GobackendReEnrichFile(requestJson, &error)
            if let error = error { throw error }
            return response
            
        case "readFileMetadata":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let response = GobackendReadFileMetadata(filePath, &error)
            if let error = error { throw error }
            return response
            
        case "editFileMetadata":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let metadataJson = args["metadata_json"] as? String ?? "{}"
            let response = GobackendEditFileMetadata(filePath, metadataJson, &error)
            if let error = error { throw error }
            return response
            
        case "searchTidalAll":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as! String
            let trackLimit = args["track_limit"] as? Int ?? 15
            let artistLimit = args["artist_limit"] as? Int ?? 3
            let filter = args["filter"] as? String ?? ""
            let response = GobackendSearchTidalAll(query, Int(trackLimit), Int(artistLimit), filter, &error)
            if let error = error { throw error }
            return response

        case "searchQobuzAll":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as! String
            let trackLimit = args["track_limit"] as? Int ?? 15
            let artistLimit = args["artist_limit"] as? Int ?? 3
            let filter = args["filter"] as? String ?? ""
            let response = GobackendSearchQobuzAll(query, Int(trackLimit), Int(artistLimit), filter, &error)
            if let error = error { throw error }
            return response

        case "getDeezerRelatedArtists":
            let args = call.arguments as! [String: Any]
            let artistId = args["artist_id"] as! String
            let limit = args["limit"] as? Int ?? 12
            let response = GobackendGetDeezerRelatedArtists(artistId, Int(limit), &error)
            if let error = error { throw error }
            return response

        case "getDeezerMetadata":
            let args = call.arguments as! [String: Any]
            let resourceType = args["resource_type"] as! String
            let resourceId = args["resource_id"] as! String
            let response = GobackendGetDeezerMetadata(resourceType, resourceId, &error)
            if let error = error { throw error }
            return response

        case "getQobuzMetadata":
            let args = call.arguments as! [String: Any]
            let resourceType = args["resource_type"] as! String
            let resourceId = args["resource_id"] as! String
            let response = GobackendGetQobuzMetadata(resourceType, resourceId, &error)
            if let error = error { throw error }
            return response

        case "getTidalMetadata":
            let args = call.arguments as! [String: Any]
            let resourceType = args["resource_type"] as! String
            let resourceId = args["resource_id"] as! String
            let response = GobackendGetTidalMetadata(resourceType, resourceId, &error)
            if let error = error { throw error }
            return response

        case "parseDeezerUrl":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendParseDeezerURLExport(url, &error)
            if let error = error { throw error }
            return response

        case "parseQobuzUrl":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendParseQobuzURLExport(url, &error)
            if let error = error { throw error }
            return response

        case "parseTidalUrl":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendParseTidalURLExport(url, &error)
            if let error = error { throw error }
            return response

        case "convertTidalToSpotifyDeezer":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendConvertTidalToSpotifyDeezer(url, &error)
            if let error = error { throw error }
            return response

        case "searchDeezerByISRC":
            let args = call.arguments as! [String: Any]
            let isrc = args["isrc"] as! String
            let response = GobackendSearchDeezerByISRC(isrc, &error)
            if let error = error { throw error }
            return response

        case "getDeezerExtendedMetadata":
            let args = call.arguments as! [String: Any]
            let trackId = args["track_id"] as! String
            let response = GobackendGetDeezerExtendedMetadata(trackId, &error)
            if let error = error { throw error }
            return response

        case "convertSpotifyToDeezer":
            let args = call.arguments as! [String: Any]
            let resourceType = args["resource_type"] as! String
            let spotifyId = args["spotify_id"] as! String
            let response = GobackendConvertSpotifyToDeezer(resourceType, spotifyId, &error)
            if let error = error { throw error }
            return response

        case "checkAvailabilityFromDeezerID":
            let args = call.arguments as! [String: Any]
            let deezerTrackId = args["deezer_track_id"] as! String
            let response = GobackendCheckAvailabilityFromDeezerID(deezerTrackId, &error)
            if let error = error { throw error }
            return response
            
        case "checkAvailabilityByPlatformID":
            let args = call.arguments as! [String: Any]
            let platform = args["platform"] as! String
            let entityType = args["entity_type"] as! String
            let entityId = args["entity_id"] as! String
            let response = GobackendCheckAvailabilityByPlatformID(platform, entityType, entityId, &error)
            if let error = error { throw error }
            return response
            
        case "getSpotifyIDFromDeezerTrack":
            let args = call.arguments as! [String: Any]
            let deezerTrackId = args["deezer_track_id"] as! String
            let response = GobackendGetSpotifyIDFromDeezerTrack(deezerTrackId, &error)
            if let error = error { throw error }
            return response
            
        case "getTidalURLFromDeezerTrack":
            let args = call.arguments as! [String: Any]
            let deezerTrackId = args["deezer_track_id"] as! String
            let response = GobackendGetTidalURLFromDeezerTrack(deezerTrackId, &error)
            if let error = error { throw error }
            return response
            
        case "preWarmTrackCache":
            let args = call.arguments as! [String: Any]
            let tracksJson = args["tracks"] as! String
            let _ = GobackendPreWarmTrackCacheJSON(tracksJson, &error)
            if let error = error { throw error }
            return nil
            
        case "getTrackCacheSize":
            let response = GobackendGetTrackCacheSize()
            return response
            
        case "clearTrackCache":
            GobackendClearTrackCache()
            return nil
            
        // Log methods
        case "getLogs":
            let response = GobackendGetLogs()
            return response
            
        case "getLogsSince":
            let args = call.arguments as! [String: Any]
            let index = args["index"] as? Int ?? 0
            let response = GobackendGetLogsSince(Int(index))
            return response
            
        case "clearLogs":
            GobackendClearLogs()
            return nil
            
        case "getLogCount":
            let response = GobackendGetLogCount()
            return response
            
        case "setLoggingEnabled":
            let args = call.arguments as! [String: Any]
            let enabled = args["enabled"] as? Bool ?? false
            GobackendSetLoggingEnabled(enabled)
            return nil
            
        // Extension System methods
        case "initExtensionSystem":
            let args = call.arguments as! [String: Any]
            let extensionsDir = args["extensions_dir"] as! String
            let dataDir = args["data_dir"] as! String
            GobackendInitExtensionSystem(extensionsDir, dataDir, &error)
            if let error = error { throw error }
            return nil
            
        case "loadExtensionsFromDir":
            let args = call.arguments as! [String: Any]
            let dirPath = args["dir_path"] as! String
            let response = GobackendLoadExtensionsFromDir(dirPath, &error)
            if let error = error { throw error }
            return response
            
        case "loadExtensionFromPath":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let response = GobackendLoadExtensionFromPath(filePath, &error)
            if let error = error { throw error }
            return response
            
        case "unloadExtension":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            GobackendUnloadExtensionByID(extensionId, &error)
            if let error = error { throw error }
            return nil
            
        case "getInstalledExtensions":
            let response = GobackendGetInstalledExtensions(&error)
            if let error = error { throw error }
            return response
            
        case "setExtensionEnabled":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let enabled = args["enabled"] as? Bool ?? false
            GobackendSetExtensionEnabledByID(extensionId, enabled, &error)
            if let error = error { throw error }
            return nil
            
        case "setProviderPriority":
            let args = call.arguments as! [String: Any]
            let priorityJson = args["priority"] as! String
            GobackendSetProviderPriorityJSON(priorityJson, &error)
            if let error = error { throw error }
            return nil
            
        case "getProviderPriority":
            let response = GobackendGetProviderPriorityJSON(&error)
            if let error = error { throw error }
            return response

        case "setDownloadFallbackExtensionIds":
            let args = call.arguments as! [String: Any]
            let extensionIdsJson = args["extension_ids"] as? String ?? ""
            GobackendSetExtensionFallbackProviderIDsJSON(extensionIdsJson, &error)
            if let error = error { throw error }
            return nil
            
        case "setMetadataProviderPriority":
            let args = call.arguments as! [String: Any]
            let priorityJson = args["priority"] as! String
            GobackendSetMetadataProviderPriorityJSON(priorityJson, &error)
            if let error = error { throw error }
            return nil
            
        case "getMetadataProviderPriority":
            let response = GobackendGetMetadataProviderPriorityJSON(&error)
            if let error = error { throw error }
            return response
            
        case "getExtensionSettings":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let response = GobackendGetExtensionSettingsJSON(extensionId, &error)
            if let error = error { throw error }
            return response
            
        case "setExtensionSettings":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let settingsJson = args["settings"] as! String
            GobackendSetExtensionSettingsJSON(extensionId, settingsJson, &error)
            if let error = error { throw error }
            return nil
            
        case "invokeExtensionAction":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let actionName = args["action"] as! String
            let response = GobackendInvokeExtensionActionJSON(extensionId, actionName, &error)
            if let error = error { throw error }
            return response
            
        case "searchTracksWithExtensions":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as! String
            let limit = args["limit"] as? Int ?? 20
            let response = GobackendSearchTracksWithExtensionsJSON(query, Int(limit), &error)
            if let error = error { throw error }
            return response

        case "searchTracksWithMetadataProviders":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as! String
            let limit = args["limit"] as? Int ?? 20
            let includeExtensions = args["include_extensions"] as? Bool ?? true
            let response = GobackendSearchTracksWithMetadataProvidersJSON(
                query,
                Int(limit),
                includeExtensions,
                &error
            )
            if let error = error { throw error }
            return response
            
        case "enrichTrackWithExtension":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let trackJson = args["track"] as? String ?? "{}"
            let response = GobackendEnrichTrackWithExtensionJSON(extensionId, trackJson, &error)
            if let error = error { throw error }
            return response

        case "downloadWithExtensions":
            let requestJson = call.arguments as! String
            let response = GobackendDownloadWithExtensionsJSON(requestJson, &error)
            if let error = error { throw error }
            return response
            
        case "removeExtension":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            GobackendRemoveExtensionByID(extensionId, &error)
            if let error = error { throw error }
            return nil
            
        case "upgradeExtension":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let response = GobackendUpgradeExtensionFromPath(filePath, &error)
            if let error = error { throw error }
            return response
            
        case "checkExtensionUpgrade":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let response = GobackendCheckExtensionUpgradeFromPath(filePath, &error)
            if let error = error { throw error }
            return response
            
        case "cleanupExtensions":
            GobackendCleanupExtensions()
            return nil
            
        // Extension Auth API
        case "getExtensionPendingAuth":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let response = GobackendGetExtensionPendingAuthJSON(extensionId, &error)
            if let error = error { throw error }
            return response
            
        case "setExtensionAuthCode":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let authCode = args["auth_code"] as! String
            GobackendSetExtensionAuthCodeByID(extensionId, authCode)
            return nil
            
        case "setExtensionTokens":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let accessToken = args["access_token"] as! String
            let refreshToken = args["refresh_token"] as? String ?? ""
            let expiresIn = args["expires_in"] as? Int ?? 0
            GobackendSetExtensionTokensByID(extensionId, accessToken, refreshToken, Int(expiresIn))
            return nil
            
        case "clearExtensionPendingAuth":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            GobackendClearExtensionPendingAuthByID(extensionId)
            return nil
            
        case "isExtensionAuthenticated":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let response = GobackendIsExtensionAuthenticatedByID(extensionId)
            return response
            
        case "getAllPendingAuthRequests":
            let response = GobackendGetAllPendingAuthRequestsJSON(&error)
            if let error = error { throw error }
            return response
            
        // Extension FFmpeg API
        case "getPendingFFmpegCommand":
            let args = call.arguments as! [String: Any]
            let commandId = args["command_id"] as! String
            let response = GobackendGetPendingFFmpegCommandJSON(commandId, &error)
            if let error = error { throw error }
            return response
            
        case "setFFmpegCommandResult":
            let args = call.arguments as! [String: Any]
            let commandId = args["command_id"] as! String
            let success = args["success"] as? Bool ?? false
            let output = args["output"] as? String ?? ""
            let errorMsg = args["error"] as? String ?? ""
            GobackendSetFFmpegCommandResult(commandId, success, output, errorMsg)
            return nil
            
        case "getAllPendingFFmpegCommands":
            let response = GobackendGetAllPendingFFmpegCommandsJSON(&error)
            if let error = error { throw error }
            return response
            
        // Extension Custom Search API
        case "customSearchWithExtension":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let query = args["query"] as! String
            let optionsJson = args["options"] as? String ?? ""
            let response = GobackendCustomSearchWithExtensionJSON(extensionId, query, optionsJson, &error)
            if let error = error { throw error }
            return response
            
        case "getSearchProviders":
            let response = GobackendGetSearchProvidersJSON(&error)
            if let error = error { throw error }
            return response
            
        // Extension URL Handler API
        case "handleURLWithExtension":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendHandleURLWithExtensionJSON(url, &error)
            if let error = error { throw error }
            return response
            
        case "findURLHandler":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendFindURLHandlerJSON(url)
            return response
            
        case "getURLHandlers":
            let response = GobackendGetURLHandlersJSON(&error)
            if let error = error { throw error }
            return response
            
        case "getAlbumWithExtension":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let albumId = args["album_id"] as! String
            let response = GobackendGetAlbumWithExtensionJSON(extensionId, albumId, &error)
            if let error = error { throw error }
            return response
            
        case "getPlaylistWithExtension":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let playlistId = args["playlist_id"] as! String
            let response = GobackendGetPlaylistWithExtensionJSON(extensionId, playlistId, &error)
            if let error = error { throw error }
            return response
            
        case "getArtistWithExtension":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let artistId = args["artist_id"] as! String
            let response = GobackendGetArtistWithExtensionJSON(extensionId, artistId, &error)
            if let error = error { throw error }
            return response
            
        // Extension Post-Processing API
        case "runPostProcessing":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let metadataJson = args["metadata"] as? String ?? ""
            let response = GobackendRunPostProcessingJSON(filePath, metadataJson, &error)
            if let error = error { throw error }
            return response

        case "runPostProcessingV2":
            let args = call.arguments as! [String: Any]
            let inputJson = args["input"] as? String ?? ""
            let metadataJson = args["metadata"] as? String ?? ""
            let response = GobackendRunPostProcessingV2JSON(inputJson, metadataJson, &error)
            if let error = error { throw error }
            return response
            
        case "getPostProcessingProviders":
            let response = GobackendGetPostProcessingProvidersJSON(&error)
            if let error = error { throw error }
            return response
            
        // Extension Store
        case "initExtensionStore":
            let args = call.arguments as! [String: Any]
            let cacheDir = args["cache_dir"] as! String
            GobackendInitExtensionStoreJSON(cacheDir, &error)
            if let error = error { throw error }
            return nil
            
        case "setStoreRegistryUrl":
            let args = call.arguments as! [String: Any]
            let registryUrl = args["registry_url"] as? String ?? ""
            GobackendSetStoreRegistryURLJSON(registryUrl, &error)
            if let error = error { throw error }
            return nil
            
        case "getStoreRegistryUrl":
            let response = GobackendGetStoreRegistryURLJSON(&error)
            if let error = error { throw error }
            return response
            
        case "clearStoreRegistryUrl":
            GobackendClearStoreRegistryURLJSON(&error)
            if let error = error { throw error }
            return nil
            
        case "getStoreExtensions":
            let args = call.arguments as! [String: Any]
            let forceRefresh = args["force_refresh"] as? Bool ?? false
            let response = GobackendGetStoreExtensionsJSON(forceRefresh, &error)
            if let error = error { throw error }
            return response
            
        case "searchStoreExtensions":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as? String ?? ""
            let category = args["category"] as? String ?? ""
            let response = GobackendSearchStoreExtensionsJSON(query, category, &error)
            if let error = error { throw error }
            return response
            
        case "getStoreCategories":
            let response = GobackendGetStoreCategoriesJSON(&error)
            if let error = error { throw error }
            return response
            
        case "downloadStoreExtension":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let destDir = args["dest_dir"] as! String
            let response = GobackendDownloadStoreExtensionJSON(extensionId, destDir, &error)
            if let error = error { throw error }
            return response
            
        case "clearStoreCache":
            GobackendClearStoreCacheJSON(&error)
            if let error = error { throw error }
            return nil
            
        // Extension Home Feed API
        case "getExtensionHomeFeed":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let response = GobackendGetExtensionHomeFeedJSON(extensionId, &error)
            if let error = error { throw error }
            return response
            
        case "getExtensionBrowseCategories":
            let args = call.arguments as! [String: Any]
            let extensionId = args["extension_id"] as! String
            let response = GobackendGetExtensionBrowseCategoriesJSON(extensionId, &error)
            if let error = error { throw error }
            return response
            
        // Local Library Scanning
        case "setLibraryCoverCacheDir":
            let args = call.arguments as! [String: Any]
            let cacheDir = args["cache_dir"] as! String
            GobackendSetLibraryCoverCacheDirJSON(cacheDir)
            return nil
            
        case "scanLibraryFolder":
            let args = call.arguments as! [String: Any]
            let folderPath = args["folder_path"] as! String
            let response = GobackendScanLibraryFolderJSON(folderPath, &error)
            if let error = error { throw error }
            return response
            
        case "scanLibraryFolderIncremental":
            let args = call.arguments as! [String: Any]
            let folderPath = args["folder_path"] as! String
            let existingFiles = args["existing_files"] as? String ?? "{}"
            let response = GobackendScanLibraryFolderIncrementalJSON(folderPath, existingFiles, &error)
            if let error = error { throw error }
            return response
            
        case "getLibraryScanProgress":
            let response = GobackendGetLibraryScanProgressJSON()
            return parseJsonPayload(response as String? ?? "{}")
            
        case "cancelLibraryScan":
            GobackendCancelLibraryScanJSON()
            return nil
            
        case "readAudioMetadata":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let response = GobackendReadAudioMetadataJSON(filePath, &error)
            if let error = error { throw error }
            return response
        
        // iOS Security-Scoped Bookmark for Local Library
        case "resolveIosBookmark":
            let args = call.arguments as! [String: Any]
            let bookmarkBase64 = args["bookmark"] as! String
            return try resolveIosBookmark(bookmarkBase64)
            
        case "startAccessingIosBookmark":
            let args = call.arguments as! [String: Any]
            let bookmarkBase64 = args["bookmark"] as! String
            return try startAccessingIosBookmark(bookmarkBase64)
            
        case "stopAccessingIosBookmark":
            stopAccessingIosBookmark()
            return nil
            
        case "createIosBookmarkFromPath":
            let args = call.arguments as! [String: Any]
            let path = args["path"] as! String
            return try createIosBookmarkFromPath(path)
            
        // Lyrics Provider Settings
        case "setLyricsProviders":
            let args = call.arguments as! [String: Any]
            let providersJson = args["providers_json"] as? String ?? "[]"
            GobackendSetLyricsProvidersJSON(providersJson, &error)
            if let error = error { throw error }
            return "{\"success\":true}"
            
        case "getLyricsProviders":
            let response = GobackendGetLyricsProvidersJSON(&error)
            if let error = error { throw error }
            return response
            
        case "getAvailableLyricsProviders":
            let response = GobackendGetAvailableLyricsProvidersJSON(&error)
            if let error = error { throw error }
            return response
            
        case "setLyricsFetchOptions":
            let args = call.arguments as! [String: Any]
            let optionsJson = args["options_json"] as? String ?? "{}"
            GobackendSetLyricsFetchOptionsJSON(optionsJson, &error)
            if let error = error { throw error }
            return "{\"success\":true}"
            
        case "getLyricsFetchOptions":
            let response = GobackendGetLyricsFetchOptionsJSON(&error)
            if let error = error { throw error }
            return response
            
        // CUE Sheet Parsing
        case "parseCueSheet":
            let args = call.arguments as! [String: Any]
            let cuePath = args["cue_path"] as! String
            let audioDir = args["audio_dir"] as? String ?? ""
            let response = GobackendParseCueSheet(cuePath, audioDir, &error)
            if let error = error { throw error }
            return response
            
        default:
            throw NSError(
                domain: "SpotiFLAC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Method not implemented: \(call.method)"]
            )
        }
    }
    
    // MARK: - iOS Security-Scoped Bookmark Helpers
    
    /// Create a security-scoped bookmark from a filesystem path (e.g. from FilePicker).
    /// The path must currently be accessible (within the same picker session).
    /// Returns base64-encoded bookmark data.
    private func createIosBookmarkFromPath(_ path: String) throws -> String {
        let url = URL(fileURLWithPath: path)
        do {
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return bookmarkData.base64EncodedString()
        } catch {
            throw NSError(
                domain: "SpotiFLAC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create bookmark for path \(path): \(error.localizedDescription)"]
            )
        }
    }
    
    /// Resolve a base64-encoded security-scoped bookmark and return the resolved path.
    /// Does NOT start accessing the resource.
    private func resolveIosBookmark(_ bookmarkBase64: String) throws -> String {
        guard let bookmarkData = Data(base64Encoded: bookmarkBase64) else {
            throw NSError(
                domain: "SpotiFLAC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid base64 bookmark data"]
            )
        }
        
        var isStale = false
        let url: URL
        do {
            url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            throw NSError(
                domain: "SpotiFLAC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to resolve bookmark: \(error.localizedDescription)"]
            )
        }
        
        return url.path
    }
    
    /// Resolve a base64-encoded bookmark, start accessing the security-scoped resource,
    /// and return the resolved filesystem path. The resource stays accessed until
    /// `stopAccessingIosBookmark()` is called.
    private func startAccessingIosBookmark(_ bookmarkBase64: String) throws -> String {
        // Stop any previously accessed resource first
        stopAccessingIosBookmark()
        
        guard let bookmarkData = Data(base64Encoded: bookmarkBase64) else {
            throw NSError(
                domain: "SpotiFLAC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid base64 bookmark data"]
            )
        }
        
        var isStale = false
        let url: URL
        do {
            url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            throw NSError(
                domain: "SpotiFLAC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to resolve bookmark: \(error.localizedDescription)"]
            )
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(
                domain: "SpotiFLAC",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to start accessing security-scoped resource at \(url.path)"]
            )
        }
        
        activeSecurityScopedURL = url
        return url.path
    }
    
    /// Stop accessing the currently active security-scoped resource, if any.
    private func stopAccessingIosBookmark() {
        if let url = activeSecurityScopedURL {
            url.stopAccessingSecurityScopedResource()
            activeSecurityScopedURL = nil
        }
    }
}

private final class ClosureStreamHandler: NSObject, FlutterStreamHandler {
    typealias ListenHandler = (_ arguments: Any?, _ events: @escaping FlutterEventSink) -> FlutterError?
    typealias CancelHandler = (_ arguments: Any?) -> FlutterError?

    private let onListenHandler: ListenHandler
    private let onCancelHandler: CancelHandler

    init(
        onListen: @escaping ListenHandler,
        onCancel: @escaping CancelHandler = { _ in nil }
    ) {
        self.onListenHandler = onListen
        self.onCancelHandler = onCancel
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        onListenHandler(arguments, events)
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        onCancelHandler(arguments)
    }
}
