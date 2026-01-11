import Flutter
import UIKit
import Gobackend  // Import Go framework

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "com.zarz.spotiflac/backend"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call: call, result: result)
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
        case "parseSpotifyUrl":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendParseSpotifyURL(url, &error)
            if let error = error { throw error }
            return response
            
        case "getSpotifyMetadata":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendGetSpotifyMetadata(url, &error)
            if let error = error { throw error }
            return response
            
        case "searchSpotify":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as! String
            let limit = args["limit"] as? Int ?? 10
            let response = GobackendSearchSpotify(query, Int(limit), &error)
            if let error = error { throw error }
            return response
            
        case "searchSpotifyAll":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as! String
            let trackLimit = args["track_limit"] as? Int ?? 15
            let artistLimit = args["artist_limit"] as? Int ?? 3
            let response = GobackendSearchSpotifyAll(query, Int(trackLimit), Int(artistLimit), &error)
            if let error = error { throw error }
            return response
            
        case "checkAvailability":
            let args = call.arguments as! [String: Any]
            let spotifyId = args["spotify_id"] as! String
            let isrc = args["isrc"] as! String
            let response = GobackendCheckAvailability(spotifyId, isrc, &error)
            if let error = error { throw error }
            return response
            
        case "downloadTrack":
            let requestJson = call.arguments as! String
            let response = GobackendDownloadTrack(requestJson, &error)
            if let error = error { throw error }
            return response
            
        case "downloadWithFallback":
            let requestJson = call.arguments as! String
            let response = GobackendDownloadWithFallback(requestJson, &error)
            if let error = error { throw error }
            return response
            
        case "getDownloadProgress":
            let response = GobackendGetDownloadProgress()
            return response
            
        case "getAllDownloadProgress":
            let response = GobackendGetAllDownloadProgress()
            return response
            
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
            
        case "setDownloadDirectory":
            let args = call.arguments as! [String: Any]
            let path = args["path"] as! String
            GobackendSetDownloadDirectory(path, &error)
            if let error = error { throw error }
            return nil
            
        case "checkDuplicate":
            let args = call.arguments as! [String: Any]
            let outputDir = args["output_dir"] as! String
            let isrc = args["isrc"] as! String
            let response = GobackendCheckDuplicate(outputDir, isrc, &error)
            if let error = error { throw error }
            return response
            
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
            let response = GobackendFetchLyrics(spotifyId, trackName, artistName, &error)
            if let error = error { throw error }
            return response
            
        case "getLyricsLRC":
            let args = call.arguments as! [String: Any]
            let spotifyId = args["spotify_id"] as! String
            let trackName = args["track_name"] as! String
            let artistName = args["artist_name"] as! String
            let filePath = args["file_path"] as? String ?? ""
            let response = GobackendGetLyricsLRC(spotifyId, trackName, artistName, filePath, &error)
            if let error = error { throw error }
            return response
            
        case "embedLyricsToFile":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let lyrics = args["lyrics"] as! String
            let response = GobackendEmbedLyricsToFile(filePath, lyrics, &error)
            if let error = error { throw error }
            return response
            
        case "cleanupConnections":
            GobackendCleanupConnections()
            return nil
            
        case "readFileMetadata":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let response = GobackendReadFileMetadata(filePath, &error)
            if let error = error { throw error }
            return response
            
        case "searchDeezerAll":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as! String
            let trackLimit = args["track_limit"] as? Int ?? 15
            let artistLimit = args["artist_limit"] as? Int ?? 3
            let response = GobackendSearchDeezerAll(query, Int(trackLimit), Int(artistLimit), &error)
            if let error = error { throw error }
            return response

        case "getDeezerMetadata":
            let args = call.arguments as! [String: Any]
            let resourceType = args["resource_type"] as! String
            let resourceId = args["resource_id"] as! String
            let response = GobackendGetDeezerMetadata(resourceType, resourceId, &error)
            if let error = error { throw error }
            return response

        case "parseDeezerUrl":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendParseDeezerURLExport(url, &error)
            if let error = error { throw error }
            return response

        case "searchDeezerByISRC":
            let args = call.arguments as! [String: Any]
            let isrc = args["isrc"] as! String
            let response = GobackendSearchDeezerByISRC(isrc, &error)
            if let error = error { throw error }
            return response

        case "convertSpotifyToDeezer":
            let args = call.arguments as! [String: Any]
            let resourceType = args["resource_type"] as! String
            let spotifyId = args["spotify_id"] as! String
            let response = GobackendConvertSpotifyToDeezer(resourceType, spotifyId, &error)
            if let error = error { throw error }
            return response

        case "getSpotifyMetadataWithFallback":
            let args = call.arguments as! [String: Any]
            let url = args["url"] as! String
            let response = GobackendGetSpotifyMetadataWithDeezerFallback(url, &error)
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
            
        case "setSpotifyCredentials":
            let args = call.arguments as! [String: Any]
            let clientId = args["client_id"] as! String
            let clientSecret = args["client_secret"] as! String
            GobackendSetSpotifyAPICredentials(clientId, clientSecret)
            return nil
            
        case "hasSpotifyCredentials":
            let hasCredentials = GobackendCheckSpotifyCredentials()
            return hasCredentials
            
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
            
        case "searchTracksWithExtensions":
            let args = call.arguments as! [String: Any]
            let query = args["query"] as! String
            let limit = args["limit"] as? Int ?? 20
            let response = GobackendSearchTracksWithExtensionsJSON(query, Int(limit), &error)
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
            
        // Extension Post-Processing API
        case "runPostProcessing":
            let args = call.arguments as! [String: Any]
            let filePath = args["file_path"] as! String
            let metadataJson = args["metadata"] as? String ?? ""
            let response = GobackendRunPostProcessingJSON(filePath, metadataJson, &error)
            if let error = error { throw error }
            return response
            
        case "getPostProcessingProviders":
            let response = GobackendGetPostProcessingProvidersJSON(&error)
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
}
