extends Node
## Auditoría automática de interfaz (V5). Recorre las pantallas y sus paneles en inglés y en
## español y busca, sobre el árbol real de controles:
##   · textos o botones fuera de la pantalla (1280x720 lógicos; el juego escala uniforme)
##   · textos cortados (más líneas de las que caben, o más anchos que su caja)
##   · textos o botones que se salen del panel que los contiene
##   · botones que se pisan entre sí
## Uso:  godot --headless --fixed-fps 60 --path . res://tests/Layout.tscn [-- --es] [--only=hub]
## No sustituye mirar la pantalla: detecta geometría, no si algo se lee bien.

const VIEW := Rect2(0, 0, 1280, 720)
const FULL := {"chassis": "chassis_reinf", "deck": "deck_ext", "wheels": "wheels_reinf", "power": "rtg", "computer": "cpu_adv", "arm": "arm_ext",
	"parts": ["uhf", "hga", "battery_ext", "storage", "mastcam", "supercam", "pixl", "sherloc", "drill", "rimfax", "meda", "moxie", "rocker", "navsens", "autonav", "regolith"]}

var main: Node
var issues: Array = []
var checked := 0
var only := ""

func arg(key: String, fallback: String = "") -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with("--" + key + "="): return item.split("=")[1]
	return fallback

func frames(n: int) -> void:
	for i in range(n): await get_tree().process_frame

