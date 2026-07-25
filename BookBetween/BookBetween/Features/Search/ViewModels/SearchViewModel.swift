//
//  SearchViewModel.swift
//  BookBetween
//
//  Created by 이준성 on 7/8/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class SearchViewModel {
    var searchText: String = ""
    private(set) var recentKeywords: [String] = []
    private(set) var searchResults: [BookSearchItem] = []
    private(set) var isSearching = false
    private(set) var isLoadingNextPage = false
    private(set) var hasSearched = false
    var errorMessage: String?

    private let service: any BookServiceProtocol
    private let pageSize: Int
    private var currentPage = 0
    private var hasNext = false
    private var submittedQuery = ""

    init(
        service: any BookServiceProtocol,
        pageSize: Int = 15
    ) {
        self.service = service
        self.pageSize = pageSize
    }

    func loadRecentSearches() async {
        do {
            recentKeywords = try await service.fetchRecentSearches().map(\.keyword)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitSearch() async {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            resetSearch()
            return
        }
        guard !isSearching else { return }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            let result = try await service.searchBooks(
                query: keyword,
                page: 1,
                size: pageSize
            )

            searchResults = result.books
            currentPage = result.page
            hasNext = result.hasNext
            submittedQuery = keyword
            hasSearched = true

            recentKeywords.removeAll { $0 == keyword }
            recentKeywords.insert(keyword, at: 0)
            recentKeywords = Array(recentKeywords.prefix(5))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNextPageIfNeeded(currentItem: BookSearchItem) async {
        guard
            currentItem.listID == searchResults.last?.listID,
            hasNext,
            !isSearching,
            !isLoadingNextPage,
            !submittedQuery.isEmpty
        else { return }

        isLoadingNextPage = true
        errorMessage = nil
        defer { isLoadingNextPage = false }

        do {
            let result = try await service.searchBooks(
                query: submittedQuery,
                page: currentPage + 1,
                size: pageSize
            )

            searchResults.append(contentsOf: result.books)
            currentPage = result.page
            hasNext = result.hasNext
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectRecentKeyword(_ keyword: String) {
        searchText = keyword
    }

    func removeRecentKeyword(_ keyword: String) {
        recentKeywords.removeAll { $0 == keyword }
    }

    private func resetSearch() {
        searchText = ""
        searchResults = []
        currentPage = 0
        hasNext = false
        submittedQuery = ""
        hasSearched = false
        errorMessage = nil
    }
}
