extends Control
## ETAPA 2 · MISSION OPERATIONS. Conducir, investigar, almacenar y transmitir.
## Regla central: la ciencia solo cuenta cuando la Tierra la recibe.

const WORLD := Vector2(3000, 2000)
const DAY := 100.0
const NIGHT := 45.0
const PASS_PERIOD := 60.0
const PASS_LENGTH := 22.0
const FIRST_PASS := 28.0
const ZOOM := 1.3
const LANDING := Vector2(520, 1000)

var zone: Dictionary
var build: Dictionary
var stats: Dictionary
var has: Array = []
var rng := RandomNumberGenerator.new()

var pos := Vector2(520, 1000)
var vel := Vector2.ZERO
var heading := 0.0
var energy := 100.0
var integrity := 100.0
var dust := 0.0
var safe_mode := false
var clock := 0.0
var time := 0.0
var bump_cooldown := 0.0

var packets: Array = []
var collected_mb := 0.0
var received_mb := 0.0
var received_science := 0.0
var transmitting := false
var tubes := 4
var cached: Array = []
var meda_on := false
var meda_timer := 0.0
var meda_packets := 0
var moxie_timer := -1.0
var moxie_runs := 0
var rimfax_scans := 0
var quiz_done := {}
var quiz_correct := 0
var quiz_asked := 0
var energy_used := 0.0

var obstacles: Array = []
var targets: Array = []
var sites: Array = []
var patches: Array = []
var devils: Array = []
var pebbles: Array = []
var shards: Array = []
var tracks: Array = []
var storm_start := -1.0
var storm_end := -1.0

var mode := "brief"   # brief | drive | menu | minigame | card | paused | ended
var focus: Dictionary = {}
var dialog: Control
var game: Dictionary = {}
var toasts: Array = []
var told := {}
var all_done_announced := false
var confirmable := false
var hotkeys: Array = []   # botones del diálogo abierto, elegibles con 1-5

func _ready() -> void:
	zone = Data.ZONES[Game.zone]
	build = Game.build
	stats = Data.stats(build)
	has = build.get("instruments", [])
	rng.seed = hash(Game.zone) + 7
	energy = float(stats.battery)
	if not "arm" in has: tubes = 0
	generate()
	show_brief()

# ------------------------------------------------------------------ mundo
func free_spot(margin: float, clearance: float) -> Vector2:
	for attempt in range(200):
		var point := Vector2(rng.randf_range(margin, WORLD.x - margin), rng.randf_range(margin, WORLD.y - margin))
		if point.distance_to(pos) < 330: continue
		var ok := true
		for item in obstacles + targets + sites:
			if point.distance_to(item.pos) < clearance + float(item.get("r", 40)): ok = false
		if ok: return point
	return Vector2(rng.randf_range(margin, WORLD.x - margin), rng.randf_range(margin, WORLD.y - margin))

func generate() -> void:
	var ground := Color(String(zone.ground))
	for i in range(46):
		pebbles.append({"points": Art.blob(Vector2(rng.randf_range(0, WORLD.x), rng.randf_range(0, WORLD.y)), rng.randf_range(90, 320), rng.randf_range(60, 200), i, 9, 0.2), "color": Art.shade(ground, rng.randf_range(-0.07, 0.08))})
	for i in range(420):
		var at := Vector2(rng.randf_range(0, WORLD.x), rng.randf_range(0, WORLD.y))
		var reach := rng.randf_range(5, 13)
		var turn := rng.randf() * TAU
		shards.append({"pos": at, "points": PackedVector2Array([at + Vector2.from_angle(turn) * reach, at + Vector2.from_angle(turn + 2.2) * reach * 0.8, at + Vector2.from_angle(turn + 4.1) * reach * 0.9]), "color": Art.shade(ground, rng.randf_range(-0.3, -0.12) if i % 3 > 0 else 0.14)})
	var hazards: Array = zone.hazards
	var kinds: Array = []
	if "sharp" in hazards: kinds += ["sharp", "sharp", "sharp", "sharp"]
	if "sand" in hazards: kinds += ["sand", "sand", "sand"]
	if "cold" in hazards: kinds += ["cold", "cold", "cold"]
	for kind in kinds:
		var center := free_spot(260, 0)
		var rx := rng.randf_range(170, 280)
		var ry := rng.randf_range(120, 200)
		patches.append({"kind": kind, "pos": center, "rx": rx, "ry": ry, "points": Art.blob(center, rx, ry, patches.size() + 3, 11, 0.15), "seed": patches.size()})
	for id in zone.rocks:
		for n in range(int(zone.rocks[id])):
			targets.append({"type": id, "pos": free_spot(240, 230), "r": rng.randf_range(30, 40), "seed": rng.randi() % 1000, "imaged": false, "chem": false, "pixl": false, "sherloc": false, "cached": false})
	for i in range(int(zone.sites)):
		sites.append({"pos": free_spot(300, 260), "r": 70.0, "scanned": false})
	for i in range(64):
		obstacles.append({"pos": free_spot(60, 70), "r": rng.randf_range(18, 56), "seed": rng.randi() % 1000, "color": Art.shade(ground, rng.randf_range(-0.34, -0.18))})
	if "devils" in hazards:
		for i in range(3): devils.append({"pos": free_spot(200, 0), "dir": Vector2.from_angle(rng.randf() * TAU), "r": 46.0, "cool": 0.0, "turn": rng.randf_range(2, 5)})
	if "storm" in hazards:
		storm_start = float(zone.time) * 0.34
		storm_end = storm_start + 55.0

func light() -> float:
	var phase := fmod(clock + 12.0, DAY + NIGHT)
	if phase < DAY: return clampf(minf(phase, DAY - phase) / 8.0, 0.0, 1.0)
	return 0.0

func storming() -> bool:
	return storm_start >= 0.0 and clock >= storm_start and clock < storm_end

func pass_open() -> bool:
	return clock >= FIRST_PASS and fmod(clock - FIRST_PASS, PASS_PERIOD) < PASS_LENGTH

func link_rate() -> float:
	var rate := 0.0
	if pass_open(): rate = 6.0
	elif stats.direct: rate = 1.4
	return rate * (0.5 if storming() else 1.0)

func memory_used() -> float:
	var total := 0.0
	for packet in packets: total += float(packet.mb) - float(packet.sent)
	return total

func patch_at(point: Vector2, kind: String) -> bool:
	for patch in patches:
		if patch.kind != kind: continue
		var offset: Vector2 = point - patch.pos
		if pow(offset.x / float(patch.rx), 2) + pow(offset.y / float(patch.ry), 2) < 0.8: return true
	return false

# ------------------------------------------------------------------ bucle
func _process(delta: float) -> void:
	time += delta
	for toast in toasts: toast.age += delta
	toasts = toasts.filter(func(item: Dictionary) -> bool: return item.age < 7.0)
	if mode == "minigame": update_minigame(delta)
	if mode in ["drive", "menu"]:
		clock += delta
		simulate(delta)
	queue_redraw()

