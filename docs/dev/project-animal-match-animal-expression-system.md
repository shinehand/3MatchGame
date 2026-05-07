# Project Animal Match Animal Expression System

## 목적

동물 12종이 보드 위에서 살아 있는 느낌을 주도록 표정 애니메이션 시스템을 정의한다. 이 문서는 개발 에이전트가 `scripts/block_tile.gd`와 `scripts/gameplay.gd`를 수정할 때 따르는 구현 명세다.

## 핵심 원칙

- full-frame 애니메이션만으로 12종을 모두 처리하지 않는다.
- 1차 구현은 기존 단일 TextureRect 구조를 유지하면서 scale, tint, overlay, atlas region 변경으로 표현한다.
- 표정 시스템은 매치 판정, 낙하, 리필, 특수 블록 상태를 침범하지 않는다.
- 보드 전체가 동시에 움직이지 않도록 idle 애니메이션 동시 수를 제한한다.

## 표정 상태

| 상태 | 트리거 | 길이 | 우선순위 |
| --- | --- | --- | --- |
| `idle` | 기본 상태 | 상시 | 0 |
| `blink` | 대기 중 scheduler | 0.12-0.18s | 1 |
| `smile` | 선택/힌트/목표 근접 | 0.20-0.30s | 2 |
| `match` | 제거 직전 | 0.16-0.22s | 3 |
| `fever` | 피버 중 목표/특수 블록 | 0.45-0.60s loop | 2 |
| `worried` | 이동 수 3 이하/실패 직전 | 0.50-0.80s short loop | 2 |

우선순위가 높은 상태가 재생 중이면 낮은 상태는 무시한다. `match`는 제거 직전 상태이므로 가장 강하다.

## 권장 BlockTile API

```gdscript
func set_expression(expression_id: String, force: bool = false) -> void:
	pass

func clear_expression() -> void:
	pass

func can_play_idle_expression() -> bool:
	return not is_inactive and icon.visible and not is_expression_locked
```

## BlockTile 내부 상태 후보

```gdscript
var expression_state := "idle"
var expression_tween: Tween
var expression_priority := 0
var is_expression_locked := false
```

## fallback 표현

에셋이 준비되지 않은 상태에서도 개발 검증이 가능해야 한다.

| 상태 | fallback |
| --- | --- |
| `blink` | icon scale y를 1.0 -> 0.82 -> 1.0으로 짧게 변경 |
| `smile` | icon scale 1.0 -> 1.06 -> 1.0, 밝기 소폭 증가 |
| `match` | 기존 `play_match_effect()` 전에 0.08초 scale-up |
| `fever` | icon modulate를 밝게 하고 특수 rim/glow를 짧게 반복 |
| `worried` | 좌우 2px shake와 채도 소폭 감소 |

## BoardExpressionScheduler 설계

### 위치

1차 구현은 `scripts/gameplay.gd` 내부 함수로 시작해도 된다. 규모가 커지면 `scripts/board_expression_scheduler.gd`로 분리한다.

### 조건

- `stage_state == "playing"`일 때만 동작한다.
- `is_busy == false`일 때만 새 idle expression을 시작한다.
- active cell 중 texture가 있는 타일만 대상으로 한다.
- 동시에 blink 중인 타일은 최대 4개다.

### 의사 코드

```gdscript
func _schedule_next_idle_expression() -> void:
	var delay := rng.randf_range(2.8, 6.0)
	await get_tree().create_timer(delay).timeout
	if stage_state != "playing" or is_busy:
		_schedule_next_idle_expression()
		return
	_play_random_blinks()
	_schedule_next_idle_expression()

func _play_random_blinks() -> void:
	var candidates := _active_visible_tiles()
	candidates.shuffle()
	var count := mini(candidates.size(), rng.randi_range(1, 4))
	for index in range(count):
		candidates[index].set_expression("blink")
```

## 이벤트 연결

| 게임 이벤트 | 호출 |
| --- | --- |
| 타일 선택 | `tile.set_expression("smile")` |
| 유효 스왑 완료 | 양쪽 타일 `smile` 짧게 |
| 매치 제거 직전 | 제거 대상 `match` |
| 특수 블록 생성 | 생성 위치 `smile`, 이후 badge 연출 |
| 이동 수 3 이하 | 목표 동물 중 일부 `worried` |
| 실패 팝업 직전 | 보드 내 목표 동물 `worried` |

## 씬 변경 후보

`scenes/block_tile.tscn`에 overlay 노드를 추가할 수 있다.

```text
Content
├── Icon
├── ExpressionOverlay
├── MatchBurst
├── SelectionGlow
└── SpecialBadge
```

1차 구현에서는 overlay 없이 `Icon` Tween만으로 시작해도 된다. overlay 추가는 에셋이 준비된 뒤 진행한다.

## 데이터 확장

추후 atlas 기반으로 전환할 때는 동물별 expression profile을 Resource 또는 JSON으로 둔다.

```json
{
  "animal_id": "rabbit",
  "frames": {
    "idle": ["idle"],
    "blink": ["blink_01", "blink_02", "blink_03"],
    "smile": ["smile_01", "smile_02"],
    "match": ["match_01", "match_02", "match_03"],
    "fever": ["fever_01", "fever_02"],
    "worried": ["worried_01", "worried_02"]
  }
}
```

## 완료 기준

- 기존 타일 표시가 깨지지 않는다.
- MVP 12종 보드 로스터가 fallback 포함으로 표시 가능하다.
- 대기 중 blink가 일부 타일에서만 재생된다.
- 매치/낙하 중 idle expression이 새로 시작되지 않는다.
- 홈 AnimalStrip, Rescue Book 카드 preview, 결과 overlay mascot도 `idle`/`blink`/`smile` 또는 상황별 `worried`/`fever` fallback 상태를 노출한다.
- 홈과 Rescue Book preview Tween은 화면에 보이는 대상 기준 최대 4개만 활성화한다.
- `scripts/validate_gameplay.sh` 또는 씬 로드 검증이 통과한다.
