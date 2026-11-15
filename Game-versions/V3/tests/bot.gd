extends Node
## Bot de pruebas de 2Mars. Juega el juego REAL: pulsa los botones de la interfaz, conduce con
## acciones de entrada y opera los instrumentos con las reglas normales (no hace trampas).
##
## Uso (frecuencia fija para que el tiempo sea determinista):
##   godot --headless --fixed-fps 60 res://tests/Bot.tscn                 todo
##   godot --headless --fixed-fps 60 res://tests/Bot.tscn -- --es         todo, en español
##   godot --headless --fixed-fps 60 res://tests/Bot.tscn -- --quick      solo el flujo completo de una misión
##   godot ... -- --shots=CARPETA                                         guarda capturas (necesita pantalla)
## Usa su propio archivo de guardado: no toca partidas reales.

const TEST_SAVE := "user://2mars_bot_save.json"
const TEST_LEGACY := "user://2mars_bot_legacy.json"

var failures: Array = []
var checks := 0
var main: Control
var shots_dir := ""
var args: PackedStringArray
var stuck_from := Vector2.ZERO
var stuck_clock := 0.0
var sidestep := 0.0
var events := {}

const BUILDS := {
	"geology": {"chassis": "chassis_std", "deck": "deck_compact", "wheels": "wheels_std", "power": "solar", "computer": "cpu_basic", "arm": "", "parts": ["uhf", "mastcam", "supercam"]},
	"life": {"chassis": "chassis_std", "deck": "deck_compact", "wheels": "wheels_std", "power": "solar", "computer": "cpu_basic", "arm": "arm_std", "parts": ["uhf", "battery_ext", "storage", "mastcam", "supercam", "sherloc"]},
	"archive": {"chassis": "chassis_std", "deck": "deck_compact", "wheels": "wheels_reinf", "power": "solar", "computer": "cpu_basic", "arm": "arm_std", "parts": ["uhf", "hga", "battery_ext", "mastcam", "supercam", "drill"]},
	"frontier": {"chassis": "chassis_std", "deck": "deck_compact", "wheels": "wheels_std", "power": "rtg", "computer": "cpu_basic", "arm": "", "parts": ["uhf", "storage", "meda", "moxie", "rimfax", "mastcam"]}
}
## Diseño con compromisos fuertes: ligero y barato, sin instrumento de composición y solo enlace directo.
const COMPROMISED := {"chassis": "chassis_light", "deck": "deck_compact", "wheels": "wheels_light", "power": "solar", "computer": "cpu_basic", "arm": "", "parts": ["hga", "mastcam"]}

func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("  ok   ", text)
	else:
		failures.append(text)
		print("  FAIL ", text)

func frames(count: int) -> void:
	for i in range(count): await get_tree().process_frame

func seconds(amount: float) -> void:
	await frames(int(amount * 60.0))

func screen(expected: String) -> Control:
	for i in range(600):
		if main.current_name == expected and not main.busy and is_instance_valid(main.current): break
		await get_tree().process_frame
	check(main.current_name == expected, "Screen opens: " + expected)
	await frames(3)
	return main.current

func shot(label: String) -> void:
	if shots_dir == "": return
	RenderingServer.render_loop_enabled = true
	await frames(22)   # deja terminar la aparición de paneles (0,25 s)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [shots_dir, label])
	RenderingServer.render_loop_enabled = false   # entre capturas no se dibuja: el recorrido va rápido

## Pulsa el primer botón visible y activo cuyo texto contiene alguno de los fragmentos.
func press(root: Node, fragments: Array) -> bool:
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button.disabled or not button.is_visible_in_tree(): continue
		for fragment in fragments:
			if button.text.contains(String(fragment)):
				button.pressed.emit()
				return true
	return false

func t(en: String, es: String) -> String:
	return Game.t(en, es)

func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)

func _ready() -> void:
	args = OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--shots="): shots_dir = arg.trim_prefix("--shots=")
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
		RenderingServer.render_loop_enabled = false
	for path in [TEST_SAVE, TEST_LEGACY]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Game.save_path = TEST_SAVE
	Game.legacy_path = TEST_LEGACY
	Game.load_save()
	Game.volume = 0.0
	Game.apply_volume()
	if "--es" in args: Game.lang = "es"
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	if "--tour" in args:   # solo capturas de tres pantallas al tamaño de ventana actual (--resolution)
		await tour()
		get_tree().quit(0)
		return
	await data_checks()
	await first_mission()
	if not "--quick" in args:
		await save_checks()
		await edge_checks()
		await contrast()
		for zone in ["life", "archive", "frontier"]: await zone_run(zone)
		await adaptive_checks()
		await sandbox_checks()
		await coop_checks()
		await language_checks()
		await menu_screens()
	print("BOT SUMMARY: %d checks; %d failures" % [checks, failures.size()])
	for failure in failures: print("  FAILED: ", failure)
	for path in [TEST_SAVE, TEST_LEGACY]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	get_tree().quit(1 if not failures.is_empty() else 0)

