//
//  DefectDetailView.swift
//  RoomLog
//
//  Created by 송민교 on 4/20/26.
//

import SwiftUI
import NukeUI

struct DefectDetailView: View {
    let defect: DefectReportDetail
    let roomId: Int
    let roomImageURL: String?

    @Environment(\.di) var di

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                roomImageView
                summaryCard
                detailCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            bottomButton
        }
        .navigationTitle(defect.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Room Image

private extension DefectDetailView {
    var roomImageView: some View {
        Group {
            if let urlString = defect.imageURL ?? roomImageURL,
               let url = URL(string: urlString) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill)
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

private extension DefectDetailView {
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

private extension DefectDetailView {
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
            Text(String(format: "%.2f m²", defect.defectArea))
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

// MARK: - Bottom Button

private extension DefectDetailView {
    var bottomButton: some View {
        BottomCTAButton {
            let pathStore = di.resolve(PathStore.self)
            pathStore.defectPath.append(.defect(.repairShopList(roomId: roomId, defect: defect)))
        } label: {
            Text("추천 업체 보기")
                .font(.semibold, 17)
        }
    }
}

#Preview {
    NavigationStack {
        DefectDetailView(defect: PreviewSampleData.defects[0], roomId: 1, roomImageURL: nil)
    }
    .environment(\.di, DIContainer.configured())
}

