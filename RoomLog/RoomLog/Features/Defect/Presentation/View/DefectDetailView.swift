//
//  DefectDetailView.swift
//  RoomLog
//
//  Created by 송민교 on 4/20/26.
//

import SwiftUI
import NukeUI

/// 하자 상세. 하자 id만 받아 직접 조회하므로 목록·챗봇·알림 등 어떤 진입점에서든 같은 목적지로 연다
struct DefectDetailView: View {
    @State private var viewModel: DefectDetailViewModel

    private let scrollsToSelfRepair: Bool
    private let provider: DefectUseCaseProvider

    init(defectId: Int, scrollsToSelfRepair: Bool = false, provider: DefectUseCaseProvider) {
        self.scrollsToSelfRepair = scrollsToSelfRepair
        self.provider = provider
        self._viewModel = .init(
            wrappedValue: DefectDetailViewModel(defectId: defectId, provider: provider)
        )
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                Content(detail: detail, scrollsToSelfRepair: scrollsToSelfRepair, provider: provider)
            } else if let message = viewModel.errorMessage {
                loadFailedView(message)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.fetch() }
    }

    private func loadFailedView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.medium, 15)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                Task { await viewModel.retry() }
            }
            .font(.semibold, 15)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Content

private extension DefectDetailView {
    /// 조회가 끝난 뒤의 본문. 하자·방 정보를 non-optional로 받아 카드 뷰들이 분기 없이 그린다
    struct Content: View {
        let detail: DefectDetail

        @State private var selfRepairViewModel: SelfRepairViewModel
        /// 챗봇에서 "자가 수리 안내" 링크로 들어오면 진입 후 자가 수리 카드로 내려간다
        @State private var scrollPosition = ScrollPosition()
        /// 콘텐츠 좌표계 기준 자가 수리 카드 상단 y. 위 카드들은 높이가 고정이라 가이드 로드 전후로 값이 바뀌지 않는다
        @State private var selfRepairCardTop: CGFloat = 0
        /// 진입 시 한 번만 내려간다. 추천 업체에서 돌아올 때 `.task`가 재실행돼도 읽던 위치를 유지하기 위함
        @State private var hasScrolledToSelfRepair = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        private let scrollsToSelfRepair: Bool

        private static let contentCoordinateSpace = "defectDetailContent"
        /// push 전환이 끝난 뒤 스크롤을 시작해야 이동이 보인다. 전환 중에 움직이면 두 애니메이션이 겹쳐 튀어 보인다
        private static let scrollDelay: Duration = .milliseconds(450)
        /// 스크롤 도착 시 자가 수리 카드 위에 남길 여백
        private static let selfRepairScrollInset: CGFloat = 24

        static let displayDateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy.MM.dd"
            f.locale = Locale(identifier: "ko_KR")
            return f
        }()

        init(detail: DefectDetail, scrollsToSelfRepair: Bool, provider: DefectUseCaseProvider) {
            self.detail = detail
            self.scrollsToSelfRepair = scrollsToSelfRepair
            self._selfRepairViewModel = .init(
                wrappedValue: SelfRepairViewModel(defectId: detail.defect.id, provider: provider)
            )
        }

        var defect: DefectReportDetail { detail.defect }

        /// 가이드 결과(또는 실패)가 레이아웃에 반영됐는지. 로딩 카드는 짧아서 그 전에 스크롤하면 콘텐츠 끝에 걸려 카드가 상단에 오지 못한다
        private var isSelfRepairResolved: Bool {
            selfRepairViewModel.guide != nil || selfRepairViewModel.loadFailed
        }

        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    roomImageView
                    summaryCard
                    detailCard
                    selfRepairCard
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.frame(in: .named(Self.contentCoordinateSpace)).minY
                        } action: { top in
                            selfRepairCardTop = top
                        }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .coordinateSpace(.named(Self.contentCoordinateSpace))
            }
            .scrollPosition($scrollPosition)
            .safeAreaInset(edge: .bottom) {
                bottomButton
            }
            .navigationTitle(defect.type.displayName)
            .task { await selfRepairViewModel.fetch() }
            .task(id: isSelfRepairResolved) { await scrollToSelfRepairIfNeeded() }
        }

        private func scrollToSelfRepairIfNeeded() async {
            guard scrollsToSelfRepair, isSelfRepairResolved, !hasScrolledToSelfRepair else { return }
            try? await Task.sleep(for: Self.scrollDelay)
            guard !Task.isCancelled else { return }
            hasScrolledToSelfRepair = true
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.5)) {
                scrollPosition.scrollTo(y: max(0, selfRepairCardTop - Self.selfRepairScrollInset))
            }
        }
    }
}

