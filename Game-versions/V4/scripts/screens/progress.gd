extends BaseScreen
## Progreso · inventario científico (referencia 17, V4). Cuadrícula de descubrimientos
## ilustrados por categoría y panel del elemento elegido: imagen grande, resumen, procedencia y
## progreso medible. El historial, los consejos y el retorno científico por zona se abren aparte.
## Todo sale del archivo de guardado: nada se inventa ni se rellena.

const GREEN := Color("#7edb6a")
const STORY_ICON := {"wheels": "comp_wheel", "spirit": "pin_rover", "dust": "comp_solar", "roubion": "mat_canister", "moxie": "comp_analyzer", "delay": "up_range"}
const ZONE_ICON := {"geology": "pin_resource", "life": "pin_anomaly", "archive": "pin_main", "frontier": "pin_exploration"}
var category := "rocks"
var selected := ""
var items: Array = []
var grid: GridContainer
var detail: VBoxContainer
var tabs := {}

func _ready() -> void:
	stage_backdrop("workshop")
	scene3d.goal = Vector3(-2.2, 0.22, 13.0)
	scene3d.orbit = scene3d.goal
	shade(Rect2(0, 0, 1280, 720), Color(UIK.INK, 0.45))
	build_items()
	title(Game.t("SCIENCE INVENTORY", "INVENTARIO CIENTÍFICO"), Vector2(28, 12), 40).add_theme_color_override("font_color", GREEN)
	var total := 0
	var earned := 0
	for item in items:
		total += (item.steps as Array).size()
		earned += int(item.pips)
	var sub := UIK.label(self, Game.t("Campaign %d%%  ·  %d science points on Earth  ·  discovered %d%%", "Campaña %d%%  ·  %d puntos de ciencia en la Tierra  ·  descubierto %d%%") % [Game.campaign_percent(), Game.total_science(), int(100.0 * earned / maxf(1.0, total))], 16, UIK.PAPER, "bold")
	sub.position = Vector2(32, 62)
	back_button(Game.t("GO BACK", "VOLVER"), "hub", Vector2(1096, 20))
	var extra := UIK.row(self, 8)
	extra.position = Vector2(700, 22)
	UIK.icon_button(extra, Game.t("Log & advice", "Bitácora y consejos"), "nav_progress", open_log, "ghost", Vector2(220, 44)).add_theme_font_size_override("font_size", 15)
	UIK.icon_button(extra, Game.t("Achievements", "Logros"), "nav_achievements", func() -> void: Game.go("achievements"), "ghost", Vector2(160, 44)).add_theme_font_size_override("font_size", 15)
	var left := UIK.panel(self, Rect2(24, 100, 760, 600), GREEN, 26)
	var filters := UIK.row(left, 8)
	filters.position = Vector2(18, 14)
	for item in [["rocks", Game.t("Rocks", "Rocas"), "ore_regolith"], ["tools", Game.t("Instruments", "Instrumentos"), "comp_analyzer"], ["zones", Game.t("Zones", "Zonas"), "pin_mission"], ["stories", Game.t("Stories", "Historias"), "nav_inventory"]]:
		var key := String(item[0])
		var b := UIK.icon_button(filters, String(item[1]), String(item[2]), func() -> void: open_category(key), "ghost", Vector2(174, 44))
		b.add_theme_font_size_override("font_size", 16)
		tabs[key] = b
	var holder := ScrollContainer.new()
	holder.position = Vector2(14, 70)
	holder.size = Vector2(736, 516)
	holder.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	holder.follow_focus = true
	left.add_child(holder)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	holder.add_child(grid)
	var right := UIK.panel(self, Rect2(800, 100, 456, 600), UIK.PAPER, 26)
	detail = UIK.column(right, Rect2(24, 18, 408, 564), 8)
	open_category(category)
	Motion.slide_in(left, Vector2(-40, 0))
	Motion.slide_in(right, Vector2(40, 0))

