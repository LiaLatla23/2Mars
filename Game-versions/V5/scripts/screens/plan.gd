extends BaseScreen
## Planificación de misión (V5). Seis decisiones conectadas, de una en una:
## lanzador, ventana, trayectoria, clase de misión, sitio de aterrizaje y prioridad científica.
## A la izquierda los pasos con lo elegido; en el centro las opciones del paso; a la derecha
## lo que el plan significa para el rover (masa de lanzamiento, créditos, tiempos) y la revisión.
## Lo esencial está a la vista; los hechos reales y el desglose se abren con «Conocer más».

const STEPS := ["launcher", "window", "trajectory", "profile", "site", "priority"]

var plan: Dictionary
var step := "launcher"
var owen_label: Label
var summary: Panel
var options: Panel
var steps_box: VBoxContainer
var step_buttons := {}
var cells := {}

func _ready() -> void:
	backdrop = "workshop"
	backdrop_dim = 0.45
	plan = Data.clean_plan((Game.plan_draft if not Game.plan_draft.is_empty() else Game.plan).duplicate(true))
	Game.plan_draft = {}
	if not plan.has("launcher"): plan["launcher"] = Data.launcher_id(plan)
	if not plan.has("trajectory"): plan["trajectory"] = "balanced"
	var zone: Dictionary = Data.ZONES[Game.zone]
	var head := title(Game.t("MISSION PLANNING", "PLANIFICACIÓN DE MISIÓN"), Vector2(30, 14), 36)
	var where := UIK.chip(self, "  %s · %s  " % [Game.tt(zone.goal).to_upper(), Game.tt(zone.name)], Color(String(zone.color)))
	where.position = Vector2(34 + head.get_minimum_size().x + 10, 28)
	back_button(Game.t("← Missions", "← Misiones"), "zones", Vector2(1100, 18))
	coop_banner(Vector2(30, 66), Game.t("decides the plan", "decide el plan"), Game.t("checks mass and science", "revisa masa y ciencia"))
	var left := UIK.panel(self, Rect2(24, 100, 250, 606))
	steps_box = UIK.column(left, Rect2(12, 12, 226, 582), 8)
	for i in range(STEPS.size()):
		var id: String = STEPS[i]
		var b := UIK.button(steps_box, "", func() -> void: open_step(id), "ghost", Vector2(226, 86))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 15)
		step_buttons[id] = b
	options = UIK.panel(self, Rect2(286, 100, 560, 606))
	summary = UIK.panel(self, Rect2(858, 100, 398, 384), Color(UIK.INK, 0.92))
	var owen := owen_panel(self, Rect2(858, 494, 398, 142), Game.t("Six choices, and each one moves the others. Start with the launcher.", "Seis decisiones, y cada una mueve a las demás. Empieza por el lanzador."), "", 64.0)
	owen_label = owen.label
	owen_label.add_theme_font_size_override("font_size", 14)
	owen_label.max_lines_visible = 4
	var go := UIK.button(self, Game.t("CONFIRM PLAN → WORKSHOP", "CONFIRMAR PLAN → TALLER"), confirm, "go", Vector2(398, 56))
	go.position = Vector2(858, 648)
	open_step(step)

func table(key: String) -> Dictionary:
	return {"launcher": Data.LAUNCHERS, "window": Data.WINDOWS, "trajectory": Data.TRAJECTORIES, "profile": Data.PROFILES, "site": Data.SITES, "priority": Data.PRIORITIES}[key]

func order(key: String) -> Array:
	return {"launcher": Data.LAUNCHER_ORDER, "window": Data.WINDOW_ORDER, "trajectory": Data.TRAJECTORY_ORDER, "profile": Data.PROFILE_ORDER, "site": Data.SITE_ORDER, "priority": Data.PRIORITY_ORDER}[key]

func step_name(key: String) -> String:
	return {"launcher": Game.t("Launcher", "Lanzador"), "window": Game.t("Launch window", "Ventana"), "trajectory": Game.t("Trajectory", "Trayectoria"),
		"profile": Game.t("Mission class", "Clase de misión"), "site": Game.t("Landing site", "Aterrizaje"), "priority": Game.t("Science priority", "Prioridad")}[key]

