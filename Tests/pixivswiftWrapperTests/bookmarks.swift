//
//  bookmarks.swift
//  
//
//  Created by Fabio Mauersberger on 26.01.22.
//

import Foundation
import XCTest
import pixivswiftWrapper
import pixivswift

extension pixivswiftWrapperTests {
    
    func testBookmarks() throws {
        XCTAssertNoThrow(try {
            let bookmarks = try self.downloader.my_favorite_works(publicity: .public, limit: 20)
            for bookmark in bookmarks {
                try self.downloader.unbookmark(illust_id: bookmark.id)
                try self.downloader.bookmark(illust_id: bookmark.id)
            }
        }())
    }
                         
        
}