# ------------------------------------------------------------------ datos reales del archivo
func build_items() -> void:
	items = []
	var rocks: Dictionary = Game.discoveries.get("rocks", {})
	for id in Data.ROCKS:
		var info: Dictionary = Data.ROCKS[id]
		var entry: Dictionary = rocks.get(id, {})
		var steps := [[Game.t("Photographed", "Fotografiada"), int(entry.get("photo", 0))], [Game.t("Composition read", "Composición leída"), int(entry.get("chem", 0))], [Game.t("Contact analysis", "Análisis por contacto"), int(entry.get("contact", 0))], [Game.t("Sample cached", "Muestra guardada"), int(entry.get("sample", 0))]]
		var found := not entry.is_empty()
		items.append({"id": id, "cat": "rocks", "name": Game.tt(info.name), "image": UIK.tex("res://assets/rocks/%s.png" % id), "found": found, "steps": steps, "pips": steps.filter(func(s: Array) -> bool: return int(s[1]) > 0).size(),
			"summary": (Game.tt(info.chem) if int(entry.get("chem", 0)) + int(entry.get("contact", 0)) > 0 else Game.t("Seen, but its composition has not been read yet.", "Vista, pero aún no se ha leído su composición.")) if found else Game.t("Not studied yet. Look for it on Mars.", "Aún sin estudiar. Búscala en Marte."),
			"origin": (Game.t("First studied at: ", "Estudiada por primera vez en: ") + Game.tt(Data.ZONES[String(entry.get("zone", "geology"))].name)) if found else Game.t("Game rock inspired by Jezero units", "Roca del juego inspirada en unidades de Jezero")})
	var tools: Dictionary = Game.discoveries.get("tools", {})
	for id in Data.INSTRUMENT_ORDER + ["drill", "regolith"]:
		var uses := int(tools.get(id, 0))
		var steps2 := [[Game.t("Used in 1 mission", "Usado en 1 misión"), 1 if uses >= 1 else 0], [Game.t("Used in 2 missions", "Usado en 2 misiones"), 1 if uses >= 2 else 0], [Game.t("Used in 4 missions", "Usado en 4 misiones"), 1 if uses >= 4 else 0], [Game.t("Used in 6 missions", "Usado en 6 misiones"), 1 if uses >= 6 else 0]]
		items.append({"id": id, "cat": "tools", "name": Data.comp_name(id), "image": UIK.tex("res://assets/parts/%s.png" % id), "found": uses > 0, "steps": steps2, "pips": steps2.filter(func(s: Array) -> bool: return int(s[1]) > 0).size(),
			"summary": Game.tt(Data.INSTRUMENTS[id].game), "origin": Game.t("Real Perseverance instrument", "Instrumento real de Perseverance") if Data.COMPONENTS[id].nasa else Game.t("Game part (simplification)", "Pieza de juego (simplificación)"), "count": uses})
	for id in Data.ZONE_ORDER:
		var zone: Dictionary = Data.ZONES[id]
		var entry2: Dictionary = Game.progress.get(id, {})
		var grade := String(entry2.get("grade", ""))
		var steps3 := [[Game.t("Mission flown", "Misión volada"), 1 if not entry2.is_empty() else 0], [Game.t("Grade C or better", "Nota C o mejor"), 1 if grade in ["S", "A", "B", "C"] else 0], [Game.t("Grade A or better", "Nota A o mejor"), 1 if grade in ["S", "A"] else 0], [Game.t("Grade S", "Nota S"), 1 if grade == "S" else 0]]
		items.append({"id": id, "cat": "zones", "name": Game.tt(zone.name), "image": UIK.tex(String(ZONE_ICON[id])), "found": not entry2.is_empty(), "steps": steps3, "pips": steps3.filter(func(s: Array) -> bool: return int(s[1]) > 0).size(), "tile": Color(String(zone.color)),
			"summary": Game.tt(zone.nasa), "origin": Game.t("Jezero crater · %.2f° N, %.2f° E (real coordinates; artistic map)", "Cráter Jezero · %.2f° N, %.2f° E (coordenadas reales; mapa artístico)") % [float(zone.lat), float(zone.lon)],
			"line": (Game.t("Best grade %s · %d science pts · %d flight(s)", "Mejor nota %s · %d pts de ciencia · %d vuelo(s)") % [grade, int(entry2.get("science", 0)), int(entry2.get("runs", 0))]) if not entry2.is_empty() else (Game.t("Not flown yet", "Aún sin volar") if Game.zone_unlocked(id) else Game.t("Locked: finish the previous zone", "Bloqueada: termina la zona anterior"))})
	for id in Data.STORY_ORDER:
		var story: Dictionary = Data.STORIES[id]
		var heard := Game.stories.has(id)
		items.append({"id": id, "cat": "stories", "name": Game.tt(story.title) if heard else "???", "image": UIK.tex(String(STORY_ICON.get(id, "nav_inventory"))), "found": heard, "steps": [[Game.t("Heard from Dr. Owen", "Contada por la Dra. Owen"), 1 if heard else 0]], "pips": 1 if heard else 0,
			"summary": Game.t("A real mission story.", "Una historia real de misiones.") if heard else Game.t("Ask Dr. Owen: “Wait! Don't you have anything else to tell me?”", "Pregúntale a la Dra. Owen: «¡Espera! ¿No tienes algo más que contarme?»"), "origin": Game.t("Source: ", "Fuente: ") + String(story.source)})

