//
//  related.swift
//  
//
//  Created by Fabio Mauersberger on 17.02.22.
//

import Foundation
import XCTest
import pixivswift

extension pixivswiftTests {
    
    func testRelatedIllustrations() throws {
        XCTAssertNoThrow(try {
            let ids = try (self.aapi.user_bookmarks_illust(user_id: self.aapi.user_id).illusts ?? []).map({$0.id})
            guard !ids.isEmpty else { throw TestErrors.noBookmarks }
            guard let id = try ids.first(where: {
                do { return !(try self.aapi.illust_detail(illust_id: $0).illusts ?? []).isEmpty } catch PixivError.targetNotFound { return false }
            }) else { throw TestErrors.noBookmarks }
            if let testSource = try self.aapi.illust_detail(illust_id: id).illusts?.first {
                var r = try self.aapi.illust_related(illust_id: testSource.id)
                let arguments = self.aapi.parse_qs(url: r.nextURL)
                guard let id = Int(arguments["illust_id"] as? String ?? ""), let seeds = arguments["seed_illust_ids"] as? Array<Int>, let viewed = arguments["viewed"] as? Array<Int> else {
                    print(arguments["illust_id"] as Any)
                    print(arguments["seed_illust_ids"] as Any)
                    print(arguments["viewed"] as Any)
                    throw TestErrors.missingQueryData }
                r += try self.aapi.illust_related(illust_id: id, seed_illust_ids: seeds.compactMap({Int($0)}), viewed: viewed.compactMap({Int($0)}))
            } else {
                throw TestErrors.noBookmarks
            }
        }())
    }
    
}
