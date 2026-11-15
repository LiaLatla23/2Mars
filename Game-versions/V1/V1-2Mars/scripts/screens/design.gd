extends Control
## ETAPA 1 · MISSION DESIGN. El jugador arma el rover dentro de un límite de masa y
## presupuesto. La Dra. Owen explica qué objetivos de la zona podrá cumplir ese diseño.

var build: Dictionary
var left: VBoxContainer
var right: Panel
var detail: Label
var name_box: LineEdit
var time := 0.0
var part_buttons := {}

func _ready() -> void:
	build = Game.build.duplicate(true)
	var zone: Dictionary = Data.ZONES[Game.zone]
	var title := UIK.label(self, Game.t("Mission design", "Diseño de misión"), 40, UIK.NAVY, "title")
	title.position = Vector2(36, 14)
	var where := UIK.chip(self, "  %s · %s  " % [Game.tt(zone.goal).to_upper(), Game.tt(zone.name)], Color(zone.color))
	where.position = Vector2(52 + title.get_minimum_size().x, 30)
	var parts_panel := UIK.panel(self, Rect2(24, 74, 440, 630))
	left = UIK.scroll(parts_panel, Rect2(16, 12, 412, 606))
	left.add_theme_constant_override("separation", 5)
	for slot in Data.PART_ORDER:
		UIK.label(left, Game.tt(Data.PARTS[slot].title).to_upper(), 14, UIK.MUTED, "bold")
		var line := UIK.row(left, 8)
		for option in Data.PARTS[slot].options:
			var info: Dictionary = Data.PARTS[slot].options[option]
			var button := UIK.button(line, Game.tt(info.name), func() -> void: choose(slot, option), "ghost", Vector2(126, 40))
			button.add_theme_font_size_override("font_size", 14)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
			button.mouse_entered.connect(func() -> void: describe(Game.tt(info.name), Game.tt(info.note), int(info.mass), int(info.cost)))
			part_buttons[slot + ":" + option] = button
	UIK.label(left, Game.t("SCIENCE PAYLOAD", "CARGA CIENTÍFICA"), 14, UIK.MUTED, "bold")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	left.add_child(grid)
	for id in Data.INSTRUMENT_ORDER:
		var info: Dictionary = Data.INSTRUMENTS[id]
		var button := UIK.button(grid, Data.instrument_name(id), func() -> void: toggle(id), "ghost", Vector2(198, 40))
		button.add_theme_font_size_override("font_size", 15)
		button.clip_text = true
		button.mouse_entered.connect(func() -> void: describe(Data.instrument_name(id), Game.t("Real instrument: ", "Instrumento real: ") + Game.tt(info.real) + "\n" + Game.t("In the game: ", "En el juego: ") + Game.tt(info.game), int(info.mass), int(info.cost)))
		part_buttons["instrument:" + id] = button
	var middle := UIK.panel(self, Rect2(478, 440, 360, 264), UIK.PAPER)
	var middle_column := UIK.column(middle, Rect2(18, 12, 324, 240), 6)
	UIK.label(middle_column, Game.t("ROVER NAME", "NOMBRE DEL ROVER"), 13, UIK.MUTED, "bold")
	name_box = LineEdit.new()
	name_box.text = Game.rover_name
	name_box.max_length = 14
	name_box.add_theme_font_override("font", UIK.bold_font)
	name_box.add_theme_font_size_override("font_size", 20)
	name_box.add_theme_color_override("font_color", UIK.NAVY)
	name_box.add_theme_stylebox_override("normal", UIK.box(UIK.CREAM, 12, UIK.MINT, 2, 0))
	name_box.add_theme_stylebox_override("focus", UIK.box(UIK.CREAM, 12, UIK.TEAL, 2, 0))
	middle_column.add_child(name_box)
	detail = UIK.text(middle_column, Game.t("Point at a part to see what it does on Mars and what it costs you.", "Señala una pieza para ver qué hace en Marte y qué te cuesta."), 15, UIK.INK)
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right = UIK.panel(self, Rect2(852, 74, 404, 630))
	var back := UIK.button(self, Game.t("← Map", "← Mapa"), func() -> void: Game.go("zones"), "ghost", Vector2(120, 42))
	back.position = Vector2(1136, 20)
	refresh()

func describe(title: String, body: String, mass: int, cost: int) -> void:
	detail.text = "%s  ·  %d kg  ·  %d cr\n%s" % [title, mass, cost, body]

func choose(slot: String, option: String) -> void:
	build[slot] = option
	refresh()

func toggle(id: String) -> void:
	var list: Array = build.get("instruments", []).duplicate()
	if id in list:
		list.erase(id)
		if id == "arm":
			list.erase("pixl")
			list.erase("sherloc")
	else:
		list.append(id)
		if id in ["pixl", "sherloc"] and not "arm" in list: list.append("arm")
	build["instruments"] = list
	refresh()

func mark(button: Button, active: bool) -> void:
	var color := UIK.TEAL if active else UIK.PAPER
	var normal := UIK.box(color, 14, UIK.MINT, 0 if active else 2, 3)
	var hover := UIK.box(color.lightened(0.1), 14, UIK.TEAL, 2, 5)
	for style in [normal, hover]: style.set_content_margin_all(7)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]: button.add_theme_color_override(state, UIK.PAPER if active else UIK.NAVY)

