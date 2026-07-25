//
//  NotificationInboxView.swift
//  BookBetween
//

import SwiftUI

@MainActor
struct NotificationInboxView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NotificationInboxViewModel

    init() {
        _viewModel = State(
            initialValue: NotificationInboxViewModel(
                service: NotificationService.stubbed()
            )
        )
    }

    init(viewModel: NotificationInboxViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea()
                .overlay(alignment: .bottomLeading) {
                    bottomLeadingGradient
                }

            VStack(spacing: 0) {
                navigationHeader

                if viewModel.isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }

            leafDecoration
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                ProgressView()
            }
        }
        .task {
            await viewModel.start()
        }
        .alert(
            "알림을 불러오지 못했습니다.",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var navigationHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image("icon_arrow_left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            Text("알림함")
                .head1Style
                .foregroundStyle(.gray900)

            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.notifications) { notification in
                    Button {
                        Task {
                            await viewModel.markAsRead(notification)
                        }
                    } label: {
                        NotificationCardView(item: notification)
                    }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.loadNextPageIfNeeded(
                            currentItem: notification
                        )
                    }
                }

                if viewModel.isLoadingNextPage {
                    ProgressView()
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.gray400)

            Text("새로운 알림이 없어요")
                .body1SemiBoldStyle
                .foregroundStyle(.gray600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var leafDecoration: some View {
        Image("notification_leaf_right")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 136)
            .opacity(0.55)
            .offset(x: 16, y: 30)
            .allowsHitTesting(false)
    }

    private var bottomLeadingGradient: some View {
        RadialGradient(
            stops: [
                .init(
                    color: Color(hex: "DCEBE1").opacity(0.4),
                    location: 0.3
                ),
                .init(
                    color: Color(hex: "DCEBE1").opacity(0),
                    location: 0.7
                )
            ],
            center: .center,
            startRadius: 0,
            endRadius: 281
        )
        .frame(width: 562, height: 454)
        .offset(x: -175, y: 209)
        .allowsHitTesting(false)
    }
}

#Preview("알림 목록") {
    NotificationInboxView()
}

#Preview("빈 알림함") {
    NotificationInboxView(
        viewModel: NotificationInboxViewModel(notifications: [])
    )
}
