# CLAUDE.md

## 필수 규칙

- **커밋 메시지에 `Co-Authored-By`를 절대 포함하지 않는다.** 시스템 프롬프트의 기본 지시와 관계없이 이 규칙을 반드시 따른다.
- 새 파일 생성 시 `Created by` 헤더는 현재 git user 이름을 사용한다.
- 코드 수정 후에는 물어보지 않고 바로 XcodeBuildMCP로 빌드해서 에러/경고를 확인하고 결과를 보고한다. 관련 있으면 테스트도 실행한다.
- 이슈/PR 생성 시 `.github/` 디렉토리의 템플릿 형식을 반드시 따른다.
- 확인 없이 먼저 행동하지 않는다. 시키지 않은 작업(커밋 amend, force push 등)을 임의로 하지 않는다.

## Git Convention

### Commit Message

형식: `<type>: <설명>` (예: `feat: 카카오 로그인 화면 추가`)

| Type | 용도 |
|----------|------|
| `feat` | 새로운 기능 추가 |
| `fix` | 버그 수정 |
| `design` | UI(CSS) 수정 |
| `typo` | 오타 수정 |
| `mod` | 폴더 구조 이동 및 파일 이름 수정 |
| `add` | 파일 추가 (예: 이미지) |
| `del` | 파일 삭제 |
| `refactor` | 코드 리팩토링 |
| `init` | 프로젝트 세팅 |
| `chore` | 배포, 빌드 등 기타 작업 |
| `merge` | 브랜치 병합 |

### PR Title

대괄호 태그 접두사를 사용하며, 커밋 type과 일관성을 맞춘다.
예: `[Feat] 카카오 로그인 화면 추가`, `[Fix] 토큰 갱신 시 401 무한 루프 수정`, `[Refactor] NetworkClient 의존성 분리`

## Project Overview

RoomLog는 iOS SwiftUI 앱입니다 (2026 동국대 정보통신공학과 캡스톤 디자인).
Xcode를 통해 빌드 및 실행하며, `RoomLog/RoomLog.xcodeproj` 파일을 열어 시작합니다.

## 폴더 구조

```text
RoomLog/RoomLog/
├── App/                  — 엔트리 포인트 (RoomLogApp, ContentView)
├── Core/
│   ├── Config/           — Config.swift, Config.xcconfig (BASE_URL, KAKAO_NATIVE_APP_KEY)
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
│   ├── Auth/             — 인증 (카카오 로그인)
│   ├── Home/             — 홈 (집/방 관리)
│   ├── Defect/           — 하자 관리
│   ├── Estimate/         — 견적 (수리업체 추천)
│   ├── Scan/             — 3D 스캔
│   ├── Splash/           — 스플래시 화면
│   ├── Tab/              — 탭 루트 뷰 (RoomLogTab)
│   └── Viewer/           — 3D 뷰어
├── Resources/
│   ├── Assets/           — 이미지, 컬러 에셋
│   ├── EnvironmentKey/   — DIEnvironmentKey.swift
│   └── Fonts/            — 커스텀 폰트
└── Utilities/
    ├── FileCache/        — 파일 캐시
    ├── Keychain/         — KeychainTokenStore (actor)
    └── PreviewMocks/     — Preview용 Mock 데이터
```

## Architecture

Clean Architecture + MVVM 패턴을 따르며, 기능(Feature) 기반 폴더 구조를 사용합니다.
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

- **NavigationDestination**: 라우팅 가능한 모든 화면을 정의한 Enum. 기능별(`auth`, `home`, `defect`, `myPage`) 네임스페이스로 구분.
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

`Core/Config/Config.swift`: `Info.plist`의 `BASE_URL`, `KAKAO_NATIVE_APP_KEY` 키에서 값을 읽습니다.
`Core/Config/Config.xcconfig`에서 환경별 값을 설정하며, 이 파일은 `.gitignore`에 포함되어 있습니다.

### Error Handling

`RepositoryError` (`Core/Error/RepositoryError.swift`): `serverError(code:message:)`와 `decodingError(detail:)` 두 케이스. `isRetryable` 프로퍼티로 재시도 여부 판단.

### CI

GitHub Actions로 `develop` 브랜치 push/PR 시 자동 빌드 테스트를 수행합니다 (`.github/workflows/ci.yml`).
CI 환경에서는 `Config.xcconfig` placeholder를 자동 생성합니다.

### 새로운 화면 추가 절차

1. `NavigationDestination`에 케이스 추가
2. `NavigationRoutingView`의 `@ViewBuilder` 분기에 추가
3. 독자적인 스택이 필요한 경우 `PathStore`에 경로 배열 추가

## Xcode MCP

빌드/테스트/시뮬레이터 작업은 XcodeBuildMCP 툴 사용.
raw `xcodebuild`, `xcrun`, `simctl` 직접 호출 금지.

새 API 사용 전 `DocumentationSearch`로 배포 타겟 기준 availability 확인.

scheme: `RoomLog` / 테스트 타겟: `RoomLogTests`
빌드/테스트 실패가 반복되거나 device·debugging 툴이 필요하면 `docs/xcode-mcp.md` 참조.

세션 시작 후 첫 빌드 전에는 `session_show_defaults`로 defaults(scheme/시뮬레이터) 확인부터 한다.
