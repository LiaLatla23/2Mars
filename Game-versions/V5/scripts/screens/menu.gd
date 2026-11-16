extends BaseScreen
## Menú principal (referencias 1 y 7, V4): logotipo destacado, paisaje 3D de Marte con
## movimiento suave (vaivén de cámara, baliza, planeta) y acciones claras con iconos.

var settings: Node

func _ready() -> void:
	stage_backdrop("vista")
	var art := logo(Rect2(350, 2, 580, 368))
	if not Game.reduced_motion:
		var float_tween := art.create_tween().set_loops()
		float_tween.tween_property(art, "position:y", 12.0, 2.4).set_trans(Tween.TRANS_SINE)
		float_tween.tween_property(art, "position:y", 2.0, 2.4).set_trans(Tween.TRANS_SINE)
	var has_save := Game.any_slot_used()
	var column := UIK.column(self, Rect2(430, 364, 420, 344), 8)
	if has_save:
		var resume := UIK.icon_button(column, Game.t("CONTINUE", "CONTINUAR"), "nav_rovers", func() -> void: Game.go("profiles"), "primary", Vector2(420, 66))
		resume.add_theme_font_size_override("font_size", 28)
		resume.alignment = HORIZONTAL_ALIGNMENT_CENTER
		Motion.shine(resume, 4.5, 0.26)
	var start := UIK.icon_button(column, Game.t("START NEW GAME", "PARTIDA NUEVA"), "nav_launch", func() -> void: Game.go("profiles"), "primary" if not has_save else "yellow", Vector2(420, 58))
	start.add_theme_font_size_override("font_size", 24 if not has_save else 22)
	start.alignment = HORIZONTAL_ALIGNMENT_CENTER
	# V5 · modo de juego (cooperativo) y logros viven aquí, no en la base
	var pair := UIK.row(column, 10)
	UIK.icon_button(pair, (Game.t("Co-op: %s", "Coop: %s") % Game.coop_name()) if Game.coop else Game.t("Co-op", "Cooperativo"), "pin_main", open_coop, "yellow" if Game.coop else "ghost", Vector2(205, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.icon_button(pair, Game.t("Sandbox", "Sandbox"), "nav_workshop", open_sandbox, "teal", Vector2(205, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pair2 := UIK.row(column, 10)
	UIK.icon_button(pair2, Game.t("Achievements", "Logros"), "nav_achievements", func() -> void: Game.go("achievements"), "ghost", Vector2(205, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.icon_button(pair2, Game.t("Library", "Biblioteca"), "nav_research", func() -> void:
		Game.library_return = "menu"
		Game.go("library"), "ghost", Vector2(205, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pair3 := UIK.row(column, 10)
	UIK.icon_button(pair3, Game.t("Credits", "Créditos"), "medal_excellence", open_credits, "ghost", Vector2(205, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.icon_button(pair3, Game.t("Settings", "Ajustes"), "nav_settings", open_settings, "ghost", Vector2(205, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Salir del juego es una acción aparte y explícita, con confirmación. En el navegador no existe:
	# allí la pestaña es la salida, y quit() dejaría el juego parado.
	if not OS.has_feature("web"):
		var quit := UIK.button(self, Game.t("Quit game", "Salir del juego"), ask_quit, "ghost", Vector2(150, 40))
		quit.position = Vector2(1108, 664)
	var team := UIK.heading(self, "SpaceNuts", 20, UIK.CREAM)
	team.position = Vector2(24, 672)
	var version := UIK.label(self, "V5 · %s" % String(ProjectSettings.get_setting("application/config/version", "")), 13, Color(UIK.PAPER, 0.8), "bold")
	version.position = Vector2(150, 682)
	if Game.save_notice != "": explain_save.call_deferred()
	Motion.stagger(column.get_children(), 0.035)
	UIK.focus_first(column)

func _init() -> void:
	menu_exit = false

## El menú principal no tiene «menú de Esc»: Esc solo cierra el panel abierto.
func open_menu() -> void:
	pass

func ask_quit() -> void:
	UIK.close_modal(self)
	var content := UIK.modal(self, Vector2(520, 250), Game.t("Quit the game?", "¿Salir del juego?"))
	UIK.text(content, Game.t("Your progress is already saved.", "Tu progreso ya está guardado."), 16, UIK.MUTED)
	var line := UIK.row(content, 10)
	UIK.button(line, Game.t("Stay", "Seguir jugando"), func() -> void: UIK.close_modal(self), "go", Vector2(220, 48))
	UIK.button(line, Game.t("Quit", "Salir"), func() -> void: get_tree().quit(), "ghost", Vector2(180, 48))
	UIK.focus_first(line)

## Aviso único cuando el guardado estaba dañado: qué pasó y qué se conservó.
func explain_save() -> void:
	var recovered := Game.save_notice == "recovered"
	Game.save_notice = ""
	var content := UIK.modal(self, Vector2(680, 320), Game.t("About your save file", "Sobre tu guardado"))
	UIK.text(content, Game.t("The save file could not be read, so 2Mars loaded the previous copy. At most your last session's changes are missing.", "El archivo de guardado no se pudo leer, así que 2Mars cargó la copia anterior. Como mucho faltan los cambios de tu última sesión.") if recovered else Game.t("The save file could not be read and there was no usable copy. Nothing was deleted: the unreadable file is kept next to the save as “.corrupt”.", "El archivo de guardado no se pudo leer y no había una copia utilizable. No se ha borrado nada: el archivo ilegible se conserva junto al guardado como «.corrupt»."), 16, UIK.INK)
	var line := UIK.row(content, 10)
	UIK.button(line, Game.t("Understood", "Entendido"), func() -> void: UIK.close_modal(self), "go", Vector2(220, 48))
	UIK.focus_first(line)

## Modo de juego: un jugador o uno de los dos cooperativos locales (misma computadora).
func open_coop() -> void:
	UIK.close_modal(self)
	var content := UIK.modal(self, Vector2(1200, 640), Game.t("Game mode", "Modo de juego"))
	UIK.text(content, Game.t("Local co-op: two players on the same computer and the same rover. No online play.", "Cooperativo local: dos jugadores en la misma computadora y el mismo rover. Sin juego en línea."), 15, UIK.MUTED)
	var cards := UIK.row(content, 12)
	for item in [["solo", Game.t("ONE PLAYER", "UN JUGADOR"), UIK.NAVY, "pin_rover", Game.t("You plan, build, drive and do the science.", "Tú planificas, construyes, conduces y haces la ciencia."), [Game.t("Keyboard or mouse", "Teclado o ratón")]],
		["crew", Game.t("CREW · driver + scientist", "TRIPULACIÓN · conductor y científico"), UIK.P1, "pin_main", Game.t("Player 1 drives and keeps the rover safe. Player 2 runs the science from the mouse panel.", "El jugador 1 conduce y cuida el rover. El jugador 2 hace la ciencia desde el panel del ratón."),
			[Game.t("P1 · keyboard: W A S D or arrows, T transmit", "J1 · teclado: W A S D o flechas, T transmitir"), Game.t("P2 · mouse: pick rocks, run instruments, send signals", "J2 · ratón: elige rocas, usa instrumentos, envía señales"), Game.t("Signals: come here · stop · target ready · danger", "Señales: ven aquí · detente · objetivo listo · peligro")]],
		["expedition", Game.t("EXPEDITION · two rovers", "EXPEDICIÓN · dos rovers"), UIK.TEAL, "pin_rover", Game.t("Each player drives a rover on a split screen. One mission, shared science.", "Cada jugador conduce un rover en pantalla dividida. Una misión, ciencia compartida."),
			[Game.t("P1: W A S D · E · Space · T", "J1: W A S D · E · Espacio · T"), Game.t("P2: arrows · period · Enter · comma", "J2: flechas · punto · Intro · coma"), Game.t("Energy and health belong to each rover", "Energía y salud son de cada rover")]],
		["roles", Game.t("SHARED KEYBOARD", "TECLADO COMPARTIDO"), UIK.P2, "nav_rovers", Game.t("Both on the keyboard, with separate keys and three shared decisions.", "Los dos al teclado, con teclas separadas y tres decisiones compartidas."),
			[Game.t("Commander: arrows, T, Enter", "Comandante: flechas, T, Intro"), Game.t("Engineer: E, 1-6, Space, M O R G, F", "Ingeniero: E, 1-6, Espacio, M O R G, F"), Game.t("Both confirm plan, design and mission end", "Los dos confirman plan, diseño y fin de misión")]]]:
		var id := String(item[0])
		var active := (id == "solo" and not Game.coop) or (Game.coop and Game.coop_mode == id)
		var card := UIK.card(cards, String(item[1]), item[2], UIK.CREAM if active else UIK.PAPER)
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.get_parent().custom_minimum_size = Vector2(270, 380)
		UIK.picture(card, UIK.tex(String(item[3])), Vector2(72, 72))
		UIK.text(card, String(item[4]), 15, UIK.INK)
		for line in item[5]: UIK.text(card, "· " + String(line), 14, UIK.NAVY)
		var pick := UIK.button(card, Game.t("Selected", "Elegido") if active else Game.t("Choose", "Elegir"), func() -> void:
			Game.coop = id != "solo"
			if id != "solo": Game.coop_mode = id
			Game.go("menu"), "go" if active else "primary", Vector2(180, 44))
		pick.size_flags_vertical = Control.SIZE_SHRINK_END
	var line2 := UIK.row(content, 10)
	UIK.button(line2, Game.t("Back", "Volver"), func() -> void: UIK.close_modal(self), "ghost", Vector2(180, 44))
	UIK.focus_first(line2)

## Créditos del equipo e información. No confundir con CR (créditos de misión, la unidad del juego).
func open_credits() -> void:
	UIK.close_modal(self)
	var content := UIK.modal(self, Vector2(900, 640), Game.t("Credits", "Créditos"))
	content.add_theme_constant_override("separation", 6)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(848, 480)
	content.add_child(holder)
	var list := UIK.scroll(holder, Rect2(0, 0, 848, 480))
	var top := UIK.row(list, 16)
	var mark := UIK.column(top, Rect2(0, 0, 0, 0), 0)
	mark.custom_minimum_size.x = 300
	var logo := UIK.tex("res://assets/brand/spacenuts_logo.jpg")
	if logo != null:
		var art := UIK.picture(mark, logo, Vector2(300, 150))     # logo original del equipo, con su proporción
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIK.label(mark, "SpaceNuts", 30, UIK.RUST, "title")
	UIK.label(mark, "Panama Team", 20, UIK.NAVY, "title")
	UIK.label(mark, "NASA Space Apps Challenge 2026", 13, UIK.MUTED, "bold")
	var names := GridContainer.new()
	names.columns = 2
	names.add_theme_constant_override("h_separation", 26)
	names.add_theme_constant_override("v_separation", 4)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(names)
	for person in Data.TEAM: UIK.label(names, String(person), 20, UIK.INK, "bold")
	var info := UIK.card(list, Game.t("INFORMATION", "INFORMACIÓN"), UIK.TEAL)
	UIK.text(info, Game.t("Code developed with artificial intelligence assistance.", "Código desarrollado con asistencia de inteligencia artificial."), 16, UIK.INK)
	UIK.text(info, Game.t("The game's concept, direction and decisions belong to the team.", "El concepto, la dirección y las decisiones del juego son del equipo."), 14, UIK.MUTED)
	var made := UIK.card(list, Game.t("MADE WITH", "HECHO CON"), UIK.ORANGE)
	for line in Data.CREDIT_LINES: UIK.text(made, "· " + Game.tt(line), 14, UIK.INK)
	var nasa := UIK.card(list, "NASA", UIK.RUST)
	UIK.text(nasa, Game.t("2Mars uses public NASA and NASA/JPL information about Mars 2020 Perseverance. NASA does not endorse or sponsor this game. Every source is listed in the Library.", "2Mars usa información pública de la NASA y NASA/JPL sobre Mars 2020 Perseverance. La NASA no avala ni patrocina este juego. Todas las fuentes están en la Biblioteca."), 14, UIK.INK)
	var line3 := UIK.row(content, 10)
	UIK.button(line3, Game.t("Back", "Volver"), func() -> void: UIK.close_modal(self), "go", Vector2(180, 46))
	UIK.button(line3, Game.t("NASA sources", "Fuentes NASA"), func() -> void:
		Game.library_return = "menu"
		Game.library_tab = "sources"
		Game.go("library"), "ghost", Vector2(220, 46))
	UIK.focus_first(line3)

func open_settings() -> void:
	Settings.open(self, func() -> void: Game.go("menu"))

func open_sandbox() -> void:
	Game.mode = "sandbox"
	Game.coop = false
	Game.zone = String(Game.sandbox.get("zone", "geology"))
	Game.go("design")
