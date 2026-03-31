//
//  DIContainer.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import Foundation

@Observable
final class DIContainer {
    // MARK: - Storage
    
    @ObservationIgnored
    private var factories: [ObjectIdentifier: Any] = [:]
    @ObservationIgnored
    private var cachedInstances: [ObjectIdentifier: Any] = [:]
    
    // MARK: - Registration

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        factories[key] = factory
    }
    
    // MARK: - Resolution

    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        if let cached = cachedInstances[key] as? T {
            return cached
        }
        guard let factory = factories[key] as? () -> T else {
            fatalError("DIContainer Error: No Factory registered for type '\(T.self)'.")
        }
        let instance = factory()
        cachedInstances[key] = instance
        return instance
    }
    
    // MARK: - Cache Management
    
    func resetCache() {
        cachedInstances.removeAll()
    }
    
    func resetCache<T>(for type: T.Type) {
        let key = ObjectIdentifier(type)
        cachedInstances.removeValue(forKey: key)
    }
}

// MARK: - 앱 의존성 구성
extension DIContainer {
    static func configured() -> DIContainer {
        let container = DIContainer()
        container.register(UseCaseProvider.self) { UseCaseProvider() }
        
        return container
    }
}
