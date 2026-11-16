extends BaseScreen
## Biblioteca científica. Separa los datos reales de la NASA de los valores del juego,
## muestra el catálogo de ingeniería del equipo, la trazabilidad fuente → mecánica y las fuentes.
## Aquí viven también los avisos de atribución que antes ocupaban el pie de las pantallas.

var content: VBoxContainer
var tabs: HBoxContainer
var current := "instruments"

func _ready() -> void:
	stage_backdrop("vista")
	shade(Rect2(0, 0, 1280, 720), Color(UIK.INK, 0.38))
	backdrop_dim = 0.45
	title(Game.t("SCIENCE LIBRARY", "BIBLIOTECA CIENTÍFICA"), Vector2(40, 14), 38)
	tabs = UIK.row(self, 8)
	tabs.position = Vector2(40, 82)
	var names := {"instruments": Game.t("Instruments", "Instrumentos"), "catalog": Game.t("Rover parts", "Piezas del rover"), "samples": Game.t("Real samples", "Muestras reales"), "rover": Game.t("The real rover", "El rover real"),
		"trace": Game.t("NASA → game", "NASA → juego"), "stories": Game.t("Mission stories", "Historias"), "glossary": Game.t("Glossary", "Glosario"), "sources": Game.t("Sources", "Fuentes")}
	for id in ["instruments", "catalog", "samples", "rover", "trace", "stories", "glossary", "sources"]:
		var tab_button := UIK.button(tabs, names[id], func() -> void: open(id), "ghost", Vector2(140, 44))
		tab_button.add_theme_font_size_override("font_size", 15)
		tab_button.set_meta("tab", id)
	var panel := UIK.panel(self, Rect2(40, 138, 1200, 510))
	content = UIK.scroll(panel, Rect2(24, 16, 1152, 478))
	var back := UIK.button(self, Game.t("← Back", "← Volver"), func() -> void: Game.go(Game.library_return), "ghost", Vector2(150, 46))
	back.position = Vector2(40, 660)
	open(Game.library_tab if Game.library_tab != "" else "instruments")
	Game.library_tab = ""
	UIK.focus_first(tabs)

