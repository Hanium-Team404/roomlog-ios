# RoomLog

> 자취/원룸 거주자를 위한 **3D 방 기록 & 하자 관리 iOS 앱**
> 2026 한이음 드림업 프로젝트 (Team 404)

LiDAR 기반 3D 스캔으로 입주 시점의 방을 기록하고, 퇴거 시 동일 공간을 다시 스캔해 변경된 영역과 하자를 자동으로 비교·관리하는 iOS 앱입니다.
## 👥 Team

| <a href="https://github.com/ddodle"><img src="https://github.com/ddodle.png" width="120" /></a> | <a href="https://github.com/wk1717"><img src="https://github.com/wk1717.png" width="120" /></a> |
|:---:|:---:|
| **김도연** | **송민교** |
| iOS | iOS |
| Auth · Home · Scan · MyPage<br/>Core (NetworkClient · TokenStore · DIContainer · CI) | Viewer · Defect · Comparison · Estimate |
| [@ddodle](https://github.com/ddodle) | [@wk1717](https://github.com/wk1717) |

## ✨ 주요 기능

| 기능 | 설명 |
|------|------|
| **인증 (Auth)** | 이메일/비밀번호 기반 회원가입·로그인. Access/Refresh 토큰은 Keychain에 안전하게 저장하고, 401 응답 시 자동으로 갱신·재요청합니다. |
| **홈 (Home)** | 등록한 집을 자체 **isometric 캔버스**에 시각화. 줌(0.7×~2.0×)·팬·자동 가장자리 스크롤을 지원하며, matchedGeometry 기반 zoom 트랜지션으로 방 목록으로 진입합니다. |
| **3D 스캔 (Scan)** | LiDAR(ARKit)로 방 내부를 녹화하고, **Depth / Confidence / IMU / Odometry / Video** 5채널 데이터를 동시 인코딩·ZIP 패키징해 서버로 업로드합니다. |
| **3D 뷰어 (Viewer)** | 서버에서 처리된 PLY 포인트클라우드를 불러와 방 내부를 3D로 둘러봅니다. PLY는 로컬에 캐시되어 재진입 시 즉시 표시됩니다. |
| **하자 점검 (Defect)** | 스캔 결과에서 추출된 하자 위치를 3D 공간에 태그로 표시. 하자를 탭하면 카메라가 해당 위치로 부드럽게 이동합니다. |
| **내방비교 (Comparison)** | 입주 전 / 퇴거 후 스캔을 비교해 변경된 영역과 하자 차이를 시각화. 두 시점의 PLY를 토글하며 비교할 수 있습니다. |
| **수리 견적 (Estimate)** | 백엔드가 추천한 주변 수리업체를 **KakaoMapsSDK** 지도에 POI로 표시하고, SMS로 견적 문의를 전송합니다. |

## 📸 Screenshots

<table>
  <tr>
    <td align="center"><b>로그인</b></td>
    <td align="center"><b>홈 (Isometric 캔버스)</b></td>
    <td align="center"><b>3D 스캔 (LiDAR)</b></td>
  </tr>
  <tr>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 31 48" src="https://github.com/user-attachments/assets/69c27545-90bb-4c4b-ba9b-562bfefced70" />
</td>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 32 00" src="https://github.com/user-attachments/assets/b9bb06cf-d0ac-4851-a180-a825199da931" />
</td>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 32 11" src="https://github.com/user-attachments/assets/e0230548-253f-422e-955c-9d2c7b61b5a3" />
</td>
  </tr>
  <tr>
    <td align="center"><b>3D 뷰어 (PLY)</b></td>
    <td align="center"><b>하자 점검</b></td>
    <td align="center"><b>하자 상세</b></td>
  </tr>
  <tr>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 32 25" src="https://github.com/user-attachments/assets/92141419-c81b-4b1c-a88d-071dd88acd5e" />

</td>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 32 38" src="https://github.com/user-attachments/assets/0968232b-69a0-4c6e-bd61-c0869fd773e9" />
</td>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 32 46" src="https://github.com/user-attachments/assets/23075a73-6987-4c3b-ba2b-aefd2755498e" />

</td>
  </tr>
  <tr>
    <td align="center"><b>방 목록</b></td>
    <td align="center"><b>비교 내역</b></td>
    <td align="center"><b>수리업체 (KakaoMap)</b></td>
  </tr>
  <tr>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 33 08" src="https://github.com/user-attachments/assets/ec78e27b-ecd5-4385-a2d4-3785155937cb" />

</td>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 33 23" src="https://github.com/user-attachments/assets/6c80cacc-5952-476e-ad67-4f01f15ea2f8" />
</td>
    <td><img width="240" height="512" alt="스크린샷 2026-06-18 17 33 38" src="https://github.com/user-attachments/assets/d14099e8-ad0e-49fc-b688-6343f53da2b8" />
</td>
  </tr>
</table>

## 🚀 사용 기술

### 1. Swift Concurrency 기반 동시성 안전한 인증 파이프라인

- **`NetworkClient` (actor)** — 401 발생 시 토큰을 자동 갱신·재요청. **동시에 여러 요청이 갱신을 트리거해도 단일 `Task<TokenPair, Error>`로 직렬화**하여 중복 갱신과 race condition을 차단합니다.
- **`KeychainTokenStore` (actor)** — Access/Refresh 토큰을 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`로 Keychain에 저장. 동시 접근에도 안전합니다.
- **`AuthenticationPolicy` 추상화** — 요청별 인증 필요 여부와 401 판단 로직을 정책 객체로 분리해 테스트 가능성을 확보했습니다.

### 2. 백그라운드 안전·재개 가능한 멀티스테이지 스캔 파이프라인

`ScanProcessingManager`는 `압축 → 업로드 → 상태 폴링 → 프리뷰 다운로드`의 4단계를 단일 `Task`로 오케스트레이션하며, 다음 시나리오까지 모두 다룹니다.

- **앱 재시작 복구** — 진행 단계를 `ScanArtifactStore`가 Codable 단일 레코드(`uploadReady` / `polling`)로 기록해 업로드 성공 시 전환이 원자적입니다. 폴링 기록은 재폴링으로, 업로드 미완 기록은 재시도 가능한 실패 상태로 복원됩니다.
- **zip 영속화** — zip은 Application Support의 영속 디렉터리에 두고(백업 제외) 기록에는 파일명만 저장해 컨테이너 경로가 바뀌어도 복원됩니다. 기록에 없는 zip·데이터셋은 재실행 시 고아 청소로 정리합니다.
- **백그라운드 연장** — 촬영 완료·업로드 재시도로 시작한 처리는 `BGContinuedProcessingTask`로 프리뷰 완료까지 앱이 suspend되지 않게 하고, 진행률과 단계 문구를 Live Activity에 표시합니다(서버 처리 중에는 진행률을 알 수 없어 폴링 시도 예산을 쓴 만큼 40~95%로 표시). 단계 문구는 상태 시트와 같은 정의를 공유합니다. 유저가 중지하거나 시스템이 연장을 끝내도 스캔은 취소하지 않고 "스캔 일시 중지"로 표시하며, suspend로 멈춘 처리는 복귀 시 이어집니다. 처리가 끝나면 앱 사용 중이든 내려가 있든 로컬 알림으로 완료를 알리고, 알림을 누르면 해당 집의 방 목록으로 이동해 스캔 상태 시트를 엽니다.
- **실패 지점별 재시도** — `RetrySource`(upload / polling / download)를 실패 페이로드에 담아 실패한 단계부터 재시도합니다. `.failed` 기록과 재시도 불가 시 폐기를 디스패처 한 곳에서 처리해 재시도 가능성과 재시작 복구 가능성이 항상 일치합니다.
- **Cross-house 격리** — 기록과 활성 스캔이 `houseId`를 함께 들고 있어 다른 집의 스캔과 섞이지 않습니다.
- **고정 간격 폴링** — 7초 간격 최대 60회, 연속 에러 3회면 실패로 전이. 폴링 타임아웃은 서버 스캔을 지우지 않고 재폴링 가능한 실패로 남깁니다.
- **취소 안전성** — 단계마다 `checkCancellation`으로 늦게 도착한 응답을 무시합니다.

### 3. ARKit 멀티 채널 스캔 데이터 인코딩

`DatasetEncoder`는 한 번의 녹화 세션에서 5종류의 시계열 데이터를 동기화하여 기록합니다.
인코더 구현은 [Stray Scanner](https://github.com/strayrobots/scanner)(MIT License)를 기반으로 이식했습니다.

| 채널 | 데이터 | 인코더 |
|------|--------|--------|
| RGB Video | `ARFrame.capturedImage` | `VideoEncoder` (H.264) |
| Depth | `ARFrame.sceneDepth.depthMap` | `DepthEncoder` |
| Confidence | `ARFrame.sceneDepth.confidenceMap` | `ConfidenceEncoder` |
| Odometry | `ARFrame.camera.transform` | `OdometryEncoder` |
| IMU | `CMMotionManager` 가속도·자이로 | `IMUEncoder` |

`NSLock` 기반 IMU 동기화, `frameInterval`로 FPS 다운샘플링을 지원하며, 최종 산출물은 `ZIPFoundation`으로 압축되어 서버에 전송됩니다.

### 4. iOS 17+ Observation 매크로와 SwiftUI Environment 기반 DI

- 모든 ViewModel과 공유 상태(`HomeState`, `ScanProcessingManager`)에 **`@Observable` 매크로** 적용
- `DIContainer`는 `ObjectIdentifier` 기반 지연 생성 싱글톤 + 캐시 무효화(`resetCache`)를 지원
- SwiftUI `Environment(\.di)`로 컨테이너를 전파하고, View는 필요한 타입만 `resolve(_:)`로 꺼냄
- `UseCaseProvider` 패턴으로 Feature별 UseCase 팩토리를 그룹화

### 5. PLY 파일 캐시 & 비교 결과 영속화

- `PLYFileCache` (actor) — `roomId`별 PLY 파일을 캐시 디렉터리에 저장하여 재진입 시 즉시 표시. 원격 URL을 사이드카로 기록해 같은 URL이면 캐시 히트 시 네트워크 요청 없이 반환하고, URL이 바뀌면 다시 받습니다(테스트로 고정). `PLYFileCacheProtocol`로 ViewModel에 주입되어 테스트에서는 Mock으로 대체됩니다.
- `ComparisonResultViewModel` — `UserDefaults`에 `(moveInRoomId, moveOutRoomId)` 쌍의 `analysisId`를 영속화하여 폴링 중단 후 재진입에도 결과를 즉시 복원

## 🛠 기술 스택

- **언어/프레임워크**: Swift 5, SwiftUI (iOS 26.0+)
- **동시성**: Swift Concurrency (`actor`, `async`/`await`, `Task`), `@Observable`
- **3D / AR**: ARKit, RealityKit, LiDAR Depth Sensing
- **네트워크**: [Moya](https://github.com/Moya/Moya) + 자체 `NetworkClient` actor
- **지도**: [KakaoMapsSDK](https://github.com/kakao-mapsSDK/KakaoMapsSDK-SPM) — Estimate 화면 한정
- **이미지**: [Nuke / NukeUI](https://github.com/kean/Nuke)
- **압축**: [ZIPFoundation](https://github.com/weichsel/ZIPFoundation)
- **저장소**: Keychain (토큰), 자체 FileCache (PLY)
- **CI**: GitHub Actions (`macos-26`, iPhone 17 Pro 시뮬레이터)

## 🏛 아키텍처

**Clean Architecture + MVVM**, 기능(Feature) 단위 모듈 구성. 각 Feature는 `Data` / `Domain` / `Presentation` 레이어로 분리됩니다.

```text
Feature/
├── Data/          — TargetType, DTO, Repository 구현
├── Domain/        — Interface, Model, UseCase
└── Presentation/  — View, ViewModel, Provider
```

```text
RoomLog/RoomLog/
├── App/                  — 엔트리 포인트 (RoomLogApp), 알림 처리 (AppNotificationDelegate — 포그라운드 배너, 탭 시 화면 이동)
├── Core/
│   ├── Config/           — 환경 설정 (BASE_URL, KAKAO_NATIVE_APP_KEY)
│   ├── Common/           — Extensions, UIComponents
│   ├── DIContainer/      — 의존성 컨테이너
│   ├── Error/            — RepositoryError, NetworkError, ServerErrorCode
│   ├── Navigation/       — AppRouter, PathStore, NavigationDestination
│   ├── NetworkAdapter/   — NetworkClient(actor), TokenStore, MoyaAdapter
│   └── ScanProcessing/   — ScanProcessingManager, ScanArtifactStore, ScanProcessingState, ScanBackgroundContinuation, ScanCompletionNotifier
├── Features/             — Auth · Home · Scan · Viewer · Defect · Comparison · Estimate · Chatbot · MyPage · Splash · Tab
├── Resources/            — Assets, Fonts, EnvironmentKey
└── Utilities/            — FileCache(PLYFileCache, PLYFileCacheProtocol), Keychain, PreviewMocks
```

## 🧪 테스트

- **102개** — Swift Testing 70 + XCTest 32 (`RoomLogTests/`). Xcode ⌘U 또는 `xcodebuild test`로 실행하며, CI에서도 실행됩니다.
- 스캔 파이프라인 38개(`ScanProcessingManagerTests` 24 · `ScanArtifactStoreTests` 14) — 재시작 복구, 백그라운드 연장 시작·종료, 완료 알림, 재시도 불가 시 폐기 등 실패 경로를 위주로 검증합니다.
- ViewModel 테스트는 Mock Repository·Mock PLY 캐시를 주입해 상태 전이와 호출 횟수를 단언하며, 실행 중 네트워크 요청과 실제 캐시 디렉터리 접근이 없습니다.

## 🤖 CI

- `develop` 브랜치 push / PR 시 GitHub Actions(`.github/workflows/ci.yml`)가 자동 빌드·테스트 검증을 수행합니다. 테스트 실패 시 `.xcresult`를 아티팩트로 남깁니다.
- CI 환경에서는 `Config.xcconfig` placeholder를 자동 생성합니다.
- 실행 환경: `macos-26`, `iPhone 17 Pro` 시뮬레이터

## 📄 License

[MIT License](LICENSE) © 2026 Team404
