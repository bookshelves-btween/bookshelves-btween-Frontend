//
//  BookRecordDetailView.swift
//  BookBetween
//
//  Created by 이준성 on 7/11/26.
//

import SwiftUI

struct BookRecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: BookRecordDetailViewModel
    @FocusState private var isReviewFocused: Bool  // 키보드 내리기
    
    init(record: UserBookRecord, isSaveable: Bool = true) {
        _viewModel = State(initialValue: BookRecordDetailViewModel(record: record, isSaveable: isSaveable))
    }

    init(book: Book, isSaveable: Bool = true) {
        self.init(
            record: UserBookRecord(
                book: book,
                progress: 0,
                rating: nil,
                memo: nil
            ),
            isSaveable: isSaveable
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    bookHeader
                    bookDescription
                    readingRecordForm
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isReviewFocused = false
        }
        .background(alignment: .topTrailing) {
            Image("leaf_img2")
                .resizable()
                .scaledToFit()
                .frame(width: 147, height: 133)
                .opacity(0.75)
                //.offset(y: 10)
                .allowsHitTesting(false)
            }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 책정보, 수정하기
    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image("icon_arrow_left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            Text("책 정보")
                .head2Style
                .foregroundStyle(.gray900)

            Spacer()

            Button {
                viewModel.startEditing()
            } label: {
                HStack(spacing: 6) {
                    Image("icon_pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Text("수정하기")
                        .body1SemiBoldStyle
                        .foregroundStyle(.gray800)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isEditing || !viewModel.isSaveable)
            .opacity(viewModel.isEditing || !viewModel.isSaveable ? 0 : 1)
        }
    }

    // MARK: - 책 이미지, 제목
    private var bookHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            BookCoverImage(book: viewModel.book, placeholderImageName: "book_cover_0")
                .scaledToFill()
                .frame(width: 105.4, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(.gray200, lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.book.title)
                    .head2Style
                    .foregroundStyle(.gray800)
                    .lineLimit(1)

                Text(viewModel.book.author)
                    .body1RegularStyle
                    .foregroundStyle(.gray500)

                if let kdcName = viewModel.book.kdcName {
                    Text(kdcName)
                        .body2SemiBoldStyle
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.green600)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 16)
    }


    // MARK: - 글 설명
    private var bookDescription: some View {
        Text(viewModel.book.description ?? "")
            .caption1RegularStyle
            .foregroundStyle(.gray700)
            .lineSpacing(4)
            .lineLimit(4)
            .padding(.top, 25)
    }

    // MARK: - 독서 진행률, 평점, 한줄평, 저장하기
    private var readingRecordForm: some View {
        VStack(spacing: 0) {
            progressCard
            ratingCard
            reviewCard
            saveButton
        }
        .padding(.top, 44)
    }

    private var progressCard: some View {
        recordCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("독서 진행률")
                    .body1SemiBoldStyle
                    .foregroundStyle(.gray800)

                BookProgressView(progress: $viewModel.progress, isEditable: viewModel.isEditing)
                    .frame(width: 288)
                    .padding(.top, 8)
            }
        }
    }

    private let starSize: CGFloat = 20
    private let starSpacing: CGFloat = 4
    private var starsRowWidth: CGFloat { starSize * 5 + starSpacing * 4 }

    private var ratingCard: some View {
        recordCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("평점")
                    .body1SemiBoldStyle
                    .foregroundStyle(.gray800)

                GeometryReader { geo in
                    HStack(spacing: starSpacing) {
                        ForEach(1...5, id: \.self) { score in
                            Image(starImageName(for: score))
                                .resizable()
                                .scaledToFit()
                                .frame(width: starSize, height: starSize)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard viewModel.isEditing else { return }
                                updateRating(dragX: value.location.x, fullWidth: geo.size.width)
                            }
                    )
                }
                .frame(width: starsRowWidth, height: starSize)
                .padding(.top, 3)
            }
        }
        .padding(.top, 5)
    }

    private func starImageName(for score: Int) -> String {
        let threshold = Double(score)
        if viewModel.rating >= threshold {
            return "icon_star_fill"
        } else if viewModel.rating >= threshold - 0.5 {
            return "icon_star_half"
        } else {
            return "icon_star_empty"
        }
    }

    private func updateRating(dragX: CGFloat, fullWidth: CGFloat) {
        guard fullWidth > 0 else { return }
        let ratio = min(max(dragX / fullWidth, 0), 1)
        let steppedScore = (ratio * 5 * 2).rounded() / 2
        viewModel.updateRating(steppedScore)
    }

    private var reviewCard: some View {
        recordCard (borderColor: viewModel.isEditing ? .green500 : .gray200,
                    borderWidth: viewModel.isEditing ? 1.5 : 0.5
        
        ){
            VStack(alignment: .leading, spacing: 5) {
                Text("한줄평")
                    .body1SemiBoldStyle
                    .foregroundStyle(.gray800)

                if viewModel.isEditing {
                    ZStack(alignment: .topLeading) {
                        if viewModel.memo.isEmpty {
                            Text("이 책에 대한 짧은 감상을 남겨주세요.")
                                .caption1RegularStyle
                                .foregroundStyle(.gray800)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $viewModel.memo)
                            .font(.caption1Regular)
                            .foregroundStyle(.gray800)
                            .frame(minHeight: 76)
                            .scrollContentBackground(.hidden)
                            .focused($isReviewFocused)  // 키보드 내리기
                            .padding(.leading, -5)// UIKit의 기본 padding 제거
                            .padding(.top, -8)
                    }
                } else {
                    Text(viewModel.reviewPlaceholderText)
                        .caption1RegularStyle
                        .foregroundStyle(viewModel.hasReview ? .gray700 : .gray500)
                        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
                }
            }
            .background (alignment: .bottomTrailing){
                Image("leaf_img1")
                    .resizable()
                    .scaledToFit()
                    .frame(width:82, height: 109)
                    .opacity(0.55)
                    .allowsHitTesting(false) // 배경 이미지가 TextEditor의 터치를 가로채지 않도록.
                    .offset(x: 18, y: 16) // padding 만큼 밀어냄
            }
        }
        .padding(.top, 12)
    }

    private var saveButton: some View {
        Button {
            viewModel.saveRecord()
        } label: {
            Text("기록 저장하기")
                .body1SemiBoldStyle
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.green600)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isEditing)
        .opacity(viewModel.isEditing ? 1 : 0)
        .padding(.top, 45.82)
    }

    private func recordCard<Content: View>(
        borderColor: Color = .gray200,
        borderWidth: CGFloat = 0.5,
        @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
    }
}

#Preview {
    NavigationStack {
        BookRecordDetailView(
            record: UserBookRecord(
                book: Book(
                    id: 1,
                    title: "랑과 나의 사막",
                    author: "천선란",
                    description: "성해나 작가의 단편 소설집 혼모노는 진짜와 가짜, 믿음에 대한 날카로운 질문을 던지는 작품입니다.\n표제작 혼모노는 신발을 잃고 20대 애기 무당에게 자리를 빼앗긴 베테랑 무당이 진정한 자신의 정체성을 찾아가는 과정을 그립니다.",
                    kdcName: "한국문학"
                ),
                progress: 0,
                rating: nil,
                memo: nil
            )
        )
    }
}
