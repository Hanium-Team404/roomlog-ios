//
//  SelfRepairCard.swift
//  RoomLog
//
//  Created by wk1717 on 8/26/26.
//

import SwiftUI
import NukeUI

/// 하자 상세 화면 하단의 "자가 수리 가능 여부" 카드.
struct SelfRepairCard: View {
    let guide: SelfRepairGuide?
    let isLoading: Bool
    let loadFailed: Bool
    let onRetry: () -> Void

    @Environment(\.openURL) private var openURL

    private static let possibleColor = Color(red: 0.16, green: 0.62, blue: 0.35)
    private static let impossibleColor = Color(red: 0.89, green: 0.21, blue: 0.22)

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("자가 수리 가능 여부")
                .font(.semibold, 20)
                .foregroundStyle(Color("neutral800"))

            if let guide {
                contentSection(guide)
            } else if loadFailed {
                failureSection
            } else {
                loadingSection
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }
}

// MARK: - States

private extension SelfRepairCard {
    var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("AI가 자가 수리 가능 여부를 확인하는 중이에요")
                .font(.medium, 14)
                .foregroundStyle(Color("blueGray400"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    var failureSection: some View {
        VStack(spacing: 12) {
            Text("자가 수리 안내를 불러오지 못했어요")
                .font(.medium, 14)
                .foregroundStyle(Color("blueGray400"))
            Button(action: onRetry) {
                Text("다시 시도")
                    .font(.semibold, 14)
                    .foregroundStyle(Color("dustyBlue"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Color("dustyBlue").opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    func contentSection(_ guide: SelfRepairGuide) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            possibilityRow(isPossible: guide.isPossible)

            sectionRow(label: "하자 설명") {
                Text(guide.description)
                    .font(.medium, 16)
                    .foregroundStyle(Color("blueGray500"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if guide.isPossible {
                if !guide.videos.isEmpty {
                    sectionRow(label: "자가 수리 예시 영상") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(guide.videos, id: \.self) { video in
                                videoRow(video)
                            }
                        }
                    }
                }

                if !guide.items.isEmpty {
                    sectionRow(label: "구매 필요 목록") {
                        purchaseItemsSection(guide.items)
                    }
                }

                sectionRow(label: "전체 예상 비용 (최저가 기준)") {
                    Text(formattedCost(guide.totalCost))
                        .font(.semibold, 20)
                        .foregroundStyle(Color("neutral700"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    func possibilityRow(isPossible: Bool) -> some View {
        HStack(alignment: .center) {
            Text("가능 여부")
                .font(.medium, 16)
                .foregroundStyle(.primary)
            Spacer()
            let color = isPossible ? Self.possibleColor : Self.impossibleColor
            Text(isPossible ? "가능" : "불가능")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    /// 제목을 위, 내용을 아래에 두는 세로 구성. 값이 길거나 리스트라 좌우 2단보다 읽기 편하다.
    func sectionRow<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.medium, 16)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Videos

private extension SelfRepairCard {
    func videoRow(_ video: SelfRepairVideo) -> some View {
        Button {
            guard let url = URL(string: video.urlString) else { return }
            openURL(url)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                videoThumbnail(video)
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.medium, 14)
                        .foregroundStyle(Color("neutral700"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(video.channel)
                        .font(.regular, 12)
                        .foregroundStyle(Color("blueGray400"))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    func videoThumbnail(_ video: SelfRepairVideo) -> some View {
        Group {
            if let urlString = video.thumbnailURLString, let url = URL(string: urlString) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        ImagePlaceholder()
                    }
                }
            } else {
                ImagePlaceholder()
            }
        }
        .frame(width: 80, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Purchase Items

private extension SelfRepairCard {
    func purchaseItemsSection(_ items: [SelfRepairItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    itemThumbnail(item)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.medium, 14)
                            .foregroundStyle(Color("neutral700"))
                            .multilineTextAlignment(.leading)
                        Text(formattedCost(item.price))
                            .font(.regular, 12)
                            .foregroundStyle(Color("blueGray500"))
                        storeLinkButton(item)
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// image_url이 항상 null로 내려와 자리만 잡아 둔다. 에셋이 준비되면 여기서 교체한다.
    func itemThumbnail(_ item: SelfRepairItem) -> some View {
        Group {
            if let urlString = item.imageURLString, let url = URL(string: urlString) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        ImagePlaceholder()
                    }
                }
            } else {
                ImagePlaceholder()
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    func storeLinkButton(_ item: SelfRepairItem) -> some View {
        Button {
            guard let url = URL(string: item.urlString) else { return }
            openURL(url)
        } label: {
            Text(storeName(for: item.urlString))
                .font(.medium, 12)
                .foregroundStyle(Color("dustyBlue"))
                .underline()
        }
        .buttonStyle(.plain)
    }

    /// 링크 도메인으로 쇼핑몰을 판별한다. 모르는 도메인이면 중립 문구로 떨어진다.
    func storeName(for urlString: String) -> String {
        let host = URL(string: urlString)?.host?.lowercased() ?? ""
        if host.contains("coupang") { return "쿠팡 링크" }
        if host.contains("gmarket") { return "G마켓 링크" }
        return "구매하러 가기"
    }
}

// MARK: - Helpers

private extension SelfRepairCard {
    func formattedCost(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩ \(formatted)"
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Previews

#Preview("로딩") {
    SelfRepairCard(guide: nil, isLoading: true, loadFailed: false, onRetry: {})
        .padding(16)
        .background(Color("white200"))
}

#Preview("실패") {
    SelfRepairCard(guide: nil, isLoading: false, loadFailed: true, onRetry: {})
        .padding(16)
        .background(Color("white200"))
}

#Preview("불가능") {
    SelfRepairCard(
        guide: SelfRepairGuide(
            defectId: 1,
            isPossible: false,
            description: "해당 하자는 구조체를 관통하는 균열로, 안전상 위험이 있어 스스로 수리 불가",
            videos: [],
            items: [],
            totalCost: 0
        ),
        isLoading: false,
        loadFailed: false,
        onRetry: {}
    )
    .padding(16)
    .background(Color("white200"))
}

#Preview("가능") {
    ScrollView {
        SelfRepairCard(
            guide: SelfRepairGuide(
                defectId: 2,
                isPossible: true,
                description: "해당 하자는 벽지가 들뜬 하자로, 도배 풀과 벽지만 있으면 스스로 수리 가능",
                videos: [
                    SelfRepairVideo(
                        title: "욕실 타일 깨짐 보수하는 방법! 이제 셀프로 해결하세요.",
                        urlString: "https://www.youtube.com/watch?v=L4Ro4hKoAvs",
                        channel: "이것도 꽉Fix",
                        thumbnailURLString: "https://i.ytimg.com/vi/L4Ro4hKoAvs/mqdefault.jpg"
                    )
                ],
                items: [
                    SelfRepairItem(name: "곰팡이 제거제", price: 8_900, urlString: "https://www.coupang.com", imageURLString: nil),
                    SelfRepairItem(name: "욕실용 실리콘", price: 11_100, urlString: "https://www.gmarket.co.kr", imageURLString: nil)
                ],
                totalCost: 20_000
            ),
            isLoading: false,
            loadFailed: false,
            onRetry: {}
        )
        .padding(16)
    }
    .background(Color("white200"))
}
