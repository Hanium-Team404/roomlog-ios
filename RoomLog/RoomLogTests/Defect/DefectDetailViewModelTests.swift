//
//  DefectDetailViewModelTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/11/26.
//

import Testing
import Foundation
@testable import RoomLog

/// 하자 id 단건 조회 → 상세 화면 상태(성공·실패 문구·중복 호출 방지·재시도) 매핑을 검사한다
@MainActor
struct DefectDetailViewModelTests {

    private let provider = MockDefectUseCaseProvider()
    private let sut: DefectDetailViewModel

    init() {
        sut = DefectDetailViewModel(defectId: 1, provider: provider)
    }

    @Test func 조회_성공시_detail이_설정된다() async throws {
        await sut.fetch()

        let detail = try #require(sut.detail)
        #expect(detail.defect.id == 1)
        #expect(detail.roomId == 5)
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test func 서버_에러시_에러코드_문구가_노출된다() async {
        provider.getDefectDetailResult = .failure(
            RepositoryError.serverError(code: 404, message: "없음", errorCode: .defectNotFound)
        )

        await sut.fetch()

        #expect(sut.detail == nil)
        #expect(sut.errorMessage == ServerErrorCode.defectNotFound.userMessage)
    }

    @Test func 이미_조회됐으면_다시_호출하지_않는다() async {
        await sut.fetch()
        await sut.fetch()

        #expect(provider.getDefectDetailCallCount == 1)
    }

    @Test func 실패_후_재시도에_성공하면_detail이_설정되고_에러가_지워진다() async throws {
        provider.getDefectDetailResult = .failure(NSError(domain: "test", code: -1))
        await sut.fetch()
        try #require(sut.errorMessage != nil)

        provider.getDefectDetailResult = MockDefectUseCaseProvider().getDefectDetailResult
        await sut.retry()

        #expect(sut.detail != nil)
        #expect(sut.errorMessage == nil)
    }
}