func open_category(id: String) -> void:
	category = id
	for key in tabs: (tabs[key] as Button).add_theme_stylebox_override("normal", UIK.box(UIK.NAVY if key == id else UIK.PAPER, 16, UIK.INK, 3, 3))
	for key in tabs:
		for state in ["font_color", "font_hover_color", "font_focus_color"]: (tabs[key] as Button).add_theme_color_override(state, UIK.PAPER if key == id else UIK.INK)
	var first := items.filter(func(item: Dictionary) -> bool: return item.cat == id)
	var known := first.filter(func(item: Dictionary) -> bool: return item.found)
	selected = String((known[0] if not known.is_empty() else first[0]).id)
	refresh(true)

func refresh(animate: bool = false) -> void:
	for child in grid.get_children(): child.queue_free()
	var shown: Array = []
	for item in items:
		if item.cat != category: continue
		var key := String(item.id)
		var steps: Array = item.steps
		var full: bool = int(item.pips) >= steps.size()
		var card := UIK.tile(grid, Vector2(170, 158), func() -> void: pick(key), {"image": item.image, "title": String(item.name), "tile": item.get("tile", Color("#2f6f3a") if item.found else Color("#3e4a44")),
			"accent": GREEN, "selected": key == selected, "done": full, "sub": "%d / %d" % [int(item.pips), steps.size()]})
		if not item.found:
			for child in card.get_children():
				if child is TextureRect and (child as TextureRect).texture == item.image: (child as TextureRect).modulate = Color(0.1, 0.12, 0.14, 0.7)
		shown.append(card)
	if animate: Motion.stagger(shown)
	show_detail()

func pick(id: String) -> void:
	selected = id
	refresh()

func current() -> Dictionary:
	for item in items:
		if item.cat == category and String(item.id) == selected: return item
	return items[0]

