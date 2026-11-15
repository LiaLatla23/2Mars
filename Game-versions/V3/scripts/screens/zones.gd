extends BaseScreen
## Panel de misiones (referencias 21 y 22): globo de Marte interactivo en tiempo real
## (arrastrar para girar, rueda para acercar) y las cuatro zonas de Jezero.
## El globo es una representación artística; las coordenadas de los lugares marcados son reales.

const LANDMARKS := [
	{"name": "Jezero", "lat": 18.4, "lon": 77.5, "main": true},
	{"name": "Gale (Curiosity)", "lat": -5.4, "lon": 137.8, "main": false},
	{"name": "Olympus Mons", "lat": 18.6, "lon": -133.8, "main": false},
	{"name": "Valles Marineris", "lat": -14.0, "lon": -59.0, "main": false}
]
const SPOTS := {"geology": Vector2(0.28, 0.18), "life": Vector2(-0.42, -0.1), "archive": Vector2(-0.12, -0.52), "frontier": Vector2(0.5, 0.56)}

var selected := "geology"
var card: Panel
var globe: ColorRect
var material_globe: ShaderMaterial
var spin := 0.4
var target_spin := 0.4
var tilt := 0.3
var zoom := 1.0
var dragging := false
var auto := true
var buttons := {}
const CENTER := Vector2(300, 370)
const RADIUS := 220.0

