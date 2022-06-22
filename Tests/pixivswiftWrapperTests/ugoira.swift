//
//  ugoira.swift
//  
//
//  Created by Fabio Mauersberger on 22.06.22.
//

import Foundation
import XCTest


extension pixivswiftWrapperTests {
    func testUgoiraCreation() throws {
        XCTAssertNoThrow(try {
            let target = 94700030
            let illustration = try downloader.illustration(illust_id: target)
            let downloadedURLs = downloader.download(illustration: illustration)
            XCTAssertEqual(illustration.pageCount, downloadedURLs.count)
        }())
    }
}
