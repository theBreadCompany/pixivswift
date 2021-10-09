//
//  PixivDownloader.swift
//  pixivswiftWrapper
//
//  Created by Fabio Mauersberger on 16.04.21.
//  Original work written in Python by https://github.com/Xdynix.
//

import Foundation
import ImageIO
import Zip
import pixivswift


#if canImport(UIKit)
import UIKit
let kUTTypePNG = "public.png" as CFString
let kUTTypeGIF = "com.compuserve.gif" as CFString
let kUTTypeJPEG = "public.jpeg" as CFString
#endif

private let TOKEN_LIFETIME = 2700

open class PixivDownloader {
    
    public let auto_relogin: Bool
    
    public let _aapi: AppPixivAPI
    
    public var authed: Bool
    public var last_login: Date?
    
    public var refresh_token: String?
    
    public init(auto_relogin: Bool = true) {
        self.auto_relogin = auto_relogin
        
        self._aapi = AppPixivAPI()
        
        self.authed = false
        self.last_login = nil
        
        self.refresh_token = nil
    }
    /*
     init with logged in client
     */
    public init(login_with_token refresh_token: String, auto_relogin: Bool = true) {
        self.auto_relogin = auto_relogin
        
        self._aapi = AppPixivAPI()
        
        self.authed = false
        self.last_login = nil
        
        self.refresh_token = nil
        
        self.login(refresh_token: refresh_token)
    }
    
    
    /**
     Login
     
     - Parameter username: the username of your account
     - Parameter password: the password of your account
     - Parameter refresh_token: a refresh\_token that grants access to your account
     */
    open func login(username: String? = nil, password: String? = nil, refresh_token: String? = nil) {
        
        if let refresh_token = refresh_token {
            do {
                let _ = try self._aapi.auth(refresh_token: refresh_token)
                self.refresh_token = refresh_token
                self.authed = true
            } catch {
                print("Login failed")
                self.authed = false
            }
        } else if let username = username, let password = password {
            do {
                let _ = try self._aapi.auth(username: username, password: password)
                self.refresh_token = self._aapi.refresh_token
                self.authed = true
            } catch {
                print("Login failed")
                self.authed = false
            }
        }
        
        self.last_login = Date()
    }
    
    /*
     Check whether the PixivDownloader object is logged in
     */
    private func check_auth(auto_relogin: Bool = false) throws {
        if self.last_login == nil || (!self.authed && !(self.refresh_token ?? "").isEmpty) {
            if self.auto_relogin {
                self.login(refresh_token: self.refresh_token)
            } else {
                throw PixivError.AuthErrors.missingAuth(nil)
            }
        }
    }
    
    private func aapi_collect(result: PixivResult, targetCollection: [PixivIllustration], limit: Int) -> [PixivIllustration] {
        var _targetCollection = targetCollection
        for illust in result.illusts! {
            if _targetCollection.count < limit {
                _targetCollection.append(illust)
            } else {
                return _targetCollection
            }
        }
        return _targetCollection
    }
    
    /**
     Generate PixivIllustration object
     
     - Parameter illust_id: ID of the Illustration to be generated
     
     - returns: a PixivIllustration object
     */
    open func illustration(illust_id: Int) throws -> PixivIllustration {
        return try self._aapi.illust_detail(illust_id: illust_id).illusts!.first!
    }
    
    /**
     Fetch the newest illustrations of the users you follow
     
     - Parameter until: optional filter by date in the format "day/month/year"
     - Parameter publicity: publicity of the follows that should be considered
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     */
    open func my_following_illusts(until: String? = nil, publicity: Publicity = .public, limit: Int) throws -> [PixivIllustration]{
        var _until: Date
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if until != nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            _until = formatter.date(from: until!)!
        } else {
            _until = Date(timeIntervalSince1970: Date().timeIntervalSinceNow)
        }
        
