//
//  Config.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

enum Config {
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist cannot be found")
        }
        return dict
    }()
    
    static let baseURL: String = {
        guard let baseURL = Config.infoDictionary["BASE_URL"] as? String else {
            fatalError("BaseURL not found")
        }
        return baseURL
    }()

    static let kakaoNativeAppKey: String = {
        guard let raw = Config.infoDictionary["KAKAO_NATIVE_APP_KEY"] as? String else {
            fatalError("KAKAO_NATIVE_APP_KEY not found")
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.hasPrefix("${") else {
            fatalError("KAKAO_NATIVE_APP_KEY is empty or unresolved")
        }
        return key
    }()
}
