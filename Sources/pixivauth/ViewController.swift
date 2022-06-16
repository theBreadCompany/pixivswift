//
//  ViewController.swift
//  pixivauth
//
//  Created by Fabio Mauersberger on 28.05.22.
//

import AppKit
import WebKit
import pixivswift

class ViewController: NSViewController {

    lazy var webview = WKWebView()
    var loginHelper = LoginHelper()
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 50, y: 50, width: 400, height: 600))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        webview.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        loginHelper.startLogin(onView: webview, completionHandler: { token in
            print(token)
            NSApp.terminate(0)
        })
        view.addSubview(webview)
    }
}

public class URLObserver: NSObject {
    @objc var webview: WKWebView
    var observation: NSKeyValueObservation?
    public var changeHandler: (URL) -> Void
    
    init(webview: WKWebView, changeHandler: @escaping (URL) -> Void) {
        self.webview = webview
        self.changeHandler = changeHandler
        super.init()
        
        observation = observe(\.webview.url, options: .new) { wv, change in
            self.changeHandler(change.newValue!!)
        }
    }
}

public class LoginHelper: NSObject {
    public var oauthData: (String, String) = BasePixivAPI().oauth_pkce()
    public var observer: URLObserver? = nil
    
    public func startLogin(onView webview: WKWebView, completionHandler: @escaping (String) -> Void) {
        webview.load(createRequest(using: self.oauthData))
        self.observer = URLObserver(webview: webview, changeHandler: { url in
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false)
            if let code = components?.queryItems?.first(where: {$0.name == "code"})?.value {
                let r = (try! JSONSerialization.jsonObject(with: Data((BasePixivAPI().handle_code(code, code_challenge: self.oauthData.1, code_verifier: self.oauthData.0)).utf8)) as! [String:Any])["response"] as! [String:Any]
                completionHandler(r["refresh_token"] as! String)
            }
        })
    }
    
    private func createRequest(using oauthData: (String, String)) -> URLRequest {
        
        let login_params = [
            "code_challenge": oauthData.1,
            "code_challenge_method": "S256",
            "client": "pixiv-android"
        ]
        
        var params_string = ""
        for (key, val) in login_params {
            params_string += "\(key)=\(val)&"
        }
        params_string.removeLast()
        let url = URL(string:"https://app-api.pixiv.net/web/v1/login?"+params_string)!
        return URLRequest(url: url)
    }
}
