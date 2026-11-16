extends BaseScreen
## ETAPA 2 · MISSION OPERATIONS. Conducir, investigar, almacenar y transmitir.
## Regla central: la ciencia solo cuenta cuando la Tierra la recibe.
##
## Unidades del modelo (educativo, no cifras de la NASA): potencia en W (libro de ingeniería),
## energía almacenada en Wh, datos en MB. 1 s de juego = 10 min de misión, así que
## Wh por segundo = W / 6. Un día dura 100 s de juego y una noche 45 s (≈ un sol).

const WORLD := Vector2(3000, 2000)
const DAY := 100.0
const NIGHT := 45.0
const PASS_PERIOD := 60.0
const PASS_LENGTH := 22.0   # valor base; con la mejora «relay» vale Data.pass_length()
const FIRST_PASS := 28.0
const ZOOM := 1.3
const LANDING := Vector2(520, 1000)
const WH_PER_W := 1.0 / 6.0

var zone: Dictionary
var build: Dictionary
var plan: Dictionary
var stats: Dictionary
var has: Array = []
var rng := RandomNumberGenerator.new()
var time_limit := 300.0
var need_mb := 45.0

var pos := Vector2(520, 1000)
var vel := Vector2.ZERO
var heading := 0.0
var energy := 500.0
var integrity := 100.0
var dust := 0.0
var safe_mode := false
var clock := 0.0
var bump_cooldown := 0.0
var driven := 0.0
var net_w := 0.0

var packets: Array = []
var collected_mb := 0.0
var received_mb := 0.0
var received_science := 0.0
var unrecorded_mb := 0.0
var transmitting := false
var tubes := 0
var cached: Array = []
var meda_on := false
var meda_timer := 0.0
var meda_packets := 0
var moxie_timer := -1.0
var moxie_runs := 0
var rimfax_scans := 0
var quiz_done := {}
var quiz_correct := 0
var quiz_first := 0
var quiz_asked := 0
var energy_used := 0.0
var safe_count := 0
var mem_full_count := 0
var failed_samples := 0
var photos := 0
var analyses := 0
var used := {}             # instrumentos usados al menos una vez
var autopilot := false
var mouse_drive := false
var cam := Vector2.ZERO
var tense_now := false
var world3d: OpsWorld      # presentación 3D del mundo (no decide reglas)

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
const PINGS := {"come": {"name": ["Come here", "Ven aquí"], "color": Color("#91C6BB"), "sfx": "select"}, "stop": {"name": ["Stop", "Detente"], "color": Color("#FFAD45"), "sfx": "warn"},
	"ready": {"name": ["Target ready", "Objetivo listo"], "color": Color("#7fd68a"), "sfx": "good"}, "danger": {"name": ["Danger", "Peligro"], "color": Color("#ff6a5c"), "sfx": "warn"}}
var sub := "main"            # subnivel en juego: recon | main | arcade
var hazard := {}             # peligro arcade en curso: {kind, phase, t, pos, spots, r}
var hazard_wait := 12.0      # respiro hasta el siguiente (nunca dos a la vez)
var hazard_turn := 0
var arcade_slow := 1.0       # factor de velocidad impuesto por sismo o frente frío
var arcade_pull := Vector2.ZERO
var stun := 0.0              # segundos sin control tras un rayo
var shake := 0.0
var craters: Array = []
var arcade_hits := 0
var mate := {}               # Expedición: estado del rover que no está en foco
var lead := 0               # Expedición: jugador (0 o 1) dueño de las variables normales
var menu_pick := 0
var forced := {}             # pruebas: dirección impuesta por jugador
var ping := {}               # señal activa entre jugadores (Tripulación)
var crew_box: Panel
var toasts: Array = []
var told := {}
var required_announced := false
var confirmable := false
var hotkeys: Array = []   # botones del diálogo abierto, elegibles con 1-6
var action_bar: HBoxContainer
var coach: Dictionary = {}
var coach_step := -1
var tutorial_time := 0.0

func _ready() -> void:
	backdrop = "none"
	notice_at = Vector2(876, 150)   # bajo la tarjeta de objetivo: no tapa reloj, enlace ni acciones
	zone = Data.ZONES[Game.zone]
	build = Game.sandbox.build if Game.mode == "sandbox" else Game.build
	plan = Game.active_plan()
	stats = Data.stats(build)
	has = Data.installed(build)
	if Data.has(build, "arm"): has.append("arm")
	sub = Game.sub if Game.mode == "campaign" and Data.SUBLEVELS.has(Game.sub) else "main"
	time_limit = Data.mission_time(Game.zone, plan)
	need_mb = Data.need_mb(Game.zone, plan)
	if sub == "recon":
		# Reconocimiento: solo los dos primeros objetivos obligatorios cuentan como tales; sin tormenta.
		zone = zone.duplicate(true)
		var kept := 0
		for objective in zone.objectives:
			if bool(objective.get("opt", false)): continue
			kept += 1
			if kept > 2: objective["opt"] = true
		zone.hazards = (zone.hazards as Array).filter(func(item: String) -> bool: return item != "storm")
		time_limit *= 0.8
	rng.seed = hash(Game.zone) + 7
	var flight: Dictionary = Game.flight if Game.mode != "sandbox" else {}
	energy = float(stats.battery) * float(flight.get("charge", 1.0))
	integrity = 100.0 - float(flight.get("damage", 0.0))
	clock = float(flight.get("delay", 0.0))
	if "drill" in has or "regolith" in has: tubes = int(Data.MODEL.tubes)
	generate()
	place_landing(float(flight.get("near", float(Data.SITES[String(plan.get("site", "flat"))].near) * 0.5)))
	if expedition():
		mate = {"pos": pos + Vector2(0, 110), "vel": Vector2.ZERO, "heading": heading, "energy": energy, "integrity": integrity, "tubes": tubes, "stun": 0.0, "safe_mode": false, "dead": false}
		mouse_drive = false
	world3d = OpsWorld.make(self)
	build_action_bar()
	if crew(): build_crew_panel()
	if Game.mode == "sandbox": Game.unlock("sandbox")
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
	if "slope" in hazards: kinds += ["slope", "slope", "slope"]
	for kind in kinds:
		var center := free_spot(260, 0)
		var rx := rng.randf_range(170, 280)
		var ry := rng.randf_range(120, 200)
		patches.append({"kind": kind, "pos": center, "rx": rx, "ry": ry, "points": Art.blob(center, rx, ry, patches.size() + 3, 11, 0.15), "seed": patches.size()})
	for id in zone.rocks:
		for n in range(int(zone.rocks[id])):
			targets.append({"type": id, "pos": free_spot(240, 230), "r": rng.randf_range(30, 40), "seed": rng.randi() % 1000, "imaged": false, "photos": 0, "chem": false, "pixl": false, "sherloc": false, "cached": false, "crumbled": false})
	for i in range(int(zone.sites)):
		sites.append({"pos": free_spot(300, 260), "r": 70.0, "scanned": false})
	for i in range(64):
		obstacles.append({"pos": free_spot(60, 70), "r": rng.randf_range(18, 56), "seed": rng.randi() % 1000, "color": Art.shade(ground, rng.randf_range(-0.34, -0.18))})
	if "devils" in hazards:
		for i in range(3): devils.append({"pos": free_spot(200, 0), "dir": Vector2.from_angle(rng.randf() * TAU), "r": 46.0, "cool": 0.0, "turn": rng.randf_range(2, 5)})
	if "storm" in hazards:
		storm_start = time_limit * 0.34 * Data.storm_factor(plan)
		storm_end = storm_start + 55.0

## Sitio de aterrizaje elegido en el plan: cuanto más "cerca", más próximo a la ciencia.
func place_landing(near: float) -> void:
	if near <= 0.0 or targets.is_empty(): return
	var best: Vector2 = targets[0].pos
	for target in targets:
		if LANDING.distance_to(target.pos) < LANDING.distance_to(best): best = target.pos
	pos = LANDING.lerp(best, clampf(near, 0.0, 1.0) * 0.7)
	collide()

func light() -> float:
	var phase := fmod(clock + 12.0, DAY + NIGHT)
	if phase < DAY: return clampf(minf(phase, DAY - phase) / 8.0, 0.0, 1.0)
	return 0.0

func storming() -> bool:
	return storm_start >= 0.0 and clock >= storm_start and clock < storm_end

func pass_open() -> bool:
	return clock >= FIRST_PASS and fmod(clock - FIRST_PASS, PASS_PERIOD) < Data.pass_length()

## MB por segundo de juego. El relevo UHF solo funciona con un orbitador encima; la antena de
## alta ganancia enlaza directo en cualquier momento, más despacio (acelerada respecto a la real).
func link_rate() -> float:
	var rate := 0.0
	if pass_open() and stats.uhf: rate = float(Data.MODEL.pass_rate)
	elif stats.direct: rate = Data.direct_rate()
	return rate * (0.5 if storming() else 1.0)

func link_kind() -> String:
	if pass_open() and stats.uhf: return "uhf"
	return "hga" if stats.direct else ""

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

func deadline() -> float:
	return time_limit + tutorial_time

# ------------------------------------------------------------------ bucle
func tick(delta: float) -> void:
	if not ping.is_empty():
		ping.age = float(ping.age) + delta
		if float(ping.age) > 3.2: ping = {}
	for toast in toasts: toast.age += delta
	toasts = toasts.filter(func(item: Dictionary) -> bool: return item.age < 7.0)
	if mode == "minigame": update_minigame(delta)
	if mode in ["drive", "menu"]:
		clock += delta
		if (coach_step >= 0 and coach_step < 5) or mode == "menu": tutorial_time += delta   # ni el tutorial ni elegir una acción gastan tiempo de misión
		simulate(delta)
		update_coach()
	if expedition() and mode in ["drive", "menu", "minigame"]: simulate_mate(delta)
	if sub == "arcade" and mode == "drive": update_arcade(delta)
	if is_instance_valid(world3d): world3d.position = (Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 7.0 * minf(1.0, shake / 0.3)) if shake > 0.0 and not Game.reduced_motion else Vector2.ZERO
	if is_instance_valid(action_bar): action_bar.visible = mode == "drive"
	if is_instance_valid(crew_box): crew_box.visible = mode == "drive"
	# la música sube de tensión cuando la misión aprieta (tormenta, modo seguro, poca energía o poco tiempo)
	if mode != "ended":
		var tense := storming() or safe_mode or energy < float(stats.battery) * 0.15 or (deadline() - clock) < 40.0 or not hazard.is_empty()
		if tense != tense_now:
			tense_now = tense
			Game.play_music("tension" if tense else "explore")

func drive_wish() -> Vector2:
	if mode != "drive" or safe_mode or moxie_timer >= 0.0: return Vector2.ZERO
	var wish := Vector2.ZERO
	if expedition(): return keys_vector(lead)
	if crew(): wish = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	elif Game.input_mode != "mouse":
		wish = Input.get_vector("p1_left", "p1_right", "p1_up", "p1_down") if Game.coop else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if wish == Vector2.ZERO and mouse_drive and Game.input_mode != "keyboard" and not crew():
		var goal: Vector2 = world3d.to_world(get_local_mouse_position())
		if goal.distance_to(pos) > 34.0: wish = (goal - pos).normalized()
	if wish != Vector2.ZERO: autopilot = false
	elif autopilot:
		var goal2 := next_goal()
		if goal2 == Vector2.ZERO or pos.distance_to(goal2) < 110.0:
			autopilot = false
			say(Game.t("AutoNav: arrived. Manual control.", "AutoNav: llegada. Control manual."))
		else:
			wish = (goal2 - pos).normalized()
			for item in obstacles + targets:   # rodea obstáculos: se aparta de los que tiene delante
				var gap: Vector2 = pos - item.pos
				var near := float(item.r) + 70.0
				if gap.length() < near and item.pos.distance_to(goal2) > 60.0: wish += gap.normalized().rotated(0.9) * (1.0 - gap.length() / near) * 2.2
			wish = wish.normalized()
	return wish

func simulate(delta: float) -> void:
	bump_cooldown = maxf(0.0, bump_cooldown - delta)
	var wish := drive_wish()
	var speed := float(stats.speed)
	var terrain := float(stats.terrain)
	var in_sand := patch_at(pos, "sand")
	var on_slope := patch_at(pos, "slope")
	if in_sand: speed *= lerpf(0.45, 0.95, terrain)
	if on_slope: speed *= lerpf(0.5, 1.0, terrain)
	if integrity < 40.0: speed *= 0.8
	speed *= arcade_slow
	if stun > 0.0:
		stun = maxf(0.0, stun - delta)
		wish = Vector2.ZERO
	vel = vel.lerp(wish * speed, clampf(delta * 6.0, 0.0, 1.0)) + arcade_pull * delta
	if wish != Vector2.ZERO and transmitting:
		transmitting = false
		say(Game.t("Transmission paused: the antenna needs the rover to hold still.", "Transmisión en pausa: la antena necesita que el rover esté quieto."))
	var moving := vel.length() > 8.0
	if moving:
		heading = lerp_angle(heading, vel.angle(), clampf(delta * 8.0, 0.0, 1.0))
		pos += vel * delta
		driven += vel.length() * delta
		collide()
		if tracks.is_empty() or tracks[-1].distance_to(pos) > 26.0:
			tracks.append(pos)
			if tracks.size() > 90: tracks.pop_front()
		if patch_at(pos, "sharp"):
			integrity -= 2.4 * float(stats.wear) * delta
			tell("sharp", Game.t("Sharp rocks are chewing the wheels. Slow down or go around.", "Las rocas afiladas están dañando las ruedas. Reduce la marcha o rodéalas."))
		if in_sand: tell("sand", Game.t("Soft sand: slow and costly. Spirit was trapped in sand like this.", "Arena blanda: lenta y costosa. Spirit quedó atrapado en arena así."))
		if on_slope: tell("slope", Game.t("Slope: the rover climbs slowly and spends more energy. Better suspension helps here.", "Pendiente: el rover sube despacio y gasta más energía. Una mejor suspensión ayuda aquí."))
	pos = pos.clamp(Vector2(40, 40), WORLD - Vector2(40, 40))
	# Energía: generación (W) menos cargas (W), convertidas a Wh
	var sun := light()
	var drain := float(stats.idle_w)
	if moving: drain += float(stats.drive_w) * (vel.length() / maxf(1.0, float(stats.speed))) * (1.6 if in_sand else 1.0) * (1.5 if on_slope else 1.0)
	if autopilot: drain += float(Data.COMPONENTS.autonav.power)
	if sun <= 0.01 and stats.solar: drain += Data.heater_w()
	if patch_at(pos, "cold"):
		drain += 30.0 if stats.solar else 10.0
		tell("cold", Game.t("Cold shadow: the heaters are working hard to protect the electronics.", "Sombra fría: los calentadores trabajan duro para proteger la electrónica."))
	if meda_on: drain += float(Data.COMPONENTS.meda.power)
	if transmitting: drain += float(Data.COMPONENTS.uhf.power) if link_kind() == "uhf" else float(Data.COMPONENTS.hga.power)
	if moxie_timer >= 0.0: drain += float(Data.COMPONENTS.moxie.power)
	var charge := float(stats.gen_w)
	if stats.solar: charge *= sun * (1.0 - dust * 0.7) * (0.3 if storming() else 1.0)
	if safe_mode: drain = Data.heater_w() if stats.solar else 0.0
	net_w = charge - drain
	energy_used += drain * WH_PER_W * delta
	energy = clampf(energy + net_w * WH_PER_W * delta, 0.0, float(stats.battery))
	if stats.solar: dust = minf(1.0, dust + delta / (130.0 if storming() else 520.0))
	if energy <= 0.0 and not safe_mode:
		safe_mode = true
		safe_count += 1
		transmitting = false
		meda_on = false
		moxie_timer = -1.0
		autopilot = false
		Game.sfx("warn")
		say(Game.t("Battery empty. Safe mode: everything is off until power returns.", "Batería agotada. Modo seguro: todo apagado hasta que vuelva la energía."))
	if safe_mode and energy >= float(stats.battery) * 0.15:
		safe_mode = false
		say(Game.t("Power restored. Systems back online.", "Energía restablecida. Sistemas en línea otra vez."))
	if energy < float(stats.battery) * 0.22: tell("low", Game.t("Energy is low. Stop and recharge before the next task.", "Poca energía. Detente y recarga antes de la próxima tarea."))
	if sun <= 0.01: tell("night", Game.t("Night on Mars. Solar panels give nothing and the heaters cost energy.", "Noche en Marte. Los paneles no dan nada y los calentadores gastan energía.") if stats.solar else Game.t("Night on Mars. The generator keeps the rover alive and warm.", "Noche en Marte. El generador mantiene al rover vivo y tibio."))
	update_devils(delta)
	update_systems(delta)
	if storm_start >= 0.0:
		if meda_on and clock > storm_start - 20.0 and clock < storm_start: tell("storm_warn", Game.t("MEDA: pressure dropping. A dust storm arrives in seconds.", "MEDA: la presión cae. Una tormenta de polvo llega en segundos."))
		if storming(): tell("storm", Game.t("Dust storm. Less sunlight and a weaker link until it passes.", "Tormenta de polvo. Menos luz solar y un enlace más débil hasta que pase."))
	# V5 · aviso antes del fallo definitivo: aún hay tiempo de cambiar de ruta o terminar con lo recibido
	if integrity < 35.0 and integrity > 0.0: tell("health", Game.t("Rover health is critical. More damage will end the mission: slow down, avoid sharp rock and transmit what you have.", "La salud del rover es crítica. Más daño terminará la misión: reduce la marcha, evita la roca afilada y transmite lo que tengas."))
	if integrity <= 0.0: finish("wheels")
	elif clock >= deadline(): finish("time")
	elif not required_announced and required_done():
		required_announced = true
		Game.sfx("done")
		show_required_done()