# ------------------------------------------------------------------ datos e ingeniería
func data_checks() -> void:
	print("== Engineering data")
	check(Data.COMPONENTS.size() == 30, "Catalogue has the workbook's 30 components (%d)" % Data.COMPONENTS.size())
	var listed := {}
	for group in Data.GROUPS:
		for id in group.options: listed[id] = true
	check(listed.size() == 30, "Every component is selectable in a workshop group (%d)" % listed.size())
	var base := Data.default_build()
	var s := Data.stats(base)
	check(Data.mass(base) == 267 and Data.cost(base) == 1400, "Default rover: 267 kg and 1400 cr from selected parts only (got %d kg, %d cr)" % [Data.mass(base), Data.cost(base)])
	var rtg := base.duplicate(true)
	rtg.power = "rtg"
	var r := Data.stats(rtg)
	check(float(r.gen_w) == 300.0 and float(r.idle_w) == float(s.idle_w), "RTG output is generation, never added to consumption (%d W gen, %d W idle)" % [int(r.gen_w), int(r.idle_w)])
	var battery := base.duplicate(true)
	battery.parts.append("battery_ext")
	check(float(Data.stats(battery).battery) == 1100.0 and float(Data.stats(battery).memory) == float(s.memory), "Extended battery adds Wh, not MB of memory")
	var storage := base.duplicate(true)
	storage.parts.append("storage")
	check(float(Data.stats(storage).memory) == 200.0 and float(Data.stats(storage).battery) == float(s.battery), "Large storage adds MB, not Wh")
	var heavy := base.duplicate(true)
	heavy.chassis = "chassis_reinf"
	check(float(Data.stats(heavy).drive_w) > float(s.drive_w) and float(Data.stats(heavy).speed) < float(s.speed), "More mass costs more power to drive and lowers speed")
	var plan := Game.default_plan()
	var levels := func(build: Dictionary, zone: String) -> Dictionary:
		var out := {}
		for item in Data.check(build, zone, plan): out[item.level] = int(out.get(item.level, 0)) + 1
		return out
	var frontier: Dictionary = levels.call(base, "frontier")
	check(not frontier.has("blocker") and frontier.has("limit") and frontier.has("risk"), "Default rover in Landing Plains: limitations and risks, no blocker " + str(frontier))
	var pixl := base.duplicate(true)
	pixl.parts.append("pixl")
	var found := Data.check(pixl, "geology", plan).filter(func(item: Dictionary) -> bool: return item.level == "blocker")
	check(found.size() == 1 and found[0].has("fix"), "PIXL without an arm is a compatibility blocker with a one-click fix")
	var everything := base.duplicate(true)
	everything.deck = "deck_ext"
	everything.arm = "arm_ext"
	everything.parts = ["uhf", "hga", "rocker", "battery_ext", "storage", "navsens", "drill", "regolith"] + Data.INSTRUMENT_ORDER
	var all_levels: Dictionary = levels.call(everything, "geology")
	check(int(all_levels.get("blocker", 0)) >= 3, "A rover with everything is blocked by mass, budget and deck space " + str(all_levels))
	var mute := base.duplicate(true)
	mute.parts.erase("uhf")
	check(int(levels.call(mute, "geology").get("blocker", 0)) == 1, "No antenna blocks the launch")
	check(Data.readiness_index(Data.check(base, "geology", plan), "geology") > Data.readiness_index(Data.check(base, "frontier", plan), "frontier"), "Readiness index responds to the zone")
	var old := Data.migrate_build({"power": "rtg", "battery": "large", "wheels": "rugged", "comms": "hga", "computer": "expanded", "instruments": ["mastcam", "arm", "pixl"]})
	check(old.power == "rtg" and old.wheels == "wheels_reinf" and old.arm == "arm_std" and "drill" in old.parts and "battery_ext" in old.parts and "hga" in old.parts and "storage" in old.parts and "pixl" in old.parts, "A ToMars 1.0 design migrates to the new catalogue")
	check(Data.recommendations([]).size() == 1, "With no history, recommendations give beginner guidance")
	for id in Data.QUIZ:
		var quiz: Dictionary = Data.QUIZ[id]
		check(quiz.has("see") and quiz.has("term") and quiz.wrong.size() == quiz.options.size(), "Quiz '%s' gives evidence, a term and feedback for every option" % id)
	await frames(1)