func _ready() -> void:
	only = arg("only")
	Game.save_path = "user://2mars_layout_save.json"
	if FileAccess.file_exists(Game.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	Game.load_save()
	Game.setup_done = true
	Game.volume = 0.0
	Game.apply_volume()
	Game.reduced_motion = true      # sin animaciones de entrada: se mide la posición final
	var langs := ["es"] if "--es" in OS.get_cmdline_user_args() else (["en"] if "--en" in OS.get_cmdline_user_args() else ["en", "es"])
	main = load("res://scenes/Main.tscn").instantiate()
	main.start_screen = "menu"
	add_child(main)
	await frames(10)
	for lang in langs:
		Game.lang = lang
		await run(lang)
	print("LAYOUT SUMMARY: %d views checked; %d issues" % [checked, issues.size()])
	get_tree().quit(1 if issues.size() > 0 else 0)

func seed_state(long_names: bool) -> void:
	Game.start_slot(0, true)
	Game.player_name = "Maximiliana Fernández" if long_names else "Ada"
	Game.team_name = "SpaceNuts Exploration Team" if long_names else "SpaceNuts"
	Game.rover_name = "PERSEVERANCIA 2026" if long_names else "ARES 01"
	Game.mission_name = "Operación Jezero Occidental" if long_names else "Jezero One"
	Game.zone = "archive"
	Game.mode = "campaign"
	Game.coop = false
	Game.tutorial = {"ops": true, "workshop": true, "intro": true}
	Game.build = FULL.duplicate(true)
	Game.plan = Game.default_plan()
	Game.plan.profile = "flagship"
	Game.plan.launcher = "heavy"
	Game.progress = {"geology": {"grade": "A", "science": 130, "runs": 2}, "life": {"grade": "B", "science": 96, "runs": 1}, "archive": {"grade": "C", "science": 60, "runs": 1}}
	for id in Data.ACHIEVEMENT_ORDER.slice(0, 9): Game.achievements[id] = true
	Game.history = [{"zone": "geology", "grade": "B", "science": 80, "flags": {"safe": 1, "damage": 1}}, {"zone": "geology", "grade": "A", "science": 130, "flags": {"mem_full": 1, "left": 1}}]
	Game.upgrades = {"treads": true}
	Game.location = "earth"

func go(screen: String) -> Control:
	main.show_screen(screen, true)
	await frames(12)
	return main.current

func run(lang: String) -> void:
	for long_names in [false, true]:
		seed_state(long_names)
		var tag := "%s%s" % [lang, "+long" if long_names else ""]
		if wanted("menu"):
			var menu := await go("menu")
			await audit(tag, "menu")
			menu.open_settings()
			await audit(tag, "menu/settings")
			for method in ["open_coop", "open_credits", "ask_quit"]:
				UIK.close_modal(menu)
				menu.call(method)
				await audit(tag, "menu/" + method)
		if wanted("hub"):
			var hub := await go("hub")
			await audit(tag, "hub/earth")
			hub.open_menu()
			await audit(tag, "hub/earth/menu")
			UIK.close_modal(hub)
			hub.explain_coop()
			await audit(tag, "hub/earth/coop")
			Game.coop = false
			Game.location = "mars"
			hub = await go("hub")
			await audit(tag, "hub/mars")
			Game.location = "earth"
		if wanted("zones"):
			var zones := await go("zones")
			for id in Data.ZONE_ORDER:
				zones.pick(id)
				await audit(tag, "zones/" + id)
			for id in Data.SUB_ORDER:
				zones.pick_sub(id)
				await audit(tag, "zones/sub/" + id)
			zones.why_jezero()
			await audit(tag, "zones/why")
		if wanted("plan"):
			for coop in [false, true]:
				Game.coop = coop
				var plan := await go("plan")
				for step in plan.STEPS:
					plan.open_step(step)
					await audit(tag, "plan/%s%s" % [step, "/coop" if coop else ""])
				plan.choose("launcher", "light")
				plan.choose("trajectory", "fast")
				await audit(tag, "plan/over%s" % ("/coop" if coop else ""))
				plan.open_breakdown()
				await audit(tag, "plan/breakdown")
				for step in ["launcher", "window", "trajectory", "site"]:
					plan.learn_more(step)
					await audit(tag, "plan/learn/" + step)
				if coop:
					UIK.close_modal(plan)
					plan.confirm()
					await audit(tag, "plan/gate")
			Game.coop = false
		if wanted("design"):
			var design := await go("design")
			for category in Data.CATEGORIES:
				design.open_category(String(category.id))
				await audit(tag, "design/" + String(category.id))
			for id in ["moxie", "rtg", "chassis_reinf", "autonav"]:
				design.preview(id)
				await audit(tag, "design/preview/" + id)
			design.end_preview()
			for show in ["plan", "blocker", "risk", "limit", "tip"]:
				design.open_readiness(show)
				await audit(tag, "design/readiness/" + show)
			UIK.close_modal(design)
			design.open_menu()
			await audit(tag, "design/menu")
			for id in ["navsens", "moxie", "rtg", "arm_ext"]:
				design.open_part(id)
				await audit(tag, "design/part/" + id)
			UIK.close_modal(design)
			design.open_hangar()
			await audit(tag, "design/hangar")
			UIK.close_modal(design)
			# peor caso: diseño incompatible y pesado con el lanzador ligero
			Game.plan.launcher = "light"
			Game.plan.trajectory = "fast"
			Game.build.arm = ""
			design = await go("design")
			await audit(tag, "design/worst")
			for show in ["plan", "blocker", "risk"]:
				design.open_readiness(show)
				await audit(tag, "design/worst/readiness/" + show)
			seed_state(long_names)
		if wanted("transit"):
			var transit := await go("transit")
			await audit(tag, "transit/prep")
			transit.comm_event()
			await audit(tag, "transit/comm")
			transit.energy_event()
			await audit(tag, "transit/energy")
			transit.energy_answer("review", Data.stats(Game.build))
			await audit(tag, "transit/energy/review")
			UIK.close_modal(transit)
			transit.land()
			await audit(tag, "transit/landed")
		if wanted("progress"):
			var progress := await go("progress")
			for id in ["rocks", "tools", "zones", "stories"]:
				progress.open_category(id)
				await audit(tag, "progress/" + id)
			progress.open_more()
			await audit(tag, "progress/more")
			UIK.close_modal(progress)
			progress.open_log()
			await audit(tag, "progress/log")
		if wanted("upgrades"):
			var upgrades := await go("upgrades")
			for id in Data.UPGRADE_ORDER:
				upgrades.pick(id)
				await audit(tag, "upgrades/" + id)
		if wanted("achievements"):
			var achievements := await go("achievements")
			for id in ["first_launch", "historian", "all_zones"]:
				achievements.pick(id)
				await audit(tag, "achievements/" + id)
		if wanted("library"):
			var library := await go("library")
			for tab in ["instruments", "catalog", "rover", "samples", "stories", "trace", "sources", "glossary"]:
				library.open(tab)
				await audit(tag, "library/" + tab)
		if wanted("ops"):
			for zone in ["archive", "frontier"]:
				Game.zone = zone
				Game.flight = {"charge": 1.0, "damage": 2.0, "near": 0.0, "delay": 0.0}
				Game.last_issue = Data.check(Game.build, zone, Game.plan)
				var ops := await go("ops")
				await audit(tag, "ops/%s/brief" % zone)
				ops.begin()
				await frames(20)
				await audit(tag, "ops/%s/hud" % zone)
				for method in ["show_pause", "show_goals", "show_recovery", "show_help", "show_data", "abort"]:
					ops.call(method)
					await audit(tag, "ops/%s/%s" % [zone, method])
					ops.close_dialog()
				if not ops.targets.is_empty():
					for extra in [false, true]:
						ops.show_actions(ops.targets[0], extra)
						await audit(tag, "ops/%s/actions%s" % [zone, "/details" if extra else ""])
						ops.close_dialog()
				ops.transmitting = true
				await frames(4)
				await audit(tag, "ops/%s/link" % zone)
				ops.transmitting = false
				ops.finish("time")
				await frames(14)
				await audit(tag, "debrief/%s" % zone)
				if main.current.has_method("open_details"):
					main.current.open_details()
					await audit(tag, "debrief/%s/details" % zone)
		if wanted("ops"):
			Game.zone = "geology"
			Game.sub = "arcade"
			Game.flight = {"charge": 1.0, "damage": 2.0, "near": 0.0, "delay": 0.0}
			var arcade_ops := await go("ops")
			await audit(tag, "ops/arcade/brief")
			arcade_ops.finish("player")
			await frames(14)
			await audit(tag, "debrief/arcade")
			Game.sub = "main"
			Game.coop = true
			Game.coop_mode = "crew"
			Game.zone = "geology"
			Game.flight = {"charge": 1.0, "damage": 2.0, "near": 0.0, "delay": 0.0}
			var crew_ops := await go("ops")
			await audit(tag, "ops/crew/brief")
			crew_ops.begin()
			await frames(10)
			crew_ops.send_ping("danger")
			await audit(tag, "ops/crew/hud")
			Game.coop_mode = "expedition"
			var exp_ops := await go("ops")
			await audit(tag, "ops/expedition/brief")
			exp_ops.begin()
			await frames(10)
			await audit(tag, "ops/expedition/hud")
			Game.coop = false
			Game.coop_mode = "roles"
		if wanted("profiles"):
			await go("profiles")
			await audit(tag, "profiles")

func wanted(name: String) -> bool:
	return only == "" or only == name

func modal_root() -> Node:
	var found: Node = null
	for child in main.current.get_children():
		if child.is_in_group("modal") and not child.is_queued_for_deletion(): found = child
	return found

func audit(tag: String, view: String) -> void:
	await frames(8)
	checked += 1
	var root: Node = modal_root()
	if root == null: root = main.current
	var buttons: Array = []
	var seen := {}
	for node in root.find_children("*", "Control", true, false):
		var c := node as Control
		if not c.is_visible_in_tree() or c.is_queued_for_deletion(): continue
		if not (c is Label or c is Button or c is LineEdit or c is ProgressBar): continue
		if root == main.current and under_modal(c): continue
		var rect := c.get_global_rect()
		if rect.size.x < 1.0 or rect.size.y < 1.0: continue
		var what := describe(c)
		var scroll := scroll_parent(c)
		# 1 · fuera de pantalla (dentro de una lista con desplazamiento solo cuenta el eje horizontal)
		if scroll == null:
			if not VIEW.grow(2.0).encloses(rect): report(seen, tag, view, "OFFSCREEN", what, rect)
		elif rect.position.x < scroll.get_global_rect().position.x - 2.0 or rect.end.x > scroll.get_global_rect().end.x + 2.0:
			report(seen, tag, view, "WIDER THAN LIST", what, rect)
		# 2 · texto cortado
		if c is Label:
			var label := c as Label
			if label.text.strip_edges() != "":
				if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
					var lines := label.get_line_count()
					var fits := label.get_visible_line_count()
					if label.max_lines_visible >= 0: fits = mini(fits, label.max_lines_visible)
					if lines > fits and label.tooltip_text == "": report(seen, tag, view, "TEXT CUT (%d of %d lines)" % [fits, lines], what, rect)
					if clip_parent_cuts(label): report(seen, tag, view, "TEXT CUT BY BOX", what, rect)
				elif label.get_minimum_size().x > label.size.x + 1.5 and (label.clip_text or label.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
					if label.tooltip_text == "": report(seen, tag, view, "TEXT CUT (needs %d px, has %d)" % [int(label.get_minimum_size().x), int(label.size.x)], what, rect)
		elif c is Button:
			var button := c as Button
			if button.text != "" and button.get_minimum_size().x > button.size.x + 1.5 and button.autowrap_mode == TextServer.AUTOWRAP_OFF:
				report(seen, tag, view, "BUTTON TEXT CUT (needs %d px, has %d)" % [int(button.get_minimum_size().x), int(button.size.x)], what, rect)
			if button.autowrap_mode != TextServer.AUTOWRAP_OFF and button.get_minimum_size().y > button.size.y + 1.5:
				report(seen, tag, view, "BUTTON TEXT TALLER THAN BUTTON", what, rect)
			if not button.disabled or button.text != "": buttons.append(button)
		# 3 · se sale del panel que lo contiene
		var box := box_parent(c)
		if box != null and scroll == null:
			var outer := box.get_global_rect().grow(3.0)
			if not outer.encloses(rect): report(seen, tag, view, "OUTSIDE ITS PANEL (%s)" % describe(box), what, rect)
	# 5 · textos que se pisan entre sí o con un botón ajeno
	var texts: Array = []
	for node in root.find_children("*", "Label", true, false):
		var l := node as Label
		if l.is_visible_in_tree() and not l.is_queued_for_deletion() and l.text.strip_edges() != "" and not (root == main.current and under_modal(l)): texts.append(l)
	for i in range(texts.size()):
		var a: Label = texts[i]
		var ra := ink_rect(a)
		for j in range(i + 1, texts.size()):
			var b: Label = texts[j]
			if scroll_parent(a) != scroll_parent(b): continue
			var cut := ra.intersection(ink_rect(b))
			if cut.size.x > 8.0 and cut.size.y > 6.0: report(seen, tag, view, "TEXTS OVERLAP", "%s  ×  %s" % [describe(a), describe(b)], cut)
		for button in buttons:
			var b2: Button = button
			if b2.is_ancestor_of(a) or scroll_parent(a) != scroll_parent(b2) or box_parent(a) == b2: continue
			var cut2 := ra.intersection(b2.get_global_rect())
			if cut2.size.x > 8.0 and cut2.size.y > 6.0: report(seen, tag, view, "TEXT UNDER/OVER A BUTTON", "%s  ×  %s" % [describe(a), describe(b2)], cut2)
	# 4 · botones que se pisan
	for i in range(buttons.size()):
		for j in range(i + 1, buttons.size()):
			var a: Button = buttons[i]
			var b: Button = buttons[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a): continue
			if scroll_parent(a) != scroll_parent(b): continue
			var cut := a.get_global_rect().intersection(b.get_global_rect())
			if cut.size.x > 6.0 and cut.size.y > 6.0: report(seen, tag, view, "BUTTONS OVERLAP", "%s  ×  %s" % [describe(a), describe(b)], cut)

## Rectángulo que ocupa de verdad el texto de una etiqueta (una etiqueta ancha con poco texto no cuenta entera).
func ink_rect(label: Label) -> Rect2:
	var rect := label.get_global_rect()
	if label.autowrap_mode != TextServer.AUTOWRAP_OFF: return rect.grow(-1.0)
	var width := minf(rect.size.x, label.get_minimum_size().x)
	var x := rect.position.x
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER: x += (rect.size.x - width) * 0.5
	elif label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT: x += rect.size.x - width
	return Rect2(x, rect.position.y, width, rect.size.y).grow(-1.0)

func under_modal(c: Control) -> bool:
	var node: Node = c
	while node != null and node != main.current:
		if node.is_in_group("modal"): return true
		node = node.get_parent()
	return false

func scroll_parent(c: Control) -> ScrollContainer:
	var node: Node = c.get_parent()
	while node != null and node != main.current:
		if node is ScrollContainer: return node
		node = node.get_parent()
	return null

func box_parent(c: Control) -> Control:
	var node: Node = c.get_parent()
	while node != null and node != main.current:
		if node is Panel or node is PanelContainer or (node is Button and c is Label): return node
		node = node.get_parent()
	return null

## Una caja con recorte (UIK.note) que deja fuera parte del texto.
func clip_parent_cuts(label: Label) -> bool:
	var node: Node = label.get_parent()
	while node != null and node != main.current:
		if node is Control and (node as Control).clip_contents and not (node is ScrollContainer):
			if label.tooltip_text != "": return false
			return label.get_global_rect().end.y > (node as Control).get_global_rect().end.y + 2.0
		node = node.get_parent()
	return false

func describe(c: Control) -> String:
	var text := ""
	if c is Label: text = (c as Label).text
	elif c is Button: text = (c as Button).text
	text = text.replace("\n", " / ").strip_edges()
	if text.length() > 46: text = text.left(46) + "…"
	return "%s «%s»" % [c.get_class(), text]

func report(seen: Dictionary, tag: String, view: String, kind: String, what: String, rect: Rect2) -> void:
	var key := "%s|%s" % [kind, what]
	if seen.has(key): return
	seen[key] = true
	issues.append(key)
	print("LAYOUT [%s] %s · %s · %s · at (%d,%d) %dx%d" % [tag, view, kind, what, int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y)])
