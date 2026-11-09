extends Node

## Sons do jogo, todos gerados por código (sem arquivos de áudio): efeitos de acerto, crítico,
## bloqueio, esquiva, dano no herói, moeda, nível e estrondo, e uma música calma em laço (acordes
## suaves e notas lentas). Os efeitos nascem na abertura; a música é montada aos poucos, alguns
## milhares de amostras por quadro, para não travar o menu nem a web.

const SFX_RATE := 22050
const MUSIC_RATE := 8000
## Cada acorde dura CHORD_SECONDS; a progressão tem 4 acordes e volta ao começo sem emenda.
const CHORD_SECONDS := 4.0
const CHORDS := 4
const NOTE_STEP := 2.0
const POLYPHONY := 10
const MUSIC_DB := -23.0
## Acordes (Lá menor, Fá, Dó, Sol): três notas do pad e a nota grave.
const PROGRESSION := [
	{"tones": [220.0, 261.63, 329.63], "bass": 110.0},
	{"tones": [174.61, 220.0, 261.63], "bass": 87.31},
	{"tones": [261.63, 329.63, 392.0], "bass": 130.81},
	{"tones": [196.0, 246.94, 293.66], "bass": 98.0},
]
const ARPEGGIO := [0, 2, 1, 2]
## Volume (dB) e intervalo mínimo (s) entre dois toques do mesmo efeito.
const SFX_SETTINGS := {
	"hit": {"db": -15.0, "gap": 0.08},
	"crit": {"db": -8.0, "gap": 0.12},
	"block": {"db": -13.0, "gap": 0.1},
	"dodge": {"db": -17.0, "gap": 0.15},
	"hurt": {"db": -9.0, "gap": 0.2},
	"coin": {"db": -18.0, "gap": 0.09},
	"level": {"db": -11.0, "gap": 0.3},
	"boom": {"db": -8.0, "gap": 0.25},
	"pop": {"db": -22.0, "gap": 0.1},
}

var sfx_enabled := true
var music_enabled := true
var music_ready := false
var music_progress := 0.0
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _last_played := {}
var _music: AudioStreamPlayer
var _music_samples := PackedFloat32Array()
var _music_index := 0
var _generating := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 12345
	for i in POLYPHONY:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB + linear_to_db(maxf(Settings.music, 0.0001))
	add_child(_music)
	_build_effects()
	_start_music_generation()


func has_sfx(sfx_name: String) -> bool:
	return _streams.has(sfx_name)


