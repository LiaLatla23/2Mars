extends Node
## Estado global de 2Mars: ajustes, perfiles de guardado, diseño actual, plan de misión,
## logros, historial de misiones y audio.
##
## Guardado: user://2mars_save.json (3 archivos de campaña + Sandbox, separados).
## Compatibilidad: si existe el guardado antiguo de ToMars 1.0 (user://tomars_save.json) y no hay
## guardado nuevo, se importa al archivo 1 sin tocar el original.

const SAVE_PATH := "user://2mars_save.json"
const LEGACY_PATH := "user://tomars_save.json"
var save_path := SAVE_PATH       # las pruebas lo redirigen para no tocar partidas reales
var legacy_path := LEGACY_PATH
const SLOT_COUNT := 3

# Ajustes globales
var lang := "en"
var volume := 0.7          # volumen general (0 = silencio)
var music_volume := 0.7
var sfx_volume := 0.9
var input_mode := "both"   # mouse | keyboard | both
var reduced_motion := false
var setup_done := false    # el jugador ya eligió idioma y modo de entrada
var quality := 1           # calidad gráfica 3D: 0 baja · 1 media (por defecto) · 2 alta
var show_fps := false      # medidor de fotogramas (F3)

# Perfiles
var slots: Array = []
var slot := 0
var sandbox := {}

# Copia de trabajo del perfil activo (se vuelca al guardar)
var player_name := ""
var team_name := ""
var emblem := 0
var rover_name := "ARES 01"
var mission_name := ""
var build: Dictionary = {}
var plan: Dictionary = {}
var progress: Dictionary = {}      # zone -> {grade, science, runs}
var hints_seen: Dictionary = {}
var achievements: Dictionary = {}
var stories: Dictionary = {}
var history: Array = []
var tutorial: Dictionary = {}
var saved_rovers: Array = []
var discoveries: Dictionary = {}   # inventario científico: {"rocks": {tipo: {...}}, "tools": {id: misiones}}
var upgrades: Dictionary = {}      # mejoras compradas en este archivo (id -> true)

# Sesión (no se guarda)
var zone := "geology"
var report: Dictionary = {}        # último informe de misión
var mode := "campaign"             # campaign | sandbox
var coop := false
var coop_swapped := false          # false: J1 Comandante / J2 Ingeniero
var flight := {}                   # resultado del viaje: carga inicial, daño de aterrizaje, precisión
var location := "earth"            # base que muestra el hub: earth | mars
var library_return := "menu"       # a dónde vuelve la biblioteca
var last_issue := []               # hallazgos de readiness con los que se lanzó
var main: Control
var save_enabled := true
var music: AudioStreamPlayer
var tracks := {}
var decks: Array = []
var deck := 0
var track_id := ""
var fade: Tween
var sounds := {}
var unlocked_queue: Array = []
var last_hover := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	register_inputs()
	load_save()
	for id in ["click", "good", "bad", "data", "link", "done", "bump", "hover", "attach", "warn", "launch", "discover", "select", "reward", "error", "detach"]:
		var path := "res://assets/audio/%s.wav" % id
		if ResourceLoader.exists(path): sounds[id] = load(path)
	# Música (V4): cuatro temas originales sintetizados, con fundido cruzado entre ellos.
	for id in ["base", "explore", "tension", "resolve"]:
		var path := "res://assets/audio/music_%s.ogg" % id
		if not ResourceLoader.exists(path): continue
		var stream: AudioStreamOggVorbis = load(path)
		stream.loop = true
		tracks[id] = stream
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.volume_db = -60.0
		add_child(player)
		decks.append(player)
	music = decks[0]
	play_music("base", true)

