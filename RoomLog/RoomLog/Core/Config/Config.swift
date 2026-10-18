//
//  Config.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

nonisolated enum Config {
    private static func infoValue(_ key: String) -> String? {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist cannot be found")
        }
        return dict[key] as? String
    }

    static let baseURL: String = {
        guard let baseURL = infoValue("BASE_URL") else {
            fatalError("BaseURL not found")
        }
        return baseURL
    }()

    static let kakaoNativeAppKey: String = {
        guard let raw = infoValue("KAKAO_NATIVE_APP_KEY") else {
            fatalError("KAKAO_NATIVE_APP_KEY not found")
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.hasPrefix("${") else {
            fatalError("KAKAO_NATIVE_APP_KEY is empty or unresolved")
        }
        return key
    }()
}
