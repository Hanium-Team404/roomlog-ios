//
//  DefectAttachmentChip.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI
import NukeUI

/// 선택한 하자를 첨부 형태로 표시하는 칩. onRemove가 nil이면 삭제 버튼을 숨긴다 (말풍선 첨부 표시용).
struct DefectAttachmentChip: View {
    let defect: ChatSelectableDefect
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
                .frame(width: 36, height: 36)
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(defect.type.displayName)
                    .font(.semibold, 13)
                    .foregroundStyle(Color.neutral800)
                Text(locationText)
                    .font(.medium, 12)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(.systemGray3))
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .accessibilityLabel("첨부 제거")
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, onRemove == nil ? 8 : 0)
        .padding(.vertical, onRemove == nil ? 8 : 4)
        .background(Color(.systemGray6).opacity(0.8), in: .rect(cornerRadius: 14))
    }

    private var locationText: String {
        defect.roomName.isEmpty ? defect.location : "\(defect.roomName) · \(defect.location)"
    }

    private var thumbnail: some View {
        Group {
            if let urlString = defect.imageURL, let url = URL(string: urlString) {
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
    }
}

#Preview {
    DefectAttachmentChip(
        defect: ChatSelectableDefect(id: 1, type: .peeling, severity: .low, location: "벽면 북서부", roomName: "거실", imageURL: nil)
    ) {}
        .padding(16)
}
