extends BaseScreen
## Panel de misiones (referencias 21 y 22, V4): globo de Marte en 3D real (geometría y cámara
## ortográfica; arrastrar para girar, rueda para acercar), ruta de zonas con su progreso y la
## misión elegida con objetivos por iconos, requisitos y despliegue.
## El globo es una representación artística; las coordenadas de los lugares marcados son reales.

const LANDMARKS := [
	{"name": "Jezero", "lat": 18.4, "lon": 77.5, "main": true},
	{"name": "Gale (Curiosity)", "lat": -5.4, "lon": 137.8, "main": false},
	{"name": "Olympus Mons", "lat": 18.6, "lon": -133.8, "main": false},
	{"name": "Valles Marineris", "lat": -14.0, "lon": -59.0, "main": false}
]
const SPOTS := {"geology": Vector2(0.28, 0.18), "life": Vector2(-0.42, -0.1), "archive": Vector2(-0.12, -0.52), "frontier": Vector2(0.5, 0.56)}
const GOAL_ICON := {"imaged": "comp_camera", "angles": "up_scanning", "chem_types": "comp_analyzer", "pixl": "comp_analyzer", "received": "up_range", "aqueous": "nav_research", "sherloc": "comp_sensor", "quiz": "pin_main",
	"cache_types": "mat_canister", "cache_documented": "comp_camera", "meda": "up_efficiency", "moxie": "up_production", "rimfax": "up_scanning", "regolith": "ore_regolith"}
const HAZARD := {"sharp": ["Sharp rocks", "Rocas afiladas"], "devils": ["Dust devils", "Remolinos"], "sand": ["Soft sand", "Arena blanda"], "storm": ["Dust storm", "Tormenta"], "cold": ["Cold shadows", "Sombras frías"], "slope": ["Slopes", "Pendientes"]}

var selected := "geology"
var card: Panel
var globe: Stage3D
var ball: MeshInstance3D
var spin := 0.4
var target_spin := 0.4
var sub := "main"            # subnivel mostrado en la ficha
var tilt := 0.3
var target_tilt := 0.3
var focusing := false
var zoom := 1.0
var dragging := false
var auto := true
var buttons := {}
const CENTER := Vector2(300, 370)
const RADIUS := 220.0

func grade_steps(id: String) -> int:
	if not Game.progress.has(id): return 0
	return {"S": 4, "A": 3, "B": 2, "C": 2}.get(String(Game.progress[id].get("grade", "D")), 1)