## Cambia de tema con un fundido cruzado suave. Pedir el tema que ya suena no hace nada.
func play_music(id: String, instant: bool = false) -> void:
	if id == track_id or not tracks.has(id): return
	track_id = id
	var old: AudioStreamPlayer = decks[deck]
	deck = 1 - deck
	var fresh: AudioStreamPlayer = decks[deck]
	music = fresh
	fresh.stream = tracks[id]
	fresh.volume_db = -60.0
	fresh.play()
	if fade != null and fade.is_valid(): fade.kill()
	var level := music_db()
	if instant:
		fresh.volume_db = level
		old.stop()
		return
	fade = create_tween().set_parallel(true)
	fade.tween_property(fresh, "volume_db", level, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(old, "volume_db", -60.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade.chain().tween_callback(old.stop)

func music_db() -> float:
	return linear_to_db(maxf(0.0001, volume * music_volume * 0.5))

## Escala de render de las vistas 3D según la calidad elegida.
func render_scale() -> float:
	return [0.6, 0.85, 1.0][clampi(quality, 0, 2)]

func apply_volume() -> void:
	if fade != null and fade.is_valid(): fade.kill()
	for i in range(decks.size()): (decks[i] as AudioStreamPlayer).volume_db = music_db() if i == deck else -60.0

## Efecto de sonido corto (sintetizado para el juego).
func sfx(id: String, pitch: float = 1.0) -> void:
	var level := volume * sfx_volume * (0.35 if id == "hover" else 0.8)
	if not sounds.has(id): id = {"select": "click", "reward": "discover", "error": "bad", "detach": "attach"}.get(id, id)
	if level <= 0.01 or not sounds.has(id): return
	# el hover no se apila: como mucho uno cada 60 ms
	if id == "hover":
		var now := Time.get_ticks_msec()
		if now - last_hover < 60: return
		last_hover = now
	var player := AudioStreamPlayer.new()
	player.stream = sounds[id]
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(level)
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
		"p1_up": [KEY_UP], "p1_down": [KEY_DOWN], "p1_left": [KEY_LEFT], "p1_right": [KEY_RIGHT],
		"interact": [KEY_E, KEY_SPACE], "transmit": [KEY_T], "pause": [KEY_ESCAPE],
		"confirm": [KEY_ENTER, KEY_SPACE], "weather": [KEY_M], "oxygen": [KEY_O], "radar": [KEY_R],
		"autonav": [KEY_G], "data_panel": [KEY_TAB], "help": [KEY_H, KEY_F1], "skip": [KEY_ESCAPE, KEY_ENTER, KEY_SPACE],
		"p1_confirm": [KEY_ENTER, KEY_KP_ENTER], "p2_confirm": [KEY_F]
	}
	for action in map:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for code in map[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)
	# Mando (opcional, pensado para el Jugador 2 en cooperativo): A interactuar/confirmar, X transmitir, B pausa.
	var pad := {"interact": JOY_BUTTON_A, "p2_confirm": JOY_BUTTON_A, "transmit": JOY_BUTTON_X, "pause": JOY_BUTTON_START, "autonav": JOY_BUTTON_Y}
	for action in pad:
		var button := InputEventJoypadButton.new()
		button.button_index = pad[action]
		InputMap.action_add_event(action, button)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0], "move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in axes:
		var motion := InputEventJoypadMotion.new()
		motion.axis = axes[action][0]
		motion.axis_value = axes[action][1]
		InputMap.action_add_event(action, motion)

## Texto bilingüe: t("English", "Español").
func t(en: String, es: String) -> String:
	return es if lang == "es" else en

func tt(pair: Array) -> String:
	return String(pair[1] if lang == "es" and pair.size() > 1 else pair[0])

func owen() -> String:
	return t("Dr. Owen", "Dra. Owen")

func go(screen: String) -> void:
	if is_instance_valid(main): main.show_screen(screen)

func zone_unlocked(id: String) -> bool:
	if mode == "sandbox": return true
	var index := Data.ZONE_ORDER.find(id)
	if index <= 0: return true
	var previous: String = Data.ZONE_ORDER[index - 1]
	return progress.has(previous) and String(progress[previous].get("grade", "D")) in ["S", "A", "B", "C"]

func record(id: String, grade: String, science: int) -> void:
	if mode == "sandbox": return
	var entry: Dictionary = progress.get(id, {"grade": "", "science": 0, "runs": 0})
	var order := "SABCD"
	if entry.grade == "" or order.find(grade) < order.find(String(entry.grade)): entry.grade = grade
	entry.science = maxi(int(entry.science), science)
	entry.runs = int(entry.runs) + 1
	progress[id] = entry
	save()

## Inventario científico (V4): qué rocas estudió el rover y con qué, y qué instrumentos se usaron.
## Es un registro de trabajo de campo; los puntos de ciencia siguen midiendo datos RECIBIDOS.
func record_discoveries(zone_id: String, targets: Array, tools: Array) -> void:
	if mode == "sandbox": return
	var rocks: Dictionary = discoveries.get("rocks", {})
	for target in targets:
		var studied: bool = target.imaged or target.chem or target.pixl or target.sherloc or target.cached
		if not studied: continue
		var entry: Dictionary = rocks.get(String(target.type), {"photo": 0, "chem": 0, "contact": 0, "sample": 0, "zone": zone_id})
		if target.imaged: entry.photo = int(entry.photo) + 1
		if target.chem: entry.chem = int(entry.chem) + 1
		if target.pixl or target.sherloc: entry.contact = int(entry.contact) + 1
		if target.cached: entry.sample = int(entry.sample) + 1
		rocks[String(target.type)] = entry
	var used: Dictionary = discoveries.get("tools", {})
	for id in tools: used[String(id)] = int(used.get(String(id), 0)) + 1
	discoveries = {"rocks": rocks, "tools": used}
	save()

