//
//  SearchView.swift
//  BookBetween
//
//  Created by 이준성 on 6/25/26.
//

import SwiftUI

@MainActor
struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @FocusState private var isSearchFocused: Bool

    init() {
        _viewModel = State(
            initialValue: SearchViewModel(service: BookService.stubbed())
        )
    }

    init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    TitleView
                    SearchInputSectionView
                    SearchResultSectionView(
                        idleHeight: max(geometry.size.height - 145, 520)
                    )
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture {
                    isSearchFocused = false
                }
                .padding(.horizontal, 19)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task {
            await viewModel.loadRecentSearches()
        }
        .alert(
            "도서 정보를 불러오지 못했습니다.",
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
    
    // MARK: 도서검색 TITLE
    private var TitleView: some View {
        HStack {
            Text("도서 검색")
                .head2Style
                .foregroundStyle(Color.gray900)
            Spacer()
        }
        .padding(.leading, 11) // 11 + 19 = 30
    }
    
    // MARK: - 검색 바
    private var SearchInputSectionView: some View {
        VStack(spacing: 0) {
            SearchBarView

            if isSearchFocused && !viewModel.recentKeywords.isEmpty {
                Divider()
                    .background(.gray200)
                    .padding(.horizontal, 20)
                RecentSearchListView
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray200, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }
    
    private var SearchBarView: some View {
        HStack(spacing: 10) {
            Image(.iconMagnifyingglass)
                .foregroundStyle(Color.gray600)

            TextField("검색어를 입력하세요", text: $viewModel.searchText)
                .font(.body1Regular)
                .foregroundStyle(Color.gray800)
                .focused($isSearchFocused)
                .onSubmit {
                    isSearchFocused = false
                    Task {
                        await viewModel.submitSearch()
                    }
                }
        }
        .frame(height: 46)
        .padding(.horizontal, 11)
    }
    
    private var RecentSearchListView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("최근 검색 도서")
                .body2SemiBoldStyle
                .foregroundStyle(Color.gray600)
                .padding(.top, 11)

            VStack(spacing: 7) {
                ForEach(viewModel.recentKeywords, id: \.self) { keyword in
                    RecentKeywordRow(
                        keyword: keyword,
                        onSelect: {
                            viewModel.selectRecentKeyword(keyword)
                            isSearchFocused = false
                            Task {
                                await viewModel.submitSearch()
                            }
                        },
                        onDelete: {
                            viewModel.removeRecentKeyword(keyword)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 13)
    }
    
    private func SearchResultSectionView(idleHeight: CGFloat) -> some View {
        VStack(spacing: 12) {
            if viewModel.isSearching {
                ProgressView()
                    .padding(.top, 24)
            } else if !viewModel.hasSearched {
                SearchIdleView(height: idleHeight)
            } else if viewModel.hasSearched && viewModel.searchResults.isEmpty {
                Text("검색 결과가 없어요")
                    .body2RegularStyle
                    .foregroundStyle(.gray500)
                    .padding(.top, 24)
            } else {
                ForEach(viewModel.searchResults, id: \.listID) { item in
                    SearchBookResultCardView(item: item)
                        .task {
                            await viewModel.loadNextPageIfNeeded(currentItem: item)
                        }
                }
            }

            if viewModel.isLoadingNextPage {
                ProgressView()
                    .padding(.vertical, 12)
            }
        }
    }

    private func SearchIdleView(height: CGFloat) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack {
                RadialGradient(
                    colors: [
                        Color(hex: "DCEBE1").opacity(0.58),
                        Color.white.opacity(0)
                    ],
                    center: UnitPoint(x: 0.5, y: 0.48),
                    startRadius: 12,
                    endRadius: 270
                )

                Image("leaf_left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 108)
                    .position(x: 30, y: height * 0.13)

                Image("leaf_right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 108)
                    .position(x: width - 30, y: height * 0.22)

                Image("search_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 152, height: 134)
                    .position(x: width / 2, y: height * 0.46)

                VStack(spacing: 10) {
                    Text("원하는 책을 찾아보세요")
                        .pointText4Style
                        .foregroundStyle(Color.green900)

                    Text("책 제목, 저자, 키워드로\n쉽고 빠르게 검색할 수 있어요")
                        .body2RegularStyle
                        .foregroundStyle(Color.gray600)
                        .multilineTextAlignment(.center)
                }
                .position(x: width / 2, y: height * 0.67)
            }
            .allowsHitTesting(false)
        }
        .frame(height: height)
    }
}

private struct RecentKeywordRow: View {
    let keyword: String
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                Text(keyword)
                    .body2RegularStyle
                    .foregroundStyle(Color.gray600)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.gray500)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 18)
    }
}

#Preview {
    SearchView()
}