func collide() -> void:
	for item in obstacles + targets:
		var reach: float = float(item.r) * 0.82 + 20.0
		var offset: Vector2 = pos - item.pos
		if offset.length() < reach:
			pos = item.pos + (offset.normalized() if offset.length() > 0.01 else Vector2.RIGHT) * reach
			if vel.length() > float(stats.speed) * 0.6 and bump_cooldown <= 0.0:
				integrity -= 1.5 * float(stats.hull)
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
			integrity -= 3.0 * float(stats.hull)
			vel += devil.dir * 160.0
			if stats.solar and dust > 0.12:
				dust = 0.0
				say(Game.t("A dust devil swept the solar panels clean! Real rovers got these 'cleaning events' too.", "¡Un remolino limpió los paneles solares! Los rovers reales también tuvieron estos «eventos de limpieza»."))
			else: say(Game.t("Dust devil! A small knock for the rover.", "¡Remolino de polvo! Un pequeño golpe para el rover."))

func update_systems(delta: float) -> void:
	if meda_on:
		meda_timer += delta
		if meda_timer >= 14.0:
			meda_timer = 0.0
			if store({"label": Game.t("Weather report", "Informe meteorológico"), "mb": Data.activity_mb(build, "meda"), "science": science_for("meda", 0.25), "kind": "meda"}):
				meda_packets += 1
				used["meda"] = true
				if meda_packets == 1: ask("weather", packets[-1])
	if moxie_timer >= 0.0:
		moxie_timer += delta
		if moxie_timer >= 6.0:   # 6 s de juego = 1 h de misión
			moxie_timer = -1.0
			moxie_runs += 1
			used["moxie"] = true
			if store({"label": Game.t("MOXIE oxygen run", "Prueba de oxígeno MOXIE"), "mb": Data.activity_mb(build, "moxie"), "science": science_for("moxie", 1.0), "kind": "moxie"}):
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
				received_mb += step   # cada MB se cuenta una sola vez: el paquete se borra al completarse
				if float(packet.sent) >= float(packet.mb) - 0.001:
					received_science += float(packet.science)
					packets.pop_front()
			if received_mb >= 1.0: Game.unlock("first_data")
			if packets.is_empty():
				transmitting = false
				Game.sfx("good")
				say(Game.t("All data received on Earth. The science team is already reading it.", "Todos los datos recibidos en la Tierra. El equipo científico ya los está leyendo."))
	if link_rate() > 0.0 and not packets.is_empty() and not transmitting:
		if link_kind() == "uhf": tell("pass", Game.t("An orbiter is overhead. Stop and press T to send your data.", "Hay un orbitador encima. Detente y pulsa T para enviar tus datos.") if Game.input_mode != "mouse" else Game.t("An orbiter is overhead. Stop and press Transmit to send your data.", "Hay un orbitador encima. Detente y pulsa Transmitir para enviar tus datos."))

## Puntos de ciencia de un producto: Science_Score del libro x calidad x prioridad científica del plan.
func science_for(id: String, quality: float) -> float:
	var bonus := 1.3 if id in Data.PRIORITIES[String(plan.get("priority", "context"))].kinds else 1.0
	return float(Data.COMPONENTS[id].science) * quality * bonus

func store(packet: Dictionary) -> bool:
	if memory_used() + float(packet.mb) > float(stats.memory) + 0.01:
		mem_full_count += 1
		unrecorded_mb += float(packet.mb)
		Game.sfx("warn")
		say(Game.t("Memory full. That data was not recorded: transmit or delete something to free space.", "Memoria llena. Ese dato no se grabó: transmite o borra algo para liberar espacio."))
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
		var need := float(objective.need)
		match String(objective.kind):
			"imaged": value = targets.filter(func(t: Dictionary) -> bool: return t.imaged).size()
			"angles": value = targets.filter(func(t: Dictionary) -> bool: return int(t.photos) >= 3).size()
			"chem_types":
				var kinds := {}
				for target in targets:
					if target.chem or target.pixl: kinds[target.type] = true
				value = kinds.size()
			"aqueous": value = targets.filter(func(t: Dictionary) -> bool: return (t.chem or t.pixl) and Data.ROCKS[t.type].aqueous).size()
			"pixl": value = targets.filter(func(t: Dictionary) -> bool: return t.pixl).size()
			"sherloc": value = targets.filter(func(t: Dictionary) -> bool: return t.sherloc).size()
			"quiz": value = quiz_correct
			"received":
				need = need_mb
				value = floorf(received_mb + 0.01)
			"cache_types":
				var types := {}
				for sample in cached:
					if sample.tool == "drill": types[sample.type] = true
				value = types.size()
			"cache_documented": value = cached.filter(func(s: Dictionary) -> bool: return s.documented and s.tool == "drill").size()
			"regolith": value = cached.filter(func(s: Dictionary) -> bool: return s.tool == "regolith").size()
			"meda": value = meda_packets
			"moxie": value = moxie_runs
			"rimfax": value = rimfax_scans
		var text := Game.tt(objective.text)
		if String(objective.kind) == "received": text = Game.t("Receive %d MB of science on Earth", "Recibe %d MB de ciencia en la Tierra") % int(need)
		out.append({"text": text, "value": value, "need": need, "done": value >= need, "opt": bool(objective.get("opt", false)), "kind": String(objective.kind)})
	return out

func required_done() -> bool:
	for item in objective_state():
		if not item.opt and not item.done: return false
	return true

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
	if not gate.is_empty(): return
	if expedition() and expedition_key(event):
		get_viewport().set_input_as_handled()
		return
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
	if mode != "drive": return
	if event.is_action("help"): show_help()
	elif event.is_action("data_panel"): show_data()
	elif safe_mode: return
	elif event.is_action("interact"): study_nearest()
	elif event.is_action("transmit"): toggle_transmit()
	elif event.is_action("weather"): toggle_meda()
	elif event.is_action("oxygen"): start_moxie()
	elif event.is_action("radar"): start_radar()
	elif event.is_action("autonav"): toggle_autonav()

## Ratón: mantener pulsado sobre el suelo conduce hacia el cursor; clic en una roca la estudia.
func _gui_input(event: InputEvent) -> void:
	if expedition(): return   # Expedición se juega con el teclado: el ratón no conduce
	if crew():
		crew_click(event)
		return
	if Game.input_mode == "keyboard" or not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT: return
	if mode == "minigame":
		if event.pressed: press_minigame()
		return
	if mode != "drive":
		mouse_drive = false
		return
	if not event.pressed:
		mouse_drive = false
		return
	var world: Vector2 = world3d.to_world(event.position)
	for target in targets:
		if world.distance_to(target.pos) < float(target.r) + 16.0 and pos.distance_to(target.pos) - float(target.r) < 270.0:
			if not safe_mode: show_actions(target)
			return
	mouse_drive = true

# ------------------------------------------------------------------ V5 · Desafío arcade
## Peligros ficticios y exagerados, solo en el subnivel «Desafío arcade». Ciclo de cada uno:
## aviso (texto, sonido y zona marcada) → impacto → recuperación. Nunca hay dos a la vez, entre
## uno y otro hay un respiro, y no corren mientras hay un panel abierto. El daño depende de la
## distancia y del chasis; ninguno es inevitable.
func update_arcade(delta: float) -> void:
	arcade_slow = 1.0
	arcade_pull = Vector2.ZERO
	shake = maxf(0.0, shake - delta)
	for mark in craters: mark.age = float(mark.age) + delta
	craters = craters.filter(func(mark: Dictionary) -> bool: return float(mark.age) < 30.0)
	if hazard.is_empty():
		hazard_wait -= delta
		if hazard_wait <= 0.0 and not safe_mode and deadline() - clock > 20.0: start_hazard(String(Data.ARCADE_ORDER[hazard_turn % Data.ARCADE_ORDER.size()]))
		return
	var info: Dictionary = Data.ARCADE[String(hazard.kind)]
	hazard.t = float(hazard.t) + delta
	if String(hazard.phase) == "warn":
		if float(hazard.t) >= float(info.warn):
			hazard.phase = "active"
			hazard.t = 0.0
			strike()
		return
	match String(hazard.kind):
		"quake":
			arcade_slow = 0.65
			shake = 0.2
		"cold":
			hazard.pos = (hazard.pos as Vector2) + (hazard.dir as Vector2) * 26.0 * delta
			if pos.distance_to(hazard.pos) < float(hazard.r):
				arcade_slow = 0.6
				energy = maxf(0.0, energy - (2.2 if Data.up("insulation") else 3.4) * delta)   # los calentadores trabajan más
				hazard.inside = true
		"vortex":
			var gap: float = pos.distance_to(hazard.pos)
			if gap < float(hazard.r) and gap > 1.0:
				arcade_pull = (hazard.pos as Vector2 - pos).normalized() * 170.0 * (1.0 - gap / float(hazard.r))
				if gap < 46.0 and not bool(hazard.get("hit", false)):
					hazard.hit = true
					hurt(7.0, Game.t("The vortex threw the rover.", "El vórtice lanzó al rover."))
					vel = (pos - (hazard.pos as Vector2)).normalized().rotated(1.2) * 260.0
	if float(hazard.t) >= float(info.active): end_hazard()

func start_hazard(kind: String) -> void:
	hazard_turn += 1
	var ahead := pos + vel * 1.1
	hazard = {"kind": kind, "phase": "warn", "t": 0.0, "pos": ahead, "r": 0.0, "spots": []}
	match kind:
		"meteor":
			hazard.pos = (ahead + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20.0, 90.0)).clamp(Vector2(120, 120), WORLD - Vector2(120, 120))
			hazard.r = 150.0
		"lightning":
			for i in range(4): (hazard.spots as Array).append((pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(40.0, 250.0)).clamp(Vector2(60, 60), WORLD - Vector2(60, 60)))
			hazard.r = 74.0
		"cold":
			var from := Vector2.from_angle(rng.randf() * TAU)
			hazard.pos = (pos + from * 420.0).clamp(Vector2(0, 0), WORLD)
			hazard["dir"] = (pos - (hazard.pos as Vector2)).normalized()
			hazard.r = 250.0
		"vortex":
			hazard.pos = (pos + Vector2.from_angle(rng.randf() * TAU) * 230.0).clamp(Vector2(100, 100), WORLD - Vector2(100, 100))
			hazard.r = 320.0
	Game.sfx("warn")

func strike() -> void:
	match String(hazard.kind):
		"meteor":
			var gap: float = pos.distance_to(hazard.pos)
			craters.append({"pos": hazard.pos, "r": float(hazard.r) * 0.55, "age": 0.0})
			shake = 0.5
			Game.sfx("bump")
			if gap < float(hazard.r):
				hurt(16.0 * (1.0 - gap / float(hazard.r)), Game.t("Meteor impact nearby.", "Impacto de meteorito cerca."))
				vel += (pos - (hazard.pos as Vector2)).normalized() * 220.0 * (1.0 - gap / float(hazard.r))
		"lightning":
			Game.sfx("error")
			shake = 0.25
			for spot in hazard.spots:
				if pos.distance_to(spot) < float(hazard.r):
					stun = 2.2
					energy = maxf(0.0, energy - float(stats.battery) * 0.06)
					hurt(3.0, Game.t("Lightning: systems restart in a moment.", "Rayo: los sistemas se reinician en un momento."))
					break
		"quake":
			Game.sfx("bump")
		"cold":
			Game.sfx("link")
		"vortex":
			Game.sfx("link")

func hurt(amount: float, text: String) -> void:
	arcade_hits += 1
	integrity -= amount * float(stats.hull)
	say(text)
	if integrity < 35.0 and integrity > 0.0: tell("health", Game.t("Rover health is critical. More damage will end the mission: slow down, avoid sharp rock and transmit what you have.", "La salud del rover es crítica. Más daño terminará la misión: reduce la marcha, evita la roca afilada y transmite lo que tengas."))
	if integrity <= 0.0: finish("wheels")

func end_hazard() -> void:
	hazard = {}
	hazard_wait = rng.randf_range(9.0, 14.0)   # respiro
	arcade_slow = 1.0
	arcade_pull = Vector2.ZERO

## Disco relleno sobre el terreno (32 puntos sin repetir; si queda degenerado no se dibuja).
func fill_ring(center: Vector2, radius: float, color: Color, lift: float = 0.1) -> void:
	var points := PackedVector2Array()
	for i in range(32): points.append(world3d.to_screen(center + Vector2.from_angle(TAU * i / 32.0) * radius, lift))
	if points[0].distance_to(points[16]) < 4.0 or points[8].distance_to(points[24]) < 4.0: return
	draw_colored_polygon(points, color)

func ring_points(center: Vector2, radius: float, lift: float = 0.1) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(33): points.append(world3d.to_screen(center + Vector2.from_angle(TAU * i / 32.0) * radius, lift))
	return points

