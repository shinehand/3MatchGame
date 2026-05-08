extends RefCounted

const SOURCE_REWARDED_AD := "rewarded_ad"
const SOURCE_IAP := "iap"
const SOURCE_COINS := "coins"
const RESULT_COMPLETED := "completed"
const RESULT_FAILED := "failed"
const RESULT_PENDING := "pending"
const DEFAULT_PLACEMENT := "fail_offer"
const DEFAULT_REWARD_TYPE := "extra_moves"
const DEFAULT_AD_NETWORK := "local_simulator"
const DEFAULT_PRODUCT_ID := "fail_offer_continue_pack"
const DEFAULT_PRICE := 0.99
const DEFAULT_CURRENCY := "USD"
const DEFAULT_PROVIDER_ID := "local_simulator"
const MAX_REQUEST_LOG := 120

static var _provider_id := DEFAULT_PROVIDER_ID
static var _continue_adapter: Callable = Callable()
static var _queued_results: Array = []
static var _request_log: Array = []


static func request_continue(source: String, stage_id: int, fail_offer: Dictionary, details: Dictionary = {}) -> Dictionary:
	var normalized_source := _normalize_source(source)
	if not _is_supported_source(normalized_source):
		var rejected_details := {
			"provider_id": _provider_id,
			"placement": DEFAULT_PLACEMENT,
			"error_code": "invalid_source",
		}
		_merge_details(rejected_details, details)
		var rejected_result := {
			"source": normalized_source,
			"result": "failed",
			"details": rejected_details,
			"request_status": "rejected_invalid_source",
		}
		_log_request(normalized_source, stage_id, fail_offer, rejected_result)
		return rejected_result
	var merged_details := _default_details(normalized_source, stage_id, fail_offer)
	var queued_result := _pop_queued_result(normalized_source)
	var result := RESULT_COMPLETED
	if not queued_result.is_empty():
		_merge_details(merged_details, Dictionary(queued_result.get("details", {})))
		_merge_details(merged_details, details)
		var queued_result_value = queued_result.get("result", details.get("result", RESULT_COMPLETED))
		result = _normalize_result(queued_result_value, RESULT_COMPLETED)
		_preserve_provider_result(merged_details, queued_result_value, result)
	elif _continue_adapter.is_valid():
		var adapter_result := _request_continue_from_adapter(normalized_source, stage_id, fail_offer, merged_details, details)
		_merge_details(merged_details, details)
		_merge_details(merged_details, Dictionary(adapter_result.get("details", {})))
		var adapter_result_value = adapter_result.get("result", RESULT_FAILED)
		result = _normalize_result(adapter_result_value, RESULT_FAILED)
		_preserve_provider_result(merged_details, adapter_result_value, result)
	else:
		_merge_details(merged_details, details)
		var local_result_value = details.get("result", RESULT_COMPLETED)
		result = _normalize_result(local_result_value, RESULT_COMPLETED)
		_preserve_provider_result(merged_details, local_result_value, result)
	var gateway_result := {
		"source": normalized_source,
		"result": result,
		"details": merged_details,
		"request_status": "resolved",
	}
	_log_request(normalized_source, stage_id, fail_offer, gateway_result)
	return gateway_result


static func queue_continue_result_for_testing(source: String, result: String, details: Dictionary = {}) -> void:
	_queued_results.append({
		"source": _normalize_source(source),
		"result": result.strip_edges().to_lower(),
		"details": details.duplicate(true),
	})


static func configure_continue_adapter(provider_id: String, adapter: Callable) -> void:
	_set_provider_id(provider_id)
	_continue_adapter = adapter


static func clear_continue_adapter_for_testing() -> void:
	_continue_adapter = Callable()


static func clear_continue_results_for_testing() -> void:
	_queued_results.clear()


static func get_request_log_for_testing() -> Array:
	return _request_log.duplicate(true)


static func clear_request_log_for_testing() -> void:
	_request_log.clear()


static func set_provider_id_for_testing(provider_id: String) -> void:
	_set_provider_id(provider_id)


static func _set_provider_id(provider_id: String) -> void:
	var normalized_provider := provider_id.strip_edges()
	_provider_id = DEFAULT_PROVIDER_ID if normalized_provider.is_empty() else normalized_provider


static func reset_for_testing() -> void:
	_provider_id = DEFAULT_PROVIDER_ID
	_continue_adapter = Callable()
	_queued_results.clear()
	_request_log.clear()


static func _pop_queued_result(source: String) -> Dictionary:
	for index in range(_queued_results.size()):
		var queued_result: Dictionary = Dictionary(_queued_results[index])
		var queued_source := str(queued_result.get("source", "")).strip_edges().to_lower()
		if queued_source == source or queued_source == "*":
			_queued_results.remove_at(index)
			return queued_result
	return {}


