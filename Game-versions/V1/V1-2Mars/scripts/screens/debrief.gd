extends Control
## Informe final. La Dra. Owen resume qué se logró y cómo influyó el diseño.

var time := 0.0

func _ready() -> void:
	var report: Dictionary = Game.report
	var zone: Dictionary = Data.ZONES[String(report.get("zone", Game.zone))]
	var grade := String(report.get("grade", "D"))
	var title := UIK.label(self, Game.t("Mission debrief", "Informe de misión"), 40, UIK.NAVY, "title")
	title.position = Vector2(250, 22)
	var where := UIK.label(self, "%s · %s" % [Game.tt(zone.goal), Game.tt(zone.name)], 20, UIK.TEAL, "bold")
	where.position = Vector2(252, 76)
	var left := UIK.panel(self, Rect2(36, 250, 590, 440))
	var column := UIK.column(left, Rect2(24, 18, 542, 410), 7)
	UIK.label(column, Game.t("OBJECTIVES", "OBJETIVOS"), 14, UIK.MUTED, "bold")
	for goal in report.get("goals", []):
		UIK.text(column, ("✓  " if goal.done else "✗  ") + "%s  (%d/%d)" % [goal.text, int(minf(goal.value, goal.need)), int(goal.need)], 16, UIK.GOOD if goal.done else UIK.BAD)
	UIK.label(column, Game.t("WHAT YOUR DESIGN DECIDED", "LO QUE DECIDIÓ TU DISEÑO"), 14, UIK.MUTED, "bold")
	var blocked := 0
	for note in report.get("readiness", []):
		if note.ok: continue
		blocked += 1
		UIK.text(column, "•  %s: %s." % [Game.tt(note.text), Game.tt(note.why)], 15, UIK.INK)
	if blocked == 0: UIK.text(column, Game.t("•  The rover carried every instrument this zone needed. The rest was operations.", "•  El rover llevaba todos los instrumentos que la zona pedía. Lo demás fue operación."), 15, UIK.INK)
	var right := UIK.panel(self, Rect2(650, 110, 594, 580))
	var side := UIK.column(right, Rect2(26, 18, 542, 470), 8)
	UIK.text(side, Game.t("Dr. Owen: ", "Dra. Owen: ") + verdict(grade, report), 18, UIK.INK)
	UIK.label(side, Game.t("THE PATH OF YOUR DATA", "EL CAMINO DE TUS DATOS"), 14, UIK.MUTED, "bold")
	UIK.text(side, Game.t("Collected on Mars: %d MB", "Recolectado en Marte: %d MB") % int(report.get("collected", 0)), 17, UIK.NAVY)
	UIK.text(side, Game.t("Received on Earth: %d MB  →  %d science points", "Recibido en la Tierra: %d MB  →  %d puntos de ciencia") % [int(report.get("received", 0)), int(report.get("science", 0))], 17, UIK.GOOD)
	var lost := int(report.get("lost", 0))
	UIK.text(side, Game.t("Left on the rover, never transmitted: %d MB", "Quedó en el rover, sin transmitir: %d MB") % lost, 17, UIK.BAD if lost > 0 else UIK.MUTED)
	UIK.label(side, Game.t("ROVER", "ROVER"), 14, UIK.MUTED, "bold")
	UIK.text(side, Game.t("Wheels %d%%  ·  energy used %d  ·  mission time %d:%02d", "Ruedas %d%%  ·  energía usada %d  ·  tiempo de misión %d:%02d") % [int(report.get("integrity", 0)), int(report.get("energy_used", 0)), int(report.get("time", 0)) / 60, int(report.get("time", 0)) % 60], 16, UIK.INK)
	UIK.text(side, Game.t("Findings reported at the right level of certainty: %d of %d", "Hallazgos informados con el nivel de certeza correcto: %d de %d") % [int(report.get("quiz_right", 0)), int(report.get("quiz_asked", 0))], 16, UIK.INK)
	var samples: Array = report.get("samples", [])
	if not samples.is_empty():
		UIK.label(side, Game.t("SAMPLE CATALOGUE (FICTIONAL)", "CATÁLOGO DE MUESTRAS (FICTICIO)"), 14, UIK.MUTED, "bold")
		for i in range(samples.size()):
			var sample: Dictionary = samples[i]
			var context := Game.t("site documented", "sitio documentado") if sample.documented else Game.t("no context image", "sin imagen de contexto")
			UIK.text(side, "TM-%s-%02d  ·  %s  ·  %s" % [String(report.get("zone", "x")).substr(0, 1).to_upper(), i + 1, Game.tt(Data.ROCKS[sample.type].name), context], 15, UIK.GOOD if sample.documented else UIK.SAND)
	var buttons := UIK.row(right, 14)
	buttons.position = Vector2(26, 506)
	UIK.button(buttons, Game.t("Mission map", "Mapa de misión"), func() -> void: Game.go("zones"), "primary", Vector2(264, 56))
	UIK.button(buttons, Game.t("Redesign and retry", "Rediseñar y reintentar"), func() -> void: Game.go("design"), "teal", Vector2(264, 56))
	Game.sfx("done" if grade in ["S", "A", "B"] else "bad")
	UIK.pop(left, 0.1)
	UIK.pop(right, 0.2)

