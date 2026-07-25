//
//  NotificationTarget.swift
//  BookBetween
//

import Foundation
import Alamofire
import Moya

struct NotificationTarget: TargetType {
    enum Endpoint {
        case registerFCMToken(String)
        case fetchNotifications(page: Int, size: Int)
        case fetchNewNotifications(afterId: Int)
        case markAsRead(notificationId: Int)
    }

    let baseURL: URL
    let endpoint: Endpoint

    var path: String {
        switch endpoint {
        case .registerFCMToken:
            return "/api/v1/notifications/fcm/tokens"
        case .fetchNotifications:
            return "/api/v1/notifications"
        case .fetchNewNotifications:
            return "/api/v1/notifications/new"
        case .markAsRead(let notificationId):
            return "/api/v1/notifications/\(notificationId)/read"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .registerFCMToken:
            return .post
        case .fetchNotifications, .fetchNewNotifications:
            return .get
        case .markAsRead:
            return .patch
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .registerFCMToken(let token):
            return .requestParameters(
                parameters: ["fcmToken": token],
                encoding: JSONEncoding.default
            )
        case let .fetchNotifications(page, size):
            return .requestParameters(
                parameters: [
                    "page": page,
                    "size": size
                ],
                encoding: URLEncoding.queryString
            )
        case .fetchNewNotifications(let afterId):
            return .requestParameters(
                parameters: ["afterId": afterId],
                encoding: URLEncoding.queryString
            )
        case .markAsRead:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
    }

    var sampleData: Data {
        NotificationStubData.data(for: endpoint)
    }
}