func step_help(key: String) -> String:
	return {"launcher": Game.t("How much mass leaves Earth, and what it costs.", "Cuánta masa sale de la Tierra, y cuánto cuesta."),
		"window": Game.t("When you leave decides the season you land in.", "Cuándo sales decide en qué estación aterrizas."),
		"trajectory": Game.t("A faster path costs propellant, and propellant is mass.", "Un camino más rápido cuesta propelente, y el propelente es masa."),
		"profile": Game.t("Budget, surface time and the data Earth expects.", "Presupuesto, tiempo en superficie y datos que espera la Tierra."),
		"site": Game.t("Land safely far away, or close on rough ground.", "Aterrizar seguro y lejos, o cerca en suelo áspero."),
		"priority": Game.t("The data you favour counts 30% more.", "Los datos que favoreces valen un 30% más.")}[key]

## Quién lleva cada decisión en cooperativo (los dos confirman el plan completo al final).
func step_role(key: String) -> Array:
	return {"launcher": [Game.t("Engineer reports the mass · Commander decides", "El Ingeniero informa la masa · el Comandante decide"), UIK.P2],
		"window": [Game.t("Commander decides", "Decide el Comandante"), UIK.P1],
		"trajectory": [Game.t("Both review it", "La revisan los dos"), UIK.MINT],
		"profile": [Game.t("Commander weighs the budget", "El Comandante valora el presupuesto"), UIK.P1],
		"site": [Game.t("Commander proposes · Engineer checks", "El Comandante propone · el Ingeniero revisa"), UIK.P1],
		"priority": [Game.t("Commander sets the priority", "El Comandante fija la prioridad"), UIK.P1]}[key]

## Tres datos cortos por opción: lo esencial para decidir.
func facts(key: String, id: String) -> Array:
	var info: Dictionary = table(key)[id]
	match key:
		"launcher": return [Game.t("%d kg to Mars", "%d kg a Marte") % int(info.capacity), "%d CR" % int(info.cost), Game.t("fast transfer: yes", "rápida: sí") if bool(info.fast) else Game.t("fast transfer: no", "rápida: no")]
		"window": return [Game.tt(info.period), ("%+d CR" % int(info.budget)) if int(info.budget) != 0 else Game.t("no budget change", "sin cambio de presupuesto"), Game.t("time on Mars ×%s", "tiempo en Marte ×%s") % Data.months_text(float(info.time))]
		"trajectory": return [Game.t("≈ %s months", "≈ %s meses") % Data.months_text(float(info.months)), Game.t("%d kg propellant", "%d kg de propelente") % int(info.prop), Game.t("time on Mars ×%s", "tiempo en Marte ×%s") % Data.months_text(float(info.time))]
		"profile": return [Game.t("%d CR mission", "misión de %d CR") % (int(info.budget) + int(Data.LAUNCHERS[Data.CLASS_LAUNCHER[id]].cost)), Game.t("time on Mars ×%s", "tiempo en Marte ×%s") % Data.months_text(float(info.time)), Game.t("data ×%s", "datos ×%s") % Data.months_text(float(info.data))]
		"site": return [Game.t("gentle landing", "aterrizaje suave") if float(info.stress) == 0.0 else Game.t("rough landing", "aterrizaje áspero"), Game.t("long drive", "trayecto largo") if float(info.near) == 0.0 else Game.t("short drive", "trayecto corto")]
	return []

func open_step(key: String) -> void:
	step = key
	for child in options.get_children(): child.queue_free()
	cells.clear()
	var column := UIK.column(options, Rect2(18, 14, 524, 578), 8)
	var head := UIK.row(column, 10)
	UIK.label(head, "%d · %s" % [STEPS.find(key) + 1, step_name(key).to_upper()], 24, UIK.NAVY, "title").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var more := UIK.button(head, Game.t("Learn more", "Conocer más"), func() -> void: learn_more(step), "ghost", Vector2(150, 38))
	more.add_theme_font_size_override("font_size", 15)
	UIK.text(column, step_help(key), 15, UIK.MUTED)
	if Game.coop:
		var role := step_role(key)
		UIK.chip(column, "  %s  " % String(role[0]), role[1])
	var ids := order(key)
	for id in ids:
		var info: Dictionary = table(key)[id]
		var card := Button.new()
		card.custom_minimum_size = Vector2(524, 92 if ids.size() > 3 else (150 if ids.size() == 2 else 138))
		card.focus_mode = Control.FOCUS_ALL
		card.pressed.connect(func() -> void: choose(key, id))
		card.mouse_entered.connect(func() -> void: explain(key, id))
		card.focus_entered.connect(func() -> void: explain(key, id))
		column.add_child(card)
		var inner := UIK.column(card, Rect2(16, 10, 492, card.custom_minimum_size.y - 20), 4)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var top := UIK.row(inner, 8)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIK.label(top, Game.tt(info.name), 20, UIK.NAVY, "title").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if key == "launcher": UIK.chip(top, Game.t(" fictional · 2Mars ", " ficticio · 2Mars "), UIK.MUTED)
		var line := HFlowContainer.new()
		line.add_theme_constant_override("h_separation", 6)
		line.add_theme_constant_override("v_separation", 4)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(line)
		for fact in facts(key, id): UIK.chip(line, " %s " % String(fact), UIK.NAVY).add_theme_font_size_override("font_size", 13)
		if info.has("pro"):
			UIK.label(inner, "+ " + Game.tt(info.pro), 14, UIK.GOOD, "bold").mouse_filter = Control.MOUSE_FILTER_IGNORE
			UIK.label(inner, "− " + Game.tt(info.con), 14, UIK.RUST, "bold").mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			var note := UIK.text(inner, Game.tt(info.note), 14, UIK.INK)
			note.max_lines_visible = 2
			note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cells[key + ":" + id] = card
	refresh()
	explain(key, String(plan[key]))
	if cells.has(key + ":" + String(plan[key])): (cells[key + ":" + String(plan[key])] as Button).grab_focus.call_deferred()

