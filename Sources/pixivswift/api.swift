//
//  api.swift
//  pixivswift
//
//  Created by theBreadCompany on 16.04.21.
//  Original work written in Python by https://github.com/upbit.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
/**
 Class to be used by any API classes
 */
public class BasePixivAPI {
    
    private var client_id: String
    private var client_secret: String
    private let hash_secret: String
    
    public var access_token: String
    public var user_id: Int
    public var refresh_token: String
    
    public var hosts: URL?
    
    
    public init() {
        self.client_id = "MOBrBDS8blbauoSck0ZfDbtuzpyT"
        self.client_secret = "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj"
        self.hash_secret = "28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c"
        
        self.access_token = ""
        self.user_id = 0
        self.refresh_token = ""
        
        self.hosts = nil
    }
    
    
    internal func parse_json(json: String) -> Dictionary<String, Any> {
        if let jsonData = try? JSONSerialization.jsonObject(with: Data(json.utf8), options: []) as? Dictionary<String, Any> {
            return jsonData
        } else {
            return Dictionary<String, Any>()
        }
    }
    
    internal func parse_date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter.string(from: date)
    }
    
    /**
     throw exception if there is no access token
     */
    internal func require_auth() throws {
        if self.access_token.isEmpty {
            throw PixivError.AuthErrors.missingAuth("Authentication required! Call login() or set_auth() first!")
        }
    }
    
    internal func requests_call(method: HttpMethod, url: URL, headers: Dictionary<String, Any> = [:], params: Dictionary<String, Any> = [:], data: Dictionary<String, Any> = [:], stream: Bool = false) throws -> String {
        
        var _url = URLComponents(url: url, resolvingAgainstBaseURL: url.baseURL != nil)
        _url?.queryItems = params.map { URLQueryItem(name: $0, value: ($1 as! String)) }
        guard let queryURL = _url?.url else { throw PixivError.responseAcquirationFailed("Failed to build URL!") }
        var req = URLRequest(url: queryURL)
        req.allHTTPHeaderFields = (headers as! [String:String])
        req.httpMethod = method.rawValue
        
        if !data.isEmpty {
            var components = URLComponents()
            components.queryItems = data.map( {URLQueryItem(name: $0.key, value: ($0.value as! String))} )
            req.httpBody = components.url!.query!.data(using: .utf8)
        }
        
        var responseData: String = ""
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: req ) { data, _, error in
            if let data = data, error == nil {
                // the warning about thread safety will have to stay until I've refactored this thing to use actual async syntax
                responseData = String(data: data, encoding: .utf8) ?? ""
            }
            semaphore.signal()
        }
        task.resume()
        
        semaphore.wait()
        
        guard !responseData.isEmpty else { throw PixivError.responseAcquirationFailed("No response data!") }
        guard let response = task.response as? HTTPURLResponse else { throw PixivError.responseAcquirationFailed("Response conversion failed!") }
        
        switch response.statusCode {
        case 200, 301, 302:
            break
        case 400:
            throw PixivError.responseAcquirationFailed("Bad request, reason: \(responseData)")
        case 403:
            throw PixivError.RateLimitError
        case 404:
            throw PixivError.targetNotFound(data.description)
        default:
            throw PixivError.unknownException("Request failed with HTTP Error \(response.statusCode); response: \(responseData)")
        }
        return responseData
    }
    
    /**
     use already received credentials to prevent yet another login query
     - Parameter access_token: the access token used to actually authorize any calls to the API
     - Parameter refresh_token: the refresh token used to re-login when the access token has lost its validity
     */
    public func set_auth(access_token: String, refresh_token: String? = nil) {
        self.access_token = access_token
        self.refresh_token = refresh_token!
    }
    
    /**
     use your own client identity
     
     
     In case
     */
    public func set_client(client_id: String, client_secret: String) {
        self.client_id = client_id
        self.client_secret = client_secret
    }
    
    #if canImport(Erik)
    public func auth(username: String = "", password: String = "", refresh_token: String = "") throws -> Dictionary<String, Any> {
        try self._auth(username: username, password: password, refresh_token: refresh_token)
    }
    #else
    public func auth(refresh_token: String = "") throws -> Dictionary<String, Any> {
        try self._auth(refresh_token: refresh_token)
    }
    #endif
    
    private func _auth(username: String = "", password: String = "", refresh_token: String = "") throws -> Dictionary<String, Any> {
        assert(!refresh_token.isEmpty || (!username.isEmpty && !password.isEmpty), "auth() has been called, but without any credentials or refresh_token")
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("y-m-dTH:m:s+00:00")
        let local_time = formatter.string(from: Date())
        var headers = [
            "User-Agent": "PixivAndroidApp/5.0.115 (Android 6.0; PixivBot)",
            "X-Client-Time": local_time,
            "X-Client-Hash": (local_time + self.hash_secret).MD5
        ]
        
        var auth_hosts: URL
        if self.hosts == nil || self.hosts == URL(string: "https://app-api.pixiv.net/")! {
            auth_hosts = URL(string: "https://oauth.secure.pixiv.net")!
        } else {
            auth_hosts = self.hosts!
            headers["host"] = "oauth.secure.pixiv.net"
        }
        
        let url = URL(string: "\(auth_hosts)/auth/token")!
        var data = [
            "get_secure_url": 1.description,
            "client_id": self.client_id,
            "client_secret": self.client_secret,
        ] as [String : String]
        
        var token: Dictionary<String, Any> = [:]
        if !refresh_token.isEmpty || !self.refresh_token.isEmpty {
            data["grant_type"] = "refresh_token"
            data["refresh_token"] = !refresh_token.isEmpty ? refresh_token : self.refresh_token
            
            guard let r = try? self.requests_call(method: .POST, url: url, headers: headers, data: data) else {
                throw PixivError.AuthErrors.authFailed("auth() failed! check refresh_token.")
            }
            guard let _token = self.parse_json(json: r.description)["response"] as? Dictionary<String, Any> else {
                throw PixivError.AuthErrors.authFailed("Response failed for unknown reasons! Result: \(self.parse_json(json: r.description))")
            }
            token = _token
        }
#if canImport(Erik)
        if !username.isEmpty && !password.isEmpty {
            do {
                token = try self.parse_json(json: self.login(username: username, password: password))
            } catch let e {
                if e as? HeadlessLoginError == .recognition {
                    Thread.sleep(forTimeInterval: .init(10)) // wait then retry, usually works
                    token = try self.parse_json(json: self.login(username: username, password: password))
                } else {
                    throw e
                }
            }
        }
#endif
        
        // I hate native JSON. But no, I won't use third party libs, I know that there are great parsers for this, but I don't want dependencies :/
        if let access_token = token["access_token"] as? String,
           let user_id = Int((token["user"] as? Dictionary<String, Any>)?["id"] as? String ?? ""),
           let refresh_token = token["refresh_token"] as? String {
            self.access_token = access_token
            self.user_id = user_id
            self.refresh_token = refresh_token
        }
        
        return token
    }
    
    /**
     download an URL to the local storage
     - Parameter url: URL of the file
     - Parameter prefix: (optional) prefix for the filename
     - Parameter path: path to the target directory
     - Parameter name: (optional) new name for the file
     - Parameter replace: replace if already existing
     - Parameter referer: a referer the URLRequest should refer to, default is recommended
     - returns: whether the download succeeded
     */
    public func download(url: URL, prefix: String = "", path: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true), name: String? = nil, replace: Bool = false, referer: URL = URL(string: "https://app-api.pixiv.net/")!) -> Bool{
        var _name: String
        if let name = name {
            _name = name
        } else {
            _name = url.absoluteString.split(separator: "/").last!.description
        }
        
        if !_name.isEmpty {
            _name = prefix + _name
            let targetURL = path.appendingPathComponent(_name).absoluteURL
            
            if FileManager.default.fileExists(atPath: targetURL.path) { return true }
            
            var req = URLRequest(url: url)
            req.allHTTPHeaderFields = ["Referer": referer.absoluteString]
            let task = URLSession.shared.downloadTask(with: req) { url, _, error in
                guard let url = url, error == nil else { return }
                guard let _ = try? FileManager.default.moveItem(at: url, to: targetURL) else { return }
                
                
            }
            task.resume()
            while task.state != .completed { }
            return (task.error == nil)
            
        }
        return false
    }
    
    internal func log(_ messages: Any...) {
        #if DEBUG
        print(messages)
        #endif
    }
}

