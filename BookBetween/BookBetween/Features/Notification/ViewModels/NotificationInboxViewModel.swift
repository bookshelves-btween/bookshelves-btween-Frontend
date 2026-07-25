//
//  NotificationInboxViewModel.swift
//  BookBetween
//

import Foundation
import Observation

@Observable
@MainActor
final class NotificationInboxViewModel {
    private(set) var notifications: [NotificationItem] = []
    private(set) var isLoading = false
    private(set) var isLoadingNextPage = false
    var errorMessage: String?

    private let service: any NotificationServiceProtocol
    private let pageSize: Int
    private let pollingIntervalNanoseconds: UInt64
    private let automaticallyLoads: Bool
    private var currentPage = 0
    private var hasNext = false
    private var hasLoaded = false
    private var isPolling = false
    private var readingNotificationIds: Set<Int> = []

    var isEmpty: Bool {
        notifications.isEmpty
    }

    init(
        service: any NotificationServiceProtocol,
        pageSize: Int = 20,
        pollingIntervalNanoseconds: UInt64 = 30_000_000_000
    ) {
        self.service = service
        self.pageSize = pageSize
        self.pollingIntervalNanoseconds = pollingIntervalNanoseconds
        self.automaticallyLoads = true
    }

    init(notifications: [NotificationItem]) {
        self.notifications = notifications
        self.service = NotificationService.stubbed()
        self.pageSize = 20
        self.pollingIntervalNanoseconds = 30_000_000_000
        self.automaticallyLoads = false
    }

    func start() async {
        guard automaticallyLoads else { return }

        await loadNotifications()
        await pollForNewNotifications()
    }

    func loadNotifications() async {
        guard !hasLoaded, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await service.fetchNotifications(
                page: 1,
                size: pageSize
            )
            notifications = result.notifications
            currentPage = result.page
            hasNext = result.hasNext
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNextPageIfNeeded(currentItem: NotificationItem) async {
        guard
            currentItem.id == notifications.last?.id,
            hasNext,
            !isLoading,
            !isLoadingNextPage
        else { return }

        isLoadingNextPage = true
        errorMessage = nil
        defer { isLoadingNextPage = false }

        do {
            let result = try await service.fetchNotifications(
                page: currentPage + 1,
                size: pageSize
            )
            appendUnique(result.notifications)
            currentPage = result.page
            hasNext = result.hasNext
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAsRead(_ notification: NotificationItem) async {
        guard
            !notification.isRead,
            !readingNotificationIds.contains(notification.id)
        else { return }

        readingNotificationIds.insert(notification.id)
        defer { readingNotificationIds.remove(notification.id) }

        do {
            let notificationId = try await service.markAsRead(
                notificationId: notification.id
            )

            guard let index = notifications.firstIndex(
                where: { $0.id == notificationId }
            ) else { return }

            notifications[index] = notifications[index].markingAsRead()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pollForNewNotifications() async {
        guard !isPolling else { return }

        isPolling = true
        defer { isPolling = false }

        while !Task.isCancelled {
            do {
                try await Task.sleep(
                    nanoseconds: pollingIntervalNanoseconds
                )
            } catch {
                return
            }

            await fetchNewNotifications()
        }
    }

    private func fetchNewNotifications() async {
        guard let latestNotificationId = notifications.map(\.id).max() else {
            return
        }

        do {
            let newNotifications = try await service.fetchNewNotifications(
                afterId: latestNotificationId
            )
            prependUnique(newNotifications)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func appendUnique(_ newNotifications: [NotificationItem]) {
        let existingIds = Set(notifications.map(\.id))
        notifications.append(
            contentsOf: newNotifications.filter {
                !existingIds.contains($0.id)
            }
        )
    }

    private func prependUnique(_ newNotifications: [NotificationItem]) {
        let existingIds = Set(notifications.map(\.id))
        let uniqueNotifications = newNotifications.filter {
            !existingIds.contains($0.id)
        }

        notifications.insert(contentsOf: uniqueNotifications, at: 0)
        notifications.sort {
            if $0.createdAt == $1.createdAt {
                return $0.id > $1.id
            }
            return $0.createdAt > $1.createdAt
        }
    }
}
