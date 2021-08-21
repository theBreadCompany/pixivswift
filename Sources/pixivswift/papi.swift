//
//  papi.swift
//  pixivswift
//
//  Created by Fabio Mauersberger on 16.04.21.
//  Original work written in Python by https://github.com/upbit.
//

import Foundation
import SwiftyJSON

public class PixivAPI: BasePixivAPI {
    
    public override init() {
        super.init()
    }
    
    private func auth_requests_call(method: HttpMethod, url: URL, headers: Dictionary<String, Any> = [:], params: Dictionary<String, Any> = [:], data: Dictionary<String, Any> = [:]) throws -> String {
        try! self.require_auth()
        var _headers = headers
        _headers["Referer"] = "http://spapi.pixiv.net"
        _headers["User-Agent"] = "PixivIOSApp/5.8.7"
        _headers["Authorization"] = "Bearer \(self.access_token)"
        let result = try self.requests_call(method: method, url: url, headers: _headers, params: params, data: data)
        return result
    }
    
    public func parse_result(req: String) -> JSON{
        let result = self.parse_json(json: req.description)
        return result
    }
    /* dead
    /**
     fetch the bad words
     - returns: a SwiftyJSON containing the bad words
     */
    public func bad_words() throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1.1/bad_words.json")!
        let result = try self.auth_requests_call(method: .GET, url: url)
        return self.parse_result(req: result)
    }
     */
    
    /**
     fetch a wotk
     - Parameter illust_id: ID of the work
     - returns: a SwiftyJSON containing the work
     */
    public func works(illust_id: Int, include_sanity_level: Bool = false) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/works/\(illust_id.description).json")!
        let params = [
            "image_sizes": "px_128x128,small,medium,large,px_480mw",
            "include_stats": "true",
            "include_sanity_level": include_sanity_level.description.lowercased()
        ]
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch a user
     - Parameter author_id: ID of the user
     - returns: a SwiftyJSON containing the user
     */
    public func users(author_id: Int) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/users/\(author_id.description).json")!
        let params = [
            "profile_image_sizes": "px_170x170,px_50x50",
            "image_sizes": "px_128x128,small,medium,large,px_480mw",
            "include_stats": 1.description,
            "include_profile": 1.description,
            "include_workspace": 1.description,
            "include_contacts": 1.description
        ]
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch my feeds
     - Parameter show_r18: whether to allow showing works declared as NSFW
     - Parameter max_id: (optional) highest allowed work ID
     - returns: a SwiftyJSON containing the works
     */
    public func me_feeds(show_r18: Bool = true, max_id: Int? = nil) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/me/feeds.json")!
        var params = [
            "relation": "all",
            "type": "touch_nottext",
            "show_r18": show_r18 ? 1.description : 0.description
        ]
        if let max_id = max_id {
            params["max_id"] = max_id.description
        }
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    //me_favorite_* not implemented as the public api urls for these public functions are not available anymore
    
    /**
     fetch your newest works
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - Parameter image_sizes: allowed image sizes
     - Parameter include_stats: whether statistics like scores should be included
     - Parameter include_sanity_level: whether to include the sanity level
     - returns: a SwiftyJSON containing the works
     */
    public func me_following_works(page: Int = 1, per_page: Int = 30, image_sizes: Array<ImageSizes> = ImageSizes.allCases, include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/me/following/works.json")!
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "image_sizes": image_sizes.map{$0.rawValue}.joined(separator: ","),
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description
        ]
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch the users you are following
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - Parameter publicity: publicity of the follows
     - returns: a SwiftyJSON of the users
     */
    public func me_following(page: Int = 1, per_page: Int = 30, publicity: Publicity = .public) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/me/following.json")!
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "publicity": publicity.rawValue
        ]
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     follow a user
     - Parameter user_id: ID of the user
     - Parameter publicity: publicity of the follow
     - returns: a SwiftyJSON
     */
    public func me_favorite_users_follow(user_id: Int, publicity: Publicity = .public) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/me/favorite-users.json")!
        let params = [
            "target_user_id": user_id.description,
            "publicity": publicity.rawValue
        ]
        
        let result = try self.auth_requests_call(method: .POST, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     unfollow users
     - Parameter user_ids: a array containg the users IDs
     - Parameter publicity: publicity of the follows
     - returns: a SwiftyJSON
     */
    public func me_favorite_users_unfollow(user_ids: Array<Int>, publicity: Publicity = .public) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/me/favorite-users.json")!
        let params = ["delete_ids": user_ids.count == 1 ? user_ids.first!.description : user_ids.description.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: ""), "publicity": publicity.rawValue]
        
        let result = try self.auth_requests_call(method: .DELETE, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch a user's works
     - Parameter author_id: ID of the user
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - Parameter image_sizes: allowed image sizes
     - Parameter include_stats: whether statistics like scores should be included
     - Parameter include_sanity_level: whether to include the sanity level
     - returns: a SwiftyJSON containing the works
     */
    public func users_works(author_id: Int, page: Int = 1, per_page: Int = 30, image_sizes: Array<ImageSizes> = ImageSizes.allCases, include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/users/\(author_id)/works.json")!
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description,
            "image_sizes": image_sizes.map{$0.rawValue}.joined(separator: ",")
        ]
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch a user's favorite works (bookmarks)
     - Parameter author_id: ID of the user
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - Parameter image_sizes: allowed image sizes
     - Parameter include_sanity_level: whether to include the sanity level
     - returns: a SwiftyJSON containing the works
     */
    public func users_favorite_works(author_id: Int, page: Int = 1, per_page: Int = 30, image_sizes: Array<ImageSizes> = ImageSizes.allCases, include_sanity_level: Bool = true) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/users/\(author_id)/favorite_works.json")!
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "include_sanity_level": include_sanity_level.description,
            "images_sizes": image_sizes.map{$0.rawValue}.joined(separator: ",")
        ]
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch a user's feeds
     - Parameter author_id: ID of the user
     - Parameter show_r18: whether to allow showing works declared as NSFW
     - Parameter max_id: (optional) highest allowed work ID
     - returns: a SwiftyJSON containing the works
     */
    public func users_feeds(author_id: Int, show_r18: Bool = true, max_id: Int? = nil) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/users/\(author_id)/feeds.json")!
        var params = [
            "relation": "all",
            "type": "touch_nottext",
            "show_r18": show_r18 ? 1.description : 0.description
        ]
        if let max_id = max_id {
            params["max_id"] = max_id.description
        }
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch the users a given user is following
     - Parameter author_id: ID of the user
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - returns: a SwiftyJSON containing the users
     */
    public func users_following(author_id: Int, page: Int = 1, per_page: Int = 30) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/users/\(author_id)/following.json")!
        let params = [
            "page": page.description,
            "per_page": per_page.description
        ]
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch currently high ranked works
     - Parameter ranking_type: type of ranking
     - Parameter mode: ranking mode
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - Parameter image_sizes: allowed image sizes
     - Parameter profile_image_sizes: allowed profile picture image sizes
     - Parameter include_stats: whether statistics like scores should be included
     - Parameter include_sanity_level: whether to include the sanity level
     - returns: a SwiftyJSON containing the works
     */
    public func ranking(ranking_type: String = "all", mode: String = "daily", page: Int = 1, per_page: Int = 50, date: Date? = nil, image_sizes: Array<ImageSizes> = ImageSizes.allCases, profile_image_sizes: Array<ProfileImageSizes> = ProfileImageSizes.allCases, include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/ranking/\(ranking_type).json")!
        var params = [
            "mode": mode,
            "page": page.description,
            "per_page": per_page.description,
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description,
            "image_sizes": image_sizes.map{$0.rawValue}.joined(separator: ","),
            "profile_iomage_sizes": profile_image_sizes.map{$0.rawValue}.joined(separator: ",")
        ]
        if let date = date {
            params["date"] = self.parse_date(date)
        }
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch currently high ranked works
     - Parameter ranking_type: type of ranking
     - Parameter mode: ranking mode
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - Parameter image_sizes: allowed image sizes
     - Parameter profile_image_sizes: allowed profile picture image sizes
     - Parameter include_stats: whether statistics like scores should be included
     - Parameter include_sanity_level: whether to include the sanity level
     - returns: a SwiftyJSON containing the works
     */
    public func ranking_all(ranking_type: String = "all", mode: String = "daily", page: Int = 1, per_page: Int = 50, date: Date? = nil, image_sizes: Array<ImageSizes> = ImageSizes.allCases, profile_image_sizes: Array<ProfileImageSizes> = ProfileImageSizes.allCases, include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON{
        return try self.ranking(ranking_type: "all", mode: mode, page: page, per_page: per_page, date: date,
                                image_sizes: image_sizes, profile_image_sizes: profile_image_sizes,
                                include_stats: include_stats, include_sanity_level: include_sanity_level)
    }
    
    /**
     search works by tags
     - Parameter query: the tags array joined as a string with spaces
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - Parameter mode: search mode
     - Parameter period: timespan that should be considered
     - Parameter order: order of the results
     - Parameter sort: sorting that should be applied
     - Parameter types: array of allowed content
     - Parameter image_sizes: allowed image sizes
     - Parameter include_stats: whether statistics like scores should be included
     - Parameter include_sanity_level: whether to include the sanity level
     - returns: a SwiftyJSON containing the works
     */
    public func search_works(query: String, page: Int = 1, per_page: Int = 30, mode: String = "text", period: String = "all", order: String = "desc", sort: String = "date", types: Array<ContentTypes> = ContentTypes.allCases, image_sizes: Array<ImageSizes> = ImageSizes.allCases, include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/search/works.json")!
        let params = [
            "q": query,
            "page": page.description,
            "per_page": per_page.description,
            "period": period,
            "order": order,
            "sort": sort,
            "mode": mode,
            "types": types.map{$0.rawValue}.joined(separator: ","),
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description,
            "image_sizes": image_sizes.map{$0.rawValue}.joined(separator: ",")
        ]
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch the newest works
     - Parameter page: number of pages that should be fetched
     - Parameter per_page: number of works per page
     - Parameter image_sizes: allowed image sizes
     - Parameter profile_image_sizes: allowed profile picture image sizes
     - Parameter include_stats: whether statistics like scores should be included
     - Parameter include_sanity_level: whether to include the sanity level
     - returns: a SwiftyJSON containing the works
     */
    public func latest_works(page: Int = 1, per_page: Int = 30, image_sizes: Array<ImageSizes> = ImageSizes.allCases, profile_image_sizes: Array<ProfileImageSizes> = ProfileImageSizes.allCases, include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = URL(string: "https://public-api.secure.pixiv.net/v1/works.json")!
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description,
            "image_sizes": image_sizes.map{$0.rawValue}.joined(separator: ","),
            "profile_iomage_sizes": profile_image_sizes.map{$0.rawValue}.joined(separator: ",")
        ]
        
        let result = try self.auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
}

//outsourced enums that may be helpful to prevent misspelling
extension PixivAPI {
    
    public enum ImageSizes: String, CaseIterable {
        case px_128x128, px_480mw, large
    }
    
    public enum ProfileImageSizes: String, CaseIterable {
        case px_170x170, px_50x50
    }
    
    public enum ContentTypes: String, CaseIterable {
        case illustration, manga, ugoira
    }
}