func _ready() -> void:
	backdrop = "stars"
	Game.mode = "campaign"
	selected = Game.zone if Data.ZONES.has(Game.zone) else "geology"
	globe = Stage3D.make(self, Rect2(CENTER - Vector2(RADIUS, RADIUS) * 1.2, Vector2(RADIUS, RADIUS) * 2.4), true)
	ball = globe.globe()
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(func() -> void: draw_markers(overlay))
	add_child(overlay)
	portraits.append(overlay)
	var side := UIK.panel(self, Rect2(640, 0, 640, 720), Color("#22306b").lerp(UIK.NAVY, 0.55), 0)
	var head := UIK.heading(side, Game.t("MISSION PANEL", "PANEL DE MISIONES"), 40)
	head.position = Vector2(34, 12)
	var back := UIK.button(side, Game.t("GO BACK", "VOLVER"), func() -> void: Game.go("hub"), "ghost", Vector2(150, 44))
	back.position = Vector2(460, 20)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(34, 76)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	side.add_child(grid)
	for id in Data.ZONE_ORDER:
		var zone: Dictionary = Data.ZONES[id]
		var index: int = Data.ZONE_ORDER.find(id) + 1
		var b := UIK.button(grid, "", func() -> void: pick(id), "dark", Vector2(280, 74))
		b.draw.connect(func() -> void:
			var open := Game.zone_unlocked(id)
			b.draw_style_box(UIK.box(Color(String(zone.color)) if open else UIK.MUTED, 12, UIK.INK, 3, 0), Rect2(8, 8, 56, 56))
			if open: b.draw_string(UIK.title_font, Vector2(8, 50), str(index), HORIZONTAL_ALIGNMENT_CENTER, 56, 36, UIK.INK)
			else: b.draw_texture_rect(UIK.tex("pin_locked"), Rect2(14, 14, 44, 44), false)
			b.draw_string(UIK.title_font, Vector2(74, 28), Game.tt(zone.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 198, 17, UIK.PAPER)
			b.draw_string(UIK.bold_font, Vector2(74, 46), Game.tt(zone.goal), HORIZONTAL_ALIGNMENT_LEFT, 198, 13, UIK.MINT)
			var steps := grade_steps(id)
			for n in range(4): b.draw_style_box(UIK.box(UIK.GO if n < steps else Color(UIK.PAPER, 0.18), 4, UIK.INK, 2, 0), Rect2(74 + n * 34, 52, 30, 12))
			var state := Game.t("LOCKED", "BLOQUEADA") if not open else (String(Game.progress[id].grade) if Game.progress.has(id) else Game.t("NEW", "NUEVA"))
			b.draw_string(UIK.bold_font, Vector2(212, 63), state, HORIZONTAL_ALIGNMENT_RIGHT, 58, 14, UIK.CREAM if open else UIK.MUTED)
			if id == selected: b.draw_style_box(UIK.box(Color.TRANSPARENT, 16, UIK.ORANGE, 4, 0), Rect2(Vector2.ZERO, b.size)))
		buttons[id] = b
	card = UIK.panel(side, Rect2(34, 250, 572, 456), UIK.PAPER, 18)
	var help := UIK.heading(self, Game.t("Drag to rotate · wheel to zoom", "Arrastra para girar · rueda para acercar") if Game.input_mode != "keyboard" else Game.t("Rotate with the ◀ ▶ buttons", "Gira con los botones ◀ ▶"), 16)
	help.position = Vector2(30, 24)
	var note := UIK.label(self, Game.t("Artistic globe · real coordinates", "Globo artístico · coordenadas reales"), 13, Color(UIK.PAPER, 0.8), "bold")
	note.position = Vector2(30, 52)
	var controls := UIK.row(self, 8)
	controls.position = Vector2(30, 660)
	UIK.button(controls, "◀", func() -> void: nudge(-0.5), "ghost", Vector2(52, 44))
	UIK.button(controls, "▶", func() -> void: nudge(0.5), "ghost", Vector2(52, 44))
	UIK.button(controls, Game.t("Find Jezero", "Ir a Jezero"), find_jezero, "primary", Vector2(170, 44))
	Motion.stagger(grid.get_children(), 0.035, Vector2(30, 0))
	refresh()
	find_jezero()
	UIK.focus_first(grid)

func nudge(amount: float) -> void:
	auto = false
	target_spin += amount

## Centra Jezero por el camino angular corto: giro y también inclinación (antes solo giraba,
## y tras inclinar el globo a mano la zona elegida quedaba fuera del centro).
func find_jezero() -> void:
	auto = false
	var goal := deg_to_rad(77.5)
	target_spin = spin + wrapf(goal - spin, -PI, PI)
	target_tilt = -deg_to_rad(18.4)
	focusing = true

## Elegir un subnivel solo cambia la ficha: no desbloquea ni toca el progreso.
func pick_sub(id: String) -> void:
	sub = id
	Game.sfx("select")
	refresh()

func pick(id: String) -> void:
	selected = id
	sub = "main"
	Game.sfx("attach")
	find_jezero()
	refresh()

## «Conocer más» del destino: criterio real de selección de Jezero y qué simplifica el juego.
func why_jezero() -> void:
	UIK.close_modal(self)
	var info: Dictionary = Data.PLAN_FACTS.site
	var content := UIK.modal(self, Vector2(780, 520), Game.t("Why Jezero?", "¿Por qué Jezero?"))
	var real := UIK.card(content, Game.t("REAL · NASA", "REAL · NASA"), UIK.TEAL)
	UIK.text(real, Game.tt(info.real), 15, UIK.INK)
	UIK.link(real, String(info.source), String(info.url))
	var game := UIK.card(content, Game.t("IN 2MARS · game model", "EN 2MARS · modelo de juego"), UIK.RUST)
	UIK.text(game, Game.tt(info.game), 15, UIK.INK)
	UIK.text(game, Game.t("Each zone trades science against terrain: check which instruments it asks for and which hazards it has before you plan.", "Cada zona intercambia ciencia por terreno: mira qué instrumentos pide y qué riesgos tiene antes de planificar."), 15, UIK.INK)
	var line := UIK.row(content, 10)
	UIK.button(line, Game.t("Close", "Cerrar"), func() -> void: UIK.close_modal(self), "ghost", Vector2(160, 44))
	UIK.focus_first(line)

func deploy() -> void:
	Game.zone = selected
	Game.sub = sub if Game.sub_unlocked(selected, sub) else "main"
	Game.go("plan")

## Misión elegida: objetivos con icono y contador, requisitos y despliegue.
func refresh() -> void:
	for child in card.get_children(): child.queue_free()
	var zone: Dictionary = Data.ZONES[selected]
	var unlocked := Game.zone_unlocked(selected)
	var content := UIK.column(card, Rect2(20, 12, 532, 370), 5)
	# cabecera: nombre de la zona y «por qué Jezero»
	var head := UIK.row(content, 8)
	var zone_title := UIK.label(head, Game.tt(zone.name), 24, UIK.NAVY, "title")
	zone_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_title.tooltip_text = "%s · %s 18.4°N 77.5°E" % [Game.tt(zone.goal), Game.t("Jezero Crater", "cráter Jezero")]
	zone_title.mouse_filter = Control.MOUSE_FILTER_STOP
	var why := UIK.button(head, "ⓘ", why_jezero, "ghost", Vector2(38, 30))
	why.add_theme_font_size_override("font_size", 16)
	why.tooltip_text = Game.t("Why Jezero? Real selection criteria", "¿Por qué Jezero? Criterios reales de selección")
	# V5 · subniveles de la zona: nodos con su estado
	var nodes := UIK.row(content, 6)
	for id in Data.SUB_ORDER:
		var info: Dictionary = Data.SUBLEVELS[id]
		var open := Game.sub_unlocked(selected, id)
		var result := Game.sub_result(selected, id)
		var mark := ""
		if not open: mark = "  🔒"
		elif not result.is_empty(): mark = "  ✓ " + String(result.get("grade", ""))
		var node := UIK.icon_button(nodes, Game.tt(info.name) + mark, String(info.icon) if open else "pin_locked", func() -> void: pick_sub(id), "ghost", Vector2(172, 38))
		node.add_theme_font_size_override("font_size", 13)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.add_theme_stylebox_override("normal", UIK.box((UIK.MINT if id == sub else UIK.PAPER) if open else Color("#e3dccb"), 12, UIK.ORANGE if id == sub else UIK.INK, 4 if id == sub else 2, 2))
		node.tooltip_text = Game.tt(info.note) if id != "main" else Game.tt(zone.brief)
	var brief := UIK.text(content, Game.tt(zone.brief) if sub == "main" else Game.tt(Data.SUBLEVELS[sub].note), 14, UIK.INK if sub != "arcade" else UIK.RUST)
	brief.max_lines_visible = 2
	brief.tooltip_text = Game.tt(zone.nasa) if sub == "main" else Game.tt(Data.SUBLEVELS[sub].note)
	brief.mouse_filter = Control.MOUSE_FILTER_STOP
	var goals := GridContainer.new()
	goals.columns = 2
	goals.add_theme_constant_override("h_separation", 10)
	goals.add_theme_constant_override("v_separation", 4)
	content.add_child(goals)
	var required_seen := 0
	for objective in zone.objectives:
		var optional := bool(objective.get("opt", false))
		if not optional:
			required_seen += 1
			if sub == "recon" and required_seen > 2: optional = true
		var line := UIK.row(goals, 6)
		line.custom_minimum_size = Vector2(260, 34)
		line.tooltip_text = Game.tt(objective.text)
		UIK.picture(line, UIK.tex(String(GOAL_ICON.get(String(objective.kind), "pin_mission"))), Vector2(30, 30)).modulate.a = 0.7 if optional else 1.0
		var words := UIK.text(line, Game.tt(objective.text), 13, UIK.MUTED if optional else UIK.INK)
		words.max_lines_visible = 2
		words.add_theme_constant_override("line_spacing", -3)
		if not optional: words.add_theme_font_override("font", UIK.bold_font)
		UIK.chip(line, "×%d" % int(objective.need), UIK.TEAL if optional else UIK.RUST).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var needs := UIK.row(content, 6)
	UIK.label(needs, Game.t("SUGGESTED", "SUGERIDO"), 13, UIK.TEAL, "bold")
	for id in zone.suggest:
		var have := Data.has(Game.build, "arm") if String(id).begins_with("arm") else Data.has(Game.build, String(id))
		var slot := PanelContainer.new()
		slot.add_theme_stylebox_override("panel", UIK.box(Color("#2a62b8"), 10, UIK.GO if have else UIK.INK, 3, 0))
		slot.tooltip_text = "%s · %s" % [Data.comp_name(String(id)), Game.t("installed", "instalado") if have else Game.t("not on your rover", "no está en tu rover")]
		needs.add_child(slot)
		UIK.picture(slot, UIK.tex("res://assets/parts/%s.png" % String(id)), Vector2(30, 30))
	# V5 · el destino se conecta con el rover actual: qué objetivos obligatorios alcanza hoy
	var reach := 0
	var required := 0
	for note in Data.readiness(Game.build, selected):
		if bool(note.opt): continue
		required += 1
		if bool(note.ok): reach += 1
	var fit := UIK.chip(needs, Game.t(" your rover: %d/%d goals ", " tu rover: %d/%d objetivos ") % [reach, required], UIK.GOOD if reach == required else UIK.SAND)
	fit.add_theme_font_size_override("font_size", 13)
	fit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fit.mouse_filter = Control.MOUSE_FILTER_STOP
	fit.tooltip_text = Game.t("Required objectives your current rover can reach here. Change instruments in the workshop.", "Objetivos obligatorios que tu rover actual puede alcanzar aquí. Cambia instrumentos en el taller.")
	var risks := UIK.row(content, 5)
	UIK.label(risks, Game.t("TERRAIN", "TERRENO"), 13, UIK.RUST, "bold")
	if sub == "arcade":
		var fake := UIK.chip(risks, Game.t(" fictional: meteors · lightning · quakes · cold fronts · vortices ", " ficticios: meteoritos · rayos · sismos · frentes fríos · vórtices "), UIK.BAD)
		fake.add_theme_font_size_override("font_size", 12)
	else:
		for hazard in zone.hazards:
			if sub == "recon" and String(hazard) == "storm": continue
			UIK.chip(risks, " %s " % Game.tt(HAZARD[hazard]), UIK.SAND).add_theme_font_size_override("font_size", 13)
	var launch := UIK.button(card, Game.t("PLAN THIS MISSION", "PLANIFICAR ESTA MISIÓN"), deploy, "go", Vector2(532, 58))
	launch.position = Vector2(20, 386)
	launch.add_theme_font_size_override("font_size", 22)
	launch.disabled = not unlocked
	if unlocked and not Game.sub_unlocked(selected, sub):
		launch.disabled = true
		launch.text = Game.t("Pass the main mission with grade C or better", "Supera la misión principal con nota C o mejor")
		launch.add_theme_font_size_override("font_size", 16)
	elif unlocked and sub != "main":
		launch.text = Game.t("PLAN: %s", "PLANIFICAR: %s") % Game.tt(Data.SUBLEVELS[sub].name).to_upper()
		launch.add_theme_font_size_override("font_size", 19)
	if not unlocked:
		var previous: String = Data.ZONE_ORDER[Data.ZONE_ORDER.find(selected) - 1]
		launch.text = Game.t("Finish %s with grade C or better", "Termina %s con nota C o mejor") % Game.tt(Data.ZONES[previous].name)
		launch.add_theme_font_size_override("font_size", 16)
	Motion.slide_in(card, Vector2(0, 20), 0.2)

func _gui_input(event: InputEvent) -> void:
	if Game.input_mode == "keyboard": return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed and event.position.distance_to(CENTER) < RADIUS * zoom + 20.0
			if dragging: auto = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom = minf(1.25, zoom + 0.06)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom = maxf(0.75, zoom - 0.06)
	elif event is InputEventMouseMotion and dragging:
		# Arrastre directo: la superficie sigue al puntero en los dos ejes (el vertical iba al revés).
		focusing = false                      # arrastrar cancela el enfoque automático en curso
		var grip := RADIUS * zoom
		target_spin -= event.relative.x / grip
		spin = target_spin
		tilt = clampf(tilt - event.relative.y / grip, -0.9, 0.9)   # límite: no se cruzan los polos
		target_tilt = tilt

func tick(delta: float) -> void:
	if auto and not Game.reduced_motion: target_spin += delta * 0.12
	spin = lerp(spin, target_spin, clampf(delta * 5.0, 0.0, 1.0)) if not Game.reduced_motion else target_spin
	if focusing:
		tilt = lerp(tilt, target_tilt, clampf(delta * 5.0, 0.0, 1.0)) if not Game.reduced_motion else target_tilt
		if absf(tilt - target_tilt) < 0.002 and absf(spin - target_spin) < 0.002: focusing = false
	var r := RADIUS * zoom
	globe.position = CENTER - Vector2(r, r) * 1.2
	globe.size = Vector2(r, r) * 2.4
	# misma rotación que usa project(): la malla 3D y los marcadores 2D coinciden
	ball.basis = Basis(Vector3.RIGHT, -tilt) * Basis(Vector3.UP, -spin)
	for id in buttons: buttons[id].queue_redraw()

## Proyección ortográfica del globo 3D (misma base que la malla). Devuelve [posición, visible].
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
	for n in range(Data.ZONE_ORDER.size() - 1):
		var from: Vector2 = inset + SPOTS[Data.ZONE_ORDER[n]] * r
		var to: Vector2 = inset + SPOTS[Data.ZONE_ORDER[n + 1]] * r
		canvas.draw_dashed_line(from, to, Color(UIK.PAPER, 0.9) if Game.zone_unlocked(Data.ZONE_ORDER[n + 1]) else Color(UIK.INK, 0.5), 3.0, 7.0)
	for id in Data.ZONE_ORDER:
		var spot: Vector2 = inset + SPOTS[id] * r
		var zone: Dictionary = Data.ZONES[id]
		var open := Game.zone_unlocked(id)
		var size_px := 15.0 + (3.0 * sin(time * 4.0) if id == selected and not Game.reduced_motion else 0.0)
		canvas.draw_circle(spot, size_px + 3.0, UIK.INK)
		canvas.draw_circle(spot, size_px, Color(String(zone.color)) if open else UIK.MUTED)
		if open: canvas.draw_string(UIK.title_font, spot + Vector2(-12, 7), str(Data.ZONE_ORDER.find(id) + 1), HORIZONTAL_ALIGNMENT_CENTER, 24, 18, UIK.INK)
		else: canvas.draw_texture_rect(UIK.tex("pin_locked"), Rect2(spot - Vector2(13, 13), Vector2(26, 26)), false)
		if grade_steps(id) >= 2: canvas.draw_texture_rect(UIK.tex("pin_completed"), Rect2(spot + Vector2(6, -26), Vector2(22, 22)), false)
		if id == selected: canvas.draw_arc(spot, size_px + 7.0, 0, TAU, 24, UIK.PAPER, 3.0, true)
	canvas.draw_string_outline(UIK.bold_font, inset + Vector2(-r, -r - 12), Game.t("JEZERO CRATER", "CRÁTER JEZERO"), HORIZONTAL_ALIGNMENT_CENTER, r * 2, 15, 6, UIK.INK)
	canvas.draw_string(UIK.bold_font, inset + Vector2(-r, -r - 12), Game.t("JEZERO CRATER", "CRÁTER JEZERO"), HORIZONTAL_ALIGNMENT_CENTER, r * 2, 15, UIK.PAPER)
