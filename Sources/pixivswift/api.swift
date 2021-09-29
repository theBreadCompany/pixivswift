//
//  File.swift
//  pixivswift
//
//  Created by Fabio Mauersberger on 16.04.21.
//  Original work written in Python by https://github.com/upbit.
//

import Foundation
import SwiftyJSON

public class BasePixivAPI {
    
    private var client_id: String
    private var client_secret: String
    private let hash_secret: String
    
    public var access_token: String
    public var user_id: Int
    public var refresh_token: String
    
    public var hosts: String
    
    
    public init() {
        self.client_id = "MOBrBDS8blbauoSck0ZfDbtuzpyT"
        self.client_secret = "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj"
        self.hash_secret = "28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c"
        
        self.access_token = ""
        self.user_id = 0
        self.refresh_token = ""
        
        self.hosts = ""
    }
    
    
    public func parse_json(json: String) -> JSON {
        do {
            return try JSON(data: Data(json.utf8))
        } catch {
            return [:]
        }
    }
    
    public func parse_date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter.string(from: date)
    }
    
    /**
     throw exception if there is access token
     */
    public func require_auth() throws {
        if self.access_token.isEmpty {
            throw PixivError.AuthErrors.missingAuth("Authentication required! Call login() or set_auth() first!")
        }
    }
    
    public func requests_call(method: HttpMethod, url: URL, headers: Dictionary<String, Any> = [:], params: Dictionary<String, Any> = [:], data: Dictionary<String, Any> = [:], stream: Bool = false) throws -> String {
        var response: HTTPURLResponse = HTTPURLResponse()
        var response_data: String = ""
        
        var _url = URLComponents(url: url, resolvingAgainstBaseURL: false)
        _url?.queryItems = params.map { URLQueryItem(name: $0, value: ($1 as! String)) }
        var task = URLRequest(url: URL(string: _url!.string!)!)
        task.allHTTPHeaderFields = (headers as! [String:String])
        task.httpMethod = method.rawValue
        
        if !data.isEmpty {
            var components = URLComponents()
            components.queryItems = data.map( {URLQueryItem(name: $0.key, value: ($0.value as! String))} )
            task.httpBody = components.url!.query!.data(using: .utf8)
        }
        
        let _ = URLSession.shared.dataTask(with: task ) { data, _response, error in
            guard let data = data, error == nil else { return }
            response = _response as! HTTPURLResponse
            response_data = String(data: data, encoding: .utf8)!
        }.resume()
        
        
        while response_data.isEmpty {
            continue
        }
        
        switch response.statusCode {
        case 200, 301, 302:
            break
        case 400:
            throw PixivError.badProgramming(misstake: "Bad request!")
        case 403:
            if response_data.contains("Rate Limit") { throw PixivError.RateLimitError }
        case 404:
            throw PixivError.targetNotFound(target: data.description)
        default:
            throw PixivError.unknownException("Request failed with HTTP Error \(response.statusCode); response: \(response_data)")
        }
        return response_data
    }
    
    public func set_auth(access_token: String, refresh_token: String? = nil) {
        self.access_token = access_token
        self.refresh_token = refresh_token!
    }
    
    public func set_client(client_id: String, client_secret: String) {
        self.client_id = client_id
        self.client_secret = client_secret
    }
    
    public func auth(username: String = "", password: String = "", refresh_token: String = "") throws -> JSON {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("y-m-dTH:m:s+00:00")
        let local_time = formatter.string(from: Date())
        var headers = [
            "User-Agent": "PixivAndroidApp/5.0.115 (Android 6.0; PixivBot)",
            "X-Client-Time": local_time,
            "X-Client-Hash": (local_time + self.hash_secret).MD5
        ]
        
        var auth_hosts: String
        if self.hosts.isEmpty || self.hosts == "https://app-api.pixiv.net" {
            auth_hosts = "https://oauth.secure.pixiv.net"
        } else {
            auth_hosts = self.hosts
            headers["host"] = "oauth.secure.pixiv.net"
        }
        
        let url = URL(string: "\(auth_hosts)/auth/token")!
        var data = [
            "get_secure_url": 1.description,
            "client_id": self.client_id,
            "client_secret": self.client_secret,
        ] as [String : String]
        
        let token: JSON
        if !username.isEmpty && !password.isEmpty {
            do {
                token = try self.parse_json(json: self.login(username: username, password: password))
            } catch let e {
                if e as? HeadlessLoginError == HeadlessLoginError.recognition {
                    Thread.sleep(forTimeInterval: .init(10)) // wait then retry, mostly works
                    token = try self.parse_json(json: self.login(username: username, password: password))
                } else {
                    throw e
                }
            }
        } else if !refresh_token.isEmpty || !self.refresh_token.isEmpty {
            data["grant_type"] = "refresh_token"
            data["refresh_token"] = !refresh_token.isEmpty ? refresh_token: self.refresh_token
            
            let r: String
            do {
                r = try self.requests_call(method: .POST, url: url, headers: headers, data: data)
            } catch PixivError.badProgramming /* 400 is generally a bad request, so a login error is a more specific version of that */ {
                throw PixivError.AuthErrors.authFailed("auth() failed! check refresh_token.")
            }
            token = self.parse_json(json: r.description)["response"]
        } else {
            throw PixivError.badProgramming(misstake: "auth() has been called, but without any credentials or refresh_token")
        }

        
        self.access_token = token["access_token"].stringValue
        self.user_id = token["user"]["id"].intValue
        self.refresh_token = token["refresh_token"].stringValue
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
    public func download(url: URL, prefix: String = "", path: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true), name: String? = nil, replace: Bool = false, referer: URL = URL(string: "https://app-api.pixiv.net")!) -> Bool{
        var _name = ""
        if let name = name {
            _name = name
        } else {
            _name = url.absoluteString.split(separator: "/").last!.description
        }
        
        var img_path = ""
        if !_name.isEmpty {
            _name = prefix + _name
            img_path = "\(path)/\(_name)"
            
            if FileManager.default.fileExists(atPath: img_path) {
                return true
            }
            
            var task = URLRequest(url: url)
            task.allHTTPHeaderFields = ["Referer": referer.absoluteString]
            var error_occured = false
            let _ = URLSession.shared.dataTask(with: task) { data, _, error in
                guard let data = data, error == nil else { return }
                guard let _ = try? data.write(to: URL(fileURLWithPath: img_path), options: []) else { error_occured = true; return }
            }
            return !error_occured
            
        }
        return false
    }
}

