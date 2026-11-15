extends BaseScreen
## Planificación de misión (guion fase 1): ventana de lanzamiento, perfil, sitio de aterrizaje
## y prioridad científica. Cada elección cambia límites, tiempo, datos exigidos o el aterrizaje.
## La Dra. Owen explica cada opción en una esquina, sin interrumpir.

var plan: Dictionary
var owen_label: Label
var summary: Panel
var groups: VBoxContainer
var cells := {}

func _ready() -> void:
	backdrop = "workshop"
	backdrop_dim = 0.45
	plan = Game.plan.duplicate(true)
	var zone: Dictionary = Data.ZONES[Game.zone]
	var head := title(Game.t("MISSION PLANNING", "PLANIFICACIÓN DE MISIÓN"), Vector2(30, 14), 36)
	var where := UIK.chip(self, "  %s · %s  " % [Game.tt(zone.goal).to_upper(), Game.tt(zone.name)], Color(String(zone.color)))
	where.position = Vector2(34 + head.get_minimum_size().x + 10, 28)
	back_button(Game.t("← Missions", "← Misiones"), "zones", Vector2(1100, 18))
	coop_banner(Vector2(30, 66), Game.t("sets the priorities", "fija las prioridades"), Game.t("checks they are feasible", "comprueba que son viables"))
	var area := UIK.panel(self, Rect2(24, 100, 800, 606))
	groups = UIK.column(area, Rect2(20, 12, 760, 584), 4)
	add_group("window", Game.t("LAUNCH WINDOW  ·  time", "VENTANA DE LANZAMIENTO  ·  tiempo"), Data.WINDOW_ORDER, Data.WINDOWS)
	add_group("profile", Game.t("MISSION PROFILE  ·  mass, budget and data", "PERFIL DE MISIÓN  ·  masa, presupuesto y datos"), Data.PROFILE_ORDER, Data.PROFILES)
	add_group("site", Game.t("LANDING SITE  ·  risk against distance", "SITIO DE ATERRIZAJE  ·  riesgo frente a distancia"), Data.SITE_ORDER, Data.SITES)
	add_group("priority", Game.t("SCIENCE PRIORITY  ·  what counts most", "PRIORIDAD CIENTÍFICA  ·  qué cuenta más"), Data.PRIORITY_ORDER, Data.PRIORITIES)
	summary = UIK.panel(self, Rect2(840, 100, 416, 380), Color(UIK.INK, 0.92))
	var owen := owen_panel(self, Rect2(840, 494, 416, 212), Game.t("Pick an option and I'll tell you what it changes. Real launch windows to Mars open about every 26 months.", "Elige una opción y te digo qué cambia. Las ventanas reales de lanzamiento a Marte se abren cada 26 meses aproximadamente."))
	owen_label = owen.label
	owen_label.add_theme_font_size_override("font_size", 15)
	refresh()
	UIK.focus_first(groups)

func add_group(key: String, caption: String, order: Array, table: Dictionary) -> void:
	UIK.label(groups, caption, 14, UIK.RUST, "bold")
	var line := UIK.row(groups, 8)
	for id in order:
		var info: Dictionary = table[id]
		var b := UIK.button(line, Game.tt(info.name), func() -> void: choose(key, id), "ghost", Vector2(120, 100))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 17)
		b.mouse_entered.connect(func() -> void: explain(key, id))
		b.focus_entered.connect(func() -> void: explain(key, id))
		cells[key + ":" + id] = b

func explain(key: String, id: String) -> void:
	var table: Dictionary = {"window": Data.WINDOWS, "profile": Data.PROFILES, "site": Data.SITES, "priority": Data.PRIORITIES}[key]
	var text := "%s: %s" % [Game.tt(table[id].name), Game.tt(table[id].note)]
	if key == "profile": text += Game.t(" Limits: %d kg, %d cr.", " Límites: %d kg, %d cr.") % [int(table[id].mass), int(table[id].budget)]
	owen_label.text = text
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
		b.add_theme_stylebox_override("normal", UIK.box(UIK.ORANGE if active else UIK.PAPER, 16, UIK.INK, 4 if active else 2, 3))
	for child in summary.get_children(): child.queue_free()
	var cap := Data.limits(plan)
	var before := Data.limits(Game.plan)
	var column := UIK.column(summary, Rect2(22, 16, 372, 300), 6)
	UIK.label(column, Game.t("WHAT THIS PLAN MEANS", "QUÉ SIGNIFICA ESTE PLAN"), 15, UIK.MINT, "bold")
	var minutes := Data.mission_time(Game.zone, plan)
	for item in [["mass", Game.t("Mass limit", "Límite de masa"), "%d kg" % int(cap.mass), int(cap.mass) - int(before.mass)],
		["budget", Game.t("Budget", "Presupuesto"), "%d cr" % int(cap.budget), int(cap.budget) - int(before.budget)],
		["time", Game.t("Surface time", "Tiempo en superficie"), "%d:%02d" % [int(minutes) / 60, int(minutes) % 60], 0],
		["data", Game.t("Data Earth expects", "Datos que espera la Tierra"), "%d MB" % int(Data.need_mb(Game.zone, plan)), 0],
		["energy", Game.t("Dust storms", "Tormentas de polvo"), Game.t("arrive later", "llegan más tarde") if float(Data.WINDOWS[String(plan.window)].storm) > 1.0 else (Game.t("arrive sooner", "llegan antes") if float(Data.WINDOWS[String(plan.window)].storm) < 1.0 else Game.t("as forecast", "según lo previsto")), 0],
		["comms", Game.t("Landing", "Aterrizaje"), Game.tt(Data.SITES[String(plan.site)].name), 0]]:
		var row := UIK.row(column, 8)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(26, 26)
		var kind := String(item[0])
		icon.draw.connect(func() -> void: Art.icon(icon, kind, Vector2(13, 13), 24, UIK.ORANGE))
		row.add_child(icon)
		UIK.label(row, String(item[1]), 15, UIK.PAPER, "bold").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if int(item[3]) != 0: UIK.chip(row, "%+d" % int(item[3]), UIK.GOOD if int(item[3]) > 0 else UIK.SAND)
		UIK.label(row, String(item[2]), 15, UIK.CREAM, "bold")
	var suggested: Array = []
	for id in Data.ZONES[Game.zone].suggest: suggested.append(Data.comp_name(id))
	UIK.text(column, Game.t("Suggested for this goal: ", "Sugerido para esta meta: ") + ", ".join(suggested), 14, UIK.MINT)
	UIK.text(column, Game.t("Limits, times and megabytes are a game model, not NASA figures.", "Límites, tiempos y megabytes son un modelo de juego, no cifras de la NASA."), 12, UIK.MUTED)
	var go := UIK.button(summary, Game.t("CONFIRM PLAN → WORKSHOP", "CONFIRMAR PLAN → TALLER"), confirm, "go", Vector2(372, 54))
	go.position = Vector2(22, 312)

func confirm() -> void:
	coop_gate(Game.t("Mission plan", "Plan de misión"),
		Game.t("You chose the priorities. Are they the right ones for this goal?", "Elegiste las prioridades. ¿Son las correctas para esta meta?"),
		Game.t("Can a rover be built inside %d kg and %d cr for this plan?", "¿Se puede construir un rover dentro de %d kg y %d cr para este plan?") % [int(Data.limits(plan).mass), int(Data.limits(plan).budget)],
		func() -> void:
			Game.plan = plan.duplicate(true)
			Game.save()
			Game.go("design"))
