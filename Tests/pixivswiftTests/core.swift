//
//  pixivswiftTests.swift
//  
//
//  Created by Fabio Mauersberger on 09.01.22.
//

import XCTest
import pixivswift

class pixivswiftTests: XCTestCase {

    var aapi = AppPixivAPI()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let _ = try self.aapi.auth(refresh_token: "1l2BQBrUTh_Q7ZS_tgGAEUCxpBzre1_7R5vpeCB1lk8") //try self.aapi.auth(refresh_token: "0zeYA-PllRYp1tfrsq_w3vHGU1rPy237JMf5oDt73c4")
        if !self.aapi.access_token.isEmpty {
            NSLog("Login successfull! Access token and refresh token have been stored...")
        } else {
            NSLog("Login failed!")
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}
