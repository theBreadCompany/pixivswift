//
//  papi.swift
//  SwiftyPixiv
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
    
    private func auth_requests_call(method: String, url: String, headers: Dictionary<String, Any> = [:], params: Dictionary<String, Any> = [:], data: Dictionary<String, Any> = [:]) throws -> String {
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
    
    public func bad_words() throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1.1/bad_words.json"
        let result = try self.auth_requests_call(method: "GET", url: url)
        return self.parse_result(req: result)
    }
    
    public func works(illust_id: Int, include_sanity_level: Bool = false) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/works/\(illust_id.description).json"
        let params = [
            "image_sizes": "px_128x128,small,medium,large,px_480mw",
            "include_stats": "true",
            "include_sanity_level": include_sanity_level.description.lowercased()
        ]
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func users(author_id: Int) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/users/\(author_id.description).json"
        let params = [
            "profile_image_sizes": "px_170x170,px_50x50",
            "image_sizes": "px_128x128,small,medium,large,px_480mw",
            "include_stats": 1.description,
            "include_profile": 1.description,
            "include_workspace": 1.description,
            "include_contacts": 1.description
        ]
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func me_feeds(show_r18: Bool = true, max_id: Int? = nil) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/me/feeds.json"
        var params = [
            "relation": "all",
            "type": "touch_nottext",
            "show_r18": show_r18 ? 1.description : 0.description
        ]
        if max_id != nil {
            params["max_id"] = max_id?.description
        }
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    //me_favorite_* not implemented as the public api urls for these public functions are not available anymore
    
    public func me_following_works(page: Int = 1, per_page: Int = 30, image_sizes: Array<String> = ["px_128x128", "px_480mw", "large"], include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/me/following/works.json"
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "image_sizes": image_sizes.joined(separator: ","),
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description
        ]
        let result = try self.auth_requests_call(method: "FET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func me_following(page: Int = 1, per_page: Int = 30, publicity: String = "public") throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/me/following.json"
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "publicity": publicity
        ]
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func me_favorite_users_follow(user_id: Int, publicity: String = "String") throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/me/favorite-users.json"
        let params = [
            "target_user_id": user_id.description,
            "publicity": publicity
        ]
        
        let result = try self.auth_requests_call(method: "POST", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func me_favorite_users_unfollow(user_ids: Array<Int>, publicity: String = "public") throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/me/favorite-users.json"
        let params = ["delete_ids": user_ids.count == 1 ? user_ids.first!.description : user_ids.description.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: ""), "publicity": publicity]
        
        let result = try self.auth_requests_call(method: "DELETE", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func users_works(author_id: Int, page: Int = 1, per_page: Int = 30, image_sizes: Array<String> = ["px_128x128", "px_480mw", "large"], include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/users/\(author_id)/works.json"
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description,
            "image_sizes": image_sizes.joined(separator: ",")
        ]
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func users_favorite_works(author_id: Int, page: Int = 1, per_page: Int = 30, image_sizes: Array<String> = ["px_128x128", "px_480mw", "large"], include_sanity_level: Bool = true) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/users/\(author_id)/favorite_works.json"
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "include_sanity_level": include_sanity_level.description,
            "images_sizes": image_sizes.joined(separator: ",")
        ]
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func users_feeds(author_id: Int, show_r18: Bool = true, max_id: Int? = nil) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/users/\(author_id)/feeds.json"
        var params = [
            "relation": "all",
            "type": "touch_nottext",
            "show_r18": show_r18 ? 1.description : 0.description
        ]
        if max_id != nil {
            params["max_id"] = max_id?.description
        }
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func users_following(author_id: Int, page: Int = 1, per_page: Int = 30) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/users/\(author_id)/following.json"
        let params = [
            "page": page.description,
            "per_page": per_page.description
        ]
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func ranking(ranking_type: String = "all", mode: String = "daily", page: Int = 1, per_page: Int = 50, date: String? = nil, image_sizes: Array<String> = ["px_128x128", "px_480mw", "large"], profile_image_sizes: Array<String> = ["px_170x170", "px_50x50"], include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/ranking/\(ranking_type).json"
        var params = [
            "mode": mode,
            "page": page.description,
            "per_page": per_page.description,
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description,
            "image_sizes": image_sizes.joined(separator: ","),
            "profile_image_sizes": profile_image_sizes.joined(separator: ",")
        ]
        if date != nil {
            params["date"] = date
        }
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func ranking_all(ranking_type: String = "all", mode: String = "daily", page: Int = 1, per_page: Int = 50, date: String? = nil, image_sizes: Array<String> = ["px_128x128", "px_480mw", "large"], profile_image_sizes: Array<String> = ["px_170x170", "px_50x50"], include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON{
        return try self.ranking(ranking_type: "all", mode: mode, page: page, per_page: per_page, date: date,
                            image_sizes: image_sizes, profile_image_sizes: profile_image_sizes,
                            include_stats: include_stats, include_sanity_level: include_sanity_level)
    }
    
    public func search_works(query: String, page: Int = 1, per_page: Int = 30, mode: String = "text", period: String = "all", order: String = "desc", sort: String = "date", types: Array<String> = ["illustration", "manga", "ugoira"], image_sizes: Array<String> = ["px_128x128", "px_480mw", "large"], include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/search/works.json"
        let params = [
            "q": query,
            "page": page.description,
            "per_page": per_page.description,
            "period": period,
            "order": order,
            "sort": sort,
            "mode": mode,
            "types": types.joined(separator: ","),
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description,
            "image_sizes": image_sizes.joined(separator: ",")
        ]
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    public func latest_works(page: Int = 1, per_page: Int = 30, image_sizes: Array<String> = ["px_128x128", "px_480mw", "large"], profile_image_sizes: Array<String> = ["px_170x170", "px_50x50"], include_stats: Bool = true, include_sanity_level: Bool = true) throws -> JSON {
        let url = "https://public-api.secure.pixiv.net/v1/works.json"
        let params = [
            "page": page.description,
            "per_page": per_page.description,
            "include_stats": include_stats.description,
            "include_sanity_level": include_sanity_level.description,
            "image_sizes": image_sizes.joined(separator: ","),
            "profile_iomage_sizes": profile_image_sizes.joined(separator: ",")
        ]
        
        let result = try self.auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
}
