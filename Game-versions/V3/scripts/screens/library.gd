extends BaseScreen
## Biblioteca científica. Separa los datos reales de la NASA de los valores del juego,
## muestra el catálogo de ingeniería del equipo, la trazabilidad fuente → mecánica y las fuentes.
## Aquí viven también los avisos de atribución que antes ocupaban el pie de las pantallas.

var content: VBoxContainer
var tabs: HBoxContainer
var current := "instruments"

func _ready() -> void:
	backdrop = "space"
	backdrop_dim = 0.45
	title(Game.t("SCIENCE LIBRARY", "BIBLIOTECA CIENTÍFICA"), Vector2(40, 14), 38)
	tabs = UIK.row(self, 8)
	tabs.position = Vector2(40, 82)
	var names := {"instruments": Game.t("Instruments", "Instrumentos"), "catalog": Game.t("Rover parts", "Piezas del rover"), "samples": Game.t("Real samples", "Muestras reales"), "rover": Game.t("The real rover", "El rover real"),
		"trace": Game.t("NASA → game", "NASA → juego"), "stories": Game.t("Mission stories", "Historias"), "sources": Game.t("Sources & credits", "Fuentes y créditos")}
	for id in ["instruments", "catalog", "samples", "rover", "trace", "stories", "sources"]:
		UIK.button(tabs, names[id], func() -> void: open(id), "ghost", Vector2(164, 44)).add_theme_font_size_override("font_size", 15)
	var panel := UIK.panel(self, Rect2(40, 138, 1200, 510))
	content = UIK.scroll(panel, Rect2(24, 16, 1152, 478))
	var back := UIK.button(self, Game.t("← Back", "← Volver"), func() -> void: Game.go(Game.library_return), "ghost", Vector2(150, 46))
	back.position = Vector2(40, 660)
	open("instruments")
	UIK.focus_first(tabs)

