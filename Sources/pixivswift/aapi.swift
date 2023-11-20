//
//  aapi.swift
//  pixivswift
//
//  Created by theBreadCompany on 16.04.21.
//  Original work written in Python by https://github.com/upbit.
//

import Foundation

/**
 This class provides functions similiar to the ones used in the official Pixiv App.
 It is strongly recommended to `auth` the instance before using any API calls.
 
 The `notification` methods are currently under construction and should only be used with caution.
 Unstable methods will be labeled as such in the docs or marked `internal` entirely.
 */
public class AppPixivAPI: BasePixivAPI {
    
    /**
     Initialize a new _unauthorized_ `AppPixivAPI` instance
     
     The `.auth(username:password:refresh_token:)` method of the new instance
     has to be called with valid credentials first before it is allowed to interact with the API.
     */
    public override init() {
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        super.init()
        self.hosts = URL(string: "https://app-api.pixiv.net/")!
    }
    
    internal var decoder: JSONDecoder
    
#if DEBUG // yes, this is literally just for... research
public func engineer(method: HttpMethod, url: URL, headers: Dictionary<String, String> = [:], params: Dictionary<String, String> = [:], data: Dictionary<String, String> = [:], stream: Bool = false) throws -> String {
    try self.no_auth_requests_call(method: method, url: url, headers: headers, params: params, data: data)
}
#endif
    
    public func no_auth_requests_call(method: HttpMethod, url: URL, headers: Dictionary<String, String> = [:], params: Dictionary<String, String> = [:], data: Dictionary<String, String> = [:], req_auth: Bool = true) throws -> String {
        var _headers = headers
        if self.hosts != URL(string: "https://app-api.pixiv.net/")! {
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
            try self.require_auth()
            _headers["Authorization"] = "Bearer " + self.access_token
            return try self.requests_call(method: method, url: url, headers: _headers, params: params, data: data)
        }
    }
    
    /**
     parse the next\_url contained in an API response to get its components
     
     - Parameter url: the next\_url to get components from
     - returns: the components as a PixivResponse dictionary
     */
    public func parse_qs(url: URL?) -> Dictionary<String, Any> {
        var result: Dictionary<String, Any> = [:]
        
        guard let url = url else { return result }
        
        for var component in URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems! {
            if let ob = component.name.firstIndex(of: "["), let cb = component.name.firstIndex(of: "]") {
                component.name.removeSubrange(ob...cb)
                result.updateValue(((result[component.name] as? [String]) ?? [] + component.value!).compactMap({Int($0)}) as Any, forKey: component.name)
            } else {
                result[component.name] = component.value
            }
        }
        return result
    }
    
    /**
     fetch details about a user
     
     - Parameter user_id: ID of the requested user
     - Parameter filter: request for a specific platform
     - Parameter req_auth: whether the API needs to be authorized
     - returns: the user's information as a PixivResponse
     */
    public func user_detail(user_id: Int, filter: String = "for_ios", req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "v1/user/detail", relativeTo: self.hosts)!
        let params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch a user's illustrations
     
     available types: "illust", "manga"
     
     - Parameter user_id: ID of the requested user
     - Parameter type: requested content category
     - Parameter filter: request for a specific platform
     - Parameter offset: offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: the user's content as a PixivResponse
     */
    public func user_illusts(user_id: Int, type: String = "illust", filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "v1/user/illusts", relativeTo: self.hosts)!
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if !type.isEmpty {
            params["type"] = type
        }
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch the illustration a user has bookmarked
     
