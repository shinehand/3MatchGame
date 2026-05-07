extends RefCounted

const TYPE_NEAR_MISS := "near_miss"
const TYPE_STRATEGIC := "strategic_miss"
const TYPE_FIRST_FAIL := "first_fail"
const TYPE_REPEAT_FAIL := "repeat_fail"
const TYPE_HARD_FAIL := "hard_level_fail"
const TYPE_BLOCKERS := "blockers_remaining"
const TYPE_SCORE := "score_shortfall"
const TYPE_COLLECTION := "collection_shortfall"
const TYPE_GENERAL := "general_shortfall"


static func classify(stage: Dictionary, progress: Dictionary) -> String:
	var stage_id := int(stage.get("id", 1))
	var fail_count := int(progress.get("fail_count", 0))
	var difficulty := String(stage.get("difficulty", ""))
	var tags: Array = stage.get("tags", [])
	if stage_id >= 11 and (difficulty == "Hard" or tags.has("master") or tags.has("finale")):
		return TYPE_HARD_FAIL
	if fail_count >= 2:
		return TYPE_REPEAT_FAIL
	if _is_near_miss(stage, progress):
		return TYPE_NEAR_MISS
	if stage_id <= 10 and fail_count <= 1:
		return TYPE_FIRST_FAIL
	if _primary_shortfall(stage, progress) != TYPE_GENERAL:
		return TYPE_STRATEGIC
	if fail_count <= 1:
		return TYPE_FIRST_FAIL
	return TYPE_GENERAL


static func build_offer(stage: Dictionary, progress: Dictionary) -> Dictionary:
	var stage_id := int(stage.get("id", 1))
	var fail_type := classify(stage, progress)
	var can_show_ad := stage_id >= 11
	var can_show_iap := stage_id >= 16 and (fail_type == TYPE_NEAR_MISS or fail_type == TYPE_HARD_FAIL)
	var offer := {
		"type": fail_type,
		"primary_cta": "재도전",
		"secondary_cta": "홈으로",
		"hint": "목표 칩을 보고 필요한 동물부터 우선적으로 모아 보세요.",
		"booster_suggestion": "rainbow_paw",
		"show_rewarded_ad": false,
		"show_iap": false,
	}

	match fail_type:
		TYPE_NEAR_MISS:
			offer["hint"] = "정말 아깝습니다. 남은 목표가 적으니 추가 이동이 가장 효율적입니다."
			offer["primary_cta"] = "+3 이동 받고 계속" if can_show_ad else "무료 재도전"
			offer["secondary_cta"] = "재도전" if can_show_ad else "홈으로"
			offer["show_rewarded_ad"] = can_show_ad
			offer["booster_suggestion"] = "rainbow_paw"
		TYPE_STRATEGIC:
			offer["hint"] = _strategic_hint(stage, progress)
			offer["booster_suggestion"] = _strategic_booster(stage, progress)
		TYPE_FIRST_FAIL:
			offer["hint"] = "첫 실패는 페널티 없이 다시 흐름을 익히는 구간입니다."
			offer["primary_cta"] = "무료 재도전"
			offer["booster_suggestion"] = _strategic_booster(stage, progress)
		TYPE_REPEAT_FAIL:
			offer["hint"] = "같은 목표에서 막혔습니다. 추천 부스터를 보고 다른 경로로 풀어 보세요."
			offer["primary_cta"] = "힌트 보고 재도전"
			offer["booster_suggestion"] = _strategic_booster(stage, progress)
		TYPE_HARD_FAIL:
			offer["hint"] = "하드 구간은 특수 블록 조합을 먼저 만들면 훨씬 안정적입니다."
			offer["primary_cta"] = "+3 이동 받고 계속" if can_show_ad else "재도전"
			offer["secondary_cta"] = "재도전"
			offer["show_rewarded_ad"] = can_show_ad
			offer["booster_suggestion"] = "bomb"

	if can_show_iap:
		offer["show_iap"] = true
	if stage_id <= 10:
		offer["show_rewarded_ad"] = false
		offer["show_iap"] = false
		if String(offer.get("primary_cta", "")).contains("+3"):
			offer["primary_cta"] = "무료 재도전"
	return offer