func draw_arcade() -> void:
	for mark in craters:
		var fade := clampf(1.0 - float(mark.age) / 30.0, 0.0, 1.0)
		fill_ring(mark.pos, float(mark.r), Color(0.1, 0.07, 0.08, 0.45 * fade), 0.05)
	if hazard.is_empty(): return
	var info: Dictionary = Data.ARCADE[String(hazard.kind)]
	var tint: Color = info.color
	var warn: bool = String(hazard.phase) == "warn"
	var left := (float(info.warn) - float(hazard.t)) if warn else (float(info.active) - float(hazard.t))
	var blink := 0.55 + 0.45 * sin(float(hazard.t) * 16.0) if warn and not Game.reduced_motion else 1.0
	match String(hazard.kind):
		"meteor":
			if warn:
				fill_ring(hazard.pos, float(hazard.r), Color(tint, 0.16 + 0.12 * blink))
				draw_polyline(ring_points(hazard.pos, float(hazard.r)), Color(tint, blink), 5.0)
				draw_polyline(ring_points(hazard.pos, float(hazard.r) * clampf(left / float(info.warn), 0.05, 1.0)), UIK.PAPER, 3.0)
			else: fill_ring(hazard.pos, float(hazard.r) * (0.6 + float(hazard.t)), Color(1.0, 0.85, 0.6, 0.5 * (1.0 - float(hazard.t) / float(info.active))))
		"lightning":
			for spot in hazard.spots:
				fill_ring(spot, float(hazard.r), Color(tint, (0.14 + 0.14 * blink) if warn else 0.5))
				draw_polyline(ring_points(spot, float(hazard.r)), Color(tint, blink), 4.0)
				if not warn:
					var ground: Vector2 = world3d.to_screen(spot, 0.1)
					draw_polyline(PackedVector2Array([ground + Vector2(-14, -330), ground + Vector2(10, -220), ground + Vector2(-12, -120), ground]), UIK.PAPER, 6.0)
		"cold":
			var cloud := ring_points(hazard.pos, float(hazard.r), 0.6)
			fill_ring(hazard.pos, float(hazard.r), Color(tint, 0.2 if warn else 0.34), 0.6)
			fill_ring((hazard.pos as Vector2) + Vector2(40, -20), float(hazard.r) * 0.7, Color(0.85, 0.92, 1.0, 0.12 if warn else 0.22), 0.9)
			draw_polyline(cloud, Color(tint, 0.9), 3.0)
		"vortex":
			draw_polyline(ring_points(hazard.pos, float(hazard.r)), Color(tint, 0.8 * blink), 4.0)
			for i in range(3):
				var radius := float(hazard.r) * (0.25 + 0.22 * i)
				var turn := float(hazard.t) * (2.4 if not Game.reduced_motion else 0.0) + i * TAU / 3.0
				var arc := PackedVector2Array()
				for step in range(13): arc.append(world3d.to_screen((hazard.pos as Vector2) + Vector2.from_angle(turn + step * 0.19) * radius, 0.3 + 0.25 * i))
				draw_polyline(arc, Color(tint, 0.9), 5.0)
		"quake":
			pass
	var box := Rect2(390, 210, 500, 66)
	draw_style_box(UIK.box(Color(UIK.INK, 0.92), 16, tint, 4, 4), box)
	draw_string(UIK.title_font, Vector2(box.position.x, box.position.y + 28), "%s  ·  %s" % [Game.tt(info.name), (Game.t("in %d s", "en %d s") % int(ceil(left))) if warn else (Game.t("%d s left", "quedan %d s") % int(ceil(left)))], HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 22, tint)
	draw_string(UIK.bold_font, Vector2(box.position.x, box.position.y + 52), Game.tt(info["do"]) + Game.t("  ·  fictional", "  ·  ficticio"), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, UIK.PAPER)
	if stun > 0.0: outlined(world3d.to_screen(pos, 1.6), Game.t("RESTARTING…", "REINICIANDO…"), tint, 16, 240.0)

# ------------------------------------------------------------------ V5 · cooperativo «Tripulación»
## Un rover, dos papeles activos: el jugador 1 conduce con el teclado y el jugador 2 hace la
## ciencia con el ratón. El ratón no conduce: elige rocas, usa instrumentos y envía señales.
# ------------------------------------------------------------------ V5 · cooperativo «Expedición»
## Dos rovers en la misma misión. Los datos de `OWN` son de cada rover; reloj, memoria, datos,
## objetivos y recompensas son de la misión y existen una sola vez. Las variables normales
## describen el rover «en foco» (el del jugador `lead`); el otro vive en `mate`. Cuando el otro
## jugador interactúa, se intercambian: así toda la lógica de estudio y minijuegos sirve a los dos.
const OWN := ["pos", "vel", "heading", "energy", "integrity", "tubes", "stun", "safe_mode"]

func expedition() -> bool:
	return Game.coop and Game.coop_mode == "expedition"

func player_pos(player: int) -> Vector2:
	return pos if lead == player or mate.is_empty() else mate.pos

func player_state(player: int) -> Dictionary:
	if lead == player or mate.is_empty(): return {"energy": energy, "integrity": integrity, "dead": false, "safe_mode": safe_mode}
	return mate

func swap_focus() -> void:
	for key in OWN:
		var kept = get(key)
		set(key, mate[key])
		mate[key] = kept
	lead = 1 - lead
	transmitting = false
	autopilot = false

func keys_vector(player: int) -> Vector2:
	if forced.has(player): return forced[player]
	var k: Array = [KEY_A, KEY_D, KEY_W, KEY_S] if player == 0 else [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
	var v := Vector2(float(Input.is_physical_key_pressed(k[1])) - float(Input.is_physical_key_pressed(k[0])), float(Input.is_physical_key_pressed(k[3])) - float(Input.is_physical_key_pressed(k[2])))
	return v.normalized() if v.length() > 1.0 else v

## El rover que no está en foco: movimiento, choques, energía y desgaste propios.
func simulate_mate(delta: float) -> void:
	if mate.is_empty() or bool(mate.get("dead", false)): return
	var want := keys_vector(1 - lead)
	if bool(mate.safe_mode) or float(mate.stun) > 0.0: want = Vector2.ZERO
	mate.stun = maxf(0.0, float(mate.stun) - delta)
	var at: Vector2 = mate.pos
	var speed := float(stats.speed)
	if patch_at(at, "sand"): speed *= lerpf(0.45, 0.95, float(stats.terrain))
	if patch_at(at, "slope"): speed *= lerpf(0.5, 1.0, float(stats.terrain))
	var v: Vector2 = (mate.vel as Vector2).lerp(want * speed, clampf(delta * 6.0, 0.0, 1.0))
	var moving := v.length() > 8.0
	if moving:
		mate.heading = lerp_angle(float(mate.heading), v.angle(), clampf(delta * 8.0, 0.0, 1.0))
		at += v * delta
		for item in obstacles + targets:
			var reach: float = float(item.r) * 0.82 + 20.0
			var offset: Vector2 = at - item.pos
			if offset.length() < reach: at = item.pos + (offset.normalized() if offset.length() > 0.01 else Vector2.RIGHT) * reach
		if patch_at(at, "sharp"): mate.integrity = float(mate.integrity) - 2.4 * float(stats.wear) * delta
	# los dos rovers no se atraviesan
	var apart: Vector2 = at - pos
	if apart.length() < 70.0: at = pos + (apart.normalized() if apart.length() > 0.01 else Vector2.RIGHT) * 70.0
	mate.pos = at.clamp(Vector2(40, 40), WORLD - Vector2(40, 40))
	mate.vel = v
	var drain := float(stats.idle_w) + (float(stats.drive_w) * (v.length() / maxf(1.0, float(stats.speed))) if moving else 0.0)
	var charge := float(stats.gen_w) * ((light() * (1.0 - dust * 0.7) * (0.3 if storming() else 1.0)) if stats.solar else 1.0)
	mate.energy = clampf(float(mate.energy) + (charge - drain) * WH_PER_W * delta, 0.0, float(stats.battery))
	if float(mate.energy) <= 0.0: mate.safe_mode = true
	elif bool(mate.safe_mode) and float(mate.energy) >= float(stats.battery) * 0.15: mate.safe_mode = false
	if float(mate.integrity) <= 0.0:
		mate.dead = true
		mate.vel = Vector2.ZERO
		say(Game.t("Player %d's rover is disabled. The other rover carries on.", "El rover del jugador %d quedó inutilizado. El otro rover sigue.") % (2 - lead))

## Teclas de Expedición. Devuelve true si la tecla quedó atendida.
func expedition_key(event: InputEventKey) -> bool:
	var who := -1
	var act := ""
	var table := {KEY_E: [0, "interact"], KEY_SPACE: [0, "action"], KEY_T: [0, "transmit"], KEY_PERIOD: [1, "interact"], KEY_ENTER: [1, "action"], KEY_KP_ENTER: [1, "action"], KEY_COMMA: [1, "transmit"]}
	if table.has(event.physical_keycode):
		who = int(table[event.physical_keycode][0])
		act = String(table[event.physical_keycode][1])
	if who < 0: return false
	if mode == "minigame":
		if who == lead: press_minigame()
		return true
	if mode == "menu":
		if who != lead or hotkeys.is_empty(): return true
		if act == "interact":
			for step in range(hotkeys.size()):
				menu_pick = (menu_pick + 1) % hotkeys.size()
				if not (hotkeys[menu_pick] as Button).disabled: break
			mark_pick()
		elif act == "action" and menu_pick < hotkeys.size() and not (hotkeys[menu_pick] as Button).disabled: (hotkeys[menu_pick] as Button).pressed.emit()
		return true
	if mode != "drive": return false
	if bool(player_state(who).get("dead", false)): return true
	if who != lead: swap_focus()
	if safe_mode: return true
	if act == "interact":
		study_nearest()
		if mode == "menu":
			menu_pick = 0
			for i in range(hotkeys.size()):
				if not (hotkeys[i] as Button).disabled:
					menu_pick = i
					break
			mark_pick()
	elif act == "transmit": toggle_transmit()
	return true

func mark_pick() -> void:
	for i in range(hotkeys.size()):
		if is_instance_valid(hotkeys[i]): (hotkeys[i] as Button).modulate = Color(1.0, 0.92, 0.6) if i == menu_pick else Color.WHITE

func draw_expedition() -> void:
	draw_rect(Rect2(638, 0, 4, 720), UIK.INK)
	for player in [0, 1]:
		var state := player_state(player)
		var tint: Color = UIK.P1 if player == 0 else UIK.P2
		var x: float = 150.0 + 642.0 * float(player)
		var text := "%s  ·  ⚡ %d%%  ·  ♥ %d%%%s" % [Game.t("P%d", "J%d") % (player + 1), int(100.0 * float(state.energy) / maxf(1.0, float(stats.battery))), int(maxf(0.0, float(state.integrity))), Game.t("  ·  DISABLED", "  ·  INUTILIZADO") if bool(state.get("dead", false)) else ""]
		draw_style_box(UIK.box(Color(UIK.INK, 0.88), 12, tint, 3, 2), Rect2(x, 150, 330, 34))
		draw_string(UIK.bold_font, Vector2(x, 173), text, HORIZONTAL_ALIGNMENT_CENTER, 330, 16, tint)
		# etiqueta sobre cada rover en las dos vistas
		for seen in [0, 1]:
			var at: Vector2 = world3d.to_screen(player_pos(player), 1.7) if seen == 0 else world3d.to_screen2(player_pos(player), 1.7)
			if (seen == 0 and at.x < 630.0 and at.x > 0.0) or (seen == 1 and at.x > 650.0 and at.x < 1280.0): outlined(at, Game.t("P%d", "J%d") % (player + 1), tint, 16, 80.0)
	outlined(Vector2(320, 206), Game.t("W A S D · E · Space · T", "W A S D · E · Espacio · T"), UIK.PAPER, 13, 330.0)
	outlined(Vector2(960, 206), Game.t("arrows · period · Enter · comma", "flechas · punto · Intro · coma"), UIK.PAPER, 13, 330.0)

func crew() -> bool:
	return Game.coop and Game.coop_mode == "crew"

func crew_click(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: return
	if mode == "minigame":
		press_minigame()
		return
	if mode != "drive": return
	var world: Vector2 = world3d.to_world(event.position)
	for target in targets:
		if world.distance_to(target.pos) > float(target.r) + 18.0: continue
		if pos.distance_to(target.pos) - float(target.r) < 270.0 and not safe_mode:
			say(Game.t("P2 is studying the rock: the rover waits.", "J2 estudia la roca: el rover espera."))
			show_actions(target)
		else: send_ping("come", target.pos)
		return
	send_ping("come", world)   # en el suelo: una señal para el conductor, no una orden de marcha

## Señal entre jugadores: texto grande un momento y, si lleva punto, un marcador en el terreno.
func send_ping(kind: String, at = null) -> void:
	var info: Dictionary = PINGS[kind]
	ping = {"kind": kind, "age": 0.0, "pos": at}
	Game.sfx(String(info.sfx))

func build_crew_panel() -> void:
	crew_box = UIK.panel(self, Rect2(14, 226, 190, 284), Color(UIK.INK, 0.86))
	var column := UIK.column(crew_box, Rect2(12, 10, 166, 264), 5)
	UIK.label(column, Game.t("P1 drives · keyboard", "J1 conduce · teclado"), 13, UIK.P1, "bold")
	UIK.label(column, Game.t("P2 science · mouse", "J2 ciencia · ratón"), 13, UIK.P2, "bold")
	for kind in ["come", "stop", "ready", "danger"]:
		var info: Dictionary = PINGS[kind]
		var b := UIK.button(column, Game.tt(info.name), func() -> void: send_ping(kind, signal_point(kind)), "ghost", Vector2(166, 36))
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 14)
		b.tooltip_text = Game.t("Signal for the other player", "Señal para el otro jugador")

## «Ven aquí» señala la roca sin estudiar más cercana; las demás señales no llevan punto.
func signal_point(kind: String):
	if kind != "come": return null
	var best: Variant = null
	var far := 1.0e9
	for target in targets:
		if target_complete(target): continue
		var gap: float = pos.distance_to(target.pos)
		if gap < far:
			far = gap
			best = target.pos
	return best

func target_complete(target: Dictionary) -> bool:
	for id in Data.ROCK_ACTIONS:
		if id in has and not action_done(id, target): return false
	return true

func draw_ping() -> void:
	if ping.is_empty(): return
	var info: Dictionary = PINGS[String(ping.kind)]
	var tint: Color = info.color
	if ping.pos != null:
		var at: Vector2 = world3d.to_screen(ping.pos, 0.3)
		var pulse := 26.0 + 8.0 * sin(float(ping.age) * 7.0) * (0.0 if Game.reduced_motion else 1.0)
		draw_arc(at, pulse, 0.0, TAU, 28, UIK.INK, 8.0)
		draw_arc(at, pulse, 0.0, TAU, 28, tint, 4.0)
		outlined(at + Vector2(0, -pulse - 10.0), Game.tt(info.name).to_upper(), tint, 16, 220.0)
	var box := Rect2(440, 150, 400, 54)
	draw_style_box(UIK.box(Color(UIK.INK, 0.9), 16, tint, 4, 4), box)
	draw_string(UIK.title_font, Vector2(box.position.x, box.position.y + 36), Game.tt(info.name).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 24, tint)

func study_nearest() -> void:
	if mode != "drive" or safe_mode: return
	var target := nearest_target()
	if not site_here().is_empty() and "rimfax" in has: start_radar()
	elif not target.is_empty(): show_actions(target)
	else: say(Game.t("No rock in range. Follow the yellow arrow to the nearest target.", "No hay rocas al alcance. Sigue la flecha amarilla hasta el objetivo más cercano."))

func toggle_transmit() -> void:
	if mode != "drive": return
	if transmitting:
		transmitting = false
		return
	if packets.is_empty(): say(Game.t("Nothing to send yet. Use an instrument on a rock first.", "Aún no hay nada que enviar. Usa primero un instrumento en una roca."))
	elif not stats.uhf and not stats.direct: say(Game.t("This rover has no antenna.", "Este rover no tiene antena."))
	elif link_rate() <= 0.0: say(Game.t("No link. The UHF relay needs an orbiter overhead: wait for the next pass.", "Sin enlace. El relevo UHF necesita un orbitador encima: espera el próximo paso."))
	elif vel.length() > 12.0: say(Game.t("Stop the rover before transmitting.", "Detén el rover antes de transmitir."))
	else:
		transmitting = true
		autopilot = false
		Game.sfx("link")

func toggle_meda() -> void:
	if mode != "drive": return
	if not "meda" in has:
		say(Game.t("MEDA was not installed on this rover.", "MEDA no se instaló en este rover."))
		return
	meda_on = not meda_on
	say(Game.t("MEDA weather station ON: logging wind, temperature and dust (15 W).", "Estación MEDA ENCENDIDA: registra viento, temperatura y polvo (15 W).") if meda_on else Game.t("MEDA off.", "MEDA apagada."))

func start_moxie() -> void:
	if mode != "drive": return
	var cost := Data.activity_wh(build, "moxie") if "moxie" in has else 0.0
	if not "moxie" in has: say(Game.t("MOXIE was not installed on this rover.", "MOXIE no se instaló en este rover."))
	elif moxie_timer >= 0.0: pass
	elif energy + float(stats.gen_w) * (light() if stats.solar else 1.0) < cost * 0.8: say(Game.t("MOXIE draws 300 W for an hour (300 Wh). Charge the battery first.", "MOXIE consume 300 W durante una hora (300 Wh). Carga primero la batería."))
	else:
		moxie_timer = 0.0
		transmitting = false
		autopilot = false
		say(Game.t("MOXIE running: splitting CO2 into oxygen. Hold position.", "MOXIE en marcha: separa el CO2 para obtener oxígeno. Mantén la posición."))

func start_radar() -> void:
	if mode != "drive": return
	if not "rimfax" in has:
		say(Game.t("RIMFAX was not installed on this rover.", "RIMFAX no se instaló en este rover."))
		return
	var site := site_here()
	if site.is_empty(): say(Game.t("Drive onto a radar site (dashed circle) to scan.", "Conduce sobre un sitio de radar (círculo punteado) para escanear."))
	elif energy < Data.activity_wh(build, "rimfax") + 20.0: say(Game.t("Not enough energy for a radar scan.", "Energía insuficiente para un escaneo de radar."))
	else: run_instrument("rimfax", site)

func toggle_autonav() -> void:
	if mode != "drive": return
	if not stats.autonav:
		say(Game.t("AutoNav was not installed (it needs the advanced computer).", "AutoNav no se instaló (necesita la computadora avanzada)."))
		return
	autopilot = not autopilot
	transmitting = false
	say(Game.t("AutoNav ON: driving to the next target (+50 W).", "AutoNav ACTIVADO: conduciendo al siguiente objetivo (+50 W).") if autopilot else Game.t("AutoNav off.", "AutoNav apagado."))

# ------------------------------------------------------------- barra de acciones
## La exploración gestiona Esc por su cuenta (pausa y cierre de paneles).
func handle_escape() -> void:
	pass

func build_action_bar() -> void:
	action_bar = UIK.row(self, 6)
	var items := [[Game.t("Study", "Estudiar"), "E", study_nearest, true], [Game.t("Transmit", "Transmitir"), "T", toggle_transmit, stats.uhf or stats.direct], [Game.t("Data", "Datos"), "Tab", show_data, true],
		["MEDA", "M", toggle_meda, "meda" in has], ["MOXIE", "O", start_moxie, "moxie" in has], ["Radar", "R", start_radar, "rimfax" in has], ["AutoNav", "G", toggle_autonav, bool(stats.autonav)],
		[Game.t("Controls", "Controles"), "H", show_help, true], [Game.t("Pause", "Pausa"), "Esc", show_pause, true]]
	for item in items:
		if not item[3]: continue
		var caption := String(item[0]) if Game.input_mode == "mouse" else "%s  [%s]" % [String(item[0]), String(item[1])]
		var callback: Callable = item[2]
		var b := UIK.button(action_bar, caption, func() -> void:
			if mode == "drive": callback.call(), "dark", Vector2(0, 38))
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 14)
		b.set_meta("key", String(item[1]))
	action_bar.position = Vector2(640 - action_bar.get_minimum_size().x * 0.5, 672)
	action_bar.reset_size()
	action_bar.position.x = 640 - action_bar.size.x * 0.5

