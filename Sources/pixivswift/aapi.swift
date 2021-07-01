//
//  aapi.swift
//  SwiftyPixiv
//
//  Created by Fabio Mauersberger on 16.04.21.
//  Original work written in Python by https://github.com/upbit.
//

import Foundation
import SwiftyJSON

public class AppPixivAPI: BasePixivAPI {
    
    public override init() {
        super.init()
        self.hosts = "https://app-api.pixiv.net"
    }
    
    private func no_auth_requests_call(method: String, url: String, headers: Dictionary<String, String> = [:], params: Dictionary<String, String> = [:], data: Dictionary<String, String> = [:], req_auth: Bool = true) throws -> String {
        var _headers = headers
        if self.hosts != "https://app-api.pixiv.net" {
            _headers["host"] = "app-api.pixiv.net"
        }
        if headers["User-Agent"] ?? nil == nil && headers["user-agent"] ?? nil == nil {
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
    
    private func parse_result(req: String) -> JSON{
        let result = self.parse_json(json: req.description)
        return result
    }
    
    public func parse_qs(url: String) throws -> JSON{
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

    public func user_detail(user_id: Int, filter: String = "for_ios", req_auth: Bool = true) throws -> JSON{
        let url = "\(self.hosts)/v1/user/detail"
        let params = [
            "user_id": String(user_id),
            "filter": filter
        ]
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params)
        return self.parse_result(req: result)
    }
    
    // available types: "illust", "manga"
    public func user_illusts(user_id: Int, type: String = "illust", filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> JSON{
        let url = "\(self.hosts)/v1/user/illusts"
        var params = [
            "user_id": String(user_id),
            "filter": filter
        ]
        if !type.isEmpty {
            params["type"] = type
        }
        if offset != nil {
            params["offset"] = String(offset!)
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_bookmarks_illust(user_id: Int, restrict: String = "public", filter: String = "for_ios", max_bookmark: Int? = nil, tag: String? = nil, req_true: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/bookmarks/illust"
        var params = [
            "user_id": String(user_id),
            "restrict": restrict,
            "filter": filter
        ]
        if max_bookmark != nil {
            params["max_bookmark_id"] = String(max_bookmark!)
        }
        if tag != nil {
            params["tag"] = tag!
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_true)
        return self.parse_result(req: result)
    }
    
    public func user_related(seed_user_id: Int, filter: String = "for_ios", offset: Int = 0, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/related"
        let params = [
            "filter": filter,
            "offset": offset.description,
            "seed_user_id": seed_user_id.description
        ]
        let r = try no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        var parsed_r = self.parse_result(req: r)
        parsed_r["next_url"] = JSON("\(self.hosts)/v1/user/related?filter=" + params["filter"]! + "&offset=\(Int(params["offset"]!)!+30)&seed_user_id=" + params["seed_user_id"]!)
        return parsed_r
    }
    
    public func illust_follow(restrict: String = "public", offset: Int? = nil, req_auth: Bool = true) throws -> JSON{
        let url = "\(self.hosts)/v2/illust/follow"
        var params = [
            "restrict": restrict
        ]
        if offset != nil {
            params["offset"] = String(offset!)
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func illust_detail(illust_id: Int, req_auth: Bool = true) throws -> JSON{
        let url = "\(self.hosts)/v1/illust/detail"
        let params = [
            "illust_id": String(illust_id)
        ]
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func illust_comments(illust_id: Int, offset:Int? = nil, include_total_comments: Bool? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/illust/comments"
        var params = [
            "illust_id": String(illust_id)
        ]
        if offset != nil {
            params["offset"] = String(offset!)
        }
        if include_total_comments != nil {
            params["include_total_comments"] = String(include_total_comments!)
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func illust_related(illust_id: Int, filter: String = "for_ios", seed_illust_ids: Array<Int>? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v2/illust/related"
        var params = [
            "illust_id": String(illust_id),
            "filter": filter,
            "offset": offset == nil ? 0.description : offset!.description
        ]
        if seed_illust_ids != nil {
            params["seed_illust_ids[]"] = seed_illust_ids!.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func illust_recommended(content_type: String = "illust", include_ranking_label: Bool = true, filter: String = "for_ios", max_bookmark_id_for_recommend: Int? = nil, min_bookmark_id_for_recent_illust: Int? = nil, offset: Int? = nil, include_ranking_illusts: Bool? = nil, bookmark_illust_ids: Array<String>? = nil, include_privacy_policy: Bool? = nil, req_auth: Bool = true) throws -> JSON{
        let url: String
        if req_auth {
            url = "\(self.hosts)/v1/illust/recommended"
        } else {
            url = "\(self.hosts)/v1/illust/recommended-nologin"
        }
        var params = [
            "conntent_type": content_type,
            "include_ranking_label": include_ranking_label.description,
            "filter": filter
        ]
        if max_bookmark_id_for_recommend != nil {
            params["max_bookmark_id_for_recommend"] = max_bookmark_id_for_recommend?.description
        }
        if min_bookmark_id_for_recent_illust != nil {
            params["min_bookmark_id_for_recent_illust"] = min_bookmark_id_for_recent_illust?.description
        }
        if offset != nil {
            params["offset"] = offset?.description
        }
        if include_ranking_illusts != nil {
            params["include_ranking_illusts"] = include_ranking_illusts?.description
        }
        
        if !req_auth {
            if bookmark_illust_ids?.count == 1 {
                params["bookmark_illust_ids"] = bookmark_illust_ids?.first
            } else if bookmark_illust_ids!.count > 1 {
                params["bookmark_illust_ids"] = bookmark_illust_ids?.description.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            }
        }
        
        if include_privacy_policy! {
            params["include_privacy_policy"] = include_privacy_policy?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func illust_ranking(mode: String = "day", filter: String = "for_ios", date: String? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> JSON{
        let url = "\(self.hosts)/v1/illust/ranking"
        var params = [
            "mode": mode,
            "filter": filter
        ]
        
        if date != nil {
            params["date"] = date!
        }
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return parse_result(req: result)
    }
    
    public func trending_tags_illust(filter: String = "for_ios", req_auth:Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/trending-tags/illust"
        let params = [
            "filter": filter
        ]
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func search_illust(word: String, search_target: String = "partial_match_for_tags", sort: String = "date_desc", duration: String? = nil, start_date: String? = nil, end_date: String? = nil, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/search/illust"
        var params = [
            "word": word,
            "search_target": search_target,
            "sort": sort,
            "filter": filter
        ]
        if start_date != nil {
            params["start_date"] = start_date!
        }
        if end_date != nil {
            params["end_date"] = end_date!
        }
        if duration != nil {
            params["duration"] = duration!
        }
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func search_novel(word: String, search_target: String = "partial_match_for_tags", sort: String = "date_desc", merge_plain_keyword_results: Bool = true, include_translated_tag_results: Bool = true, start_date: String? = nil, end_date: String? = nil, filter: String? = nil, offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/search/novel"
        var params = [
            "word": word,
            "search_targets": search_target,
            "merge_plain_keyword_results": merge_plain_keyword_results.description,
            "include_translated_tag_results": include_translated_tag_results.description,
            "sort": sort,
            "filter": filter!
        ]
        if start_date != nil {
            params["start_date"] = start_date
        }
        if end_date != nil {
            params["end_date"] = end_date
        }
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func search_user(word: String, sort: String = "date_desc", duration: String? = nil, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/search/user"
        var params = [
            "word": word,
            "sort": sort,
            "filter": filter
        ]
        
        if duration != nil {
            params["duration"] = duration
        }
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func illust_bookmark_detail(illust_id: Int, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v2/illust/bookmark/detail"
        let params = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func illust_bookmark_add(illust_id: Int, restrict: String = "public", tags: Array<String>? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v2/illust/bookmark/add"
        var data = [
            "illust_id": illust_id.description,
            "restrict": restrict
        ]
        if tags != nil {
            if tags!.count == 1 {
                data["tags"] = tags!.first
            } else if tags!.count > 1 {
                data["tags"] = tags!.joined(separator: " ")
            }
        }
        
        let result = try self.no_auth_requests_call(method: "POST", url: url, data: data, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func illust_bookmark_delete(illust_id: Int, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/illust/bookmark/delete"
        let data = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: "POST", url: url, data: data, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_follow_add(user_id: Int, restrict: String = "public", req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/follow/add"
        let data = [
            "user_id": user_id.description,
            "restrict": restrict
        ]
        
        let result = try self.no_auth_requests_call(method: "POST", url: url, data: data, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_follow_delete(user_id: Int, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/follow/delete"
        let data = [
            "user_id": user_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: "POST", url: url, data: data, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_bookmark_tags_illust(restrict: String = "public", offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/bookmark-tags/illust"
        var params = [
            "restrict": restrict
        ]
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_following(user_id: Int, restrict: String = "public", offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/following"
        var params = [
            "user_id": user_id.description,
            "restrict": restrict
        ]
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_follow(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/follower"
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_mypixiv(user_id: Int, offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/mypixiv"
        var params = [
            "user_id": user_id.description
        ]
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_list(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v2/user/list"
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func ugoira_metadata(illust_id: Int, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/ugoira/metadata"
        let params = [
            "illust_id": illust_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func user_novels(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/user/novels"
        var params = [
            "user_id": user_id.description,
            "filter": filter
        ]
        if offset != nil {
            params["offset"] = offset?.description
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func novel_series(series_id: Int, filter: String = "for_ios", last_order: String? = nil, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v2/novel/series"
        var params = [
            "series_id": series_id.description,
            "filter": filter
        ]
        if last_order != nil {
            params["last_oder"] = last_order!
        }
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func novel_details(novel_id: Int, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v2/novel/detail"
        let params = [
            "novel_id": novel_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func novel_text(novel_id: Int, req_auth: Bool = true) throws -> JSON {
        let url = "\(self.hosts)/v1/novel/text"
        let params = [
            "novel_id": novel_id.description
        ]
        
        let result = try self.no_auth_requests_call(method: "GET", url: url, params: params, req_auth: req_auth)
        return self.parse_result(req: result)
    }
    
    public func showcase_article(showcase_id: Int) throws -> JSON {
        let url = "https://www.pixiv.net/ajax/showcase/article"
        let headers = [
            "User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36",
            "Referer": "https://www.pixiv.net"
        ]
        let params = [
            "article-id": showcase_id.description
        ]
        let result = try self.no_auth_requests_call(method: "GET", url: url, headers: headers, params: params, req_auth: false)
        return self.parse_result(req: result)
    }
}

