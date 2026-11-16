extends BaseScreen
## Bases (referencias 10 y 20). Dos ubicaciones con acciones distintas:
##  · Base terrestre: el rover sobre la plataforma del taller; se diseña, se mejora y se lanza.
##  · Base en Marte: el rover ya aterrizado; se eligen misiones y se revisa la ciencia obtenida.
## La base en Marte se abre al aterrizar por primera vez (dato real del archivo de guardado).

var scene: Stage3D
var on_mars := false

func landed() -> int:
	var total := 0
	for id in Game.progress: total += int(Game.progress[id].get("runs", 0))
	return total

func _ready() -> void:
	backdrop = "none"
	Game.mode = "campaign"
	on_mars = Game.location == "mars" and landed() > 0
	var s := Data.stats(Game.build)
	var cap := Data.limits(Game.plan)
	# escenario 3D con el rover del jugador como protagonista
	scene = Stage3D.make(self, Rect2(0, 0, 960, 720))
	if on_mars:
		scene.vista(true)
		scene.show_rover(Game.build, Vector3(0, scene.ground_height(Vector2.ZERO) + 0.02, 0), 0.9)
		scene.focus = Vector3(0.2, -0.3, 0)
		scene.goal = Vector3(0.55, 0.2, 10.5)
		scene.zoom_range = Vector2(6.0, 14.0)
		scene.camera.fov = 36.0
	else:
		scene.workshop()
		scene.show_rover(Game.build)
		scene.focus = Vector3(0.0, -0.45, 0)
		scene.goal = Vector3(0.7, 0.3, 11.0)
		scene.zoom_range = Vector2(7.0, 13.0)
	scene.orbit = scene.goal
	scene.spin = 0.16
	scene.parallax = 0.03
	scene.enable_orbit()
	shade(Rect2(0, 0, 960, 150), Color(UIK.INK, 0.28))
	# cabecera: dónde estás y cómo cambiar de base
	var where := UIK.chip(self, Game.t("  YOU ARE ON MARS  ", "  ESTÁS EN MARTE  ") if on_mars else Game.t("  YOU ARE AT THE EARTH STATION  ", "  ESTÁS EN LA BASE TERRESTRE  "), UIK.RUST if on_mars else UIK.NAVY)
	where.position = Vector2(24, 18)
	where.add_theme_font_size_override("font_size", 16)
	var head := UIK.heading(self, Game.rover_name, 40, UIK.CREAM)
	head.position = Vector2(24, 50)
	var hint := UIK.label(self, Game.t("Drag to rotate · wheel to zoom", "Arrastra para girar · rueda para acercar"), 13, Color(UIK.PAPER, 0.85), "bold")
	hint.position = Vector2(24, 104)
	hint.add_theme_color_override("font_outline_color", UIK.INK)
	hint.add_theme_constant_override("outline_size", 5)
	# tarjeta resumen
	var card := UIK.panel(self, Rect2(24, 396, 420, 190), Color(UIK.INK, 0.88))
	var list := UIK.column(card, Rect2(18, 12, 384, 166), 6)
	if on_mars:
		UIK.label(list, Game.t("ROVERS LANDED ON MARS: %d", "ROVERS ATERRIZADOS EN MARTE: %d") % landed(), 16, UIK.MINT, "bold")
		var facts := UIK.row(list, 10)
		UIK.stat(facts, "nav_research", "%d" % Game.total_science(), Game.t("science", "ciencia"), UIK.CREAM)
		UIK.stat(facts, "nav_progress", "%d%%" % Game.campaign_percent(), Game.t("campaign", "campaña"), UIK.CREAM)
		UIK.stat(facts, "mat_canister", "%d" % samples(), Game.t("samples", "muestras"), UIK.CREAM)
		if not Game.history.is_empty():
			var last: Dictionary = Game.history[-1]
			UIK.label(list, Game.t("Last mission: %s · grade %s", "Última misión: %s · nota %s") % [Game.tt(Data.ZONES[String(last.zone)].name), String(last.grade)], 15, UIK.PAPER, "bold")
	else:
		UIK.label(list, Game.t("CURRENT ROVER", "ROVER ACTUAL"), 14, UIK.MINT, "bold")
		for item in [["nav_inventory", Game.t("Mass", "Masa"), float(s.mass) / float(cap.mass), "%d / %d kg" % [int(s.mass), int(cap.mass)]],
			["up_power", Game.t("Battery", "Batería"), float(s.battery) / 1100.0, "%d Wh" % int(s.battery)],
			["nav_research", Game.t("Science", "Ciencia"), float(s.science) / 300.0, "%d" % int(s.science)]]:
			var line := UIK.row(list, 8)
			UIK.picture(line, UIK.tex(String(item[0])), Vector2(24, 24))
			UIK.label(line, String(item[1]), 14, UIK.PAPER, "bold").custom_minimum_size.x = 72
			UIK.gauge(line, float(item[2]), UIK.ORANGE, 12.0, Color(UIK.PAPER, 0.16))
			UIK.label(line, String(item[3]), 14, UIK.CREAM, "bold").custom_minimum_size.x = 104
		var checks := Data.check(Game.build, Game.zone if Data.ZONES.has(Game.zone) else "geology", Game.plan)
		var blockers := Data.count_level(checks, "blocker")
		var risks := Data.count_level(checks, "risk")
		var spent := Data.cost(Game.build)
		var money := UIK.row(list, 8)
		UIK.picture(money, UIK.tex("mat_ingot"), Vector2(24, 24))
		UIK.label(money, Game.t("Budget", "Presup."), 14, UIK.PAPER, "bold").custom_minimum_size.x = 72
		UIK.gauge(money, clampf(float(spent) / maxf(1.0, float(cap.budget)), 0.0, 1.0), UIK.BAD if spent > int(cap.budget) else UIK.GO, 12.0, Color(UIK.PAPER, 0.16))
		var money_text := UIK.label(money, "%d / %d CR" % [spent, int(cap.budget)], 14, UIK.CREAM, "bold")
		money_text.custom_minimum_size.x = 104
		money.tooltip_text = Game.tt(Data.CR_NOTE)
		var state := UIK.row(list, 6)
		UIK.chip(state, (Game.t(" %d CR left ", " quedan %d CR ") % (int(cap.budget) - spent)) if spent <= int(cap.budget) else (Game.t(" %d CR over ", " %d CR de más ") % (spent - int(cap.budget))), UIK.GO if spent <= int(cap.budget) else UIK.BAD)
		UIK.chip(state, (Game.t(" %d blocker(s) ", " %d bloqueo(s) ") % blockers) if blockers > 0 else Game.t(" no blockers ", " sin bloqueos "), UIK.BAD if blockers > 0 else UIK.TEAL)
		if risks > 0: UIK.chip(state, Game.t(" %d risk(s) ", " %d riesgo(s) ") % risks, UIK.SAND)
	# acción principal de la base
	var go := UIK.icon_button(self, Game.t("MISSION PANEL", "PANEL DE MISIONES"), "pin_mission", func() -> void: Game.go("zones"), "go", Vector2(420, 66))
	go.position = Vector2(480, 520)
	go.add_theme_font_size_override("font_size", 24)
	var say := UIK.label(self, Game.t("Choose where to explore", "Elige dónde explorar") if on_mars else Game.t("Ready? Pick a mission and launch", "¿Listo? Elige misión y lanza"), 15, UIK.PAPER, "bold")
	say.position = Vector2(486, 494)
	say.add_theme_color_override("font_outline_color", UIK.INK)
	say.add_theme_constant_override("outline_size", 5)
	# consejo de la Dra. Owen según el historial real (resumen; el detalle está en Progreso)
	var advice: Dictionary = Data.recommendations(Game.history)[0]
	var owen := owen_panel(self, Rect2(24, 598, 612, 108), "%s — %s" % [Game.tt(advice.issue), Game.tt(advice.tip)], Game.t("Advice from your flight history", "Consejo según tu historial de vuelo"), 80.0)
	owen.label.tooltip_text = "%s — %s" % [Game.tt(advice.issue), Game.tt(advice.tip)]   # la frase completa, si no cabe en tres líneas
	owen.label.mouse_filter = Control.MOUSE_FILTER_STOP
	var bubble: Label = owen.label
	bubble.max_lines_visible = 2
	bubble.add_theme_font_size_override("font_size", 15)
	var more := wait_button(self)
	more.position = Vector2(648, 630)
	more.custom_minimum_size = Vector2(288, 56)
	more.size = Vector2(288, 56)
	more.add_theme_font_size_override("font_size", 14)
	# navegación lateral
	var side := UIK.panel(self, Rect2(960, 0, 320, 720), UIK.PAPER, 0)
	var column := UIK.column(side, Rect2(28, 18, 264, 690), 9)
	UIK.label(column, Game.t("Welcome!", "¡Bienvenido!"), 32, UIK.NAVY, "title")
	var who := UIK.row(column, 8)
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.draw.connect(func() -> void: Art.emblem(badge, Game.emblem, Vector2(20, 20), 19))
	who.add_child(badge)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -4)
	who.add_child(names)
	UIK.label(names, Game.player_name, 20, UIK.RUST, "title")
	UIK.label(names, Game.team_name, 13, UIK.MUTED, "bold")
	var bar_line := UIK.row(column, 8)
	UIK.gauge(bar_line, Game.campaign_percent() / 100.0, UIK.GO, 14.0)
	UIK.label(bar_line, "%d%%" % Game.campaign_percent(), 15, UIK.NAVY, "bold")
	var big := []
	if on_mars:
		big = [[Game.t("PROGRESS", "PROGRESO"), "nav_progress", "progress", "go"], [Game.t("LIBRARY", "BIBLIOTECA"), "nav_research", "library", "teal"]]
	else:
		big = [[Game.t("WORKSHOP", "TALLER"), "nav_workshop", "design", "teal"], [Game.t("PROGRESS", "PROGRESO"), "nav_progress", "progress", "go"], [Game.t("UPGRADES", "MEJORAS"), "up_efficiency", "upgrades", "yellow"]]
	for item in big:
		var target := String(item[2])
		var b := UIK.icon_button(column, String(item[0]), String(item[1]), func() -> void:
			if target == "library": Game.library_return = "hub"
			Game.go(target), String(item[3]), Vector2(264, 62))
		b.add_theme_font_size_override("font_size", 22)
	if not on_mars:
		var points := UIK.row(column, 6)
		UIK.picture(points, UIK.tex("nav_research"), Vector2(26, 26))
		UIK.label(points, Game.t("%d science points to invest", "%d puntos de ciencia para invertir") % Game.science_points(), 14, UIK.NAVY, "bold")
	# cambio de base: una opción de navegación más, junto a las demás
	var swap := UIK.icon_button(column, Game.t("Earth station", "Base terrestre") if on_mars else Game.t("Mars base", "Base en Marte"), "nav_home" if on_mars else "pin_rover", switch_base, "ghost", Vector2(264, 50))
	swap.add_theme_font_size_override("font_size", 18)
	if not on_mars and landed() == 0:
		swap.disabled = true
		swap.tooltip_text = Game.t("Opens when your first rover lands on Mars.", "Se abre cuando tu primer rover aterrice en Marte.")
		UIK.label(column, Game.t("Land a rover to open it", "Aterriza un rover para abrirla"), 13, UIK.MUTED, "bold")
	# lo secundario (biblioteca, ajustes, menú) va en «Más» / Esc; cooperativo y logros están en el menú principal
	var menu_button := UIK.icon_button(column, Game.t("More", "Más"), "nav_settings", open_menu, "ghost", Vector2(264, 46))
	menu_button.add_theme_font_size_override("font_size", 18)
	menu_button.tooltip_text = Game.t("Library, settings and main menu (Esc)", "Biblioteca, ajustes y menú principal (Esc)")
	if Game.coop: UIK.chip(column, Game.t("  Co-op: %s  ", "  Cooperativo: %s  ") % Game.coop_name(), UIK.P2)
	Motion.stagger(column.get_children(), 0.03, Vector2(24, 0))
	Motion.slide_in(card, Vector2(-30, 0))
	UIK.focus_first(column)

## Acciones secundarias de la base (botón «Más» o Esc).
func menu_entries() -> Array:
	return [[Game.t("Science library", "Biblioteca científica"), "nav_research", func() -> void:
		Game.library_return = "hub"
		Game.go("library")]]

func samples() -> int:
	var total := 0
	var rocks: Dictionary = Game.discoveries.get("rocks", {})
	for id in rocks: total += int(rocks[id].get("sample", 0))
	return total

func switch_base() -> void:
	Game.location = "earth" if on_mars else "mars"
	Game.go("hub")

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
