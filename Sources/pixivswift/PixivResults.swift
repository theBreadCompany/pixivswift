//
//  PixivResults.swift
//  pixivswift
//
//  Created by Fabio Mauersberger on 03.10.21.
//

import Foundation

/**
 This `struct` is basically able to hold any response returned by https://app-api.pixiv.com.
 All properties have to be `Optional`, as non of these will appear in every response possible.
 The result is that you have to ask for the exspected `Optionals` and handle `nil` as well,
 which will be an unexpected behaviour if occuring.
 */
public struct PixivResult: Codable {
    
    /// Initializer for the `JSONDecoder`
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
    
    enum CodingKeys: String, CodingKey { case illusts, illust, ugoiraMetadata, userPreviews, nextURL = "nextUrl" }
    
    /// holds any returned illustrations
    public var illusts: [PixivIllustration]?
    private var illust: PixivIllustration?
    /// holds any returned ugoira metadata; returned by `AppPixivAPI.ugoira_metadata(illust_id:req_auth:)`
    public var ugoiraMetadata: UgoiraMetadata?  // sorry for leaving it at object root :/
    /// holds any returned users
    public var userPreviews: [PixivUser]?
    /// holds the next page if any exists; parse with `AppPixivAPI.parse_qs(url:)` to get  the arguments for the next query
    public var nextURL: URL?
}

/**
 This `struct` holds any information about an illustration that exists on the pixiv servers.
 */
public struct PixivIllustration: Codable {
    
    public var sanityLevel: Int
    /// specifies if the access should be restricted to specific ages
    public var ageLimit: IllustrationAgeLimit {
        return tags.map { $0.name }.contains("R-18") ? .r18 : .all
    }
    private var createDate: String
    public var creationDate: Date {
        if #available(macOS 10.12, iOS 10.0, *) {
            return ISO8601DateFormatter().date(from: createDate)!
        } else {
            // Fallback on earlier versions
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            return dateFormatter.date(from: createDate)!
        }
    }
    public var xRestrict: Int
    public var tags: [IllustrationTag]
    public var visible: Bool
    private var metaPages: [IllustrationImageURLs]
    public var isBookmarked: Bool
    public var type: IllustrationType
    public var title: String
    public var height: Int
    /// Individual identification number; provides access to the illustration via https://pixiv.net/en/artworks/ILLUSTRATIONID
    public var id: Int
    public var pageCount: Int
    public var user: PixivUserProperties
    public var totalView: Int
    public var tools: [String]
    /// Whether this illustration has been muted; _premium feature_
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

/**
 This `struct` collects the data of an artist.
 */
public struct PixivUser: Codable {
    
    public var user: PixivUserProperties
    public var illusts: [PixivIllustration]
}


/// This `struct` stores the actual user information.
public struct PixivUserProperties: Codable {
    ///
    public var profileImageUrls: [String: URL]
    /// individual identification number; provides access to the illustration via https://pixiv.net/en/users/USERID
    public var id: Int
    /// This is the actual name that is being displayed when you visit an artist's page.
    public var name: String
    /// This property tells whether the logged in user follows the artist; recommended to update manually if the status switches.
    public var isFollowed: Bool
    /// This name is a more or less internal property. It is more a unique identifier than a user interfacable value, one wouldnt even be able to find an artist via `AppPixivAPI.search_user(word:)`.
    public var account: String
}

/**
 This `struct` holds any existing content types.
 */
public enum IllustrationType: String, Codable {
    
    /// standard Illustration with 1-n pages
    case illust
    /// manga-type illustration with 1-n pages; behaves like a normall `illust`
    case manga
    /// Ugo-ira ("animated illustration") aka image sequence; see docs of `UgoiraMetadata`-`struct`
    case ugoira
}

/// This `struct` collects information about the series an illustration may be contained by.
public struct IllustrationSeries: Codable {
    /// Title of the series.
    public var title: String
    /// Unique identifier of the series.
    public var id: Int
}

/// This `struct` holds information about a tag and its respective translation for the chosen local.
public struct IllustrationTag: Codable {
    
    /// Native, mostly japenese name of the tag
    public var name: String
    /// Name translated into the defined language
    /// TODO: add capability to force switching to a different platform language
    public var translatedName: String?
}

/// This `struct` stores the URLs to the files of an illustration.
///
/// If it is intended to download any image. it is important to `addValue("https://app-api.pixiv.net/", forKey: "Referer")`
/// on the `URLRequest` to be able to access the content.
public struct IllustrationImageURLs: Codable {
    
    enum CodingKeys: String, CodingKey { case imageUrls, squareMedium, medium, large, original }
    
