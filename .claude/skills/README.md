# RoomLog 팀 공용 Agent Skills

이 디렉터리의 스킬은 커뮤니티에 공개된 Swift/iOS Agent Skill을 가져온 것이다.
Claude Code가 자동으로 로드하며, `/<skill-name>`으로 직접 호출할 수도 있다.

| 스킬 | 출처 | 저자 | 라이선스 | 도입 이유 |
|------|------|------|----------|-----------|
| `swift-concurrency-pro` | [twostraws/Swift-Concurrency-Agent-Skill](https://github.com/twostraws/Swift-Concurrency-Agent-Skill) | Paul Hudson | MIT | `NetworkClient`·`KeychainTokenStore` actor, 토큰 갱신 직렬화, `@MainActor` 관련 이슈 대응 |
| `swift-testing-pro` | [twostraws/Swift-Testing-Agent-Skill](https://github.com/twostraws/Swift-Testing-Agent-Skill) | Paul Hudson | MIT | `RoomLogTests`가 XCTest와 Swift Testing 혼재 → 마이그레이션 기준 |
| `swiftui-pro` | [twostraws/swiftui-agent-skill](https://github.com/twostraws/swiftui-agent-skill) | Paul Hudson | MIT | iOS 26 타겟, Liquid Glass 사용 → 최신 API·deprecated 판별 |
| `ios-accessibility` | [dadederk/iOS-Accessibility-Agent-Skill](https://github.com/dadederk/iOS-Accessibility-Agent-Skill) | Daniel Devesa | 각 스킬 폴더의 `LICENSE.txt` 참조 | VoiceOver·Dynamic Type 대응 (현재 접근성 코드 없음) |

전체 Swift 스킬 목록은 [twostraws/swift-agent-skills](https://github.com/twostraws/swift-agent-skills) 참고.

## 업데이트 방법

원본 저장소를 클론한 뒤 스킬 폴더만 덮어쓴다. (`agents/`, `assets/`, `.claude-plugin/`, 중첩 `skills/`는 제외)

```bash
git clone --depth 1 https://github.com/twostraws/swiftui-agent-skill.git /tmp/s
rsync -a --delete \
  --exclude agents --exclude assets --exclude .claude-plugin --exclude skills \
  /tmp/s/swiftui-pro/ .claude/skills/swiftui-pro/
```