func open(tab: String) -> void:
	current = tab
	for child in content.get_children(): child.queue_free()
	match tab:
		"instruments":
			for key in Data.INSTRUMENT_ORDER:
				var info: Dictionary = Data.INSTRUMENTS[key]
				var part: Dictionary = Data.COMPONENTS[key]
				UIK.label(content, Data.comp_name(key), 24, UIK.NAVY, "title")
				UIK.text(content, Game.t("Real instrument (NASA): ", "Instrumento real (NASA): ") + Game.tt(info.real), 16, UIK.INK)
				UIK.text(content, Game.t("In 2Mars: ", "En 2Mars: ") + Game.tt(info.game) + "  ·  %d kg · %d cr · %d W · %d MB" % [int(part.mass), int(part.cost), int(part.power), int(info.mb)], 15, UIK.TEAL)
			UIK.text(content, Game.t("WATSON is the camera that works with SHERLOC; it is not one of the seven science instruments.", "WATSON es la cámara que trabaja con SHERLOC; no es uno de los siete instrumentos científicos."), 15, UIK.MUTED)
			UIK.text(content, Game.t("Kilograms, credits, watts, megabytes and times in 2Mars are a simplified educational model, not NASA figures.", "Los kilogramos, créditos, vatios, megabytes y tiempos de 2Mars son un modelo educativo simplificado, no cifras de la NASA."), 15, UIK.RUST)
			UIK.link(content, String(Data.SOURCES[1][0]), String(Data.SOURCES[1][1]))
		"catalog":
			UIK.text(content, Game.t("The team's engineering workbook: 30 components. Mass, power, credits and scores are GAME PARAMETERS chosen by the team. \"Real subsystem\" only means the part is inspired by a real Perseverance subsystem; it does not certify the numbers. Example: the game's RTG gives 300 W, while Perseverance's real MMRTG gives about 110 W.", "El libro de ingeniería del equipo: 30 componentes. Masa, potencia, créditos y puntuaciones son PARÁMETROS DE JUEGO elegidos por el equipo. «Subsistema real» solo significa que la pieza se inspira en un subsistema real de Perseverance; no certifica las cifras. Ejemplo: el RTG del juego da 300 W, mientras que el MMRTG real de Perseverance da unos 110 W."), 15, UIK.RUST)
			for category in Data.CATEGORIES:
				UIK.label(content, Game.tt(category.name), 22, UIK.NAVY, "title")
				for id in Data.COMPONENTS:
					var part: Dictionary = Data.COMPONENTS[id]
					if String(part.cat) != String(category.id): continue
					var power := (Game.t("generates %d W", "genera %d W") % int(part.power)) if id in ["solar", "rtg"] else (Game.t("draws %d W", "consume %d W") % int(part.power))
					UIK.text(content, "%s  ·  %s  ·  %d kg  ·  %s  ·  %d cr  ·  %s\n✓ %s     ✗ %s     →  %s" % [Game.tt(part.name), Game.tt(part.fn), int(part.mass), power, int(part.cost), Game.t("real subsystem", "subsistema real") if part.nasa else Game.t("game part", "pieza de juego"), Game.tt(part.adv), Game.tt(part.dis), Game.tt(Data.EFFECTS[id])], 15, UIK.INK)
			UIK.link(content, String(Data.SOURCES[2][0]), String(Data.SOURCES[2][1]))
		"samples":
			UIK.text(content, Game.t("Real samples collected by Perseverance (NASA). The rocks you study in the game are fictional and only inspired by Jezero. NASA's sample catalogue keeps changing: check the page for current numbers.", "Muestras reales recolectadas por Perseverance (NASA). Las rocas que estudias en el juego son ficticias y solo se inspiran en Jezero. El catálogo de la NASA sigue cambiando: consulta la página para ver las cifras actuales."), 16, UIK.RUST)
			for sample in Data.REAL_SAMPLES:
				UIK.label(content, "%s  ·  %s" % [sample.name, sample.rock], 22, UIK.NAVY, "title")
				UIK.text(content, "%s  ·  %s %d  ·  sol %d  ·  %s" % [Game.tt(sample.kind), Game.t("sample", "muestra"), int(sample.number), int(sample.sol), sample.date], 16, UIK.INK)
			UIK.link(content, Game.t("Photos and details of every real sample (NASA)", "Fotos y detalles de cada muestra real (NASA)"), Data.SAMPLES_URL)
		"rover":
			UIK.text(content, Game.t("Facts about the real Perseverance rover (NASA). Your game rover is a simplified model.", "Datos del rover Perseverance real (NASA). El rover del juego es un modelo simplificado."), 16, UIK.RUST)
			for fact in Data.REAL_FACTS: UIK.text(content, "•  " + Game.tt(fact), 16, UIK.INK)
			UIK.link(content, String(Data.SOURCES[2][0]), String(Data.SOURCES[2][1]))
			UIK.link(content, String(Data.SOURCES[5][0]), String(Data.SOURCES[5][1]))
		"trace":
			UIK.text(content, Game.t("How NASA information becomes a mechanic, a decision and a consequence in the game.", "Cómo la información de la NASA se convierte en una mecánica, una decisión y una consecuencia en el juego."), 16, UIK.RUST)
			for row in Data.TRACE:
				var card := UIK.card(content, String(Data.SOURCES[int(row.src)][0]).to_upper(), UIK.ORANGE)
				UIK.text(card, Game.t("NASA information: ", "Información de la NASA: ") + Game.tt(row.info), 15, UIK.INK)
				UIK.text(card, Game.t("Game mechanic: ", "Mecánica del juego: ") + Game.tt(row.mech), 15, UIK.TEAL)
				UIK.text(card, Game.t("Your decision: ", "Tu decisión: ") + Game.tt(row.dec) + "   →   " + Game.t("Consequence: ", "Consecuencia: ") + Game.tt(row.cons), 15, UIK.INK)
				UIK.link(card, Game.t("Open the source", "Abrir la fuente"), String(Data.SOURCES[int(row.src)][1]))
		"stories":
			UIK.text(content, Game.t("Real mission stories Dr. Owen has told you. Ask her \"Wait! Don't you have anything else to tell me?\" to hear more.", "Historias reales de misiones que te ha contado la Dra. Owen. Pregúntale «¡Espera! ¿No tienes algo más que contarme?» para escuchar más."), 16, UIK.RUST)
			for id in Data.STORY_ORDER:
				var story: Dictionary = Data.STORIES[id]
				if Game.stories.has(id):
					UIK.label(content, Game.tt(story.title), 22, UIK.NAVY, "title")
					UIK.text(content, Game.tt(story.text), 15, UIK.INK)
					UIK.text(content, Game.t("Source: ", "Fuente: ") + String(story.source), 13, UIK.MUTED)
				else: UIK.label(content, "???  ·  " + Game.t("not heard yet", "aún no escuchada"), 18, UIK.MUTED, "bold")
		"sources":
			UIK.label(content, Game.t("NASA resources used", "Recursos de la NASA utilizados"), 24, UIK.NAVY, "title")
			for source in Data.SOURCES: UIK.link(content, String(source[0]), String(source[1]))
			UIK.label(content, Game.t("What is real and what is game", "Qué es real y qué es juego"), 24, UIK.NAVY, "title")
			UIK.text(content, Game.t("1 · Verified NASA information: the facts in \"The real rover\", \"Real samples\" and Dr. Owen's stories.\n2 · Gameplay abstractions informed by science: component values, energy in W and Wh, megabytes, link rates, mission times, landing and hazards.\n3 · Fiction: Dr. Owen, your team, your rover, the mission, and every rock and sample you study.", "1 · Información verificada de la NASA: los datos de «El rover real», «Muestras reales» y las historias de la Dra. Owen.\n2 · Abstracciones de juego informadas por la ciencia: valores de componentes, energía en W y Wh, megabytes, tasas de enlace, tiempos de misión, aterrizaje y riesgos.\n3 · Ficción: la Dra. Owen, tu equipo, tu rover, la misión y cada roca y muestra que estudias."), 16, UIK.INK)
			UIK.label(content, Game.t("Credits", "Créditos"), 24, UIK.NAVY, "title")
			UIK.text(content, Game.t("2Mars · Team SpaceNuts (Panama) · NASA Space Apps Challenge 2026 · Space Mission Design Game. Developed in several sessions during November 14 and 15.\nArt: original vector art drawn by code; 2MARS logo by the team. Sound effects and music: synthesised for the game. Fonts: Fredoka and Nunito (SIL Open Font License). Engine: Godot 4.7.\nThe Mars globe is an artistic rendering, not a NASA map. 2Mars is not affiliated with or endorsed by NASA.", "2Mars · Equipo SpaceNuts (Panamá) · NASA Space Apps Challenge 2026 · Space Mission Design Game. Desarrollado en distintas sesiones durante el 14 y 15 de noviembre.\nArte: vectorial y original, dibujado por código; logotipo 2MARS del equipo. Efectos de sonido y música: sintetizados para el juego. Fuentes: Fredoka y Nunito (SIL Open Font License). Motor: Godot 4.7.\nEl globo de Marte es una representación artística, no un mapa de la NASA. 2Mars no tiene afiliación ni respaldo de la NASA."), 16, UIK.INK)