func explain(key: String, id: String) -> void:
	var info: Dictionary = table(key)[id]
	var text := "%s: %s" % [Game.tt(info.name), Game.tt(info.note)]
	# La Dra. Owen avisa de las combinaciones que no encajan, con la corrección al lado.
	var trial := plan.duplicate(true)
	trial[key] = id
	if Data.trajectory_id(trial) == "fast" and not bool(Data.LAUNCHERS[Data.launcher_id(trial)].fast):
		text = Game.t("%s cannot fly the fast transfer. Pick another transfer or a more capable launcher.", "%s no puede con la transferencia rápida. Elige otra transferencia o un lanzador más capaz.") % Game.tt(Data.LAUNCHERS[Data.launcher_id(trial)].name)
	elif Data.mass(Game.build) > Data.rover_mass_limit(trial):
		text = Game.t("Your rover is too heavy for this plan by %d kg. You can lighten it in the workshop or choose a more capable launcher.", "Tu rover pesa %d kg de más para este plan. Puedes aligerarlo en el taller o elegir un lanzador más capaz.") % (Data.mass(Game.build) - Data.rover_mass_limit(trial))
	owen_label.text = text
	owen_label.tooltip_text = text
	owen_label.mouse_filter = Control.MOUSE_FILTER_STOP
	owen_label.visible_ratio = 1.0

func choose(key: String, id: String) -> void:
	plan[key] = id
	Game.sfx("attach")
	explain(key, id)
	refresh()