func _ready() -> void:
	backdrop = "stars"
	Game.mode = "campaign"
	selected = Game.zone if Data.ZONES.has(Game.zone) else "geology"
	globe = ColorRect.new()
	material_globe = ShaderMaterial.new()
	material_globe.shader = load("res://shaders/globe.gdshader")
	globe.material = material_globe
	globe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(globe)
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(func() -> void: draw_markers(overlay))
	add_child(overlay)
	portraits.append(overlay)
	var side := UIK.panel(self, Rect2(640, 0, 640, 720), Color("#22306b").lerp(UIK.NAVY, 0.55), 0)
	var head := UIK.heading(side, Game.t("MISSION PANEL", "PANEL DE MISIONES"), 40)
	head.position = Vector2(34, 16)
	var back := UIK.button(side, Game.t("GO BACK", "VOLVER"), func() -> void: Game.go("hub"), "ghost", Vector2(150, 44))
	back.position = Vector2(460, 26)
	var list := UIK.column(side, Rect2(34, 84, 572, 250), 8)
	for id in Data.ZONE_ORDER:
		var zone: Dictionary = Data.ZONES[id]
		var index: int = Data.ZONE_ORDER.find(id) + 1
		var b := UIK.button(list, "", func() -> void: pick(id), "dark", Vector2(572, 54))
		b.draw.connect(func() -> void:
			var open := Game.zone_unlocked(id)
			b.draw_style_box(UIK.box(Color(String(zone.color)), 10, UIK.INK, 2, 0), Rect2(8, 7, 40, 40))
			if open: b.draw_string(UIK.title_font, Vector2(8, 38), str(index), HORIZONTAL_ALIGNMENT_CENTER, 40, 26, UIK.INK)
			else: Art.icon(b, "lock", Vector2(28, 27), 26, UIK.INK)
			b.draw_string(UIK.title_font, Vector2(60, 26), Game.tt(zone.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 330, 20, UIK.PAPER)
			b.draw_string(UIK.body_font, Vector2(60, 45), Game.tt(zone.goal), HORIZONTAL_ALIGNMENT_LEFT, 330, 14, UIK.MINT)
			var state := Game.t("LOCKED", "BLOQUEADA") if not open else (Game.t("BEST %s", "MEJOR %s") % String(Game.progress[id].grade) if Game.progress.has(id) else Game.t("NEW", "NUEVA"))
			b.draw_string(UIK.bold_font, Vector2(400, 33), state, HORIZONTAL_ALIGNMENT_RIGHT, 160, 15, UIK.CREAM if open else UIK.MUTED)
			if id == selected: b.draw_style_box(UIK.box(Color.TRANSPARENT, 16, UIK.ORANGE, 4, 0), Rect2(Vector2.ZERO, b.size)))
		buttons[id] = b
	card = UIK.panel(side, Rect2(34, 340, 572, 362), UIK.PAPER, 16)
	var help := UIK.heading(self, Game.t("Drag to rotate · wheel to zoom", "Arrastra para girar · rueda para acercar") if Game.input_mode != "keyboard" else Game.t("Rotate with the ◀ ▶ buttons", "Gira con los botones ◀ ▶"), 16)
	help.position = Vector2(30, 24)
	var controls := UIK.row(self, 8)
	controls.position = Vector2(30, 660)
	UIK.button(controls, "◀", func() -> void: nudge(-0.5), "ghost", Vector2(52, 44))
	UIK.button(controls, "▶", func() -> void: nudge(0.5), "ghost", Vector2(52, 44))
	UIK.button(controls, Game.t("Find Jezero", "Ir a Jezero"), find_jezero, "primary", Vector2(170, 44))
	refresh()
	find_jezero()
	UIK.focus_first(list)

func nudge(amount: float) -> void:
	auto = false
	target_spin += amount

func find_jezero() -> void:
	auto = false
	var goal := deg_to_rad(77.5)
	target_spin = spin + wrapf(goal - spin, -PI, PI)

func pick(id: String) -> void:
	selected = id
	Game.sfx("attach")
	find_jezero()
	refresh()

func deploy() -> void:
	Game.zone = selected
	Game.go("plan")

func refresh() -> void:
	for child in card.get_children(): child.queue_free()
	var zone: Dictionary = Data.ZONES[selected]
	var unlocked := Game.zone_unlocked(selected)
	var content := UIK.scroll(card, Rect2(20, 12, 536, 270))
	content.add_theme_constant_override("separation", 5)
	var chips := UIK.row(content, 8)
	UIK.chip(chips, " %s " % Game.tt(zone.goal).to_upper(), Color(String(zone.color)))
	UIK.chip(chips, " %s  18.4°N 77.5°E " % Game.t("JEZERO CRATER", "CRÁTER JEZERO"), UIK.NAVY)
	UIK.label(content, Game.tt(zone.name), 28, UIK.NAVY, "title")
	UIK.text(content, Game.tt(zone.brief), 15, UIK.INK)
	UIK.label(content, Game.t("REQUIRED", "REQUERIDOS"), 13, UIK.RUST, "bold")
	for objective in zone.objectives:
		if not bool(objective.get("opt", false)): UIK.text(content, "•  " + Game.tt(objective.text), 15, UIK.INK)
	UIK.label(content, Game.t("OPTIONAL", "OPCIONALES"), 13, UIK.TEAL, "bold")
	for objective in zone.objectives:
		if bool(objective.get("opt", false)): UIK.text(content, "◦  " + Game.tt(objective.text), 15, UIK.MUTED)
	var hazard_names := {"sharp": ["sharp rocks", "rocas afiladas"], "devils": ["dust devils", "remolinos de polvo"], "sand": ["soft sand", "arena blanda"], "storm": ["dust storm", "tormenta de polvo"], "cold": ["cold shadows", "sombras frías"], "slope": ["slopes", "pendientes"]}
	var listed: Array = []
	for hazard in zone.hazards: listed.append(Game.tt(hazard_names[hazard]))
	UIK.text(content, Game.t("Terrain and hazards: ", "Terreno y riesgos: ") + ", ".join(listed), 14, UIK.RUST)
	UIK.text(content, Game.tt(zone.nasa), 13, UIK.TEAL)
	var launch := UIK.button(card, Game.t("PLAN THIS MISSION", "PLANIFICAR ESTA MISIÓN"), deploy, "go", Vector2(532, 56))
	launch.position = Vector2(20, 292)
	launch.add_theme_font_size_override("font_size", 22)
	launch.disabled = not unlocked
	if not unlocked:
		var previous: String = Data.ZONE_ORDER[Data.ZONE_ORDER.find(selected) - 1]
		launch.text = Game.t("Finish %s with grade C or better", "Termina %s con nota C o mejor") % Game.tt(Data.ZONES[previous].name)
		launch.add_theme_font_size_override("font_size", 16)
	UIK.pop(card)

func _gui_input(event: InputEvent) -> void:
	if Game.input_mode == "keyboard": return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed and event.position.distance_to(CENTER) < RADIUS * zoom + 20.0
			if dragging: auto = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom = minf(1.25, zoom + 0.06)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom = maxf(0.75, zoom - 0.06)
	elif event is InputEventMouseMotion and dragging:
		target_spin -= event.relative.x * 0.008
		spin = target_spin
		tilt = clampf(tilt + event.relative.y * 0.006, -0.9, 0.9)

func tick(delta: float) -> void:
	if auto and not Game.reduced_motion: target_spin += delta * 0.12
	spin = lerp(spin, target_spin, clampf(delta * 5.0, 0.0, 1.0)) if not Game.reduced_motion else target_spin
	var r := RADIUS * zoom
	globe.position = CENTER - Vector2(r, r) * 1.2
	globe.size = Vector2(r, r) * 2.4
	material_globe.set_shader_parameter("spin", spin)
	material_globe.set_shader_parameter("tilt", tilt)
	for id in buttons: buttons[id].queue_redraw()

## Proyección ortográfica inversa a la del shader. Devuelve [posición, visible].
func project(lat_deg: float, lon_deg: float) -> Array:
	var lat := deg_to_rad(lat_deg)
	var lon := deg_to_rad(lon_deg)
	var s := Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
	var cs := cos(spin)
	var ss := sin(spin)
	var n1 := Vector3(s.x * cs - s.z * ss, s.y, s.x * ss + s.z * cs)
	var ct := cos(tilt)
	var st := sin(tilt)
	var n0 := Vector3(n1.x, n1.y * ct + n1.z * st, -n1.y * st + n1.z * ct)
	return [CENTER + Vector2(n0.x, -n0.y) * RADIUS * zoom, n0.z > 0.05]

func draw_markers(canvas: Control) -> void:
	var jezero := Vector2.ZERO
	var jezero_visible := false
	for mark in LANDMARKS:
		var result := project(float(mark.lat), float(mark.lon))
		if not result[1]: continue
		var at: Vector2 = result[0]
		if mark.main:
			jezero = at
			jezero_visible = true
			var pulse := 12.0 + (sin(time * 3.0) * 4.0 if not Game.reduced_motion else 0.0)
			canvas.draw_circle(at, pulse + 6.0, Color(UIK.ORANGE, 0.3))
			canvas.draw_circle(at, 8.0, UIK.ORANGE)
			canvas.draw_arc(at, pulse, 0, TAU, 24, UIK.PAPER, 2.5, true)
		else:
			canvas.draw_circle(at, 5.0, UIK.MINT)
			canvas.draw_string_outline(UIK.bold_font, at + Vector2(10, 5), String(mark.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 5, UIK.INK)
			canvas.draw_string(UIK.bold_font, at + Vector2(10, 5), String(mark.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIK.PAPER)
	# Recuadro ampliado del cráter con las cuatro zonas
	var inset := Vector2(500, 590)
	var r := 104.0
	if jezero_visible: canvas.draw_line(jezero, inset - (inset - jezero).normalized() * r, Color(UIK.ORANGE, 0.8), 2.0)
	canvas.draw_circle(inset, r + 6.0, UIK.INK)
	canvas.draw_colored_polygon(Art.blob(inset, r, r, 4, 16, 0.04), Color("#d9805a"))
	canvas.draw_colored_polygon(Art.blob(inset + Vector2(6, 6), r * 0.74, r * 0.72, 6, 12, 0.1), Color("#c66a47"))
	canvas.draw_colored_polygon(PackedVector2Array([inset + Vector2(-r * 0.86, -r * 0.2), inset + Vector2(-r * 0.4, -r * 0.5), inset + Vector2(0, -r * 0.3), inset + Vector2(-r * 0.1, r * 0.1), inset + Vector2(-r * 0.6, r * 0.2)]), Color("#e3a877"))
	for id in Data.ZONE_ORDER:
		var spot: Vector2 = inset + SPOTS[id] * r
		var zone: Dictionary = Data.ZONES[id]
		var open := Game.zone_unlocked(id)
		var size_px := 15.0 + (3.0 * sin(time * 4.0) if id == selected and not Game.reduced_motion else 0.0)
		canvas.draw_circle(spot, size_px + 3.0, UIK.INK)
		canvas.draw_circle(spot, size_px, Color(String(zone.color)) if open else UIK.MUTED)
		canvas.draw_string(UIK.title_font, spot + Vector2(-12, 7), str(Data.ZONE_ORDER.find(id) + 1), HORIZONTAL_ALIGNMENT_CENTER, 24, 18, UIK.INK)
		if id == selected: canvas.draw_arc(spot, size_px + 7.0, 0, TAU, 24, UIK.PAPER, 3.0, true)
	canvas.draw_string_outline(UIK.bold_font, inset + Vector2(-r, -r - 12), Game.t("JEZERO CRATER", "CRÁTER JEZERO"), HORIZONTAL_ALIGNMENT_CENTER, r * 2, 15, 6, UIK.INK)
	canvas.draw_string(UIK.bold_font, inset + Vector2(-r, -r - 12), Game.t("JEZERO CRATER", "CRÁTER JEZERO"), HORIZONTAL_ALIGNMENT_CENTER, r * 2, 15, UIK.PAPER)
