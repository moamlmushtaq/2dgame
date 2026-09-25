extends Node
## Procedural audio: every sound effect and music loop is synthesised in code, so the
## game ships without audio files. Music is composed on a worker thread to avoid hitches.
## Press M to mute or unmute.

const RATE := 22050
const VOICES := 12
const MUSIC_DB := -10.0

enum Wave { SINE, SQUARE, TRIANGLE }

var muted := false
var _sfx := {}
var _voices: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _tracks := {}
var _wanted := ""
var _composing := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus("Music")
	_make_bus("SFX")
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	_music.bus = "Music"
	add_child(_music)
	_build_sfx()


func _exit_tree() -> void:
	for task in _composing.values():
		WorkerThreadPool.wait_for_task_completion(task)
	_composing.clear()
	_music.stop()
	_music.stream = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_M:
		muted = not muted
		AudioServer.set_bus_mute(0, muted)


## Volumes are 0..1 and come from the settings menu.
func set_volumes(music: float, sfx: float) -> void:
	_set_bus("Music", music)
	_set_bus("SFX", sfx)


func _make_bus(bus: String) -> void:
	if AudioServer.get_bus_index(bus) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus)
	AudioServer.set_bus_send(i, "Master")


func _set_bus(bus: String, volume: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(volume, 0.001)))
	AudioServer.set_bus_mute(i, volume <= 0.0)


func play(sound: String, volume_db := 0.0, pitch := 1.0, jitter := 0.06) -> void:
	if not _sfx.has(sound):
		return
	var p := _voices[_next]
	_next = (_next + 1) % VOICES
	p.stream = _sfx[sound]
	p.volume_db = volume_db
	p.pitch_scale = pitch * (1.0 + randf_range(-jitter, jitter))
	p.play()


## Starts a music loop ("voyage" or "island"), composing it in the background the first time.
func play_music(track: String) -> void:
	if _wanted == track:
		return
	_wanted = track
	if _tracks.has(track):
		_start_track(track)
	elif not _composing.has(track):
		_music.stop()
		_composing[track] = WorkerThreadPool.add_task(_compose_async.bind(track))


func stop_music() -> void:
	_wanted = ""
	_music.stop()


func _compose_async(track: String) -> void:
	var stream := _compose(track)
	_finish_compose.call_deferred(track, stream)


func _finish_compose(track: String, stream: AudioStreamWAV) -> void:
	if _composing.has(track):
		WorkerThreadPool.wait_for_task_completion(_composing[track])
		_composing.erase(track)
	_tracks[track] = stream
	if _wanted == track:
		_start_track(track)


func _start_track(track: String) -> void:
	_music.stream = _tracks[track]
	_music.volume_db = -40.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", MUSIC_DB, 1.5)


# --- Sound effects -----------------------------------------------------------

