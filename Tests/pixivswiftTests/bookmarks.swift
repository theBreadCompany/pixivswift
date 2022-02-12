//
//  bokmarks.swift
//  
//
//  Created by Fabio Mauersberger on 18.01.22.
//

import Foundation
import pixivswift
import XCTest

extension pixivswiftTests {
    
    /// Fetch some illustrations, un- and rebookmark them. Everything wrapped in an assert that allows no throw.
    func testBookmarkAppliance() throws {
        XCTAssertNoThrow(try {
            let testBookmarks = try self.aapi.user_bookmarks_illust(user_id: self.aapi.user_id)
            if testBookmarks.illusts?.count ?? 0 > 0 {
                for bookmark in testBookmarks.illusts ?? [] {
                    XCTAssertNoThrow(try self.aapi.illust_bookmark_delete(illust_id: bookmark.id))
                    XCTAssertNoThrow(try self.aapi.illust_bookmark_add(illust_id: bookmark.id))
                }
            }
        }())
    }

    /// Fetch many bookmarks where many means more than 30 to force the usage of the nextURL property
    func testFetchingBookmarks() throws {
        XCTAssertNoThrow(try {
            var r = try self.aapi.user_bookmarks_illust(user_id: self.aapi.user_id)
            if r.illusts?.isEmpty ?? true { throw TestErrors.noBookmarks }
            if r.illusts?.count ?? 1 == 30 {
                if let nextURL = r.nextURL {
                    let arguments = self.aapi.parse_qs(url: nextURL)
                    guard let user_id = Int(arguments["user_id"] as? String ?? "x") else { throw TestErrors.missingQueryData}
                    let r_bac = r
                    r += try self.aapi.user_bookmarks_illust(user_id: user_id)
                    XCTAssertNotEqual(r.illusts?.count, r_bac.illusts?.count)
                }
            }
        }())
    }
    
    /// Dumb test of the `AppPixivAPI.illust_bookmark_detail` method
    func testBookmarkDetails() throws {
        XCTAssertNoThrow(try {
            let bookmarks = try self.aapi.user_bookmarks_illust(user_id: self.aapi.user_id)
            guard let bookmarks = bookmarks.illusts, !bookmarks.isEmpty else { throw TestErrors.noBookmarks}
            let illustrationIDs = bookmarks[...5]
            var illustrations = [PixivResult]()
            for illustrationID in illustrationIDs.compactMap({$0.id}) {
                do { illustrations.append(try self.aapi.illust_bookmark_detail(illust_id: illustrationID))
                } catch PixivError.targetNotFound { continue
                } catch { throw error
                }
            }
        }())
    }
}