func simulate(delta: float) -> void:
	bump_cooldown = maxf(0.0, bump_cooldown - delta)
	var wish := Vector2.ZERO
	if mode == "drive" and not safe_mode and moxie_timer < 0.0:
		wish = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := float(stats.speed)
	var in_sand := patch_at(pos, "sand")
	var rugged: bool = String(build.wheels) == "rugged"
	if in_sand: speed *= 0.85 if rugged else 0.5
	if integrity < 40.0: speed *= 0.8
	vel = vel.lerp(wish * speed, clampf(delta * 6.0, 0.0, 1.0))
	if wish != Vector2.ZERO and transmitting:
		transmitting = false
		say(Game.t("Transmission paused: the antenna needs the rover to hold still.", "Transmisión en pausa: la antena necesita que el rover esté quieto."))
	var moving := vel.length() > 8.0
	if moving:
		heading = lerp_angle(heading, vel.angle(), clampf(delta * 8.0, 0.0, 1.0))
		pos += vel * delta
		collide()
		if tracks.is_empty() or tracks[-1].distance_to(pos) > 26.0:
			tracks.append(pos)
			if tracks.size() > 90: tracks.pop_front()
		if patch_at(pos, "sharp"):
			integrity -= 2.4 * float(stats.wear) * delta
			tell("sharp", Game.t("Sharp rocks are chewing the wheels. Slow down or go around.", "Las rocas afiladas están dañando las ruedas. Reduce la marcha o rodéalas."))
		if in_sand: tell("sand", Game.t("Soft sand: slow and costly. Spirit was trapped in sand like this.", "Arena blanda: lenta y costosa. Spirit quedó atrapado en arena así."))
	pos = pos.clamp(Vector2(40, 40), WORLD - Vector2(40, 40))
	# Energía
	var sun := light()
	var drain := 0.2
	if moving: drain += float(stats.drive_cost) * (vel.length() / maxf(1.0, float(stats.speed))) * (1.6 if in_sand else 1.0)
	if sun <= 0.01: drain += 0.25 if not stats.solar else 0.8
	if patch_at(pos, "cold"):
		drain += 0.3 if not stats.solar else 0.9
		tell("cold", Game.t("Cold shadow: the heaters are working hard to protect the electronics.", "Sombra fría: los calentadores trabajan duro para proteger la electrónica."))
	if meda_on: drain += 0.3
	if transmitting: drain += 1.0
	if moxie_timer >= 0.0: drain += 40.0 / 14.0
	var charge := 1.35
	if stats.solar: charge = 2.5 * sun * (1.0 - dust * 0.7) * (0.3 if storming() else 1.0)
	energy_used += drain * delta
	energy = clampf(energy + (charge - drain) * delta, 0.0, float(stats.battery))
	if stats.solar: dust = minf(1.0, dust + delta / (130.0 if storming() else 520.0))
	if energy <= 0.0 and not safe_mode:
		safe_mode = true
		transmitting = false
		meda_on = false
		moxie_timer = -1.0
		say(Game.t("Battery empty. Safe mode: waiting for power to return.", "Batería agotada. Modo seguro: esperando a que vuelva la energía."))
	if safe_mode and energy >= 16.0:
		safe_mode = false
		say(Game.t("Power restored. Systems back online.", "Energía restablecida. Sistemas en línea otra vez."))
	if energy < float(stats.battery) * 0.22: tell("low", Game.t("Energy is low. Stop and recharge before the next task.", "Poca energía. Detente y recarga antes de la próxima tarea."))
	if sun <= 0.01: tell("night", Game.t("Night on Mars. Solar panels give nothing and heaters cost energy.", "Noche en Marte. Los paneles no dan nada y los calentadores gastan energía.") if stats.solar else Game.t("Night on Mars. The generator keeps the rover alive.", "Noche en Marte. El generador mantiene vivo al rover."))
	update_devils(delta)
	update_systems(delta)
	if storm_start >= 0.0:
		if meda_on and clock > storm_start - 20.0 and clock < storm_start: tell("storm_warn", Game.t("MEDA: pressure dropping. A dust storm arrives in seconds.", "MEDA: la presión cae. Una tormenta de polvo llega en segundos."))
		if storming(): tell("storm", Game.t("Dust storm. Less sunlight and a weaker link until it passes.", "Tormenta de polvo. Menos luz solar y un enlace más débil hasta que pase."))
	if integrity <= 0.0: finish("wheels")
	elif clock >= float(zone.time): finish("time")
	elif not all_done_announced and all_objectives_done():
		all_done_announced = true
		Game.sfx("done")
		say(Game.t("All objectives complete! Press Esc to end the mission, or keep exploring.", "¡Todos los objetivos completos! Pulsa Esc para terminar la misión, o sigue explorando."))

func collide() -> void:
	for item in obstacles + targets:
		var reach: float = float(item.r) * 0.82 + 20.0
		var offset: Vector2 = pos - item.pos
		if offset.length() < reach:
			pos = item.pos + offset.normalized() * reach
			if vel.length() > float(stats.speed) * 0.6 and bump_cooldown <= 0.0:
				integrity -= 1.5 * float(stats.wear)
				bump_cooldown = 0.7
				Game.sfx("bump")
			vel *= 0.5

func update_devils(delta: float) -> void:
	for devil in devils:
		devil.turn -= delta
		devil.cool = maxf(0.0, float(devil.cool) - delta)
		if devil.turn <= 0.0:
			devil.dir = Vector2.from_angle(rng.randf() * TAU)
			devil.turn = rng.randf_range(3, 7)
		devil.pos += devil.dir * 62.0 * delta
		if devil.pos.x < 80 or devil.pos.x > WORLD.x - 80: devil.dir.x *= -1.0
		if devil.pos.y < 80 or devil.pos.y > WORLD.y - 80: devil.dir.y *= -1.0
		devil.pos = devil.pos.clamp(Vector2(80, 80), WORLD - Vector2(80, 80))
		var gap: float = pos.distance_to(devil.pos)
		if meda_on and gap < 420.0: tell("devil_warn", Game.t("MEDA: wind vortex nearby.", "MEDA: vórtice de viento cerca."))
		if gap < float(devil.r) + 22.0 and devil.cool <= 0.0:
			devil.cool = 4.0
			integrity -= 3.0 * float(stats.wear)
			vel += devil.dir * 160.0
			if stats.solar and dust > 0.12:
				dust = 0.0
				say(Game.t("A dust devil swept the solar panels clean! Real rovers got these 'cleaning events' too.", "¡Un remolino limpió los paneles solares! Los rovers reales también tuvieron estos 'eventos de limpieza'."))
			else: say(Game.t("Dust devil! A small knock for the rover.", "¡Remolino de polvo! Un pequeño golpe para el rover."))

