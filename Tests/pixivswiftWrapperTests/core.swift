//
//  core.swift
//  
//
//  Created by Fabio Mauersberger on 26.01.22.
//

import XCTest
import pixivswiftWrapper
import pixivswift

class pixivswiftWrapperTests: XCTestCase {

    var downloader = PixivDownloader()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.downloader.login(refresh_token: "1l2BQBrUTh_Q7ZS_tgGAEUCxpBzre1_7R5vpeCB1lk8")
        if self.downloader.authed {
            NSLog("Login successfull! Access token and refresh token have been stored...")
        } else {
            NSLog("Login failed!")
            throw TestErrors.loginFailed
        }
    }
}
