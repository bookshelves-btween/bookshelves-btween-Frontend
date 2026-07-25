//
//  NotificationService.swift
//  BookBetween
//

import Foundation
import Moya

protocol NotificationServiceProtocol {
    func registerFCMToken(_ token: String) async throws
    func fetchNotifications(page: Int, size: Int) async throws -> NotificationPage
    func fetchNewNotifications(afterId: Int) async throws -> [NotificationItem]
    func markAsRead(notificationId: Int) async throws -> Int
}

final class NotificationService: NotificationServiceProtocol {
    private let baseURL: URL
    private let provider: MoyaProvider<NotificationTarget>

    init(configuration: NetworkConfiguration) {
        self.baseURL = configuration.baseURL
        self.provider = MoyaProvider<NotificationTarget>(
            plugins: [
                AuthorizationPlugin(accessToken: configuration.accessToken)
            ]
        )
    }

    init(
        baseURL: URL,
        provider: MoyaProvider<NotificationTarget>
    ) {
        self.baseURL = baseURL
        self.provider = provider
    }

    static func stubbed() -> NotificationService {
        let baseURL = URL(string: "https://stub.bookbetween.local")!
        let provider = MoyaProvider<NotificationTarget>(
            stubClosure: { _ in .immediate }
        )
        return NotificationService(baseURL: baseURL, provider: provider)
    }

    func registerFCMToken(_ token: String) async throws {
        do {
            let response = try await provider.requestAsync(
                NotificationTarget(
                    baseURL: baseURL,
                    endpoint: .registerFCMToken(token)
                )
            )
            try response.validateAPIResponse()
        } catch let error as MoyaError {
            throw NetworkError.transport(error)
        }
    }

    func fetchNotifications(
        page: Int = 1,
        size: Int = 20
    ) async throws -> NotificationPage {
        do {
            let response = try await provider.requestAsync(
                NotificationTarget(
                    baseURL: baseURL,
                    endpoint: .fetchNotifications(page: page, size: size)
                )
            )
            return try response
                .decodePayload(NotificationListResultDTO.self)
                .toDomain()
        } catch let error as MoyaError {
            throw NetworkError.transport(error)
        }
    }

    func fetchNewNotifications(
        afterId: Int
    ) async throws -> [NotificationItem] {
        do {
            let response = try await provider.requestAsync(
                NotificationTarget(
                    baseURL: baseURL,
                    endpoint: .fetchNewNotifications(afterId: afterId)
                )
            )
            return try response
                .decodePayload(NewNotificationResultDTO.self)
                .toDomain()
        } catch let error as MoyaError {
            throw NetworkError.transport(error)
        }
    }

    func markAsRead(notificationId: Int) async throws -> Int {
        do {
            let response = try await provider.requestAsync(
                NotificationTarget(
                    baseURL: baseURL,
                    endpoint: .markAsRead(notificationId: notificationId)
                )
            )
            return try response
                .decodePayload(ReadNotificationResultDTO.self)
                .id
        } catch let error as MoyaError {
            throw NetworkError.transport(error)
        }
    }
}
