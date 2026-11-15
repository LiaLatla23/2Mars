extends Control
## Mapa de la campaña: cuatro zonas, una por objetivo científico de Perseverance.
## Las zonas bloqueadas también se pueden consultar.

const SPOTS := {"geology": Vector2(430, 420), "life": Vector2(250, 330), "archive": Vector2(330, 190), "frontier": Vector2(520, 560)}

var selected := "geology"
var card: Panel
var time := 0.0
var markers := {}

func _ready() -> void:
	selected = Game.zone if Data.ZONES.has(Game.zone) else "geology"
	var title := UIK.label(self, Game.t("Mission map", "Mapa de misión"), 44, UIK.NAVY, "title")
	title.position = Vector2(48, 24)
	var sub := UIK.label(self, Game.t("Four zones, four science goals. Pick where to send %s.", "Cuatro zonas, cuatro metas científicas. Elige a dónde enviar a %s.") % Game.rover_name, 19, UIK.MUTED)
	sub.position = Vector2(50, 80)
	for id in Data.ZONE_ORDER:
		var index: int = Data.ZONE_ORDER.find(id) + 1
		var marker := UIK.button(self, str(index), func() -> void: pick(id), "dark", Vector2(58, 58))
		marker.position = SPOTS[id] - Vector2(29, 29)
		marker.add_theme_font_size_override("font_size", 26)
		markers[id] = marker
	var back := UIK.button(self, Game.t("← Menu", "← Menú"), func() -> void: Game.go("menu"), "ghost", Vector2(150, 48))
	back.position = Vector2(48, 648)
	card = UIK.panel(self, Rect2(700, 110, 540, 580))
	refresh()
	var complete := true
	for id in Data.ZONE_ORDER:
		if not Game.progress.has(id): complete = false
	if complete:
		var banner := UIK.label(self, Game.t("Campaign complete · %d science points received on Earth. Dr. Owen: \"Four zones, one story. Well done.\"", "Campaña completa · %d puntos de ciencia recibidos en la Tierra. Dra. Owen: \"Cuatro zonas, una historia. Bien hecho.\"") % Game.total_science(), 16, UIK.PAPER, "bold")
		banner.add_theme_stylebox_override("normal", UIK.box(UIK.GOOD, 14, Color.TRANSPARENT, 0, 4))
		banner.position = Vector2(230, 652)

func pick(id: String) -> void:
	selected = id
	refresh()

func open_design() -> void:
	Game.zone = selected
	Game.go("design")

func refresh() -> void:
	for child in card.get_children(): child.queue_free()
	var zone: Dictionary = Data.ZONES[selected]
	var unlocked := Game.zone_unlocked(selected)
	var column := UIK.column(card, Rect2(26, 20, 488, 470), 8)
	var chips := UIK.row(column, 8)
	UIK.chip(chips, " %s " % Game.tt(zone.goal).to_upper(), Color(zone.color))
	if Game.progress.has(selected): UIK.chip(chips, " %s %s " % [Game.t("BEST GRADE", "MEJOR NOTA"), Game.progress[selected].grade], UIK.NAVY)
	elif not unlocked: UIK.chip(chips, " %s " % Game.t("LOCKED", "BLOQUEADA"), UIK.MUTED)
	UIK.label(column, Game.tt(zone.name), 36, UIK.NAVY, "title")
	UIK.text(column, Game.tt(zone.nasa), 16, UIK.TEAL)
	UIK.text(column, Game.tt(zone.brief), 18, UIK.INK)
	UIK.label(column, Game.t("MISSION OBJECTIVES", "OBJETIVOS DE MISIÓN"), 15, UIK.MUTED, "bold")
	for objective in zone.objectives: UIK.text(column, "•  " + Game.tt(objective.text), 17, UIK.INK)
	var hazard_names := {"sharp": ["sharp rocks", "rocas afiladas"], "devils": ["dust devils", "remolinos de polvo"], "sand": ["soft sand", "arena blanda"], "storm": ["dust storm", "tormenta de polvo"], "cold": ["cold shadows", "sombras frías"]}
	var listed: Array = []
	for hazard in zone.hazards: listed.append(Game.tt(hazard_names[hazard]))
	UIK.text(column, Game.t("Hazards: ", "Riesgos: ") + ", ".join(listed) + Game.t("  ·  Mission time: ", "  ·  Tiempo de misión: ") + "%d:%02d" % [int(zone.time) / 60, int(zone.time) % 60], 16, UIK.CORAL)
	var launch := UIK.button(card, Game.t("Design the mission →", "Diseñar la misión →"), open_design, "primary", Vector2(488, 58))
	launch.position = Vector2(26, 500)
	launch.disabled = not unlocked
	if not unlocked:
		var previous: String = Data.ZONE_ORDER[Data.ZONE_ORDER.find(selected) - 1]
		launch.text = Game.t("Finish %s with grade C or better", "Termina %s con nota C o mejor") % Game.tt(Data.ZONES[previous].name)
	UIK.pop(card)
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	Art.gradient(self, Rect2(Vector2.ZERO, size), Color("#fff1d6"), Color("#f6cf9f"))
	var center := Vector2(370, 390)
	draw_colored_polygon(Art.blob(center + Vector2(14, 16), 330, 270, 4, 13, 0.1), Color(0.5, 0.25, 0.15, 0.18))
	draw_colored_polygon(Art.blob(center, 330, 270, 4, 13, 0.1), Color("#d9805a"))
	draw_colored_polygon(Art.blob(center + Vector2(20, 20), 250, 196, 6, 11, 0.12), Color("#c66a47"))
	var fan := PackedVector2Array([Vector2(110, 300), Vector2(210, 230), Vector2(330, 270), Vector2(360, 360), Vector2(290, 430), Vector2(180, 400)])
	draw_colored_polygon(fan, Color("#e3a877"))
	draw_colored_polygon(PackedVector2Array([fan[0], fan[1], fan[2], Vector2(230, 320)]), Color("#ecb98a"))
	draw_polyline(PackedVector2Array([Vector2(60, 250), Vector2(120, 290), Vector2(200, 310), Vector2(270, 345)]), Color("#f6d9b5"), 5.0, true)
	draw_colored_polygon(Art.blob(Vector2(520, 560), 120, 70, 9, 9, 0.12), Color("#cf7650"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(16):
		var angle := TAU * i / 16.0
		Art.rock(self, center + Vector2(cos(angle) * 318, sin(angle) * 258), rng.randf_range(18, 34), 40 + i, Color("#b9573d"))
	for id in Data.ZONE_ORDER:
		var spot: Vector2 = SPOTS[id]
		var zone: Dictionary = Data.ZONES[id]
		var ring := 40.0 + (sin(time * 3.0) * 4.0 if id == selected else 0.0)
		draw_circle(spot, ring, Color(Color(zone.color), 0.35 if id == selected else 0.16))
		if id == selected: draw_arc(spot, ring + 4, 0, TAU, 40, Color(zone.color), 4.0, true)
		draw_string(UIK.bold_font, spot + Vector2(-120, 58), Game.tt(zone.goal), HORIZONTAL_ALIGNMENT_CENTER, 240, 17, UIK.NAVY)
		if Game.progress.has(id): draw_string(UIK.title_font, spot + Vector2(22, -22), String(Game.progress[id].grade), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UIK.GOOD)
		elif not Game.zone_unlocked(id): draw_string(UIK.bold_font, spot + Vector2(-120, 76), Game.t("locked", "bloqueada"), HORIZONTAL_ALIGNMENT_CENTER, 240, 14, UIK.MUTED)
