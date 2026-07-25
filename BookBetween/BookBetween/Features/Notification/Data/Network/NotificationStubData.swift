//
//  NotificationStubData.swift
//  BookBetween
//

import Foundation

enum NotificationStubData {
    static func data(for endpoint: NotificationTarget.Endpoint) -> Data {
        let json: String

        switch endpoint {
        case .registerFCMToken:
            json = registerFCMTokenResponse
        case let .fetchNotifications(page, size):
            json = notificationListResponse(page: page, size: size)
        case .fetchNewNotifications(let afterId):
            json = newNotificationResponse(afterId: afterId)
        case .markAsRead(let notificationId):
            json = markAsReadResponse(notificationId: notificationId)
        }

        return Data(json.utf8)
    }

    private static let registerFCMTokenResponse = """
    {
      "isSuccess": true,
      "code": "NOTI200",
      "message": "FCM 토큰이 등록되었습니다.",
      "result": null
    }
    """

    private static func notificationListResponse(
        page: Int,
        size: Int
    ) -> String {
        let notifications: String

        if page == 1 {
            notifications = """
            [
              {
                "id": 103,
                "type": "MEETING_CANCELLED",
                "title": "최소 인원 미달로 모임이 취소되었어요",
                "content": "혼모노 | 7/15 (수) · 18:30 | 2/6",
                "isRead": false,
                "targetId": null,
                "createdAt": "2026-07-14T21:00:00"
              },
              {
                "id": 102,
                "type": "MEETING_SUMMARY_DONE",
                "title": "AI 요약이 완료되었어요",
                "content": "지금 확인해보세요",
                "isRead": false,
                "targetId": 15,
                "createdAt": "2026-07-14T20:10:00"
              },
              {
                "id": 101,
                "type": "MEETING_STARTED",
                "title": "혼모노 독서 모임이 시작되었어요",
                "content": "지금 모임에 참여해보세요",
                "isRead": false,
                "targetId": 12,
                "createdAt": "2026-07-14T20:00:00"
              }
            ]
            """
        } else {
            notifications = "[]"
        }

        return """
        {
          "isSuccess": true,
          "code": "NOTI200",
          "message": "알림 목록 조회에 성공했습니다.",
          "result": {
            "notifications": \(notifications),
            "page": \(page),
            "size": \(size),
            "hasNext": false
          }
        }
        """
    }

    private static func newNotificationResponse(afterId: Int) -> String {
        let notifications = afterId < 126
            ? """
              [
                {
                  "id": 126,
                  "type": "MEETING_SUMMARY_DONE",
                  "title": "새 AI 요약이 완료되었어요",
                  "content": "방금 생성된 요약을 확인해보세요",
                  "isRead": false,
                  "targetId": 21,
                  "createdAt": "2026-07-14T22:10:00"
                }
              ]
              """
            : "[]"

        return """
        {
          "isSuccess": true,
          "code": "NOTI200",
          "message": "새 알림 조회에 성공했습니다.",
          "result": {
            "notifications": \(notifications)
          }
        }
        """
    }

    private static func markAsReadResponse(notificationId: Int) -> String {
        """
        {
          "isSuccess": true,
          "code": "NOTI200",
          "message": "알림을 읽음 처리했습니다.",
          "result": {
            "id": \(notificationId)
          }
        }
        """
    }
}