func update_systems(delta: float) -> void:
	if meda_on:
		meda_timer += delta
		if meda_timer >= 14.0:
			meda_timer = 0.0
			if store({"label": Game.t("Weather report", "Informe meteorológico"), "mb": 4.0, "science": 6.0, "kind": "meda"}):
				meda_packets += 1
				if meda_packets == 1: ask("weather", packets[-1])
	if moxie_timer >= 0.0:
		moxie_timer += delta
		if moxie_timer >= 14.0:
			moxie_timer = -1.0
			moxie_runs += 1
			if store({"label": Game.t("MOXIE oxygen run", "Prueba de oxígeno MOXIE"), "mb": 16.0, "science": 40.0, "kind": "moxie"}):
				show_card("MOXIE", Game.t("Oxygen produced from the CO2 atmosphere. Purity and rate logged.", "Oxígeno producido a partir de la atmósfera de CO2. Pureza y ritmo registrados."), "moxie", packets[-1])
	if transmitting:
		var rate := link_rate()
		if rate <= 0.0 or packets.is_empty():
			transmitting = false
			if not packets.is_empty(): say(Game.t("Link closed. The rest of the data stays on board for the next pass.", "Enlace cerrado. El resto de los datos queda a bordo para el próximo paso."))
		else:
			var budget := rate * delta
			while budget > 0.0 and not packets.is_empty():
				var packet: Dictionary = packets[0]
				var step := minf(budget, float(packet.mb) - float(packet.sent))
				packet.sent = float(packet.sent) + step
				budget -= step
				received_mb += step
				if float(packet.sent) >= float(packet.mb) - 0.001:
					received_science += float(packet.science)
					packets.pop_front()
			if packets.is_empty():
				transmitting = false
				Game.sfx("good")
				say(Game.t("All data received on Earth. The science team is already reading it.", "Todos los datos recibidos en la Tierra. El equipo científico ya los está leyendo."))
	if pass_open() and not packets.is_empty() and not transmitting: tell("pass", Game.t("An orbiter is overhead. Stop and press T to send your data.", "Hay un orbitador encima. Detente y pulsa T para enviar tus datos."))

func store(packet: Dictionary) -> bool:
	if memory_used() + float(packet.mb) > float(stats.memory) + 0.01:
		say(Game.t("Memory full. That data was not recorded: transmit to free space.", "Memoria llena. Ese dato no se grabó: transmite para liberar espacio."))
		return false
	packet["sent"] = 0.0
	packets.append(packet)
	Game.sfx("data")
	collected_mb += float(packet.mb)
	tell("first_data", Game.t("Data stored on board. It only counts once Earth receives it.", "Dato guardado a bordo. Solo cuenta cuando la Tierra lo recibe."))
	return true

# ------------------------------------------------------------- objetivos
func objective_state() -> Array:
	var out: Array = []
	for objective in zone.objectives:
		var value := 0.0
		match String(objective.kind):
			"imaged": value = targets.filter(func(t: Dictionary) -> bool: return t.imaged).size()
			"chem_types":
				var kinds := {}
				for target in targets:
					if target.chem or target.pixl: kinds[target.type] = true
				value = kinds.size()
			"aqueous": value = targets.filter(func(t: Dictionary) -> bool: return (t.chem or t.pixl) and Data.ROCKS[t.type].aqueous).size()
			"sherloc": value = targets.filter(func(t: Dictionary) -> bool: return t.sherloc).size()
			"quiz": value = quiz_correct
			"received": value = floorf(received_mb + 0.01)
			"cache_types":
				var types := {}
				for sample in cached: types[sample.type] = true
				value = types.size()
			"cache_documented": value = cached.filter(func(s: Dictionary) -> bool: return s.documented).size()
			"meda": value = meda_packets
			"moxie": value = moxie_runs
			"rimfax": value = rimfax_scans
		out.append({"text": Game.tt(objective.text), "value": value, "need": float(objective.need), "done": value >= float(objective.need)})
	return out

func all_objectives_done() -> bool:
	for item in objective_state():
		if not item.done: return false
	return true

# --------------------------------------------------------------- entrada
func nearest_target() -> Dictionary:
	var best := {}
	var best_gap := 270.0
	for target in targets:
		var gap: float = pos.distance_to(target.pos) - float(target.r)
		if gap < best_gap:
			best_gap = gap
			best = target
	return best

## Punto más cercano que aún aporta ciencia: roca sin estudiar o sitio de radar.
func next_goal() -> Vector2:
	var best := Vector2.ZERO
	var best_gap := INF
	for target in targets:
		if target.imaged or target.chem or target.pixl or target.sherloc or target.cached: continue
		var gap: float = pos.distance_to(target.pos)
		if gap < best_gap:
			best_gap = gap
			best = target.pos
	if "rimfax" in has:
		for site in sites:
			if not site.scanned and pos.distance_to(site.pos) < best_gap:
				best_gap = pos.distance_to(site.pos)
				best = site.pos
	return best

func site_here() -> Dictionary:
	for site in sites:
		if not site.scanned and pos.distance_to(site.pos) < float(site.r): return site
	return {}

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if mode == "minigame":
		if event.is_action("interact"): press_minigame()
		return
	var number: int = event.physical_keycode - KEY_1
	if mode in ["card", "menu"] and number >= 0 and number < hotkeys.size():
		var button: Button = hotkeys[number]
		if is_instance_valid(button) and not button.disabled:
			get_viewport().set_input_as_handled()
			button.pressed.emit()
		return
	if mode in ["card", "brief"]:
		if confirmable and event.is_action("confirm"): close_dialog()
		return
	if event.is_action("pause"):
		if mode == "drive": show_pause()
		elif mode in ["menu", "paused"]: close_dialog()
		return
	if mode != "drive" or safe_mode: return
	if event.is_action("interact"):
		var target := nearest_target()
		if not target.is_empty(): show_actions(target)
	elif event.is_action("transmit"): toggle_transmit()
	elif event.is_action("weather"): toggle_meda()
	elif event.is_action("oxygen"): start_moxie()
	elif event.is_action("radar"): start_radar()

func toggle_transmit() -> void:
	if transmitting:
		transmitting = false
		return
	if packets.is_empty(): say(Game.t("Nothing to send yet. Use an instrument on a rock first.", "Aún no hay nada que enviar. Usa primero un instrumento en una roca."))
	elif link_rate() <= 0.0: say(Game.t("No link. Wait for the next orbiter pass.", "Sin enlace. Espera el próximo paso del orbitador."))
	elif vel.length() > 12.0: say(Game.t("Stop the rover before transmitting.", "Detén el rover antes de transmitir."))
	else:
		transmitting = true
		Game.sfx("link")

func toggle_meda() -> void:
	if not "meda" in has:
		say(Game.t("MEDA was not installed on this rover.", "MEDA no se instaló en este rover."))
		return
	meda_on = not meda_on
	say(Game.t("MEDA weather station ON: logging wind, temperature and dust.", "Estación MEDA ENCENDIDA: registra viento, temperatura y polvo.") if meda_on else Game.t("MEDA off.", "MEDA apagada."))

