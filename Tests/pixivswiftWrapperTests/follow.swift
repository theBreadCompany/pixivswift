//
//  follow.swift
//  
//
//  Created by Fabio Mauersberger on 05.03.22.
//

import Foundation
import XCTest

extension pixivswiftWrapperTests {
    
    func testFetchingNewestContentFromFollowing() throws {
        XCTAssertNoThrow(try {
            let target = 50
            let r = try self.downloader.my_following_illusts(limit: target)
            XCTAssertEqual(r.count, target)
        }())
    }
}
