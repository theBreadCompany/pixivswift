//
//  aapi.swift
//  pixivswift
//
//  Created by Fabio Mauersberger on 16.04.21.
//  Original work written in Python by https://github.com/upbit.
//

import Foundation
import SwiftyJSON

/**
 This class provides functions similiar to the ones used in the official Pixiv App.
 */
public class AppPixivAPI: BasePixivAPI {
    
    public override init() {
        super.init()
        self.hosts = "https://app-api.pixiv.net"
    }
    
    private func no_auth_requests_call(method: HttpMethod, url: URL, headers: Dictionary<String, String> = [:], params: Dictionary<String, String> = [:], data: Dictionary<String, String> = [:], req_auth: Bool = true) throws -> String {
        var _headers = headers
        if self.hosts != "https://app-api.pixiv.net" {
            _headers["host"] = "app-api.pixiv.net"
        }
        if headers["User-Agent"] == nil && headers["user-agent"] == nil {
            _headers["App-OS"] = "ios"
            _headers["App-OS-Version"] = "12.2"
            _headers["App-Version"] = "7.6.2"
            _headers["User-Agent"] = "PixivIOSApp/7.6.2 (iOS 12.2; iPhone9,1)"
        }
        
        if !req_auth {
            return try self.requests_call(method: method, url: url, headers: _headers, params: params, data: data)
        } else {
            try! self.require_auth()
            _headers["Authorization"] = "Bearer " + self.access_token
            return try self.requests_call(method: method, url: url, headers: _headers, params: params, data: data)
        }
    }
    
    /* old 'parser'
    private func parse_result(req: String) -> PixivResult {
        let result = self.parse_json(json: req.description)
        return result
    }
     */
    private func parse_result(req: String) -> PixivResult {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(PixivResult.self, from: Data(req.utf8))
    }
    
    
    /**
     parse the next\_url contained in an API response to get its components
     
     - Parameter url: the next\_url to get components from
     - returns: the components as a SwiftyJSON dictionary
     */
    public func parse_qs(url: String) throws -> JSON {
        var result: Dictionary<String, Any> = [:]
        
        if url.isEmpty {
            return JSON(result)
        }
        
        for component in URLComponents(string: url)!.queryItems! {
            if let ob = component.name.firstIndex(of: "["), let cb = component.name.firstIndex(of: "]") {
                var _component = component
                _component.name.removeSubrange(ob...cb)
                guard let _ = result[_component.name] else { result[_component.name] = [_component.value!.description]; continue }
                result[_component.name] = (result[_component.name] as! [String]) + [_component.value!]
            } else {
                result[component.name] = component.value
            }
        }
        return JSON(result)
    }
    
