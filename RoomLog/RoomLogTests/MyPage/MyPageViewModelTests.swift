//
//  MyPageViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
import Testing
@testable import RoomLog

@MainActor
struct MyPageViewModelTests {

    private let provider: MockMyPageUseCaseProvider
    private let sut: MyPageViewModel

    init() {
        provider = MockMyPageUseCaseProvider()
        sut = MyPageViewModel(provider: provider)
    }

    // MARK: - fetchUser

    @Test
    func fetchUser_성공시_user가_설정된다() async {
        let user = User(id: 1, nickname: "도연", email: "dy@test.com", createdAt: Date())
        provider.getUserResult = .success(user)

        await sut.fetchUser()

        #expect(sut.user?.nickname == "도연")
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test
    func fetchUser_실패시_에러상태가_된다() async {
        provider.getUserResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "네트워크 오류"]))

        await sut.fetchUser()

        #expect(sut.user == nil)
        #expect(sut.errorMessage == "네트워크 오류")
        #expect(sut.showError)
        #expect(sut.isLoading == false)
    }

    // MARK: - updateNickname

    @Test
    func updateNickname_성공시_user가_갱신된다() async {
        let updatedUser = User(id: 1, nickname: "새닉네임", email: "dy@test.com", createdAt: Date())
        provider.updateUserResult = .success(())
        provider.getUserResult = .success(updatedUser)
        sut.editingNickname = "새닉네임"

        await sut.updateNickname()

        #expect(sut.user?.nickname == "새닉네임")
        #expect(sut.editingNickname.isEmpty)
    }

    @Test
    func updateNickname_공백이면_실행하지_않는다() async {
        sut.editingNickname = "   "

        await sut.updateNickname()

        #expect(sut.user == nil)
        #expect(provider.updateUserCallCount == 0, "공백 입력 시 API를 호출하지 않아야 합니다")
    }

    @Test
    func updateNickname_실패시_에러상태가_된다() async {
        provider.updateUserResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "수정 실패"]))
        sut.editingNickname = "새닉네임"

        await sut.updateNickname()

        #expect(sut.errorMessage == "수정 실패")
        #expect(sut.showError)
    }

    // MARK: - deleteAccount

    @Test
    func deleteAccount_성공시_true를_반환한다() async {
        provider.deleteUserResult = .success(())

        let result = await sut.deleteAccount()

        #expect(result)
    }

    @Test
    func deleteAccount_실패시_false를_반환하고_에러상태가_된다() async {
        provider.deleteUserResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "삭제 실패"]))

        let result = await sut.deleteAccount()

        #expect(result == false)
        #expect(sut.errorMessage == "삭제 실패")
        #expect(sut.showError)
    }
}