func refresh() -> void:
	for key in cells:
		var parts: PackedStringArray = String(key).split(":")
		var active: bool = String(plan[parts[0]]) == parts[1]
		var b: Button = cells[key]
		for state in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(state, UIK.box((UIK.CREAM if active else UIK.PAPER).lerp(UIK.ORANGE, 0.12 if state == "hover" else 0.0), 16, UIK.ORANGE if active else UIK.INK, 4 if active or state == "focus" else 2, 3))
	for id in step_buttons:
		var b: Button = step_buttons[id]
		b.text = "%d · %s\n%s" % [STEPS.find(id) + 1, step_name(id).to_upper(), Game.tt(table(id)[String(plan[id])].name)]
		b.add_theme_stylebox_override("normal", UIK.box(UIK.MINT if id == step else UIK.PAPER, 16, UIK.INK, 4 if id == step else 2, 3))
	for child in summary.get_children(): child.queue_free()
	var pile := Data.stack(Game.build, plan)
	var column := UIK.column(summary, Rect2(20, 14, 358, 356), 5)
	UIK.label(column, Game.t("WHAT THIS PLAN MEANS", "QUÉ SIGNIFICA ESTE PLAN"), 15, UIK.MINT, "bold")
	var over := int(pile.margin) < 0
	var head := UIK.row(column, 6)
	UIK.label(head, Game.t("Launch mass", "Masa de lanzamiento"), 15, UIK.PAPER, "bold").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.label(head, "%d / %d kg" % [int(pile.total), int(pile.capacity)], 15, UIK.BAD if over else UIK.CREAM, "bold")
	UIK.gauge(column, clampf(float(pile.total) / float(pile.capacity), 0.0, 1.0), UIK.BAD if over else (UIK.SAND if int(pile.margin) < 40 else UIK.GOOD), 14.0, Color(1, 1, 1, 0.16))
	var margin := UIK.row(column, 6)
	UIK.label(margin, (Game.t("%d kg over capacity", "%d kg por encima de la capacidad") % -int(pile.margin)) if over else (Game.t("Margin: %d kg", "Margen: %d kg") % int(pile.margin)), 13, UIK.BAD if over else UIK.MINT, "bold").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var detail := UIK.button(margin, Game.t("Breakdown", "Desglose"), open_breakdown, "ghost", Vector2(112, 30))
	detail.add_theme_font_size_override("font_size", 13)
	var before := Data.limits(Game.plan)
	var cap := Data.limits(plan)
	var minutes := Data.mission_time(Game.zone, plan)
	var storm := Data.storm_factor(plan)
	for item in [[Game.t("Rover mass limit", "Límite de masa del rover"), "%d kg" % int(cap.mass), int(cap.mass) - int(before.mass)],
		[Game.t("Rover budget", "Presupuesto del rover"), "%d CR" % int(cap.budget), int(cap.budget) - int(before.budget)],
		[Game.t("Cruise", "Crucero"), Game.t("≈ %s months", "≈ %s meses") % Data.months_text(Data.travel_months(plan)), 0],
		[Game.t("Surface time", "Tiempo en superficie"), "%d:%02d" % [int(minutes) / 60, int(minutes) % 60], 0],
		[Game.t("Data Earth expects", "Datos que espera la Tierra"), "%d MB" % int(Data.need_mb(Game.zone, plan)), 0],
		[Game.t("Dust season", "Temporada de polvo"), Game.t("arrives later", "llega más tarde") if storm > 1.0 else (Game.t("arrives sooner", "llega antes") if storm < 1.0 else Game.t("as forecast", "según lo previsto")), 0]]:
		var row := UIK.row(column, 6)
		UIK.label(row, String(item[0]), 14, UIK.PAPER, "bold").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if int(item[2]) != 0: UIK.chip(row, "%+d" % int(item[2]), UIK.GOOD if int(item[2]) > 0 else UIK.SAND)
		UIK.label(row, String(item[1]), 14, UIK.CREAM, "bold")
	var review := Data.plan_review(Game.build, Game.zone, plan)
	var chips := UIK.row(column, 6)
	UIK.chip(chips, Game.t(" %d validated ", " %d validados ") % Data.review_count(review, "ok"), UIK.GOOD)
	if Data.review_count(review, "warn") > 0: UIK.chip(chips, Game.t(" %d warnings ", " %d avisos ") % Data.review_count(review, "warn"), UIK.SAND)
	if Data.review_count(review, "critical") > 0: UIK.chip(chips, Game.t(" %d critical ", " %d CRíticos ") % Data.review_count(review, "critical"), UIK.BAD)
	var note := UIK.text(column, Game.t("CR = mission credits, a fictional unit. Game model, not NASA figures.", "CR = créditos de misión, unidad ficticia. Modelo de juego, no cifras de la NASA."), 12, UIK.MUTED)
	note.mouse_filter = Control.MOUSE_FILTER_STOP
	note.tooltip_text = Game.tt(Data.CR_NOTE)