func show_detail() -> void:
	for child in detail.get_children(): child.queue_free()
	var item := current()
	var head := UIK.row(detail, 14)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UIK.box(item.get("tile", Color("#2f6f3a")), 20, UIK.INK, 3, 4))
	head.add_child(plate)
	var art := UIK.picture(plate, item.image, Vector2(140, 140))
	if not item.found: art.modulate = Color(0.1, 0.12, 0.14, 0.75)
	Motion.celebrate(art)
	var words := UIK.column(head, Rect2(0, 0, 0, 0), 4)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.chip(words, Game.t(" DISCOVERED ", " DESCUBIERTO ") if item.found else Game.t(" PENDING ", " PENDIENTE "), UIK.GOOD if item.found else UIK.MUTED)
	var name_label := UIK.text(words, String(item.name), 25, UIK.NAVY)
	name_label.add_theme_font_override("font", UIK.title_font)
	if item.has("line"): UIK.text(words, String(item.line), 14, UIK.RUST).add_theme_font_override("font", UIK.bold_font)
	var summary := UIK.text(detail, String(item.summary), 16, UIK.INK)
	summary.max_lines_visible = 3
	UIK.text(detail, String(item.origin), 13, UIK.TEAL).add_theme_font_override("font", UIK.bold_font)
	var steps: Array = item.steps
	var done := int(item.pips)
	UIK.label(detail, Game.t("MASTERED: %d%%", "DOMINADO: %d%%") % int(100.0 * done / maxf(1.0, steps.size())), 18, UIK.NAVY, "title")
	var pips := UIK.row(detail, 8)
	for i in range(steps.size()):
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(maxf(40.0, 380.0 / steps.size() - 8.0), 22)
		pip.add_theme_stylebox_override("panel", UIK.box(UIK.GO if int(steps[i][1]) > 0 else Color(UIK.NAVY, 0.16), 8, UIK.INK, 2, 0))
		pips.add_child(pip)
	for step in steps:
		var line := UIK.row(detail, 8)
		UIK.picture(line, UIK.tex("pin_completed" if int(step[1]) > 0 else "pin_locked"), Vector2(22, 22))
		UIK.label(line, String(step[0]), 15, UIK.INK if int(step[1]) > 0 else UIK.MUTED, "bold").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if category == "rocks" and int(step[1]) > 0: UIK.label(line, "× %d" % int(step[1]), 15, UIK.TEAL, "bold")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(spacer)
	var more := UIK.button(detail, Game.t("More information", "Más información"), open_more, "teal", Vector2(408, 48))
	more.disabled = category == "stories" and not item.found

# ------------------------------------------------------------------ detalles a petición
func open_more() -> void:
	var item := current()
	var id := String(item.id)
	if category == "stories":
		show_story(id)
		return
	var content := UIK.modal(self, Vector2(760, 520), String(item.name))
	match category:
		"rocks":
			var info: Dictionary = Data.ROCKS[id]
			var kinds := {"igneous": Game.t("Igneous: cooled from molten rock", "Ígnea: se enfrió a partir de roca fundida"), "sedimentary": Game.t("Sedimentary: laid down in layers", "Sedimentaria: depositada en capas"), "soil": Game.t("Loose soil (regolith)", "Suelo suelto (regolito)")}
			UIK.text(content, String(kinds[String(info.klass)]), 17, UIK.INK).add_theme_font_override("font", UIK.bold_font)
			UIK.text(content, Game.tt(info.chem), 16, UIK.INK)
			var facts := UIK.row(content, 8)
			UIK.chip(facts, Game.t(" formed in water ", " formada en agua ") if info.aqueous else Game.t(" no sign of water ", " sin señal de agua "), UIK.TEAL if info.aqueous else UIK.MUTED)
			if info.organics: UIK.chip(facts, Game.t(" can preserve organics ", " puede conservar orgánicos "), UIK.GOOD)
			if info.fragile: UIK.chip(facts, Game.t(" fragile: cores may crumble ", " frágil: el núcleo puede desmoronarse "), UIK.SAND)
			UIK.text(content, Game.t("Organic molecules and habitable conditions are clues, not a detection of life. NASA has not confirmed life on Mars.", "Las moléculas orgánicas y las condiciones habitables son indicios, no una detección de vida. La NASA no ha confirmado vida en Marte."), 15, UIK.RUST)
			UIK.text(content, Game.t("This is a fictional game rock. Real Perseverance samples of similar types are listed by NASA:", "Es una roca ficticia del juego. La NASA lista las muestras reales de Perseverance de tipos parecidos:"), 14, UIK.MUTED)
			UIK.link(content, "NASA · Mars Rock Samples", Data.SAMPLES_URL)
		"tools":
			var tool: Dictionary = Data.INSTRUMENTS[id]
			UIK.label(content, Game.t("ON THE REAL ROVER", "EN EL ROVER REAL"), 13, UIK.TEAL, "bold")
			UIK.text(content, Game.tt(tool.real), 16, UIK.INK)
			UIK.label(content, Game.t("IN THE GAME", "EN EL JUEGO"), 13, UIK.RUST, "bold")
			UIK.text(content, Game.tt(tool.game), 16, UIK.INK)
			if String(Game.tt(tool.mini)) != "": UIK.text(content, Game.t("Mini-game: ", "Minijuego: ") + Game.tt(tool.mini), 15, UIK.MUTED)
			UIK.text(content, Game.t("Activity: %d Wh · %d MB (game model)", "Actividad: %d Wh · %d MB (modelo de juego)") % [int(Data.activity_wh(Game.build, id)), int(Data.activity_mb(Game.build, id))], 15, UIK.NAVY)
		"zones":
			var zone: Dictionary = Data.ZONES[id]
			UIK.text(content, Game.tt(zone.nasa), 16, UIK.TEAL)
			UIK.text(content, Game.tt(zone.brief), 16, UIK.INK)
			UIK.label(content, Game.t("OBJECTIVES", "OBJETIVOS"), 13, UIK.RUST, "bold")
			for goal in zone.objectives: UIK.text(content, ("◦  " if goal.get("opt", false) else "☐  ") + Game.tt(goal.text), 15, UIK.MUTED if goal.get("opt", false) else UIK.INK)
			UIK.text(content, Game.t("Science points measure data RECEIVED on Earth. Samples stay in their tubes on Mars.", "Los puntos de ciencia miden datos RECIBIDOS en la Tierra. Las muestras se quedan en sus tubos en Marte."), 14, UIK.MUTED)
	UIK.button(content, Game.t("Close", "Cerrar"), func() -> void: UIK.close_modal(self), "primary", Vector2(200, 46)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content)

