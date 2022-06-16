//
//  api+completionHandlers.swift
//  
//
//  Created by Fabio Mauersberger on 16.06.22.
//

import Foundation

extension AppPixivAPI {
    
    /**
     fetch details about a user
     
     - Parameter user_id: ID of the requested user
     - Parameter filter: request for a specific platform
     - Parameter req_auth: whether the API needs to be authorized
     - returns: the user's information as a PixivResponse
     */
    public func user_detail(user_id: Int, filter: String = "for_ios", req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_detail(user_id: user_id, filter: filter, req_auth: req_auth))
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
    public func user_illusts(user_id: Int, type: String = "illust", filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws{
        completionHandler(try user_illusts(user_id: user_id, type: type, filter: filter, offset: offset, req_auth: req_auth))
    }
    
    /**
     fetch the illustration a user has bookmarked
     
     - Parameter user_id: ID of the user
     - Parameter restrict: publicity of the requested content
     - Parameter filter: request for a specific platform
     - Parameter offset: offset of the requested content
     - Parameter max_bookmark: (optional) highest ID that should be fetched
     - Parameter tag: (optional) name of the requested bookmark collection
     - Parameter req_auth: whether the API is required to be authorized
     - returns: the user's bookmarks as a PixivResponse
     */
    public func user_bookmarks_illust(user_id: Int, restrict: Publicity = .public, filter: String = "for_ios", offset: Int = 0, max_bookmark: Int? = nil, tag: String? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_bookmarks_illust(user_id: user_id, restrict: restrict, filter: filter, offset: offset, max_bookmark: max_bookmark, tag: tag, req_true: req_auth))
    }
    
