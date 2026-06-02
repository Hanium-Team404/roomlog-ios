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
        // MARK: - Token Store
        container.register(TokenStore.self) {
            KeychainTokenStore()
        }

        // MARK: - Network
        container.register(NetworkClient.self) {
            AuthSystemFactory.makeNetworkClient(
                baseURL: URL(string: Config.baseURL)!,
                tokenStore: container.resolve(TokenStore.self)
            )
        }

        container.register(MoyaNetworkAdapter.self) {
            MoyaNetworkAdapter(
                networkClient: container.resolve(NetworkClient.self),
                baseURL: URL(string: Config.baseURL)!
            )
        }

        // MARK: - Auth Repository
        container.register(AuthRepositoryProtocol.self) {
            AuthRepository(adapter: container.resolve(MoyaNetworkAdapter.self))
        }

        // MARK: - UseCase Providers
        container.register(AuthUseCaseProvider.self) {
            AuthUseCaseProviderImpl(
                repositoryProvider: container.resolve(AuthRepositoryProtocol.self),
                tokenStore: container.resolve(TokenStore.self)
            )
        }

        container.register(HomeUseCaseProvider.self) {
            HomeUseCaseProviderImpl(adapter: container.resolve(MoyaNetworkAdapter.self))
        }

        container.register(MyPageUseCaseProvider.self) {
            MyPageUseCaseProviderImpl(adapter: container.resolve(MoyaNetworkAdapter.self))
        }
        
        container.register(DefectUseCaseProvider.self) {
            DefectUseCaseProviderImpl(defectRepository: container.resolve(DefectRepositoryProtocol.self))
        }

        container.register(EstimateUseCaseProvider.self) {
            EstimateUseCaseProviderImpl(adapter: container.resolve(MoyaNetworkAdapter.self))
        }

        container.register(ScanRepositoryProtocol.self) {
            ScanRepository(adapter: container.resolve(MoyaNetworkAdapter.self))
        }

        container.register(ComparisonUseCaseProvider.self) {
            ComparisonUseCaseProviderImpl(repository: container.resolve(ComparisonRepositoryProtocol.self))
        }

        // MARK: - Repository
        container.register(DefectRepositoryProtocol.self) {
            DefectRepository(adapter: container.resolve(MoyaNetworkAdapter.self))
        }
        
        // TODO: 서버 연동 시 ComparisonRepository(adapter:)로 교체
        container.register(ComparisonRepositoryProtocol.self) {
            MockComparisonRepository()
        }

        // MARK: - Scan Processing
        container.register(ScanProcessingManager.self) {
            let manager = ScanProcessingManager()
            manager.configure(scanRepository: container.resolve(ScanRepositoryProtocol.self))
            return manager
        }

        // MARK: - Shared State
        container.register(HomeState.self) {
            HomeState()
        }

        // MARK: - Navigation
        container.register(PathStore.self) {
            PathStore()
        }
        
        container.register(NavigationRouter.self) {
            NavigationRouter()
        }

        return container
    }
}

