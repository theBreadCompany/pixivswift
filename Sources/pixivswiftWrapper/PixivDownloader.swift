//
//  PixivDownloader.swift
//  pixivswiftWrapper
//
//  Created by theBreadCompany on 16.04.21.
//  Original work written in Python by https://github.com/Xdynix.
//

import Foundation
import ZIPFoundation
import pixivswift

#if canImport(FoundationNetworking)
import FoundationNetworking
import GIF
import SwiftGD
#endif

private let TOKEN_LIFETIME = 2700

open class PixivDownloader {
    
    public let auto_relogin: Bool
    public let _aapi: AppPixivAPI
    
    public var authed: Bool {
        !self._aapi.refresh_token.isEmpty
    }
    public var last_login: Date?
    public var refresh_token: String?
    
    public init(auto_relogin: Bool = true) {
        self.auto_relogin = auto_relogin
        self._aapi = AppPixivAPI()
        self.last_login = nil
        self.refresh_token = nil
    }
    /*
     init with logged in client
     */
    public init(login_with_token refresh_token: String, auto_relogin: Bool = true) {
        self.auto_relogin = auto_relogin
        self._aapi = AppPixivAPI()
        self.last_login = nil
        self.refresh_token = nil
        self.login(refresh_token: refresh_token)
    }
    
#if canImport(Erik)
    public func login(username: String? = nil, password: String? = nil, refresh_token: String? = nil) { self._login(username: username, password: password, refresh_token: refresh_token) }
#else
    public func login(refresh_token: String? = nil) { self._login(refresh_token: refresh_token) }
#endif
    /**
     Login
     
     - Parameter username: the username of your account
     - Parameter password: the password of your account
     - Parameter refresh_token: a refresh\_token that grants access to your account
     */
    private func _login(username: String? = nil, password: String? = nil, refresh_token: String? = nil) {
        
        if let refresh_token = refresh_token {
            do {
                let _ = try self._aapi.auth(refresh_token: refresh_token)
                self.refresh_token = refresh_token
            } catch {
                NSLog("Login failed")
            }
        }
#if canImport(Erik)
        if let username = username, let password = password {
            do {
                let _ = try self._aapi.auth(username: username, password: password)
                self.refresh_token = self._aapi.refresh_token
            } catch {
                print("Login failed")
            }
        }
#endif
        
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
     
     - Parameter until: optional filter by date
     - Parameter publicity: publicity of the follows that should be considered
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     */
    open func my_following_illusts(until earliestDate: Date? = nil, publicity: Publicity = .public, limit: Int) throws -> [PixivIllustration]{
        var result = try self._aapi.illust_follow(restrict: publicity)
        while (result.illusts ?? []).count <= limit && (result.illusts ?? []).allSatisfy({$0.creationDate >= earliestDate ?? Date(timeIntervalSince1970: 0)}) {
            let arguments = self._aapi.parse_qs(url: result.nextURL)
            result += try self._aapi.illust_follow(restrict: Publicity(rawValue: arguments["restrict"] as? String ?? "") ?? publicity, offset: Int(arguments["offset"] as? String ?? "") ?? (result.illusts ?? []).count)
        }
        return Array((result.illusts ?? [])[0...(limit<<(result.illusts ?? []).count)-1]).filter({$0.creationDate >= earliestDate ?? Date(timeIntervalSince1970: 0)})
    }
    
    /**
     Fetch your bookmarked illustrations
     
     - Parameter publicity: publicity of the bookmarks to fetch
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     */
    open func my_favorite_works(publicity: Publicity = .public, limit: Int) throws -> [PixivIllustration]{
        var result = try self._aapi.user_bookmarks_illust(user_id: self._aapi.user_id, restrict: publicity)
        while (result.illusts ?? []).count <= limit {
            let arguments = self._aapi.parse_qs(url: result.nextURL)
            result += try self._aapi.user_bookmarks_illust(user_id: Int(arguments["user_id"] as? String ?? "x") ?? self._aapi.user_id, restrict: Publicity(rawValue: arguments["restrict"] as? String ?? "") ?? publicity, filter: arguments["filter"] as? String ?? "for_ios", max_bookmark: Int(arguments["max_bookmark_id"] as? String ?? "x"), tag: arguments["tag"] as? String)
        }
        return Array((result.illusts ?? [])[0...limit-1])
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
        var result = try self._aapi.illust_recommended()
        while (result.illusts ?? []).count <= limit {
            let arguments = self._aapi.parse_qs(url: result.nextURL)
            result += try self._aapi.illust_recommended(content_type: arguments["content_type"] as! String, include_ranking_label: arguments["include_ranking_label"] as! Bool, filter: arguments["filter"] as? String ?? "for_ios", max_bookmark_id_for_recommend: Int(arguments["max_bookmark_id_for_recommend"] as? String ?? "x"), offset: Int(arguments["offset"] as? String ?? "") ?? (result.illusts ?? []).count, include_ranking_illusts: arguments["include_ranking_ilusts"] as? Bool, include_privacy_policy: arguments["include_privacy_policy"] as? Bool)
        }
        return Array((result.illusts ?? [])[0...limit-1])
    }
    
    /**
     Fetch illustrations published by a specific user
     
     - Parameter user_id: ID or name of the user
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     */
    open func user_illusts(user: String, limit: Int) throws -> [PixivIllustration] {
        let userID: Int = Int(user) != nil ? Int(user)! : try self.get_id_from_name(username: user)
        var result = try self._aapi.user_illusts(user_id: userID)
        while (result.illusts ?? []).count <= limit {
            let arguments = self._aapi.parse_qs(url: result.nextURL)
            result += try self._aapi.user_illusts(user_id: Int(arguments["user_id"] as? String ?? "x") ?? userID, type: arguments["type"] as? String ?? "illusts", filter: arguments["filter"] as? String ?? "for_ios", offset: result.illusts?.count ?? 0)
        }
        return Array((result.illusts ?? [])[0...limit-1])
    }
    
    /**
     Search for illustrations
     
     - Parameter query: terms to search for
     - Parameter searchMode: detail accuracy filter
     - Parameter sortMode: whether to sort by date or by popularity (adcending or descending respectivly)
     - Parameter limit: hard illustration count limit
     
     - returns: a list of PixivIllustration objects
     - Note: The popularity filters will only work if the account is authorized for premium; server will otherwise default to date
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
        var result = try self._aapi.illust_related(illust_id: illust_id)
        while (result.illusts ?? []).count <= limit {
            let arguments = self._aapi.parse_qs(url: result.nextURL)
            result += try self._aapi.illust_related(illust_id: Int(arguments["illust_id"] as? String ?? "x") ?? illust_id, filter: arguments["filter"] as? String ?? "for_ios", seed_illust_ids: arguments["seed_illust_ids"] as? Array<Int>, viewed: arguments["viewed"] as? Array<Int>, offset: Int(arguments["offset"] as? String ?? "") ?? (result.illusts ?? []).count)
        }
        return Array((result.illusts ?? [])[0...limit-1])
    }
    
    private func get_id_from_name(username: String) throws -> Int {
        guard let result = try self._aapi.search_user(word: username).userPreviews?.first?.user else { throw PixivError.targetNotFound(username) }
        let result_name = result.name
        if result_name.lowercased() == username.lowercased() || result_name.lowercased().contains(username.lowercased()) || username.lowercased().contains(result_name.lowercased()) {
            return result.id
        } else {
            throw PixivError.targetNotFound(username)
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
            
            let semaphore = DispatchSemaphore(value: 0)
            
            let request = URLSession.shared.downloadTask(with: task) { tempurl, _, error in
                guard let tempurl = tempurl, error == nil else { semaphore.signal(); return }
                let target = URL(fileURLWithPath: url.lastPathComponent, relativeTo: directory)
                if with_metadata {
                    self.meta_update(metadata: illustration, illust_url: tempurl)
                }
                do { try FileManager.default.moveItem(at: tempurl, to: target) } catch { semaphore.signal(); return }
                semaphore.signal()
            }
            request.resume()
            semaphore.wait() // wait for the response
            
            guard let response = request.response as? HTTPURLResponse else { return nil }
            return [200, 301, 302].contains(response.statusCode) // if the response signals a success, continue with setting the succeeded url and wait for it to be written to the disk
            ? directory.appendingPathComponent(url.lastPathComponent)
            : nil
        }
        
        if !FileManager().directoryExists(directory.path) {
            try! FileManager().createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        let target_urls: [URL] = previews_only ? illustration.illustrationURLs.map {$0.squareMedium} : illustration.illustrationURLs.map {$0.original}
        
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
     Convert a given ZIP file with images to an ugoira (GIF) image and saves it to a file
     
     - Parameter zip: path to a zip_file
     - Parameter destination: path to a directory where the resulting GIF will be copied to
     - Parameter delay: delay between each frame of the GIF
     */
    private func zip_to_ugoira(zip: URL, destination: URL, delay: Int) {
#if canImport(ImageIO)
        do {
            let unzipped_url = try self.unzip(zipURL: zip)
            
            let gif_destination = CGImageDestinationCreateWithURL(destination.appendingPathComponent(zip.deletingPathExtension().appendingPathExtension("gif").lastPathComponent) as CFURL, kUTTypeGIF, try FileManager().contentsOfDirectory(atPath: unzipped_url.path).count, [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary)
            
            for image in try FileManager().contentsOfDirectory(atPath: unzipped_url.path).sorted() {
                CGImageDestinationAddImage(gif_destination!, CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: image, relativeTo: unzipped_url) as CFURL, nil)!, 0, nil)!, [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFUnclampedDelayTime as String: Double(delay)/Double(1000)]] as CFDictionary)
            }
            CGImageDestinationFinalize(gif_destination!)
        } catch {
            print(error.localizedDescription)
        }