    /// Initializer for the `JSONDecoder`
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        imageUrls =  try values.decodeIfPresent([String:URL].self, forKey: .imageUrls) ?? [:]
        squareMedium = try values.decodeIfPresent(URL.self, forKey: .squareMedium) ?? imageUrls["square_medium"]!
        medium = try values.decodeIfPresent(URL.self, forKey: .medium) ?? imageUrls["medium"]!
        large = try values.decodeIfPresent(URL.self, forKey: .large) ?? imageUrls["large"]!
        original = try values.decodeIfPresent(URL.self, forKey: .original) ?? imageUrls["original"] ?? large // large is simply for safe fallback reasons, this will be overwritten anyways if it has to use it
    }
    
    /// Initialize a new `struct` holding custom `IllustrationImageURLs`.
    init(squareMedium: URL, medium: URL, large: URL, original: URL) {
        self.imageUrls = [:]
        self.squareMedium = squareMedium
        self.medium = medium
        self.large = large
        self.original = original
    }
    
    private var imageUrls: [String:URL]
    /// Rectangular preview scaled to 360x360
    public var squareMedium: URL
    /// a preview scaled to a height of 540px
    public var medium: URL
    /// a preview scaled to a width of 600px
    public var large: URL
    /// the original image itself with no downscaling applied
    public var original: URL
}

/// This `struct` holds information about an _ugoira_, pixiv's animation type.
///
/// Each _ugoira_ is a simple image sequence, played after a certain `delay`.
/// This `delay`, given in milliseconds, is specified in the `delay` property in each of the `frames`.
/// The `file`s of the sequence are contained in zips, linked to by the `zipURLs` property.
///
/// The creation of a GIF works as following: Download the zip, unzip it, create a `CGImageSource` as a target,
/// loop through the unzipped directory and add its content to the `CGImageSource` including the delay of the frame
/// and finally write to disk.
public struct UgoiraMetadata: Codable {
    
    /// This `struct` contains information about individual frames of an _ugoira_.
    public struct UgoiraFrame: Codable {
        /// Contains the name of the file.
        public var file: String
        /// Contains how long the delay to the next frame should be.
        public var delay: Int
    }
    
    /// This `struct` contains `URL`s to the zips containing the files of an _ugoira_.
    /// TODO: Find out if there are non-downscaled versions of ugoiras
    public struct UgoiraURLs: Codable {
        /// This zip contains a version of the image sequence, downscaled to one the bigger side being at most 600px
        public var medium: URL
    }
    
    /// Contains the `URL` to the zip containing the individual frames
    public var zipUrls: UgoiraURLs
    /// Contains the `UgoiraFrames`, which store information about each individual frame.
    public var frames: [UgoiraFrame]
}

public protocol PixivComment: Codable {
    var id: Int { get }
    var comment: String { get }
    var date: String { get }
    var user: PixivUserProperties { get }
}

public struct PixivNovelComment: PixivComment {
    public var id: Int
    public var comment: String
    public var date: String
    public var user: PixivUserProperties
    public var has_replies: Bool
    public var stamp: String?
}

public struct PixivIllustrationCommentResult: Codable {
    
    public struct PixivIllustrationComment: PixivComment {
        public var id: Int
        public var comment: String
        public var date: String
        public var user: PixivUserProperties
    }

    public var totalComments: Int
    public var comments: [PixivIllustrationComment]
    public var nextUrl: URL
    public var commentAccessControl: Int
}

public struct PixivNotificationSettings: Codable {
    
    public struct PixivNotificationSetting: Codable {
        public var id: Int
        public var name: String
        public var enabled: Bool
    }
    
    public var deviceRegistered: Bool
    public var types: [PixivNotificationSetting]
}

/**
 This `struct` contains relevant information about new app updates or
 important notices
 */
public struct PixivApplicationInformation: Codable {
    
    public struct PixivApplicationVersionInformation: Codable {
        /// the latest publicly available version
        public var latestVersion: String
        /// whether the update is required, i.e. because new API methods got implemented
        public var updateRequired: Bool
        /// whether an update is available for the calling client
        public var updateAvailable: Bool
        /// the message to display when an update is available
        public var updateMessage: String
        /// the URL to the app store that hosts this version
        public var storeUrl: URL
        /// internal id to manage the update notices
        public var noticeId: String
        /// the message to display when the notice appears (if applicable)
        public var noticeMessage: String
        /// whether this notice is important
        public var noticeImportant: Bool
        /// whether a notice even exists
        public var noticeExists: Bool
    }
    
    /// the property containing all app revelant information
    public var applicationInfo: PixivApplicationVersionInformation
}

/**
 This `struct` stores the profile customization presets you can choose from
 when editing your profile.
 */
public struct PixivProfilePresets: Codable {
    
    public struct PixivProfilePresetCategories: Codable {
        
        public struct PixivProfileAddressPreset: Codable {
            public var id: Int
            public var name: String
            public var isGlobal: Bool
        }
        
        public struct PixivProfileCountryPreset: Codable {
            public var code: String
            public var name: String
        }
        
        public struct PixivProfileJobPreset: Codable {
            public var id: Int
            public var name: String
        }
        
        public struct PixivProfileImagePreset: Codable {
            public var medium: URL
        }
        
        public var adresses: [PixivProfileAddressPreset]
        public var countries: [PixivProfileCountryPreset]
        public var jobs: [PixivProfileJobPreset]
        public var defaultProfileImageUrls: PixivProfileImagePreset
    }
    
    public var profilePresets: PixivProfilePresetCategories
}

public enum IllustrationAgeLimit: String, Codable {
    case all, r18, r18g
}
