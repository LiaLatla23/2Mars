extends Node
## Bot de humo: recorre todas las pantallas y completa las cuatro zonas.
## Uso: godot --headless res://tests/Bot.tscn -- [--shots=DIR] [--es]

var shots := ""
var failures: Array[String] = []
var checks := 0
var main: Control

const BUILDS := {
	"geology": {"power": "solar", "battery": "small", "wheels": "standard", "comms": "uhf", "computer": "expanded", "instruments": ["mastcam", "supercam", "arm", "pixl"]},
	"life": {"power": "solar", "battery": "large", "wheels": "standard", "comms": "uhf", "computer": "expanded", "instruments": ["mastcam", "supercam", "arm", "sherloc"]},
	"archive": {"power": "solar", "battery": "large", "wheels": "rugged", "comms": "hga", "computer": "standard", "instruments": ["mastcam", "arm"]},
	"frontier": {"power": "rtg", "battery": "small", "wheels": "standard", "comms": "uhf", "computer": "standard", "instruments": ["meda", "moxie", "rimfax", "supercam"]}
}

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures.append(text)
		print("FAIL: ", text)

func frames(count: int = 2) -> void:
	for i in range(count): await get_tree().process_frame

func shot(file_name: String) -> void:
	if shots == "": return
	await frames(2)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots.path_join(Game.lang + "-" + file_name + ".png"))

func screen(expected: String) -> Control:
	for i in range(120):
		if main.current_name == expected and not main.busy: break
		await frames(1)
	check(main.current_name == expected, "Reaches screen " + expected + " (now " + main.current_name + ")")
	await frames(20)
	return main.current

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="): shots = arg.trim_prefix("--shots=")
	Game.save_enabled = false
	Game.progress = {}
	Game.lang = "es" if "--es" in OS.get_cmdline_user_args() else "en"
	Game.build = Data.default_build()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await screen("menu")
	if "--honest" in OS.get_cmdline_user_args():
		for zone in Data.ZONE_ORDER:
			if "--only-frontier" in OS.get_cmdline_user_args() and zone != "frontier": continue
			await honest(zone)
		print("BOT SUMMARY: %d checks; %d failures" % [checks, failures.size()])
		get_tree().quit(1 if not failures.is_empty() else 0)
		return
	await shot("01-menu")
	Game.go("library")
	var library := await screen("library")
	await shot("02-library")
	for tab in ["samples", "rover", "sources"]:
		library.open(tab)
		await frames(3)
	await shot("02-library-sources")
	for zone in Data.ZONE_ORDER:
		await play(zone)
	Game.go("zones")
	await screen("zones")
	await shot("09-map-complete")
	print("BOT SUMMARY: %d checks; %d failures" % [checks, failures.size()])
	for failure in failures: print("FAIL: ", failure)
	get_tree().quit(1 if not failures.is_empty() else 0)