func refresh() -> void:
	for key in part_buttons:
		var parts: PackedStringArray = String(key).split(":")
		var active: bool = (parts[1] in build.get("instruments", [])) if parts[0] == "instrument" else String(build.get(parts[0], "")) == parts[1]
		mark(part_buttons[key], active)
	for child in right.get_children(): child.queue_free()
	var mass := Data.mass(build)
	var cost := Data.cost(build)
	var stats := Data.stats(build)
	var column := UIK.column(right, Rect2(22, 16, 360, 520), 6)
	meter(column, Game.t("MASS", "MASA"), mass, Data.MASS_CAP, "kg")
	meter(column, Game.t("BUDGET", "PRESUPUESTO"), cost, Data.BUDGET, "cr")
	UIK.text(column, Game.t("Speed %d · Battery %d · Memory %d MB · %s", "Velocidad %d · Batería %d · Memoria %d MB · %s") % [int(stats.speed), int(stats.battery), int(stats.memory), Game.t("direct link", "enlace directo") if stats.direct else Game.t("orbiter passes only", "solo pasos de orbitador")], 15, UIK.MUTED)
	UIK.label(column, Game.t("WHAT THIS ROVER CAN DO HERE", "QUÉ PUEDE HACER ESTE ROVER AQUÍ"), 14, UIK.MUTED, "bold")
	var missing := 0
	for note in Data.readiness(build, Game.zone):
		var line := "✓  " + Game.tt(note.text)
		if not note.ok:
			missing += 1
			line = "✗  %s (%s)" % [Game.tt(note.text), Game.tt(note.why)]
		UIK.text(column, line, 15, UIK.GOOD if note.ok else UIK.BAD)
	var advice := owen_advice(mass, cost, missing, stats)
	UIK.text(column, "Dr. Owen: " + advice if Game.lang == "en" else "Dra. Owen: " + advice, 16, UIK.INK)
	var over := mass > Data.MASS_CAP or cost > Data.BUDGET
	var launch := UIK.button(right, Game.t("Launch to Mars →", "Lanzar a Marte →") if not over else Game.t("Over the limit", "Fuera de límite"), launch_mission, "primary", Vector2(360, 60))
	launch.position = Vector2(22, 552)
	launch.disabled = over

func meter(parent: Node, caption: String, value: int, limit: int, unit: String) -> void:
	var over := value > limit
	UIK.label(parent, "%s   %d / %d %s" % [caption, value, limit, unit], 17, UIK.BAD if over else UIK.NAVY, "bold")
	var bar := ProgressBar.new()
	bar.max_value = limit
	bar.value = mini(value, limit)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.add_theme_stylebox_override("background", UIK.box(Color(UIK.NAVY, 0.15), 8, Color.TRANSPARENT, 0, 0))
	bar.add_theme_stylebox_override("fill", UIK.box(UIK.BAD if over else (UIK.SAND if value > limit * 0.85 else UIK.TEAL), 8, Color.TRANSPARENT, 0, 0))
	parent.add_child(bar)

func owen_advice(mass: int, cost: int, missing: int, stats: Dictionary) -> String:
	if mass > Data.MASS_CAP: return Game.t("The launch vehicle cannot lift this rover. Every instrument you add is mass that something else must give up.", "El vehículo de lanzamiento no puede con este rover. Cada instrumento que agregas es masa que otra cosa debe ceder.")
	if cost > Data.BUDGET: return Game.t("We are over budget. Decide which capability the science really needs.", "Estamos sobre el presupuesto. Decide qué capacidad necesita de verdad la ciencia.")
	if missing > 0: return Game.t("You can launch, but some objectives will be out of reach. An instrument left on Earth cannot make discoveries.", "Puedes lanzar, pero algunos objetivos quedarán fuera de alcance. Un instrumento que se queda en la Tierra no descubre nada.")
	if stats.solar and "cold" in Data.ZONES[Game.zone].hazards: return Game.t("Solar panels give nothing at night, and these plains get very cold. Plan your energy.", "Los paneles solares no dan nada de noche, y esta llanura es muy fría. Planifica tu energía.")
	if not stats.direct and float(stats.memory) < 100: return Game.t("Small memory and no direct link: you will wait for orbiter passes with a full recorder. It works, with patience.", "Poca memoria y sin enlace directo: esperarás al orbitador con la grabadora llena. Funciona, con paciencia.")
	return Game.t("A balanced design. Every engineering decision shapes what the mission can discover.", "Un diseño equilibrado. Cada decisión de ingeniería define lo que la misión puede descubrir.")

func launch_mission() -> void:
	var typed := name_box.text.strip_edges()
	Game.rover_name = typed if typed != "" else "ARES 01"
	Game.build = build.duplicate(true)
	Game.save()
	Game.go("ops")

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	Art.gradient(self, Rect2(Vector2.ZERO, size), Color("#fff1d6"), Color("#f6cf9f"))
	var center := Vector2(658, 262)
	draw_colored_polygon(Art.blob(center + Vector2(0, 26), 170, 112, 3, 12, 0.06), Color("#d9805a"))
	draw_colored_polygon(Art.blob(center + Vector2(0, 14), 170, 112, 3, 12, 0.06), Color("#e9a06f"))
	Art.rock(self, center + Vector2(-150, 70), 22, 12, Color("#b9573d"))
	Art.rock(self, center + Vector2(140, -70), 16, 14, Color("#b9573d"))
	Art.rover(self, center + Vector2(0, 8), -0.5 + sin(time * 0.5) * 0.35, build, 3.6, time)