func start_moxie() -> void:
	if not "moxie" in has: say(Game.t("MOXIE was not installed on this rover.", "MOXIE no se instaló en este rover."))
	elif moxie_timer >= 0.0: pass
	elif energy < 46.0: say(Game.t("MOXIE needs 46 units of energy for a full run.", "MOXIE necesita 46 unidades de energía para una prueba completa."))
	else:
		moxie_timer = 0.0
		transmitting = false
		say(Game.t("MOXIE running: splitting CO2 into oxygen. Hold position.", "MOXIE en marcha: separa el CO2 para obtener oxígeno. Mantén la posición."))

func start_radar() -> void:
	if not "rimfax" in has:
		say(Game.t("RIMFAX was not installed on this rover.", "RIMFAX no se instaló en este rover."))
		return
	var site := site_here()
	if site.is_empty(): say(Game.t("Drive onto a radar site (dashed circle) to scan.", "Conduce sobre un sitio de radar (círculo punteado) para escanear."))
	else: run_instrument("rimfax", site)

# ------------------------------------------------------------- diálogos
func close_dialog() -> void:
	if is_instance_valid(dialog): dialog.queue_free()
	dialog = null
	if mode != "ended": mode = "drive"

func open_panel(rect: Rect2) -> Panel:
	if is_instance_valid(dialog): dialog.queue_free()
	var panel := UIK.panel(self, rect)
	dialog = panel
	confirmable = true
	hotkeys = []
	UIK.pop(panel)
	return panel

func show_brief() -> void:
	mode = "brief"
	var panel := open_panel(Rect2(300, 130, 680, 460))
	var portrait := Control.new()
	portrait.position = Vector2(24, 22)
	portrait.size = Vector2(130, 130)
	portrait.draw.connect(func() -> void: Art.owen(portrait, Rect2(Vector2.ZERO, portrait.size), time))
	panel.add_child(portrait)
	var column := UIK.column(panel, Rect2(172, 22, 484, 340), 8)
	UIK.label(column, Game.t("Dr. Owen · Mission science", "Dra. Owen · Ciencia de misión"), 15, UIK.TEAL, "bold")
	UIK.label(column, "%s · %s" % [Game.tt(zone.goal), Game.tt(zone.name)], 28, UIK.NAVY, "title")
	UIK.text(column, Game.t("%s has landed. ", "%s ha aterrizado. ") % Game.rover_name + Game.tt(zone.brief), 17, UIK.INK)
	UIK.text(column, Game.t("WASD / arrows: drive   ·   E: instruments (then 1-5)   ·   T: transmit\nM: weather station   ·   O: oxygen run   ·   R: radar   ·   Esc: pause", "WASD / flechas: conducir   ·   E: instrumentos (luego 1-5)   ·   T: transmitir\nM: estación meteorológica   ·   O: prueba de oxígeno   ·   R: radar   ·   Esc: pausa"), 15, UIK.MUTED)
	UIK.text(column, Game.t("Science only counts when Earth receives it.", "La ciencia solo cuenta cuando la Tierra la recibe."), 16, UIK.CORAL)
	var start := UIK.button(panel, Game.t("Begin operations →", "Iniciar operaciones →"), close_dialog, "primary", Vector2(300, 56))
	start.position = Vector2(356, 384)

func show_pause() -> void:
	mode = "paused"
	var panel := open_panel(Rect2(440, 190, 400, 330))
	var column := UIK.column(panel, Rect2(30, 24, 340, 290), 12)
	UIK.label(column, Game.t("Mission paused", "Misión en pausa"), 30, UIK.NAVY, "title")
	UIK.button(column, Game.t("Resume", "Continuar"), close_dialog, "teal", Vector2(340, 52))
	UIK.button(column, Game.t("End mission and debrief", "Terminar misión e informe"), func() -> void: finish("player"), "primary", Vector2(340, 52))
	UIK.button(column, Game.t("Abort to map", "Abortar al mapa"), func() -> void: Game.go("zones"), "ghost", Vector2(340, 52))

func target_title(target: Dictionary) -> String:
	var rock: Dictionary = Data.ROCKS[target.type]
	if target.chem or target.pixl or target.sherloc: return Game.tt(rock.name)
	if target.imaged: return {"igneous": Game.t("Igneous rock", "Roca ígnea"), "sedimentary": Game.t("Sedimentary rock", "Roca sedimentaria"), "soil": Game.t("Loose regolith", "Regolito suelto")}[rock.klass]
	return Game.t("Unidentified target", "Objetivo sin identificar")

func show_actions(target: Dictionary) -> void:
	mode = "menu"
	focus = target
	var panel := open_panel(Rect2(390, 372, 500, 320))
	var column := UIK.column(panel, Rect2(22, 14, 456, 300), 6)
	UIK.label(column, target_title(target), 24, UIK.NAVY, "title")
	var gap: float = pos.distance_to(target.pos) - float(target.r)
	var offered := 0
	for id in ["mastcam", "supercam", "pixl", "sherloc", "arm"]:
		if not id in has: continue
		offered += 1
		var info: Dictionary = Data.INSTRUMENTS[id]
		var done: bool = target.cached if id == "arm" else target[{"mastcam": "imaged", "supercam": "chem", "pixl": "pixl", "sherloc": "sherloc"}[id]]
		var caption := "%s  ·  %d MB  ·  %d %s" % [Data.instrument_name(id) if id != "arm" else Game.t("Core and cache a sample (%d tubes)", "Extraer y guardar muestra (%d tubos)") % tubes, int(info.mb), int(info.energy), Game.t("energy", "energía")]
		var reason := ""
		if done: reason = Game.t("done", "hecho")
		elif gap > float(info.range): reason = Game.t("move closer", "acércate más")
		elif energy < float(info.energy) + 4.0: reason = Game.t("not enough energy", "energía insuficiente")
		elif memory_used() + float(info.mb) > float(stats.memory): reason = Game.t("memory full", "memoria llena")
		elif id == "arm" and tubes <= 0: reason = Game.t("no tubes left", "sin tubos")
		var button := UIK.button(column, "%d   %s" % [offered, caption] + ("   — " + reason if reason != "" else ""), func() -> void: run_instrument(id, target), "teal" if reason == "" else "ghost", Vector2(456, 42))
		hotkeys.append(button)
		button.add_theme_font_size_override("font_size", 16)
		button.disabled = reason != ""
	if offered == 0: UIK.text(column, Game.t("This rover carries no instrument that can study a rock. That was decided in the design.", "Este rover no lleva ningún instrumento para estudiar una roca. Eso se decidió en el diseño."), 16, UIK.BAD)
	var close := UIK.button(column, Game.t("Close (Esc)", "Cerrar (Esc)"), close_dialog, "ghost", Vector2(456, 36))
	close.add_theme_font_size_override("font_size", 15)

func run_instrument(id: String, target: Dictionary) -> void:
	if is_instance_valid(dialog): dialog.queue_free()
	dialog = null
	transmitting = false
	focus = target
	energy -= float(Data.INSTRUMENTS[id].energy)
	energy_used += float(Data.INSTRUMENTS[id].energy)
	game = {"id": id, "mode": String(Data.INSTRUMENTS[id].mode), "t": 0.0, "hits": 0, "tries": 0, "value": 0.2, "band": 0.5, "progress": 0.0, "flash": 0.0}
	mode = "minigame"

