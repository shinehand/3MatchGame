extends RefCounted

const SOURCE_REWARDED_AD := "rewarded_ad"
const SOURCE_IAP := "iap"
const SOURCE_COINS := "coins"
const RESULT_COMPLETED := "completed"
const DEFAULT_PLACEMENT := "fail_offer"
const DEFAULT_REWARD_TYPE := "extra_moves"
const DEFAULT_AD_NETWORK := "local_simulator"
const DEFAULT_PRODUCT_ID := "fail_offer_continue_pack"
const DEFAULT_PRICE := 0.99
const DEFAULT_CURRENCY := "USD"

static var _queued_results: Array = []


static func request_continue(source: String, stage_id: int, fail_offer: Dictionary, details: Dictionary = {}) -> Dictionary:
	var normalized_source := _normalize_source(source)
	var queued_result := _pop_queued_result(normalized_source)
	var merged_details := _default_details(normalized_source, stage_id, fail_offer)
	if not queued_result.is_empty():
		_merge_details(merged_details, Dictionary(queued_result.get("details", {})))
	_merge_details(merged_details, details)
	var result := String(details.get("result", queued_result.get("result", RESULT_COMPLETED))).strip_edges().to_lower()
	if result.is_empty():
		result = RESULT_COMPLETED
	return {
		"source": normalized_source,
		"result": result,
		"details": merged_details,
	}


static func queue_continue_result_for_testing(source: String, result: String, details: Dictionary = {}) -> void:
	_queued_results.append({
		"source": _normalize_source(source),
		"result": result.strip_edges().to_lower(),
		"details": details.duplicate(true),
	})


static func clear_continue_results_for_testing() -> void:
	_queued_results.clear()


static func _pop_queued_result(source: String) -> Dictionary:
	for index in range(_queued_results.size()):
		var queued_result: Dictionary = Dictionary(_queued_results[index])
		var queued_source := String(queued_result.get("source", "")).strip_edges().to_lower()
		if queued_source == source or queued_source == "*":
			_queued_results.remove_at(index)
			return queued_result
	return {}


static func _default_details(source: String, stage_id: int, fail_offer: Dictionary) -> Dictionary:
	match source:
		SOURCE_IAP:
			return {
				"product_id": DEFAULT_PRODUCT_ID,
				"placement": DEFAULT_PLACEMENT,
				"price": DEFAULT_PRICE,
				"currency": DEFAULT_CURRENCY,
				"transaction_id": _make_transaction_id("iap_continue", stage_id),
			}
		SOURCE_COINS:
			return {
				"placement": DEFAULT_PLACEMENT,
				"cost_amount": int(fail_offer.get("coin_cost", 120)),
				"transaction_id": _make_transaction_id("coin_continue", stage_id),
			}
	return {
		"placement": DEFAULT_PLACEMENT,
		"reward_type": DEFAULT_REWARD_TYPE,
		"ad_network": DEFAULT_AD_NETWORK,
		"transaction_id": _make_transaction_id("fail_offer_continue", stage_id),
	}


static func _merge_details(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if String(key) == "result":
			continue
		target[key] = source[key]


static func _normalize_source(source: String) -> String:
	var normalized_source := source.strip_edges().to_lower()
	if normalized_source == "rewarded":
		return SOURCE_REWARDED_AD
	if normalized_source == "purchase":
		return SOURCE_IAP
	if normalized_source == "coin":
		return SOURCE_COINS
	return normalized_source


static func _make_transaction_id(source: String, stage_id: int) -> String:
	return "%s-%d-%d" % [source, stage_id, Time.get_ticks_msec()]