func play(zone: String) -> void:
	Game.go("zones")
	var map := await screen("zones")
	map.pick(zone)
	await frames(4)
	check(Game.zone_unlocked(zone), zone + " is unlocked in order")
	if zone in ["geology", "life"]: await shot("03-map-" + zone)
	map.open_design()
	var design := await screen("design")
	if zone == "geology": await shot("04-design-default")
	design.build = BUILDS[zone].duplicate(true)
	design.refresh()
	await frames(4)
	check(Data.mass(design.build) <= Data.MASS_CAP and Data.cost(design.build) <= Data.BUDGET, zone + " reference build fits mass and budget (%d kg, %d cr)" % [Data.mass(design.build), Data.cost(design.build)])
	await shot("04-design-" + zone)
	design.launch_mission()
	var ops := await screen("ops")
	await shot("05-brief-" + zone)
	ops.close_dialog()
	await frames(30)
	await shot("06-ops-start-" + zone)
	var first := true
	for target in ops.targets:
		ops.pos = target.pos + Vector2(-(float(target.r) + 40.0), 0)
		await frames(3)
		if first:
			ops.show_actions(target)
			await shot("06-ops-actions-" + zone)
			if zone == "geology":
				# Atajo de teclado: 1 elige el primer instrumento.
				var key := InputEventKey.new()
				key.physical_keycode = KEY_1
				key.pressed = true
				ops._unhandled_input(key)
				check(ops.mode == "minigame" and String(ops.game.id) == "mastcam", "Number key picks an instrument from the action menu")
				ops.end_minigame(0.9)
				await resolve_dialogs(ops, false, "")
			else: ops.close_dialog()
		for id in ["mastcam", "supercam", "pixl", "sherloc", "arm"]:
			if not id in ops.has: continue
			if id == "arm" and (ops.tubes <= 0 or zone != "archive"): continue
			await send_all(ops)
			if ops.energy < 30.0: ops.energy = float(ops.stats.battery)
			ops.run_instrument(id, target)
			await frames(12)
			if first: await shot("06-ops-minigame-%s-%s" % [id, zone])
			ops.end_minigame(0.9)
			await frames(3)
			await resolve_dialogs(ops, first, zone + "-" + id)
		first = false
	if "rimfax" in ops.has:
		for site in ops.sites:
			ops.pos = site.pos
			await frames(3)
			ops.start_radar()
			await frames(6)
			ops.end_minigame(1.0)
			await resolve_dialogs(ops, true, zone + "-rimfax")
	if "moxie" in ops.has:
		ops.energy = float(ops.stats.battery)
		ops.start_moxie()
		for i in range(1200):
			if ops.moxie_runs > 0: break
			await frames(1)
		await resolve_dialogs(ops, true, zone + "-moxie")
	if "meda" in ops.has:
		ops.toggle_meda()
		for i in range(6000):
			if ops.meda_packets >= 4: break
			if ops.mode == "card": await resolve_dialogs(ops, true, zone + "-meda")
			if ops.memory_used() > float(ops.stats.memory) - 8.0: await send_all(ops)
			ops.energy = maxf(ops.energy, 40.0)
			await frames(1)
	await send_all(ops)
	if zone == "life":
		ops.pos = ops.targets[0].pos + Vector2(-190, 60)
		ops.heading = -0.3
		ops.tracks.clear()
		for i in range(12): ops.tracks.append(ops.pos + Vector2(-26.0 * (12 - i), 8.0 * (12 - i)))
		await frames(20)
	await shot("07-ops-end-" + zone)
	var goals: Array = ops.objective_state()
	for goal in goals: check(goal.done, "%s objective: %s (%d/%d)" % [zone, goal.text, int(goal.value), int(goal.need)])
	if zone == "geology":
		ops.clock = 96.0
		await frames(40)
		await shot("07-ops-night")
	if zone == "archive":
		ops.clock = ops.storm_start + 5.0
		await frames(30)
		await shot("07-ops-storm")
	ops.finish("player")
	await screen("debrief")
	await shot("08-debrief-" + zone)
	check(String(Game.report.grade) in ["S", "A"], "%s ends with grade S/A (got %s, score %.0f)" % [zone, Game.report.grade, float(Game.report.score)])

func resolve_dialogs(ops: Control, capture: bool, label: String) -> void:
	for step in range(6):
		await frames(3)
		if ops.mode != "card": return
		var options: Array = []
		for button in ops.dialog.find_children("*", "Button", true, false): options.append(button)
		if options.size() >= 3:
			if capture: await shot("06-ops-quiz-" + label)
			var quiz_id := ""
			for id in Data.QUIZ:
				if ops.quiz_done.has(id) and options[0].text.ends_with(Game.tt(Data.QUIZ[id].options[0])): quiz_id = id
			check(quiz_id != "", "Quiz dialog matches a known question")
			options[int(Data.QUIZ[quiz_id].correct) if quiz_id != "" else 0].pressed.emit()
		else:
			if capture: await shot("06-ops-card-" + label)
			ops.close_dialog()

func send_all(ops: Control) -> void:
	## Espera un paso de orbitador (acelerando el reloj) y transmite todo.
	if ops.packets.is_empty(): return
	for i in range(4000):
		if ops.packets.is_empty(): break
		if ops.mode == "card": await resolve_dialogs(ops, false, "")
		if ops.link_rate() <= 0.0: ops.clock += 0.5
		elif not ops.transmitting:
			ops.vel = Vector2.ZERO
			ops.toggle_transmit()
		ops.energy = maxf(ops.energy, 30.0)
		await frames(1)
	check(ops.packets.is_empty(), "All packets can be transmitted")


# ---------------------------------------------------------------- juego real
## Juega con las reglas reales: teclas, energía, noche, pasos de orbitador y límite de tiempo.
func release() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "interact"]: Input.action_release(action)

func drive_to(ops: Control, goal: Vector2, arrive: float) -> bool:
	var stuck := 0.0
	var last: Vector2 = ops.pos
	var dodge := 0.0
	var side := 1.0
	for i in range(3600):
		if ops.mode == "ended" or main.current != ops: return false
		if ops.mode == "card": await resolve_dialogs(ops, false, "")
		if ops.pos.distance_to(goal) <= arrive:
			release()
			return true
		if ops.safe_mode or ops.energy < 12.0:
			release()
			await frames(30)
			continue
		var way: Vector2 = (goal - ops.pos).normalized()
		if dodge > 0.0:
			way = (way + way.orthogonal() * side * 1.6).normalized()
			dodge -= 1.0 / 60.0
		for pair in [["move_right", way.x > 0.35], ["move_left", way.x < -0.35], ["move_down", way.y > 0.35], ["move_up", way.y < -0.35]]:
			if pair[1]: Input.action_press(pair[0])
			else: Input.action_release(pair[0])
		await frames(1)
		if i % 30 == 29:
			if ops.pos.distance_to(last) < 14.0:
				dodge = 0.9
				side = -side
			last = ops.pos
	release()
	return false