func update_minigame(delta: float) -> void:
	game.t += delta
	game.flash = maxf(0.0, float(game.flash) - delta)
	match String(game.mode):
		"focus", "timing": game.value = 0.5 + 0.5 * sin(float(game.t) * (2.6 if game.mode == "focus" else 3.4))
		"steady":
			game.band = 0.5 + 0.22 * sin(float(game.t) * 1.3)
			game.value = clampf(float(game.value) + (0.75 if Input.is_action_pressed("interact") else -0.6) * delta, 0.0, 1.0)
			if absf(float(game.value) - float(game.band)) < 0.14: game.progress = float(game.progress) + delta / 3.0
			if float(game.progress) >= 1.0: end_minigame(clampf(1.25 - float(game.t) / 12.0, 0.45, 1.0))
			elif float(game.t) > 14.0: end_minigame(0.45)

func press_minigame() -> void:
	match String(game.mode):
		"focus": end_minigame(clampf(1.0 - absf(float(game.value) - 0.5) * 2.2, 0.4, 1.0))
		"timing":
			game.tries += 1
			if absf(float(game.value) - 0.5) < 0.13:
				game.hits += 1
				game.flash = 0.25
				Game.sfx("click", 1.5)
			if int(game.tries) >= 3: end_minigame(0.4 + 0.2 * int(game.hits))

func end_minigame(quality: float) -> void:
	var id := String(game.id)
	var info: Dictionary = Data.INSTRUMENTS[id]
	var packet := {"label": Data.instrument_name(id), "mb": float(info.mb), "science": float(info.science) * quality, "kind": id}
	var body := ""
	var quiz := ""
	if id == "rimfax":
		focus.scanned = true
		rimfax_scans += 1
		body = Game.t("Radargram recorded: tilted layers continue metres below the wheels.", "Radargrama registrado: capas inclinadas continúan metros bajo las ruedas.")
		quiz = "radar"
	else:
		var rock: Dictionary = Data.ROCKS[focus.type]
		match id:
			"mastcam":
				focus.imaged = true
				body = {"igneous": Game.t("Context image: a massive, dark rock with no layering. Igneous.", "Imagen de contexto: roca oscura y masiva, sin capas. Ígnea."), "sedimentary": Game.t("Context image: fine layers stacked like pages. Sedimentary.", "Imagen de contexto: capas finas apiladas como páginas. Sedimentaria."), "soil": Game.t("Context image: loose grains and dust, no solid outcrop.", "Imagen de contexto: granos sueltos y polvo, sin afloramiento sólido.")}[rock.klass]
			"supercam", "pixl":
				if id == "pixl": focus.pixl = true
				else: focus.chem = true
				body = Game.tt(rock.name) + ". " + Game.tt(rock.chem)
				if id == "pixl": body += Game.t(" PIXL maps where each element sits, grain by grain.", " PIXL mapea dónde está cada elemento, grano por grano.")
				quiz = "igneous" if rock.klass == "igneous" else ("water" if rock.aqueous else "")
			"sherloc":
				focus.sherloc = true
				if rock.organics:
					body = Game.t("Organic molecules detected, next to minerals that formed in water.", "Moléculas orgánicas detectadas, junto a minerales formados en agua.")
					quiz = "organics"
				else:
					body = Game.t("No organics detected here. A clean negative is still a result.", "No se detectaron orgánicos aquí. Un negativo limpio también es un resultado.")
					packet.science = float(packet.science) * 0.4
			"arm":
				focus.cached = true
				tubes -= 1
				cached.append({"type": focus.type, "documented": focus.imaged})
				packet.label = Game.t("Sample record", "Registro de muestra")
				if focus.imaged:
					packet.science = float(packet.science) + 12.0
					body = Game.t("Core sealed in its tube. Site, rock type and context are on record.", "Núcleo sellado en su tubo. Sitio, tipo de roca y contexto quedan registrados.")
				else: body = Game.t("Core sealed, but the site was never imaged: the sample has lost part of its context.", "Núcleo sellado, pero el sitio nunca se fotografió: la muestra perdió parte de su contexto.")
				quiz = "cache"
	mode = "drive"
	if store(packet): show_card(String(packet.label), body + ("  (%s %d%%)" % [Game.t("signal quality", "calidad de señal"), int(quality * 100)]), quiz, packet)

func show_card(title: String, body: String, quiz: String, packet: Dictionary) -> void:
	if quiz != "" and not quiz_done.has(quiz):
		ask(quiz, packet, title, body)
		return
	mode = "card"
	var panel := open_panel(Rect2(360, 200, 560, 290))
	var column := UIK.column(panel, Rect2(26, 18, 508, 200), 8)
	UIK.label(column, title, 26, UIK.NAVY, "title")
	UIK.text(column, body, 18, UIK.INK)
	UIK.text(column, "+%d MB %s" % [int(packet.mb), Game.t("stored on board — not yet on Earth", "guardados a bordo — aún no en la Tierra")], 15, UIK.TEAL)
	var ok := UIK.button(panel, Game.t("Continue", "Continuar"), close_dialog, "primary", Vector2(220, 50))
	ok.position = Vector2(170, 222)

func ask(id: String, packet: Dictionary, title: String = "", body: String = "") -> void:
	mode = "card"
	quiz_done[id] = true
	quiz_asked += 1
	var quiz: Dictionary = Data.QUIZ[id]
	var panel := open_panel(Rect2(300, 120, 680, 480))
	confirmable = false
	var column := UIK.column(panel, Rect2(26, 16, 628, 450), 8)
	if title != "": UIK.label(column, title, 22, UIK.NAVY, "title")
	if body != "": UIK.text(column, body, 16, UIK.MUTED)
	UIK.text(column, Game.t("Dr. Owen: ", "Dra. Owen: ") + Game.tt(quiz.q), 19, UIK.INK)
	for i in range(quiz.options.size()):
		var button := UIK.button(column, "%d   %s" % [i + 1, Game.tt(quiz.options[i])], func() -> void: answer(id, i, packet), "ghost", Vector2(628, 50))
		hotkeys.append(button)
		button.add_theme_font_size_override("font_size", 15)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func answer(id: String, choice: int, packet: Dictionary) -> void:
	var quiz: Dictionary = Data.QUIZ[id]
	var right: bool = choice == int(quiz.correct)
	Game.sfx("good" if right else "bad")
	if right:
		quiz_correct += 1
		packet.science = float(packet.science) * 1.25
	var panel := open_panel(Rect2(360, 190, 560, 320))
	var column := UIK.column(panel, Rect2(26, 18, 508, 220), 10)
	UIK.label(column, Game.t("Well reasoned", "Bien razonado") if right else Game.t("Careful with that claim", "Cuidado con esa afirmación"), 26, UIK.GOOD if right else UIK.BAD, "title")
	UIK.text(column, Game.tt(quiz.why), 18, UIK.INK)
	UIK.text(column, Game.t("Interpretation bonus: +25% science for this finding.", "Bono de interpretación: +25% de ciencia para este hallazgo.") if right else Game.t("No bonus: evidence must be reported at the level it supports.", "Sin bono: la evidencia se informa al nivel que realmente sostiene."), 15, UIK.TEAL)
	var ok := UIK.button(panel, Game.t("Continue", "Continuar"), close_dialog, "primary", Vector2(220, 50))
	ok.position = Vector2(170, 250)