## Desglose opcional: qué incluye la masa que se compara con la capacidad del lanzador.
func open_breakdown() -> void:
	UIK.close_modal(self)
	var pile := Data.stack(Game.build, plan)
	var content := UIK.modal(self, Vector2(720, 560), Game.t("Launch mass", "Masa de lanzamiento"))
	UIK.text(content, Game.t("The launcher lifts the whole stack, not just the rover. This is what 2Mars counts.", "El lanzador levanta toda la pila, no solo el rover. Esto es lo que cuenta 2Mars."), 15, UIK.MUTED)
	for item in [["rover", Game.t("Rover (structure and systems)", "Rover (estructura y sistemas)")], ["instruments", Game.t("Science instruments", "Instrumentos científicos")], ["descent", Game.t("Descent stage", "Etapa de descenso")],
		["aeroshell", Game.t("Aeroshell and parachute", "Aeroescudo y paracaídas")], ["cruise", Game.t("Cruise stage", "Etapa de crucero")], ["propellant", Game.t("Cruise propellant", "Propelente de crucero")]]:
		var row := UIK.row(content, 10)
		UIK.label(row, String(item[1]), 16, UIK.INK, "bold").custom_minimum_size.x = 300
		var bar := UIK.gauge(row, float(pile[String(item[0])]) / maxf(1.0, float(pile.capacity)), UIK.ORANGE, 14.0)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		UIK.label(row, "%d kg" % int(pile[String(item[0])]), 16, UIK.NAVY, "bold").custom_minimum_size.x = 76
	var over := int(pile.margin) < 0
	UIK.label(content, Game.t("Total %d kg · capacity %d kg · %s", "Total %d kg · capacidad %d kg · %s") % [int(pile.total), int(pile.capacity), (Game.t("%d kg over", "%d kg de más") % -int(pile.margin)) if over else (Game.t("margin %d kg", "margen %d kg") % int(pile.margin))], 18, UIK.BAD if over else UIK.GOOD, "title")
	if over:
		var names: Array = []
		for id in Data.heaviest(Game.build): names.append("%s (%d kg)" % [Data.comp_name(id), int(Data.COMPONENTS[id].mass)])
		UIK.text(content, Game.t("Heaviest parts on your rover: ", "Piezas más pesadas de tu rover: ") + ", ".join(names) + ".", 15, UIK.INK)
	UIK.text(content, Game.t("Simplified on purpose: the descent stage and the aeroshell are counted as heavy as the rover each, and the cruise stage as a fixed 200 kg. These are not the real masses of Mars 2020.", "Simplificado a propósito: la etapa de descenso y el aeroescudo cuentan cada uno tanto como el rover, y la etapa de crucero 200 kg fijos. No son las masas reales de Mars 2020."), 13, UIK.MUTED)
	var line := UIK.row(content, 10)
	UIK.button(line, Game.t("Close", "Cerrar"), func() -> void: UIK.close_modal(self), "ghost", Vector2(160, 44))
	UIK.focus_first(line)

## «Conocer más»: hecho real con su fuente, qué simplifica el juego y por qué importa.
func learn_more(key: String) -> void:
	UIK.close_modal(self)
	var info: Dictionary = Data.PLAN_FACTS[key]
	var content := UIK.modal(self, Vector2(820, 640), step_name(key))
	var why := UIK.card(content, Game.t("WHY DOES THIS MATTER?", "¿POR QUÉ IMPORTA?"), UIK.ORANGE)
	UIK.text(why, Game.tt(info.why), 16, UIK.INK)
	if Game.tt(info.real) != "":
		var real := UIK.card(content, Game.t("REAL · NASA", "REAL · NASA"), UIK.TEAL)
		UIK.text(real, Game.tt(info.real), 15, UIK.INK)
		UIK.link(real, String(info.source), String(info.url))
	var game := UIK.card(content, Game.t("IN 2MARS · game model", "EN 2MARS · modelo de juego"), UIK.RUST)
	UIK.text(game, Game.tt(info.game), 15, UIK.INK)
	var line := UIK.row(content, 10)
	UIK.button(line, Game.t("Close", "Cerrar"), func() -> void: UIK.close_modal(self), "ghost", Vector2(160, 44))
	UIK.focus_first(line)

func confirm() -> void:
	var cap := Data.limits(plan)
	coop_gate(Game.t("Mission plan", "Plan de misión"),
		Game.t("You approve the window, the trajectory and the budget: %s, %s, %d CR for the rover. Go?", "Apruebas la ventana, la trayectoria y el presupuesto: %s, %s, %d CR para el rover. ¿Adelante?") % [Game.tt(Data.WINDOWS[String(plan.window)].name), Game.tt(Data.TRAJECTORIES[Data.trajectory_id(plan)].name), int(cap.budget)],
		Game.t("With %s the rover can weigh up to %d kg. Can the science payload be built inside that?", "Con %s el rover puede pesar hasta %d kg. ¿Cabe ahí la carga científica?") % [Game.tt(Data.LAUNCHERS[Data.launcher_id(plan)].name), int(cap.mass)],
		func() -> void:
			Game.plan = plan.duplicate(true)
			Game.save()
			Game.go("design"))

func after_settings() -> void:
	Game.plan_draft = plan.duplicate(true)   # lo elegido hasta ahora no se pierde
	Game.go("plan")

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo or not gate.is_empty(): return
	var index := STEPS.find(step)
	if event.keycode == KEY_PAGEDOWN or event.keycode == KEY_BRACKETRIGHT: open_step(STEPS[(index + 1) % STEPS.size()])
	elif event.keycode == KEY_PAGEUP or event.keycode == KEY_BRACKETLEFT: open_step(STEPS[(index + STEPS.size() - 1) % STEPS.size()])