static func _request_continue_from_adapter(source: String, stage_id: int, fail_offer: Dictionary, default_details: Dictionary, request_details: Dictionary) -> Dictionary:
	var payload_details := default_details.duplicate(true)
	_merge_details(payload_details, request_details)
	var request_payload := {
		"source": source,
		"stage_id": stage_id,
		"fail_type": str(fail_offer.get("type", fail_offer.get("fail_type", ""))),
		"offer_type": str(fail_offer.get("offer_type", "")),
		"placement": str(payload_details.get("placement", DEFAULT_PLACEMENT)),
		"provider_id": _provider_id,
		"details": payload_details,
		"fail_offer": fail_offer.duplicate(true),
	}
	var adapter_response = _continue_adapter.call(request_payload.duplicate(true))
	return _normalize_adapter_response(adapter_response)


static func _normalize_adapter_response(adapter_response) -> Dictionary:
	if adapter_response is Dictionary:
		var response: Dictionary = Dictionary(adapter_response).duplicate(true)
		response["details"] = Dictionary(response.get("details", {})).duplicate(true)
		return response
	if adapter_response is String:
		return {"result": str(adapter_response)}
	if adapter_response is bool:
		return {"result": RESULT_COMPLETED if bool(adapter_response) else RESULT_FAILED}
	return {
		"result": RESULT_FAILED,
		"details": {"error_code": "adapter_invalid_result"},
	}


static func _normalize_result(result_value, default_result: String) -> String:
	var result := str(result_value).strip_edges().to_lower()
	if result.is_empty():
		return _normalize_default_result(default_result)
	match result:
		RESULT_COMPLETED, "complete", "success", "succeeded", "ok", "granted", "rewarded", "purchased":
			return RESULT_COMPLETED
		RESULT_FAILED, "fail", "failure", "error", "errored", "timeout", "timed_out", "cancel", "cancelled", "canceled", "aborted", "denied", "rejected", "expired", "unavailable":
			return RESULT_FAILED
		RESULT_PENDING, "start", "started", "in_progress", "processing", "running", "queued", "requested", "loading", "deferred", "awaiting_callback":
			return RESULT_PENDING
	return RESULT_FAILED


static func _preserve_provider_result(details: Dictionary, result_value, canonical_result: String) -> void:
	var raw_result := str(result_value).strip_edges().to_lower()
	if raw_result.is_empty() or raw_result == canonical_result or details.has("provider_result"):
		return
	details["provider_result"] = raw_result


static func _normalize_default_result(default_result: String) -> String:
	var normalized_default := default_result.strip_edges().to_lower()
	if [RESULT_COMPLETED, RESULT_FAILED, RESULT_PENDING].has(normalized_default):
		return normalized_default
	return RESULT_FAILED


static func _default_details(source: String, stage_id: int, fail_offer: Dictionary) -> Dictionary:
	match source:
		SOURCE_IAP:
			return {
				"provider_id": _provider_id,
				"product_id": DEFAULT_PRODUCT_ID,
				"placement": DEFAULT_PLACEMENT,
				"price": DEFAULT_PRICE,
				"currency": DEFAULT_CURRENCY,
				"transaction_id": _make_transaction_id("iap_continue", stage_id),
			}
		SOURCE_COINS:
			return {
				"provider_id": _provider_id,
				"placement": DEFAULT_PLACEMENT,
				"cost_amount": int(fail_offer.get("coin_cost", 120)),
				"transaction_id": _make_transaction_id("coin_continue", stage_id),
			}
	return {
		"provider_id": _provider_id,
		"placement": DEFAULT_PLACEMENT,
		"reward_type": DEFAULT_REWARD_TYPE,
		"ad_network": DEFAULT_AD_NETWORK,
		"transaction_id": _make_transaction_id("fail_offer_continue", stage_id),
	}


static func _merge_details(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if str(key) == "result":
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


static func _is_supported_source(source: String) -> bool:
	return [SOURCE_REWARDED_AD, SOURCE_IAP, SOURCE_COINS].has(source)


static func _log_request(source: String, stage_id: int, fail_offer: Dictionary, gateway_result: Dictionary) -> void:
	var details := Dictionary(gateway_result.get("details", {})).duplicate(true)
	var entry := {
		"source": source,
		"stage_id": stage_id,
		"fail_type": str(fail_offer.get("type", fail_offer.get("fail_type", ""))),
		"offer_type": str(fail_offer.get("offer_type", "")),
		"placement": str(details.get("placement", DEFAULT_PLACEMENT)),
		"provider_id": str(details.get("provider_id", _provider_id)),
		"result": str(gateway_result.get("result", "")),
		"request_status": str(gateway_result.get("request_status", "")),
		"details": details,
	}
	_request_log.append(entry)
	while _request_log.size() > MAX_REQUEST_LOG:
		_request_log.pop_front()


static func _make_transaction_id(source: String, stage_id: int) -> String:
	return "%s-%d-%d" % [source, stage_id, Time.get_ticks_msec()]
