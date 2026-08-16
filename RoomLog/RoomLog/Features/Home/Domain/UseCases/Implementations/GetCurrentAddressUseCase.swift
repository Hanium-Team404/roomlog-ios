//
//  GetCurrentAddressUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 8/16/26.
//

import Foundation

struct GetCurrentAddressUseCase: GetCurrentAddressUseCaseProtocol {

    private let provider: CurrentAddressProviderProtocol

    init(provider: CurrentAddressProviderProtocol) {
        self.provider = provider
    }

    func execute() -> AsyncStream<String> {
        provider.addressUpdates()
    }
}
