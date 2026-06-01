//
//  MyPageViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import XCTest
@testable import RoomLog

@MainActor
final class MyPageViewModelTests: XCTestCase {

    private var provider: MockMyPageUseCaseProvider!
    private var sut: MyPageViewModel!

    override func setUp() {
        super.setUp()
        provider = MockMyPageUseCaseProvider()
        sut = MyPageViewModel(provider: provider)
    }

    // MARK: - fetchUser

    func test_fetchUser_성공시_user가_설정된다() async {
        let user = User(id: 1, nickname: "도연", email: "dy@test.com", createdAt: Date())
        provider.getUserResult = .success(user)

        await sut.fetchUser()

        XCTAssertEqual(sut.user?.nickname, "도연")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_fetchUser_실패시_에러상태가_된다() async {
        provider.getUserResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "네트워크 오류"]))

        await sut.fetchUser()

        XCTAssertNil(sut.user)
        XCTAssertEqual(sut.errorMessage, "네트워크 오류")
        XCTAssertTrue(sut.showError)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - updateNickname

    func test_updateNickname_성공시_user가_갱신된다() async {
        let updatedUser = User(id: 1, nickname: "새닉네임", email: "dy@test.com", createdAt: Date())
        provider.updateUserResult = .success(())
        provider.getUserResult = .success(updatedUser)
        sut.editingNickname = "새닉네임"

        await sut.updateNickname()

        XCTAssertEqual(sut.user?.nickname, "새닉네임")
        XCTAssertTrue(sut.editingNickname.isEmpty)
    }

    func test_updateNickname_공백이면_실행하지_않는다() async {
        sut.editingNickname = "   "

        await sut.updateNickname()

        XCTAssertNil(sut.user)
    }

    func test_updateNickname_실패시_에러상태가_된다() async {
        provider.updateUserResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "수정 실패"]))
        sut.editingNickname = "새닉네임"

        await sut.updateNickname()

        XCTAssertEqual(sut.errorMessage, "수정 실패")
        XCTAssertTrue(sut.showError)
    }

    // MARK: - deleteAccount

    func test_deleteAccount_성공시_true를_반환한다() async {
        provider.deleteUserResult = .success(())

        let result = await sut.deleteAccount()

        XCTAssertTrue(result)
    }

    func test_deleteAccount_실패시_false를_반환하고_에러상태가_된다() async {
        provider.deleteUserResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "삭제 실패"]))

        let result = await sut.deleteAccount()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "삭제 실패")
        XCTAssertTrue(sut.showError)
    }
}