# ------------------------------------------------------------------ primera misión completa
func first_mission() -> void:
	print("== First mission, full flow")
	var boot := await screen("boot")
	for i in range(4000):   # la carga va en hilos: depende del tiempo real, no de los fotogramas
		if boot.phase != "load": break
		OS.delay_msec(2)
		await get_tree().process_frame
	check(boot.loaded == boot.ASSETS.size() and boot.phase == "setup", "Boot shows real loading progress, then asks language and input mode (loaded %d/%d, phase %s)" % [boot.loaded, boot.ASSETS.size(), boot.phase])
	await shot("01-boot-setup")
	boot.set_mode("both")
	await frames(2)
	check(press(boot, [t("Continue", "Continuar")]), "Setup can be confirmed")
	var menu := await screen("menu")
	check(Game.setup_done, "Setup choice is remembered")
	await seconds(1.0)
	await shot("02-menu")
	check(press(menu, [t("START NEW GAME", "PARTIDA NUEVA")]), "Menu starts a new game")
	var profiles := await screen("profiles")
	await shot("03-files")
	profiles.pick(0)
	check(press(profiles, [t("CREATE", "CREAR")]), "An empty file can be created")
	await frames(3)
	profiles.team_box.text = "Bot Team"
	profiles.emblem = 2
	await shot("04-team")
	check(press(profiles, [t("CONTINUE", "CONTINUAR")]), "Team name and emblem are confirmed")
	var briefing := await screen("briefing")
	check(Game.team_name == "Bot Team" and Game.emblem == 2 and bool(Game.slots[0].used), "Team is stored in save file 1")
	briefing.name_box.text = "Ada"
	await shot("05-briefing-name")
	briefing.next()
	await frames(3)
	briefing.rover_box.text = "BOT-1"
	briefing.mission_box.text = "Test One"
	briefing.next()
	await seconds(1.2)
	briefing.explain(3)
	await shot("06-briefing-factors")
	briefing.next()
	await seconds(1.0)
	await shot("07-how-to-play")
	check(press(briefing, [t("Wait!", "¡Espera!")]), "Optional conversation with Dr. Owen opens")
	await seconds(0.8)
	await shot("08-owen-story")
	check(Game.stories.size() == 1 and Game.achievements.has("curious"), "The story is recorded and unlocks a hidden achievement")
	press(briefing, [t("Thanks", "Gracias")])
	await frames(3)
	check(press(briefing, [t("To the lab", "Al laboratorio")]), "Briefing ends")
	var hub := await screen("hub")
	check(Game.player_name == "Ada" and Game.rover_name == "BOT-1" and Game.mission_name == "Test One" and bool(Game.tutorial.get("intro", false)), "Names are stored and used")
	await seconds(1.0)
	await shot("09-earth-station")
	check(press(hub, [t("MISSION PANEL", "PANEL DE MISIONES")]), "Hub opens the mission panel")
	var zones := await screen("zones")
	await seconds(1.5)
	var spot: Array = zones.project(18.4, 77.5)
	check(bool(spot[1]) and absf(Vector2(spot[0]).x - zones.CENTER.x) < 40.0, "The globe turns to bring Jezero to the front")
	var before: float = zones.spin
	zones.nudge(0.5)
	await seconds(0.5)
	check(absf(zones.spin - before) > 0.2, "The globe rotates on input")
	zones.find_jezero()
	await seconds(1.0)
	await shot("10-mission-panel")
	zones.pick("life")
	await frames(3)
	check(not Game.zone_unlocked("life"), "Later zones stay locked until the previous one is done")
	zones.pick("geology")
	await frames(3)
	check(press(zones, [t("PLAN THIS MISSION", "PLANIFICAR ESTA MISIÓN")]), "A zone can be planned")
	var plan := await screen("plan")
	var cap_before: int = Data.limits(plan.plan).budget
	plan.choose("window", "late")
	check(int(Data.limits(plan.plan).budget) == cap_before + 250 and Data.mission_time("geology", plan.plan) < Data.mission_time("geology", Game.default_plan()), "Launch window changes budget and surface time")
	plan.choose("window", "optimal")
	plan.choose("site", "rough")
	plan.choose("priority", "composition")
	await frames(3)
	await shot("11-mission-planning")
	check(press(plan, [t("CONFIRM PLAN", "CONFIRMAR PLAN")]), "Plan is confirmed")
	var design := await screen("design")
	check(String(Game.plan.site) == "rough" and String(Game.plan.priority) == "composition", "Plan choices are saved")
	check(design.coach_step == 0, "First visit to the workshop starts the guided tutorial")
	await seconds(0.8)
	await shot("12-workshop-tutorial")
	design.open_category("science")
	check(design.coach_step == 1, "Tutorial step 1 completes on a real action (category opened)")
	design.preview("pixl")
	check(design.coach_step == 2, "Tutorial step 2 completes when a component is previewed")
	await frames(3)
	await shot("13-workshop-compare")
	var mass_before: int = Data.mass(design.build)
	design.install("pixl")
	check(design.coach_step == 3 and Data.mass(design.build) == mass_before + 8, "Installing a component updates the rover and advances the tutorial")
	await seconds(0.6)
	design.open_readiness()
	await frames(3)
	check(design.coach_step == -1 and bool(Game.tutorial.get("workshop", false)), "Tutorial ends at Mission Readiness and is recorded once")
	await shot("14-readiness-blocker")
	check(Data.count_level(Data.check(design.build, "geology", Game.plan), "blocker") == 1, "Readiness reports the real blocker (PIXL with no arm)")
	check(press(design, [t("Add the standard arm", "Añadir el brazo estándar")]), "The blocker offers a fix")
	await frames(3)
	check(Data.count_level(Data.check(design.build, "geology", Game.plan), "blocker") == 0 and String(design.build.arm) == "arm_std", "Applying the fix resolves the blocker")
	UIK.close_modal(design)
	design.build = BUILDS.geology.duplicate(true)
	design.persist()
	design.refresh()
	design.save_design()
	check(Game.saved_rovers.size() == 1, "A design can be saved to the hangar")
	design.open_readiness()
	await seconds(0.5)
	await shot("15-readiness")
	check(press(design, [t("GO FOR LAUNCH", "LISTOS PARA LANZAR")]), "Launch is allowed with no blockers")
	var transit := await screen("transit")
	await seconds(1.2)
	await shot("16-launch-preparation")
	check(press(transit, [t("LAUNCH NOW", "LANZAR AHORA")]), "Launch starts from the preparation screen")
	await seconds(2.0)
	await shot("17-countdown")
	for i in range(900):
		if transit.phase == "ascent": break
		await get_tree().process_frame
	await seconds(1.5)
	await shot("18-liftoff")
	check(Game.achievements.has("first_launch"), "First launch is recorded")
	for i in range(1500):
		if transit.phase == "event": break
		await get_tree().process_frame
	check(transit.phase == "event" and transit.events_done == 0, "Cruise raises the communication interruption")
	await seconds(0.5)
	await shot("19-cruise-comm-event")
	transit.comm_answer("log")
	await frames(5)
	transit.comm_restored()
	await seconds(0.4)
	await shot("20-cruise-restored")
	transit.resume_cruise()
	for i in range(1500):
		if transit.phase == "event": break
		await get_tree().process_frame
	check(transit.events_done == 1, "Cruise raises the energy review")
	transit.energy_answer("review", Data.stats(Game.build))
	await seconds(0.4)
	await shot("21-cruise-energy-review")
	transit.energy_answer("save", Data.stats(Game.build))
	await frames(5)
	check(float(transit.flight.charge) == 1.0 and float(transit.flight.delay) > 0.0, "Energy-saving mode has a real effect: full battery, later check-out")
	transit.resume_cruise()
	for i in range(1500):
		if transit.phase == "edl": break
		await get_tree().process_frame
	await seconds(4.5)
	await shot("22-entry-descent-landing")
	for i in range(1500):
		if transit.phase == "landed": break
		await get_tree().process_frame
	await seconds(0.8)
	await shot("23-touchdown")
	check(Game.achievements.has("touchdown") and float(Game.flight.damage) > 0.0 and float(Game.flight.charge) == 1.0, "Landing outcome depends on design and site (damage %d%%)" % int(Game.flight.get("damage", 0)))
	transit.begin_ops()
	transit.begin_ops()
	var ops := await screen("ops")
	check(main.current_name == "ops", "Pressing 'begin' twice reaches operations exactly once")
	check(is_equal_approx(ops.integrity, 100.0 - float(Game.flight.damage)) and is_equal_approx(ops.energy, float(ops.stats.battery)), "Operations start from the landing state")
	await shot("24-ops-briefing")
	ops.begin()
	await frames(5)
	check(ops.coach_step == 0, "First mission on Mars starts the guided tutorial")
	await shot("25-ops-tutorial")
	events = {}
	await play_ops(ops, {"shots": true})
	var debrief := await screen("debrief")
	await seconds(1.5)
	await shot("30-debrief")
	var report: Dictionary = Game.report
	check(int(report.done) == int(report.required) and String(report.grade) in ["S", "A", "B"], "Geology: required objectives complete under real rules (grade %s, score %.0f)" % [report.grade, float(report.score)])
	check(bool(Game.tutorial.get("ops", false)), "Mars tutorial completed and recorded")
	check(debrief.dimensions().size() == 6, "Debrief shows six evaluation dimensions")
	check(float(report.dims.data) >= 0.0 and float(report.dims.data) <= 100.0 and is_equal_approx(float(report.received) + float(report.lost), float(report.collected)), "Data return is consistent: received + left on board = recorded (no double counting)")
	check(not debrief.causes().why.is_empty() and not debrief.causes().next.is_empty(), "Debrief explains causes and next steps")
	debrief.detail_open = true
	debrief.fill_right()
	await frames(3)
	await shot("31-debrief-detail")
	check(Game.history.size() == 1 and Game.progress.has("geology"), "Mission is saved to the history and campaign progress")
	check(Game.achievements.has("first_data"), "Achievements come from real events")
	check(press(debrief, [t("Earth station", "Base terrestre")]), "Debrief returns to the Earth station")
	await screen("hub")
	check(Game.zone_unlocked("life"), "Completing the zone unlocks the next one")