func _build_sfx() -> void:
	var b := _buf(0.14)
	_tone(b, 0.0, 0.14, 330.0, 640.0, 0.14, Wave.SQUARE, 0.004, 1.6)
	_sfx["jump"] = _wav(b)

	b = _buf(0.18)
	_noise(b, 0.0, 0.1, 0.45, 0.2, 2.0)
	_tone(b, 0.0, 0.14, 150.0, 80.0, 0.35, Wave.SINE, 0.002, 1.5)
	_sfx["coal"] = _wav(b)

	b = _buf(0.45)
	_noise(b, 0.0, 0.4, 0.3, 0.45, 1.0)
	_tone(b, 0.0, 0.3, 220.0, 520.0, 0.16, Wave.TRIANGLE, 0.01, 1.2)
	_sfx["feed"] = _wav(b)

	b = _buf(0.6)
	_noise(b, 0.0, 0.55, 0.7, 0.22, 2.5)
	_tone(b, 0.0, 0.4, 120.0, 38.0, 0.6, Wave.SINE, 0.002, 1.4)
	_sfx["cannon"] = _wav(b)

	b = _buf(0.9)
	_noise(b, 0.0, 0.85, 0.8, 0.12, 2.0)
	_noise(b, 0.05, 0.3, 0.35, 0.7, 3.0)
	_tone(b, 0.0, 0.7, 85.0, 28.0, 0.7, Wave.SINE, 0.002, 1.2)
	_sfx["crash"] = _wav(b)

	b = _buf(0.18)
	_noise(b, 0.0, 0.14, 0.5, 0.6, 3.0)
	_tone(b, 0.0, 0.07, 620.0, 210.0, 0.12, Wave.SQUARE, 0.002, 1.0)
	_sfx["crack"] = _wav(b)

	b = _buf(0.06)
	_tone(b, 0.0, 0.05, 1250.0, 900.0, 0.12, Wave.SQUARE, 0.001, 2.0)
	_noise(b, 0.0, 0.04, 0.25, 0.8, 2.0)
	_sfx["hammer"] = _wav(b)

	b = _buf(0.45)
	for i in 3:
		_tone(b, i * 0.08, 0.22, [523.0, 659.0, 784.0][i], [523.0, 659.0, 784.0][i], 0.2, Wave.TRIANGLE, 0.004, 1.5)
	_sfx["fixed"] = _wav(b)

	b = _buf(0.2)
	_tone(b, 0.0, 0.13, 1500.0, 650.0, 0.1, Wave.SQUARE, 0.002, 1.0)
	_noise(b, 0.02, 0.15, 0.25, 0.5, 2.0)
	_sfx["bird"] = _wav(b)

	b = _buf(0.9)
	_tone(b, 0.0, 0.8, 1568.0, 1568.0, 0.2, Wave.SINE, 0.002, 3.0)
	_tone(b, 0.07, 0.8, 2093.0, 2093.0, 0.15, Wave.SINE, 0.002, 3.0)
	_sfx["gem"] = _wav(b)

	b = _buf(1.6)
	_tone(b, 0.0, 1.5, 784.0, 784.0, 0.22, Wave.SINE, 0.002, 2.5)
	_tone(b, 0.0, 1.2, 1976.0, 1976.0, 0.07, Wave.SINE, 0.002, 3.5)
	_tone(b, 0.0, 0.9, 2637.0, 2637.0, 0.04, Wave.SINE, 0.002, 4.0)
	_sfx["bell"] = _wav(b)

	b = _buf(0.2)
	_noise(b, 0.0, 0.05, 0.35, 0.7, 2.0)
	_tone(b, 0.0, 0.06, 320.0, 200.0, 0.12, Wave.SQUARE, 0.001, 1.0)
	_tone(b, 0.09, 0.09, 170.0, 150.0, 0.2, Wave.TRIANGLE, 0.001, 1.5)
	_sfx["lever"] = _wav(b)

	b = _buf(0.05)
	_tone(b, 0.0, 0.04, 820.0, 820.0, 0.1, Wave.SQUARE, 0.001, 2.0)
	_sfx["click"] = _wav(b)

	b = _buf(0.3)
	_tone(b, 0.0, 0.1, 440.0, 440.0, 0.18, Wave.TRIANGLE, 0.003, 1.2)
	_tone(b, 0.08, 0.18, 660.0, 660.0, 0.18, Wave.TRIANGLE, 0.003, 1.2)
	_sfx["join"] = _wav(b)

	b = _buf(1.6)
	var fanfare := [523.0, 659.0, 784.0, 1047.0]
	for i in fanfare.size():
		var last := i == fanfare.size() - 1
		_tone(b, i * 0.13, 1.0 if last else 0.25, fanfare[i], fanfare[i], 0.2, Wave.TRIANGLE, 0.004, 1.3)
		_tone(b, i * 0.13, 1.0 if last else 0.25, fanfare[i] * 2.0, fanfare[i] * 2.0, 0.05, Wave.SINE, 0.004, 2.0)
	_sfx["win"] = _wav(b)

	b = _buf(1.4)
	_tone(b, 0.0, 1.3, 420.0, 90.0, 0.25, Wave.TRIANGLE, 0.01, 1.0)
	_noise(b, 0.0, 1.0, 0.5, 0.15, 1.5)
	_sfx["wreck"] = _wav(b)

	b = _buf(1.0)
	_noise(b, 0.0, 0.95, 0.6, 0.05, 1.0)
	_sfx["rumble"] = _wav(b)

	b = _buf(0.3)
	_tone(b, 0.0, 0.28, 300.0, 900.0, 0.15, Wave.SINE, 0.01, 1.0)
	_sfx["respawn"] = _wav(b)

	b = _buf(0.45)
	_tone(b, 0.0, 0.42, 760.0, 190.0, 0.15, Wave.SINE, 0.01, 1.0)
	_sfx["fall"] = _wav(b)

	b = _buf(0.8)
	_noise(b, 0.0, 0.8, 0.35, 0.3, 0.6)
	_sfx["wind"] = _wav(b)


# --- Music -------------------------------------------------------------------