func verdict(grade: String, report: Dictionary) -> String:
	var reason := String(report.get("reason", ""))
	var opening := ""
	if reason == "wheels": opening = Game.t("The wheels gave out and the rover is now a fixed station. ", "Las ruedas cedieron y el rover es ahora una estación fija. ")
	elif reason == "time": opening = Game.t("The prime mission has reached its end. ", "La misión principal llegó a su fin. ")
	match grade:
		"S": return opening + Game.t("Outstanding. The design fit the science and nothing was left behind on Mars.", "Sobresaliente. El diseño encajó con la ciencia y nada se quedó en Marte.")
		"A": return opening + Game.t("Excellent work. The team on Earth has what it needs to tell this zone's story.", "Excelente trabajo. El equipo en la Tierra tiene lo necesario para contar la historia de esta zona.")
		"B": return opening + Game.t("A solid mission. A few objectives or megabytes stayed out of reach: look at what blocked them.", "Una misión sólida. Algunos objetivos o megabytes quedaron fuera de alcance: mira qué los bloqueó.")
		"C": return opening + Game.t("We learned something, but much of the plan did not reach Earth. Rethink the design or the route.", "Aprendimos algo, pero buena parte del plan no llegó a la Tierra. Replantea el diseño o la ruta.")
	return opening + Game.t("Very little science came home. In mission design that is also data: change one decision and try again.", "Muy poca ciencia volvió a casa. En diseño de misiones eso también es un dato: cambia una decisión e inténtalo otra vez.")

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	Art.gradient(self, Rect2(Vector2.ZERO, size), Color("#fff1d6"), Color("#f6cf9f"))
	Art.owen(self, Rect2(40, 20, 190, 190), time, String(Game.report.get("grade", "D")) in ["S", "A", "B"])
	var grade := String(Game.report.get("grade", "D"))
	var tone: Color = {"S": UIK.YELLOW, "A": UIK.GOOD, "B": UIK.TEAL, "C": UIK.SAND, "D": UIK.BAD}[grade]
	var badge := Vector2(548, 172)
	var points := PackedVector2Array()
	for i in range(8): points.append(badge + Vector2.from_angle(TAU * i / 8.0 + time * 0.2) * (64.0 + sin(time * 2.0) * 3.0))
	draw_colored_polygon(points, tone)
	draw_colored_polygon(PackedVector2Array([points[0], points[1], points[2], badge]), tone.lightened(0.2))
	draw_string(UIK.title_font, badge + Vector2(-60, 30), grade, HORIZONTAL_ALIGNMENT_CENTER, 120, 84, UIK.PAPER)
	draw_string(UIK.bold_font, Vector2(250, 130), Game.t("GRADE", "NOTA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIK.MUTED)
	draw_string(UIK.bold_font, Vector2(250, 160), Game.rover_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UIK.NAVY)