# ------------------------------------------------------------------ jugador honesto
func nearest(ops: Control, items: Array) -> Dictionary:
	var best := {}
	var gap := INF
	for item in items:
		if ops.pos.distance_to(item.pos) < gap:
			gap = ops.pos.distance_to(item.pos)
			best = item
	return best

## Decide la siguiente tarea útil según los objetivos pendientes y los instrumentos a bordo.
func want(ops: Control, optional: bool) -> Dictionary:
	var has: Array = ops.has
	var contact: bool = "arm" in has
	var composition := "supercam" if "supercam" in has else ("pixl" if "pixl" in has and contact else "")
	for goal in ops.objective_state():
		if goal.done or (goal.opt and not optional): continue
		var pool: Array = []
		var id := ""
		match String(goal.kind):
			"imaged", "angles":
				if not "mastcam" in has: continue
				id = "mastcam"
				pool = ops.targets.filter(func(x: Dictionary) -> bool: return not x.imaged) if goal.kind == "imaged" else ops.targets.filter(func(x: Dictionary) -> bool: return int(x.photos) < 3 and int(x.photos) > 0)
				if pool.is_empty() and goal.kind == "angles": pool = ops.targets.filter(func(x: Dictionary) -> bool: return int(x.photos) < 3)
			"chem_types":
				if composition == "": continue
				id = composition
				var known := {}
				for target in ops.targets:
					if target.chem or target.pixl: known[target.type] = true
				pool = ops.targets.filter(func(x: Dictionary) -> bool: return not known.has(x.type))
			"aqueous":
				if composition == "": continue
				id = composition
				pool = ops.targets.filter(func(x: Dictionary) -> bool: return Data.ROCKS[x.type].aqueous and not (x.chem or x.pixl))
			"pixl":
				if not ("pixl" in has and contact): continue
				id = "pixl"
				pool = ops.targets.filter(func(x: Dictionary) -> bool: return not x.pixl and Data.ROCKS[x.type].klass != "soil")
			"sherloc":
				if not ("sherloc" in has and contact): continue
				id = "sherloc"
				pool = ops.targets.filter(func(x: Dictionary) -> bool: return not x.sherloc and Data.ROCKS[x.type].organics)
				if pool.is_empty(): pool = ops.targets.filter(func(x: Dictionary) -> bool: return not x.sherloc)
			"quiz":
				if composition != "" and not ops.quiz_done.has("water"):
					id = composition
					pool = ops.targets.filter(func(x: Dictionary) -> bool: return Data.ROCKS[x.type].aqueous and not (x.chem or x.pixl))
				if pool.is_empty() and composition != "" and not ops.quiz_done.has("igneous"):
					id = composition
					pool = ops.targets.filter(func(x: Dictionary) -> bool: return Data.ROCKS[x.type].klass == "igneous" and not (x.chem or x.pixl))
				if pool.is_empty() and "sherloc" in has and contact and not ops.quiz_done.has("organics"):
					id = "sherloc"
					pool = ops.targets.filter(func(x: Dictionary) -> bool: return Data.ROCKS[x.type].organics and not x.sherloc)
			"cache_types", "cache_documented":
				if not ("drill" in has and contact) or ops.tubes <= 0: continue
				var types := {}
				for sample in ops.cached: types[sample.type] = true
				pool = ops.targets.filter(func(x: Dictionary) -> bool: return not x.cached and not types.has(x.type) and Data.ROCKS[x.type].klass != "soil")
				var choice := nearest(ops, pool)
				if choice.is_empty(): continue
				return {"target": choice, "id": "mastcam" if "mastcam" in has and not choice.imaged else "drill"}
			"regolith":
				if not "regolith" in has or ops.tubes <= 0: continue
				id = "regolith"
				pool = ops.targets.filter(func(x: Dictionary) -> bool: return Data.ROCKS[x.type].klass == "soil" and not x.cached)
			"meda":
				if "meda" in has and not ops.meda_on: return {"tool": "meda"}
				continue
			"moxie":
				if "moxie" in has: return {"tool": "moxie"}
				continue
			"rimfax":
				if not "rimfax" in has: continue
				var open: Array = ops.sites.filter(func(x: Dictionary) -> bool: return not x.scanned)
				if not open.is_empty(): return {"site": nearest(ops, open)}
				continue
			"received":
				# Faltan MB: generar más ciencia útil, como haría un jugador (otra foto u otro análisis).
				if ops.received_mb + ops.memory_used() >= float(goal.need) + 1.0: continue
				if composition != "":
					id = composition
					pool = ops.targets.filter(func(x: Dictionary) -> bool: return not (x.chem or x.pixl))
				if pool.is_empty() and "mastcam" in has:
					id = "mastcam"
					pool = ops.targets.filter(func(x: Dictionary) -> bool: return int(x.photos) < 3)
				if pool.is_empty() and "rimfax" in has:
					var more: Array = ops.sites.filter(func(x: Dictionary) -> bool: return not x.scanned)
					if not more.is_empty(): return {"site": nearest(ops, more)}
				if pool.is_empty() and "meda" in has and not ops.meda_on: return {"tool": "meda"}
		var pick := nearest(ops, pool)
		if not pick.is_empty(): return {"target": pick, "id": id}
	return {}

func steer(ops: Control, goal: Vector2, delta: float) -> void:
	var way: Vector2 = (goal - ops.pos).normalized()
	stuck_clock += delta
	if stuck_clock > 1.2:
		if ops.pos.distance_to(stuck_from) < 24.0: sidestep = 0.9
		stuck_from = ops.pos
		stuck_clock = 0.0
	if sidestep > 0.0:
		sidestep -= delta
		way = way.rotated(1.5)
	var prefix := "p1_" if Game.coop else "move_"
	for item in [["left", -way.x], ["right", way.x], ["up", -way.y], ["down", way.y]]:
		if float(item[1]) > 0.15: Input.action_press(prefix + String(item[0]), minf(1.0, float(item[1]) * 1.4))
		else: Input.action_release(prefix + String(item[0]))

func halt() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "p1_left", "p1_right", "p1_up", "p1_down", "interact"]: Input.action_release(action)

