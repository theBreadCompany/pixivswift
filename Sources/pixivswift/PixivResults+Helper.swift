//
//  PixivResults+Helper.swift
//  
//
//  Created by theBreadCompany on 15.07.22.
//

import Foundation

internal struct AutocompleteIllustrationTags: Codable {
    var tags: [IllustrationTag]
}

internal struct NotificationUnreadResult: Codable {
    public var hasUnreadNotifications: Bool
}

internal struct NotificationNewFromFollowing: Codable {
    public var notification: PixivNotification
    public var latestSeenIllustId: Int
    public var latestSeenNovelId: Int
}

internal struct PixivNotification: Codable {}

internal struct PixivNotificationRegistration: Codable {
    public var topic: String
}


internal struct _PixivNotificationSettings: Codable {
    public var notificationSettings: PixivNotificationSettings
}