    /**
     fetch details about a user
     
     - Parameter user_id: ID of the requested user
     - Parameter filter: request for a specific platform
     - Parameter req_auth: whether the API needs to be authorized
     - returns: the user's information as a SwiftyJSON
     */
    public func user_detail(user_id: Int, filter: String = "for_ios", req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "\(self.hosts)/v1/user/detail")!
        let params = [
            "user_id": String(user_id),
            "filter": filter
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params)
        return self.parse_result(req: result)
    }
    
    /**
     fetch a user's illustrations
     
     available types: "illust", "manga"
     
     - Parameter user_id: ID of the requested user
     - Parameter type: requested content category
     - Parameter filter: request for a specific platform
     - Parameter offset: offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: the user's content as a SwiftyJSON
     */
    public func user_illusts(user_id: Int, type: String = "illust", filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "\(self.hosts)/v1/user/illusts")!
        var params = [
            "user_id": String(user_id),
            "filter": filter
        ]
        if !type.isEmpty {
            params["type"] = type
        }
        if let offset = offset {
            params["offset"] = String(offset)
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch the illustration a user has bookmarked
     
     - Parameter user_id: ID of the user
     - Parameter restrict: publicity of the requested content
     - Parameter filter: request for a specific platform
     - Parameter max_bookmark: (optional) highest ID that should be fetched
     - Parameter tag: (optional) name of the requested bookmark collection
     - Parameter req_true: whether the API is required to be authorized
     - returns: the user's bookmarks as a SwiftyJSON
     */
    public func user_bookmarks_illust(user_id: Int, restrict: Publicity = .public, filter: String = "for_ios", max_bookmark: Int? = nil, tag: String? = nil, req_true: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/bookmarks/illust")!
        var params = [
            "user_id": String(user_id),
            "restrict": restrict.rawValue,
            "filter": filter
        ]
        if let max_bookmark = max_bookmark {
            params["max_bookmark_id"] = String(max_bookmark)
        }
        if let tag = tag {
            params["tag"] = tag
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_true)
        return self.parse_result(req: result)
    }
    
    /**
     fetch users similiar to a given one
     
     - Parameter seed_user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON with related users to the given ID
     */
    public func user_related(seed_user_id: Int, filter: String = "for_ios", offset: Int = 0, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/related")!
        let params = [
            "filter": filter,
            "offset": offset.description,
            "seed_user_id": seed_user_id.description
        ]
        let r = try no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        var parsed_r = self.parse_result(req: r)
        parsed_r.nextURL = URL(string: "\(self.hosts)/v1/user/related?filter=" + params["filter"]! + "&offset=\(Int(params["offset"]!)!+30)&seed_user_id=" + params["seed_user_id"]!)!
        return parsed_r
    }
    
    /**
     fetch the newest illustrations of the users you are following
     
     - Parameter restrict: publicity of the requested content
     - Parameter offset: offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a  SwiftyJSON with the newest content of the illustrations of the users you follow
     */
    public func illust_follow(restrict: Publicity = .public, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "\(self.hosts)/v2/illust/follow")!
        var params = [
            "restrict": restrict.rawValue
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch illustration details like title, caption, tags etc.
     - Parameter illust_id: ID of the illustration
     - Parameter req_auth:  whether the API is require to be authorized
     - returns: a SwiftyJSON with the requested details
     */
    public func illust_detail(illust_id: Int, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "\(self.hosts)/v1/illust/detail")!
        let params = [
            "illust_id": String(illust_id)
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch comments posted under a given illustration
     - Parameter illust_id: ID of the illustration
     - Parameter offset: offset of the requested comments
     - Parameter include_total_comments: whether to include total comments
     - Parameter req_auth: whether the API is required to be authorized
     - returns: the comments of the illustration as a SwiftyJSON
     */
    public func illust_comments(illust_id: Int, offset: Int? = nil, include_total_comments: Bool? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/illust/comments")!
        var params = [
            "illust_id": String(illust_id)
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        if let include_total_comments = include_total_comments {
            params["include_total_comments"] = include_total_comments.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch illustrations related to a given ID
     - Parameter illust_id: ID of the illustration
     - Parameter filter: request for a specific platform
     - Parameter seed_illust_ids: array with more IDs that should be considered
     - Parameter offset: offset of the requested illustrations
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON with similiar illustrations
     */
    public func illust_related(illust_id: Int, filter: String = "for_ios", seed_illust_ids: Array<Int>? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v2/illust/related")!
        var params = [
            "illust_id": String(illust_id),
            "filter": filter,
            "offset": offset == nil ? 0.description : offset!.description
        ]
        if let seed_illust_ids = seed_illust_ids {
            params["seed_illust_ids[]"] = seed_illust_ids.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch illustrations recommended for your account
     - Parameter content_type: type of the requested content
     - Parameter include_ranking_label: whether to include the ranking label
     - Parameter filter: request for a specific platform
     - Parameter max_bookmark_id_for_recommend: (optional) highest bookmark ID that should be considered for recommendations
     - Parameter min_bookmark_id_for_recent_illust: (optional) lowest bookmark ID that should be considered for recent recommendations
     - Parameter offset: (optional) offset of the requested illustrations
     - Parameter include_ranking_illusts: (optional) also include ranked illustrations
     - Parameter bookmark_illust_ids: (optional)  bookmark IDs of illustrations that should be considered
     - Parameter include_privacy_policy: (optional) include the privacy policy
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON with recommendations for the user
     */
    public func illust_recommended(content_type: String = "illust", include_ranking_label: Bool = true, filter: String = "for_ios", max_bookmark_id_for_recommend: Int? = nil, min_bookmark_id_for_recent_illust: Int? = nil, offset: Int? = nil, include_ranking_illusts: Bool? = nil, bookmark_illust_ids: Array<String>? = nil, include_privacy_policy: Bool? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url: URL
        if req_auth {
            url = URL(string: "\(self.hosts)/v1/illust/recommended")!
        } else {
            url = URL(string: "\(self.hosts)/v1/illust/recommended-nologin")!
        }
        var params = [
            "content_type": content_type,
            "include_ranking_label": include_ranking_label.description,
            "filter": filter
        ]
        if let max_bookmark_id_for_recommend = max_bookmark_id_for_recommend {
            params["max_bookmark_id_for_recommend"] = max_bookmark_id_for_recommend.description
        }
        if let min_bookmark_id_for_recent_illust = min_bookmark_id_for_recent_illust {
            params["min_bookmark_id_for_recent_illust"] = min_bookmark_id_for_recent_illust.description
        }
        if let offset = offset {
            params["offset"] = offset.description
        }
        if let include_ranking_illusts = include_ranking_illusts {
            params["include_ranking_illusts"] = include_ranking_illusts.description
        }
        
        if !req_auth {
            if let bookmark_illust_ids = bookmark_illust_ids {
                if bookmark_illust_ids.count == 1 {
                    params["bookmark_illust_ids"] = bookmark_illust_ids.first
                } else if bookmark_illust_ids.count > 1 {
                    params["bookmark_illust_ids"] = bookmark_illust_ids.description.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                }
            }
        }
        
        if include_privacy_policy! {
            params["include_privacy_policy"] = include_privacy_policy?.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch ranked illustrations
     - Parameter mode: timespan of the ranking
     - Parameter filter: request for a specific platform
     - Parameter date: (optional) request for a specific date
     - Parameter offset: (optional) offset of the requested illustrations
     - Parameter req_auth: whether the API is required to be authorized
     */
    public func illust_ranking(mode: String = "day", filter: String = "for_ios", date: Date? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "\(self.hosts)/v1/illust/ranking")!
        var params = [
            "mode": mode,
            "filter": filter
        ]
        
        if let date = date {
            params["date"] = self.parse_date(date)
        }
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return parse_result(req: result)
    }
    
    /**
     fetch trending illustration tags
     - Parameter filter: request for a specific platform
     - Parameter req_auth: whether the API is required to be logged in
     - returns: a SwiftyJSON with the currently trending tags
     */
    public func trending_tags_illust(filter: String = "for_ios", req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/trending-tags/illust")!
        let params = [
            "filter": filter
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     search illustrations by tags
     - Parameter word: the tags as a string (an array of tags needs to be joined together with spaces
     - Parameter search_target: tolerance of the filter applied to the results
     - Parameter sort: how the results should be sorted
     - Parameter duration: (optional) timespan that should be considered
     - Parameter start_date: (optional)  start point that should be considered (format: YYYY-MM-DD)
     - Parameter end_date: (optional)  end point that should be considered (format: YYYY-MM-DD)
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested illustrations
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON with search results
     */
    public func search_illust(word: String, search_target: SearchMode = .partial_match_for_tags, sort: SortMode = .date_desc, duration: Duration? = nil, start_date: Date? = nil, end_date: Date? = nil, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/search/illust")!
        var params = [
            "word": word,
            "search_target": search_target.rawValue,
            "sort": sort.rawValue,
            "filter": filter
        ]
        if let start_date = start_date {
            params["start_date"] = self.parse_date(start_date)
        }
        if let end_date = end_date {
            params["end_date"] = self.parse_date(end_date)
        }
        if let duration = duration {
            params["duration"] = duration.rawValue
        }
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     search novels by tags
     - Parameter word: the tags as a string (an array of tags needs to be joined together with spaces
     - Parameter search_target: tolerance of the filter applied to the results
     - Parameter sort: how the results should be sorted
     - Parameter merge_plain_keyword_results: whether to also merge plain keyword results (?)
     - Parameter include_translated_tag_results: whether to also include translated tag results (?)
     - Parameter start_date: (optional)  start point that should be considered (format: YYYY-MM-DD)
     - Parameter end_date: (optional)  end point that should be considered (format: YYYY-MM-DD)
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested illustrations
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON with search results
     */
    public func search_novel(word: String, search_target: SearchMode = .partial_match_for_tags, sort: SortMode = .date_desc, merge_plain_keyword_results: Bool = true, include_translated_tag_results: Bool = true, start_date: Date? = nil, end_date: Date? = nil, filter: String? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/search/novel")!
        var params = [
            "word": word,
            "search_targets": search_target.rawValue,
            "merge_plain_keyword_results": merge_plain_keyword_results.description,
            "include_translated_tag_results": include_translated_tag_results.description,
            "sort": sort.rawValue,
            "filter": filter!
        ]
        if let start_date = start_date {
            params["start_date"] = self.parse_date(start_date)
        }
        if let end_date = end_date {
            params["end_date"] = self.parse_date(end_date)
        }
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     search users by a part of or their whole name
     - Parameter word: a name or a part of it
     - Parameter sort: how the results should be sorted
     - Parameter duration: (optional) timespan that should be considered
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON containing potential search results
     */
    public func search_user(word: String, sort: SortMode = .date_desc, duration: Duration? = nil, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/search/user")!
        var params = [
            "word": word,
            "sort": sort.rawValue,
            "filter": filter
        ]
        
        if let duration = duration {
            params["duration"] = duration.rawValue
        }
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch fetails about a bookmarked illustration
     - Parameter illust_id: ID of the illustration details should be fetched for
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON containing the details
     */
    public func illust_bookmark_detail(illust_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v2/illust/bookmark/detail")!
        let params = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     bookmark an illustration
     - Parameter illust_id: ID of the illustration that should be bookmarked
     - Parameter restrict: publicity of the bookmark
     - Parameter tags: (optional) array of the bookmark collections this bookmark should be appended
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON
     */
    public func illust_bookmark_add(illust_id: Int, restrict: Publicity = .public, tags: Array<String>? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v2/illust/bookmark/add")!
        var data = [
            "illust_id": illust_id.description,
            "restrict": restrict.rawValue
        ]
        if let tags = tags {
            if tags.count == 1 {
                data["tags"] = tags.first
            } else if tags.count > 1 {
                data["tags"] = tags.joined(separator: " ")
            }
        }
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     delete an illustration from your bookmarks
     - Parameter illust_id: ID of the illustration that should be deleted from the bookmarks
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON
     */
    public func illust_bookmark_delete(illust_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/illust/bookmark/delete")!
        let data = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     follow a user
     - Parameter user_id: ID of the user that should be followed
     - Parameter restrict: publicity of the bookmark
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON
     */
    public func user_follow_add(user_id: Int, restrict: Publicity = .public, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/follow/add")!
        let data = [
            "user_id": user_id.description,
            "restrict": restrict.rawValue
        ]
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    /**
     unfollow a user
     - Parameter user_id: ID of the user that should be unfollowed
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON
     */
    public func user_follow_delete(user_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/follow/delete")!
        let data = [
            "user_id": user_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     (*)*)
     - Parameter restrict: publicity of the tags
     - Parameter offset:(optional) offset of the requested tags
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON containing the tags
     */
    public func user_bookmark_tags_illust(restrict: Publicity = .public, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/bookmark-tags/illust")!
        var params = [
            "restrict": restrict.rawValue
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch users a given user follows
     - Parameter user_id: ID of the user
     - Parameter restrict: publicity of the follows
     - Parameter offset:(optional) offset of the requested users
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON containing the users
     */
    public func user_following(user_id: Int, restrict: Publicity = .public, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/following")!
        var params = [
            "user_id": user_id.description,
            "restrict": restrict.rawValue
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     get the followers of a given user
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset:(optional) offset of the requested tags
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON containing the users
     */
    public func user_follow(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/follower")!
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     - Parameter user_id: ID of the user
     - Parameter offset: (optional) offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a SwiftyJSON containing the user's mypixiv content
     */
    public func user_mypixiv(user_id: Int, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/mypixiv")!
        var params = [
            "user_id": user_id.description
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     list users (?)
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested users
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a SwiftyJSON containing the users
     */
    public func user_list(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v2/user/list")!
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
    fetch metadata like frame delays of an ugoira illustration
     - Parameter illust_id: ID of the illustration
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a SwiftyJSON containing the ugoiras metadata
     */
    public func ugoira_metadata(illust_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/ugoira/metadata")!
        let params = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch a user's novels
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested users
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a SwiftyJSON containing the user's novels
     */
    public func user_novels(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/user/novels")!
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch a novel series
     - Parameter series_id: ID of the series
     - Parameter filter: request for a specific platform
     - Parameter last_order: (optional) last order of the series (?)
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a SwiftyJSON containing the series
     */
    public func novel_series(series_id: Int, filter: String = "for_ios", last_order: String? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v2/novel/series")!
        var params = [
            "series_id": series_id.description,
            "filter": filter
        ]
        if let last_order = last_order {
            params["last_oder"] = last_order
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch details about a novel
     - Parameter novel_id: ID of the novel
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a SwiftyJSON containing the novel details
     */
    public func novel_details(novel_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v2/novel/detail")!
        let params = [
            "novel_id": novel_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch the text of a novel
     - Parameter novel_id: ID of the novel
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a SwiftyJSON containing the novel text
     */
    public func novel_text(novel_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "\(self.hosts)/v1/novel/text")!
        let params = [
            "novel_id": novel_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    /**
     fetch a showcase article
     - Parameter showcase_id: ID of the showcase
     - returns: a SwiftyJSON containing the showcase
     */
    public func showcase_article(showcase_id: Int) throws -> PixivResult {
        let url = URL(string: "https://www.pixiv.net/ajax/showcase/article")!
        let headers = [
            "User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36",
            "Referer": "https://www.pixiv.net"
        ]
        let params = [
            "article-id": showcase_id.description
        ]
        let result = try self.no_auth_requests_call(method: .GET, url: url, headers: headers, params: params, req_auth: false)
        return self.parse_result(req: result)
    }
}

extension AppPixivAPI {
    
    public enum SortMode: String {
        case date_asc, date_desc, popular_desc
    }
    
    public enum SearchMode: String {
        case partial_match_for_tags, exact_match_for_tags, title_and_caption
    }
    
    public enum Duration: String {
        case within_last_day, within_last_week, within_last_month
    }
}
