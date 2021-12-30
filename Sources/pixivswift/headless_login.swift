//
//  headless_login.swift
//  pixivswift
//
//  Created by Fabio Mauersberger on 01.07.21.
//  This is cursed and bad code.

#if canImport(Erik)
import Erik
#endif
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
    
    #if canImport(Erik)
    
    func login(username: String, password: String) throws -> String {
        var shouldKeepRunning = true

        let h = pixivURLHandler()
                
        let c = WKWebViewConfiguration()
        c.setURLSchemeHandler(h, forURLScheme: "pixiv")
        let web = WKWebView(frame: .init(), configuration: c)
        let erik = Erik(webView: web)
        
        let (code_verifier, code_challenge) = oauth_pkce()

        var response = ""
            
        var compontents = URLComponents(string: "https://app-api.pixiv.net/web/v1/login")!
        compontents.queryItems = [
            URLQueryItem(name: "code_challenge", value: code_challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "client", value: "pixiv-android")
        ]

        var error: HeadlessLoginError? = nil
        
        erik.visit(url: compontents.url!) { document, err in
            if err == nil, let document = document {
                print("succeded")
                print(document.querySelectorAll("button"))
                
                if let _ = document.querySelectorAll("button.sc-1lncwd-0.fmkwSU.vsvtes-6.lnXvUo").first {
                    // we just crash if we get recognised
                    error = .recognition
                    shouldKeepRunning = false
                    return
                }
                
                erik.currentContent { document, _ in
                                                
                    guard let document = document else { shouldKeepRunning = false; print("something failed!"); return}
                    
                    if let username_input = document.querySelectorAll("input[type=\"text\"]").first {
                        username_input["value"] = username
                    }
                    if let passwd_input = document.querySelectorAll("input[type=\"password\"]").first {
                        passwd_input["value"] = password
                    }
                    
                    if let form = document.querySelectorAll("button.signup-form__submit").first {
                        form.click()
                    }
                    
                    shouldKeepRunning = false
                }
            } else {
                shouldKeepRunning = false
                print("failed!")
            }
        }
        
        if let error = error { throw error }
        
        while shouldKeepRunning && RunLoop.current.run(mode: .default, before: .distantFuture) { }
        shouldKeepRunning = true
        
        
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: .init(10))
            shouldKeepRunning = false
        }

        while shouldKeepRunning && RunLoop.current.run(mode: .default, before: .distantFuture) { }
        
        if !h.code.isEmpty {
            response = handle_code(h.code, code_challenge: code_challenge, code_verifier: code_verifier)
        } else {
            error = .badCredentials
        }
        
        if let error = error {
            throw error
        } else {
            return response
        }
    }
    
    #endif
}

fileprivate class pixivURLHandler: NSObject, WKURLSchemeHandler {
    
    var code = ""
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems?.forEach( { if $0.name == "code" { self.code = $0.value! } } )
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
    
}

enum HeadlessLoginError: Error {
    case badCredentials
    case recognition
}