func open(tab: String) -> void:
	current = tab
	for child in content.get_children(): child.queue_free()
	for child in tabs.get_children():
		if child is Button: (child as Button).add_theme_stylebox_override("normal", UIK.box(UIK.ORANGE if String(child.get_meta("tab", "")) == tab else UIK.PAPER, 16, UIK.INK, 3, 4))
	match tab:
		"instruments":
			var entries: Array = []
			for key in Data.INSTRUMENT_ORDER:
				var id: String = key
				entries.append({"image": UIK.tex("res://assets/parts/%s.png" % id), "title": Data.comp_name(id), "tile": Color("#2a62b8"), "detail": func(box: VBoxContainer) -> void:
					var info: Dictionary = Data.INSTRUMENTS[id]
					var part: Dictionary = Data.COMPONENTS[id]
					UIK.label(box, Game.t("ON THE REAL ROVER (NASA)", "EN EL ROVER REAL (NASA)"), 13, UIK.TEAL, "bold")
					UIK.text(box, Game.tt(info.real), 16, UIK.INK)
					UIK.label(box, Game.t("IN 2MARS (GAME MODEL)", "EN 2MARS (MODELO DE JUEGO)"), 13, UIK.RUST, "bold")
					UIK.text(box, Game.tt(info.game), 16, UIK.INK)
					var facts := UIK.row(box, 6)
					for chip in ["%d kg" % int(part.mass), "%d CR" % int(part.cost), "%d W" % int(part.power), "%d MB" % int(info.mb)]: UIK.chip(facts, " %s " % chip, UIK.NAVY)
					if id == "sherloc": UIK.text(box, Game.t("WATSON is the camera that works with SHERLOC; it is not one of the seven science instruments.", "WATSON es la cámara que trabaja con SHERLOC; no es uno de los siete instrumentos científicos."), 14, UIK.MUTED)
					if id == "moxie": UIK.text(box, Game.t("MOXIE was a technology demonstration, not a life-support system.", "MOXIE fue una demostración tecnológica, no un sistema de soporte vital."), 14, UIK.MUTED)
					UIK.link(box, String(Data.SOURCES[1][0]), String(Data.SOURCES[1][1]))})
			gallery(entries, Game.t("The seven science instruments of Perseverance. Game numbers are a simplified educational model, not NASA figures.", "Los siete instrumentos científicos de Perseverance. Las cifras del juego son un modelo educativo simplificado, no cifras de la NASA."))
		"catalog":
			var entries2: Array = []
			for key in Data.COMPONENTS:
				var id2: String = key
				entries2.append({"image": UIK.tex("res://assets/parts/%s.png" % id2), "title": Data.comp_name(id2), "tile": Color("#2a62b8"), "detail": func(box: VBoxContainer) -> void:
					var part: Dictionary = Data.COMPONENTS[id2]
					var facts := UIK.row(box, 6)
					UIK.chip(facts, " %s " % Game.tt(part.fn), UIK.NAVY)
					UIK.chip(facts, Game.t(" inspired by a real subsystem ", " inspirada en un subsistema real ") if part.nasa else Game.t(" game part ", " pieza de juego "), UIK.TEAL if part.nasa else UIK.MUTED)
					var nums := UIK.row(box, 14)
					UIK.stat(nums, "nav_inventory", "%d kg" % int(part.mass), Game.t("mass", "masa"))
					UIK.stat(nums, "up_power", ("+%d W" if id2 in ["solar", "rtg"] else "−%d W") % int(part.power), Game.t("generates", "genera") if id2 in ["solar", "rtg"] else Game.t("draws", "consume"))
					UIK.stat(nums, "up_production", "%d CR" % int(part.cost), Game.t("cost", "costo"))
					UIK.text(box, Game.tt(Data.EFFECTS[id2]), 16, UIK.INK)
					UIK.text(box, "✓ %s      ✗ %s" % [Game.tt(part.adv), Game.tt(part.dis)], 15, UIK.RUST)
					if id2 == "rtg": UIK.text(box, Game.t("Game value: 300 W. Perseverance's real MMRTG gives about 110 W at the start of the mission.", "Valor de juego: 300 W. El MMRTG real de Perseverance da unos 110 W al inicio de la misión."), 14, UIK.MUTED)})
			gallery(entries2, Game.t("The team's engineering workbook: 30 parts. Mass, power and credits are GAME parameters; “real subsystem” means inspiration, not certified numbers.", "El libro de ingeniería del equipo: 30 piezas. Masa, potencia y créditos son parámetros de JUEGO; «subsistema real» indica inspiración, no cifras certificadas."))
		"samples":
			var entries3: Array = []
			for item in Data.REAL_SAMPLES:
				var sample: Dictionary = item
				entries3.append({"image": UIK.tex("mat_canister"), "title": String(sample.name), "tile": Color("#3d8b82"), "detail": func(box: VBoxContainer) -> void:
					UIK.label(box, Game.t("Rock: %s", "Roca: %s") % String(sample.rock), 18, UIK.NAVY, "bold")
					var facts := UIK.row(box, 6)
					UIK.chip(facts, " %s " % Game.tt(sample.kind), UIK.RUST)
					UIK.chip(facts, " %s %d " % [Game.t("sample", "muestra"), int(sample.number)], UIK.NAVY)
					UIK.chip(facts, " sol %d " % int(sample.sol), UIK.NAVY)
					UIK.label(box, String(sample.date), 16, UIK.INK, "bold")
					UIK.text(box, Game.t("A real sample collected by Perseverance. The rocks in the game are fictional and only inspired by Jezero.", "Una muestra real recolectada por Perseverance. Las rocas del juego son ficticias y solo se inspiran en Jezero."), 15, UIK.MUTED)
					UIK.link(box, Game.t("Photos and details (NASA)", "Fotos y detalles (NASA)"), Data.SAMPLES_URL)})
			gallery(entries3, Game.t("Real Perseverance samples (NASA). The catalogue keeps changing: check the NASA page for current numbers.", "Muestras reales de Perseverance (NASA). El catálogo cambia: consulta la página de la NASA para las cifras actuales."))
		"trace":
			UIK.text(content, Game.t("How NASA information becomes a mechanic, a decision and a consequence in the game.", "Cómo la información de la NASA se convierte en una mecánica, una decisión y una consecuencia en el juego."), 16, UIK.RUST)
			for row in Data.TRACE:
				var card := UIK.card(content, String(Data.SOURCES[int(row.src)][0]).to_upper(), UIK.ORANGE)
				var flow := UIK.row(card, 4)
				var steps := [[Game.t("NASA SOURCE", "FUENTE NASA"), Game.tt(row.info), UIK.MINT], [Game.t("MECHANIC", "MECÁNICA"), Game.tt(row.mech), UIK.CREAM], [Game.t("YOUR DECISION", "TU DECISIÓN"), Game.tt(row.dec), UIK.ORANGE], [Game.t("CONSEQUENCE", "CONSECUENCIA"), Game.tt(row.cons), Color("#e8a58c")]]
				for i in range(steps.size()):
					var cell := PanelContainer.new()
					cell.add_theme_stylebox_override("panel", UIK.box(steps[i][2], 12, UIK.INK, 2, 0))
					cell.custom_minimum_size = Vector2(238, 96)
					cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					flow.add_child(cell)
					var words := VBoxContainer.new()
					words.add_theme_constant_override("separation", 0)
					cell.add_child(words)
					UIK.label(words, String(steps[i][0]), 12, UIK.NAVY, "bold")
					var body := UIK.text(words, String(steps[i][1]), 13, UIK.INK)
					body.max_lines_visible = 4
					body.tooltip_text = String(steps[i][1])
					body.mouse_filter = Control.MOUSE_FILTER_STOP
					if i < steps.size() - 1: UIK.label(flow, "→", 26, UIK.NAVY, "title").size_flags_vertical = Control.SIZE_SHRINK_CENTER
				UIK.link(card, Game.t("Open the source", "Abrir la fuente"), String(Data.SOURCES[int(row.src)][1]))
		"stories":
			var entries4: Array = []
			var icons := {"wheels": "comp_wheel", "spirit": "pin_rover", "dust": "comp_solar", "roubion": "mat_canister", "moxie": "comp_analyzer", "delay": "up_range"}
			for key in Data.STORY_ORDER:
				var id4: String = key
				var heard := Game.stories.has(id4)
				entries4.append({"image": UIK.tex(String(icons.get(id4, "nav_inventory"))), "title": Game.tt(Data.STORIES[id4].title) if heard else "???", "tile": Color("#AA5D40") if heard else Color("#6f7f8c"), "locked": not heard, "detail": func(box: VBoxContainer) -> void:
					var story: Dictionary = Data.STORIES[id4]
					if not Game.stories.has(id4):
						UIK.text(box, Game.t("Not heard yet. Ask Dr. Owen: “Wait! Don't you have anything else to tell me?”", "Aún no escuchada. Pregúntale a la Dra. Owen: «¡Espera! ¿No tienes algo más que contarme?»"), 16, UIK.MUTED)
						return
					UIK.text(box, Game.tt(story.text), 15, UIK.INK)
					UIK.text(box, Game.t("Source: ", "Fuente: ") + String(story.source), 13, UIK.MUTED)
					if story.has("url"): UIK.link(box, Game.t("Open the NASA page", "Abrir la página de la NASA"), String(story.url))})
			gallery(entries4, Game.t("Real mission stories told by Dr. Owen.", "Historias reales de misiones contadas por la Dra. Owen."))
		"glossary":
			UIK.text(content, Game.t("Words the game uses, and whether each one is real or a game value.", "Palabras que usa el juego, y si cada una es real o un valor de juego."), 15, UIK.MUTED)
			for entry in Data.GLOSSARY:
				var term := UIK.card(content, Game.tt(entry.term), UIK.TEAL if bool(entry.real) else UIK.ORANGE)
				UIK.text(term, Game.tt(entry.text), 15, UIK.INK)
				UIK.label(term, Game.t("Real concept", "Concepto real") if bool(entry.real) else Game.t("2Mars game value", "Valor de juego de 2Mars"), 12, UIK.MUTED, "bold")
		"sources":
			UIK.label(content, Game.t("NASA resources used", "Recursos de la NASA utilizados"), 24, UIK.NAVY, "title")
			for source in Data.SOURCES: UIK.link(content, String(source[0]), String(source[1]))
			UIK.label(content, Game.t("What is real and what is game", "Qué es real y qué es juego"), 24, UIK.NAVY, "title")
			UIK.text(content, Game.t("1 · Verified NASA information: the facts in \"The real rover\", \"Real samples\" and Dr. Owen's stories.\n2 · Gameplay abstractions informed by science: component values, energy in W and Wh, megabytes, link rates, mission times, landing and hazards.\n3 · Fiction: Dr. Owen, your team, your rover, the mission, and every rock and sample you study.", "1 · Información verificada de la NASA: los datos de «El rover real», «Muestras reales» y las historias de la Dra. Owen.\n2 · Abstracciones de juego informadas por la ciencia: valores de componentes, energía en W y Wh, megabytes, tasas de enlace, tiempos de misión, aterrizaje y riesgos.\n3 · Ficción: la Dra. Owen, tu equipo, tu rover, la misión y cada roca y muestra que estudias."), 16, UIK.INK)
			UIK.label(content, Game.t("Credits", "Créditos"), 24, UIK.NAVY, "title")
			UIK.text(content, Game.t("2Mars · Team SpaceNuts (Panama) · NASA Space Apps Challenge 2026 · Space Mission Design Game. Developed in several sessions during November 14 and 15.\n3D art (rover, terrain, Mars globe, workshop and landscape): geometry generated by code; part and rock pictures are renders of those models. 2D art: vector drawings made by code. Interface icons, medals and grade badges: cropped from the team's icon sheet. 2MARS logo: by the team. Launch clip: supplied by the team and marked on screen as SI-generated. Music and sound effects: synthesised by a program written for the game (no samples, no AI audio model). Code: written with AI assistance (Claude, Anthropic) and reviewed with automated tests. Fonts: Fredoka and Nunito (SIL Open Font License). Engine: Godot 4.7.\nThe Mars globe is an artistic rendering, not a NASA map. 2Mars is not affiliated with or endorsed by NASA.", "2Mars · Equipo SpaceNuts (Panamá) · NASA Space Apps Challenge 2026 · Space Mission Design Game. Desarrollado en distintas sesiones durante el 14 y 15 de noviembre.\nArte 3D (rover, terreno, globo de Marte, taller y paisaje): geometría generada por código; las imágenes de piezas y rocas son renders de esos modelos. Arte 2D: dibujos vectoriales hechos por código. Iconos de interfaz, medallas e insignias de nota: recortados de la hoja de iconos del equipo. Logotipo 2MARS: del equipo. Clip de lanzamiento: entregado por el equipo y marcado en pantalla como generado con SI. Música y efectos: sintetizados por un programa escrito para el juego (sin muestras ni modelos de IA de audio). Código: escrito con asistencia de IA (Claude, Anthropic) y revisado con pruebas automáticas. Fuentes: Fredoka y Nunito (SIL Open Font License). Motor: Godot 4.7.\nEl globo de Marte es una representación artística, no un mapa de la NASA. 2Mars no tiene afiliación ni respaldo de la NASA."), 16, UIK.INK)

