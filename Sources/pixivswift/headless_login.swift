//
//  headless_login.swift
//  
//
//  Created by Fabio Mauersberger on 01.07.21.
//

#if canImport(Erik)
import Erik
import WebKit
import CryptoKit
import Foundation
import CommonCrypto

extension BasePixivAPI {
    
    public func oauth_pkce() -> (String, String) {
        var keyData = Data(count: 32)
        let _ = keyData.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        
        var code_verifier = keyData.base64EncodedString()
        code_verifier.removeLast()
        code_verifier = code_verifier.replacingOccurrences(of: "+", with: "-")
        code_verifier = code_verifier.replacingOccurrences(of: "/", with: "_")
        
        var code_challenge: String = { () -> Data in
            if #available(macOS 10.15, iOS 13, *) {
                return Data(SHA256.hash(data: code_verifier.data(using: .ascii)!))
            } else {
                var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
                Data(code_verifier.utf8).withUnsafeBytes {
                    _ = CC_SHA256($0.baseAddress, CC_LONG(Data(code_verifier.utf8).count), &hash)
                }
                return Data(hash)
            }
        }().base64EncodedString()
        code_challenge.removeLast()
        code_challenge = code_challenge.replacingOccurrences(of: "+", with: "-")
        code_challenge = code_challenge.replacingOccurrences(of: "/", with: "_")
        
        return (code_verifier, code_challenge)
    }
    
    public func handle_code(_ code: String, code_challenge: String, code_verifier: String) -> String {
        let data = [
            "client_id": "MOBrBDS8blbauoSck0ZfDbtuzpyT",
            "client_secret": "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj",
            "code": code,
            "code_verifier": code_verifier,
            "grant_type": "authorization_code",
            "include_policy": "true",
            "redirect_uri": "https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback",
        ]
        var auth_components = URLComponents()
        auth_components.queryItems = data.map({URLQueryItem(name: $0.key, value: ($0.value))})
        
        var code_req = URLRequest(url: URL(string: "https://oauth.secure.pixiv.net/auth/token")!)
        code_req.addValue("PixivAndroidApp/5.0.234 (Android 11; Pixel 5)", forHTTPHeaderField: "User-Agent")
        code_req.httpMethod = "POST"
        code_req.httpBody = auth_components.url!.query!.data(using: .utf8)
        
        var response = ""
        
        let _ = URLSession.shared.dataTask(with: code_req) { data, _, error in
            guard let data = data, error == nil else { print("Failure!"); response = "{}"; return}
            response = String(data: data, encoding: .utf8)!
        }.resume()
        
        while response.isEmpty {
            continue
        }
        return response
    }
    
    func login(username: String, password: String) throws -> String {
        let web = WKWebView()
        let erik = Erik(webView: web)
        
        var code = ""
        
        var _ = web.observe(\.url, options: .new) {webView, change in
            if let value = change.newValue {
                if let value = value {
                    if value.scheme == "pixiv" {
                        let components = URLComponents(url: value, resolvingAgainstBaseURL: false)!
                        code = components.queryItems!.first(where: { queryItem -> Bool in queryItem.name == "code" })!.value!
                    }
                }
            }
        }
        
        
        let (code_verifier, code_challenge) = oauth_pkce()
        
        let login_params = [
            "code_challenge": code_challenge,
            "code_challenge_method": "S256",
            "client": "pixiv-android"
        ]
        
        var params_string = ""
        for (key, val) in login_params {
            params_string += "\(key)=\(val)&"
        }
        params_string.removeLast()
        
        let url = URL(string:"https://app-api.pixiv.net/web/v1/login?"+params_string)!
        
        var response = ""
        
        var error: Error? = nil
        
        erik.visit(url: url) { document, _ in
            guard let document = document else { return }
            
            if let b = document.querySelectorAll("button[class=\"button secondary\"]").first {
                b.click()
            }
            
            erik.visit(url: erik.url!) { document, _ in
                guard let document = document else { return }
                
                if let username_input = document.querySelectorAll("input[type=\"text\"]").dropFirst().first {
                    username_input["value"] = username
                }
                if let passwd_input = document.querySelectorAll("input[type=\"password\"]").dropFirst().first { passwd_input["value"] = password
                }
                document.querySelectorAll("button[type=\"submit\"]")[1].click {doc,_ in
                    
                    if (doc as! Document).toHTML!.contains("Please check") {
                        error = PixivError.AuthErrors.authFailed("Wrong PixivID/username or password!")
                    }
                    
                    while code.isEmpty {
                        continue
                    }
                    
                    response = self.handle_code(code, code_challenge: code_challenge, code_verifier: code_verifier)
                    
                }
            }
        }
        if let error = error {
            throw error
        } else {
            return response
        }
    }
}
#endif
