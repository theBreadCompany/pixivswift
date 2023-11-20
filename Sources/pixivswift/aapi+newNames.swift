//
//  aapi+newNames.swift
//
//
//  Created by theBreadCompany on 15.07.22.
//

import Foundation


/*
 signature: [action][relation]category
 action: get, search, add, remove
 [relation]: new, user (optional)
 category: user, illustration, novel, manga
 */

public typealias Visibility = Publicity

extension AppPixivAPI {
    
    // MARK: helper methods
    
    public func request(method: HttpMethod, url: URL, headers: Dictionary<String, String> = [:], params: Dictionary<String, String> = [:], data: Dictionary<String, String> = [:], req_auth: Bool = true) throws -> String {
        return try self.no_auth_requests_call(method: method, url: url, headers: headers, params: params, data: data, req_auth: true)
    }
    
    public func parse(nextURL: URL?) -> Dictionary<String, Any> {
        return self.parse_qs(url: nextURL)
    }
    
    // MARK:  user methods
    
    public func getUserDetails(ID: Int, filter: String = "for_ios") throws -> PixivUser? {
        return try self.user_detail(user_id: ID, filter: filter).userPreviews?.first
    }
    
    public func getUserIllustrations(ID: Int, type: String = "illust", filter: String = "for_ios", offset: Int = 0) throws -> [PixivIllustration]? {
        return try self.user_illusts(user_id: ID, type: type, filter: filter, offset: offset).illusts
    }
    
    public func getUserBookmarks(ID: Int, visibility: Visibility = .public, filter: String = "for_ios", offset: Int = 0, maxBookmarkID: Int? = nil, tag: String? = nil) throws -> [PixivIllustration]? {
        return try self.user_bookmarks_illust(user_id: ID, restrict: visibility, filter: filter, offset: offset, max_bookmark: maxBookmarkID, tag: tag).illusts
    }
    
    public func getUserRelated(ID: Int, filter: String = "for_ios", offset: Int = 0) throws -> [PixivUser]? {
        return try self.user_related(seed_user_id: ID, filter: filter, offset: offset).userPreviews
    }
    
    // MARK: illustration methods
    
    public func getIllustrationsNew(visibility: Visibility = .public, offset: Int = 0) throws -> [PixivIllustration]? {
        return try self.illust_follow(restrict: visibility, offset: offset).illusts
    }
    
    public func getIllustrationDetails(ID: Int) throws -> PixivIllustration? {
        return try self.illust_detail(illust_id: ID).illusts?.first
    }
    
    public func getIllustrationComments(ID: Int, offset: Int = 0, includeTotalComments: Bool = false) throws -> [PixivComment]? {
        return try self.illust_comments(illust_id: ID, offset: offset, include_total_comments: includeTotalComments).comments
    }
    
    public func uploadIllustrationComment() {}
    
    public func getIllustrationsRelated(ID: Int, filter: String = "for_ios", seedIDs: Array<Int>? = nil, viewedIDs: Array<Int>? = nil, offset: Int = 0) throws -> [PixivIllustration]? {
        return try self.illust_related(illust_id: ID, filter: filter, seed_illust_ids: seedIDs, viewed: viewedIDs, offset: offset).illusts
    }
    
    public func getIllustrationsRecommended(type: String = "illust", includeRankingLabel: Bool = true, filter: String = "for_ios", maxBookmarkIDForRecommendations: Int? = nil, minBookmarkIDForRecentIllusts: Int? = nil, offset: Int = 0, includeRankdingIllusts: Bool = false, bookmarkIllustIDs: Array<String>? = nil, includePrivacyPolicy: Bool = true) throws -> [PixivIllustration]? {
        return try self.illust_recommended(content_type: type, include_ranking_label: includeRankingLabel, filter: filter, max_bookmark_id_for_recommend: maxBookmarkIDForRecommendations, min_bookmark_id_for_recent_illust: minBookmarkIDForRecentIllusts, offset: offset, include_ranking_illusts: includeRankdingIllusts, bookmark_illust_ids: bookmarkIllustIDs, include_privacy_policy: includePrivacyPolicy).illusts
    }
    
    // MARK: novel methods
    