# ------------------------------------------------------------- diálogos
func close_dialog() -> void:
	if is_instance_valid(dialog): dialog.queue_free()
	dialog = null
	if mode != "ended": mode = "drive"
	mouse_drive = false

func open_panel(rect: Rect2) -> Panel:
	if is_instance_valid(dialog): dialog.queue_free()
	var panel := UIK.panel(self, rect)
	dialog = panel
	confirmable = true
	hotkeys = []
	mouse_drive = false
	UIK.pop(panel)
	return panel

func show_brief() -> void:
	mode = "brief"
	var panel := open_panel(Rect2(250, 90, 780, 540))
	portrait(panel, Rect2(24, 22, 130, 130))
	var column := UIK.column(panel, Rect2(172, 20, 584, 420), 6)
	UIK.label(column, Game.owen() + " · " + Game.t("Mission science", "Ciencia de misión"), 15, UIK.TEAL, "bold")
	UIK.label(column, "%s · %s" % [Game.tt(zone.goal), Game.tt(zone.name)], 28, UIK.NAVY, "title")
	UIK.text(column, Game.t("%s is on the surface. ", "%s está en la superficie. ") % Game.rover_name + Game.tt(zone.brief), 16, UIK.INK)
	UIK.label(column, Game.t("REQUIRED · they complete the mission", "REQUERIDOS · completan la misión"), 13, UIK.RUST, "bold")
	for item in objective_state():
		if not item.opt: UIK.text(column, "☐  " + String(item.text), 15, UIK.INK)
	UIK.label(column, Game.t("OPTIONAL · extra science", "OPCIONALES · ciencia extra"), 13, UIK.TEAL, "bold")
	for item in objective_state():
		if item.opt: UIK.text(column, "◦  " + String(item.text), 14, UIK.MUTED)
	var note := Game.t("Science only counts when Earth receives it.", "La ciencia solo cuenta cuando la Tierra la recibe.")
	if sub == "arcade": UIK.text(column, Game.t("ARCADE CHALLENGE · meteors, lightning, quakes, cold fronts and vortices here are fictional and exaggerated. Each one warns first: watch the marked ground. No science points, no achievements.", "DESAFÍO ARCADE · los meteoritos, rayos, sismos, frentes fríos y vórtices de aquí son ficticios y exagerados. Todos avisan antes: mira el suelo marcado. No da puntos de ciencia ni logros."), 14, UIK.BAD)
	elif sub == "recon": UIK.text(column, Game.t("RECONNAISSANCE · a short first drive. Only the first two objectives are required.", "RECONOCIMIENTO · una primera salida corta. Solo son obligatorios los dos primeros objetivos."), 14, UIK.TEAL)
	if expedition(): note = Game.t("EXPEDITION · two rovers, one mission. P1: W A S D, E study, Space action, T transmit. P2: arrows, period study, Enter action, comma transmit. Data, objectives and the clock are shared; energy and health belong to each rover.", "EXPEDICIÓN · dos rovers, una misión. J1: W A S D, E estudiar, Espacio acción, T transmitir. J2: flechas, punto estudiar, Intro acción, coma transmitir. Datos, objetivos y reloj son compartidos; la energía y la salud son de cada rover.")
	elif crew(): note = Game.t("CREW · Player 1 drives with W A S D or the arrows and transmits with T. Player 2 clicks rocks, runs the instruments and sends signals with the mouse.", "TRIPULACIÓN · El jugador 1 conduce con W A S D o las flechas y transmite con T. El jugador 2 hace clic en las rocas, usa los instrumentos y envía señales con el ratón.")
	elif Game.coop: note = Game.t("CO-OP · Commander: ARROWS drive, T transmits. Engineer: E studies, SPACE runs instruments, M/O/R/G tools. Ending the mission needs both.", "COOPERATIVO · Comandante: FLECHAS conducen, T transmite. Ingeniero: E estudia, ESPACIO opera instrumentos, M/O/R/G herramientas. Terminar la misión exige a ambos.")
	elif Game.mode == "sandbox": note = Game.t("SANDBOX test drive: nothing here is saved to your campaign.", "Prueba de SANDBOX: nada de esto se guarda en tu campaña.")
	UIK.text(column, note, 15, UIK.RUST)
	var start := UIK.button(panel, Game.t("Begin operations →", "Iniciar operaciones →"), begin, "go", Vector2(320, 56))
	start.position = Vector2(230, 464)
	start.focus_mode = Control.FOCUS_NONE

func begin() -> void:
	close_dialog()
	if Game.mode == "campaign" and not Game.coop and not bool(Game.tutorial.get("ops", false)): start_coach()

func show_pause() -> void:
	if mode != "drive": return
	mode = "paused"
	var panel := open_panel(Rect2(410, 64, 460, 596))
	var column := UIK.column(panel, Rect2(30, 20, 400, 560), 8)
	UIK.label(column, Game.t("Mission paused", "Misión en pausa"), 30, UIK.NAVY, "title")
	for item in [[Game.t("Resume", "Continuar"), close_dialog, "go"], [Game.t("Controls", "Controles"), show_help, "primary"], [Game.t("Objectives", "Objetivos"), show_goals, "primary"],
		[Game.t("Stuck? How to recover", "¿Atascado? Cómo recuperarte"), show_recovery, "teal"], [Game.t("Replay the tutorial", "Repetir el tutorial"), replay_coach, "ghost"], [Game.t("Settings", "Ajustes"), open_settings, "ghost"],
		[Game.t("End mission and debrief", "Terminar misión e informe"), ask_finish, "primary"], [Game.t("Abort to base (no report)", "Abortar a la base (sin informe)"), abort, "ghost"]]:
		var b := UIK.button(column, "%d   %s" % [hotkeys.size() + 1, String(item[0])], item[1], String(item[2]), Vector2(400, 50))
		b.focus_mode = Control.FOCUS_NONE
		hotkeys.append(b)
	confirmable = false

func open_settings() -> void:
	Settings.open(self, func() -> void: pass)

## Lista completa de objetivos (el HUD solo muestra el actual).
func show_goals() -> void:
	mode = "paused"
	var panel := open_panel(Rect2(290, 90, 700, 540))
	var column := UIK.column(panel, Rect2(30, 20, 640, 430), 6)
	UIK.label(column, Game.t("Mission objectives", "Objetivos de la misión"), 30, UIK.NAVY, "title")
	for pass_opt in [false, true]:
		UIK.label(column, Game.t("OPTIONAL · extra science", "OPCIONALES · ciencia extra") if pass_opt else Game.t("REQUIRED · they complete the mission", "REQUERIDOS · completan la misión"), 13, UIK.TEAL if pass_opt else UIK.RUST, "bold")
		for goal in objective_state():
			if bool(goal.opt) != pass_opt: continue
			var line := UIK.row(column, 8)
			UIK.picture(line, UIK.tex("pin_completed" if goal.done else "pin_mission"), Vector2(26, 26))
			UIK.text(line, String(goal.text), 16, UIK.GOOD if goal.done else UIK.INK)
			UIK.chip(line, " %d/%d " % [int(minf(goal.value, goal.need)), int(goal.need)], UIK.GOOD if goal.done else UIK.NAVY)
	var ok := UIK.button(panel, Game.t("Close", "Cerrar"), close_dialog, "primary", Vector2(220, 48))
	ok.position = Vector2(240, 474)
	ok.focus_mode = Control.FOCUS_NONE

## Qué hacer cuando la misión se complica. Son las reglas reales del juego, en corto.
func show_recovery() -> void:
	mode = "paused"
	var panel := open_panel(Rect2(250, 70, 780, 580))
	var column := UIK.column(panel, Rect2(30, 20, 720, 470), 8)
	UIK.label(column, Game.t("Stuck? How to recover", "¿Atascado? Cómo recuperarte"), 30, UIK.NAVY, "title")
	for item in [["up_power", Game.t("No energy (safe mode): stop and wait. Solar panels recharge in daylight; an RTG charges day and night.", "Sin energía (modo seguro): detente y espera. Los paneles recargan de día; un RTG carga de día y de noche.")],
		["up_storage", Game.t("Memory full: transmit, or open Data and delete what is worth least.", "Memoria llena: transmite, o abre Datos y borra lo que valga menos.")],
		["up_range", Game.t("No link: the UHF relay needs an orbiter overhead. Watch the timer at the top and stop before it arrives.", "Sin enlace: el relevo UHF necesita un orbitador encima. Mira el contador de arriba y detente antes de que llegue.")],
		["comp_wheel", Game.t("Wheels wearing out: leave the dark sharp-rock patches. Slopes and sand only slow you down.", "Ruedas desgastándose: sal de las zonas oscuras de roca afilada. Las pendientes y la arena solo te frenan.")],
		["nav_workshop", Game.t("Missing an instrument for a required objective: end the mission. The debrief tells you what to change, and “Redesign and retry” keeps your campaign.", "Te falta un instrumento para un objetivo requerido: termina la misión. El informe te dice qué cambiar, y «Rediseñar y reintentar» conserva tu campaña.")],
		["pin_main", Game.t("Short on time: transmit what you have. Science only counts once Earth receives it.", "Poco tiempo: transmite lo que tengas. La ciencia solo cuenta cuando la Tierra la recibe.")]]:
		var line := UIK.row(column, 10)
		UIK.picture(line, UIK.tex(String(item[0])), Vector2(40, 40))
		UIK.text(line, String(item[1]), 16, UIK.INK)
	UIK.text(column, Game.t("Time does not run while the game is paused, during the tutorial or while you choose an instrument.", "El tiempo no corre con el juego en pausa, durante el tutorial ni mientras eliges un instrumento."), 14, UIK.TEAL)
	var ok := UIK.button(panel, Game.t("Close", "Cerrar"), close_dialog, "primary", Vector2(220, 48))
	ok.position = Vector2(280, 514)
	ok.focus_mode = Control.FOCUS_NONE

func replay_coach() -> void:
	close_dialog()
	Game.tutorial["ops"] = false
	Game.tutorial["ops_step"] = 0
	coach_step = 0
	show_coach()

## Abandonar la misión: primero se confirma; después se vuelve a la base. Nunca cierra el juego.
func abort() -> void:
	if mode == "ended": return
	close_dialog()
	mode = "paused"
	var panel := open_panel(Rect2(380, 220, 520, 280))
	var column := UIK.column(panel, Rect2(26, 18, 468, 244), 8)
	UIK.label(column, Game.t("Leave the mission?", "¿Abandonar la misión?"), 26, UIK.NAVY, "title")
	UIK.text(column, Game.t("You go back to the base with no report. Science not yet received on Earth is lost; your saved progress stays.", "Vuelves a la base sin informe. La ciencia que aún no llegó a la Tierra se pierde; tu progreso guardado se conserva."), 15, UIK.INK)
	var line := UIK.row(column, 10)
	var stay := UIK.button(line, Game.t("1   Keep playing", "1   Seguir jugando"), close_dialog, "go", Vector2(228, 50))
	var leave := UIK.button(line, Game.t("2   Leave to base", "2   Salir a la base"), leave_mission, "ghost", Vector2(228, 50))
	for b in [stay, leave]:
		b.focus_mode = Control.FOCUS_NONE
		hotkeys.append(b)
	confirmable = false

func leave_mission() -> void:
	if mode == "ended": return
	mode = "ended"
	transmitting = false
	halt_inputs()
	Game.go("design" if Game.mode == "sandbox" else "hub")

## Suelta las acciones de movimiento: nada queda «pulsado» al cambiar de pantalla.
func halt_inputs() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "p1_left", "p1_right", "p1_up", "p1_down", "interact"]:
		if InputMap.has_action(action): Input.action_release(action)

func show_help() -> void:
	if not mode in ["drive", "paused"]: return
	mode = "paused"
	var panel := open_panel(Rect2(190, 70, 900, 580))
	var column := UIK.column(panel, Rect2(30, 20, 840, 470), 6)
	UIK.label(column, Game.t("Controls", "Controles"), 30, UIK.NAVY, "title")
	Settings.controls(column)
	UIK.label(column, Game.t("ON THE MAP", "EN EL MAPA"), 13, UIK.MUTED, "bold")
	UIK.text(column, Game.t("Yellow ring: rock not studied yet · green ring: studied · yellow arrow: nearest target · dashed circle: radar site · dark patches: sharp rock · pale patches: sand · striped patches: slope · blue patches: cold shadow.", "Anillo amarillo: roca sin estudiar · anillo verde: estudiada · flecha amarilla: objetivo más cercano · círculo punteado: sitio de radar · manchas oscuras: roca afilada · manchas claras: arena · manchas rayadas: pendiente · manchas azules: sombra fría."), 14, UIK.INK)
	if Game.coop: UIK.text(column, Game.t("CO-OP · Commander: arrows, T, Enter. Engineer: E, 1-6, Space, M, O, R, G, F.", "COOPERATIVO · Comandante: flechas, T, Intro. Ingeniero: E, 1-6, Espacio, M, O, R, G, F."), 14, UIK.RUST)
	var ok := UIK.button(panel, Game.t("Close", "Cerrar"), close_dialog, "primary", Vector2(220, 48))
	ok.position = Vector2(340, 512)
	ok.focus_mode = Control.FOCUS_NONE

