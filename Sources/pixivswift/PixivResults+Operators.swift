//
//  PixivResults+Operators.swift
//  
//
//  Created by theBreadCompany on 18.01.22.
//

import Foundation

extension PixivResult: Equatable {
    /**
     Compares two `PixivResult`s by equality
      - Parameter lhs: a `PixivResult`
      - Parameter rhs: a `PixivResult` to compare against
      - returns: whether the given `PixivResult`s are equal
     */
    public static func == (lhs: PixivResult, rhs: PixivResult) -> Bool {
        return {
            lhs.userPreviews == rhs.userPreviews &&
            lhs.illusts == rhs.illusts &&
            lhs.nextURL == rhs.nextURL &&
            lhs.ugoiraMetadata == rhs.ugoiraMetadata
        }()
    }
    
    /**
     add two `PixivResult`s together, combining them into one item
     - Parameter lhs: a `PixivResult`
     - Parameter rhs: a `PixivResult`
     - returns: a `PixivResult` containing the items of both results
     
     As there is only one `nextURL` and `ugoiraMetadata` property,
     one has to overwrite the other, so `rhs` overwrites `lhs`
     */
    public static func + (lhs: PixivResult, rhs: PixivResult) -> PixivResult {
        var lhs = lhs
        lhs.userPreviews?.append(contentsOf: rhs.userPreviews ?? [])
        lhs.illusts?.append(contentsOf: rhs.illusts ?? [])
        lhs.nextURL = rhs.nextURL ?? lhs.nextURL
        lhs.ugoiraMetadata = rhs.ugoiraMetadata ?? lhs.ugoiraMetadata
        return lhs
    }
    
    /**
     add one `PixivResult` into another
     - Parameter lhs: a mutable `PixivResult`
     - Parameter rhs: another `PixivResult` to merge into `lhs`
     */
    public static func += (lhs: inout PixivResult, rhs: PixivResult) {
        lhs = lhs + rhs
    }
}

extension PixivUser: Equatable {
    public static func == (lhs: PixivUser, rhs: PixivUser) -> Bool {
        return {
            lhs.illusts == rhs.illusts &&
            lhs.user == rhs.user
        }()
    }
}

extension PixivUserProperties: Equatable {
    static public func == (lhs: PixivUserProperties, rhs: PixivUserProperties) -> Bool {
        return {
            lhs.name == rhs.name &&
            lhs.id == rhs.id &&
            lhs.account == rhs.account &&
            lhs.isFollowed == rhs.isFollowed &&
            lhs.profileImageUrls == rhs.profileImageUrls
        }()
    }
}

extension PixivIllustration: Equatable {
    
    /**
     Compare two `PixivIllustration`s, by _total_ equality _considering all values_.
     - Parameter lhs: a `PixivIllustration`
     - Parameter rhs: a `PixivIllustration` to compare against
     - returns: whether the given `PixivIllustration`s are equal
     */
    public static func === (lhs: PixivIllustration, rhs: PixivIllustration) -> Bool {
        return (try? JSONEncoder().encode(lhs)) ?? Data() == (try? JSONEncoder().encode(rhs)) ?? Data()
    }
    
    /**
     Compare two `PixivIllustration`s by equality, _considering all values but likes and views_.
     - Parameter lhs: a `PixivIllustration`
     - Parameter rhs: a `PixivIllustration` to compare against
     - returns: whether the given `PixivIllustration`s are equal
     */
    public static func == (lhs: PixivIllustration, rhs: PixivIllustration) -> Bool {
        return {
            lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.ageLimit == rhs.ageLimit &&
            lhs.caption == rhs.caption &&
            lhs.creationDate == rhs.creationDate &&
            lhs.illustrationURLs == rhs.illustrationURLs &&
            lhs.tags == rhs.tags &&
            lhs.pageCount == rhs.pageCount &&
            lhs.tools == rhs.tools &&
            lhs.user == rhs.user &&
            lhs.width == rhs.width &&
            lhs.height == rhs.height &&
            lhs.type == rhs.type
        }()
    }
}

extension PixivIllustration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension UgoiraMetadata: Equatable {
    public static func == (lhs: UgoiraMetadata, rhs: UgoiraMetadata) -> Bool {
        return (try? JSONEncoder().encode(lhs)) ?? Data() == (try? JSONEncoder().encode(rhs)) ?? Data()
    }
}

extension IllustrationTag: Equatable {
    public static func == (lhs: IllustrationTag, rhs: IllustrationTag) -> Bool {
        return {
            lhs.name == rhs.name &&
            lhs.translatedName == rhs.translatedName
        }()
    }
}

extension IllustrationImageURLs: Equatable {
    static public func == (lhs: IllustrationImageURLs, rhs: IllustrationImageURLs) -> Bool {
        return {
            lhs.squareMedium == rhs.squareMedium &&
            lhs.medium == rhs.medium &&
            lhs.large == rhs.large &&
            lhs.original == rhs.original
        }()
    }
}

