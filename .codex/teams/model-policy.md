# 모델 및 이성 수준 정책

## 목적

이 문서는 어떤 프로젝트에서도 팀별 에이전트에 적합한 AI 모델과 이성 수준을 빠르게 선택하기 위한 범용 정책이다.

## 이성 수준 기준

- `low`
  - 짧은 요약, 단순 반복, 변환 작업
- `medium`
  - 일반 구현, 빠른 시안, 일상적인 문서 작성
- `high`
  - 기획 설계, 복잡한 리뷰, 구조 변경, QA 분석
- `xhigh`
  - 장기 구조 재설계, 모호한 의사결정, 실패 비용이 큰 전략 작업

## 팀별 기본 추천

| 팀 | 권장 모델 | 기본 이성 수준 | 사용 이유 |
| --- | --- | --- | --- |
| PM Team Lead | `gpt-5.2` | `high` | 긴 문맥 유지, 우선순위 조정, 다팀 조율에 강함 |
| PM Team Members | `gpt-5.4-mini` | `medium` | 일정 정리, 리스크 정리, 상태 업데이트에 효율적 |
| Planning Team Lead | `gpt-5.4` | `high` | 시스템 기획, 구조화, 모호성 제거에 강함 |
| Planning Team Members | `gpt-5.4` | `medium` 또는 `high` | 밸런스, 스토리, UX 플로우에 유연함 |
| Art Team Lead | `gpt-5.4` | `high` | 비주얼 방향성과 UX 원칙 정리에 적합 |
| Art Team Members | `gpt-5.4` | `medium` | 반복 시안, 에셋 명세, 화면 피드백에 적합 |
| Development Team Lead | `gpt-5.3-codex` | `high` | 구현 범위 분배, 통합, 기술 판단에 적합 |
| Development Team Members | `gpt-5.3-codex` | `medium` | 실제 코드 작업 속도와 안정성 균형이 좋음 |
| Development Reviewer | `gpt-5.4` | `high` | 회귀, 논리 구멍, 리뷰 품질에 강함 |
| QA Team Lead | `gpt-5.4` | `high` | 승인/반려 기준과 품질 판단에 적합 |
| QA Team Members | `gpt-5.4-mini` | `high` | 재현 절차, 체크리스트, 기기별 확인에 효율적 |

## 상황별 조정 규칙

### 속도가 우선일 때

- PM 보조, QA 체크리스트, 단순 문서 분류는 `mini + medium`
- 개발 구현은 `codex + medium`

### 정확도가 우선일 때

- 기획, 리뷰, QA 승인, 구조 변경은 `high`
- 장기 아키텍처 개편이나 복합 전략 작업은 `xhigh`

### 비용과 품질을 함께 볼 때

- 팀장은 상위 모델을 유지한다.
- 팀원은 기본적으로 빠른 모델을 쓰고, 막히는 작업만 상향한다.

## 권장 기준 요약

- 팀장: 더 강한 모델 + 더 높은 이성 수준
- 실행 담당: 코덱스 계열 또는 동일 역할에 맞는 실행형 모델 + `medium`
- 리뷰/QA: 일반 구현보다 한 단계 높은 검토 모델 + `high`
