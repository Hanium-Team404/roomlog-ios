//
//  Font.swift
//  RoomLog
//
//  Created by 송민교 on 4/27/26.
//

import SwiftUI
import UIKit

extension Font {
    enum Pretend {
        case bold
        case semibold
        case medium
        case regular

        var value: String {
            switch self {
            case .bold:     return "Pretendard-Bold"
            case .semibold: return "Pretendard-SemiBold"
            case .medium:   return "Pretendard-Medium"
            case .regular:  return "Pretendard-Regular"
            }
        }

        static func lineHeight(for size: Int) -> CGFloat {
            switch size {
            case 36: return 44
            case 30: return 38
            case 24: return 32
            case 20: return 30
            case 18: return 28
            case 16: return 24
            case 14: return 20
            case 12: return 18
            default: return CGFloat(size) * 1.5
            }
        }
    }
}

extension View {
    func font(_ weight: Font.Pretend, _ size: Int) -> some View {
        modifier(PretendardModifier(weight: weight, size: size))
    }
}

private struct PretendardModifier: ViewModifier {
    let weight: Font.Pretend
    let size: Int

    func body(content: Content) -> some View {
        let fontSize = CGFloat(size)
        let targetLineHeight = Font.Pretend.lineHeight(for: size)
        let uiFont = UIFont(name: weight.value, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        let lineSpacing = max(0, targetLineHeight - uiFont.lineHeight)

        content
            .font(.custom(weight.value, size: fontSize))
            .lineSpacing(lineSpacing)
            .padding(.vertical, lineSpacing / 2)
    }
}
