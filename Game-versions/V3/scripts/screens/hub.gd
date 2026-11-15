extends BaseScreen
## Base terrestre (referencias 10 y 20): rover actual, estadísticas reales, presupuesto,
## recomendación de la Dra. Owen según el historial y accesos.

var preview: Control
var spin := -0.4

func _ready() -> void:
	backdrop = "workshop"
	Game.mode = "campaign"
	var s := Data.stats(Game.build)
	var cap := Data.limits(Game.plan)
	var side := UIK.panel(self, Rect2(960, 0, 320, 720), UIK.PAPER, 0)
	var column := UIK.column(side, Rect2(30, 22, 260, 680), 10)
	UIK.label(column, Game.t("Welcome!", "¡Bienvenido!"), 34, UIK.NAVY, "title")
	UIK.label(column, Game.player_name, 24, UIK.RUST, "title")
	UIK.label(column, "%s  ·  %d%%" % [Game.team_name, Game.campaign_percent()], 15, UIK.MUTED, "bold")
	UIK.button(column, Game.t("MISSION PANEL", "PANEL DE MISIONES"), func() -> void: Game.go("zones"), "go", Vector2(260, 62)).add_theme_font_size_override("font_size", 22)
	UIK.button(column, Game.t("WORKSHOP", "TALLER"), func() -> void: Game.go("design"), "primary", Vector2(260, 54)).add_theme_font_size_override("font_size", 22)
	UIK.button(column, Game.t("PROGRESS", "PROGRESO"), func() -> void: Game.go("progress"), "teal", Vector2(260, 54)).add_theme_font_size_override("font_size", 22)
	UIK.button(column, Game.t("Co-op: ON (2 players)", "Cooperativo: SÍ (2 jugadores)") if Game.coop else Game.t("Co-op: off", "Cooperativo: no"), toggle_coop, "yellow", Vector2(260, 44))
	UIK.button(column, Game.t("Science library", "Biblioteca científica"), func() -> void:
		Game.library_return = "hub"
		Game.go("library"), "ghost", Vector2(260, 42))
	UIK.button(column, Game.t("Achievements", "Logros"), func() -> void: Game.go("achievements"), "ghost", Vector2(260, 42))
	UIK.button(column, Game.t("Settings", "Ajustes"), func() -> void: Settings.open(self, func() -> void: Game.go("hub")), "ghost", Vector2(260, 42))
	UIK.button(column, Game.t("Back to menu", "Volver al menú"), func() -> void: Game.go("menu"), "ghost", Vector2(260, 42))
	var where := UIK.chip(self, Game.t("  YOU ARE AT THE EARTH STATION  ", "  ESTÁS EN LA BASE TERRESTRE  "), UIK.NAVY)
	where.position = Vector2(30, 24)
	where.add_theme_font_size_override("font_size", 16)
	var head := UIK.heading(self, Game.t("CURRENT ROVER: %s", "ROVER ACTUAL: %s") % Game.rover_name, 28)
	head.position = Vector2(30, 62)
	var stats := UIK.panel(self, Rect2(520, 110, 410, 250), Color(UIK.INK, 0.9))
	var list := UIK.column(stats, Rect2(22, 16, 366, 220), 5)
	UIK.label(list, Game.t("CURRENT ROVER STATS", "ESTADÍSTICAS DEL ROVER"), 15, UIK.MINT, "bold")
	for item in [[Game.t("Mass", "Masa"), float(s.mass) / float(cap.mass), "%d / %d kg" % [int(s.mass), int(cap.mass)]],
		[Game.t("Energy storage", "Energía almacenada"), float(s.battery) / 1100.0, "%d Wh" % int(s.battery)],
		[Game.t("Mobility", "Movilidad"), float(s.mobility) / 130.0, "%d" % int(s.mobility)],
		[Game.t("Science potential", "Potencial científico"), float(s.science) / 300.0, "%d" % int(s.science)],
		[Game.t("Memory", "Memoria"), float(s.memory) / 200.0, "%d MB" % int(s.memory)]]:
		var row := UIK.row(list, 8)
		UIK.label(row, String(item[0]), 14, UIK.PAPER, "bold").custom_minimum_size.x = 150
		var bar := ProgressBar.new()
		bar.max_value = 1.0
		bar.value = 0.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(110, 14)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_theme_stylebox_override("background", UIK.box(Color(UIK.PAPER, 0.15), 7, Color.TRANSPARENT, 0, 0))
		bar.add_theme_stylebox_override("fill", UIK.box(UIK.ORANGE, 7, Color.TRANSPARENT, 0, 0))
		row.add_child(bar)
		if Game.reduced_motion: bar.value = float(item[1])
		else: bar.create_tween().tween_property(bar, "value", clampf(float(item[1]), 0.0, 1.0), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		UIK.label(row, String(item[2]), 14, UIK.CREAM, "bold")
	var budget := UIK.chip(list, "  %s  %d / %d cr  " % [Game.t("BUDGET", "PRESUPUESTO"), Data.cost(Game.build), int(cap.budget)], UIK.GO)
	budget.add_theme_font_size_override("font_size", 17)
	var checks := Data.check(Game.build, Game.zone if Data.ZONES.has(Game.zone) else "geology", Game.plan)
	var blockers := Data.count_level(checks, "blocker")
	UIK.label(list, (Game.t("Readiness: %d blocker(s) to fix in the workshop", "Preparación: %d bloqueo(s) por resolver en el taller") % blockers) if blockers > 0 else Game.t("Readiness: no blockers", "Preparación: sin bloqueos"), 14, UIK.BAD if blockers > 0 else UIK.GO, "bold")
	# Recomendación adaptativa (historial real)
	var advice: Dictionary = Data.recommendations(Game.history)[0]
	var owen := owen_panel(self, Rect2(30, 500, 900, 196), "%s — %s %s" % [Game.tt(advice.issue), Game.tt(advice.why), Game.tt(advice.tip)], Game.t("Advice from your flight history", "Consejo según tu historial de vuelo"))
	var extra: VBoxContainer = owen.column
	var line := UIK.row(extra, 8)
	wait_button(line)
	if Game.history.size() > 0: UIK.chip(line, Game.t(" based on %d saved mission(s) ", " basado en %d misión(es) guardada(s) ") % Game.history.size(), UIK.NAVY)
	UIK.focus_first(column)

func toggle_coop() -> void:
	Game.coop = not Game.coop
	if Game.coop: explain_coop()
	else: Game.go("hub")

func explain_coop() -> void:
	var content := UIK.modal(self, Vector2(800, 520), Game.t("Local co-op · two players, one computer", "Cooperativo local · dos jugadores, una computadora"))
	var roles := UIK.row(content, 14)
	var commander_player := 2 if Game.coop_swapped else 1
	var first := UIK.card(roles, Game.t("PLAYER %d · MISSION COMMANDER", "JUGADOR %d · COMANDANTE DE MISIÓN") % commander_player, UIK.P1)
	UIK.text(first, Game.t("Sets objectives and priorities, drives the rover with the ARROW keys, authorises transmissions (T) and decides when the mission ends. Confirms with ENTER.", "Fija objetivos y prioridades, conduce el rover con las FLECHAS, autoriza transmisiones (T) y decide cuándo termina la misión. Confirma con INTRO."), 16, UIK.INK)
	var second := UIK.card(roles, Game.t("PLAYER %d · ROVER ENGINEER & SCIENTIST", "JUGADOR %d · INGENIERO Y CIENTÍFICO") % (3 - commander_player), UIK.P2)
	UIK.text(second, Game.t("Builds the rover, watches energy and memory, runs the instruments (E, 1-6, SPACE) and tools (M, O, R, G). Confirms with F, or button A on a controller.", "Construye el rover, vigila energía y memoria, opera los instrumentos (E, 1-6, ESPACIO) y herramientas (M, O, R, G). Confirma con F, o el botón A de un mando."), 16, UIK.INK)
	UIK.text(content, Game.t("Three decisions need BOTH players: the mission plan, the rover design before launch, and ending the mission. Everything else is shared live: one rover, one battery, one memory.", "Tres decisiones exigen a AMBOS jugadores: el plan de misión, el diseño del rover antes de lanzar y el final de la misión. Todo lo demás se comparte en vivo: un rover, una batería, una memoria."), 16, UIK.INK)
	var line := UIK.row(content, 10)
	UIK.button(line, Game.t("Swap roles", "Intercambiar roles"), func() -> void:
		Game.coop_swapped = not Game.coop_swapped
		UIK.close_modal(self)
		explain_coop(), "ghost", Vector2(300, 46))
	UIK.button(line, Game.t("Start co-op", "Empezar cooperativo"), func() -> void: Game.go("hub"), "go", Vector2(240, 46))
	UIK.focus_first(line)

func paint() -> void:
	var centre := Vector2(270, 300)
	draw_colored_polygon(Art.blob(centre + Vector2(0, 30), 210, 120, 3, 14, 0.04), Color(UIK.INK, 0.35))
	draw_arc(centre + Vector2(0, 24), 190, 0, TAU, 48, Color(UIK.MINT, 0.5), 3.0, true)
	Art.rover(self, centre, spin + (time * 0.25 if not Game.reduced_motion else 0.0), Game.build, 4.4, time)
	Art.emblem(self, Game.emblem, Vector2(900, 60), 34)
