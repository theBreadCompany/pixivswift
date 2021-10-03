//
//  File.swift
//  File
//
//  Created by Fabio Mauersberger on 03.10.21.
//

import Foundation

public struct PixivResult: Codable {
    
    enum CodingKeys: String, CodingKey {
        case users = "user_previews"
        case nextURL = "next_url"
        case illusts
    }
    
    let illusts: [PixivIllustration]?
    let users: [PixivUser]?
    let nextURL: URL?
}

public struct PixivIllustration: Codable {
    
    let sanityLevel: Int
    private let _creationDate: Date
    let xRestrict: Int
    let tags: [IllustrationTag]
    let visible: Bool
    let metaPages: [String]
    let isBookmarked: Bool
    let type: IllustrationType
    let title: String
    let height: Int
    let id: Int
    let pageCount: Int
    let user: PixivUser
    let totalView: Int
    let tools: [String]
    let isMuted: Bool
    let width: Int
    let series: IllustrationSeries?
    let totalBookmarks: Int
    let metaSinglePage: [String:URL]
    let restrict: Int
    let imageURLs: [String:URL]
    let caption: String
}

public struct PixivUser: Codable {
    
    let profileImageURLs: [String: URL]
    let id: Int
    let name: String
    let isFollowed: Bool
    let account: String
    
}

public enum IllustrationType: String, Codable {
    
    case illust
    case manga
    case ugoira
    
}

public struct IllustrationSeries: Codable {
    
    let title: String
    let id: Int
    
}

public struct IllustrationTag: Codable {
    
    let name: String
    let translatedName: String?
    
}

public struct IllustrationImageURLs: Codable {
    
    let squareMedium: URL
    let medium: URL
    let large: URL
    var original: URL {
        URL(string: large.absoluteString.replacingOccurrences(of: "c/600x1200_90_webp/img-master", with: "img-original").replacingOccurrences(of: "_master1200", with: ""))!
    }
}
