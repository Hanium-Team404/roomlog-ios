//
//  DateFormatter.swift
//  RoomLog
//
//  Created by 김도연 on 4/9/26.
//

import Foundation

extension Date {
    // MARK: - Static Formatters (서버 파싱 전용)

    /// "yyyy-MM-dd" 형식 파싱용
    private static let serverDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

    /// "yyyy-MM-dd'T'HH:mm:ss" 형식 파싱용
    private static let serverDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

    // MARK: - Date → String (UI 표시용, FormatStyle)

    /// 서버 전송용 날짜 문자열로 변환 (yyyy-MM-dd)
    func toServerDateString() -> String {
        Date.serverDateFormatter.string(from: self)
    }

    /// "2026년 3월 1일" 형식 (앱 UI 표시용)
    func toDisplayString() -> String {
        self.formatted(.dateTime
            .year()
            .month()
            .day()
            .locale(Locale(identifier: "ko_KR"))
        )
    }

    // MARK: - String → Date (서버 파싱용)

    /// "yyyy-MM-dd" 형식 문자열을 Date로 변환
    static func fromServerDate(_ string: String) -> Date? {
        serverDateFormatter.date(from: string)
    }

    /// "yyyy-MM-dd'T'HH:mm:ss" 형식 문자열을 Date로 변환
    static func fromServerDateTime(_ string: String) -> Date? {
        serverDateTimeFormatter.date(from: string)
    }
}
