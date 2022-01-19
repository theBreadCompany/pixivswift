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
    
    func testBookmarkAppliance() throws {
        XCTAssertNoThrow(try self.aapi.user_bookmarks_illust(user_id: self.aapi.user_id))
        let testBookmarks = try! self.aapi.user_bookmarks_illust(user_id: self.aapi.user_id)
        if testBookmarks.illusts?.count ?? 0 > 0 {
            for bookmark in testBookmarks.illusts ?? [] {
                XCTAssertNoThrow(try self.aapi.illust_bookmark_delete(illust_id: bookmark.id))
                XCTAssertNoThrow(try self.aapi.illust_bookmark_add(illust_id: bookmark.id))
            }
        }
    }
    
    func testFetchBookmarks() throws {
        XCTAssertNoThrow({
            let illustrations = try self.aapi.user_bookmarks_illust(user_id: self.aapi.user_id)
            if illustrations.illusts?.isEmpty ?? true { throw TestErrors.noBookmarks }
        })
    }
    
    
    func testBookmarkDetails() throws {
        XCTAssertNoThrow({
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
        })
    }
}
