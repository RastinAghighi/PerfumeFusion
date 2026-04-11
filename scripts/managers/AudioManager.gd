extends Node

const SAMPLE_RATE: int = 22050
const BGM_GROUP: String = "bgm"

var music_volume: float = 0.8
var sfx_volume: float = 1.0
var muted: bool = false

var _streams: Dictionary = {}


func _ready() -> void:
	_streams["merge"] = _make_pop()
	_streams["pickup"] = _make_click(0.04, 900.0, 0.35)
	_streams["drop"] = _make_thud()
	_streams["unlock"] = _make_chime()
	_streams["button"] = _make_click(0.03, 1400.0, 0.3)
	_streams["essence"] = _make_clink()
	_streams["rare_drop"] = _make_whoosh()
	_streams["frenzy"] = _make_powerup()
	_load_prefs()


# ---------- public API ----------

func set_music_volume(vol: float) -> void:
	music_volume = clamp(vol, 0.0, 1.0)
	_apply_music_volume()
	_save_prefs()


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clamp(vol, 0.0, 1.0)
	_save_prefs()


func set_mute(m: bool) -> void:
	muted = m
	_apply_music_volume()
	_save_prefs()


func toggle_mute() -> bool:
	set_mute(not muted)
	return muted


func register_bgm_player(player: AudioStreamPlayer) -> void:
	if not player.is_in_group(BGM_GROUP):
		player.add_to_group(BGM_GROUP)
	_apply_music_volume()


func _apply_music_volume() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var effective: float = 0.0 if muted else music_volume
	var db: float = linear_to_db(max(effective, 0.0001))
	for n in tree.get_nodes_in_group(BGM_GROUP):
		if n is AudioStreamPlayer:
			(n as AudioStreamPlayer).volume_db = db


func _load_prefs() -> void:
	var audio: Dictionary = SaveManager.data.get("audio", {})
	music_volume = clamp(float(audio.get("music_volume", 0.8)), 0.0, 1.0)
	sfx_volume = clamp(float(audio.get("sfx_volume", 1.0)), 0.0, 1.0)
	muted = bool(audio.get("muted", false))
	call_deferred("_apply_music_volume")


func _save_prefs() -> void:
	SaveManager.data["audio"] = {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"muted": muted,
	}
	SaveManager.save_game()


func play_merge() -> void: _play("merge")
func play_pickup() -> void: _play("pickup", 0.7)
func play_drop() -> void: _play("drop", 0.8)
func play_unlock() -> void: _play("unlock", 1.1)
func play_button() -> void: _play("button", 0.6)
func play_essence() -> void: _play("essence", 0.6)
func play_rare_drop() -> void: _play("rare_drop")
func play_frenzy() -> void: _play("frenzy", 1.1)


func _play(key: String, volume_scale: float = 1.0) -> void:
	if muted or sfx_volume <= 0.0:
		return
	var stream: AudioStream = _streams.get(key)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(clamp(sfx_volume * volume_scale, 0.0001, 1.0))
	get_tree().root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# ---------- procedural sound generation ----------

func _make_stream(buf: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SAMPLE_RATE
	s.stereo = false
	s.data = buf
	return s


func _append(buf: PackedByteArray, val: float) -> void:
	val = clamp(val, -1.0, 1.0)
	var v: int = int(val * 32767.0)
	if v < 0:
		v += 65536
	buf.append(v & 0xff)
	buf.append((v >> 8) & 0xff)


func _make_pop() -> AudioStreamWAV:
	var duration: float = 0.18
	var n: int = int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(0)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var freq: float = 480.0 + 700.0 * (1.0 - t / duration)
		var env: float = exp(-t * 14.0)
		var s: float = sin(TAU * freq * t) * env * 0.6
		_append(buf, s)
	return _make_stream(buf)


func _make_click(duration: float, freq: float, amp: float) -> AudioStreamWAV:
	var n: int = int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 60.0)
		var s: float = sin(TAU * freq * t) * env * amp
		_append(buf, s)
	return _make_stream(buf)


func _make_thud() -> AudioStreamWAV:
	var duration: float = 0.12
	var n: int = int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var freq: float = 140.0 - 60.0 * (t / duration)
		var env: float = exp(-t * 25.0)
		var s: float = sin(TAU * freq * t) * env * 0.55
		_append(buf, s)
	return _make_stream(buf)


func _make_chime() -> AudioStreamWAV:
	var duration: float = 0.8
	var n: int = int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	var freqs := [784.0, 988.0, 1175.0, 1568.0]  # G5, B5, D6, G6
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 3.2)
		var s: float = 0.0
		for k in range(freqs.size()):
			var start: float = float(k) * 0.06
			if t >= start:
				var lt: float = t - start
				s += sin(TAU * float(freqs[k]) * lt) * exp(-lt * 4.0)
		s = s * 0.18 * env
		_append(buf, s)
	return _make_stream(buf)


func _make_clink() -> AudioStreamWAV:
	var duration: float = 0.25
	var n: int = int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 18.0)
		var s: float = sin(TAU * 2200.0 * t) * 0.3 + sin(TAU * 3300.0 * t) * 0.2
		s *= env
		_append(buf, s)
	return _make_stream(buf)


func _make_whoosh() -> AudioStreamWAV:
	var duration: float = 0.5
	var n: int = int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	var noise: float = 0.0
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = sin(PI * t / duration)
		noise = noise * 0.85 + randf_range(-1.0, 1.0) * 0.15
		var tone: float = sin(TAU * (200.0 + 400.0 * (t / duration)) * t) * 0.2
		var s: float = (noise * 0.5 + tone) * env * 0.5
		_append(buf, s)
	return _make_stream(buf)


func _make_powerup() -> AudioStreamWAV:
	var duration: float = 0.45
	var n: int = int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var freq: float = 300.0 + 1200.0 * (t / duration)
		var env: float = 1.0
		if t < 0.05:
			env = t / 0.05
		elif t > duration - 0.1:
			env = max(0.0, (duration - t) / 0.1)
		var s: float = sin(TAU * freq * t) * 0.35
		s += sin(TAU * freq * 1.5 * t) * 0.15
		_append(buf, s * env)
	return _make_stream(buf)