static func format_offer_line(offer: Dictionary) -> String:
	var parts: Array[String] = [String(offer.get("hint", ""))]
	if bool(offer.get("show_rewarded_ad", false)):
		parts.append("보상형 +3 이동 제안 가능")
	if bool(offer.get("show_iap", false)):
		parts.append("부스터 팩 제안 가능")
	parts.append("추천 부스터 %s" % String(offer.get("booster_suggestion", "rainbow_paw")))
	return " · ".join(parts)


static func _is_near_miss(stage: Dictionary, progress: Dictionary) -> bool:
	var remaining_units := _remaining_goal_units(stage, progress)
	if remaining_units <= 2:
		return true
	var total_units := _total_goal_units(stage)
	if total_units <= 0:
		return false
	return float(total_units - remaining_units) / float(total_units) >= 0.8


static func _primary_shortfall(stage: Dictionary, progress: Dictionary) -> String:
	var target_blockers := int(stage.get("target_blockers", 0))
	var cleared_blockers := int(progress.get("cleared_blockers", 0))
	if target_blockers > 0 and cleared_blockers < target_blockers:
		return TYPE_BLOCKERS

	var target_score := int(stage.get("target_score", 0))
	var score := int(progress.get("score", 0))
	if target_score > 0 and score < target_score:
		return TYPE_SCORE

	var collect_targets: Dictionary = Dictionary(stage.get("target_collect", {}))
	var collected_counts: Dictionary = Dictionary(progress.get("collected_counts", {}))
	for animal_id in collect_targets.keys():
		if int(collected_counts.get(animal_id, 0)) < int(collect_targets[animal_id]):
			return TYPE_COLLECTION
	return TYPE_GENERAL


static func _strategic_hint(stage: Dictionary, progress: Dictionary) -> String:
	match _primary_shortfall(stage, progress):
		TYPE_BLOCKERS:
			return "특수 블록으로 덤불 구역을 함께 정리해 보세요."
		TYPE_SCORE:
			return "큰 매치와 연쇄를 더 노리면 점수를 끌어올릴 수 있습니다."
		TYPE_COLLECTION:
			return "목표 동물 주변부터 맞추고, 무지개 발바닥을 아껴 쓰세요."
	return "다음 시도에서는 목표 우선순위를 먼저 잡아 보세요."


static func _strategic_booster(stage: Dictionary, progress: Dictionary) -> String:
	match _primary_shortfall(stage, progress):
		TYPE_BLOCKERS:
			return "bomb"
		TYPE_SCORE:
			return "striped"
		TYPE_COLLECTION:
			return "rainbow_paw"
	return "rainbow_paw"


static func _remaining_goal_units(stage: Dictionary, progress: Dictionary) -> int:
	var remaining := 0
	var collect_targets: Dictionary = Dictionary(stage.get("target_collect", {}))
	var collected_counts: Dictionary = Dictionary(progress.get("collected_counts", {}))
	for animal_id in collect_targets.keys():
		remaining += maxi(0, int(collect_targets[animal_id]) - int(collected_counts.get(animal_id, 0)))
	remaining += maxi(0, int(stage.get("target_blockers", 0)) - int(progress.get("cleared_blockers", 0)))
	var target_score := int(stage.get("target_score", 0))
	if target_score > 0 and int(progress.get("score", 0)) < target_score:
		remaining += 3
	return remaining


static func _total_goal_units(stage: Dictionary) -> int:
	var total := 0
	for value in Dictionary(stage.get("target_collect", {})).values():
		total += int(value)
	total += int(stage.get("target_blockers", 0))
	if int(stage.get("target_score", 0)) > 0:
		total += 3
	return total