## Resuelve el diálogo abierto como lo haría una persona: lee el texto de los botones.
func handle_dialog(ops: Control, options: Dictionary) -> void:
	if ops.mode == "brief":
		ops.begin()
		return
	var keys: Array = ops.hotkeys.filter(func(b: Variant) -> bool: return is_instance_valid(b))
	if keys.is_empty():
		if ops.confirmable or ops.mode in ["menu", "paused"]: ops.close_dialog()
		return
	var first: String = keys[0].text
	if first.contains(t("Finish and debrief", "Terminar e informe")):
		events["required_prompt"] = true
		if options.get("keep_exploring", false) and not events.has("kept"):
			events["kept"] = true
			keys[1].pressed.emit()
		else: keys[0].pressed.emit()
		return
	if first.contains(t("harder rock", "roca más dura")):
		events["failed_sample"] = int(events.get("failed_sample", 0)) + 1
		if options.get("shots", false): await shot("28-failed-sample")
		if not keys[1].disabled: keys[1].pressed.emit()
		else: keys[0].pressed.emit()
		return
	if keys.size() == 1 and (first.contains(t("Try again", "Intentar otra vez")) or first.contains(t("Continue", "Continuar"))):
		keys[0].pressed.emit()
		return
	for id in Data.QUIZ:
		var quiz: Dictionary = Data.QUIZ[id]
		if keys.size() != quiz.options.size() or not first.ends_with(Game.tt(quiz.options[0])): continue
		events["quiz"] = int(events.get("quiz", 0)) + 1
		if options.get("shots", false) and not events.has("quiz_shot"):
			events["quiz_shot"] = true
			await shot("27-ops-interpretation")
		var answer := int(quiz.correct)
		if options.get("miss_first", false) and not events.has("missed"):
			events["missed"] = true
			answer = (answer + 1) % quiz.options.size()
		keys[answer].pressed.emit()
		return
	ops.close_dialog()

func play_minigame(ops: Control) -> void:
	var game: Dictionary = ops.game
	match String(game.mode):
		"focus":
			if absf(float(game.value) - 0.5) < 0.04: ops.press_minigame()
		"timing":
			if absf(float(game.value) - 0.5) < 0.06 and float(game.flash) <= 0.0 and float(game.t) - float(game.get("bot_last", -1.0)) > 0.3:
				game["bot_last"] = float(game.t)
				ops.press_minigame()
		"steady":
			if float(game.value) < float(game.band): Input.action_press("interact")
			else: Input.action_release("interact")

## Juega una misión completa con las reglas reales. options: optional, keep_exploring, miss_first, shots, limit.
func play_ops(ops: Control, options: Dictionary) -> void:
	var optional: bool = options.get("optional", false)
	var idle := 0.0
	var shot_drive := false
	var shot_link := false
	stuck_from = ops.pos
	for frame in range(60 * 60 * 9):
		if not is_instance_valid(ops) or ops.mode == "ended" or main.current_name != "ops": break
		await get_tree().process_frame
		if not is_instance_valid(ops) or ops.mode == "ended": break
		var delta := 1.0 / 60.0
		if not ops.gate.is_empty():
			halt()
			await key(KEY_ENTER)
			await key(KEY_F)
			continue
		if ops.mode == "minigame":
			play_minigame(ops)
			continue
		Input.action_release("interact")
		if ops.mode != "drive":
			halt()
			await handle_dialog(ops, options)
			continue
		if options.get("shots", false) and not shot_drive and ops.clock > 6.0:
			shot_drive = true
			await shot("26-ops-driving")
		if ops.transmitting:
			halt()
			if options.get("shots", false) and not shot_link and ops.received_mb > 4.0:
				shot_link = true
				await shot("29-ops-transmitting")
			continue
		if ops.safe_mode or ops.moxie_timer >= 0.0:
			halt()
			continue
		if float(options.get("limit", 0.0)) > 0.0 and ops.clock > float(options.limit):
			halt()
			ops.finish("player")
			break
		var task := want(ops, optional)
		var data_waiting: bool = not ops.packets.is_empty()
		var memory_tight: bool = ops.memory_used() > float(ops.stats.memory) * 0.55
		if data_waiting and ops.link_rate() > 0.0 and (task.is_empty() or memory_tight or task.has("tool") or ops.link_kind() == "uhf"):
			halt()
			if ops.vel.length() < 10.0: ops.toggle_transmit()
			continue
		if ops.energy < float(ops.stats.battery) * 0.18 and float(ops.net_w) > 0.0:
			halt()   # recargar antes de la siguiente tarea
			continue
		if task.is_empty():
			halt()
			if ops.required_done() and not data_waiting and (not optional or ops.all_objectives_done()):
				ops.ask_finish()
			idle += delta
			continue
		if task.has("tool"):
			if task.tool == "meda": ops.toggle_meda()
			elif ops.energy > Data.activity_wh(ops.build, "moxie") * 0.85 or not ops.stats.solar:
				halt()
				if ops.vel.length() < 10.0: ops.start_moxie()
			else: halt()
			continue
		if task.has("site"):
			var site: Dictionary = task.site
			if ops.pos.distance_to(site.pos) > float(site.r) * 0.6: steer(ops, site.pos, delta)
			else:
				halt()
				if ops.energy > Data.activity_wh(ops.build, "rimfax") + 25.0: ops.start_radar()
			continue
		var target: Dictionary = task.target
		var id := String(task.id)
		var info: Dictionary = Data.INSTRUMENTS[id]
		var reach: float = float(ops.stats.reach) if (info.arm or id == "regolith") else float(info.range)
		var gap: float = ops.pos.distance_to(target.pos) - float(target.r)
		if gap > reach - 14.0:
			steer(ops, target.pos, delta)
			continue
		halt()
		if ops.vel.length() > 20.0: continue
		ops.show_actions(target)
		var label := Data.comp_name(id)
		if id == "drill": label = t("Core and cache", "Extraer y guardar")
		elif id == "regolith": label = t("Scoop a regolith", "Recoger muestra de regolito")
		var pressed := false
		for button in ops.hotkeys:
			if is_instance_valid(button) and button.text.contains(label) and not button.disabled:
				button.pressed.emit()
				pressed = true
				break
		if not pressed:
			ops.close_dialog()
			await seconds(0.4)   # sin energía o memoria: esperar recarga o un enlace
	halt()

