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
    
    var illusts: [PixivIllustration]?
    var users: [PixivUser]?
    var nextURL: URL?
}

public struct PixivIllustration: Codable {
    
    var sanityLevel: Int
    private var _creationDate: Date
    var xRestrict: Int
    var tags: [IllustrationTag]
    var visible: Bool
    var metaPages: [String]
    var isBookmarked: Bool
    var type: IllustrationType
    var title: String
    var height: Int
    var id: Int
    var pageCount: Int
    var user: PixivUser
    var totalView: Int
    var tools: [String]
    var isMuted: Bool
    var width: Int
    var series: IllustrationSeries?
    var totalBookmarks: Int
    var metaSinglePage: [String:URL]
    var restrict: Int
    var imageURLs: [String:URL]
    var caption: String
}

public struct PixivUser: Codable {
    
    var profileImageURLs: [String: URL]
    var id: Int
    var name: String
    var isFollowed: Bool
    var account: String
    
}

public enum IllustrationType: String, Codable {
    
    case illust
    case manga
    case ugoira
    
}

public struct IllustrationSeries: Codable {
    
    var title: String
    var id: Int
    
}

public struct IllustrationTag: Codable {
    
    var name: String
    var translatedName: String?
    
}

public struct IllustrationImageURLs: Codable {
    
    var squareMedium: URL
    var medium: URL
    var large: URL
    var original: URL {
        URL(string: large.absoluteString.replacingOccurrences(of: "c/600x1200_90_webp/img-master", with: "img-original").replacingOccurrences(of: "_master1200", with: ""))!
    }
}
