# Project Animal Match Roster Group QA - 2026-05-02

## QA 결과

승인 — PAM-DEV-021의 `roster_group` 메타데이터 도입은 코드/데이터/검증 기준에서 통과했다.

## 대상 작업 카드

- PAM-DEV-021: 로스터 그룹 메타데이터 추가

## 확인 환경

- 저장소: `/Users/shinehandmac/Github/3MatchGame`
- 확인 일시: 2026-05-02 12:15 KST

## 검증 명령

```sh
bash scripts/validate_stage_data.sh
bash scripts/validate_stage_balance.sh
bash scripts/validate_gameplay.sh
```

## 주요 확인

- `data/stages/*.json` 100개 스테이지 모두 `roster_group` 값을 가진다.
- 10개 밴드가 각각 10개 스테이지씩 아래 그룹으로 매핑된다.
  - `1-10` → `forest_early`
  - `11-20` → `trap_trail`
  - `21-30` → `camp_outer`
  - `31-40` → `rescue_route`
  - `41-50` → `river_crossing`
  - `51-60` → `camp_inner`
  - `61-70` → `deep_jungle`
  - `71-80` → `escape_prep`
  - `81-90` → `elephant_route`
  - `91-100` → `final_rescue`
- `StageCatalog._normalize_stage()`가 `roster_group`을 읽고, 누락 시 밴드 기준 기본값을 보정한다.
- `StageDataValidator`가 유효한 `roster_group` 값만 허용한다.
- fallback stage에도 `band`, `roster_group`, `theme_key`, `mechanics`, `tags`가 보강되어 있다.

## 반려 이슈

없음.

## 재확인 필요

- 향후 실제 레벨 밸런스 조정 시 `roster_group`별 해금 동물/목표 동물 분포가 의도와 맞는지 플레이 지표로 재확인 필요.
