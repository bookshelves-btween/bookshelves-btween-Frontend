//
//  NotificationResponseDTO.swift
//  BookBetween
//

import Foundation

struct NotificationListResultDTO: Decodable {
    let notifications: [NotificationItemDTO]
    let page: Int
    let size: Int
    let hasNext: Bool
}

struct NewNotificationResultDTO: Decodable {
    let notifications: [NotificationItemDTO]
}

struct NotificationItemDTO: Decodable {
    let id: Int
    let type: String
    let title: String
    let content: String
    let isRead: Bool
    let targetId: Int?
    let createdAt: String
}

struct ReadNotificationResultDTO: Decodable {
    let id: Int
}

extension NotificationListResultDTO {
    func toDomain() throws -> NotificationPage {
        NotificationPage(
            notifications: try notifications.map { try $0.toDomain() },
            page: page,
            size: size,
            hasNext: hasNext
        )
    }
}

extension NewNotificationResultDTO {
    func toDomain() throws -> [NotificationItem] {
        try notifications.map { try $0.toDomain() }
    }
}

private extension NotificationItemDTO {
    func toDomain() throws -> NotificationItem {
        NotificationItem(
            id: id,
            type: NotificationType(apiValue: type),
            title: title,
            message: content,
            isActionable: targetId != nil,
            isRead: isRead,
            targetId: targetId,
            createdAt: try parseCreatedAt(createdAt)
        )
    }

    func parseCreatedAt(_ value: String) throws -> Date {
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: value) {
            return date
        }

        let localFormatter = DateFormatter()
        localFormatter.locale = Locale(identifier: "en_US_POSIX")
        localFormatter.calendar = Calendar(identifier: .gregorian)
        localFormatter.timeZone = .current
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        guard let date = localFormatter.date(from: value) else {
            throw NotificationDTOError.invalidDate(value)
        }

        return date
    }
}

enum NotificationDTOError: LocalizedError {
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "알림 응답의 날짜 형식이 올바르지 않습니다."
        }
    }
}