func honest_minigame(ops: Control) -> void:
	for i in range(1200):
		if ops.mode != "minigame": break
		var game: Dictionary = ops.game
		match String(game.mode):
			"focus", "timing":
				if absf(float(game.value) - 0.5) < 0.07:
					Input.action_press("interact")
					var event := InputEventAction.new()
					ops.press_minigame()
					Input.action_release("interact")
					await frames(8)
			"steady":
				if float(game.value) < float(game.band): Input.action_press("interact")
				else: Input.action_release("interact")
		await frames(1)
	release()

func honest_send(ops: Control) -> void:
	if ops.packets.is_empty(): return
	release()
	for i in range(5400):
		if ops.packets.is_empty() or ops.mode == "ended" or main.current != ops: return
		if ops.mode == "card": await resolve_dialogs(ops, false, "")
		if ops.link_rate() > 0.0 and not ops.transmitting and ops.vel.length() < 10.0: ops.toggle_transmit()
		await frames(1)

func honest(zone: String) -> void:
	Game.zone = zone
	Game.build = BUILDS[zone].duplicate(true)
	Game.go("ops")
	var ops := await screen("ops")
	ops.close_dialog()
	if "meda" in ops.has: ops.toggle_meda()
	var order: Array = ops.targets.duplicate()
	if zone == "frontier":
		# Un jugador atento empieza por lo que más energía pide, con la batería llena.
		order = []
		ops.start_moxie()
		for wait in range(1200):
			if ops.moxie_runs > 0: break
			await frames(1)
		await resolve_dialogs(ops, false, "")
	for round in range(order.size()):
		if ops.mode == "ended" or main.current != ops or ops.all_objectives_done(): break
		order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return ops.pos.distance_to(a.pos) < ops.pos.distance_to(b.pos))
		var target: Dictionary = order.pop_front()
		for id in ["mastcam", "supercam", "pixl", "sherloc", "arm"]:
			if not id in ops.has or (id == "arm" and (zone != "archive" or ops.tubes <= 0)): continue
			if ops.mode == "ended" or main.current != ops or ops.all_objectives_done(): break
			var info: Dictionary = Data.INSTRUMENTS[id]
			if ops.memory_used() + float(info.mb) > float(ops.stats.memory): await honest_send(ops)
			if not await drive_to(ops, target.pos, float(target.r) + float(info.range) - 12.0): break
			for wait in range(1800):
				if ops.energy >= float(info.energy) + 8.0 and not ops.safe_mode: break
				await frames(1)
			if ops.mode != "drive": continue
			ops.run_instrument(id, target)
			await honest_minigame(ops)
			await resolve_dialogs(ops, false, "")
		if ops.pass_open(): await honest_send(ops)
	if main.current == ops and ops.mode != "ended":
		for site in ops.sites:
			if "rimfax" in ops.has and await drive_to(ops, site.pos, 40.0):
				ops.start_radar()
				await honest_minigame(ops)
				await resolve_dialogs(ops, false, "")
		if "moxie" in ops.has and ops.moxie_runs == 0:
			for wait in range(2400):
				if ops.energy >= 50.0: break
				await frames(1)
			ops.start_moxie()
			for wait in range(1200):
				if ops.moxie_runs > 0 or ops.mode == "ended": break
				await frames(1)
			await resolve_dialogs(ops, false, "")
		for wait in range(9000):
			if ops.mode == "ended" or main.current != ops: break
			if ops.mode == "card": await resolve_dialogs(ops, false, "")
			if ops.all_objectives_done() and ops.packets.is_empty(): break
			if not ops.packets.is_empty() and ops.link_rate() > 0.0 and not ops.transmitting: ops.toggle_transmit()
			await frames(1)
	if main.current == ops and ops.mode != "ended":
		print("[HONEST] %s: objectives done at %.0f s of %d · energy %.0f · wheels %.0f%% · received %.0f MB" % [zone, ops.clock, int(ops.zone.time), ops.energy, ops.integrity, ops.received_mb])
		ops.finish("player")
	await screen("debrief")
	for goal in Game.report.goals:
		if not goal.done: print("[HONEST] %s missed: %s (%d/%d)" % [zone, goal.text, int(goal.value), int(goal.need)])
	print("[HONEST] %s: grade %s score %.0f · goals %d/%d · received %d MB · lost %d MB · reason %s" % [zone, Game.report.grade, float(Game.report.score), int(Game.report.done), Game.report.goals.size(), int(Game.report.received), int(Game.report.lost), Game.report.reason])
	check(String(Game.report.grade) in ["S", "A", "B"], "%s is beatable under real rules (grade %s)" % [zone, Game.report.grade])
