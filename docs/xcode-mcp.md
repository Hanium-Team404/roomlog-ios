# Xcode MCP 셋업 및 사용 가이드

Claude Code에서 Xcode 툴체인을 직접 다루기 위한 MCP 구성 문서.
Apple 공식 Xcode MCP + XcodeBuildMCP 두 개를 함께 사용한다.

---

## 1. 서버 구성

### Apple 공식 (Xcode 26.3 내장)

Xcode 26.3에 MCP 서버가 내장되어 있다. `xcrun mcpbridge`로 동작하며 20개 툴을
제공하고, 파일 조작 / 실시간 diagnostics / 문서 검색 / Swift REPL / SwiftUI 프리뷰를
커버한다.

Xcode 설정 → Intelligence 탭에서 MCP를 활성화한 뒤 등록한다.

```bash
claude mcp add --transport stdio xcode -s user -- xcrun mcpbridge
```

### XcodeBuildMCP

Cameron Cooke가 만들고 2026년 초 Sentry가 인수한 서드파티 서버. 약 80개 툴을
workflow 단위로 묶어 제공하며, 빌드 / 테스트 / 시뮬레이터 / 실기기 / LLDB 디버깅을
커버한다.

```bash
claude mcp add XcodeBuildMCP npx xcodebuildmcp@latest
```

요구사항: macOS 14.5+, Xcode 16.x+, Node 18+
Node를 쓰지 않으려면 Homebrew로 설치 (Apple Silicon에서는 ARM64 native Homebrew를
쓸 것 — x86 Homebrew를 경유하면 Node/Bun 계열에서 아키텍처 경고가 발생한다):

```bash
brew tap getsentry/xcodebuildmcp
brew install xcodebuildmcp
```

### 연결 확인

```bash
claude mcp list
```

Claude Code 세션 안에서는 `/mcp`로도 확인 가능.

---

## 2. 프로젝트 설정 (필수)

레포 루트에 `.xcodebuildmcp/config.yaml`을 둔다. 이 파일의 위치가 workspace root를
결정하므로 반드시 레포 루트에 위치해야 한다.

```yaml
schemaVersion: 1

enabledWorkflows:
  - simulator
  - project-discovery

sessionDefaults:
  projectPath: "./RoomLog.xcodeproj"
  scheme: "RoomLog"
  simulatorName: "iPhone 17 Pro"
```

대화형으로 생성/수정하려면:

```bash
xcodebuildmcp setup
```

### sessionDefaults를 반드시 고정할 것

defaults를 고정하지 않으면 에이전트가 매 작업 전에 시뮬레이터 목록과 scheme 목록을
조회하는 데 턴을 낭비한다. 이 discovery chatter가 그대로 토큰 비용이 된다.
sessionDefaults를 써두면 이후 모든 툴 호출에서 scheme과 프로젝트 경로를 넘기지 않아도
된다.

설정 우선순위: **세션 중 툴 호출 > config 파일 > 환경변수**

### workflow는 필요한 것만 켠다

기본적으로 simulator workflow만 활성화되어 있고, 나머지는 `enabledWorkflows`로 직접
opt-in하는 구조다. 처음부터 전부 켜면 툴 표면이 불필요하게 넓어져 에이전트의 툴 선택이
부정확해진다. 필요해질 때 추가한다.

주요 그룹:

| workflow | 내용 |
|---|---|
| `simulator` | list / boot / build / build_run / test / record_video (기본값) |
| `simulator-management` | erase, 다크모드 전환, 위치 목킹, 스테이터스바 오버라이드 |
| `project-discovery` | 프로젝트·워크스페이스 탐색, scheme 목록, 빌드 설정 조회 |
| `device` | 실기기 빌드·설치·실행·테스트 (devicectl 경유) |
| `testing` | test_sim / test_device + 커버리지 리포트 |
| `debugging` | LLDB attach, 브레이크포인트, 스택·변수 조회 |
| `ui-automation` | 스크린샷, 뷰 계층 조회, 탭/스와이프/입력 |

기대한 툴이 보이지 않으면 enabled workflows를 먼저 확인한다.
**workflow를 변경한 뒤에는 세션을 재시작해야 반영된다.**

### 커밋 여부

config.yaml은 repo-scoped 설정으로 설계되어 있어 버전 관리 대상으로 커밋하는 것이
정상이다. 팀원이 같은 scheme·시뮬레이터 기준으로 작업하게 된다.

---

