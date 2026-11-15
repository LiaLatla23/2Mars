extends Node
## Estado global de ToMars: idioma, progreso, diseño actual del rover y guardado.

const SAVE_PATH := "user://tomars_save.json"

var lang := "en"
var rover_name := "ARES 01"
var zone := "geology"
var build: Dictionary = {}
var progress: Dictionary = {}      # zone -> {grade, science, runs}
var report: Dictionary = {}        # último informe de misión
var hints_seen: Dictionary = {}
var volume := 0.7
var main: Control
var save_enabled := true
var music: AudioStreamPlayer
var sounds := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	register_inputs()
	load_save()
	if build.is_empty(): build = Data.default_build()
	for id in ["click", "good", "bad", "data", "link", "done", "bump"]: sounds[id] = load("res://assets/audio/%s.wav" % id)
	var track: AudioStreamWAV = load("res://assets/audio/music.wav")
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_end = int(track.get_length() * track.mix_rate)
	music = AudioStreamPlayer.new()
	music.stream = track
	add_child(music)
	apply_volume()
	music.play()

func apply_volume() -> void:
	music.volume_db = linear_to_db(maxf(0.0001, volume * 0.55))

## Efecto de sonido corto (sintetizado para el juego).
func sfx(id: String, pitch: float = 1.0) -> void:
	if volume <= 0.01 or not sounds.has(id): return
	var player := AudioStreamPlayer.new()
	player.stream = sounds[id]
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(volume * 0.8)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

func register_inputs() -> void:
	var map := {
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E, KEY_SPACE], "transmit": [KEY_T], "pause": [KEY_ESCAPE],
		"confirm": [KEY_ENTER, KEY_SPACE], "weather": [KEY_M], "oxygen": [KEY_O], "radar": [KEY_R]
	}
	for action in map:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for code in map[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

## Texto bilingüe: t("English", "Español").
func t(en: String, es: String) -> String:
	return es if lang == "es" else en

func tt(pair: Array) -> String:
	return String(pair[1] if lang == "es" and pair.size() > 1 else pair[0])

func go(screen: String) -> void:
	if is_instance_valid(main): main.show_screen(screen)

func zone_unlocked(id: String) -> bool:
	var index := Data.ZONE_ORDER.find(id)
	if index <= 0: return true
	var previous: String = Data.ZONE_ORDER[index - 1]
	return progress.has(previous) and String(progress[previous].get("grade", "D")) in ["S", "A", "B", "C"]

func record(id: String, grade: String, science: int) -> void:
	var entry: Dictionary = progress.get(id, {"grade": "", "science": 0, "runs": 0})
	var order := "SABCD"
	if entry.grade == "" or order.find(grade) < order.find(String(entry.grade)): entry.grade = grade
	entry.science = maxi(int(entry.science), science)
	entry.runs = int(entry.runs) + 1
	progress[id] = entry
	save()

func total_science() -> int:
	var total := 0
	for id in progress: total += int(progress[id].get("science", 0))
	return total

func save() -> void:
	if not save_enabled: return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"lang": lang, "rover_name": rover_name, "build": build, "progress": progress, "hints": hints_seen, "volume": volume}))

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary: return
	lang = String(parsed.get("lang", lang))
	rover_name = String(parsed.get("rover_name", rover_name))
	if parsed.get("build") is Dictionary: build = parsed.build
	if parsed.get("progress") is Dictionary: progress = parsed.progress
	if parsed.get("hints") is Dictionary: hints_seen = parsed.hints
	volume = float(parsed.get("volume", volume))

func reset_progress() -> void:
	progress = {}
	hints_seen = {}
	build = Data.default_build()
	save()