func say(text: String) -> void:
	for toast in toasts:
		if toast.text == text:
			toast.age = minf(float(toast.age), 1.0)
			return
	toasts.append({"text": text, "age": 0.0})
	if toasts.size() > 3: toasts.pop_front()

func tell(id: String, text: String) -> void:
	if told.has(id): return
	told[id] = true
	say(text)

# ------------------------------------------------------------------ final
func finish(reason: String) -> void:
	if mode == "ended": return
	mode = "ended"
	var goals := objective_state()
	var done := goals.filter(func(item: Dictionary) -> bool: return item.done).size()
	var lost := memory_used()
	var score := 65.0 * done / maxf(1.0, goals.size()) + 20.0 * minf(1.0, received_mb / float(zone.need_mb)) + integrity * 0.1 + (5.0 if lost < 1.0 else 0.0)
	var grade := "D"
	if score >= 93.0: grade = "S"
	elif score >= 80.0: grade = "A"
	elif score >= 65.0: grade = "B"
	elif score >= 48.0: grade = "C"
	Game.report = {"zone": Game.zone, "reason": reason, "goals": goals, "done": done, "grade": grade, "score": score,
		"collected": collected_mb, "received": received_mb, "lost": lost, "science": int(received_science),
		"energy_used": energy_used, "integrity": maxf(0.0, integrity), "time": clock, "quiz_right": quiz_correct, "quiz_asked": quiz_asked,
		"cached": cached.size(), "samples": cached.duplicate(true), "readiness": Data.readiness(build, Game.zone)}
	Game.record(Game.zone, grade, int(received_science))
	Game.go("debrief")

# ----------------------------------------------------------------- dibujo
func _draw() -> void:
	var view := size
	var span := view / ZOOM
	var camera := (pos - span * 0.5).clamp(Vector2.ZERO, WORLD - span)
	draw_set_transform(-camera * ZOOM, 0.0, Vector2(ZOOM, ZOOM))
	var ground := Color(String(zone.ground))
	draw_rect(Rect2(camera, span), ground)
	var screen := Rect2(camera - Vector2(340, 340), span + Vector2(680, 680))
	var tight := Rect2(camera - Vector2(20, 20), span + Vector2(40, 40))
	for pebble in pebbles:
		if screen.has_point(pebble.points[0]): draw_colored_polygon(pebble.points, pebble.color)
	for patch in patches:
		if not screen.has_point(patch.pos): continue
		match String(patch.kind):
			"sharp":
				draw_colored_polygon(patch.points, Art.shade(ground, -0.2))
				var local := RandomNumberGenerator.new()
				local.seed = int(patch.seed) + 50
				for i in range(16):
					var at: Vector2 = patch.pos + Vector2(local.randf_range(-0.7, 0.7) * float(patch.rx), local.randf_range(-0.7, 0.7) * float(patch.ry))
					draw_colored_polygon(PackedVector2Array([at + Vector2(-9, 6), at + Vector2(0, -12), at + Vector2(9, 6)]), Art.shade(ground, -0.42))
					draw_colored_polygon(PackedVector2Array([at + Vector2(0, -12), at + Vector2(9, 6), at + Vector2(2, 6)]), Art.shade(ground, -0.3))
			"sand":
				draw_colored_polygon(patch.points, Art.shade(ground, 0.22))
				for i in range(4): draw_arc(patch.pos + Vector2(0, -40 + i * 28), float(patch.rx) * 0.55, 0.5, 2.6, 14, Art.shade(ground, 0.34), 3.0, true)
			"cold": draw_colored_polygon(patch.points, Color(0.2, 0.3, 0.5, 0.34))
	for shard in shards:
		if tight.has_point(shard.pos): draw_colored_polygon(shard.points, shard.color)
	draw_colored_polygon(Art.blob(LANDING, 78, 60, 2, 10, 0.08), Art.shade(ground, -0.16))
	for i in range(6): draw_line(LANDING + Vector2.from_angle(TAU * i / 6.0) * 30.0, LANDING + Vector2.from_angle(TAU * i / 6.0) * 70.0, Art.shade(ground, -0.26), 5.0)
	draw_string(UIK.bold_font, LANDING + Vector2(-90, 84), Game.t("landing site", "sitio de aterrizaje"), HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color(UIK.PAPER, 0.7))
	for i in range(tracks.size()):
		var alpha := 0.3 * i / maxf(1.0, tracks.size())
		draw_circle(tracks[i] + Vector2(0, -19), 4.0, Color(0.3, 0.1, 0.08, alpha))
		draw_circle(tracks[i] + Vector2(0, 19), 4.0, Color(0.3, 0.1, 0.08, alpha))
	if "rimfax" in has:
		for site in sites:
			var tone := UIK.GOOD if site.scanned else UIK.PAPER
			for i in range(12): draw_arc(site.pos, float(site.r), TAU * i / 12.0, TAU * i / 12.0 + 0.3, 5, tone, 3.0, true)
			draw_string(UIK.bold_font, site.pos + Vector2(-90, 6), Game.t("radar site", "sitio de radar") if not site.scanned else "✓", HORIZONTAL_ALIGNMENT_CENTER, 180, 15, tone)
	var things: Array = []
	for item in obstacles:
		if screen.has_point(item.pos): things.append({"y": float(item.pos.y), "kind": "rock", "item": item})
	for item in targets:
		if screen.has_point(item.pos): things.append({"y": float(item.pos.y), "kind": "target", "item": item})
	things.append({"y": pos.y, "kind": "rover", "item": {}})
	things.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
	var near := nearest_target() if mode == "drive" else focus
	for thing in things:
		var item: Dictionary = thing.item
		match String(thing.kind):
			"rock": Art.rock(self, item.pos, float(item.r), int(item.seed), item.color)
			"rover": Art.rover(self, pos, heading, build, 1.0, time, light() < 0.3, -camera * ZOOM, ZOOM)
			"target":
				var rock: Dictionary = Data.ROCKS[item.type]
				var studied: bool = item.imaged or item.chem or item.pixl or item.sherloc or item.cached
				var ring := UIK.GOOD if studied else UIK.YELLOW
				draw_arc(item.pos + Vector2(0, 6), float(item.r) + 14.0 + sin(time * 3.0 + float(item.seed)) * 3.0, 0, TAU, 32, Color(ring, 0.9 if item == near else 0.5), 3.0, true)
				if rock.klass == "soil": draw_colored_polygon(Art.blob(item.pos, float(item.r) * 1.2, float(item.r) * 0.8, int(item.seed), 9, 0.15), Color(String(rock.color)))
				else: Art.rock(self, item.pos, float(item.r), int(item.seed), Color(String(rock.color)), 0.8)
				if item == near or studied:
					draw_string(UIK.bold_font, item.pos + Vector2(-140, -float(item.r) - 22), target_title(item), HORIZONTAL_ALIGNMENT_CENTER, 280, 16, UIK.PAPER)
	for devil in devils: Art.dust_devil(self, devil.pos, time, float(devil.r))
	var guide := next_goal()
	if mode == "drive" and guide != Vector2.ZERO and pos.distance_to(guide) > 260.0:
		var way := (guide - pos).normalized()
		var tip := pos + way * (70.0 + sin(time * 4.0) * 5.0)
		var side := way.orthogonal() * 11.0
		draw_colored_polygon(PackedVector2Array([tip + way * 16.0, tip - way * 6.0 + side, tip - way * 6.0 - side]), Color(UIK.YELLOW, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var dark := 1.0 - light()
	if dark > 0.01: draw_rect(Rect2(Vector2.ZERO, view), Color(0.07, 0.09, 0.24, 0.5 * dark))
	if storming():
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.85, 0.6, 0.38, 0.3))
		for i in range(14):
			var y := fmod(i * 61.0 + time * 40.0, view.y)
			var x := fmod(i * 173.0 + time * 520.0, view.x + 300.0) - 300.0
			draw_line(Vector2(x, y), Vector2(x + 240, y + 14), Color(1.0, 0.9, 0.75, 0.2), 3.0)
	draw_hud(view, camera, span)
	if mode == "minigame": draw_minigame(view)

