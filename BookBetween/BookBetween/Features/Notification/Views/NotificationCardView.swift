//
//  NotificationCardView.swift
//  BookBetween
//

import SwiftUI

struct NotificationCardView: View {
    let item: NotificationItem

    var body: some View {
        HStack(spacing: 12) {
            notificationIcon

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .body1SemiBoldStyle
                    .foregroundStyle(.gray800)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.message)
                    .caption1RegularStyle
                    .foregroundStyle(.gray500)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if item.isActionable {
                Image("icon_chevron_right_gray")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 7, height: 14)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 88)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray200, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }

    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 4)

            Image(iconImageName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize.width, height: iconSize.height)
        }
        .frame(width: 50, height: 50)
    }

    private var iconImageName: String {
        switch item.type {
        case .meetingCancelled:
            return "icon_exclamation_mark"
        case .aiSummaryReady:
            return "icon_check_mark"
        case .meetingStarted:
            return "icon_alert_mark"
        case .system:
            return "icon_alert_mark"
        }
    }

    private var iconSize: CGSize {
        switch item.type {
        case .meetingCancelled:
            return CGSize(width: 26, height: 26)
        case .aiSummaryReady:
            return CGSize(width: 28, height: 23)
        case .meetingStarted:
            return CGSize(width: 25, height: 27)
        case .system:
            return CGSize(width: 25, height: 27)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        NotificationCardView(
            item: NotificationItem(
                id: 1,
                type: .meetingCancelled,
                title: "최소 인원 미달로 모임이 취소되었어요",
                message: "혼모노 | 7/15 (수) · 18:30 | 2/6",
                isActionable: false
            )
        )

        NotificationCardView(
            item: NotificationItem(
                id: 2,
                type: .aiSummaryReady,
                title: "AI 요약이 완료되었어요",
                message: "지금 확인해보세요",
                isActionable: true
            )
        )
    }
    .padding(20)
    .background(.gray50)
}