## Lanza una zona directamente a operaciones (sin repetir el viaje) y la juega.
func fly(zone: String, build: Dictionary, options: Dictionary = {}) -> Dictionary:
	Game.mode = "campaign"
	Game.zone = zone
	Game.build = build.duplicate(true)
	Game.plan = Game.default_plan()
	Game.flight = {"charge": 1.0, "damage": 2.0, "near": 0.0, "delay": 0.0}
	Game.tutorial["ops"] = true
	Game.last_issue = Data.check(build, zone, Game.plan)
	events = {}
	Game.go("ops")
	var ops := await screen("ops")
	ops.begin()
	await play_ops(ops, options)
	await screen("debrief")
	return Game.report.duplicate(true)

func zone_run(zone: String) -> void:
	print("== Zone under real rules: ", zone)
	var report := await fly(zone, BUILDS[zone], {"miss_first": zone == "life"})
	await seconds(1.0)
	await shot("40-debrief-" + zone)
	for goal in report.goals:
		if not goal.done and not goal.opt: print("     missed: %s (%d/%d)" % [goal.text, int(goal.value), int(goal.need)])
	print("     %s: grade %s score %.0f · required %d/%d · received %d MB · left %d MB · time %d/%d s · safe %d · reason %s" % [zone, report.grade, float(report.score), int(report.done), int(report.required), int(report.received), int(report.lost), int(report.time), int(report.time_limit), int(report.safe), report.reason])
	print("     dims: ", report.dims, " science ", report.science, "/", report.science_ref, " health ", int(report.integrity), " energy used ", int(report.energy_used), " Wh")
	check(int(report.done) == int(report.required), "%s: every required objective is reachable with a fitting design" % zone)
	check(String(report.grade) in ["S", "A", "B"], "%s is beatable under real rules (grade %s)" % [zone, report.grade])
	check(float(report.time) < float(report.time_limit), "%s ends when required objectives are done, before the time limit" % zone)
	if zone == "life": check(events.has("missed") and int(report.quiz_right) < int(report.quiz_asked), "A wrong interpretation gets feedback and a learning retry, and is not counted as first-try")
	if zone == "archive":
		check(int(events.get("failed_sample", 0)) >= 1 and int(report.failed_samples) >= 1, "Fragile rock triggers the failed-sample event (%d)" % int(events.get("failed_sample", 0)))
		check(report.samples.size() >= 3, "Samples are catalogued with their context (%d)" % report.samples.size())

# ------------------------------------------------------------------ contraste de diseños
func contrast() -> void:
	print("== Two contrasting rovers, same zone")
	var balanced := await fly("geology", BUILDS.geology)
	var debrief: Control = main.current
	var why_a: Array = debrief.causes().why
	var weak := await fly("geology", COMPROMISED, {"limit": 200.0})
	debrief = main.current
	await seconds(1.0)
	await shot("41-debrief-compromised")
	var why_b: Array = debrief.causes().why
	print("     balanced:    grade %s · required %d/%d · science %d · data %d%%" % [balanced.grade, int(balanced.done), int(balanced.required), int(balanced.science), int(balanced.dims.data)])
	print("     compromised: grade %s · required %d/%d · science %d · data %d%%" % [weak.grade, int(weak.done), int(weak.required), int(weak.science), int(weak.dims.data)])
	for line in why_b: print("       why: ", line)
	check(int(balanced.done) > int(weak.done), "Contrasting designs reach different numbers of required objectives")
	check(String(balanced.grade) != String(weak.grade), "Contrasting designs end with different grades")
	check(float(balanced.dims.science) > float(weak.dims.science), "Scientific return differs with the payload")
	check(str(why_a) != str(why_b) and str(why_b).contains(t("out of reach", "fuera de alcance")), "The debrief traces the weaker result to the design")

# ------------------------------------------------------------------ guardado
func save_checks() -> void:
	print("== Save and load")
	Game.save()
	var snapshot := {"player": Game.player_name, "history": Game.history.size(), "build": Game.build.hash(), "achievements": Game.achievements.size()}
	Game.player_name = "changed"
	Game.load_save()
	check(Game.player_name == String(snapshot.player) and Game.history.size() == int(snapshot.history) and Game.achievements.size() == int(snapshot.achievements), "A returning save restores names, history and achievements")
	Game.start_slot(1, true)
	check(Game.progress.is_empty() and Game.history.is_empty() and not bool(Game.tutorial.get("intro", false)), "A second file starts clean")
	Game.select_slot(0)
	check(Game.progress.has("geology"), "Switching back keeps the first file intact")
	Game.slots[1] = Game.blank_slot()
	Game.save()
	# Guardado antiguo de ToMars 1.0
	var legacy := FileAccess.open(TEST_LEGACY, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"lang": "es", "rover_name": "VIEJO-7", "build": {"power": "rtg", "battery": "large", "wheels": "rugged", "comms": "hga", "computer": "expanded", "instruments": ["mastcam", "supercam", "arm"]}, "progress": {"geology": {"grade": "A", "science": 55, "runs": 2}}, "hints": {}, "volume": 0.5}))
	legacy.close()
	var keep := Game.save_path
	var language := Game.lang
	Game.save_path = "user://2mars_bot_missing.json"
	Game.load_save()
	check(Game.rover_name == "VIEJO-7" and Game.progress.has("geology") and String(Game.build.power) == "rtg" and Data.has(Game.build, "drill") and bool(Game.slots[0].used), "A ToMars 1.0 save is imported into file 1 with its rover and progress")
	Game.save_path = keep
	Game.lang = language
	Game.load_save()
	Game.volume = 0.0
	if "--es" in args: Game.lang = "es"
	check(Game.rover_name == "BOT-1", "The bot's own save is back after the import test")
	await frames(1)