func pill(rect: Rect2, color: Color) -> void:
	draw_style_box(UIK.box(color, int(rect.size.y * 0.5), Color.TRANSPARENT, 0, 4), rect)

func draw_hud(view: Vector2, camera: Vector2, span: Vector2) -> void:
	draw_style_box(UIK.box(Color(UIK.CREAM, 0.95), 18), Rect2(16, 14, 276, 132 if tubes > 0 or "arm" in has else 112))
	draw_string(UIK.title_font, Vector2(32, 42), Game.rover_name, HORIZONTAL_ALIGNMENT_LEFT, 250, 22, UIK.NAVY)
	var rows := [[Game.t("ENERGY", "ENERGÍA"), energy / float(stats.battery), UIK.YELLOW if energy > float(stats.battery) * 0.22 else UIK.BAD, "%d" % int(energy)],
		[Game.t("MEMORY", "MEMORIA"), memory_used() / float(stats.memory), UIK.TEAL, "%d/%d MB" % [int(memory_used()), int(stats.memory)]],
		[Game.t("WHEELS", "RUEDAS"), integrity / 100.0, UIK.CORAL, "%d%%" % int(maxf(0.0, integrity))]]
	for i in range(rows.size()):
		var y := 58.0 + i * 24.0
		draw_string(UIK.bold_font, Vector2(32, y + 12), String(rows[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIK.MUTED)
		UIK.bar(self, Rect2(104, y, 110, 14), float(rows[i][1]), rows[i][2])
		draw_string(UIK.bold_font, Vector2(220, y + 12), String(rows[i][3]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIK.NAVY)
	if "arm" in has: draw_string(UIK.bold_font, Vector2(32, 138), Game.t("SAMPLE TUBES  %d / 4 free", "TUBOS DE MUESTRA  %d / 4 libres") % tubes, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIK.NAVY)
	# Reloj y enlace
	var left := maxf(0.0, float(zone.time) - clock)
	pill(Rect2(view.x * 0.5 - 170, 14, 340, 40), Color(UIK.NAVY, 0.92))
	var sun := light()
	draw_circle(Vector2(view.x * 0.5 - 146, 34), 10, UIK.YELLOW if sun > 0.01 else Color("#b8c4e0"))
	draw_string(UIK.bold_font, Vector2(view.x * 0.5 - 126, 40), "%s  ·  %s %d:%02d" % [Game.t("DAY", "DÍA") if sun > 0.01 else Game.t("NIGHT", "NOCHE"), Game.t("MISSION TIME LEFT", "TIEMPO DE MISIÓN"), int(left) / 60, int(left) % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UIK.PAPER)
	var link_text := ""
	var link_color := UIK.MUTED
	if transmitting:
		link_text = Game.t("TRANSMITTING  ·  %d MB on board", "TRANSMITIENDO  ·  %d MB a bordo") % int(memory_used())
		link_color = UIK.GOOD
	elif pass_open():
		link_text = Game.t("ORBITER OVERHEAD  ·  press T  ·  %ds", "ORBITADOR ENCIMA  ·  pulsa T  ·  %ds") % int(PASS_LENGTH - fmod(clock - FIRST_PASS, PASS_PERIOD))
		link_color = UIK.TEAL
	else:
		var wait := FIRST_PASS - clock if clock < FIRST_PASS else PASS_PERIOD - fmod(clock - FIRST_PASS, PASS_PERIOD)
		link_text = Game.t("Next orbiter pass in %ds", "Próximo paso del orbitador en %ds") % int(wait)
		if stats.direct: link_text += Game.t("  ·  direct link ready (T)", "  ·  enlace directo listo (T)")
	pill(Rect2(view.x * 0.5 - 200, 62, 400, 32), Color(link_color, 0.95))
	draw_string(UIK.bold_font, Vector2(view.x * 0.5 - 190, 84), link_text, HORIZONTAL_ALIGNMENT_CENTER, 380, 15, UIK.PAPER)
	if pass_open(): Art.orbiter(self, Vector2(view.x * 0.5 - 180 + 360.0 * fmod(clock - FIRST_PASS, PASS_PERIOD) / PASS_LENGTH, 106), 0.9)
	# Objetivos
	var goals := objective_state()
	draw_style_box(UIK.box(Color(UIK.CREAM, 0.95), 18), Rect2(view.x - 356, 14, 340, 40 + goals.size() * 40))
	draw_string(UIK.bold_font, Vector2(view.x - 338, 38), "%s · %s" % [Game.tt(zone.goal).to_upper(), Game.t("RECEIVED %d MB", "RECIBIDOS %d MB") % int(received_mb)], HORIZONTAL_ALIGNMENT_LEFT, 310, 13, UIK.MUTED)
	for i in range(goals.size()):
		var goal: Dictionary = goals[i]
		var y := 62.0 + i * 40.0
		draw_circle(Vector2(view.x - 332, y + 2), 9, UIK.GOOD if goal.done else Color(UIK.NAVY, 0.18))
		if goal.done: draw_polyline(PackedVector2Array([Vector2(view.x - 337, y + 2), Vector2(view.x - 333, y + 6), Vector2(view.x - 327, y - 3)]), UIK.PAPER, 2.5)
		draw_multiline_string(UIK.body_font, Vector2(view.x - 314, y), "%s  (%d/%d)" % [goal.text, int(minf(goal.value, goal.need)), int(goal.need)], HORIZONTAL_ALIGNMENT_LEFT, 290, 14, 2, UIK.GOOD if goal.done else UIK.INK)
	# Minimapa
	var map := Rect2(view.x - 216, view.y - 156, 200, 134)
	draw_style_box(UIK.box(Color(UIK.NAVY, 0.88), 14), map)
	var ratio := Vector2(map.size.x / WORLD.x, map.size.y / WORLD.y)
	for target in targets: draw_circle(map.position + Vector2(target.pos) * ratio, 3.5, UIK.GOOD if (target.imaged or target.chem or target.pixl or target.sherloc or target.cached) else UIK.YELLOW)
	if "rimfax" in has:
		for site in sites: draw_arc(map.position + Vector2(site.pos) * ratio, 4.5, 0, TAU, 10, UIK.GOOD if site.scanned else UIK.PAPER, 1.5)
	if meda_on:
		for devil in devils: draw_circle(map.position + Vector2(devil.pos) * ratio, 3.0, UIK.SAND)
	draw_rect(Rect2(map.position + camera * ratio, span * ratio), Color(UIK.PAPER, 0.35), false, 1.0)
	draw_circle(map.position + pos * ratio, 4.0, UIK.CORAL)
	# Estado y ayudas
	var prompt := ""
	if safe_mode: prompt = Game.t("SAFE MODE — waiting for power", "MODO SEGURO — esperando energía")
	elif moxie_timer >= 0.0: prompt = Game.t("MOXIE running… %d%%", "MOXIE en marcha… %d%%") % int(moxie_timer / 14.0 * 100.0)
	elif mode == "drive":
		var target := nearest_target()
		if not site_here().is_empty() and "rimfax" in has: prompt = Game.t("R — scan this radar site", "R — escanear este sitio de radar")
		elif not target.is_empty(): prompt = Game.t("E — study: ", "E — estudiar: ") + target_title(target)
	if prompt != "":
		pill(Rect2(view.x * 0.5 - 220, view.y - 118, 440, 44), Color(UIK.CORAL, 0.96))
		draw_string(UIK.bold_font, Vector2(view.x * 0.5 - 210, view.y - 89), prompt, HORIZONTAL_ALIGNMENT_CENTER, 420, 19, UIK.PAPER)
	var status: Array = []
	if meda_on: status.append("MEDA ON")
	if stats.solar: status.append(Game.t("panel dust %d%%", "polvo en paneles %d%%") % int(dust * 100))
	if storming(): status.append(Game.t("DUST STORM", "TORMENTA DE POLVO"))
	draw_string(UIK.bold_font, Vector2(24, view.y - 14), Game.t("WASD drive · E study · T transmit · M weather · O oxygen · R radar · Esc pause", "WASD conducir · E estudiar · T transmitir · M clima · O oxígeno · R radar · Esc pausa") + ("    " + "  ·  ".join(status) if not status.is_empty() else ""), HORIZONTAL_ALIGNMENT_LEFT, view.x - 260, 14, Color(UIK.PAPER, 0.9))
	for i in range(toasts.size()):
		var toast: Dictionary = toasts[i]
		var alpha := clampf(minf(float(toast.age) * 4.0, 7.0 - float(toast.age)), 0.0, 1.0)
		var box := Rect2(16, view.y - 108 - (toasts.size() - 1 - i) * 76, 392, 68)
		draw_style_box(UIK.box(Color(UIK.PAPER, 0.96 * alpha), 16, Color(UIK.TEAL, alpha), 2, 4), box)
		draw_multiline_string(UIK.body_font, box.position + Vector2(14, 21), String(toast.text), HORIZONTAL_ALIGNMENT_LEFT, 364, 14, 3, Color(UIK.INK, alpha))

func draw_minigame(view: Vector2) -> void:
	var box := Rect2(view.x * 0.5 - 250, view.y * 0.5 - 110, 500, 220)
	draw_rect(Rect2(Vector2.ZERO, view), Color(UIK.NAVY, 0.45))
	draw_style_box(UIK.box(UIK.CREAM, 22), box)
	var id := String(game.id)
	draw_string(UIK.title_font, box.position + Vector2(24, 44), Data.instrument_name(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UIK.NAVY)
	var bar := Rect2(box.position + Vector2(40, 110), Vector2(420, 26))
	match String(game.mode):
		"focus":
			draw_multiline_string(UIK.body_font, box.position + Vector2(24, 72), Game.t("Press SPACE when the image is sharp (ring on the mark).", "Pulsa ESPACIO cuando la imagen esté nítida (anillo sobre la marca)."), HORIZONTAL_ALIGNMENT_LEFT, 452, 15, 2, UIK.INK)
			var centre := box.position + Vector2(250, 148)
			draw_circle(centre, 30, Color(UIK.TEAL, 0.25))
			draw_arc(centre, 30, 0, TAU, 40, UIK.TEAL, 3.0, true)
			draw_arc(centre, 8.0 + float(game.value) * 44.0, 0, TAU, 40, UIK.CORAL, 4.0, true)
		"timing":
			draw_multiline_string(UIK.body_font, box.position + Vector2(24, 72), Game.t("Press SPACE 3 times while the marker crosses the green zone.", "Pulsa ESPACIO 3 veces cuando el marcador cruce la zona verde."), HORIZONTAL_ALIGNMENT_LEFT, 452, 15, 2, UIK.INK)
			UIK.bar(self, bar, 0.0, UIK.TEAL)
			draw_style_box(UIK.box(UIK.GOOD if float(game.flash) <= 0.0 else UIK.YELLOW, 10, Color.TRANSPARENT, 0, 0), Rect2(bar.position + Vector2(bar.size.x * 0.37, 0), Vector2(bar.size.x * 0.26, bar.size.y)))
			draw_rect(Rect2(bar.position + Vector2(bar.size.x * float(game.value) - 4, -8), Vector2(8, bar.size.y + 16)), UIK.NAVY)
			draw_string(UIK.bold_font, box.position + Vector2(24, 186), "%s %d / 3    %s %d" % [Game.t("Shots", "Disparos"), int(game.tries), Game.t("on target", "en el blanco"), int(game.hits)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UIK.MUTED)
		"steady":
			draw_multiline_string(UIK.body_font, box.position + Vector2(24, 72), Game.t("Hold SPACE to raise the pointer. Keep it inside the moving band.", "Mantén ESPACIO para subir el puntero. Mantenlo dentro de la banda móvil."), HORIZONTAL_ALIGNMENT_LEFT, 452, 15, 2, UIK.INK)
			UIK.bar(self, bar, 0.0, UIK.TEAL)
			draw_style_box(UIK.box(UIK.GOOD, 10, Color.TRANSPARENT, 0, 0), Rect2(bar.position + Vector2(bar.size.x * (float(game.band) - 0.14), 0), Vector2(bar.size.x * 0.28, bar.size.y)))
			draw_rect(Rect2(bar.position + Vector2(bar.size.x * float(game.value) - 4, -8), Vector2(8, bar.size.y + 16)), UIK.NAVY)
			UIK.bar(self, Rect2(box.position + Vector2(40, 164), Vector2(420, 14)), float(game.progress), UIK.CORAL)
