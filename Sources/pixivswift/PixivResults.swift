//
//  PixivResults.swift
//  pixivswift
//
//  Created by Fabio Mauersberger on 03.10.21.
//  TODO: fix the imageURLs property to be usable; 

import Foundation

public struct PixivResult: Codable {
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        illusts = try values.decodeIfPresent([PixivIllustration].self, forKey: .illusts)
        illust = try values.decodeIfPresent(PixivIllustration.self, forKey: .illust)
        ugoiraMetadata = try values.decodeIfPresent(UgoiraMetadata.self, forKey: .ugoiraMetadata)
        userPreviews = try values.decodeIfPresent([PixivUser].self, forKey: .userPreviews)
        nextURL = try values.decodeIfPresent(URL.self, forKey: .nextURL)
        if let illust = illust {
            if illusts == nil {
                illusts = [illust]
            } else {
                illusts?.append(illust)
            }
        }
    }
    
    enum CodingKeys: String, CodingKey { case illusts, illust, ugoiraMetadata, userPreviews, nextURL }
    
    public var illusts: [PixivIllustration]?
    private var illust: PixivIllustration?
    public var ugoiraMetadata: UgoiraMetadata?  // sorry for leaving it at object root :/
    public var userPreviews: [PixivUser]?
    public var nextURL: URL?
}

public struct PixivIllustration: Codable {
    
    public var sanityLevel: Int
    public var ageLimit: IllustrationAgeLimit {
        return tags.map { $0.name }.contains("R-18") ? .r18 : .all
    }
    private var createDate: String
    public var creationDate: Date {
        return ISO8601DateFormatter().date(from: createDate)!
    }
    public var xRestrict: Int
    public var tags: [IllustrationTag]
    public var visible: Bool
    private var metaPages: [IllustrationImageURLs]
    public var isBookmarked: Bool
    public var type: IllustrationType
    public var title: String
    public var height: Int
    public var id: Int
    public var pageCount: Int
    public var user: PixivUserProperties
    public var totalView: Int
    public var tools: [String]
    public var isMuted: Bool
    public var width: Int
    public var series: IllustrationSeries?
    public var totalBookmarks: Int
    public var metaSinglePage: [String:URL]
    public var restrict: Int
    private var imageUrls: IllustrationImageURLs
    public var illustrationURLs: [IllustrationImageURLs] {
        if pageCount == 1 {
            return [IllustrationImageURLs(
                squareMedium: imageUrls.squareMedium,
                medium: imageUrls.medium,
                large: imageUrls.large,
                original: metaSinglePage["original_image_url"]!)]
        } else {
            return metaPages
        }
    }
    public var caption: String
}

public struct PixivUser: Codable {
    
    public var user: PixivUserProperties
    public var illusts: [PixivIllustration]
}

public struct PixivUserProperties: Codable {
    public var profileImageUrls: [String: URL]
    public var id: Int
    public var name: String
    public var isFollowed: Bool
    public var account: String
}

public enum IllustrationType: String, Codable {
    
    case illust
    case manga
    case ugoira
}

public struct IllustrationSeries: Codable {
    
    public var title: String
    public var id: Int
}

public struct IllustrationTag: Codable {
    
    public var name: String
    public var translatedName: String?
}

public struct IllustrationImageURLs: Codable {
    
    enum CodingKeys: String, CodingKey { case imageUrls, squareMedium, medium, large, original }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        imageUrls =  try values.decodeIfPresent([String:URL].self, forKey: .imageUrls) ?? [:]
        squareMedium = try values.decodeIfPresent(URL.self, forKey: .squareMedium) ?? imageUrls["square_medium"]!
        medium = try values.decodeIfPresent(URL.self, forKey: .medium) ?? imageUrls["medium"]!
        large = try values.decodeIfPresent(URL.self, forKey: .large) ?? imageUrls["large"]!
        original = try values.decodeIfPresent(URL.self, forKey: .original) ?? imageUrls["original"] ?? large // large is simply for safe fallback reasons, this will be overwritten anyways if it has to use it
    }
    
    init(squareMedium: URL, medium: URL, large: URL, original: URL) {
        self.imageUrls = [:]
        self.squareMedium = squareMedium
        self.medium = medium
        self.large = large
        self.original = original
    }
    
    private var imageUrls: [String:URL]
    public var squareMedium: URL
    public var medium: URL
    public var large: URL
    public var original: URL
}

public struct UgoiraMetadata: Codable {
    
    public struct UgoiraFrame: Codable {
        public var file: String
        public var delay: Int
    }
    
    public struct UgoiraURLs: Codable {
        public var medium: URL
    }
    
    public var zipUrls: UgoiraURLs
    public var frames: [UgoiraFrame]
}

public enum IllustrationAgeLimit: String, Codable {
    case all, r18, r18g
}