## A short looping tune over I–V–vi–IV (voyage) or I–vi–IV–V (island) in C major.
func _compose(track: String) -> AudioStreamWAV:
	var voyage := track == "voyage"
	var bpm := 116.0 if voyage else 84.0
	var beat := 60.0 / bpm
	var bars := 8
	var b := _buf(bars * 4 * beat)
	var roots := [48, 43, 45, 41] if voyage else [48, 45, 41, 43]
	var scale := [60, 62, 64, 67, 69, 72, 74, 76, 79]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 if voyage else 11
	var idx := 4

	for bar in bars:
		var root: int = roots[bar % 4]
		var minor := root == 45
		var chord := [root, root + (3 if minor else 4), root + 7]
		var t0 := bar * 4 * beat

		# Bass.
		if voyage:
			for k in 4:
				var n: int = root if k % 2 == 0 else root + 12
				_tone(b, t0 + k * beat, beat * 0.9, _hz(n - 12), _hz(n - 12), 0.26, Wave.TRIANGLE, 0.005, 1.2)
		else:
			_tone(b, t0, beat * 1.9, _hz(root - 12), _hz(root - 12), 0.24, Wave.TRIANGLE, 0.02, 1.0)
			_tone(b, t0 + 2 * beat, beat * 1.9, _hz(root - 5), _hz(root - 5), 0.2, Wave.TRIANGLE, 0.02, 1.0)
			for n: int in chord:
				_tone(b, t0, beat * 4.0, _hz(n + 12), _hz(n + 12), 0.035, Wave.SINE, 0.4, 0.6)

		# Percussion on the voyage: kick on 1 and 3, hats on the off-beats.
		if voyage:
			for k in 4:
				if k % 2 == 0:
					_tone(b, t0 + k * beat, 0.16, 130.0, 45.0, 0.35, Wave.SINE, 0.001, 1.5)
				_noise(b, t0 + (k + 0.5) * beat, 0.035, 0.07, 1.0, 2.0)

		# Melody: eighth notes walking the pentatonic scale, landing on chord tones.
		for step in 8:
			if rng.randf() < (0.3 if voyage else 0.45) and step % 2 == 1:
				continue
			idx = clampi(idx + rng.randi_range(-2, 2), 0, scale.size() - 1)
			var note: int = scale[idx]
			if step % 4 == 0:
				note = _nearest(chord, note)
			var st := t0 + step * beat * 0.5
			if voyage:
				_tone(b, st, beat * 0.45, _hz(note), _hz(note), 0.08, Wave.SQUARE, 0.004, 1.8)
			else:
				_tone(b, st, beat * 1.2, _hz(note), _hz(note), 0.17, Wave.SINE, 0.004, 2.5)
				_tone(b, st, beat * 0.6, _hz(note + 12), _hz(note + 12), 0.04, Wave.SINE, 0.004, 3.0)
	return _wav(b, true)


func _nearest(chord: Array, note: int) -> int:
	var best := note
	var dist := 99
	for c: int in chord:
		for octave in [12, 24, 36]:
			var n: int = c + octave
			if absi(n - note) < dist:
				dist = absi(n - note)
				best = n
	return best


# --- Synthesis helpers -------------------------------------------------------

static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


static func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	b.fill(0.0)
	return b


## Adds a tone that slides from f0 to f1; `decay` shapes how fast it fades.
static func _tone(b: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, vol: float,
		wave: int, attack: float, decay: float) -> void:
	var s0 := int(start * RATE)
	var n := mini(int(dur * RATE), b.size() - s0)
	var phase := 0.0
	var inv_attack := 1.0 / (attack * RATE)
	for i in n:
		var k := float(i) / (dur * RATE)
		phase = fmod(phase + lerpf(f0, f1, k) / RATE, 1.0)
		var x: float
		if wave == Wave.SINE:
			x = sin(TAU * phase)
		elif wave == Wave.SQUARE:
			x = 0.6 if phase < 0.5 else -0.6
		else:
			x = 4.0 * absf(phase - 0.5) - 1.0
		b[s0 + i] += x * vol * minf(i * inv_attack, 1.0) * pow(1.0 - k, decay)


## Adds filtered white noise; `bright` 0..1 is a simple low-pass amount.
static func _noise(b: PackedFloat32Array, start: float, dur: float, vol: float, bright: float, decay: float) -> void:
	var s0 := int(start * RATE)
	var n := mini(int(dur * RATE), b.size() - s0)
	var y := 0.0
	for i in n:
		var k := float(i) / (dur * RATE)
		y += bright * (randf_range(-1.0, 1.0) - y)
		b[s0 + i] += y * vol * pow(1.0 - k, decay)


static func _wav(b: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(b.size() * 2)
	for i in b.size():
		bytes.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = b.size()
	return w