# ------------------------------------------------------------------ casos límite
func edge_checks() -> void:
	print("== Edge cases")
	# Tutorial: saltar, y reanudar tras recargar
	Game.tutorial.erase("ops")
	Game.tutorial["ops_step"] = 2
	Game.mode = "campaign"
	Game.zone = "geology"
	Game.build = BUILDS.geology.duplicate(true)
	Game.flight = {"charge": 1.0, "damage": 0.0, "near": 0.0, "delay": 0.0}
	Game.go("ops")
	var ops := await screen("ops")
	ops.begin()
	await frames(5)
	check(ops.coach_step == 2, "The Mars tutorial resumes at the saved step")
	ops.end_coach()
	ops.end_coach()
	check(ops.coach_step == -1 and bool(Game.tutorial.get("ops", false)), "Skipping the tutorial records it once and leaves the mission playable")
	# Sin enlace
	ops.packets.append({"label": "test", "mb": 5.0, "science": 1.0, "sent": 0.0, "kind": "mastcam"})
	ops.toggle_transmit()
	check(not ops.transmitting and ops.toasts.size() > 0, "No orbiter overhead: transmission is refused with an explanation")
	# Memoria llena
	var before: int = ops.mem_full_count
	check(not ops.store({"label": "big", "mb": 999.0, "science": 5.0, "kind": "mastcam"}) and ops.mem_full_count == before + 1 and ops.unrecorded_mb >= 999.0, "Memory full: the product is not recorded and is counted as unrecorded data")
	# Panel de datos y borrado
	ops.show_data()
	await frames(3)
	await shot("32-data-panel")
	ops.delete_packet(0)
	check(ops.packets.is_empty(), "Stored data can be reviewed and deleted to free memory")
	ops.close_dialog()
	# Energía baja -> modo seguro, y recuperación
	ops.clock = 95.0   # de noche: los paneles no generan
	ops.energy = 1.0
	for i in range(900):
		if ops.safe_mode: break
		await get_tree().process_frame
	check(ops.safe_mode and ops.safe_count == 1, "An empty battery puts the rover in safe mode")
	await shot("33-safe-mode")
	ops.energy = float(ops.stats.battery) * 0.5
	await frames(5)
	check(not ops.safe_mode, "The rover recovers when power returns")
	# Ayuda y pausa
	ops.show_pause()
	await frames(3)
	await shot("34-pause")
	ops.show_help()
	await frames(3)
	await shot("35-controls")
	check(ops.mode == "paused", "Controls are available from the pause menu")
	ops.close_dialog()
	# Clics rápidos y transiciones repetidas
	Game.go("hub")
	Game.go("menu")
	Game.go("library")
	var landed := await screen("hub")
	check(is_instance_valid(landed) and main.current_name == "hub", "Rapid screen changes resolve to one screen without errors")
	# Saltar cinemáticas
	Game.go("transit")
	var transit := await screen("transit")
	transit.start_countdown()
	await frames(5)
	transit.skip()
	await frames(5)
	check(transit.phase == "cruise", "Skipping the launch goes to the cruise")
	transit.skip()
	for i in range(200):
		if transit.phase == "event": break
		await get_tree().process_frame
	check(transit.phase == "event", "Skipping the cruise still stops at the decision events")
	transit.comm_answer("wait")
	transit.comm_restored()
	transit.resume_cruise()
	transit.skip()
	for i in range(200):
		if transit.phase == "event": break
		await get_tree().process_frame
	transit.energy_answer("keep", Data.stats(Game.build))
	transit.resume_cruise()
	transit.skip()
	await frames(5)
	check(transit.phase == "edl", "After both events, skip reaches the landing")
	transit.skip()
	transit.skip()
	await frames(5)
	check(transit.phase == "landed" and float(Game.flight.charge) == 0.8, "Skipping the landing reaches the landed state once, with the chosen battery (80%)")
	# Movimiento reducido
	Game.reduced_motion = true
	Game.go("transit")
	transit = await screen("transit")
	transit.start_countdown()
	for i in range(240):
		if transit.phase == "event": break
		await get_tree().process_frame
	check(transit.phase == "event", "Reduced motion shortens the cinematics without skipping decisions")
	Game.reduced_motion = false
	Game.go("hub")
	await screen("hub")

# ------------------------------------------------------------------ recomendaciones
func adaptive_checks() -> void:
	print("== Adaptive recommendations")
	var kept: Array = Game.history.duplicate(true)
	Game.history = [{"zone": "geology", "grade": "C", "flags": {"safe": 2, "mem_full": 0, "left": 1, "damage": 0, "blocked": 0, "timeout": 0, "overbuilt": 0}}, {"zone": "geology", "grade": "B", "flags": {"safe": 1, "mem_full": 0, "left": 0, "damage": 0, "blocked": 0, "timeout": 0, "overbuilt": 0}}]
	var advice := Data.recommendations(Game.history)
	var issues: Array = advice.map(func(item: Dictionary) -> String: return String(item.issue[0]))
	check("Energy" in issues and "Communications" in issues and not "Data storage" in issues, "Recommendations follow the saved problems: " + str(issues))
	check(String(advice[0].why[0]).contains("2 of your last 2"), "A recommendation says how often the problem happened")
	var build_before: int = Game.build.hash()
	Game.go("progress")
	await screen("progress")
	await seconds(0.5)
	await shot("42-progress")
	check(Game.build.hash() == build_before, "Recommendations never change the rover")
	Game.history = kept
	Game.save()

# ------------------------------------------------------------------ Sandbox
func sandbox_checks() -> void:
	print("== Sandbox")
	var campaign := {"build": Game.build.hash(), "history": Game.history.size(), "progress": str(Game.progress), "rovers": Game.saved_rovers.size()}
	Game.go("menu")
	var menu := await screen("menu")
	check(press(menu, ["Sandbox"]), "Sandbox opens from the menu")
	var design := await screen("design")
	await seconds(0.6)
	await shot("43-sandbox-intro")
	check(design.sandbox and Game.mode == "sandbox", "The workshop runs in Sandbox mode")
	UIK.close_modal(design)
	Game.sandbox.mass_cap = 800
	Game.sandbox.budget_cap = 6000
	design.install("rtg")
	design.install("deck_ext")
	design.install("moxie")
	design.install("rimfax")
	design.install("navsens")
	design.install("chassis_reinf")
	design.install("battery_ext")
	design.install("rocker")
	await frames(3)
	check(Data.count_level(Data.check(design.build, Game.zone, Game.active_plan()), "blocker") == 0 and Data.mass(design.build) > 460, "Sandbox limits are adjustable: a %d kg rover is allowed (campaign limit 460 kg)" % Data.mass(design.build))
	design.open_sandbox_limits()
	await frames(3)
	await shot("44-sandbox-limits")
	UIK.close_modal(design)
	design.save_design()
	design.open_readiness()
	await frames(3)
	check(press(design, [t("TEST DRIVE", "PROBAR EN MARTE")]), "Sandbox offers a test drive")
	var ops := await screen("ops")
	ops.begin()
	await frames(5)
	check(ops.coach_step == -1, "Sandbox test drives have no campaign tutorial")
	events = {}
	await play_ops(ops, {"limit": 60.0})
	var debrief := await screen("debrief")
	check(bool(Game.report.sandbox), "Sandbox missions are labelled in the debrief")
	check(Game.history.size() == int(campaign.history) and str(Game.progress) == String(campaign.progress) and Game.build.hash() == int(campaign.build) and Game.saved_rovers.size() == int(campaign.rovers), "Sandbox does not touch campaign rover, hangar, progress or history")
	check(Game.achievements.has("sandbox"), "The Sandbox test drive is recorded")
	press(debrief, [t("Back to Sandbox", "Volver a Sandbox")])
	design = await screen("design")
	design.reset_build()
	check(design.build.hash() == Data.default_build().hash() and Game.build.hash() == int(campaign.build), "Sandbox reset rebuilds the reference rover only in Sandbox")
	Game.save()
	Game.load_save()
	check(Game.sandbox.build.hash() == Data.default_build().hash() and int(Game.sandbox.mass_cap) == 800, "Sandbox has its own saved state")
	Game.volume = 0.0
	if "--es" in args: Game.lang = "es"
	Game.mode = "campaign"