## Galería de fichas ilustradas: cuadrícula a la izquierda y detalle de la elegida a la derecha.
func gallery(entries: Array, intro: String) -> void:
	UIK.text(content, intro, 15, UIK.RUST)
	var split := UIK.row(content, 16)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	split.add_child(grid)
	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", UIK.box(UIK.CREAM, 18, UIK.INK, 3, 3))
	side.custom_minimum_size = Vector2(430, 400)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	split.add_child(side)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 6)
	side.add_child(detail)
	var cards: Array = []
	var show := func(index: int) -> void:
		for child in detail.get_children(): child.queue_free()
		var entry: Dictionary = entries[index]
		var head := UIK.row(detail, 12)
		var plate := PanelContainer.new()
		plate.add_theme_stylebox_override("panel", UIK.box(entry.tile, 16, UIK.INK, 3, 0))
		head.add_child(plate)
		Motion.celebrate(UIK.picture(plate, entry.image, Vector2(104, 104)))
		var name_label := UIK.text(head, String(entry.title), 24, UIK.NAVY)
		name_label.add_theme_font_override("font", UIK.title_font)
		(entry.detail as Callable).call(detail)
		for i in range(cards.size()):
			var chosen: bool = i == index
			(cards[i] as Button).add_theme_stylebox_override("normal", UIK.box(UIK.MINT.lerp(UIK.PAPER, 0.4) if chosen else UIK.PAPER, 16, UIK.INK, 4 if chosen else 3, 4 if chosen else 3))
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var index := i
		cards.append(UIK.tile(grid, Vector2(164, 138), func() -> void: show.call(index), {"image": entry.image, "title": String(entry.title), "tile": entry.tile, "accent": UIK.MINT, "locked": bool(entry.get("locked", false))}))
	Motion.stagger(cards, 0.022)
	if not entries.is_empty(): show.call(0)
