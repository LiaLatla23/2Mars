extends Control
## Biblioteca científica: instrumentos, muestras reales, datos de Perseverance y fuentes.
## Aquí se separa con claridad lo real (NASA) de lo simplificado por el juego.

var content: VBoxContainer
var tab := "instruments"
var tabs: HBoxContainer

func _ready() -> void:
	var title := UIK.label(self, Game.t("Science library", "Biblioteca científica"), 40, UIK.NAVY, "title")
	title.position = Vector2(40, 18)
	tabs = UIK.row(self, 10)
	tabs.position = Vector2(40, 84)
	for id in ["instruments", "samples", "rover", "sources"]:
		var caption: String = {"instruments": Game.t("Instruments", "Instrumentos"), "samples": Game.t("Real samples", "Muestras reales"), "rover": Game.t("The real rover", "El rover real"), "sources": Game.t("Sources & credits", "Fuentes y créditos")}[id]
		UIK.button(tabs, caption, func() -> void: open(id), "ghost", Vector2(210, 46))
	var panel := UIK.panel(self, Rect2(40, 144, 1200, 500))
	content = UIK.scroll(panel, Rect2(24, 18, 1152, 464))
	var back := UIK.button(self, Game.t("← Menu", "← Menú"), func() -> void: Game.go("menu"), "ghost", Vector2(150, 46))
	back.position = Vector2(40, 658)
	open(tab)

func open(id: String) -> void:
	tab = id
	for child in content.get_children(): child.queue_free()
	match id:
		"instruments":
			for key in Data.INSTRUMENT_ORDER:
				var info: Dictionary = Data.INSTRUMENTS[key]
				UIK.label(content, Data.instrument_name(key), 24, UIK.NAVY, "title")
				UIK.text(content, Game.t("Real instrument (NASA): ", "Instrumento real (NASA): ") + Game.tt(info.real), 17, UIK.INK)
				UIK.text(content, Game.t("In ToMars: ", "En ToMars: ") + Game.tt(info.game) + "  ·  %d kg · %d cr · %d MB" % [int(info.mass), int(info.cost), int(info.mb)], 16, UIK.TEAL)
			UIK.text(content, Game.t("Kilograms, credits, megabytes and seconds in ToMars are a simplified educational model, not NASA figures.", "Los kilogramos, créditos, megabytes y segundos de ToMars son un modelo educativo simplificado, no cifras de la NASA."), 15, UIK.CORAL)
		"samples":
			UIK.text(content, Game.t("Real samples collected by Perseverance (NASA). The rocks you study in the game are fictional and only inspired by Jezero.", "Muestras reales recolectadas por Perseverance (NASA). Las rocas que estudias en el juego son ficticias y solo se inspiran en Jezero."), 17, UIK.CORAL)
			for sample in Data.REAL_SAMPLES:
				UIK.label(content, "%s  ·  %s" % [sample.name, sample.rock], 24, UIK.NAVY, "title")
				UIK.text(content, "%s  ·  %s %d  ·  sol %d  ·  %s" % [Game.tt(sample.kind), Game.t("sample", "muestra"), int(sample.number), int(sample.sol), sample.date], 17, UIK.INK)
			UIK.text(content, Game.t("The sample catalogue keeps growing; check the NASA page for the current list.", "El catálogo de muestras sigue creciendo; consulta la página de la NASA para la lista actual."), 15, UIK.MUTED)
		"rover":
			for fact in Data.REAL_FACTS: UIK.text(content, "•  " + Game.tt(fact), 18, UIK.INK)
		"sources":
			UIK.label(content, Game.t("NASA resources used", "Recursos de la NASA utilizados"), 24, UIK.NAVY, "title")
			for source in Data.SOURCES: UIK.text(content, "%s\n%s" % [source[0], source[1]], 16, UIK.INK)
			UIK.label(content, Game.t("Credits", "Créditos"), 24, UIK.NAVY, "title")
			UIK.text(content, Game.t("ToMars · Team SpaceNuts (Panama) · NASA Space Apps Challenge 2026 · Space Mission Design Game.\nAll art is original vector art drawn by code. Fonts: Fredoka and Nunito (SIL Open Font License). Engine: Godot 4.\nDr. Owen and this mission are fictional. ToMars is not affiliated with or endorsed by NASA.", "ToMars · Equipo SpaceNuts (Panamá) · NASA Space Apps Challenge 2026 · Space Mission Design Game.\nTodo el arte es vectorial y original, dibujado por código. Fuentes: Fredoka y Nunito (SIL Open Font License). Motor: Godot 4.\nLa Dra. Owen y esta misión son ficticias. ToMars no tiene afiliación ni respaldo de la NASA."), 16, UIK.INK)

func _draw() -> void:
	Art.gradient(self, Rect2(Vector2.ZERO, size), Color("#fff1d6"), Color("#f6cf9f"))