    public func getNovelRecommendations(includeRankingLabel: Bool = true, filter: String = "for_ios", maxBookmarkIDForRecommendations: Int? = nil, minBookmarkIDForRecentIllusts: Int? = nil, offset: Int = 0, includeRankingIllusts: Bool = true, bookmarkIllustIDs: Array<String>? = nil, includePrivacyPolicy: Bool = false) throws -> PixivResult {
        return try self.novel_recommended(include_ranking_label: includeRankingLabel, filter: filter, max_bookmark_id_for_recommend: maxBookmarkIDForRecommendations, min_bookmark_id_for_recent_illust: minBookmarkIDForRecentIllusts, offset: offset, include_ranking_illusts: includeRankingIllusts, bookmark_illust_ids: bookmarkIllustIDs, include_privacy_policy: includePrivacyPolicy)
    }
    
    public func getMangaRecommendations(includeRankingLabel: Bool = true, filter: String = "for_ios", maxBookmarkIDForRecommendations: Int? = nil, minBookmarkIDForRecentIllustrations: Int? = nil, offset: Int? = nil, includeRankingIllusts: Bool? = nil, bookmarkIllustrationIDs: Array<String>? = nil, includePrivacyPolicy: Bool = false) throws -> PixivResult {
        return try self.manga_recommended(include_ranking_label: includeRankingLabel, filter: filter, max_bookmark_id_for_recommend: maxBookmarkIDForRecommendations, min_bookmark_id_for_recent_illust: minBookmarkIDForRecentIllustrations, offset: offset, include_ranking_illusts: includeRankingIllusts, bookmark_illust_ids: bookmarkIllustrationIDs, include_privacy_policy: includePrivacyPolicy)
    }
    
    public func getIllustrationRanked(mode: String = "day", filter: String = "for_ios", date: Date? = nil, offset: Int = 0) throws -> [PixivIllustration]? {
        return try self.illust_ranking(mode: mode, filter: filter, date: date, offset: offset).illusts
    }
    
    public func getTrendingTags(filter: String = "for_ios") throws -> PixivResult {
        return try self.trending_tags_illust(filter: filter)
    }
    
    public func searchTags(word: String, filter: String = "for_ios") throws -> [IllustrationTag] {
        return try self.search_tag(word: word, filter: filter)
    }
    
    public func searchIllustrations(word: String, searchTarget: SearchMode = .partial_match_for_tags, sorting: SortMode = .date_desc, duration: Duration? = nil, start: Date? = nil, end: Date?, filter: String = "for_ios", offset: Int = 0) throws -> [PixivIllustration]? {
        return try self.search_illust(word: word, search_target: searchTarget, sort: sorting, duration: duration, start_date: start, end_date: end, filter: filter, offset: offset).illusts
    }
    
    public func searchNovels(word: String, searchTarget: SearchMode = .partial_match_for_tags, sorting: SortMode = .date_desc, mergeKeywords: Bool = true, includeTagTranslations: Bool = true, start: Date? = nil, end: Date? = nil, filter: String = "for_ios", offset: Int = 0) throws -> PixivResult {
        return try self.search_novel(word: word, search_target: searchTarget, sort: sorting, merge_plain_keyword_results: mergeKeywords, include_translated_tag_results: includeTagTranslations, start_date: start, end_date: end, filter: filter, offset: offset)
    }
    
    public func searchUsers(word: String, sorting: SortMode = .date_desc, duration: Duration? = nil, filter: String = "for_ios", offset: Int = 0) throws -> [PixivUser]? {
        return try self.search_user(word: word, sort: sorting, duration: duration, filter: filter, offset: offset).userPreviews
    }
    
    public func addNovelComment(_ comment: String) throws -> PixivIllustrationCommentResult {
        return try self.novel_illust_add(comment: comment)
    }
    
    public func getBookmarkDetails(ID: Int) throws -> PixivResult {
        return try self.illust_bookmark_delete(illust_id: ID)
    }
    
    public func addBookmark(ID: Int, visibility: Visibility = .public, tags: Array<String>? = nil) throws -> PixivResult {
        return try self.illust_bookmark_add(illust_id: ID, restrict: visibility, tags: tags)
    }
    
    public func deleteBookmarks(ID: Int) throws -> PixivResult {
        return try self.illust_bookmark_delete(illust_id: ID)
    }
    
}