## 3. 사용법

툴 이름을 외워 호출할 필요는 없다. 평소 말투로 지시하면 에이전트가 알아서 선택한다.

- "빌드해서 에러 고쳐줘"
- "이 테스트 돌려봐"
- "시뮬레이터에 띄우고 스크린샷 찍어줘"

알아두면 좋은 동작:

- 세션에서 첫 build/run/test 전에 `session_show_defaults`를 호출한다. defaults가 제대로
  잡혔는지 확인하는 단계이므로 이 호출이 보이면 정상이다.
- `discover_projs`는 defaults의 프로젝트 컨텍스트가 없거나 잘못됐을 때만 쓴다. 투기적으로
  실행하지 않는다.
- 시뮬레이터 실행 의도라면 build 따로 / run 따로가 아니라 build-and-run 통합 툴을 쓰는 게
  정석이다. 프롬프트도 "빌드하고 실행해"보다 "실행해봐"가 낫다.
- `sync_xcode_defaults`로 Xcode에서 현재 선택한 scheme·시뮬레이터를 그대로 가져올 수
  있다. Xcode를 켜놓고 병행 작업할 때 유용하다.

---

## 4. 두 서버의 역할 분담

두 서버는 상보적이다. Apple MCP는 IDE 통합(문서 검색, SwiftUI Preview)에 강하고,
XcodeBuildMCP는 headless 작업(시뮬레이터, UI 자동화, 디버깅)에 강하다.

| 작업 | 사용할 서버 |
|---|---|
| API availability 확인, 문서 검색 | Apple (`DocumentationSearch`) |
| SwiftUI 프리뷰 렌더 확인 | Apple (`RenderPreview`) |
| Issue Navigator 확인 | Apple (`XcodeListNavigatorIssues`) |
| Xcode 프로젝트 파일 조작 | Apple (`XcodeRead` / `XcodeWrite` / `XcodeUpdate`) |
| 빌드 / 테스트 루프 | XcodeBuildMCP |
| 시뮬레이터 조작, UI 자동화 | XcodeBuildMCP |
| LLDB 디버깅 | XcodeBuildMCP |

참고로 XcodeBuildMCP는 Xcode 자체 MCP 툴을 프록시하기도 한다. 툴이 중복되어 에이전트가
헤매면, XcodeBuildMCP가 제공하는 MCP skill을 설치해 툴 사용 지침을 미리 주입한다.

---

## 5. 알려진 문제 및 주의사항

### 실기기 (RoomLog는 LiDAR/ARKit이라 필수)

LiDAR 스캔은 시뮬레이터로 검증할 수 없으므로 device workflow가 필요하다.
**단, code signing을 먼저 처리해야 한다.** MCP 서버가 대신 해결해줄 수 없는 영역이다.

1. Xcode에서 타겟에 signing team 지정
2. 실기기로 한 번 수동 실행해 프로비저닝 프로파일 생성
3. 이후 에이전트에서 재시도

이 순서를 밟기 전에는 device 계열 툴이 전부 실패한다.

### 알려진 버그 (이슈 트래커 등록됨)

- 빌드 툴이 scheme 설정과 무관하게 `-configuration Debug`를 주입한다. Release 빌드를
  확인해야 할 때 주의.
- 디버거로 멈춘 상태에서 탭한 뒤 UI 엘리먼트 참조가 stale해진다.

### 기타

- Xcode가 주기적으로 MCP 연결 허용 다이얼로그를 띄운다.
- Xcode 내장 Claude Code 에이전트로 쓸 경우 PATH가 제한되어 있어 npx를 찾지 못할 수
  있다. 이 경우 설정에서 PATH를 명시해야 한다.
- 서버가 자체 런타임 에러를 Sentry로 전송한다(코드나 프롬프트는 아님). 끄려면
  config.yaml에 `sentryDisabled: true`.

### 문제 진단

```bash
npx -y xcodebuildmcp@latest mcp   # 시작 에러 직접 확인
xcodebuildmcp doctor              # Xcode / Node / 의존성 버전 점검
```

대부분의 실패 원인은 오래된 Node 또는 Xcode 버전이다.

---

## 6. 참고 링크

- XcodeBuildMCP: https://github.com/getsentry/XcodeBuildMCP
- 설정 전체 스키마: https://www.xcodebuildmcp.com/docs/configuration
- 툴 목록: https://github.com/getsentry/XcodeBuildMCP/blob/main/docs/TOOLS.md