## Toca um efeito. `pitch` varia um pouco o tom para os golpes não soarem iguais.
func play(sfx_name: String, pitch_variation := 0.03) -> void:
	if sfx_name == "miss":
		sfx_name = "dodge"
	if not sfx_enabled or not _streams.has(sfx_name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var settings: Dictionary = SFX_SETTINGS[sfx_name]
	if now - float(_last_played.get(sfx_name, -10.0)) < float(settings["gap"]):
		return
	_last_played[sfx_name] = now
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _streams[sfx_name]
	if Settings.sfx <= 0.001:
		return
	player.volume_db = float(settings["db"]) + linear_to_db(Settings.sfx)
	player.pitch_scale = 1.0 + _rng.randf_range(-pitch_variation, pitch_variation)
	player.play()


func set_music_enabled(value: bool) -> void:
	music_enabled = value
	if not music_ready:
		return
	if value and not _music.playing:
		_music.play()
	elif not value:
		_music.stop()


func is_music_playing() -> bool:
	return _music != null and _music.playing


# --- Efeitos --------------------------------------------------------------------

func _build_effects() -> void:
	_streams["hit"] = _wave(_make_hit())
	_streams["crit"] = _wave(_make_crit())
	_streams["block"] = _wave(_make_block())
	_streams["dodge"] = _wave(_make_dodge())
	_streams["hurt"] = _wave(_make_hurt())
	_streams["coin"] = _wave(_make_coin())
	_streams["level"] = _wave(_make_level())
	_streams["boom"] = _wave(_make_boom())
	_streams["pop"] = _wave(_make_pop())


func _samples(seconds: float, rate := SFX_RATE) -> PackedFloat32Array:
	var data := PackedFloat32Array()
	data.resize(int(seconds * rate))
	return data


## Golpe comum: um "tum" grave curto com um estalo de ruído.
func _make_hit() -> PackedFloat32Array:
	var data := _samples(0.11)
	var smooth := 0.0
	for i in data.size():
		var t := float(i) / SFX_RATE
		smooth = lerpf(smooth, _rng.randf_range(-1.0, 1.0), 0.45)
		var thump := sin(TAU * (190.0 - 700.0 * t) * t) * exp(-t * 38.0)
		data[i] = (thump * 0.8 + smooth * exp(-t * 90.0) * 0.2)
	return data


## Crítico: o mesmo golpe, mais pesado, com um sino metálico por cima ("ding").
func _make_crit() -> PackedFloat32Array:
	var data := _samples(0.42)
	for i in data.size():
		var t := float(i) / SFX_RATE
		var thump := sin(TAU * (150.0 - 400.0 * minf(t, 0.1)) * t) * exp(-t * 26.0) * 0.9
		var click := _rng.randf_range(-1.0, 1.0) * exp(-t * 160.0) * 0.2
		var bell := sin(TAU * 784.0 * t) * 0.5 + sin(TAU * 1175.0 * t) * 0.25
		data[i] = thump + click + bell * exp(-t * 9.0) * 0.55
	return data


## Bloqueio: "tlim" de metal abafado.
func _make_block() -> PackedFloat32Array:
	var data := _samples(0.16)
	for i in data.size():
		var t := float(i) / SFX_RATE
		var ring := sin(TAU * 420.0 * t) * 0.5 + sin(TAU * 1130.0 * t) * 0.4 + sin(TAU * 1830.0 * t) * 0.25
		data[i] = ring * exp(-t * 30.0) * 0.7 + _rng.randf_range(-1.0, 1.0) * exp(-t * 150.0) * 0.4
	return data


## Esquiva: um sopro rápido (ruído que abre e fecha).
func _make_dodge() -> PackedFloat32Array:
	var data := _samples(0.2)
	var smooth := 0.0
	for i in data.size():
		var t := float(i) / SFX_RATE
		var progress := t / 0.2
		smooth = lerpf(smooth, _rng.randf_range(-1.0, 1.0), 0.08 + 0.5 * progress)
		data[i] = smooth * sin(PI * progress) * 0.8
	return data


## Dano no herói: um "ugh" grave que desce.
func _make_hurt() -> PackedFloat32Array:
	var data := _samples(0.26)
	for i in data.size():
		var t := float(i) / SFX_RATE
		var tone := sin(TAU * (150.0 - 220.0 * t) * t) * 0.8 + sin(TAU * (75.0 - 100.0 * t) * t) * 0.6
		data[i] = tone * exp(-t * 11.0) + _rng.randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.3
	return data


func _make_coin() -> PackedFloat32Array:
	var data := _samples(0.18)
	for i in data.size():
		var t := float(i) / SFX_RATE
		var first := sin(TAU * 988.0 * t) * exp(-t * 28.0)
		var second := sin(TAU * 1319.0 * maxf(t - 0.05, 0.0)) * exp(-maxf(t - 0.05, 0.0) * 22.0) if t > 0.05 else 0.0
		data[i] = (first + second) * 0.5
	return data


## Nível: quatro notas subindo (Dó, Mi, Sol, Dó).
func _make_level() -> PackedFloat32Array:
	var data := _samples(0.6)
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for n in notes.size():
		var start := n * 0.1
		for i in data.size():
			var t := float(i) / SFX_RATE - start
			if t < 0.0 or t > 0.4:
				continue
			data[i] += sin(TAU * float(notes[n]) * t) * exp(-t * 7.0) * 0.32
	return data


func _make_boom() -> PackedFloat32Array:
	var data := _samples(0.5)
	var smooth := 0.0
	for i in data.size():
		var t := float(i) / SFX_RATE
		smooth = lerpf(smooth, _rng.randf_range(-1.0, 1.0), 0.12)
		data[i] = sin(TAU * (70.0 - 80.0 * t) * t) * exp(-t * 7.0) * 0.9 + smooth * exp(-t * 14.0) * 0.5
	return data


func _make_pop() -> PackedFloat32Array:
	var data := _samples(0.09)
	for i in data.size():
		var t := float(i) / SFX_RATE
		data[i] = sin(TAU * (330.0 - 1400.0 * t) * t) * exp(-t * 40.0) * 0.7
	return data


func _wave(data: PackedFloat32Array, rate := SFX_RATE, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = data.size()
	return stream


# --- Música calma ---------------------------------------------------------------

func _start_music_generation() -> void:
	_music_samples.resize(int(CHORD_SECONDS * CHORDS * MUSIC_RATE))
	_music_index = 0
	_generating = true


func _process(_delta: float) -> void:
	if not _generating:
		return
	# Em partida, fatias menores: a música nunca pode pesar mais que o jogo.
	var scene := get_tree().current_scene
	var slice := 900 if scene != null and scene.name == "Game" else 3500
	var end := mini(_music_index + slice, _music_samples.size())
	for i in range(_music_index, end):
		_music_samples[i] = _music_sample(float(i) / MUSIC_RATE)
	_music_index = end
	music_progress = float(_music_index) / float(_music_samples.size())
	if _music_index >= _music_samples.size():
		_generating = false
		_music.stream = _wave(_music_samples, MUSIC_RATE, true)
		music_ready = true
		if music_enabled:
			_music.play()


## Uma amostra da música no instante `t` (segundos): pad de acordes que se fundem (janelas de
## Hann com 50% de sobreposição, então o laço não tem emenda), uma nota grave e notas lentas por cima.
func _music_sample(t: float) -> float:
	var loop_seconds := CHORD_SECONDS * CHORDS
	var segment := int(floor(t / CHORD_SECONDS))
	var frac := t / CHORD_SECONDS - float(segment)
	var first := segment - 1 if frac < 0.5 else segment
	var value := 0.0
	for k in 2:
		var chord_index := posmod(first + k, CHORDS)
		# Posição dentro da janela de 2 acordes que começa meio acorde antes do centro do acorde.
		var x := fposmod(t - (float(first + k) * CHORD_SECONDS - CHORD_SECONDS * 0.5), loop_seconds)
		var weight := sin(PI * x / (2.0 * CHORD_SECONDS))
		weight *= weight
		var chord: Dictionary = PROGRESSION[chord_index]
		var pad := 0.0
		for tone in chord["tones"]:
			pad += sin(TAU * float(tone) * t) * 0.085
		pad += sin(TAU * float(chord["bass"]) * t) * 0.16
		value += pad * weight
	# Notas lentas (um arpejo suave uma vez por segundo), cada uma com ataque curto e cauda longa.
	var note := int(floor(t / NOTE_STEP))
	for back in 2:
		var n := note - back
		var started := float(n) * NOTE_STEP
		var age := t - started
		var played_at := fposmod(started, loop_seconds)
		var chord_here: Dictionary = PROGRESSION[int(floor(played_at / CHORD_SECONDS)) % CHORDS]
		var pick: int = ARPEGGIO[posmod(n, ARPEGGIO.size())]
		var frequency := float(chord_here["tones"][pick]) * 2.0
		var envelope := minf(age / 0.03, 1.0) * exp(-age * 1.6)
		value += sin(TAU * frequency * age) * envelope * 0.08
	# Um respirar lento no volume deixa tudo mais calmo.
	value *= 0.9 + 0.1 * sin(TAU * t / loop_seconds * 2.0)
	return value * 0.85


## Aplica o volume da música das configurações (os efeitos leem o volume a cada toque).
func refresh_volumes() -> void:
	if _music == null:
		return
	_music.volume_db = MUSIC_DB + linear_to_db(maxf(Settings.music, 0.0001))
	_music.stream_paused = Settings.music <= 0.001