func open_log() -> void:
	var content := UIK.modal(self, Vector2(900, 600), Game.t("Mission log & advice", "Bitácora y consejos"))
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(848, 440)
	content.add_child(holder)
	var list := UIK.scroll(holder, Rect2(0, 0, 848, 440))
	UIK.label(list, Game.t("DR. OWEN'S TOP ADVICE · from your saved missions", "CONSEJOS DE LA DRA. OWEN · según tus misiones guardadas"), 14, UIK.RUST, "bold")
	var advice := Data.recommendations(Game.history)
	for i in range(mini(3, advice.size())):
		var card := UIK.card(list, Game.tt(advice[i].issue).to_upper(), UIK.ORANGE, UIK.CREAM)
		UIK.text(card, Game.tt(advice[i].why), 15, UIK.INK)
		UIK.text(card, Game.tt(advice[i].tip), 15, UIK.TEAL)
	UIK.text(list, Game.t("Recommendations never change your rover. The decision is yours.", "Las recomendaciones nunca cambian tu rover. La decisión es tuya."), 13, UIK.MUTED)
	UIK.label(list, Game.t("MISSION LOG", "BITÁCORA DE MISIONES"), 14, UIK.RUST, "bold")
	if Game.history.is_empty(): UIK.text(list, Game.t("No missions flown yet.", "Aún no has volado ninguna misión."), 15, UIK.MUTED)
	for i in range(Game.history.size() - 1, -1, -1):
		var entry: Dictionary = Game.history[i]
		var flags: Dictionary = entry.get("flags", {})
		var notes: Array = []
		for pair in [["safe", Game.t("safe mode", "modo seguro")], ["mem_full", Game.t("memory full", "memoria llena")], ["left", Game.t("data left on Mars", "datos sin enviar")], ["damage", Game.t("rover damage", "daño al rover")], ["blocked", Game.t("objectives out of reach", "objetivos fuera de alcance")], ["timeout", Game.t("time ran out", "sin tiempo")]]:
			if float(flags.get(pair[0], 0)) > 0: notes.append(pair[1])
		var line := UIK.row(list, 10)
		UIK.picture(line, UIK.tex("grade_" + String(entry.grade)), Vector2(40, 40))
		UIK.text(line, "%s  ·  %s" % [Game.tt(Data.ZONES[String(entry.zone)].name), ", ".join(notes) if not notes.is_empty() else Game.t("no issues", "sin incidencias")], 15, UIK.INK)
	UIK.button(content, Game.t("Close", "Cerrar"), func() -> void: UIK.close_modal(self), "primary", Vector2(200, 46)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content)