        var illusts: [PixivIllustration] = []
        var count = 0
        var result = try self._aapi.illust_follow(restrict: publicity)
        while true {
            for illust in result.illusts ?? [] {
                let _illust = illust
                if count < limit && _until < _illust.creationDate {
                    count += 1
                    illusts.append(_illust)
                } else {
                    return illusts
                }
            }
            let arguments = try! self._aapi.parse_qs(url: result.nextURL?.absoluteString ?? "") // AA FORGOT TO EDIT PARSE_QS
            result = try self._aapi.illust_follow(restrict: Publicity(rawValue: arguments["restrict"] as? String ?? "")!, offset: count)
        }
    }
    
    /**
     Fetch your bookmarked illustrations
     
     - Parameter publicity: publicity of the bookmarks to fetch
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     */
    open func my_favorite_works(publicity: Publicity = .public, limit: Int) throws -> [PixivIllustration]{
        var illusts: [PixivIllustration] = []
        var result = try self._aapi.user_bookmarks_illust(user_id: self._aapi.user_id, restrict: publicity)
        while true {
            illusts = aapi_collect(result: result, targetCollection: illusts, limit: limit)
            if illusts.count == limit { return illusts }
            let arguments = try! self._aapi.parse_qs(url: result.nextURL?.absoluteString ?? "")
            result = try self._aapi.user_bookmarks_illust(user_id: arguments["user_id"] as! Int, restrict: Publicity(rawValue: arguments["restrict"] as! String)!, filter: arguments["filter"] as! String, max_bookmark: arguments["max_bookmark_id"] as? Int, tag: arguments["tag"] as? String)
        }
    }
    
    /**
     Bookmark an illustration
     
     - Parameter illust_id: Illustration ID to bookmark
     - Parameter publicity: restrict the the visibility of the bookmark, either as "public" or as "private"
     */
    open func bookmark(illust_id: Int, publicity: Publicity = .public) throws {
        let _ = try self._aapi.illust_bookmark_add(illust_id: illust_id, restrict: publicity)
    }
    
    /**
     Delete an illustration from your bookmarks
     
     - Parameter illust_id: Illustration ID to remove from your bookmarks
     */
    open func unbookmark(illust_id: Int) throws {
        let _ = try self._aapi.illust_bookmark_delete(illust_id: illust_id)
    }
    
    /**
     Follow a user
     
     - Parameter user: User ID or name to follow
     - Parameter publicity: restrict the the visibility of the follow, either as "public" or as "private"
     */
    open func follow(user: String, publicity: Publicity = .public) throws {
        let _ = try self._aapi.user_follow_add(user_id: Int(user) != nil ? Int(user)! : self.get_id_from_name(username: user), restrict: publicity)
    }
    
    /**
     Unfollow a user
     
     - Parameter user_id: User ID or name to unfollow
     */
    open func unfollow(user: String) throws {
        let _ = try self._aapi.user_follow_delete(user_id: Int(user) != nil ? Int(user)! : self.get_id_from_name(username: user))
    }
    
    /**
     Fetch illustrations recommended for you
     
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     */
    open func my_recommended(limit: Int) throws -> [PixivIllustration] {
        var illusts: [PixivIllustration] = []
        var result = try self._aapi.illust_recommended()
        while true {
            illusts = aapi_collect(result: result, targetCollection: illusts, limit: limit)
            if illusts.count == limit { return illusts }
            let arguments = try! self._aapi.parse_qs(url: result.nextURL?.absoluteString ?? "")
            result = try self._aapi.illust_recommended(content_type: arguments["content_type"] as! String, include_ranking_label: arguments["include_ranking_label"] as! Bool, filter: arguments["filter"] as! String, max_bookmark_id_for_recommend: arguments["max_bookmark_id_for_recommend"] as? Int, offset: illusts.count, include_ranking_illusts: arguments["include_ranking_ilusts"] as? Bool, include_privacy_policy: arguments["include_privacy_policy"] as? Bool)
        }
    }
    
    /**
     Fetch illustrations published by a specific user
     
     - Parameter user_id: ID or name of the user
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     */
    open func user_illusts(user: String, limit: Int) throws -> [PixivIllustration] {
        var illusts: [PixivIllustration] = []
        var result = try self._aapi.user_illusts(user_id: Int(user) != nil ? Int(user)! : self.get_id_from_name(username: user))
        while true {
            illusts = aapi_collect(result: result, targetCollection: illusts, limit: limit)
            if illusts.count == limit { return illusts }
            let arguments = try! self._aapi.parse_qs(url: result.nextURL?.absoluteString ?? "")
            result = try self._aapi.user_illusts(user_id: Int(arguments["user_id"] as? String ?? "")!, type: arguments["type"] as! String, filter: arguments["filter"] as! String, offset: illusts.count)
        }
    }
    
    /**
     Search for illustrations
     
     - Parameter query: terms to search for
     - Parameter mode: search filter; valid modes: "tag", "exact_tag", "text", "caption"
     - Parameter period: period of time where the illustrations where published; valid periods: "all", "day", "week", "month"
     - Parameter order: order the illustrations should be listed; valid orders: "desc", "asc"
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     
     NOTE: this is the only PublicAPI method in this class as it also provides sorting by popularity, which the corresponding AppAPI method doesnt
     
     */
    open func search(query: String, searchMode: AppPixivAPI.SearchMode = .partial_match_for_tags, sortMode: AppPixivAPI.SortMode = .popular_desc, limit: Int) throws -> [PixivIllustration]{
        var illusts: [PixivIllustration] = []
        var count = 0
        while true {
            
            for illust in try self._aapi.search_illust(word: query, search_target: searchMode, sort: sortMode).illusts ?? [] {
                if count < limit {
                    count += 1
                } else {
                    return illusts
                }
                illusts.append(illust)
            }
        }
    }
    
    /**
     Fetch information about a user
     
     - Parameter user: ID or name of the user whose details should be fetched
     
     - returns: the information as a SwiftyJSON json object
     */
    open func user_details(user: String) throws -> PixivResult {
        try self._aapi.user_detail(user_id: Int(user) != nil ? Int(user)! : self.get_id_from_name(username: user))
    }
    
    /**
     Download illustrations related to a given Illustration ID
     
     - Parameter illust_id: source id that should be used
     - Parameter limit: hard illustration count limit
     
     - returns a list of PixivIllustration objects
     */
    open func related_illusts(illust_id: Int, limit: Int) throws -> [PixivIllustration] {
        var illusts: [PixivIllustration] = []
        var result = try self._aapi.illust_related(illust_id: illust_id)
        while true {
            illusts = aapi_collect(result: result, targetCollection: illusts, limit: limit)
            if illusts.count == limit || (result.nextURL?.absoluteString ?? "").isEmpty { return illusts }
            let arguments = try! self._aapi.parse_qs(url: result.nextURL?.absoluteString ?? "")
            result = try self._aapi.illust_related(illust_id: arguments["illust_id"] as! Int, filter: arguments["filter"] as! String, offset: illusts.count)
        }
    }
    
    private func get_id_from_name(username: String) throws -> Int {
        let result = try self._aapi.search_user(word: username).userPreviews!.first!.user
        let result_name = result.name
        if result_name.lowercased() == username.lowercased() || result_name.lowercased().contains(username.lowercased()) || username.lowercased().contains(result_name.lowercased()) {
            return result.id
        } else {
            throw PixivError.targetNotFound(target: username)
        }
    }
    
    /**
     Download an illustration to the local disk
     
     - Parameter illustration: illustration containing data about URLs to be downloaded.
     - Parameter directory: directory on the local disk to download to.
     - Parameter convert_ugoira: whether to automatically convert ugoiras to a GIF or leave it as a ZIP file containing the images.
     - Parameter replace: whether to replace already downloaded images.
     - Parameter max_tries: number of retries until the download is canceled.
     - Parameter with_metadata: whether the download should contain metadata about itself
     
     - returns: whether the download has succeeded
     */
    open func download(illustration: PixivIllustration, directory: URL = URL(fileURLWithPath: "Downloads", relativeTo: URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)), convert_ugoira: Bool = true, replace: Bool = false, max_tries: Int = 5, with_metadata: Bool = true, previews_only: Bool = false) -> [URL] {
        
        func file_download(url: URL, directory: URL, with_metadata: Bool) -> URL? {
            var task = URLRequest(url: url)
            task.allHTTPHeaderFields = ["Referer": "https://app-api.pixiv.net/"]
            
            var succeededURL: URL? = nil
            
            let request = URLSession.shared.dataTask(with: task ) { data, response, error in
                guard let imagedata = data, error == nil else { return }
                let target = URL(fileURLWithPath: url.lastPathComponent, relativeTo: directory)
                if with_metadata {
                    self.meta_update(metadata: illustration, illust_url: target, illust_data: imagedata)
                } else {
                    guard let _ = try? imagedata.write(to: target) else { return }
                }
            }
            request.resume()
            while request.response == nil && RunLoop.current.run(mode: .default, before: .distantFuture){} // wait for the response
            
            if [200, 301, 302].contains((request.response as! HTTPURLResponse).statusCode) { // if the response signals a success, continue with setting the succeeded url and wait for it to be written to the disk
                succeededURL = directory.appendingPathComponent(request.currentRequest!.url!.lastPathComponent)
                while !FileManager.default.fileExists(atPath: succeededURL!.path) { continue }
            }
            return succeededURL
        }
        
        if !FileManager().directoryExists(directory.path) {
            try! FileManager().createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        let target_urls: [URL] = previews_only ? illustration.metaPages.map {$0.squareMedium} : illustration.metaPages.map {$0.original}
        
        var succeededURLs = [URL]()
        
        if illustration.type != .ugoira {
            succeededURLs = target_urls.map({file_download(url: $0, directory: directory, with_metadata: with_metadata)}).compactMap({$0})
        } else {
            if previews_only { succeededURLs = target_urls.map({file_download(url: $0, directory: directory, with_metadata: with_metadata)}).compactMap({$0}) } else {
                let illust_metadata = try! self._aapi.ugoira_metadata(illust_id: illustration.id)
                if var succeededURL = file_download(url: illust_metadata.ugoiraMetadata!.zipUrls.medium, directory: convert_ugoira ? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true) : directory, with_metadata: false) {
                    if convert_ugoira {
                        self.zip_to_ugoira(zip: succeededURL, destination: directory, delay: illust_metadata.ugoiraMetadata!.frames.first!.delay)
                        succeededURL = URL(fileURLWithPath: succeededURL.lastPathComponent, relativeTo: directory)
                    }
                    succeededURLs.append(succeededURL)
                }
            }
        }
        return succeededURLs
    }

    /**
     Update the metadata of an image
     
     - Parameter metadata: PixivIllustration object containing metadata that should be aplied to the image
     - Parameter illust_path: path to the image
     - Parameter illust_data: Data object containing image data that should be update (illust_path is nescessary anyway as this function also writes the new data)
     */
    open func meta_update(metadata: PixivIllustration, illust_url: URL, illust_data: Data? = nil){
        let image: CGImageSource
        let file_url: URL = illust_url
        if let illust_data = illust_data {
            image = CGImageSourceCreateWithData(illust_data as CFData, nil)!
        } else {
            image = CGImageSourceCreateWithURL(file_url as CFURL, nil)!
        }
        var properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? Dictionary<String, Any> ?? [:]
        
        var translations: [String] = []
        for dict in metadata.tags {
            dict.translatedName != nil ? translations.append(dict.translatedName!) : translations.append(dict.name)
        }
        
        if properties["{IPTC}"] == nil {
            properties["{IPTC}"] = [:]
        }
        
        let IPTCmetadata: [String: Any] = [
            "Keywords": translations,
            "ObjectName": metadata.title,
            "ObjectType": metadata.type == .illust ? "illustration" : metadata.type.rawValue,
            "Caption/Abstract": metadata.caption,
            "Source": metadata.imageUrls.original.deletingLastPathComponent().appendingPathComponent(illust_url.lastPathComponent)
            
        ]
        properties.updateValue(IPTCmetadata, forKey: "{IPTC}")
        
        let TIFFmetadata: [String:Any] = [
            "Artist": metadata.user.name,
            "DateTime": metadata.creationDate
        ]
        properties.updateValue(TIFFmetadata, forKey: "{TIFF}")
        
        var img_type: CFString
        if illust_url.absoluteString.contains(".png") {
            img_type = kUTTypePNG
        } else if illust_url.absoluteString.contains(".jpg") {
            img_type = kUTTypeJPEG
        } else if illust_url.absoluteString.contains(".gif") {
            img_type = kUTTypeGIF
            try! JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: Data(properties.description.utf8), options: []), options: .prettyPrinted).write(to: illust_url.appendingPathExtension("txt"))
        } else {
            fatalError("unexpected image type")
        }
        let new_image = CGImageDestinationCreateWithURL(file_url as CFURL, img_type, CGImageSourceGetCount(image), nil)
        CGImageDestinationAddImageFromSource(new_image!, image, 0, properties as CFDictionary)
        CGImageDestinationFinalize(new_image!)
    }
    
    /**
     Convert a given ZIP file with images to an ugoira (GIF) image
     
     - Parameter zip: path to a zip_file
     - Parameter destination: path to a directory where the resulting GIF will be copied to
     - Parameter delay: delay between each frame of the GIF
     */
    private func zip_to_ugoira(zip: URL, destination: URL, delay: Int) {
        if FileManager().fileExists(atPath: zip.path) {
            let unzipped_url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(zip.deletingPathExtension().lastPathComponent, isDirectory: true)
            do {
                try Zip.unzipFile(zip, destination: unzipped_url, overwrite: true, password: nil)
            } catch {
                print("unzip of \(zip.lastPathComponent) failed: \(error.localizedDescription)")
                return
            }
            
            let gif_destination = CGImageDestinationCreateWithURL(destination.appendingPathComponent(zip.deletingPathExtension().appendingPathExtension("gif").lastPathComponent) as CFURL, kUTTypeGIF, try! FileManager().contentsOfDirectory(atPath: unzipped_url.path).count, [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary)
            
            for image in try! FileManager().contentsOfDirectory(atPath: unzipped_url.path).sorted() {
                CGImageDestinationAddImage(gif_destination!, CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: image, relativeTo: unzipped_url) as CFURL, nil)!, 0, nil)!, [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFUnclampedDelayTime as String: Double(delay)/Double(1000)]] as CFDictionary)
            }
            CGImageDestinationFinalize(gif_destination!)
        } else {
            print("ZIP for ugoira not existing! Affected path: \(zip)")
        }
    }
}
