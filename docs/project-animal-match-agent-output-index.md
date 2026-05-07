# Project Animal Match Agent Output Index

## 프로젝트 공통 컨텍스트

- 프로젝트명: `Project Animal Match` (가칭)
- 기존 문서명 연결: `Zoo-Zoo Pop`, `Animal Pop Match`는 현재 저장소의 기존 가칭이며, 본 문서군에서는 `Project Animal Match`로 통합해 참조한다.
- 엔진: Godot 4.x
- 타겟: Android/iOS 글로벌 모바일 런칭
- 장르: 귀여운 동물 테마의 스테이지 기반 매치3 퍼즐
- 핵심 가치: 직관적인 스와이프, 찰진 매칭 피드백, 동물 캐릭터 수집감, 짧은 세션의 반복 재미

## 산출물 지도

| Agent | 문서 | 다음 참조자 |
| --- | --- | --- |
| All Agents | `docs/project-animal-match-agent-start-here.md` | All |
| All Agents | `.codex/tasks/project-animal-match-planning-handoff-briefs-2026-05-02.md` | PM, Development, Art, QA |
| Planning Council | `docs/planning/project-animal-match-planning-council-synthesis.md` | All |
| Planning Council | `docs/planning/project-animal-match-planning-upgrade-report-2026-05-02.md` | All |
| Planning Agent 1 | `docs/planning/project-animal-match-core-loop-agent-review.md` | Planning, Development |
| Planning Agent 2 | `docs/planning/project-animal-match-level-balance-agent-review.md` | Planning, Development, QA |
| Planning Agent 3 | `docs/planning/project-animal-match-ux-retention-agent-review.md` | Planning, BM, QA |
| Planning Expansion | `docs/planning/project-animal-match-decision-register.md` | All |
| Planning Expansion | `docs/planning/project-animal-match-system-rules-matrix.md` | Development, QA |
| Planning Expansion | `docs/planning/project-animal-match-ftue-rescue-book-spec.md` | UX, Development, QA |
| Planning Expansion | `docs/planning/project-animal-match-analytics-remote-config-spec.md` | Tech, BM, QA |
| Planning Expansion | `docs/planning/project-animal-match-rescue-buddy-skill-spec.md` | Planning, Development, QA |
| Planning Expansion | `docs/planning/project-animal-match-animal-roster-animation-matrix.md` | Art, Development, QA |
| Planning Expansion | `docs/planning/project-animal-match-level-progression-content-bible.md` | Planning, Development, QA |
| Game Director | `docs/game/project-animal-match-core-design.md` | Art, Tech, VFX, BM |
| Project Manager | `docs/pm/project-animal-match-master-development-plan.md` | All, QA |
| Art Director | `docs/art/project-animal-match-visual-style-guide.md` | Tech, VFX |
| Technical Lead | `docs/dev/project-animal-match-technical-architecture.md` | Development, QA |
| Development Agent | `docs/dev/project-animal-match-implementation-backlog.md` | Development, QA, PM |
| Development Agent | `docs/dev/project-animal-match-animal-expression-system.md` | Development, Art, QA |
| Animation & VFX Artist | `docs/art/project-animal-match-animation-vfx.md` | Art, Tech, QA |
| Business & Operations Modeler | `docs/ops/project-animal-match-business-operations.md` | PM, Tech, Planning |
| QA Agent | `docs/qa/project-animal-match-development-gates.md` | PM, Development |

## 통합 판단

- 기획 기준: 특수 블록과 피버 시스템은 코어 재미 장치이므로 MVP 후반이 아니라 MVP 핵심 범위로 둔다.
- 기술 기준: 레벨은 JSON을 기본으로 유지하고, 반복 사용되는 블록/장애물/스킬 정의는 Godot Resource로 분리한다.
- 아트 기준: 보드 로스터는 12종, 글로벌 런칭 컬렉션 목표는 18종으로 확장하고, 스테이지별 출현 풀은 5-6종으로 제한한다.
- 연출 기준: 모든 동물은 최소 blink, smile, match, fever, worried 표정을 가지며, idle 표정 애니메이션은 동시에 4개 타일 이하만 재생한다.
- BM 기준: 초반 20레벨은 결제보다 학습과 유지율을 우선한다. 결제/광고 노출은 실패 경험이 충분히 이해된 뒤 배치한다.
- PM 기준: 글로벌 런칭 전 소프트 런칭에서 Day 1/7 retention, level fail rate, rewarded ad opt-in, crash-free sessions를 먼저 검증한다.
- 기획 협의 기준: 피버 MVP는 3회 플레이어 이동, 동물 스킬은 Rescue Buddy 1종 자동 발동, 첫 세션 목표는 Level 5 컬렉션 해금으로 고정한다.

## 핵심 요약

1. `Project Animal Match`는 귀여운 동물 캐릭터를 전면에 둔 글로벌 모바일 매치3 게임이다.
2. 핵심 루프는 스와이프, 매치, 연쇄, 특수 블록, 보상, 다음 스테이지 진입이다.
3. 4매치, L/T매치, 5매치는 각각 줄 제거, 3x3 폭발, 동일 동물 제거 계열 특수 블록을 만든다.
4. 동물 테마 차별화는 `Zoo-Zoo Fever`와 동물별 구조 스킬로 만든다.
5. 레벨 데이터는 JSON 중심으로 운영하고, 정적 규칙은 Resource로 분리한다.
6. 동물은 12종 이상으로 운영하되, 보드에는 5-6종만 출현시켜 매치 확률을 지킨다.
7. 모바일 성능은 아틀라스, 오브젝트 풀링, 파티클 수 제한, 해상도별 UI 규칙으로 관리한다.
8. 아트는 파스텔 배경과 고대비 동물 얼굴 블록을 기본으로 한다.
9. 동물 표정은 눈/입 오버레이와 제한된 full-frame 프레임을 섞어 제작량을 관리한다.
10. VFX는 0.1초 단위의 빠른 반응과 콤보 단계별 확장감을 목표로 한다.
11. BM은 하트, 부스터, 보상형 광고, 시즌 패스를 사용하되 초반 학습 구간은 방해하지 않는다.
12. 개발 로드맵은 Prototype, MVP, Soft Launch, Global Launch 순서로 게이트를 나눠 진행한다.
13. 세 기획 에이전트 협의 결과는 `docs/planning/project-animal-match-planning-council-synthesis.md`를 우선 참조한다.
14. 확정/미결정 기획 판단은 `docs/planning/project-animal-match-decision-register.md`에 기록한다.
15. 구현 조건은 `docs/planning/project-animal-match-system-rules-matrix.md`와 백로그 카드를 함께 본다.
16. 분석 이벤트와 원격 설정은 `docs/planning/project-animal-match-analytics-remote-config-spec.md`를 기준으로 한다.
17. 동물 스킬 구현은 `docs/planning/project-animal-match-rescue-buddy-skill-spec.md`의 Rescue Buddy MVP 규칙을 따른다.
18. 동물별 표정과 확장 로스터는 `docs/planning/project-animal-match-animal-roster-animation-matrix.md`를 기준으로 한다.
19. 레벨 데이터와 밴드별 난이도 조정은 `docs/planning/project-animal-match-level-progression-content-bible.md`를 기준으로 한다.
