extends SceneTree

const MANIFEST_PATH := "res://data/provider_readiness.json"
const AnalyticsGateway = preload("res://scripts/analytics_gateway.gd")
const MonetizationGateway = preload("res://scripts/monetization_gateway.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors := _validate_provider_readiness()
	if not errors.is_empty():
		for error_text in errors:
			push_error("Provider readiness validation error: %s" % error_text)
		quit(1)
		return
	print("Provider readiness validation passed.")
	quit()


func _validate_provider_readiness() -> PackedStringArray:
	var errors := PackedStringArray()
	if not FileAccess.file_exists(MANIFEST_PATH):
		errors.append("missing %s" % MANIFEST_PATH)
		return errors

	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not (parsed is Dictionary):
		errors.append("provider readiness manifest must be a dictionary")
		return errors

	var manifest: Dictionary = parsed
	_require_equal(manifest, "version", 1, errors)
	_require_equal(manifest, "open_decision", "OPEN-007", errors)
	_require_equal(manifest, "real_sdk_credentials_required", false, errors)
	_require_equal(manifest, "readiness_validation_command", "zsh scripts/validate_provider_readiness.sh", errors)
	_require_array_contains_all(
		Array(manifest.get("external_gates", [])),
		[
			"real_sdk_credentials",
			"android_real_device_install_run",
			"release_keystore",
			"store_products",
			"receipt_validation",
		],
		"external_gates",
		errors
	)
	_validate_no_production_provider_names(manifest, errors)
	_validate_analytics_manifest(Dictionary(manifest.get("analytics", {})), errors)
	_validate_monetization_manifest(Dictionary(manifest.get("monetization", {})), errors)
	return errors


func _validate_analytics_manifest(analytics: Dictionary, errors: PackedStringArray) -> void:
	if analytics.is_empty():
		errors.append("analytics readiness section is missing")
		return
	_require_equal(analytics, "status", "provider_neutral", errors)
	_require_equal(analytics, "production_sdk", "none", errors)
	_require_equal(analytics, "gateway_script", "res://scripts/analytics_gateway.gd", errors)
	_require_existing_resource(str(analytics.get("gateway_script", "")), "analytics.gateway_script", errors)
	_require_equal(analytics, "contract_validation_command", "zsh scripts/validate_analytics_contract.sh", errors)
	_require_existing_command_script(str(analytics.get("contract_validation_command", "")), "analytics.contract_validation_command", errors)
	_require_equal(analytics, "default_provider_id", AnalyticsGateway.DEFAULT_PROVIDER_ID, errors)
	_require_equal(analytics, "adapter_hook", "configure_flush_adapter(provider_id, Callable)", errors)
	_require_equal(analytics, "queue_path", AnalyticsGateway.DEFAULT_QUEUE_PATH, errors)
	_require_equal(analytics, "max_queue_size", AnalyticsGateway.MAX_DISPATCHED_EVENTS, errors)
	_require_equal(analytics, "valid_dispatch_status", "queued", errors)
	_require_equal(analytics, "sent_dispatch_status", "sent", errors)
	_require_equal(analytics, "contract_invalid_status", "rejected_contract", errors)
	_require_array_contains_all(
		Array(analytics.get("flush_contracts", [])),
		[
			"disk_persisted_queue",
			"sequential_flush_order",
			"partial_failure_keeps_rejected_and_unattempted",
			"adapter_payload_mutation_guard",
			"bounded_queue_eviction",
			"corrupt_queue_tolerance",
		],
		"analytics.flush_contracts",
		errors
	)
	_require_array_contains_all(
		Array(analytics.get("smoke_coverage", [])),
		[
			"GameSession saved event",
			"AnalyticsGateway local_buffer queued",
			"disk reload preserves queue",
			"flush drains in order exactly once",
			"contract violation rejected_contract not queued",
		],
		"analytics.smoke_coverage",
		errors
	)


func _validate_monetization_manifest(monetization: Dictionary, errors: PackedStringArray) -> void:
	if monetization.is_empty():
		errors.append("monetization readiness section is missing")
		return
	_require_equal(monetization, "status", "provider_neutral", errors)
	_require_equal(monetization, "production_ad_sdk", "none", errors)
	_require_equal(monetization, "production_iap_sdk", "none", errors)
	_require_equal(monetization, "gateway_script", "res://scripts/monetization_gateway.gd", errors)
	_require_existing_resource(str(monetization.get("gateway_script", "")), "monetization.gateway_script", errors)
	_require_equal(monetization, "scene_smoke_script", "res://scripts/validate_scene_loads.gd", errors)
	_require_existing_resource(str(monetization.get("scene_smoke_script", "")), "monetization.scene_smoke_script", errors)
	_require_equal(monetization, "default_provider_id", MonetizationGateway.DEFAULT_PROVIDER_ID, errors)
	_require_equal(monetization, "adapter_hook", "configure_continue_adapter(provider_id, Callable)", errors)
	_require_set_equals(Array(monetization.get("sources", [])), [MonetizationGateway.SOURCE_REWARDED_AD, MonetizationGateway.SOURCE_IAP, MonetizationGateway.SOURCE_COINS], "monetization.sources", errors)
	_require_set_equals(Array(monetization.get("results", [])), [MonetizationGateway.RESULT_COMPLETED, MonetizationGateway.RESULT_FAILED, MonetizationGateway.RESULT_PENDING], "monetization.results", errors)
	_require_equal(monetization, "unknown_result_policy", MonetizationGateway.RESULT_FAILED, errors)
	_require_equal(monetization, "unsupported_source_status", "rejected_invalid_source", errors)
	_require_equal(monetization, "provider_result_preservation", "details.provider_result", errors)
	_require_equal(monetization, "default_placement", MonetizationGateway.DEFAULT_PLACEMENT, errors)
	_require_equal(monetization, "default_reward_type", MonetizationGateway.DEFAULT_REWARD_TYPE, errors)
	_require_equal(monetization, "default_ad_network", MonetizationGateway.DEFAULT_AD_NETWORK, errors)
	_require_equal(monetization, "default_product_id", MonetizationGateway.DEFAULT_PRODUCT_ID, errors)
	_require_equal(monetization, "default_price", MonetizationGateway.DEFAULT_PRICE, errors)
	_require_equal(monetization, "default_currency", MonetizationGateway.DEFAULT_CURRENCY, errors)
	_require_equal(monetization, "max_request_log", MonetizationGateway.MAX_REQUEST_LOG, errors)
	_require_array_contains_all(
		Array(monetization.get("smoke_coverage", [])),
		[
			"request log source/stage_id/fail_reason/provider_id/status/result",
			"invalid source rejected_invalid_source",
			"queued result priority over adapter",
			"adapter deep-copy payload",
			"result alias canonicalization",
			"pending duplicate tap does not create second request",
			"provider_result preserves cancel semantics",
		],
		"monetization.smoke_coverage",
		errors
	)
	_validate_monetization_source_aliases(Dictionary(monetization.get("source_aliases", {})), errors)
	_validate_monetization_result_aliases(Dictionary(monetization.get("result_aliases", {})), errors)
	_validate_monetization_runtime_contract(errors)


func _validate_monetization_source_aliases(source_aliases: Dictionary, errors: PackedStringArray) -> void:
	var expected := {
		"rewarded": MonetizationGateway.SOURCE_REWARDED_AD,
		"purchase": MonetizationGateway.SOURCE_IAP,
		"coin": MonetizationGateway.SOURCE_COINS,
	}
	for alias in expected.keys():
		if str(source_aliases.get(alias, "")) != str(expected[alias]):
			errors.append("monetization.source_aliases.%s must be %s" % [alias, str(expected[alias])])
		if MonetizationGateway._normalize_source(alias) != str(expected[alias]):
			errors.append("MonetizationGateway source alias %s should normalize to %s" % [alias, str(expected[alias])])


func _validate_monetization_result_aliases(result_aliases: Dictionary, errors: PackedStringArray) -> void:
	var canonical_results := [MonetizationGateway.RESULT_COMPLETED, MonetizationGateway.RESULT_FAILED, MonetizationGateway.RESULT_PENDING]
	for canonical in canonical_results:
		var aliases := Array(result_aliases.get(canonical, []))
		if aliases.is_empty():
			errors.append("monetization.result_aliases.%s must not be empty" % canonical)
			continue
		if not aliases.has(canonical):
			errors.append("monetization.result_aliases.%s must include the canonical value" % canonical)
		for alias_value in aliases:
			var alias := str(alias_value)
			var normalized := MonetizationGateway._normalize_result(alias, MonetizationGateway.RESULT_FAILED)
			if normalized != canonical:
				errors.append("MonetizationGateway result alias %s should normalize to %s, got %s" % [alias, canonical, normalized])
	var unknown_result := MonetizationGateway._normalize_result("__unknown_provider_state__", MonetizationGateway.RESULT_PENDING)
	if unknown_result != MonetizationGateway.RESULT_FAILED:
		errors.append("MonetizationGateway unknown result should fail closed, got %s" % unknown_result)


func _validate_monetization_runtime_contract(errors: PackedStringArray) -> void:
	MonetizationGateway.reset_for_testing()
	var invalid_result := MonetizationGateway.request_continue("mystery_sdk", 1, {}, {})
	if str(invalid_result.get("request_status", "")) != "rejected_invalid_source":
		errors.append("unsupported monetization source should return rejected_invalid_source")
	if str(invalid_result.get("result", "")) != MonetizationGateway.RESULT_FAILED:
		errors.append("unsupported monetization source should return failed result")
	var success_alias := MonetizationGateway.request_continue(MonetizationGateway.SOURCE_REWARDED_AD, 1, {}, {"result": "success", "transaction_id": "provider-readiness-success"})
	if str(success_alias.get("result", "")) != MonetizationGateway.RESULT_COMPLETED:
		errors.append("provider readiness success alias should resolve to completed")
	if str(Dictionary(success_alias.get("details", {})).get("provider_result", "")) != "success":
		errors.append("provider readiness success alias should preserve details.provider_result")
	var pending_alias := MonetizationGateway.request_continue(MonetizationGateway.SOURCE_REWARDED_AD, 1, {}, {"result": "in_progress", "transaction_id": "provider-readiness-pending"})
	if str(pending_alias.get("result", "")) != MonetizationGateway.RESULT_PENDING:
		errors.append("provider readiness in_progress alias should resolve to pending")
	if str(Dictionary(pending_alias.get("details", {})).get("provider_result", "")) != "in_progress":
		errors.append("provider readiness pending alias should preserve details.provider_result")
	var unknown_alias := MonetizationGateway.request_continue(MonetizationGateway.SOURCE_REWARDED_AD, 1, {}, {"result": "sdk_weird_state", "transaction_id": "provider-readiness-unknown"})
	if str(unknown_alias.get("result", "")) != MonetizationGateway.RESULT_FAILED:
		errors.append("provider readiness unknown alias should resolve to failed")
	if str(Dictionary(unknown_alias.get("details", {})).get("provider_result", "")) != "sdk_weird_state":
		errors.append("provider readiness unknown alias should preserve details.provider_result")
	MonetizationGateway.reset_for_testing()


func _require_equal(source: Dictionary, key: String, expected, errors: PackedStringArray) -> void:
	if not source.has(key):
		errors.append("missing %s" % key)
		return
	var actual = source.get(key)
	if actual != expected:
		errors.append("%s must be %s, got %s" % [key, str(expected), str(actual)])


func _require_array_contains_all(actual: Array, expected: Array, label: String, errors: PackedStringArray) -> void:
	for expected_value in expected:
		if not actual.has(expected_value):
			errors.append("%s missing %s" % [label, str(expected_value)])


func _require_set_equals(actual: Array, expected: Array, label: String, errors: PackedStringArray) -> void:
	_require_array_contains_all(actual, expected, label, errors)
	for actual_value in actual:
		if not expected.has(actual_value):
			errors.append("%s has unexpected %s" % [label, str(actual_value)])


func _require_existing_resource(resource_path: String, label: String, errors: PackedStringArray) -> void:
	if resource_path.is_empty():
		errors.append("%s is empty" % label)
		return
	if not FileAccess.file_exists(resource_path):
		errors.append("%s does not exist: %s" % [label, resource_path])


func _require_existing_command_script(command: String, label: String, errors: PackedStringArray) -> void:
	var parts := command.split(" ", false)
	if parts.size() < 2:
		errors.append("%s must include a script path command, got %s" % [label, command])
		return
	if str(parts[0]) != "zsh":
		errors.append("%s must run through zsh, got %s" % [label, command])
	var script_path := str(parts[1])
	if not FileAccess.file_exists("res://%s" % script_path):
		errors.append("%s script does not exist: %s" % [label, script_path])


func _validate_no_production_provider_names(value, errors: PackedStringArray, path: String = "manifest") -> void:
	var blocked_terms := ["firebase", "gameanalytics", "admob", "unity ads", "unityads", "applovin", "ironsource", "revenuecat"]
	if value is Dictionary:
		for key in Dictionary(value).keys():
			_validate_no_production_provider_names(key, errors, "%s.%s" % [path, str(key)])
			_validate_no_production_provider_names(Dictionary(value)[key], errors, "%s.%s" % [path, str(key)])
	elif value is Array:
		var index := 0
		for item in Array(value):
			_validate_no_production_provider_names(item, errors, "%s[%d]" % [path, index])
			index += 1
	else:
		var text := str(value).strip_edges().to_lower()
		for blocked_term in blocked_terms:
			if text == blocked_term or text.contains("%s_" % blocked_term) or text.contains("%s:" % blocked_term):
				errors.append("%s must not select production provider '%s' before OPEN-007 is resolved" % [path, blocked_term])
