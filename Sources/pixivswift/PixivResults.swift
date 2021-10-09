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
    private var createDate: String
    public var creationDate: Date {
        return ISO8601DateFormatter().date(from: createDate)!
    }
    public var xRestrict: Int
    public var tags: [IllustrationTag]
    public var visible: Bool
    public var metaPages: [IllustrationImageURLs] { // we could  extract them from the json but seems to be actually easier to generate them like this
        var pages = [IllustrationImageURLs]()
        for n in 0...pageCount-1 {
            pages.append(IllustrationImageURLs(
                squareMedium: URL(string: imageUrls.squareMedium.absoluteString.replacingOccurrences(of: "_p0", with: "_p\(n)"))!,
                medium: URL(string: imageUrls.medium.absoluteString.replacingOccurrences(of: "_p0", with: "_p\(n)"))!,
                large: URL(string: imageUrls.large.absoluteString.replacingOccurrences(of: "_p0", with: "_p\(n)"))!,
                original: metaSinglePage["original_image_url"] ?? URL(string: imageUrls.large.absoluteString.replacingOccurrences(of: "c/600x1200_90_webp/img-master", with: "img-original").replacingOccurrences(of: "_master1200", with: "").replacingOccurrences(of: "_p0", with: "_p\(n)"))!))
        }
        return pages
    }
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
    private var imageUrls: IllustrationImageURLs // this is genuinly unsatisfying, but the image_urls property in the json doesnt contain a "original" URL, using the meta_single_page one for that instead (which is only used for pageCount>1)
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
    
    enum CodingKeys: String, CodingKey { case squareMedium, medium, large, original }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        squareMedium = try values.decode(URL.self, forKey: .squareMedium)
        medium = try values.decode(URL.self, forKey: .medium)
        large = try values.decode(URL.self, forKey: .large)
        original = try values.decodeIfPresent(URL.self, forKey: .original) ?? URL(string: large.absoluteString.replacingOccurrences(of: "c/600x1200_90_webp/img-master", with: "img-original").replacingOccurrences(of: "_master1200", with: ""))!
    }
    
    init(squareMedium: URL, medium: URL, large: URL, original: URL) {
        self.squareMedium = squareMedium
        self.medium = medium
        self.large = large
        self.original = original
    }
    
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