## Panel de datos: qué hay en memoria, cuánto vale y qué se puede borrar para liberar espacio.
func show_data() -> void:
	if not mode in ["drive", "menu"]: return
	mode = "menu"
	var panel := open_panel(Rect2(290, 110, 700, 500))
	var column := UIK.column(panel, Rect2(26, 16, 648, 400), 4)
	UIK.label(column, Game.t("Data on board", "Datos a bordo"), 28, UIK.NAVY, "title")
	UIK.text(column, Game.t("Memory %d of %d MB. Received on Earth: %d MB. Decide what deserves to be kept and sent.", "Memoria %d de %d MB. Recibido en la Tierra: %d MB. Decide qué merece conservarse y enviarse.") % [int(memory_used()), int(stats.memory), int(received_mb)], 15, UIK.INK)
	if packets.is_empty(): UIK.text(column, Game.t("Nothing stored. Use an instrument to generate science data.", "No hay nada guardado. Usa un instrumento para generar datos científicos."), 15, UIK.MUTED)
	for i in range(mini(packets.size(), 6)):
		var packet: Dictionary = packets[i]
		var line := UIK.row(column, 8)
		UIK.label(line, "%s" % String(packet.label), 15, UIK.INK, "bold").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIK.label(line, "%d MB · %d %s" % [int(float(packet.mb) - float(packet.sent)), int(packet.science), Game.t("science", "ciencia")], 14, UIK.TEAL, "bold")
		var b := UIK.button(line, "%d  %s" % [i + 1, Game.t("Delete", "Borrar")], func() -> void: delete_packet(i), "ghost", Vector2(120, 34))
		b.add_theme_font_size_override("font_size", 14)
		b.focus_mode = Control.FOCUS_NONE
		hotkeys.append(b)
	if packets.size() > 6: UIK.label(column, Game.t("+ %d more in the queue", "+ %d más en la cola") % (packets.size() - 6), 14, UIK.MUTED)
	var total := memory_used()
	UIK.text(column, real_link_text(total), 14, UIK.MUTED)
	var close := UIK.button(panel, Game.t("Close (Esc)", "Cerrar (Esc)"), close_dialog, "primary", Vector2(220, 46))
	close.position = Vector2(240, 436)
	close.focus_mode = Control.FOCUS_NONE
	confirmable = false

func delete_packet(index: int) -> void:
	if index < packets.size():
		packets.remove_at(index)
		Game.sfx("click", 0.7)
	show_data()

## Estimación con las tasas REALES de Perseverance (NASA): relevo UHF hasta 2 Mbps; banda X directa hasta 3 kbps.
func real_link_text(megabytes: float) -> String:
	var relay_seconds := megabytes * 8.0 / float(Data.REAL_LINK.uhf_mbps)
	var direct_hours := megabytes * 8000000.0 / float(Data.REAL_LINK.hga_bps_high) / 3600.0
	return Game.t("In real life, %d MB would take about %s over the UHF relay at up to 2 Mbps, or about %d hours direct to Earth at 500 bits per second. The game compresses time.", "En la vida real, %d MB tardarían unos %s por el relevo UHF a un máximo de 2 Mbps, o unas %d horas directo a la Tierra a 500 bits por segundo. El juego comprime el tiempo.") % [int(megabytes), ("%d s" % int(relay_seconds)) if relay_seconds < 90.0 else ("%d min" % int(relay_seconds / 60.0)), int(ceilf(direct_hours))]

func target_title(target: Dictionary) -> String:
	var rock: Dictionary = Data.ROCKS[target.type]
	if target.chem or target.pixl or target.sherloc: return Game.tt(rock.name)
	if target.imaged: return {"igneous": Game.t("Igneous rock", "Roca ígnea"), "sedimentary": Game.t("Sedimentary rock", "Roca sedimentaria"), "soil": Game.t("Loose regolith", "Regolito suelto")}[rock.klass]
	return Game.t("Unidentified target", "Objetivo sin identificar")

func action_done(id: String, target: Dictionary) -> bool:
	match id:
		"mastcam": return int(target.photos) >= 3
		"supercam": return target.chem
		"pixl": return target.pixl
		"sherloc": return target.sherloc
	return target.cached

## Panel de estudio de una roca (V5). Cabecera con la miniatura y el estado; una tarjeta por
## acción con su icono, coste en MB y Wh, tecla y —si no se puede usar— el motivo en palabras.
## La altura se ajusta al número de acciones. `details` añade la línea técnica de cada una.
func show_actions(target: Dictionary, details: bool = false) -> void:
	mode = "menu"
	focus = target
	var rock: Dictionary = Data.ROCKS[target.type]
	var gap: float = pos.distance_to(target.pos) - float(target.r)
	var rows: Array = []
	var missing: Array = []
	for id in Data.ROCK_ACTIONS:
		if id == "regolith" and rock.klass != "soil" and not target.crumbled: continue
		if id == "drill" and rock.klass == "soil": continue
		var info: Dictionary = Data.INSTRUMENTS[id]
		if not id in has:
			missing.append(Game.t("%s: not installed", "%s: no instalado") % Data.comp_name(id))
			continue
		if info.arm and not "arm" in has:
			missing.append(Game.t("%s: needs an arm", "%s: requiere brazo") % Data.comp_name(id))
			continue
		var wh := Data.activity_wh(build, id)
		var mb := Data.activity_mb(build, id)
		var reach: float = float(stats.reach) if (info.arm or id == "regolith") else float(info.range)
		var name := Data.comp_name(id)
		var verb := Game.t("Analyse", "Analizar")
		if id == "mastcam":
			name = Game.t("Mastcam-Z · photo %d of 3", "Mastcam-Z · foto %d de 3") % mini(3, int(target.photos) + 1)
			verb = Game.t("Photograph", "Fotografiar")
		elif id == "drill":
			name = Game.t("Core a sample · %d tubes", "Extraer muestra · %d tubos") % tubes
			verb = Game.t("Drill", "Perforar")
		elif id == "regolith":
			name = Game.t("Scoop regolith · %d tubes", "Recoger regolito · %d tubos") % tubes
			verb = Game.t("Scoop", "Recoger")
		var reason := ""
		var done := action_done(id, target)
		if done: reason = Game.t("Completed", "Completado")
		elif gap > reach: reason = Game.t("Move closer", "Acércate")
		elif energy < wh + 20.0: reason = Game.t("Not enough energy", "Energía insuficiente")
		elif memory_used() + mb > float(stats.memory): reason = Game.t("Memory full: transmit first", "Memoria llena: transmite antes")
		elif id in ["drill", "regolith"] and tubes <= 0: reason = Game.t("No tubes left", "Sin tubos")
		# texto completo del botón (lectores de pantalla y pruebas); lo visible son los elementos de la tarjeta
		var spoken := Data.comp_name(id)
		if id == "mastcam": spoken = Game.t("Mastcam-Z · photo angle %d of 3", "Mastcam-Z · foto ángulo %d de 3") % mini(3, int(target.photos) + 1)
		elif id == "drill": spoken = Game.t("Core and cache a sample (%d tubes)", "Extraer y guardar muestra (%d tubos)") % tubes
		elif id == "regolith": spoken = Game.t("Scoop a regolith sample (%d tubes)", "Recoger muestra de regolito (%d tubos)") % tubes
		rows.append({"id": id, "name": name, "verb": verb, "mb": mb, "wh": wh, "reason": reason, "done": done, "reach": reach, "arm": bool(info.arm), "spoken": "%s  ·  %d MB  ·  %d Wh%s" % [spoken, int(mb), int(wh), ("   — " + reason) if reason != "" else ""]})
	var extra := (30 if not missing.is_empty() else 0) + (34 if rows.is_empty() else 0)
	var height := 96.0 + (66.0 + (18.0 if details else 0.0)) * rows.size() + extra + 56.0
	var panel := open_panel(Rect2(290, clampf(690.0 - height, 30.0, 400.0), 700, height))
	var column := UIK.column(panel, Rect2(20, 14, 660, height - 28.0), 6)
	# cabecera: miniatura, nombre, tipo y estado, cerrar
	var head := UIK.row(column, 12)
	var thumb := UIK.tex("res://assets/rocks/%s.png" % String(target.type))
	if thumb != null: UIK.picture(head, thumb, Vector2(60, 60))
	var words := UIK.column(head, Rect2(0, 0, 0, 0), 0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.label(words, target_title(target), 24, UIK.NAVY, "title")
	var tags := UIK.row(words, 6)
	UIK.chip(tags, " %s " % (Game.t("soil", "suelo") if rock.klass == "soil" else Game.t("rock", "roca")), UIK.RUST)
	var finished := rows.filter(func(row: Dictionary) -> bool: return bool(row.done)).size()
	UIK.chip(tags, Game.t(" %d of %d studies done ", " %d de %d estudios hechos ") % [finished, rows.size()], UIK.GOOD if finished == rows.size() and rows.size() > 0 else UIK.NAVY)
	var close := UIK.button(head, Game.t("Close · Esc", "Cerrar · Esc"), close_dialog, "ghost", Vector2(130, 40))
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 14)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# una tarjeta por acción
	for row in rows:
		var id: String = row.id
		var ready: bool = String(row.reason) == ""
		var button := Button.new()
		button.custom_minimum_size = Vector2(660, 60.0 + (18.0 if details else 0.0))
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = not ready
		button.pressed.connect(func() -> void: run_instrument(id, target))
		button.text = String(row.spoken)
		button.clip_text = true
		for tint in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_hover_pressed_color"]: button.add_theme_color_override(tint, Color(0, 0, 0, 0))
		var fill: Color = UIK.MINT if ready else (UIK.PAPER.lerp(UIK.GOOD, 0.14) if bool(row.done) else Color("#e9e2d2"))
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, UIK.box(fill.lerp(UIK.ORANGE, 0.16 if state == "hover" else 0.0), 14, UIK.INK if ready else (UIK.GOOD if bool(row.done) else UIK.MUTED), 3 if ready else 2, 3 if ready else 0))
		column.add_child(button)
		hotkeys.append(button)
		var line := UIK.row(button, 10)
		line.position = Vector2(12, 6)
		line.size = Vector2(636, 48)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := UIK.tex("res://assets/parts/%s.png" % id)
		if icon != null: UIK.picture(line, icon, Vector2(46, 46)).mouse_filter = Control.MOUSE_FILTER_IGNORE
		var body := UIK.column(line, Rect2(0, 0, 0, 0), 0)
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIK.label(body, String(row.name), 17, UIK.INK, "bold").mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIK.label(body, "%d MB  ·  %d Wh" % [int(row.mb), int(row.wh)], 14, UIK.NAVY, "bold").mouse_filter = Control.MOUSE_FILTER_IGNORE
		if details: UIK.label(body, (Game.t("arm tool · reach %d", "herramienta de brazo · alcance %d") if bool(row.arm) else Game.t("remote · range %d", "a distancia · alcance %d")) % int(row.reach), 12, UIK.MUTED, "bold").mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ready:
			var key := UIK.chip(line, " %d " % hotkeys.size(), UIK.INK)
			key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			key.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var go := UIK.label(line, String(row.verb).to_upper(), 16, UIK.INK, "title")
			go.custom_minimum_size.x = 120
			go.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			go.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			var why := UIK.label(line, ("✓  " if bool(row.done) else "!  ") + String(row.reason), 15, UIK.GOOD if bool(row.done) else UIK.RUST, "bold")
			why.custom_minimum_size.x = 250
			why.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			why.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if rows.is_empty(): UIK.text(column, Game.t("No instrument on this rover can study this target. That was decided in the design.", "Ningún instrumento de este rover puede estudiar este objetivo. Eso se decidió en el diseño."), 15, UIK.BAD)
	if not missing.is_empty():
		var note := UIK.label(column, Game.t("Out of reach here · ", "Fuera de alcance aquí · ") + " · ".join(missing), 13, UIK.MUTED, "bold")
		note.clip_text = true
		note.tooltip_text = note.text
		note.mouse_filter = Control.MOUSE_FILTER_STOP
	var foot := UIK.row(column, 10)
	var more := UIK.button(foot, Game.t("Hide details", "Ocultar detalles") if details else Game.t("Technical details", "Detalles técnicos"), func() -> void:
		close_dialog()
		show_actions(target, not details), "ghost", Vector2(210, 36))
	more.focus_mode = Control.FOCUS_NONE
	more.add_theme_font_size_override("font_size", 14)
	var hint := UIK.label(foot, Game.t("Press the number or click a card", "Pulsa el número o haz clic en una tarjeta"), 13, UIK.MUTED, "bold")
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	confirmable = false

func run_instrument(id: String, target: Dictionary) -> void:
	if is_instance_valid(dialog): dialog.queue_free()
	dialog = null
	transmitting = false
	autopilot = false
	focus = target
	var cost := Data.activity_wh(build, id)
	energy = maxf(0.0, energy - cost)
	energy_used += cost
	used[id] = true
	game = {"id": id, "mode": String(Data.INSTRUMENTS[id].mode), "t": 0.0, "hits": 0, "tries": 0, "value": 0.2, "band": 0.5, "progress": 0.0, "flash": 0.0}
	mode = "minigame"

