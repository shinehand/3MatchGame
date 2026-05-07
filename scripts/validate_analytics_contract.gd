extends SceneTree

const CONTRACT_PATH := "res://data/analytics_events.json"
const REQUIRED_EVENTS := {
	"app_launch": ["session_id", "app_version", "platform"],
	"stage_start": ["session_id", "stage_id", "band", "roster_group", "moves"],
	"stage_complete": ["session_id", "stage_id", "score", "stars", "moves_left"],
	"stage_fail": ["session_id", "stage_id", "fail_type", "score", "remaining_goals"],
	"booster_used": ["session_id", "stage_id", "booster_id", "source"],
	"rescue_book_open": ["session_id", "highest_unlocked_stage", "unlocked_animal_count"],
	"animal_unlock": ["session_id", "animal_id", "source", "stage_id", "token_balance"],
	"live_event_impression": ["session_id", "event_id", "event_type", "placement"],
	"remote_config_exposure": ["session_id", "config_key", "variant_id", "config_value_hash"],
	"event_join": ["session_id", "event_id", "event_type", "placement"],
	"event_progress": ["session_id", "event_id", "event_type", "placement", "progress_key", "progress_value"],
	"event_reward_claim": ["session_id", "event_id", "event_type", "placement", "reward_id", "reward_type", "reward_amount"],
	"offer_impression": ["session_id", "stage_id", "fail_type", "primary_cta", "show_rewarded_ad", "show_iap"],
	"ad_reward_complete": ["session_id", "stage_id", "placement", "reward_type", "reward_amount", "transaction_id"],
	"ad_reward_fail": ["session_id", "stage_id", "placement", "reward_type", "ad_network", "error_code"],
	"iap_purchase_start": ["session_id", "product_id", "price", "currency", "placement"],
	"iap_purchase_complete": ["session_id", "product_id", "price", "currency", "transaction_id"],
	"iap_purchase_restore": ["session_id", "product_id", "placement", "restore_result", "restored_transaction_id"],
	"iap_purchase_cancel": ["session_id", "product_id", "placement", "price", "currency"],
	"iap_purchase_fail": ["session_id", "product_id", "placement", "error_code", "price", "currency"],
	"fail_offer_show": ["session_id", "stage_id", "fail_type", "attempt_count", "goals_remaining", "progress_ratio", "offer_type"],
	"fail_offer_select": ["session_id", "stage_id", "fail_type", "offer_type", "cost_type", "cost_amount"],
	"fail_offer_dismiss": ["session_id", "stage_id", "fail_type", "dismiss_action", "elapsed_ms"],
	"extra_moves_grant": ["session_id", "stage_id", "source", "moves_amount", "transaction_id"],
	"combo_fever_start": ["session_id", "stage_id", "turns_remaining", "score_multiplier", "target_bonus"],
	"combo_fever_end": ["session_id", "stage_id", "turns_spent"],
	"buddy_skill_charge": ["session_id", "stage_id", "animal_id", "skill_id", "charge_rule", "charge_count"],
	"buddy_skill_ready": ["session_id", "stage_id", "animal_id", "skill_id", "turn_index"],
	"buddy_skill_trigger": ["session_id", "stage_id", "animal_id", "skill_id", "effect_type", "uses_left"],
	"buddy_skill_blocked": ["session_id", "stage_id", "animal_id", "skill_id", "reason"],
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors := _validate_contract()
	if not errors.is_empty():
		for error_text in errors:
			push_error("Analytics contract validation error: %s" % error_text)
		quit(1)
		return
	print("Analytics contract validation passed.")
	quit()


func _validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if not FileAccess.file_exists(CONTRACT_PATH):
		errors.append("missing %s" % CONTRACT_PATH)
		return errors

	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	if not (parsed is Array):
		errors.append("analytics contract must be an array")
		return errors

	var events_by_name := {}
	for entry in Array(parsed):
		if not (entry is Dictionary):
			errors.append("analytics event entry must be a dictionary")
			continue
		var event: Dictionary = entry
		var event_name := String(event.get("name", ""))
		if event_name.is_empty():
			errors.append("analytics event missing name")
			continue
		if events_by_name.has(event_name):
			errors.append("duplicate analytics event %s" % event_name)
		events_by_name[event_name] = event
		var params: Array = event.get("required_params", [])
		if params.is_empty():
			errors.append("analytics event %s has no required_params" % event_name)
		var seen_params := {}
		for param_value in params:
			var param := String(param_value)
			if param.is_empty():
				errors.append("analytics event %s has empty required param" % event_name)
			elif seen_params.has(param):
				errors.append("analytics event %s duplicates required param %s" % [event_name, param])
			seen_params[param] = true

	for required_event_name in REQUIRED_EVENTS.keys():
		if not events_by_name.has(required_event_name):
			errors.append("missing required analytics event %s" % required_event_name)
			continue
		var event: Dictionary = events_by_name[required_event_name]
		var required_params: Array = event.get("required_params", [])
		for param in REQUIRED_EVENTS[required_event_name]:
			if not required_params.has(param):
				errors.append("analytics event %s missing required param %s" % [required_event_name, param])
	return errors
