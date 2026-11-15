extends BaseScreen
## Progreso (referencia 17): inventario científico real de la campaña, bitácora de misiones
## y recomendaciones de la Dra. Owen según el historial guardado.

func _ready() -> void:
	backdrop = "workshop"
	backdrop_dim = 0.5
	title(Game.t("PROGRESS · SCIENCE INVENTORY", "PROGRESO · INVENTARIO CIENTÍFICO"), Vector2(30, 14), 34)
	back_button(Game.t("← Earth station", "← Base terrestre"), "hub", Vector2(1060, 18)).custom_minimum_size = Vector2(200, 46)
	var left := UIK.panel(self, Rect2(24, 84, 610, 620))
	var column := UIK.scroll(left, Rect2(20, 14, 572, 592))
	UIK.label(column, Game.t("CAMPAIGN  %d%%  ·  %d science points received on Earth", "CAMPAÑA  %d%%  ·  %d puntos de ciencia recibidos en la Tierra") % [Game.campaign_percent(), Game.total_science()], 15, UIK.RUST, "bold")
	for id in Data.ZONE_ORDER:
		var zone: Dictionary = Data.ZONES[id]
		var card := UIK.card(column, Game.tt(zone.goal).to_upper(), Color(String(zone.color)))
		UIK.label(card, Game.tt(zone.name), 22, UIK.NAVY, "title")
		if Game.progress.has(id):
			var entry: Dictionary = Game.progress[id]
			UIK.text(card, Game.t("Best grade %s  ·  best science return %d pts  ·  %d mission(s) flown", "Mejor nota %s  ·  mejor retorno científico %d pts  ·  %d misión(es) voladas") % [String(entry.grade), int(entry.science), int(entry.runs)], 15, UIK.INK)
		else:
			UIK.text(card, Game.t("Not flown yet.", "Aún sin volar.") if Game.zone_unlocked(id) else Game.t("Locked: finish the previous zone with grade C or better.", "Bloqueada: termina la zona anterior con nota C o mejor."), 15, UIK.MUTED)
		UIK.text(card, Game.tt(zone.nasa), 13, UIK.TEAL)
	UIK.text(column, Game.t("Science points measure data RECEIVED on Earth. Samples stay in their tubes on Mars; remote analyses and findings are data. The game does not treat them as the same thing.", "Los puntos de ciencia miden datos RECIBIDOS en la Tierra. Las muestras se quedan en sus tubos en Marte; los análisis remotos y los hallazgos son datos. El juego no los trata como lo mismo."), 13, UIK.MUTED)
	var right := UIK.panel(self, Rect2(650, 84, 606, 620))
	var side := UIK.scroll(right, Rect2(20, 14, 568, 592))
	UIK.label(side, Game.t("DR. OWEN'S RECOMMENDATIONS · from your saved missions", "RECOMENDACIONES DE LA DRA. OWEN · según tus misiones guardadas"), 15, UIK.RUST, "bold")
	for advice in Data.recommendations(Game.history):
		var card := UIK.card(side, Game.tt(advice.issue).to_upper(), UIK.ORANGE, UIK.CREAM)
		UIK.text(card, Game.tt(advice.why), 15, UIK.INK)
		UIK.text(card, Game.tt(advice.tip), 15, UIK.TEAL)
	UIK.text(side, Game.t("Recommendations never change your rover. The decision is yours.", "Las recomendaciones nunca cambian tu rover. La decisión es tuya."), 13, UIK.MUTED)
	UIK.label(side, Game.t("MISSION LOG", "BITÁCORA DE MISIONES"), 15, UIK.RUST, "bold")
	if Game.history.is_empty(): UIK.text(side, Game.t("No missions flown yet.", "Aún no has volado ninguna misión."), 15, UIK.MUTED)
	for i in range(Game.history.size() - 1, -1, -1):
		var entry: Dictionary = Game.history[i]
		var flags: Dictionary = entry.get("flags", {})
		var notes: Array = []
		if float(flags.get("safe", 0)) > 0: notes.append(Game.t("safe mode", "modo seguro"))
		if float(flags.get("mem_full", 0)) > 0: notes.append(Game.t("memory full", "memoria llena"))
		if float(flags.get("left", 0)) > 0: notes.append(Game.t("data left on Mars", "datos sin enviar"))
		if float(flags.get("damage", 0)) > 0: notes.append(Game.t("rover damage", "daño al rover"))
		if float(flags.get("blocked", 0)) > 0: notes.append(Game.t("objectives out of reach", "objetivos fuera de alcance"))
		if float(flags.get("timeout", 0)) > 0: notes.append(Game.t("time ran out", "sin tiempo"))
		UIK.text(side, "%d.  %s  ·  %s %s  ·  %s" % [i + 1, Game.tt(Data.ZONES[String(entry.zone)].name), Game.t("grade", "nota"), String(entry.grade), ", ".join(notes) if not notes.is_empty() else Game.t("no issues", "sin incidencias")], 15, UIK.INK)
	UIK.label(side, Game.t("ACHIEVEMENTS  %d / %d", "LOGROS  %d / %d") % [Game.achievements.size(), Data.ACHIEVEMENT_ORDER.size()], 15, UIK.RUST, "bold")
	var go := UIK.button(side, Game.t("Open achievements", "Abrir logros"), func() -> void: Game.go("achievements"), "teal", Vector2(240, 42))
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UIK.focus_first(side)