func update_minigame(delta: float) -> void:
	game.t += delta
	game.flash = maxf(0.0, float(game.flash) - delta)
	match String(game.mode):
		"focus", "timing": game.value = 0.5 + 0.5 * sin(float(game.t) * (2.6 if game.mode == "focus" else 3.4))
		"steady":
			var holding := Input.is_action_pressed("interact") or (Game.input_mode != "keyboard" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
			game.band = 0.5 + 0.22 * sin(float(game.t) * 1.3)
			game.value = clampf(float(game.value) + (0.75 if holding else -0.6) * delta, 0.0, 1.0)
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
	var packet := {"label": Data.comp_name(id), "mb": Data.activity_mb(build, id), "science": science_for(id, quality), "kind": id}
	var body := ""
	var quiz := ""
	mode = "drive"
	if id == "rimfax":
		focus.scanned = true
		rimfax_scans += 1
		analyses += 1
		body = Game.t("Radargram recorded: tilted layers continue metres below the wheels.", "Radargrama registrado: capas inclinadas continúan metros bajo las ruedas.")
		quiz = "radar"
	else:
		var rock: Dictionary = Data.ROCKS[focus.type]
		match id:
			"mastcam":
				focus.photos = int(focus.photos) + 1
				focus.imaged = true
				photos += 1
				if int(focus.photos) > 1: packet.science = float(packet.science) * 0.5   # los ángulos extra aportan contexto, no un hallazgo nuevo
				if int(focus.photos) >= 3: Game.unlock("angles")
				body = {"igneous": Game.t("Image recorded: a massive, dark rock with no layering. Igneous.", "Imagen registrada: roca oscura y masiva, sin capas. Ígnea."), "sedimentary": Game.t("Image recorded: fine layers stacked like pages. Sedimentary.", "Imagen registrada: capas finas apiladas como páginas. Sedimentaria."), "soil": Game.t("Image recorded: loose grains and dust, no solid outcrop.", "Imagen registrada: granos sueltos y polvo, sin afloramiento sólido.")}[rock.klass]
				body += Game.t(" Angle %d of 3 saved.", " Ángulo %d de 3 guardado.") % int(focus.photos)
				if rock.fragile and rock.klass != "soil" and int(focus.photos) >= 2: body += Game.t(" From this angle the surface looks flaky and weathered: it may crumble under a drill.", " Desde este ángulo la superficie se ve escamosa y meteorizada: podría desmoronarse con un taladro.")
				packet.label = Game.t("Photo (angle %d)", "Foto (ángulo %d)") % int(focus.photos)
			"supercam", "pixl":
				if id == "pixl": focus.pixl = true
				else: focus.chem = true
				analyses += 1
				body = Game.tt(rock.name) + ". " + Game.tt(rock.chem)
				if id == "pixl": body += Game.t(" PIXL maps where each element sits, grain by grain.", " PIXL mapea dónde está cada elemento, grano por grano.")
				quiz = "igneous" if rock.klass == "igneous" else ("water" if rock.aqueous else "")
			"sherloc":
				focus.sherloc = true
				analyses += 1
				if rock.organics:
					body = Game.t("Organic molecules detected, next to minerals that formed in water.", "Moléculas orgánicas detectadas, junto a minerales formados en agua.")
					quiz = "organics"
				else:
					body = Game.t("No organics detected here. A clean negative is still a result.", "No se detectaron orgánicos aquí. Un negativo limpio también es un resultado.")
					packet.science = float(packet.science) * 0.4
			"drill":
				if rock.fragile and not focus.crumbled:
					focus.crumbled = true
					failed_samples += 1
					show_failed_sample(focus)
					return
				cache_sample(focus, "drill", packet, quality)
				body = Game.t("Core sealed in its tube. Site, rock type and context are on record.", "Núcleo sellado en su tubo. Sitio, tipo de roca y contexto quedan registrados.") if focus.imaged else Game.t("Core sealed, but the site was never photographed: the sample has lost part of its context.", "Núcleo sellado, pero el sitio nunca se fotografió: la muestra perdió parte de su contexto.")
				quiz = "cache"
			"regolith":
				cache_sample(focus, "regolith", packet, quality)
				body = Game.t("Loose material scooped and sealed. Quick to collect, with less layering to read than a core.", "Material suelto recogido y sellado. Rápido de recoger, con menos capas que leer que un núcleo.")
	if store(packet): show_card(String(packet.label), body + ("  (%s %d%%)" % [Game.t("signal quality", "calidad de señal"), int(quality * 100)]), quiz, packet)

func cache_sample(target: Dictionary, tool: String, packet: Dictionary, quality: float) -> void:
	target.cached = true
	tubes -= 1
	cached.append({"type": target.type, "documented": target.imaged, "photos": int(target.photos), "tool": tool, "partial": bool(target.crumbled) and tool == "drill"})
	packet.label = Game.t("Sample record", "Registro de muestra")
	if target.imaged:
		packet.science = float(packet.science) + 12.0 + 4.0 * maxi(0, int(target.photos) - 1)
		Game.unlock("context")
	if target.crumbled and tool == "drill": packet.science = float(packet.science) * 0.6
	Game.unlock("first_sample")

## EVENTO: recolección fallida (guion del equipo; inspirado en el primer intento real de
## Perseverance en la roca Roubion, 2021). No se pierde el tubo: se pierde energía y tiempo.
func show_failed_sample(target: Dictionary) -> void:
	mode = "card"
	Game.sfx("bad")
	var panel := open_panel(Rect2(260, 110, 760, 500))
	confirmable = false
	portrait(panel, Rect2(22, 20, 120, 120), false)
	var column := UIK.column(panel, Rect2(160, 18, 576, 470), 6)
	UIK.label(column, Game.t("Sample not collected", "Muestra no recolectada"), 26, UIK.BAD, "title")
	UIK.text(column, Game.t("We have a setback. The sample was not collected as expected: the tube is empty. Not all materials behave the same way; some rocks are fragile and crumble under the drill. Let's review the images and data before deciding what to do.", "Tenemos un inconveniente. La muestra no se recolectó como esperábamos: el tubo está vacío. No todos los materiales se comportan igual; algunas rocas son frágiles y se desmoronan con el taladro. Revisemos las imágenes y los datos antes de decidir qué hacer."), 16, UIK.INK)
	var review := UIK.card(column, Game.t("IMAGES AND DATA FOR THIS ROCK", "IMÁGENES Y DATOS DE ESTA ROCA"), UIK.ORANGE)
	UIK.text(review, (Game.t("%d photo(s): the surface is flaky and weathered. ", "%d foto(s): la superficie es escamosa y meteorizada. ") % int(target.photos)) if int(target.photos) > 0 else Game.t("No photos were taken: we drilled without looking closely first. ", "No se tomaron fotos: perforamos sin mirar bien antes. "), 14, UIK.INK)
	UIK.text(review, Game.t("Rock type: %s. The tube was not used up.", "Tipo de roca: %s. El tubo no se gastó.") % Game.tt(Data.ROCKS[target.type].name), 14, UIK.INK)
	UIK.label(column, Game.t("This happened to Perseverance too (Roubion, 2021). What now?", "Esto también le pasó a Perseverance (Roubion, 2021). ¿Y ahora?"), 13, UIK.TEAL, "bold")
	var options := [[Game.t("Look for a harder rock", "Buscar una roca más dura"), close_dialog, true], [Game.t("Try again here, carefully (smaller sample)", "Intentar otra vez aquí, con cuidado (muestra menor)"), func() -> void: run_instrument("drill", target), energy >= Data.activity_wh(build, "drill") + 20.0 and tubes > 0],
		[Game.t("Scoop the crumbled material with the collector", "Recoger el material desmoronado con el colector"), func() -> void: run_instrument("regolith", target), "regolith" in has and tubes > 0]]
	for item in options:
		var b := UIK.button(column, "%d   %s" % [hotkeys.size() + 1, String(item[0])], item[1], "primary", Vector2(576, 42))
		b.add_theme_font_size_override("font_size", 15)
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not item[2]
		hotkeys.append(b)

func show_card(title_text: String, body: String, quiz: String, packet: Dictionary) -> void:
	if quiz != "" and not quiz_done.has(quiz):
		ask(quiz, packet, title_text, body)
		return
	mode = "card"
	var panel := open_panel(Rect2(360, 190, 560, 310))
	var column := UIK.column(panel, Rect2(26, 18, 508, 220), 8)
	UIK.label(column, title_text, 26, UIK.NAVY, "title")
	UIK.text(column, body, 17, UIK.INK)
	UIK.text(column, "+%d MB %s" % [int(packet.mb), Game.t("stored on board — not yet on Earth", "guardados a bordo — aún no en la Tierra")], 15, UIK.TEAL)
	var ok := UIK.button(panel, Game.t("Continue", "Continuar"), close_dialog, "primary", Vector2(220, 50))
	ok.position = Vector2(170, 244)
	ok.focus_mode = Control.FOCUS_NONE

## Pregunta de interpretación: primero la evidencia, luego el término, después UNA pregunta.
func ask(id: String, packet: Dictionary, title_text: String = "", body: String = "", retry: bool = false) -> void:
	mode = "card"
	if not retry:
		quiz_done[id] = true
		quiz_asked += 1
	var quiz: Dictionary = Data.QUIZ[id]
	var panel := open_panel(Rect2(250, 70, 780, 590))
	confirmable = false
	var column := UIK.column(panel, Rect2(26, 14, 728, 560), 6)
	UIK.label(column, title_text if title_text != "" else Game.t("Interpreting the result", "Interpretar el resultado"), 22, UIK.NAVY, "title")
	if body != "": UIK.text(column, body, 14, UIK.MUTED)
	var seen := UIK.card(column, Game.t("WHAT WE OBSERVED", "LO QUE OBSERVAMOS"), UIK.ORANGE)
	UIK.text(seen, Game.tt(quiz.see), 16, UIK.INK)
	var term := UIK.card(column, Game.t("WORD TO KNOW", "PALABRA CLAVE"), UIK.MINT)
	UIK.text(term, Game.tt(quiz.term), 15, UIK.INK)
	UIK.text(column, Game.owen() + ": " + Game.tt(quiz.q), 19, UIK.INK).add_theme_font_override("font", UIK.bold_font)
	for i in range(quiz.options.size()):
		var button := UIK.button(column, "%d   %s" % [i + 1, Game.tt(quiz.options[i])], func() -> void: answer(id, i, packet, retry), "ghost", Vector2(728, 46))
		button.focus_mode = Control.FOCUS_NONE
		hotkeys.append(button)
		button.add_theme_font_size_override("font_size", 15)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func answer(id: String, choice: int, packet: Dictionary, retry: bool) -> void:
	var quiz: Dictionary = Data.QUIZ[id]
	var right: bool = choice == int(quiz.correct)
	Game.sfx("good" if right else "bad")
	var panel := open_panel(Rect2(330, 170, 620, 360))
	var column := UIK.column(panel, Rect2(26, 18, 568, 250), 10)
	if right:
		quiz_correct += 1
		if not retry: quiz_first += 1
		packet.science = float(packet.science) * (1.1 if retry else 1.25)
		UIK.label(column, Game.t("Well reasoned", "Bien razonado"), 26, UIK.GOOD, "title")
		UIK.text(column, Game.tt(quiz.why), 17, UIK.INK)
		UIK.text(column, Game.t("Interpretation bonus: +10% science (second try).", "Bono de interpretación: +10% de ciencia (segundo intento).") if retry else Game.t("Interpretation bonus: +25% science for this finding.", "Bono de interpretación: +25% de ciencia para este hallazgo."), 15, UIK.TEAL)
		var ok := UIK.button(panel, Game.t("Continue", "Continuar"), close_dialog, "primary", Vector2(220, 50))
		ok.position = Vector2(200, 290)
		ok.focus_mode = Control.FOCUS_NONE
	else:
		confirmable = false
		UIK.label(column, Game.t("Not quite: look at the evidence again", "No del todo: mira otra vez la evidencia"), 24, UIK.RUST, "title")
		UIK.text(column, Game.tt(quiz.wrong[choice]), 17, UIK.INK)
		UIK.text(column, Game.t("Report only what the evidence supports. You can try again.", "Informa solo lo que la evidencia sostiene. Puedes intentarlo otra vez.") if not retry else Game.tt(quiz.why), 15, UIK.TEAL)
		var again := UIK.button(panel, Game.t("1   Try again", "1   Intentar otra vez") if not retry else Game.t("1   Continue", "1   Continuar"), (func() -> void: ask(id, packet, "", "", true)) if not retry else close_dialog, "primary", Vector2(260, 50))
		again.position = Vector2(180, 290)
		again.focus_mode = Control.FOCUS_NONE
		hotkeys.append(again)

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

# ------------------------------------------------------------------ tutorial guiado
func coach_text(step: int) -> String:
	var mouse := Game.input_mode == "mouse"
	match step:
		0: return Game.t("You have control. Hold the mouse button on the ground to drive.", "Ya tienes el control. Mantén el botón del ratón sobre el suelo para conducir.") if mouse else Game.t("You have control. Drive with WASD or the arrow keys. Rocks block the way; sand and slopes slow you down.", "Ya tienes el control. Conduce con WASD o las flechas. Las rocas cortan el paso; la arena y las pendientes te frenan.")
		1: return Game.t("I've spotted interesting formations: the rocks with a yellow ring. The yellow arrow points to the nearest. Drive up to one.", "He detectado formaciones interesantes: las rocas con anillo amarillo. La flecha amarilla apunta a la más cercana. Acércate a una.")
		2: return (Game.t("Good choice. Before analysing it, photograph it: click the rock and choose Mastcam-Z.", "Buena elección. Antes de analizarla, fotografíala: haz clic en la roca y elige Mastcam-Z.") if mouse else Game.t("Good choice. Before analysing it, photograph it: press E, then 1 for Mastcam-Z.", "Buena elección. Antes de analizarla, fotografíala: pulsa E y luego 1 para Mastcam-Z."))
		3: return Game.t("Photo saved: new science data. Memory is limited, so each product must earn its place. Now read the rock's composition with your next instrument.", "¡Fotografía guardada! Nuevos datos científicos. La memoria es limitada, así que cada producto debe ganarse su lugar. Ahora lee la composición de la roca con tu siguiente instrumento.")
		4: return Game.t("Data on board does not count yet. Watch the link at the top: when an orbiter is overhead, stop and transmit (%s).", "Los datos a bordo aún no cuentan. Mira el enlace arriba: cuando haya un orbitador encima, detente y transmite (%s).") % (Game.t("Transmit button", "botón Transmitir") if mouse else "T")
	return Game.t("That is the whole loop: explore, observe, analyse, transmit. The checklist shows what is required; the rest is optional. Controls are always under Esc.", "Ese es el ciclo completo: explorar, observar, analizar, transmitir. La lista muestra lo requerido; lo demás es opcional. Los controles están siempre en Esc.")

func coach_check(step: int) -> bool:
	match step:
		0: return driven > 180.0
		1: return not nearest_target().is_empty()
		2: return not "mastcam" in has or targets.any(func(t: Dictionary) -> bool: return int(t.photos) > 0)
		3: return not ("supercam" in has or ("pixl" in has and "arm" in has)) or targets.any(func(t: Dictionary) -> bool: return t.chem or t.pixl)
		4: return received_mb > 0.5
	return false

func start_coach() -> void:
	coach_step = clampi(int(Game.tutorial.get("ops_step", 0)), 0, 4)
	show_coach()

func show_coach() -> void:
	if coach.has("panel") and is_instance_valid(coach.panel): coach.panel.queue_free()
	if coach_step < 0: return
	coach = owen_panel(self, Rect2(14, 146, 420, 196), coach_text(coach_step), Game.t("Tutorial %d/6", "Tutorial %d/6") % (coach_step + 1), 76.0)
	var label: Label = coach.label
	label.add_theme_font_size_override("font_size", 14)
	var panel: Panel = coach.panel
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var skip := UIK.button(panel, Game.t("Skip", "Saltar") if coach_step < 5 else Game.t("Got it", "Entendido"), end_coach, "ghost" if coach_step < 5 else "go", Vector2(96, 30))
	skip.position = Vector2(312, 156)
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_size_override("font_size", 13)

func update_coach() -> void:
	if coach_step < 0 or coach_step >= 5 or mode != "drive": return
	if coach_check(coach_step):
		coach_step += 1
		Game.tutorial["ops_step"] = mini(coach_step, 4)
		if coach_step >= 5: Game.tutorial["ops"] = true   # completado: se registra una sola vez
		Game.save()
		Game.sfx("good")
		show_coach()

func end_coach() -> void:
	coach_step = -1
	if coach.has("panel") and is_instance_valid(coach.panel): coach.panel.queue_free()
	Game.tutorial["ops"] = true   # completar o saltar se registra una sola vez
	Game.save()

# ------------------------------------------------------------------ final
func show_required_done() -> void:
	mode = "card"
	autopilot = false
	var panel := open_panel(Rect2(320, 170, 640, 380))
	confirmable = false
	portrait(panel, Rect2(22, 20, 110, 110))
	var column := UIK.column(panel, Rect2(150, 18, 466, 240), 8)
	UIK.label(column, Game.t("Required objectives complete!", "¡Objetivos requeridos completos!"), 26, UIK.GOOD, "title")
	var left := objective_state().filter(func(item: Dictionary) -> bool: return item.opt and not item.done).size()
	UIK.text(column, Game.t("%s has completed its main operations. You can finish now and review the mission, or keep exploring: %d optional objective(s) remain and %d MB are still on board.", "%s ha completado sus operaciones principales. Puedes terminar ahora y revisar la misión, o seguir explorando: quedan %d objetivo(s) opcional(es) y %d MB siguen a bordo.") % [Game.rover_name, left, int(memory_used())], 16, UIK.INK)
	var row := UIK.row(panel, 12)
	row.position = Vector2(26, 290)
	for item in [[Game.t("1   Finish and debrief", "1   Terminar e informe"), ask_finish, "go"], [Game.t("2   Keep exploring", "2   Seguir explorando"), close_dialog, "primary"]]:
		var b := UIK.button(row, String(item[0]), item[1], String(item[2]), Vector2(288, 54))
		b.focus_mode = Control.FOCUS_NONE
		hotkeys.append(b)

## Terminar la misión. En cooperativo exige la confirmación de ambos roles.
func ask_finish() -> void:
	if mode == "ended": return
	close_dialog()
	mode = "paused"
	coop_gate(Game.t("Conclude the mission?", "¿Concluir la misión?"),
		Game.t("Are the mission priorities met? %d MB are still on board.", "¿Se cumplieron las prioridades de la misión? Aún hay %d MB a bordo.") % int(memory_used()),
		Game.t("Rover status: %d%% health, %d Wh. Anything left worth analysing?", "Estado del rover: %d%% de salud, %d Wh. ¿Queda algo que valga la pena analizar?") % [int(integrity), int(energy)],
		func() -> void: finish("player"))
	if Game.coop: mode = "paused"

func gate_cancel() -> void:
	super.gate_cancel()
	if mode == "paused": mode = "drive"

func finish(reason: String) -> void:
	if mode == "ended": return
	if reason == "wheels" and expedition() and not mate.is_empty() and not bool(mate.get("dead", false)):
		# Expedición: si un rover queda inutilizado, el otro continúa la misión
		close_dialog()
		var lost := lead
		swap_focus()
		mate.dead = true
		mate.integrity = 0.0
		mate.vel = Vector2.ZERO
		say(Game.t("Player %d's rover is disabled. The other rover carries on.", "El rover del jugador %d quedó inutilizado. El otro rover sigue.") % (lost + 1))
		return
	mode = "ended"
	var goals := objective_state()
	var required := goals.filter(func(item: Dictionary) -> bool: return not item.opt)
	var done := required.filter(func(item: Dictionary) -> bool: return item.done).size()
	var optional_done := goals.filter(func(item: Dictionary) -> bool: return item.opt and item.done).size()
	var lost := memory_used()
	var cap := Game.limits()
	var total_cost := Data.cost(build)
	var mission := 100.0 * done / maxf(1.0, required.size())
	# Seis dimensiones (0-100). Cada una explica su base en el informe.
	var science_ref := need_mb * 3.0   # referencia de la zona (modelo de juego): 3 puntos de ciencia por MB exigido
	var science_dim := clampf(100.0 * received_science / maxf(1.0, science_ref), 0.0, 100.0)
	var payload_cost := 0.0
	var used_cost := 0.0
	var unused: Array = []
	for id in Data.instruments(build) + (["drill"] if "drill" in has else []) + (["regolith"] if "regolith" in has else []):
		payload_cost += float(Data.COMPONENTS[id].cost)
		if used.has(id): used_cost += float(Data.COMPONENTS[id].cost)
		else: unused.append(id)
	var budget_dim := 100.0 * used_cost / payload_cost if payload_cost > 0.0 else -1.0
	var schedule_dim := clampf(160.0 - 100.0 * clock / maxf(1.0, deadline()), 60.0, 100.0) if done == required.size() else 50.0 * done / maxf(1.0, required.size())
	var resource_dim := clampf(100.0 - 12.0 * safe_count - (100.0 - maxf(0.0, integrity)) * 0.5 - 5.0 * mem_full_count, 0.0, 100.0)
	var generated := collected_mb + unrecorded_mb   # MB útiles generados, se grabaran o no
	var data_dim := 100.0 * received_mb / generated if generated > 0.5 else -1.0
	var score := 0.3 * mission + 0.25 * science_dim + 0.15 * maxf(0.0, data_dim) + 0.1 * maxf(0.0, budget_dim) + 0.1 * schedule_dim + 0.1 * resource_dim
	var grade := "D"
	if score >= 90.0: grade = "S"
	elif score >= 78.0: grade = "A"
	elif score >= 63.0: grade = "B"
	elif score >= 45.0: grade = "C"
	# Las notas S y A exigen todos los objetivos requeridos; con menos de la mitad, C como máximo.
	if done < required.size() and grade in ["S", "A"]: grade = "B"
	if done * 2 < required.size() and grade == "B": grade = "C"
	var design_notes := Data.readiness(build, Game.zone)
	var blocked := design_notes.filter(func(note: Dictionary) -> bool: return not note.ok and not note.opt).size()
	Game.report = {"zone": Game.zone, "reason": reason, "goals": goals, "done": done, "required": required.size(), "optional_done": optional_done, "grade": grade, "score": score,
		"dims": {"science": science_dim, "mission": mission, "budget": budget_dim, "schedule": schedule_dim, "resource": resource_dim, "data": data_dim},
		"collected": collected_mb, "received": received_mb, "lost": lost, "unrecorded": unrecorded_mb, "science": int(received_science), "science_ref": science_ref,
		"energy_used": energy_used, "integrity": maxf(0.0, integrity), "time": clock, "time_limit": deadline(), "quiz_right": quiz_first, "quiz_asked": quiz_asked,
		"cached": cached.size(), "samples": cached.duplicate(true), "readiness": design_notes, "safe": safe_count, "mem_full": mem_full_count, "failed_samples": failed_samples,
		"photos": photos, "analyses": analyses, "unused": unused, "cost": total_cost, "budget": int(cap.budget), "mass": int(stats.mass), "mass_cap": int(cap.mass),
		"plan": plan.duplicate(true), "flight": Game.flight.duplicate(true), "launch_checks": Game.last_issue, "build": build.duplicate(true), "coop": Game.coop, "sandbox": Game.mode == "sandbox",
		"battery": float(stats.battery), "solar": bool(stats.solar), "memory": float(stats.memory), "driven": driven, "rocks": targets.filter(func(t: Dictionary) -> bool: return t.imaged or t.chem or t.pixl or t.sherloc or t.cached).size()}
	Game.report["sub"] = sub
	Game.report["arcade_hits"] = arcade_hits
	if Game.mode != "sandbox" and sub != "main":
		# Subniveles: se guardan aparte. El reconocimiento cuenta su ciencia una vez; el desafío
		# arcade no da ciencia, ni logros, ni entra en el historial que usa la Dra. Owen.
		Game.record_sub(Game.zone, sub, grade, int(received_science), score)
		if sub == "recon": Game.record_discoveries(Game.zone, targets, used.keys())
	elif Game.mode != "sandbox":
		Game.record(Game.zone, grade, int(received_science))
		Game.record_discoveries(Game.zone, targets, used.keys())
		Game.add_history({"zone": Game.zone, "grade": grade, "flags": {"safe": safe_count, "mem_full": mem_full_count, "left": 1 if lost > 1.0 else 0, "damage": 1 if integrity < 60.0 else 0, "blocked": blocked, "timeout": 1 if reason == "time" and done < required.size() else 0, "overbuilt": 1 if unused.size() >= 2 else 0}})
		if done == required.size():
			if safe_count == 0: Game.unlock("night")
			if quiz_asked > 0 and quiz_first == quiz_asked: Game.unlock("honest")
			if total_cost < int(cap.budget) * 0.75: Game.unlock("lean")
			if failed_samples > 0: Game.unlock("recovered")
			if Game.coop: Game.unlock("coop")
		if grade == "S": Game.unlock("grade_s")
		if Game.campaign_percent() >= 100: Game.unlock("all_zones")
	Game.go("debrief")

# ----------------------------------------------------------------- dibujo
func outlined(at: Vector2, text: String, color: Color, px: int = 16, width: float = 280.0) -> void:
	draw_string_outline(UIK.bold_font, at - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_CENTER, width, px, 6, UIK.INK)
	draw_string(UIK.bold_font, at - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_CENTER, width, px, color)

## El mundo es 3D (scripts/world3d.gd). Aquí solo se dibuja lo que va ENCIMA: etiquetas de
## rocas, flecha guía, velos de noche y tormenta, y el HUD.
func paint() -> void:
	var view := size
	var span: Vector2 = world3d.span()
	var camera: Vector2 = world3d.focus - span * 0.5
	cam = camera
	if "rimfax" in has:
		for site in sites:
			outlined(world3d.to_screen(site.pos) + Vector2(0, 6), "✓" if site.scanned else Game.t("radar site", "sitio de radar"), UIK.GOOD if site.scanned else UIK.PAPER, 15, 180.0)
	var near := nearest_target() if mode == "drive" else focus
	for item in targets:
		var at: Vector2 = world3d.to_screen(item.pos, world3d.height(item.pos))
		if not Rect2(Vector2(-80, -80), view + Vector2(160, 160)).has_point(at): continue
		var studied: bool = item.imaged or item.chem or item.pixl or item.sherloc or item.cached
		var reach := float(item.r) * ZOOM
		for i in range(int(item.photos)):
			draw_circle(at + Vector2(-12 + i * 12, reach * 0.55 + 16), 6.0, UIK.INK)
			draw_circle(at + Vector2(-12 + i * 12, reach * 0.55 + 16), 4.0, UIK.PAPER)
		if item == near or studied: outlined(at + Vector2(0, -reach - 30), target_title(item), UIK.PAPER if item == near else Color(UIK.PAPER, 0.8))
	var guide := next_goal()
	if mode == "drive" and guide != Vector2.ZERO and pos.distance_to(guide) > 260.0:
		var me: Vector2 = world3d.to_screen(pos, world3d.height(pos))
		var way: Vector2 = (world3d.to_screen(guide) - world3d.to_screen(pos)).normalized()
		var tip := me + way * (84.0 + (0.0 if Game.reduced_motion else sin(time * 4.0) * 6.0))
		var side := way.orthogonal() * 13.0
		draw_colored_polygon(PackedVector2Array([tip + way * 22.0, tip - way * 9.0 + side * 1.25, tip - way * 9.0 - side * 1.25]), UIK.INK)
		draw_colored_polygon(PackedVector2Array([tip + way * 16.0, tip - way * 6.0 + side, tip - way * 6.0 - side]), UIK.YELLOW)
	var dark := 1.0 - light()
	if dark > 0.01: draw_rect(Rect2(Vector2.ZERO, view), Color(0.07, 0.09, 0.24, 0.2 * dark))
	if storming():
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.85, 0.6, 0.38, 0.26))
		if not Game.reduced_motion:
			for i in range(14):
				var y := fmod(i * 61.0 + time * 40.0, view.y)
				var x := fmod(i * 173.0 + time * 520.0, view.x + 300.0) - 300.0
				draw_line(Vector2(x, y), Vector2(x + 240, y + 14), Color(1.0, 0.9, 0.75, 0.2), 3.0)
	draw_arcade()
	draw_hud(view, camera, span)
	draw_ping()
	if expedition() and not mate.is_empty(): draw_expedition()
	if mode == "minigame": draw_minigame(view)

