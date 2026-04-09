# CLAUDE.md

이 파일은 Claude Code(claude.ai/code)가 이 리포지토리의 코드를 작업할 때 참고할 가이드를 제공합니다.

## Project Overview

RoomLog는 iOS SwiftUI 앱입니다 (2026 동국대 정보통신공학과 캡스톤 디자인).
Xcode를 통해 빌드 및 실행하며, `RoomLog/RoomLog.xcodeproj` 파일을 열어 시작합니다.

## 폴더 구조

```
RoomLog/RoomLog/
├── App/                  — 엔트리 포인트 (RoomLogApp, ContentView)
├── Core/
│   ├── Config/           — Config.swift (Info.plist에서 BASE_URL 로드)
│   ├── Common/Extensions/— DateFormatter 등 공통 확장
│   ├── DIContainer/      — DIContainer, UsecaseProvider
│   ├── Error/            — RepositoryError
│   ├── Navigation/       — NavigationDestination, PathStore, NavigationRouter, NavigationRoutingView
│   └── NetworkAdapter/
│       ├── Base/         — BaseTargetType, APIResponse, EmptyResult
│       ├── NetworkClient/— NetworkClient(actor), TokenStore, TokenPair, DefaultAuthenticationPolicy
│       ├── TokenRefreshService/ — TokenRefreshServiceImpl, MoyaNetworkAdapter
│       └── Authdependencies.swift — AuthSystemFactory (NetworkClient 조립 팩토리)
├── Features/
│   ├── Home/
│   │   ├── Data/         — DTO, RoomTarget(Moya), HomeRepository
│   │   ├── Domain/
│   │   │   ├── Interfaces/   — HomeRepositoryProtocol
│   │   │   ├── Models/Home/  — HomeData, RoomDetail, UpdatedRoomDetail
│   │   │   └── UseCases/     — 각 UseCase 프로토콜 및 Implementations/
│   │   └── Presentation/     — (미구현, 추후 추가 예정)
│   └── Tab/
│       └── Presentation/ — RoomLogTab (3탭 루트 뷰)
├── Resources/
│   └── EnvironmentKey/   — DIEnvironmentKey.swift
└── Utilities/
    └── Keychain/         — KeychainTokenStore (actor)
```

## Architecture

Clean Architecture 패턴을 따르며, 기능(Feature) 기반 폴더 구조를 사용합니다.
각 Feature는 `Data/`, `Domain/`, `Presentation/` 레이어로 구분됩니다.

### Dependency Injection

`DIContainer` (`Core/DIContainer/`)는 `ObjectIdentifier`를 키로 사용하는 지연 생성 싱글톤 레지스트리입니다.
SwiftUI 환경 변수 `\.di`를 통해 전달됩니다 (`Resources/EnvironmentKey/DIEnvironmentKey.swift` 정의).
뷰에서는 `@Environment(\.di) var di`로 접근합니다.

새로운 의존성 등록은 `DIContainer.configured()`에 추가합니다.
`UsecaseProvider` 프로토콜과 `UseCaseProvider` 클래스는 모든 유즈케이스 팩토리를 그룹화합니다.

### Navigation

탭별 네비게이션은 `PathStore` (`Core/Navigation/PathStore.swift`)에서 관리합니다.
각 탭(`homePath`, `defectPath`, `mypagePath`)에 대해 별도의 `NavigationDestination` 배열을 가집니다.

- **NavigationDestination**: 라우팅 가능한 모든 화면을 정의한 Enum. 기능별(`auth`, `home`, `defect`, `myPage`) 네임스페이스로 구분. 새 화면 추가 시 여기에 케이스를 추가합니다.
- **NavigationRouter**: `NavigationRoutable`을 구현한 `@Observable` 클래스. `push`, `pop`, `popToRootView` 제공.
- **NavigationRoutingView**: `NavigationDestination`을 실제 SwiftUI 뷰로 변환하는 Switch문 기반 뷰.

### Tab Structure

`RoomLogTab` (`Features/Tab/Presentation/`)은 홈, 하자 및 비교, 마이페이지 3개 탭으로 구성된 루트 탭 뷰입니다.
`@Observable` 매크로 사용 (iOS 17+ 필요).

### Network Layer

Moya + 커스텀 `NetworkClient(actor)` 조합으로 구성됩니다.

- **BaseTargetType**: Moya `TargetType`을 확장. `baseURL`은 `Config.baseURL`에서 읽고, 공통 헤더(`Content-Type: application/json`)를 설정합니다.
- **APIResponse\<T\>**: 서버 공통 응답 래퍼. `unwrap()`으로 `isSuccess` 검사 후 결과 추출. 결과가 없는 경우 `EmptyResult` 사용.
- **NetworkClient**: `async actor`로 구현. 401 발생 시 토큰 자동 갱신 후 재시도. 동시에 여러 요청이 갱신을 요청해도 하나의 `Task`로 직렬화.
- **AuthSystemFactory**: `NetworkClient` 조립 팩토리. 기본 토큰 저장소로 `KeychainTokenStore` 사용.
- **KeychainTokenStore**: `actor` 기반. `accessToken`, `refreshToken`을 Keychain에 저장 (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- **MoyaNetworkAdapter**: Moya `Provider`를 `async/await`으로 래핑하는 어댑터.

#### 새로운 API 엔드포인트 추가 방법

1. `Features/[기능명]/Data/Target/`에 `TargetType` 파일 생성 (`BaseTargetType` 채택)
2. DTO 파일 생성 (`Features/[기능명]/Data/DTO/`)
3. Repository 구현 (`Features/[기능명]/Data/Repositories/`)
4. Domain 레이어에 Protocol 및 UseCase 추가

### Config

`Core/Config/Config.swift`: `Info.plist`의 `BASE_URL` 키에서 서버 기본 URL을 읽습니다. `xcconfig`로 환경별 값 주입이 가능합니다.

### Error Handling

`RepositoryError` (`Core/Error/RepositoryError.swift`): `serverError(code:message:)`와 `decodingError(detail:)` 두 케이스. `isRetryable` 프로퍼티로 재시도 여부 판단.

## Conventions

- 상태 및 라우터 클래스에는 `ObservableObject` 대신 **`@Observable`** 사용.
- 새로운 기능은 `Features/[기능명]/Presentation/`에 위치시키며, 필요에 따라 `Domain/`, `Data/` 레이어를 추가합니다.

### 새로운 화면 추가 절차

1. `NavigationDestination`에 케이스 추가
2. `NavigationRoutingView`의 `@ViewBuilder` 분기에 추가
3. 독자적인 스택이 필요한 경우 `PathStore`에 경로 배열 추가

### 현재 구현된 Home Feature UseCases

- `FetchHomeDataUseCase` — 홈 데이터(방 목록) 조회
- `FetchRoomDetailUseCase` — 방 상세 조회
- `UpdateRoomUseCase` — 방 정보 수정
- `PatchMainRoomUseCase` — 대표 방 변경
- `DeleteRoomUseCase` — 방 삭제
