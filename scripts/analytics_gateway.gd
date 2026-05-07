extends RefCounted

const DEFAULT_PROVIDER_ID := "local_buffer"
const MAX_DISPATCHED_EVENTS := 320

static var _provider_id := DEFAULT_PROVIDER_ID
static var _dispatch_enabled := true
static var _dispatched_events: Array = []
static var _rejected_events: Array = []


static func dispatch_event(event_entry: Dictionary, contract_valid: bool = true, rejection_reasons: PackedStringArray = PackedStringArray()) -> bool:
	var event := _normalize_event(event_entry)
	if not contract_valid:
		event["provider_id"] = _provider_id
		event["dispatch_status"] = "rejected_contract"
		event["rejection_reasons"] = Array(rejection_reasons)
		_append_bounded(_rejected_events, event)
		return false
	if not _dispatch_enabled:
		return false
	event["provider_id"] = _provider_id
	event["dispatch_status"] = "queued"
	_append_bounded(_dispatched_events, event)
	return true


static func get_dispatched_events_for_testing() -> Array:
	return _dispatched_events.duplicate(true)


static func get_rejected_events_for_testing() -> Array:
	return _rejected_events.duplicate(true)


static func clear_dispatched_events_for_testing() -> void:
	_dispatched_events.clear()


static func clear_rejected_events_for_testing() -> void:
	_rejected_events.clear()


static func set_provider_id_for_testing(provider_id: String) -> void:
	var normalized_provider := provider_id.strip_edges()
	_provider_id = DEFAULT_PROVIDER_ID if normalized_provider.is_empty() else normalized_provider


static func set_dispatch_enabled_for_testing(enabled: bool) -> void:
	_dispatch_enabled = enabled


static func reset_for_testing() -> void:
	_provider_id = DEFAULT_PROVIDER_ID
	_dispatch_enabled = true
	_dispatched_events.clear()
	_rejected_events.clear()


static func _normalize_event(event_entry: Dictionary) -> Dictionary:
	return {
		"name": String(event_entry.get("name", "")),
		"timestamp": int(event_entry.get("timestamp", Time.get_unix_time_from_system())),
		"params": Dictionary(event_entry.get("params", {})).duplicate(true),
	}


static func _append_bounded(events: Array, event: Dictionary) -> void:
	events.append(event)
	while events.size() > MAX_DISPATCHED_EVENTS:
		events.pop_front()