#endif
    }
    
    private func zip_to_ugoira(zip: URL, delay: Int) throws -> Data {
        let unzippedURL = try self.unzip(zipURL: zip)
        
#if canImport(ImageIO)
        let imgData = Data() as! CFMutableData
        
        let gifDestination = CGImageDestinationCreateWithData(imgData, kUTTypeGIF, try FileManager().contentsOfDirectory(atPath: unzippedURL.path).count, [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary)
        
        for image in try FileManager().contentsOfDirectory(atPath: unzippedURL.path).sorted() {
            CGImageDestinationAddImage(gifDestination!, CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: image, relativeTo: unzippedURL) as CFURL, nil)!, 0, nil)!, [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFUnclampedDelayTime as String: Double(delay)/Double(1000)]] as CFDictionary)
        }
        CGImageDestinationFinalize(gifDestination!)
        return imgData as Data
#else
        let sortedSources = try FileManager().contentsOfDirectory(atPath: unzippedURL.path).sorted()
        let first = Image(url: URL(fileURLWithPath: sortedSources.first!))
        var gifDestination = GIF(quantizingImage: try! .init(pngData: first!.export()))
        for i in 1..<sortedSources.count {
            gifDestination.frames.append(.init(image:try! .init(pngData: Image(url: URL(fileURLWithPath: sortedSources[i]))!.export())))
        }
        return try gifDestination.encoded()
#endif
    }
    
    /**
     Dumps the content of a zip file on the disk
     
     - Parameter zipURL: path to the zip file
     - returns: the URL to the directory containing the contents
     - throws: ZipError.fileNotFound or ZipError.unzipFailed
     */
    private func unzip(zipURL: URL) throws -> URL {
        if FileManager.default.fileExists(atPath: zipURL.path) {
            let unzippedURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(zipURL.deletingPathExtension().lastPathComponent, isDirectory: true)
            
            if !FileManager().directoryExists(unzippedURL.path) {
                try FileManager.default.createDirectory(at: unzippedURL, withIntermediateDirectories: false)
            }
            try FileManager.default.unzipItem(at: zipURL, to: unzippedURL)
            //try Zip.unzipFile(zipURL, destination: unzipped_url, overwrite: true, password: nil)
            return unzippedURL
        } else {
            throw URLError(.fileDoesNotExist)
        }
    }
}

#if canImport(Combine)
extension PixivDownloader: ObservableObject {}
#endif
