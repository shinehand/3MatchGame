extends RefCounted

const DEFAULT_PROVIDER_ID := "local_buffer"
const DEFAULT_QUEUE_PATH := "user://analytics_gateway_queue.json"
const MAX_DISPATCHED_EVENTS := 320

static var _provider_id := DEFAULT_PROVIDER_ID
static var _dispatch_enabled := true
static var _flush_adapter: Callable = Callable()
static var _queue_path := DEFAULT_QUEUE_PATH
static var _queue_loaded := false
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
	_load_queue()
	event["provider_id"] = _provider_id
	event["dispatch_status"] = "queued"
	_append_bounded(_dispatched_events, event)
	_save_queue()
	return true


static func get_dispatched_events_for_testing() -> Array:
	_load_queue()
	return _dispatched_events.duplicate(true)


static func get_rejected_events_for_testing() -> Array:
	return _rejected_events.duplicate(true)


static func clear_dispatched_events_for_testing() -> void:
	_load_queue()
	_dispatched_events.clear()
	_save_queue()


static func clear_rejected_events_for_testing() -> void:
	_rejected_events.clear()


static func set_provider_id_for_testing(provider_id: String) -> void:
	_set_provider_id(provider_id)


static func configure_flush_adapter(provider_id: String, adapter: Callable) -> void:
	_set_provider_id(provider_id)
	_flush_adapter = adapter


static func clear_flush_adapter_for_testing() -> void:
	_flush_adapter = Callable()


static func _set_provider_id(provider_id: String) -> void:
	var normalized_provider := provider_id.strip_edges()
	_provider_id = DEFAULT_PROVIDER_ID if normalized_provider.is_empty() else normalized_provider


static func set_dispatch_enabled_for_testing(enabled: bool) -> void:
	_dispatch_enabled = enabled


static func use_queue_path_for_testing(queue_path: String) -> void:
	var normalized_path := queue_path.strip_edges()
	_queue_path = DEFAULT_QUEUE_PATH if normalized_path.is_empty() else normalized_path
	_queue_loaded = false
	_dispatched_events.clear()


static func reload_queue_from_disk_for_testing() -> void:
	_queue_loaded = false
	_dispatched_events.clear()
	_load_queue()


static func clear_persisted_queue_for_testing() -> void:
	_queue_loaded = true
	_dispatched_events.clear()
	_save_queue()
	_remove_queue_file()


static func flush_queued_events(send_callback: Callable = Callable(), max_count: int = -1) -> Array:
	_load_queue()
	var sent_events: Array = []
	var remaining_events: Array = []
	var flush_limit := _dispatched_events.size() if max_count < 0 else max_count
	var effective_callback := send_callback if send_callback.is_valid() else _flush_adapter
	var stop_flush := false
	for event_value in _dispatched_events:
		var event := Dictionary(event_value).duplicate(true)
		if stop_flush or sent_events.size() >= flush_limit:
			remaining_events.append(event)
			continue
		var send_event := event.duplicate(true)
		send_event["dispatch_status"] = "sent"
		if _send_callback_accepts_event(effective_callback, send_event):
			sent_events.append(send_event)
		else:
			remaining_events.append(event)
			stop_flush = true
	_dispatched_events = remaining_events
	_save_queue()
	return sent_events


static func reset_for_testing() -> void:
	_provider_id = DEFAULT_PROVIDER_ID
	_dispatch_enabled = true
	_flush_adapter = Callable()
	_queue_loaded = false
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


static func _send_callback_accepts_event(send_callback: Callable, event: Dictionary) -> bool:
	if not send_callback.is_valid():
		return true
	var result = send_callback.call(event.duplicate(true))
	if result is bool:
		return bool(result)
	if result is Dictionary:
		return bool(Dictionary(result).get("accepted", true))
	return true


static func _load_queue() -> void:
	if _queue_loaded:
		return
	_queue_loaded = true
	_dispatched_events.clear()
	if not FileAccess.file_exists(_queue_path):
		return
	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(_queue_path))
	if parse_error != OK:
		return
	var parsed = json.data
	if not (parsed is Array):
		return
	for event_value in Array(parsed):
		if not (event_value is Dictionary):
			continue
		var event: Dictionary = Dictionary(event_value).duplicate(true)
		_dispatched_events.append(event)
	while _dispatched_events.size() > MAX_DISPATCHED_EVENTS:
		_dispatched_events.pop_front()


static func _save_queue() -> void:
	DirAccess.make_dir_recursive_absolute("user://")
	var file := FileAccess.open(_queue_path, FileAccess.WRITE)
	if file == null:
		push_warning("AnalyticsGateway: failed to persist local queue.")
		return
	file.store_string(JSON.stringify(_dispatched_events, "\t"))


static func _remove_queue_file() -> void:
	if not FileAccess.file_exists(_queue_path):
		return
	var file_name := _queue_path.get_file()
	var directory_path := _queue_path.get_base_dir()
	var queue_dir := DirAccess.open(directory_path)
	if queue_dir == null:
		return
	var remove_error := queue_dir.remove(file_name)
	if remove_error != OK:
		# A locked user:// file can fail removal in headless validation; the queue was already
		# overwritten to [] by clear_persisted_queue_for_testing, so keep the cleanup best-effort.
		return