func pill(rect: Rect2, color: Color) -> void:
	draw_style_box(UIK.box(color, int(rect.size.y * 0.5), UIK.INK, 2, 4), rect)

## Tecla dibujada (ayuda visual del tutorial y de los avisos).
func keycap(at: Vector2, text: String) -> float:
	var wide := maxf(30.0, UIK.bold_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 16.0)
	draw_style_box(UIK.box(UIK.PAPER, 8, UIK.INK, 2, 2), Rect2(at, Vector2(wide, 28)))
	draw_string(UIK.bold_font, at + Vector2(0, 20), text, HORIZONTAL_ALIGNMENT_CENTER, wide, 15, UIK.INK)
	return wide + 6.0

## HUD de exploración (V4): prioriza el terreno. Recursos compactos, objetivo actual, enlace,
## minimapa y avisos con zona reservada. Las cifras detalladas están en Datos (Tab).
func draw_hud(view: Vector2, camera: Vector2, span: Vector2) -> void:
	var show_tubes: bool = "drill" in has or "regolith" in has
	var board := Rect2(14, 12, 276, 122 if show_tubes else 98)
	draw_style_box(UIK.box(Color(UIK.INK, 0.86), 16, UIK.ORANGE, 2, 4), board)
	draw_string(UIK.title_font, Vector2(28, 36), Game.rover_name, HORIZONTAL_ALIGNMENT_LEFT, 160, 19, UIK.CREAM)
	draw_string(UIK.bold_font, Vector2(196, 35), "%+d W" % int(net_w), HORIZONTAL_ALIGNMENT_RIGHT, 82, 14, UIK.GO if net_w >= 0.0 else UIK.SAND)
	var rows := [["energy", energy / float(stats.battery), UIK.ORANGE if energy > float(stats.battery) * 0.22 else UIK.BAD, "%d Wh" % int(energy)],
		["data", memory_used() / float(stats.memory), UIK.MINT if memory_used() < float(stats.memory) * 0.85 else UIK.SAND, "%d/%d MB" % [int(memory_used()), int(stats.memory)]],
		["structure", integrity / 100.0, UIK.GOOD if integrity > 50.0 else UIK.BAD, "%d%%" % int(maxf(0.0, integrity))]]
	for i in range(rows.size()):
		var y := 46.0 + i * 20.0
		Art.icon(self, String(rows[i][0]), Vector2(38, y + 7), 17, UIK.CREAM)
		UIK.bar(self, Rect2(54, y, 118, 13), float(rows[i][1]), rows[i][2], Color(UIK.PAPER, 0.16))
		draw_string(UIK.bold_font, Vector2(180, y + 12), String(rows[i][3]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIK.PAPER)
	if show_tubes:
		Art.icon(self, "sampling", Vector2(38, 115), 17, UIK.CREAM)
		for i in range(int(Data.MODEL.tubes)): draw_style_box(UIK.box(UIK.CREAM if i < tubes else Color(UIK.PAPER, 0.16), 4, Color.TRANSPARENT, 0, 0), Rect2(54 + i * 20, 108, 14, 14))
		draw_string(UIK.bold_font, Vector2(142, 120), Game.t("%d tubes free", "%d tubos libres") % tubes, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIK.PAPER)
	# Reloj y enlace
	var left := maxf(0.0, deadline() - clock)
	pill(Rect2(view.x * 0.5 - 150, 12, 300, 36), Color(UIK.NAVY, 0.95))
	var sun := light()
	draw_circle(Vector2(view.x * 0.5 - 128, 30), 9, UIK.ORANGE if sun > 0.01 else Color("#b8c4e0"))
	draw_string(UIK.bold_font, Vector2(view.x * 0.5 - 110, 36), "%s  ·  %s %d:%02d" % [Game.t("DAY", "DÍA") if sun > 0.01 else Game.t("NIGHT", "NOCHE"), Game.t("TIME LEFT", "TIEMPO"), int(left) / 60, int(left) % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UIK.PAPER)
	var link_text := ""
	var link_color := UIK.MUTED
	var key := Game.t("Transmit", "Transmitir") if Game.input_mode == "mouse" else "T"
	if transmitting:
		link_text = Game.t("TRANSMITTING  ·  %d MB left", "TRANSMITIENDO  ·  quedan %d MB") % int(memory_used())
		link_color = UIK.GOOD
	elif pass_open() and stats.uhf:
		link_text = Game.t("ORBITER OVERHEAD  ·  %s  ·  %ds", "ORBITADOR ENCIMA  ·  %s  ·  %ds") % [key, int(Data.pass_length() - fmod(clock - FIRST_PASS, PASS_PERIOD))]
		link_color = UIK.TEAL
	elif stats.uhf:
		var wait := FIRST_PASS - clock if clock < FIRST_PASS else PASS_PERIOD - fmod(clock - FIRST_PASS, PASS_PERIOD)
		link_text = Game.t("Next orbiter pass in %ds", "Próximo paso del orbitador en %ds") % int(wait)
		if stats.direct: link_text += Game.t("  ·  direct link ready", "  ·  enlace directo listo")
	elif stats.direct: link_text = Game.t("Direct link ready  ·  %s", "Enlace directo listo  ·  %s") % key
	else: link_text = Game.t("NO ANTENNA", "SIN ANTENA")
	pill(Rect2(view.x * 0.5 - 190, 54, 380, 30), Color(link_color, 0.97))
	draw_string(UIK.bold_font, Vector2(view.x * 0.5 - 180, 75), link_text, HORIZONTAL_ALIGNMENT_CENTER, 360, 15, UIK.PAPER)
	if pass_open() and stats.uhf and not transmitting: Art.orbiter(self, Vector2(view.x * 0.5 - 170 + 340.0 * fmod(clock - FIRST_PASS, PASS_PERIOD) / Data.pass_length(), 96), 0.9)
	if transmitting: draw_link_panel(view)
	# Objetivo actual: uno grande y el resto como fichas (la lista completa está en Pausa)
	var goals := objective_state()
	var required := goals.filter(func(item: Dictionary) -> bool: return not item.opt)
	var optional := goals.filter(func(item: Dictionary) -> bool: return item.opt)
	var current := {}
	for goal in required:
		if not goal.done:
			current = goal
			break
	var card := Rect2(view.x - 318, 12, 304, 128)
	draw_style_box(UIK.box(UIK.PAPER, 16, UIK.INK, 3, 4), card)
	draw_style_box(UIK.box(UIK.ORANGE if not current.is_empty() else UIK.GO, 12, Color.TRANSPARENT, 0, 0), Rect2(card.position + Vector2(8, 8), Vector2(card.size.x - 16, 24)))
	draw_string(UIK.title_font, card.position + Vector2(18, 26), Game.t("CURRENT OBJECTIVE", "OBJETIVO ACTUAL") if not current.is_empty() else Game.t("REQUIRED COMPLETE", "REQUERIDOS COMPLETOS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UIK.INK)
	draw_string(UIK.bold_font, card.position + Vector2(card.size.x - 126, 25), Game.t("%d MB on Earth", "%d MB en la Tierra") % int(received_mb), HORIZONTAL_ALIGNMENT_RIGHT, 110, 13, UIK.INK)
	if current.is_empty(): draw_multiline_string(UIK.bold_font, card.position + Vector2(16, 54), Game.t("Go for the optional ones or finish from Pause.", "Ve por los opcionales o termina desde Pausa."), HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 32, 15, 2, UIK.GOOD)
	else:
		draw_multiline_string(UIK.bold_font, card.position + Vector2(16, 54), String(current.text), HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 32, 15, 2, UIK.INK)
		UIK.bar(self, Rect2(card.position + Vector2(16, 82), Vector2(card.size.x - 92, 12)), float(current.value) / maxf(1.0, float(current.need)), UIK.TEAL, Color(UIK.NAVY, 0.18))
		draw_string(UIK.bold_font, card.position + Vector2(card.size.x - 70, 93), "%d/%d" % [int(minf(current.value, current.need)), int(current.need)], HORIZONTAL_ALIGNMENT_RIGHT, 54, 14, UIK.NAVY)
	var x := card.position.x + 16.0
	for goal in required:
		draw_style_box(UIK.box(UIK.GOOD if goal.done else Color(UIK.NAVY, 0.16), 4, UIK.INK, 2, 0), Rect2(x, card.position.y + 102, 16, 16))
		x += 21.0
	x += 8.0
	for goal in optional:
		draw_circle(Vector2(x + 8, card.position.y + 110), 8.0, UIK.INK)
		draw_circle(Vector2(x + 8, card.position.y + 110), 6.0, UIK.GOOD if goal.done else UIK.CREAM)
		x += 21.0
	draw_string(UIK.bold_font, Vector2(x + 4, card.position.y + 115), Game.t("required · optional", "requeridos · opcionales"), HORIZONTAL_ALIGNMENT_LEFT, card.end.x - x - 12, 12, UIK.MUTED)
	# Minimapa
	var map := Rect2(view.x - 236, view.y - 196, 220, 148)
	draw_style_box(UIK.box(Color(UIK.INK, 0.92), 14, UIK.ORANGE, 2, 6), map.grow(6))
	draw_rect(map, Color(String(zone.ground)).darkened(0.45))
	var ratio := Vector2(map.size.x / WORLD.x, map.size.y / WORLD.y)
	for patch in patches:
		var tint: Color = {"sharp": Color(0, 0, 0, 0.35), "sand": Color(1, 0.9, 0.7, 0.3), "slope": Color(1, 0.6, 0.3, 0.25), "cold": Color(0.4, 0.6, 1.0, 0.35)}[String(patch.kind)]
		draw_circle(map.position + Vector2(patch.pos) * ratio, float(patch.rx) * ratio.x, tint)
	for target in targets: draw_circle(map.position + Vector2(target.pos) * ratio, 3.5, UIK.GOOD if (target.imaged or target.chem or target.pixl or target.sherloc or target.cached) else UIK.YELLOW)
	if "rimfax" in has:
		for site in sites: draw_arc(map.position + Vector2(site.pos) * ratio, 4.5, 0, TAU, 10, UIK.GOOD if site.scanned else UIK.PAPER, 1.5)
	if meda_on:
		for devil in devils: draw_circle(map.position + Vector2(devil.pos) * ratio, 3.0, UIK.SAND)
	draw_rect(Rect2(map.position + camera * ratio, span * ratio), Color(UIK.PAPER, 0.45), false, 1.0)
	var me := map.position + pos * ratio
	draw_colored_polygon(PackedVector2Array([me + Vector2.from_angle(heading) * 8.0, me + Vector2.from_angle(heading + 2.5) * 6.0, me + Vector2.from_angle(heading - 2.5) * 6.0]), UIK.PAPER)
	draw_string(UIK.bold_font, map.position + Vector2(6, -10), Game.t("MAP", "MAPA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIK.CREAM)
	# Aviso de acción y estado
	var prompt := ""
	var prompt_key := ""
	var mouse := Game.input_mode == "mouse"
	if safe_mode: prompt = Game.t("SAFE MODE — waiting for power", "MODO SEGURO — esperando energía")
	elif moxie_timer >= 0.0: prompt = Game.t("MOXIE running… %d%%", "MOXIE en marcha… %d%%") % int(moxie_timer / 6.0 * 100.0)
	elif autopilot: prompt = Game.t("AutoNav driving to the next target", "AutoNav conduciendo al siguiente objetivo")
	elif mode == "drive":
		var target := nearest_target()
		if not site_here().is_empty() and "rimfax" in has:
			prompt = Game.t("Scan this radar site", "Escanear este sitio de radar")
			prompt_key = "" if mouse else "R"
		elif not target.is_empty():
			prompt = (Game.t("Click to study: ", "Clic para estudiar: ") if mouse else Game.t("Study: ", "Estudiar: ")) + target_title(target)
			prompt_key = "" if mouse else "E"
	if prompt != "":
		pill(Rect2(view.x * 0.5 - 220, view.y - 104, 440, 42), Color(UIK.ORANGE, 0.97))
		var shift := 0.0
		if prompt_key != "": shift = keycap(Vector2(view.x * 0.5 - 208, view.y - 97), prompt_key)
		draw_string(UIK.bold_font, Vector2(view.x * 0.5 - 210 + shift, view.y - 76), prompt, HORIZONTAL_ALIGNMENT_CENTER, 420 - shift, 18, UIK.INK)
	var status: Array = []
	if meda_on: status.append("MEDA ON")
	if stats.solar: status.append(Game.t("panel dust %d%%", "polvo en paneles %d%%") % int(dust * 100))
	if storming(): status.append(Game.t("DUST STORM", "TORMENTA DE POLVO"))
	if Game.mode == "sandbox": status.append("SANDBOX")
	if Game.coop: status.append(Game.t("CO-OP", "COOPERATIVO"))
	if not status.is_empty():
		draw_string_outline(UIK.bold_font, Vector2(24, view.y - 14), "  ·  ".join(status), HORIZONTAL_ALIGNMENT_LEFT, 500, 14, 5, UIK.INK)
		draw_string(UIK.bold_font, Vector2(24, view.y - 14), "  ·  ".join(status), HORIZONTAL_ALIGNMENT_LEFT, 500, 14, UIK.PAPER)
	# Avisos: como mucho dos a la vez, en su zona reservada (abajo a la izquierda)
	var shown := toasts.slice(maxi(0, toasts.size() - 2))
	for i in range(shown.size()):
		var toast: Dictionary = shown[i]
		var alpha := clampf(minf(float(toast.age) * 4.0, 7.0 - float(toast.age)), 0.0, 1.0)
		var box := Rect2(16, view.y - 118 - (shown.size() - 1 - i) * 76, 392, 68)
		draw_style_box(UIK.box(Color(UIK.PAPER, 0.97 * alpha), 16, Color(UIK.INK, alpha), 2, 4), box)
		draw_multiline_string(UIK.body_font, box.position + Vector2(14, 21), String(toast.text), HORIZONTAL_ALIGNMENT_LEFT, 364, 14, 3, Color(UIK.INK, alpha))
	# Tutorial: resalta el control que toca usar
	if coach_step >= 0 and coach_step < 5 and mode == "drive" and is_instance_valid(action_bar):
		var want: String = {2: "E", 3: "E", 4: "T"}.get(coach_step, "")
		for child in action_bar.get_children():
			if want != "" and child is Button and String(child.get_meta("key", "")) == want:
				var pulse := 0.0 if Game.reduced_motion else 3.0 * (0.5 + 0.5 * sin(time * 6.0))
				draw_style_box(UIK.box(Color.TRANSPARENT, 18, UIK.YELLOW, 4, 0), Rect2(action_bar.position + child.position, child.size).grow(5.0 + pulse))

## Transmisión como recorrido: rover → orbitador → Tierra, con el paquete en curso.
## Las tasas reales y la conversión detallada están en Datos (Tab).
func draw_link_panel(view: Vector2) -> void:
	var box := Rect2(view.x * 0.5 - 230, 92, 460, 118)
	if coach_step >= 0: box.position.x = 452.0   # deja libre la zona del tutorial
	draw_style_box(UIK.box(Color(UIK.INK, 0.93), 16, UIK.MINT, 2, 6), box)
	var packet: Dictionary = packets[0] if not packets.is_empty() else {"label": "", "mb": 1.0, "sent": 0.0}
	var relay := link_kind() == "uhf"
	var a := box.position + Vector2(44, 40)
	var c := box.position + Vector2(box.size.x - 44, 40)
	var b := (a + c) * 0.5 + Vector2(0, -12)
	var stops := [a, b, c] if relay else [a, c]
	for i in range(stops.size() - 1): draw_dashed_line(stops[i], stops[i + 1], Color(UIK.MINT, 0.55), 3.0, 8.0)
	for i in range(stops.size() - 1):
		for n in range(3):
			var along := fmod((time if not Game.reduced_motion else 0.4) * 0.9 + n / 3.0, 1.0)
			draw_circle((stops[i] as Vector2).lerp(stops[i + 1], along), 4.5, UIK.CREAM)
	draw_style_box(UIK.box(UIK.CREAM, 6, UIK.INK, 2, 0), Rect2(a - Vector2(17, 9), Vector2(34, 16)))
	for n in range(3): draw_circle(a + Vector2(-11 + n * 11, 10), 5.0, UIK.INK)
	if relay: Art.orbiter(self, b, 1.0)
	draw_circle(c, 17.0, UIK.INK)
	draw_circle(c, 15.0, Color("#3f7fd0"))
	draw_colored_polygon(Art.blob(c + Vector2(-3, -2), 8, 6, 4, 7, 0.3), UIK.GOOD)
	draw_colored_polygon(Art.blob(c + Vector2(6, 7), 4, 3, 9, 6, 0.3), UIK.GOOD)
	draw_string(UIK.bold_font, a + Vector2(-34, 34), Game.rover_name, HORIZONTAL_ALIGNMENT_CENTER, 68, 12, UIK.CREAM)
	if relay: draw_string(UIK.bold_font, b + Vector2(-50, 36), Game.t("orbiter", "orbitador"), HORIZONTAL_ALIGNMENT_CENTER, 100, 12, UIK.CREAM)
	draw_string(UIK.bold_font, c + Vector2(-34, 34), Game.t("Earth", "Tierra"), HORIZONTAL_ALIGNMENT_CENTER, 68, 12, UIK.CREAM)
	draw_string(UIK.bold_font, box.position + Vector2(18, 92), "%s  ·  %d / %d MB" % [String(packet.label), int(packet.sent), int(packet.mb)], HORIZONTAL_ALIGNMENT_LEFT, 300, 14, UIK.PAPER)
	draw_string(UIK.bold_font, box.position + Vector2(box.size.x - 138, 92), Game.t("Details: Data", "Detalles: Datos") + ("" if Game.input_mode == "mouse" else " [Tab]"), HORIZONTAL_ALIGNMENT_RIGHT, 120, 13, UIK.MINT)
	UIK.bar(self, Rect2(box.position + Vector2(18, 98), Vector2(box.size.x - 36, 12)), float(packet.sent) / maxf(0.1, float(packet.mb)), UIK.MINT, Color(UIK.PAPER, 0.15))

func draw_minigame(view: Vector2) -> void:
	var box := Rect2(view.x * 0.5 - 270, view.y * 0.5 - 130, 540, 260)
	draw_rect(Rect2(Vector2.ZERO, view), Color(UIK.INK, 0.55))
	draw_style_box(UIK.box(UIK.PAPER, 22, UIK.INK, 3), box)
	var id := String(game.id)
	var action := Game.t("click", "haz clic") if Game.input_mode == "mouse" else Game.t("press SPACE", "pulsa ESPACIO")
	var hold := Game.t("Hold the mouse button", "Mantén el botón del ratón") if Game.input_mode == "mouse" else Game.t("Hold SPACE", "Mantén ESPACIO")
	draw_string(UIK.title_font, box.position + Vector2(24, 42), Data.comp_name(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UIK.NAVY)
	draw_multiline_string(UIK.body_font, box.position + Vector2(24, 66), Game.t("What this represents: ", "Qué representa: ") + Game.tt(Data.INSTRUMENTS[id].mini), HORIZONTAL_ALIGNMENT_LEFT, 492, 13, 2, UIK.TEAL)
	var bar := Rect2(box.position + Vector2(60, 150), Vector2(420, 26))
	match String(game.mode):
		"focus":
			draw_multiline_string(UIK.body_font, box.position + Vector2(24, 108), Game.t("When the moving ring sits on the fixed ring, %s.", "Cuando el anillo móvil esté sobre el anillo fijo, %s.") % action, HORIZONTAL_ALIGNMENT_LEFT, 492, 15, 2, UIK.INK)
			var centre := box.position + Vector2(270, 184)
			draw_circle(centre, 30, Color(UIK.TEAL, 0.25))
			draw_arc(centre, 30, 0, TAU, 40, UIK.TEAL, 3.0, true)
			draw_arc(centre, 8.0 + float(game.value) * 44.0, 0, TAU, 40, UIK.RUST, 4.0, true)
		"timing":
			draw_multiline_string(UIK.body_font, box.position + Vector2(24, 108), Game.t("3 shots: %s each time the marker crosses the green zone.", "3 disparos: %s cada vez que el marcador cruce la zona verde.") % action, HORIZONTAL_ALIGNMENT_LEFT, 492, 15, 2, UIK.INK)
			UIK.bar(self, bar, 0.0, UIK.TEAL)
			draw_style_box(UIK.box(UIK.GOOD if float(game.flash) <= 0.0 else UIK.YELLOW, 10, Color.TRANSPARENT, 0, 0), Rect2(bar.position + Vector2(bar.size.x * 0.37, 0), Vector2(bar.size.x * 0.26, bar.size.y)))
			draw_rect(Rect2(bar.position + Vector2(bar.size.x * float(game.value) - 4, -8), Vector2(8, bar.size.y + 16)), UIK.INK)
			draw_string(UIK.bold_font, box.position + Vector2(24, 222), "%s %d / 3    %s %d" % [Game.t("Shots", "Disparos"), int(game.tries), Game.t("on target", "en el blanco"), int(game.hits)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UIK.MUTED)
		"steady":
			draw_multiline_string(UIK.body_font, box.position + Vector2(24, 108), Game.t("%s to raise the pointer; release to lower it. Keep it inside the moving green band.", "%s para subir el puntero; suelta para bajarlo. Mantenlo dentro de la banda verde móvil.") % hold, HORIZONTAL_ALIGNMENT_LEFT, 492, 15, 2, UIK.INK)
			UIK.bar(self, bar, 0.0, UIK.TEAL)
			draw_style_box(UIK.box(UIK.GOOD, 10, Color.TRANSPARENT, 0, 0), Rect2(bar.position + Vector2(bar.size.x * (float(game.band) - 0.14), 0), Vector2(bar.size.x * 0.28, bar.size.y)))
			draw_rect(Rect2(bar.position + Vector2(bar.size.x * float(game.value) - 4, -8), Vector2(8, bar.size.y + 16)), UIK.INK)
			UIK.bar(self, Rect2(box.position + Vector2(60, 204), Vector2(420, 14)), float(game.progress), UIK.ORANGE)