# ------------------------------------------------------------------ cooperativo
func coop_checks() -> void:
	print("== Local co-op")
	Game.mode = "campaign"
	Game.coop = true
	Game.zone = "geology"
	Game.build = BUILDS.geology.duplicate(true)
	Game.go("hub")
	var hub := await screen("hub")
	hub.explain_coop()
	await frames(3)
	await shot("45-coop-roles")
	UIK.close_modal(hub)
	Game.go("plan")
	var plan := await screen("plan")
	plan.choose("site", "flat")
	plan.confirm()
	await frames(3)
	await shot("46-coop-plan-gate")
	check(not plan.gate.is_empty() and main.current_name == "plan", "Co-op activity 1: the plan waits for both players")
	await key(KEY_ENTER)
	check(bool(plan.gate.get("p1", false)) and main.current_name == "plan", "The Commander's confirmation alone is not enough")
	await key(KEY_F)
	var design := await screen("design")
	check(main.current_name == "design", "Both confirmations continue to the workshop")
	design.end_coach()
	design.open_readiness()
	await frames(3)
	press(design, [t("GO FOR LAUNCH", "LISTOS PARA LANZAR")])
	await frames(3)
	check(not design.gate.is_empty(), "Co-op activity 2: the design review waits for both players")
	await key(KEY_F)
	await key(KEY_ENTER)
	await screen("transit")
	Game.flight = {"charge": 1.0, "damage": 0.0, "near": 0.0, "delay": 0.0}
	Game.go("ops")
	var ops := await screen("ops")
	await shot("47-coop-ops-brief")
	ops.begin()
	await frames(3)
	check(ops.coach_step == -1, "Co-op starts without the single-player tutorial")
	Input.action_press("move_right")
	await seconds(1.0)
	var still: float = ops.driven
	Input.action_release("move_right")
	Input.action_press("p1_right")
	await seconds(1.0)
	Input.action_release("p1_right")
	check(still < 1.0 and ops.driven > 20.0, "In co-op only the Commander's arrow keys drive the rover")
	events = {}
	await play_ops(ops, {})
	await screen("debrief")
	check(bool(Game.report.coop) and int(Game.report.done) == int(Game.report.required), "Co-op activity 3: exploration and the shared decision to end the mission")
	check(Game.achievements.has("coop"), "A completed co-op mission is recorded")
	Game.coop = false

# ------------------------------------------------------------------ idioma
func language_checks() -> void:
	print("== Language switching")
	var original := Game.lang
	for lang in ["es", "en"]:
		Game.lang = lang
		for name in ["menu", "hub", "zones", "plan", "design", "progress", "library", "achievements"]:
			Game.mode = "campaign"
			Game.go(name)
			var node := await screen(name)
			if name == "design": node.open_readiness()
			if name == "hub" and lang == "es":
				await seconds(0.8)
				await shot("48-hub-es")
			if name == "design" and lang == "es":
				await frames(3)
				await shot("49-readiness-es")
	var item: Dictionary = Data.check(Data.default_build(), "frontier", Game.default_plan())[0]
	Game.lang = "es"
	var spanish := Data.check_text(item)
	Game.lang = "en"
	check(spanish != Data.check_text(item), "New texts change with the language")
	Game.lang = original

# ------------------------------------------------------------------ otras pantallas
func menu_screens() -> void:
	print("== Other screens")
	Game.go("achievements")
	var achievements := await screen("achievements")
	await seconds(0.5)
	await shot("50-achievements")
	check(Game.achievements.size() >= 5 and Game.achievements.size() < Data.ACHIEVEMENT_ORDER.size(), "Achievement count is real progress (%d of %d)" % [Game.achievements.size(), Data.ACHIEVEMENT_ORDER.size()])
	achievements.pick("historian")
	await frames(3)
	Game.library_return = "menu"
	Game.go("library")
	var library := await screen("library")
	for tab in ["catalog", "samples", "rover", "trace", "stories", "sources"]:
		library.open(tab)
		await frames(3)
		if tab in ["catalog", "trace", "sources"]: await shot("51-library-" + tab)
	check(library.content.get_child_count() > 3, "Library tabs render their content")
	Game.go("menu")
	var menu := await screen("menu")
	menu.open_settings()
	await frames(5)
	await shot("52-settings")
	check(press(menu, [t("Done", "Listo")]), "Settings can be closed")
	await screen("menu")
	Game.go("profiles")
	await screen("profiles")
	await seconds(0.5)
	await shot("53-files-returning")


## Capturas de tres pantallas al tamaño real de la ventana. Uso:
##   godot --resolution 1024x768 res://tests/Bot.tscn -- --tour --shots=carpeta
func tour() -> void:
	if shots_dir == "": return
	RenderingServer.render_loop_enabled = true
	await seconds(1.0)
	Game.setup_done = true
	Game.start_slot(0, true)
	var size := DisplayServer.window_get_size()
	for name in ["menu", "hub", "design", "zones"]:
		Game.go(name)
		await screen(name)
		if name == "design" and main.current.has_method("end_coach"): main.current.end_coach()
		await seconds(0.8)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/60-%s-%dx%d.png" % [shots_dir, name, size.x, size.y])
	Game.go("menu")
	var menu := await screen("menu")
	menu.open_settings()
	await seconds(0.8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/60-settings-%dx%d.png" % [shots_dir, size.x, size.y])
