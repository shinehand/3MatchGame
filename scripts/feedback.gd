extends Node

const SAMPLE_RATE := 44100
const PLAYER_POOL_SIZE := 6

var sound_enabled := true
var haptics_enabled := true

var _players: Array[AudioStreamPlayer] = []
var _streams := {}
var _player_index := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_players()
	_build_streams()


func play_ui_tap() -> void:
	_play_stream("ui_tap")
	_vibrate(12)


func play_swap_valid() -> void:
	_play_stream("swap_valid")
	_vibrate(18)


func play_swap_invalid() -> void:
	_play_stream("swap_invalid")
	_vibrate(28)


func play_match(combo: int, special_count: int, cleared_obstacles: int) -> void:
	if special_count > 0:
		_play_stream("special_ready")
	elif combo >= 2 or cleared_obstacles > 0:
		_play_stream("match_combo")
	else:
		_play_stream("match_small")

	var duration_ms := 18 + mini(combo, 3) * 6 + mini(special_count, 2) * 10 + mini(cleared_obstacles, 2) * 8
	_vibrate(duration_ms)


func play_shuffle() -> void:
	_play_stream("shuffle")
	_vibrate(20)


func play_stage_clear() -> void:
	_play_stream("stage_clear")
	_vibrate(55)


func play_stage_fail() -> void:
	_play_stream("stage_fail")
	_vibrate(40)


func _build_players() -> void:
	for _i in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -11.0
		add_child(player)
		_players.append(player)


func _build_streams() -> void:
	_streams["ui_tap"] = _make_stream([
		{"freq": 920.0, "duration_ms": 26, "gain": 0.18, "wave": "sine"},
		{"freq": 1280.0, "duration_ms": 18, "gain": 0.12, "wave": "sine"},
	])
	_streams["swap_valid"] = _make_stream([
		{"freq": 660.0, "duration_ms": 34, "gain": 0.17, "wave": "triangle"},
		{"freq": 880.0, "duration_ms": 42, "gain": 0.15, "wave": "sine"},
	])
	_streams["swap_invalid"] = _make_stream([
		{"freq": 420.0, "duration_ms": 42, "gain": 0.18, "wave": "sine"},
		{"freq": 320.0, "duration_ms": 68, "gain": 0.16, "wave": "triangle"},
	])
	_streams["match_small"] = _make_stream([
		{"freq": 620.0, "duration_ms": 28, "gain": 0.16, "wave": "triangle"},
		{"freq": 780.0, "duration_ms": 34, "gain": 0.14, "wave": "triangle"},
		{"freq": 1040.0, "duration_ms": 48, "gain": 0.12, "wave": "sine"},
	])
	_streams["match_combo"] = _make_stream([
		{"freq": 620.0, "duration_ms": 24, "gain": 0.18, "wave": "triangle"},
		{"freq": 880.0, "duration_ms": 30, "gain": 0.16, "wave": "triangle"},
		{"freq": 1170.0, "duration_ms": 42, "gain": 0.14, "wave": "sine"},
		{"freq": 1480.0, "duration_ms": 46, "gain": 0.11, "wave": "sine"},
	])
	_streams["special_ready"] = _make_stream([
		{"freq": 740.0, "duration_ms": 26, "gain": 0.17, "wave": "triangle"},
		{"freq": 980.0, "duration_ms": 30, "gain": 0.15, "wave": "triangle"},
		{"freq": 1240.0, "duration_ms": 36, "gain": 0.13, "wave": "sine"},
		{"freq": 1560.0, "duration_ms": 60, "gain": 0.12, "wave": "sine"},
	])
	_streams["shuffle"] = _make_stream([
		{"freq": 540.0, "duration_ms": 20, "gain": 0.12, "wave": "sine"},
		{"freq": 680.0, "duration_ms": 20, "gain": 0.12, "wave": "sine"},
		{"freq": 820.0, "duration_ms": 28, "gain": 0.11, "wave": "triangle"},
		{"freq": 980.0, "duration_ms": 40, "gain": 0.1, "wave": "sine"},
	])
	_streams["stage_clear"] = _make_stream([
		{"freq": 660.0, "duration_ms": 40, "gain": 0.17, "wave": "triangle"},
		{"freq": 880.0, "duration_ms": 44, "gain": 0.16, "wave": "triangle"},
		{"freq": 1100.0, "duration_ms": 50, "gain": 0.14, "wave": "sine"},
		{"freq": 1320.0, "duration_ms": 58, "gain": 0.13, "wave": "sine"},
		{"freq": 1580.0, "duration_ms": 110, "gain": 0.11, "wave": "sine"},
	])
	_streams["stage_fail"] = _make_stream([
		{"freq": 420.0, "duration_ms": 54, "gain": 0.17, "wave": "sine"},
		{"freq": 360.0, "duration_ms": 62, "gain": 0.15, "wave": "triangle"},
		{"freq": 300.0, "duration_ms": 90, "gain": 0.13, "wave": "sine"},
	])


func _play_stream(key: String) -> void:
	if not sound_enabled or _players.is_empty() or not _streams.has(key):
		return

	var player: AudioStreamPlayer = _players[_player_index % _players.size()]
	_player_index += 1
	player.stop()
	player.stream = _streams[key]
	player.pitch_scale = 1.0
	player.play()


func _vibrate(duration_ms: int) -> void:
	if not haptics_enabled:
		return
	# Android debug export currently lacks the VIBRATE permission.
	# Skip haptics there until permissions are wired up explicitly.
	if OS.has_feature("android"):
		return
	if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		return
	Input.vibrate_handheld(duration_ms)


func _make_stream(segments: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	for segment in segments:
		data.append_array(_build_tone_segment(
			float(segment.get("freq", 440.0)),
			int(segment.get("duration_ms", 60)),
			float(segment.get("gain", 0.2)),
			String(segment.get("wave", "sine"))
		))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _build_tone_segment(freq: float, duration_ms: int, gain: float, wave: String) -> PackedByteArray:
	var frame_count := maxi(1, int(SAMPLE_RATE * duration_ms / 1000.0))
	var attack := maxi(1, int(frame_count * 0.08))
	var release := maxi(1, int(frame_count * 0.16))
	var bytes := PackedByteArray()

	for frame in range(frame_count):
		var t := float(frame) / SAMPLE_RATE
		var phase := TAU * freq * t
		var sample := 0.0

		match wave:
			"square":
				sample = 1.0 if sin(phase) >= 0.0 else -1.0
			"triangle":
				sample = asin(sin(phase)) * (2.0 / PI)
			_:
				sample = sin(phase)

		var envelope := 1.0
		if frame < attack:
			envelope = float(frame) / attack
		elif frame > frame_count - release:
			envelope = float(frame_count - frame) / release

		var amplitude := clampf(sample * gain * envelope, -1.0, 1.0)
		var pcm := int(round(amplitude * 32767.0))
		pcm = clampi(pcm, -32768, 32767)
		var unsigned_pcm := pcm & 0xffff
		bytes.append(unsigned_pcm & 0xff)
		bytes.append((unsigned_pcm >> 8) & 0xff)

	return bytes
