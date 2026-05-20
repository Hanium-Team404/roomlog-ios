//
//  DefectAllListView.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import SwiftUI

struct DefectAllListView: View {
    @Environment(\.di) var di
    let roomId: Int
    let roomName: String
    let defects: [DefectReportDetail]

    @State private var sortOrder: SortOrder = .severityHigh

    enum SortOrder: String, CaseIterable {
        case severityHigh = "심각도 높은순"
        case severityLow = "심각도 낮은순"
    }

    private var sortedDefects: [DefectReportDetail] {
        defects.sorted { lhs, rhs in
            if lhs.severity.rank == rhs.severity.rank {
                return lhs.id < rhs.id
            }
            switch sortOrder {
            case .severityHigh:
                return lhs.severity.rank > rhs.severity.rank
            case .severityLow:
                return lhs.severity.rank < rhs.severity.rank
            }
        }
    }

    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("감지된 하자")
                        .font(.semibold, 20)
                        .foregroundStyle(Color.neutral800)
                    Spacer()
                    sortMenu
                }

                ForEach(sortedDefects, id: \.id) { defect in
                    DefectReportRow(defect: defect)
                        .onTapGesture {
                            pathStore.defectPath.append(
                                .defect(.defectListDetail(
                                    defect: defect,
                                    roomId: roomId,
                                    roomImageURL: nil
                                ))
                            )
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("\(roomName) 하자")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOrder.allCases, id: \.self) { order in
                Button {
                    sortOrder = order
                } label: {
                    HStack {
                        Text(order.rawValue)
                        if sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(sortOrder.rawValue)
                    .font(.medium, 14)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(Color.neutral700)
        }
    }
}

#Preview {
    NavigationStack {
        DefectAllListView(
            roomId: 1,
            roomName: "망고의 방",
            defects: PreviewSampleData.defects
        )
    }
    .environment(\.di, DIContainer.configured())
}