func total_science() -> int:
	var total := 0
	for id in progress: total += int(progress[id].get("science", 0))
	return total

## Porcentaje real de campaña: zonas completadas con nota C o mejor.
func campaign_percent(data: Dictionary = {}) -> int:
	var source: Dictionary = progress if data.is_empty() else data
	var done := 0
	for id in Data.ZONE_ORDER:
		if source.has(id) and String(source[id].get("grade", "D")) in ["S", "A", "B", "C"]: done += 1
	return int(100.0 * done / Data.ZONE_ORDER.size())

func limits() -> Dictionary:
	return Data.limits(active_plan())

func active_plan() -> Dictionary:
	if mode == "sandbox": return {"mass_cap": int(sandbox.get("mass_cap", 460)), "budget_cap": int(sandbox.get("budget_cap", 3200)), "profile": "explorer", "window": "optimal", "site": String(sandbox.get("site", "flat")), "priority": String(sandbox.get("priority", "context"))}
	return plan

# ------------------------------------------------------------------ mejoras
## Las mejoras son de la campaña: en Sandbox no se aplican (laboratorio con sus propios límites).
func has_upgrade(id: String) -> bool:
	return mode != "sandbox" and bool(upgrades.get(id, false))

func science_spent() -> int:
	var total := 0
	for id in upgrades:
		if Data.UPGRADES.has(id) and bool(upgrades[id]): total += int(Data.UPGRADES[id].cost)
	return total

## Puntos de ciencia disponibles: lo mejor recibido en la Tierra por zona menos lo ya invertido.
func science_points() -> int:
	return maxi(0, total_science() - science_spent())

func upgrade_state(id: String) -> String:
	if bool(upgrades.get(id, false)): return "owned"
	var info: Dictionary = Data.UPGRADES[id]
	var need := String(info.need)
	if need != "" and not (progress.has(need) and String(progress[need].get("grade", "D")) in ["S", "A", "B", "C"]): return "locked"
	return "ready" if science_points() >= int(info.cost) else "short"

func buy_upgrade(id: String) -> bool:
	if upgrade_state(id) != "ready": return false
	upgrades[id] = true
	sfx("reward")
	save()
	return true

# ------------------------------------------------------------------ logros
func unlock(id: String) -> void:
	if not Data.ACHIEVEMENTS.has(id) or achievements.has(id): return
	if mode == "sandbox" and id != "sandbox": return
	achievements[id] = true
	unlocked_queue.append(id)
	sfx("discover")
	save()

func hear_story(id: String) -> void:
	stories[id] = true
	unlock("curious")
	if stories.size() >= Data.STORY_ORDER.size(): unlock("historian")
	save()

func next_story() -> String:
	for id in Data.STORY_ORDER:
		if not stories.has(id): return id
	return Data.STORY_ORDER[randi() % Data.STORY_ORDER.size()]

func add_history(entry: Dictionary) -> void:
	if mode == "sandbox": return
	history.append(entry)
	while history.size() > 8: history.pop_front()
	save()

# ------------------------------------------------------------------ guardado
func blank_slot() -> Dictionary:
	return {"used": false, "player": "", "team": "", "emblem": 0, "rover_name": "ARES 01", "mission_name": "", "build": Data.default_build(),
		"plan": default_plan(), "progress": {}, "hints": {}, "achievements": {}, "stories": {}, "history": [], "tutorial": {}, "rovers": [], "upgrades": {}, "discoveries": {}}

func default_plan() -> Dictionary:
	return {"profile": "explorer", "window": "optimal", "site": "flat", "priority": "context"}

func default_sandbox() -> Dictionary:
	return {"build": Data.default_build(), "mass_cap": 460, "budget_cap": 3200, "zone": "geology", "site": "flat", "priority": "context"}