// MARK: - Room Image

private extension DefectDetailView.Content {
    var roomImageView: some View {
        Group {
            if let urlString = defect.imageURL ?? detail.roomImageURL,
               let url = URL(string: urlString) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fit)
                    } else if state.error != nil {
                        imagePlaceholder
                            .overlay {
                                Text("이미지를 불러올 수 없습니다")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var imagePlaceholder: some View {
        ImagePlaceholder(iconFont: .largeTitle)
    }
}

// MARK: - Summary Card

private extension DefectDetailView.Content {
    var summaryCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("심각도")
                    .font(.medium, 16)
                    .foregroundStyle(Color("dustyBlue"))
                SeverityBadge(severity: defect.severity, size: .medium)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 12) {
                Text("예상 수리비")
                    .font(.medium, 16)
                    .foregroundStyle(Color("dustyBlue"))
                Text(formattedRepairCost)
                    .font(.semibold, 24)
                    .foregroundStyle(Color("neutral700"))
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    var formattedRepairCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: defect.repairCost)) ?? "\(defect.repairCost)"
        return "₩ \(formatted)"
    }
}

// MARK: - Detail Card

private extension DefectDetailView.Content {
    var detailCard: some View {
        VStack(alignment: .leading, spacing: 42) {
            Text("하자 상세 정보")
                .font(.semibold, 20)
                .foregroundStyle(Color("neutral800"))

            infoRow(label: "위치", value: defect.location)
            areaRow
            if let date = defect.discoveredDate {
                infoRow(label: "발견일", value: Self.displayDateFormatter.string(from: date))
            }
            memoSection
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.medium, 16)
                .foregroundStyle(.primary)
                .frame(width: 52, alignment: .leading)
            Spacer()
            Text(value)
                .font(.medium, 16)
                .foregroundStyle(Color("blueGray500"))
                .multilineTextAlignment(.trailing)
        }
    }

    var areaRow: some View {
        HStack {
            Text("면적")
                .font(.medium, 16)
                .foregroundStyle(.primary)
                .frame(width: 52, alignment: .leading)
            Spacer()
            Text(String(format: "%.2f cm²", defect.defectArea))
                .font(.medium, 16)
                .foregroundStyle(Color("blueGray500"))
        }
    }

    var memoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("추가사항")
                .font(.medium, 16)
                .foregroundStyle(.primary)
            Text(defect.memo?.isEmpty == false ? defect.memo! : defect.description)
                .font(.medium, 16)
                .foregroundStyle(Color("blueGray500"))
        }
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Self Repair Card

private extension DefectDetailView.Content {
    var selfRepairCard: some View {
        SelfRepairCard(
            guide: selfRepairViewModel.guide,
            isLoading: selfRepairViewModel.isLoading,
            loadFailed: selfRepairViewModel.loadFailed
        ) {
            Task { await selfRepairViewModel.retry() }
        }
    }
}

// MARK: - Bottom Button

private extension DefectDetailView.Content {
    /// 값 기반 링크라 이 화면이 홈·뷰어 어느 탭 스택에 있든 같은 스택에 쌓인다 (챗봇 경유 진입 대응)
    var bottomButton: some View {
        BottomCTALink(value: .defect(.repairShopList(roomId: detail.roomId, defect: defect))) {
            Text("추천 업체 보기")
                .font(.semibold, 17)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DefectDetailView(
            defectId: 2,
            scrollsToSelfRepair: true,
            provider: DefectUseCaseProviderImpl(defectRepository: MockDefectRepository())
        )
    }
    .environment(\.di, DIContainer.configured())
}
#endif
