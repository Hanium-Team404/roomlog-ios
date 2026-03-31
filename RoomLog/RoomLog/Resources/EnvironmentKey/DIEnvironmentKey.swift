//
//  DIEnvironmentKey.swift
//  Projects
//
//  Created by 김도연 on 3/31/26.
//

import Foundation
import SwiftUI

struct DIEnvironmentKey: EnvironmentKey {
    static let defaultValue: DIContainer = .init()
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIEnvironmentKey.self] }
        set { self[DIEnvironmentKey.self] = newValue }
    }
}