func sync_to_slot() -> void:
	if slots.is_empty(): return
	slots[slot] = {"used": bool(slots[slot].get("used", false)), "player": player_name, "team": team_name, "emblem": emblem, "rover_name": rover_name, "mission_name": mission_name,
		"build": build, "plan": plan, "progress": progress, "hints": hints_seen, "achievements": achievements, "stories": stories, "history": history, "tutorial": tutorial, "rovers": saved_rovers, "upgrades": upgrades, "discoveries": discoveries}

func select_slot(index: int) -> void:
	slot = clampi(index, 0, SLOT_COUNT - 1)
	var data: Dictionary = slots[slot]
	player_name = String(data.get("player", ""))
	team_name = String(data.get("team", ""))
	emblem = int(data.get("emblem", 0))
	rover_name = String(data.get("rover_name", "ARES 01"))
	mission_name = String(data.get("mission_name", ""))
	build = Data.migrate_build(data.get("build", {}) if data.get("build") is Dictionary else {})
	plan = default_plan()
	if data.get("plan") is Dictionary:
		for key in plan:
			if data.plan.has(key): plan[key] = String(data.plan[key])
	progress = data.get("progress", {}) if data.get("progress") is Dictionary else {}
	hints_seen = data.get("hints", {}) if data.get("hints") is Dictionary else {}
	achievements = data.get("achievements", {}) if data.get("achievements") is Dictionary else {}
	stories = data.get("stories", {}) if data.get("stories") is Dictionary else {}
	history = data.get("history", []) if data.get("history") is Array else []
	tutorial = data.get("tutorial", {}) if data.get("tutorial") is Dictionary else {}
	saved_rovers = data.get("rovers", []) if data.get("rovers") is Array else []
	upgrades = data.get("upgrades", {}) if data.get("upgrades") is Dictionary else {}
	discoveries = data.get("discoveries", {}) if data.get("discoveries") is Dictionary else {}
	location = "earth"
	mode = "campaign"

func start_slot(index: int, fresh: bool) -> void:
	if fresh: slots[index] = blank_slot()
	select_slot(index)
	slots[slot]["used"] = true
	save()

func save() -> void:
	if not save_enabled: return
	sync_to_slot()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"version": 2, "lang": lang, "volume": volume, "music": music_volume, "sfx": sfx_volume, "input": input_mode,
		"reduced_motion": reduced_motion, "setup_done": setup_done, "quality": quality, "slot": slot, "slots": slots, "sandbox": sandbox}))

func load_save() -> void:
	slots = []
	for i in range(SLOT_COUNT): slots.append(blank_slot())
	sandbox = default_sandbox()
	var parsed = null
	if FileAccess.file_exists(save_path): parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Dictionary:
		lang = String(parsed.get("lang", lang))
		volume = float(parsed.get("volume", volume))
		music_volume = float(parsed.get("music", music_volume))
		sfx_volume = float(parsed.get("sfx", sfx_volume))
		input_mode = String(parsed.get("input", input_mode))
		reduced_motion = bool(parsed.get("reduced_motion", false))
		setup_done = bool(parsed.get("setup_done", false))
		quality = clampi(int(parsed.get("quality", 1)), 0, 2)
		if parsed.get("slots") is Array:
			for i in range(mini(SLOT_COUNT, parsed.slots.size())):
				if parsed.slots[i] is Dictionary:
					var merged := blank_slot()
					merged.merge(parsed.slots[i], true)
					slots[i] = merged
		if parsed.get("sandbox") is Dictionary:
			sandbox.merge(parsed.sandbox, true)
			sandbox.build = Data.migrate_build(sandbox.build if sandbox.build is Dictionary else {})
		select_slot(int(parsed.get("slot", 0)))
		return
	# Guardado antiguo de ToMars 1.0 -> archivo 1.
	if FileAccess.file_exists(legacy_path):
		var old = JSON.parse_string(FileAccess.get_file_as_string(legacy_path))
		if old is Dictionary:
			lang = String(old.get("lang", lang))
			volume = float(old.get("volume", volume))
			var imported := blank_slot()
			imported.used = true
			imported.rover_name = String(old.get("rover_name", "ARES 01"))
			if old.get("build") is Dictionary: imported.build = Data.migrate_build(old.build)
			if old.get("progress") is Dictionary: imported.progress = old.progress
			if old.get("hints") is Dictionary: imported.hints = old.hints
			imported.tutorial = {"ops": true, "workshop": false, "intro": true}
			slots[0] = imported
	select_slot(0)

func reset_progress() -> void:
	slots[slot] = blank_slot()
	select_slot(slot)
	save()

func any_slot_used() -> bool:
	for data in slots:
		if bool(data.get("used", false)): return true
	return false