    /**
     fetch users similiar to a given one
     
     - Parameter seed_user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse with related users to the given ID
     */
    public func user_related(seed_user_id: Int, filter: String = "for_ios", offset: Int = 0, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_related(seed_user_id: seed_user_id, filter: filter, offset: offset, req_auth: req_auth))
    }
    
    /**
     fetch the newest illustrations of the users you are following
     
     - Parameter restrict: publicity of the requested content
     - Parameter offset: offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse with the newest content of the illustrations of the users you follow
     */
    public func illust_follow(restrict: Publicity = .public, offset: Int = 0, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws{
        completionHandler(try illust_follow(restrict: restrict, offset: offset, req_auth: req_auth))
    }
    
    /**
     fetch illustration details like title, caption, tags etc.
     - Parameter illust_id: ID of the illustration
     - Parameter req_auth:  whether the API is require to be authorized
     - returns: a PixivResponse with the requested details
     */
    public func illust_detail(illust_id: Int, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws{
        completionHandler(try illust_detail(illust_id: illust_id, req_auth: req_auth))
    }
    
    /**
     fetch comments posted under a given illustration
     - Parameter illust_id: ID of the illustration
     - Parameter offset: offset of the requested comments
     - Parameter include_total_comments: whether to include total comments
     - Parameter req_auth: whether the API is required to be authorized
     - returns: the comments of the illustration as a PixivResponse
     */
    public func illust_comments(illust_id: Int, offset: Int? = nil, include_total_comments: Bool? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try illust_comments(illust_id: illust_id, offset: offset, include_total_comments: include_total_comments, req_auth: req_auth))
    }
    
    /**
     fetch illustrations related to a given ID
     - Parameter illust_id: ID of the illustration
     - Parameter filter: request for a specific platform
     - Parameter seed_illust_ids: array with more IDs that should be considered
     - Parameter offset: offset of the requested illustrations
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse with similiar illustrations
     */
    public func illust_related(illust_id: Int, filter: String = "for_ios", seed_illust_ids: Array<Int>? = nil, viewed: Array<Int>? = nil, offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try illust_related(illust_id: illust_id, filter: filter, seed_illust_ids: seed_illust_ids, viewed: viewed, offset: offset, req_auth: req_auth))
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
    public func illust_recommended(content_type: String = "illust", include_ranking_label: Bool = true, filter: String = "for_ios", max_bookmark_id_for_recommend: Int? = nil, min_bookmark_id_for_recent_illust: Int? = nil, offset: Int? = nil, include_ranking_illusts: Bool? = nil, bookmark_illust_ids: Array<String>? = nil, include_privacy_policy: Bool? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try illust_recommended(content_type: content_type, include_ranking_label: include_ranking_label, filter: filter, max_bookmark_id_for_recommend: max_bookmark_id_for_recommend, min_bookmark_id_for_recent_illust: min_bookmark_id_for_recent_illust, offset: offset, include_ranking_illusts: include_ranking_illusts, bookmark_illust_ids: bookmark_illust_ids, include_privacy_policy: include_privacy_policy, req_auth: req_auth))
    }
    
    /**
     fetch ranked illustrations
     - Parameter mode: timespan of the ranking
     - Parameter filter: request for a specific platform
     - Parameter date: (optional) request for a specific date
     - Parameter offset: (optional) offset of the requested illustrations
     - Parameter req_auth: whether the API is required to be authorized
     */
    public func illust_ranking(mode: String = "day", filter: String = "for_ios", date: Date? = nil, offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try illust_ranking(mode: mode, filter: filter, date: date, offset: offset, req_auth: req_auth))
    }
    
    /**
     fetch trending illustration tags
     - Parameter filter: request for a specific platform
     - Parameter req_auth: whether the API is required to be logged in
     - returns: a PixivResponse with the currently trending tags
     */
    public func trending_tags_illust(filter: String = "for_ios", req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try trending_tags_illust(filter: filter, req_auth: req_auth))
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
    public func search_illust(word: String, search_target: SearchMode = .partial_match_for_tags, sort: SortMode = .date_desc, duration: Duration? = nil, start_date: Date? = nil, end_date: Date? = nil, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try search_illust(word: word, search_target: search_target, sort: sort, duration: duration, start_date: start_date, end_date: end_date, filter: filter, offset: offset, req_auth: req_auth))
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
    public func search_novel(word: String, search_target: SearchMode = .partial_match_for_tags, sort: SortMode = .date_desc, merge_plain_keyword_results: Bool = true, include_translated_tag_results: Bool = true, start_date: Date? = nil, end_date: Date? = nil, filter: String? = nil, offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try search_novel(word: word, search_target: search_target, sort: sort, merge_plain_keyword_results: merge_plain_keyword_results, include_translated_tag_results: include_translated_tag_results, start_date: start_date, end_date: end_date, filter: filter, offset: offset, req_auth: req_auth))
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
    public func search_user(word: String, sort: SortMode = .date_desc, duration: Duration? = nil, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try search_user(word: word, sort: sort, duration: duration, filter: filter, offset: offset, req_auth: req_auth))
    }
    
    /**
     fetch fetails about a bookmarked illustration
     - Parameter illust_id: ID of the illustration details should be fetched for
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the details
     */
    public func illust_bookmark_detail(illust_id: Int, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try illust_bookmark_detail(illust_id: illust_id, req_auth: req_auth))
    }
    
    /**
     bookmark an illustration
     - Parameter illust_id: ID of the illustration that should be bookmarked
     - Parameter restrict: publicity of the bookmark
     - Parameter tags: (optional) array of the bookmark collections this bookmark should be appended
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse
     */
    public func illust_bookmark_add(illust_id: Int, restrict: Publicity = .public, tags: Array<String>? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try illust_bookmark_add(illust_id: illust_id, restrict: restrict, tags: tags, req_auth: req_auth))
    }
    
    /**
     delete an illustration from your bookmarks
     - Parameter illust_id: ID of the illustration that should be deleted from the bookmarks
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse
     */
    public func illust_bookmark_delete(illust_id: Int, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try illust_bookmark_delete(illust_id: illust_id, req_auth: req_auth))
    }
    
    /**
     follow a user
     - Parameter user_id: ID of the user that should be followed
     - Parameter restrict: publicity of the bookmark
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse
     */
    public func user_follow_add(user_id: Int, restrict: Publicity = .public, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_follow_add(user_id: user_id, restrict: restrict, req_auth: req_auth))
    }
    /**
     unfollow a user
     - Parameter user_id: ID of the user that should be unfollowed
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse
     */
    public func user_follow_delete(user_id: Int, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_follow_delete(user_id: user_id, req_auth: req_auth))
    }
    
    /**
     fetch tags the a given user uses to structure their bookmarks
     - Parameter restrict: publicity of the tags
     - Parameter offset:(optional) offset of the requested tags
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the tags
     */
    public func user_bookmark_tags_illust(restrict: Publicity = .public, offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_bookmark_tags_illust(restrict: restrict, offset: offset, req_auth: req_auth))
    }
    
    /**
     fetch users a given user follows
     - Parameter user_id: ID of the user
     - Parameter restrict: publicity of the follows
     - Parameter offset:(optional) offset of the requested users
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the users
     */
    public func user_following(user_id: Int, restrict: Publicity = .public, offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_following(user_id: user_id, restrict: restrict, offset: offset, req_auth: req_auth))
    }
    
    /**
     get the followers of a given user
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset:(optional) offset of the requested tags
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the users
     */
    public func user_follow(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_follow(user_id: user_id, filter: filter, offset: offset, req_auth: req_auth))
    }
    
    /**
     - Parameter user_id: ID of the user
     - Parameter offset: (optional) offset of the requested content
     - Parameter req_auth: whether the API is required to be authorized
     - returns: a PixivResponse containing the user's mypixiv content
     */
    public func user_mypixiv(user_id: Int, offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_mypixiv(user_id: user_id, offset: offset, req_auth: req_auth))
    }
    
    /**
     list users (?)
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested users
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the users
     */
    public func user_list(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_list(user_id: user_id, filter: filter, offset: offset, req_auth: req_auth))
    }
    
    /**
    fetch metadata like frame delays of an ugoira illustration
     - Parameter illust_id: ID of the illustration
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the ugoiras metadata
     */
    public func ugoira_metadata(illust_id: Int, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try ugoira_metadata(illust_id: illust_id, req_auth: req_auth))
    }
    
    /**
     fetch a user's novels
     - Parameter user_id: ID of the user
     - Parameter filter: request for a specific platform
     - Parameter offset: (optional) offset of the requested users
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the user's novels
     */
    public func user_novels(user_id: Int, filter: String = "for_ios", offset: Int? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try user_novels(user_id: user_id, filter: filter, offset: offset, req_auth: req_auth))
    }
    
    /**
     fetch a novel series
     - Parameter series_id: ID of the series
     - Parameter filter: request for a specific platform
     - Parameter last_order: (optional) last order of the series (?)
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the series
     */
    public func novel_series(series_id: Int, filter: String = "for_ios", last_order: String? = nil, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try novel_series(series_id: series_id, filter: filter, last_order: last_order, req_auth: req_auth))
    }
    
    /**
     fetch details about a novel
     - Parameter novel_id: ID of the novel
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the novel details
     */
    public func novel_details(novel_id: Int, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try novel_details(novel_id: novel_id, req_auth: req_auth))
    }
    
    /**
     fetch the text of a novel
     - Parameter novel_id: ID of the novel
     - Parameter req_auth: whether the API ist required to be authorized
     - returns: a PixivResponse containing the novel text
     */
    public func novel_text(novel_id: Int, req_auth: Bool = true, completionHandler: @escaping (PixivResult) -> Void) throws {
        completionHandler(try novel_text(novel_id: novel_id, req_auth: req_auth))
    }
}