     - Parameter user_id: ID of the user
     - Parameter restrict: publicity of the requested content
     - Parameter filter: request for a specific platform
     - Parameter offset: offset of the requested content
     - Parameter max_bookmark: (optional) highest ID that should be fetched
     - Parameter tag: (optional) name of the requested bookmark collection
     - Parameter req_true: whether the API is required to be authorized
     - returns: the user's bookmarks as a PixivResponse
     */
    public func user_bookmarks_illust(user_id: Int, restrict: Publicity = .public, filter: String = "for_ios", offset: Int = 0, max_bookmark: Int? = nil, tag: String? = nil, req_true: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/bookmarks/illust", relativeTo: self.hosts)!
        var params = [
            "user_id": user_id.description,
            "restrict": restrict.rawValue,
            "filter": filter,
            "offset": offset.description
        ]
        if let max_bookmark = max_bookmark {
            params["max_bookmark_id"] = max_bookmark.description
        }
        if let tag = tag {
            params["tag"] = tag
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_true)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch users similiar to a given one
     
     - Parameter seed_user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse with related users to the given ID
     */
    public func user_related(seed_user_id: Int, filter: String = "for_ios", offset: Int = 0, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/related", relativeTo: self.hosts)!
        let params = [
            "filter": filter,
            "offset": offset.description,
            "seed_user_id": seed_user_id.description
        ]
        let r = try no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        var parsed_r = try decoder.decode(PixivResult.self, from: Data(r.utf8))
        parsed_r.nextURL = URL(string: "v1/user/related?filter=" + params["filter"]! + "&offset=\(Int(params["offset"]!)!+30)&seed_user_id=" + params["seed_user_id"]!)!
        return parsed_r
    }
    
    /**
     fetch the newest illustrations of the users you are following
     
     - Parameter restrict: publicity of the requested content
     - Parameter offset: offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse with the newest content of the illustrations of the users you follow
     */
    public func illust_follow(restrict: Publicity = .public, offset: Int = 0, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "v2/illust/follow", relativeTo: self.hosts)!
        let params = [
            "restrict": restrict.rawValue,
            "offset": offset.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch illustration details like title, caption, tags etc.
     - Parameter illust_id: ID of the illustration
     - Parameter req_auth:  whether the API is require to be authorized
     - returns: a PixivResponse with the requested details
     */
    public func illust_detail(illust_id: Int, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "v1/illust/detail", relativeTo: self.hosts)!
        let params = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch comments posted under a given illustration
     - Parameter illust_id: ID of the illustration
     - Parameter offset: offset of the requested comments
     - Parameter include_total_comments: whether to include total comments
     - Parameter req_auth: whether the API is required to be authorized
     - returns: the comments of the illustration as a PixivResponse
     */
    public func illust_comments(illust_id: Int, offset: Int? = nil, include_total_comments: Bool? = nil, req_auth: Bool = true) throws -> PixivIllustrationCommentResult {
        let url = URL(string: "v1/illust/comments", relativeTo: self.hosts)!
        var params = [
            "illust_id": illust_id.description
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        if let include_total_comments = include_total_comments {
            params["include_total_comments"] = include_total_comments.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivIllustrationCommentResult.self, from: Data(result.utf8))
    }
    
    public func illust_comment_add() {}
    
    /**
     fetch illustrations related to a given ID
     - Parameter illust_id: ID of the illustration
     - Parameter filter: request for a specific platform
     - Parameter seed_illust_ids: array with more IDs that should be considered
     - Parameter offset: offset of the requested illustrations
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse with similiar illustrations
     */
    public func illust_related(illust_id: Int, filter: String = "for_ios", seed_illust_ids: Array<Int>? = nil, viewed: Array<Int>? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v2/illust/related", relativeTo: self.hosts)!
        var params = [
            "illust_id": illust_id.description,
            "filter": filter,
            "offset": offset == nil ? 0.description : offset!.description
        ]
        if let seed_illust_ids = seed_illust_ids, !seed_illust_ids.isEmpty {
            params["seed_illust_ids[]"] = (seed_illust_ids.count == 1) ? seed_illust_ids.first!.description : seed_illust_ids.description
        }
        if let viewed = viewed {
            params["viewed[]"] = (viewed.count == 1) ? viewed.first!.description : viewed.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
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
     - returns: a PixivResponse with recommendations for the user
     */
    public func illust_recommended(content_type: String = "illust", include_ranking_label: Bool = true, filter: String = "for_ios", max_bookmark_id_for_recommend: Int? = nil, min_bookmark_id_for_recent_illust: Int? = nil, offset: Int? = nil, include_ranking_illusts: Bool? = nil, bookmark_illust_ids: Array<String>? = nil, include_privacy_policy: Bool? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url: URL
        if req_auth {
            url = URL(string: "v1/illust/recommended", relativeTo: self.hosts)!
        } else {
            url = URL(string: "v1/illust/recommended-nologin", relativeTo: self.hosts)!
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
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch novels recommended for your account
     - Parameter include_ranking_label: whether to include the ranking label
     - Parameter filter: request for a specific platform
     - Parameter max_bookmark_id_for_recommend: (optional) highest bookmark ID that should be considered for recommendations
     - Parameter min_bookmark_id_for_recent_illust: (optional) lowest bookmark ID that should be considered for recent recommendations
     - Parameter offset: (optional) offset of the requested illustrations
     - Parameter include_ranking_illusts: (optional) also include ranked illustrations
     - Parameter bookmark_illust_ids: (optional)  bookmark IDs of illustrations that should be considered
     - Parameter include_privacy_policy: (optional) include the privacy policy
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse with recommendations for the user
     */
    public func novel_recommended(include_ranking_label: Bool = true, filter: String = "for_ios", max_bookmark_id_for_recommend: Int? = nil, min_bookmark_id_for_recent_illust: Int? = nil, offset: Int? = nil, include_ranking_illusts: Bool? = nil, bookmark_illust_ids: Array<String>? = nil, include_privacy_policy: Bool? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "v1/novel/recommended", relativeTo: self.hosts)!
        var params = [
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
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    /**
     fetch novels recommended for your account
     - Parameter include_ranking_label: whether to include the ranking label
     - Parameter filter: request for a specific platform
     - Parameter max_bookmark_id_for_recommend: (optional) highest bookmark ID that should be considered for recommendations
     - Parameter min_bookmark_id_for_recent_illust: (optional) lowest bookmark ID that should be considered for recent recommendations
     - Parameter offset: (optional) offset of the requested illustrations
     - Parameter include_ranking_illusts: (optional) also include ranked illustrations
     - Parameter bookmark_illust_ids: (optional)  bookmark IDs of illustrations that should be considered
     - Parameter include_privacy_policy: (optional) include the privacy policy
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse with recommendations for the user
     */
    public func manga_recommended(include_ranking_label: Bool = true, filter: String = "for_ios", max_bookmark_id_for_recommend: Int? = nil, min_bookmark_id_for_recent_illust: Int? = nil, offset: Int? = nil, include_ranking_illusts: Bool? = nil, bookmark_illust_ids: Array<String>? = nil, include_privacy_policy: Bool? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "v1/manga/recommended", relativeTo: self.hosts)!
        var params = [
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
        return try decoder.decode(PixivResult.self, from: Data(result.utf8)) }
    
    /**
     fetch ranked illustrations
     - Parameter mode: timespan of the ranking
     - Parameter filter: request for a specific platform
     - Parameter date: (optional) request for a specific date
     - Parameter offset: (optional) offset of the requested illustrations
     - Parameter req_auth: whether the API is required to be authorized
     */
    public func illust_ranking(mode: String = "day", filter: String = "for_ios", date: Date? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult{
        let url = URL(string: "v1/illust/ranking", relativeTo: self.hosts)!
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
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch trending illustration tags
     - Parameter filter: request for a specific platform
     - Parameter req_auth: whether the API is required to be logged in
     - returns: a PixivResponse with the currently trending tags
     */
    public func trending_tags_illust(filter: String = "for_ios", req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/trending-tags/illust", relativeTo: self.hosts)!
        let params = [
            "filter": filter
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    public func search_tag(word: String, filter: String = "for_ios", req_auth: Bool = true) throws -> [IllustrationTag] {
        let url = URL(string: "v2/search/autocomplete", relativeTo: self.hosts)!
        let params = [
            "word": word,
            "filter": filter
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params)
        return try decoder.decode(AutocompleteIllustrationTags.self, from: Data(result.utf8)).tags
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
     - returns: a PixivResponse with search results
     */
    public func search_illust(word: String, search_target: SearchMode = .partial_match_for_tags, sort: SortMode = .date_desc, duration: Duration? = nil, start_date: Date? = nil, end_date: Date? = nil, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = sort == .popular_desc && (offset ?? 0 == 0)
        ? URL(string: "v1/search/popular-preview/illust", relativeTo: self.hosts)! // Yes, we can actually access the first 10 results, even without premium. This is the "7-day trial" when you (re)download the app
        : URL(string: "v1/search/illust", relativeTo: self.hosts)!
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
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
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
     - returns: a PixivResponse with search results
     */
    public func search_novel(word: String, search_target: SearchMode = .partial_match_for_tags, sort: SortMode = .date_desc, merge_plain_keyword_results: Bool = true, include_translated_tag_results: Bool = true, start_date: Date? = nil, end_date: Date? = nil, filter: String? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/search/novel", relativeTo: self.hosts)!
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
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     search users by a part of or their whole name
     - Parameter word: a name or a part of it
     - Parameter sort: how the results should be sorted
     - Parameter duration: (optional) timespan that should be considered
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing potential search results
     */
    public func search_user(word: String, sort: SortMode = .date_desc, duration: Duration? = nil, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/search/user", relativeTo: self.hosts)!
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
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     Add comment to illustration
     
     - Parameter comment: The comment to populate under the illustration
     */
    public func novel_illust_add(comment: String, req_auth: Bool = true) throws -> PixivIllustrationCommentResult {
        let url = URL(string: "v1/illust/comment/add", relativeTo: self.hosts)!
        let data = [
            "comment": comment
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, data: data, req_auth: req_auth)
        return try decoder.decode(PixivIllustrationCommentResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch fetails about a bookmarked illustration
     - Parameter illust_id: ID of the illustration details should be fetched for
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the details
     */
    public func illust_bookmark_detail(illust_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v2/illust/bookmark/detail", relativeTo: self.hosts)!
        let params = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     bookmark an illustration
     - Parameter illust_id: ID of the illustration that should be bookmarked
     - Parameter restrict: publicity of the bookmark
     - Parameter tags: (optional) array of the bookmark collections this bookmark should be appended
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse
     */
    public func illust_bookmark_add(illust_id: Int, restrict: Publicity = .public, tags: Array<String>? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v2/illust/bookmark/add", relativeTo: self.hosts)!
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
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     delete an illustration from your bookmarks
     - Parameter illust_id: ID of the illustration that should be deleted from the bookmarks
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse
     */
    public func illust_bookmark_delete(illust_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/illust/bookmark/delete", relativeTo: self.hosts)!
        let data = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     follow a user
     - Parameter user_id: ID of the user that should be followed
     - Parameter restrict: publicity of the bookmark
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse
     */
    public func user_follow_add(user_id: Int, restrict: Publicity = .public, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/follow/add", relativeTo: self.hosts)!
        let data = [
            "user_id": user_id.description,
            "restrict": restrict.rawValue
        ]
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    /**
     unfollow a user
     - Parameter user_id: ID of the user that should be unfollowed
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse
     */
    public func user_follow_delete(user_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/follow/delete", relativeTo: self.hosts)!
        let data = [
            "user_id": user_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch tags the a given user uses to structure their bookmarks
     - Parameter restrict: publicity of the tags
     - Parameter offset:(optional) offset of the requested tags
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the tags
     */
    public func user_bookmark_tags_illust(restrict: Publicity = .public, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/bookmark-tags/illust", relativeTo: self.hosts)!
        var params = [
            "restrict": restrict.rawValue
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch users a given user follows
     - Parameter user_id: ID of the user
     - Parameter restrict: publicity of the follows
     - Parameter offset:(optional) offset of the requested users
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the users
     */
    public func user_following(user_id: Int, restrict: Publicity = .public, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/following", relativeTo: self.hosts)!
        var params = [
            "user_id": user_id.description,
            "restrict": restrict.rawValue
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     get the followers of a given user
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset:(optional) offset of the requested tags
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the users
     */
    public func user_follow(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/follower", relativeTo: self.hosts)!
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     - Parameter user_id: ID of the user
     - Parameter offset: (optional) offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the user's mypixiv content
     */
    public func user_mypixiv(user_id: Int, offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/mypixiv", relativeTo: self.hosts)!
        var params = [
            "user_id": user_id.description
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     list users (?)
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested users
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the users
     */
    public func user_list(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v2/user/list", relativeTo: self.hosts)!
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch metadata like frame delays of an ugoira illustration
     - Parameter illust_id: ID of the illustration
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the ugoiras metadata
     */
    public func ugoira_metadata(illust_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/ugoira/metadata", relativeTo: self.hosts)!
        let params = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch a user's novels
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested users
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the user's novels
     */
    public func user_novels(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/user/novels", relativeTo: self.hosts)!
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if let offset = offset {
            params["offset"] = offset.description
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch a novel series
     - Parameter series_id: ID of the series
     - Parameter filter: request for a specific platform
     - Parameter last_order: (optional) last order of the series (?)
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the series
     */
    public func novel_series(series_id: Int, filter: String = "for_ios", last_order: String? = nil, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v2/novel/series", relativeTo: self.hosts)!
        var params = [
            "series_id": series_id.description,
            "filter": filter
        ]
        if let last_order = last_order {
            params["last_oder"] = last_order
        }
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch details about a novel
     - Parameter novel_id: ID of the novel
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the novel details
     */
    public func novel_details(novel_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v2/novel/detail", relativeTo: self.hosts)!
        let params = [
            "novel_id": novel_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     fetch the text of a novel
     - Parameter novel_id: ID of the novel
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the novel text
     */
    public func novel_text(novel_id: Int, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/novel/text", relativeTo: self.hosts)!
        let params = [
            "novel_id": novel_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    /**
     Add comment to novel
     
     - Parameter comment: The comment to populate under the novel
     */
    public func novel_comment_add(comment: String, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/novel/comment/add", relativeTo: self.hosts)!
        let data = [
            "comment": comment
        ]
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    /**
     Add comment to novel
     
     - Parameter comment: The comment to populate under the novel
     */
    public func novel_comment_delete(comment: String, req_auth: Bool = true) throws -> PixivResult {
        let url = URL(string: "v1/novel/comment/delete", relativeTo: self.hosts)!
        let data = [
            "comment": comment
        ]
        
        let result = try self.no_auth_requests_call(method: .POST, url: url, data: data, req_auth: req_auth)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
    
    public func upload_novel_covers() throws -> PixivNovelCovers {
        let url = URL(string: "v1/upload/novel/covers", relativeTo: self.hosts)!
        let params: Dictionary<String, String> = [:]
        let data: Dictionary<String, String> = [:]
        let result = try self.no_auth_requests_call(method: .GET, url: url, params: params, data: data)
        return try decoder.decode(PixivNovelCovers.self, from: Data(result.utf8))
    }
    
    /*
    public func novel_drafts_detail(novel_id: Int) throws -> <#ResultType#> {
        let url = URL(string: <#Endpoint#>, relativeTo: <#Host#>)!
        let params: Dictionary<String, String> = [:]
        let data: Dictionary<String, String> = [:]
        let result = try self.no_auth_requests_call(method: <#T##HttpMethod#>, url: url, params: params, data: data)
        return try decoder.decode(<#ResultType.self#>, from: result)
    }
     */
    
    public func notification_has_unread() throws -> Bool {
        let url = URL(string: "v1/notification/has-unread-notifications", relativeTo: self.hosts)!
        let result = try self.no_auth_requests_call(method: .POST, url: url)
        return try decoder.decode(NotificationUnreadResult.self, from: Data(result.utf8)).hasUnreadNotifications
    }
    
    
    /**
     Register user for notification
     - returns: the topic of the curently logged in user
     */
    internal func notification_user_register() throws -> PixivNotificationRegistration {
        let url = URL(string: "v1/notification/user/register", relativeTo: self.hosts)!
        let params = [
            "timetone_offset": Date().offsetFromUTC().description
        ]
        let result = try self.no_auth_requests_call(method: .POST, url: url, params: params)
        return try decoder.decode(PixivNotificationRegistration.self, from: Data(result.utf8))
    }
    
    /**
     - returns: The newest notifications, together with the latest seen illustration ID and latest seen novel ID
     */
    internal func notification_following() throws -> NotificationNewFromFollowing {
        let url = URL(string: "v1/notification/new-from-following", relativeTo: self.hosts)!
        let result = try self.no_auth_requests_call(method: .POST, url: url)
        return try decoder.decode(NotificationNewFromFollowing.self, from: Data(result.utf8))
    }
    
    /**
     list all notifications
     WIP, HTTP 500 when pocking around... Code is probably not going to work, please stay patient...
     */
    internal func notification_following() throws -> [PixivNotification] {
        let url = URL(string: "v1/notification/list", relativeTo: self.hosts)!
        let result = try self.no_auth_requests_call(method: .GET, url: url)
        return try decoder.decode([PixivNotification].self, from: Data(result.utf8))
    }
    
    /**
     WIP, HTTP 500 when pocking around... Code is probably not going to work, please stay patient...
     */
    internal func notification_more() throws -> [PixivNotification] {
        let url = URL(string: "v1/notification/view-more", relativeTo: self.hosts)!
        let result = try self.no_auth_requests_call(method: .GET, url: url)
        return try decoder.decode([PixivNotification].self, from: Data(result.utf8))
    }
    
    /**
     fetch the user's settings
     - returns: the user's settings
     */
    public func notification_settings() throws -> PixivNotificationSettings {
        let url = URL(string: "v1/notification/settings", relativeTo: self.hosts)!
        let result = try self.no_auth_requests_call(method: .GET, url: url)
        return try decoder.decode(_PixivNotificationSettings.self, from: Data(result.utf8)).notificationSettings // AAAAAAAA
    }
    
    /**
     edit… settings
     - Parameter notificationID: the id of the `PixivNotificationSetting`
     - Parameter setTo: the new state
     
     WIP as only turning off is possible, additionally only all at once
     */
    internal func notification_settings_edit(notificationID: Int, setTo value: Bool) throws {
        let url = URL(string: "v1/notification/settings/edit", relativeTo: self.hosts)!
        let data = [
            "id": notificationID.description,
            "enabled": value.description
        ]
        let _ = try self.no_auth_requests_call(method: .GET, url: url, data: data)
    }
    
    /**
     fetch application info
     - Parameter platform: the OS of the app
     - returns: information about the current app release
     */
    public func application_info(platform: AppPlatform) throws -> PixivApplicationInformation {
        let url = URL(string: "v1/application-info/\(platform.rawValue)", relativeTo: self.hosts)!
        let result = try self.no_auth_requests_call(method: .GET, url: url)
        return try decoder.decode(PixivApplicationInformation.self, from: Data(result.utf8))
    }
    
    /**
     fetch a showcase article
     - Parameter showcase_id: ID of the showcase
     - returns: a PixivResponse containing the showcase
     */
    public func showcase_article(showcase_id: Int) throws -> PixivResult {
        let url = URL(string: "https://www.pixiv.net/ajax/showcase/article", relativeTo: self.hosts)!
        let headers = [
            "User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36",
            "Referer": "https://www.pixiv.net"
        ]
        let params = [
            "article-id": showcase_id.description
        ]
        let result = try self.no_auth_requests_call(method: .GET, url: url, headers: headers, params: params, req_auth: false)
        return try decoder.decode(PixivResult.self, from: Data(result.utf8))
    }
}

extension AppPixivAPI {
    
    /// `enum` defining several strategies to let the server sort content
    public enum SortMode: String {
        /// oldest content first
        case date_asc
        /// newest content first
        case date_desc
        /// most popular content first; _premium feature_; defaults to date\_desc if not premium
        case popular_desc
    }
    
    /// `enum` defining tolerances for searches via `AppPixivAPI.search_illust(word:search_target:sort:duration:start_date:end_date:filter:offset:req_auth:)`
    public enum SearchMode: String {
        /// applies if post _also contains_ specified `word`s
        case partial_match_for_tags
        /// applies if post _only contains_ specified `word`s
        case exact_match_for_tags
        /// applies if `word`s are found in title and caption of the post
        case title_and_caption
    }
    
    /// `enum` defining the search perios for searches via `AppPixivAPI.search_illust(word:search_target:sort:duration:start_date:end_date:filter:offset:req_auth:)`
    public enum Duration: String {
        /// only search for posts published in the last 24 h
        case within_last_day
        /// only search for posts published in the last 7 days
        case within_last_week
        /// only search for posts published in the last 30 days
        case within_last_month
    }
    
    /// `enum` defining the different OSs the app is released for
    public enum AppPlatform: String {
        /// Apple's iOS
        case ios
        /// Google's Android
        case android
    }
}
