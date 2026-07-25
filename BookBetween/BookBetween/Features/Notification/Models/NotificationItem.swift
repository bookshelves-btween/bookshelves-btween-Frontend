//
//  NotificationItem.swift
//  BookBetween
//

import Foundation

struct NotificationItem: Identifiable, Equatable {
    let id: Int
    let type: NotificationType
    let title: String
    let message: String
    let isActionable: Bool
    let isRead: Bool
    let targetId: Int?
    let createdAt: Date

    init(
        id: Int,
        type: NotificationType,
        title: String,
        message: String,
        isActionable: Bool,
        isRead: Bool = false,
        targetId: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.isActionable = isActionable
        self.isRead = isRead
        self.targetId = targetId
        self.createdAt = createdAt
    }

    func markingAsRead() -> NotificationItem {
        NotificationItem(
            id: id,
            type: type,
            title: title,
            message: message,
            isActionable: isActionable,
            isRead: true,
            targetId: targetId,
            createdAt: createdAt
        )
    }
}

enum NotificationType: Equatable {
    case meetingCancelled
    case aiSummaryReady
    case meetingStarted
    case system

    init(apiValue: String) {
        switch apiValue {
        case "MEETING_CANCELLED":
            self = .meetingCancelled
        case "MEETING_SUMMARY_DONE":
            self = .aiSummaryReady
        case "MEETING_STARTED":
            self = .meetingStarted
        case "SYSTEM":
            self = .system
        default:
            self = .system
        }
    }
}

struct NotificationPage: Equatable {
    let notifications: [NotificationItem]
    let page: Int
    let size: Int
    let hasNext: Bool
}
