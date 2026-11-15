extends BaseScreen
## Informe final (evaluación forense). La Dra. Owen resume qué se planeó, qué pasó y por qué.
## Seis dimensiones, cada una calculada con variables que el juego registra de verdad.
## Los valores son un MODELO EDUCATIVO del juego, no cifras de la NASA. No se inventan hallazgos:
## solo aparece lo que el jugador hizo en esta misión.

var report: Dictionary
var grade := "D"
var detail_open := false
var right_column: VBoxContainer

func _ready() -> void:
	backdrop = "plain"
	report = Game.report
	grade = String(report.get("grade", "D"))
	var zone: Dictionary = Data.ZONES[String(report.get("zone", Game.zone))]
	var head := title(Game.t("MISSION DEBRIEF", "INFORME DE MISIÓN"), Vector2(170, 6), 34)
	var where := UIK.label(self, "%s  ·  %s  ·  %s · %s%s" % [Game.mission_name if not report.get("sandbox", false) else "Sandbox", Game.rover_name, Game.tt(zone.goal), Game.tt(zone.name), Game.t("  ·  CO-OP", "  ·  COOPERATIVO") if report.get("coop", false) else ""], 16, UIK.MINT, "bold")
	where.position = Vector2(174, 52)
	portrait(self, Rect2(24, 8, 132, 132), grade in ["S", "A", "B"])
	var words := UIK.text(self, "%s: %s" % [Game.owen(), verdict()], 15, UIK.PAPER)
	words.position = Vector2(174, 76)
	words.size = Vector2(900, 66)
	var tiles := dimensions()
	for i in range(tiles.size()):
		var tile: Dictionary = tiles[i]
		var card := UIK.panel(self, Rect2(24 + i * 207, 146, 197, 136), UIK.PAPER, 16)
		var column := UIK.column(card, Rect2(12, 8, 173, 122), 1)
		UIK.label(column, String(tile.name).to_upper(), 12, UIK.MUTED, "bold")
		UIK.label(column, String(tile.value), 25, UIK.NAVY, "title")
		if float(tile.ratio) >= 0.0:
			var bar := ProgressBar.new()
			bar.max_value = 1.0
			bar.value = 0.0
			bar.show_percentage = false
			bar.custom_minimum_size = Vector2(0, 8)
			bar.add_theme_stylebox_override("background", UIK.box(Color(UIK.NAVY, 0.15), 4, Color.TRANSPARENT, 0, 0))
			bar.add_theme_stylebox_override("fill", UIK.box(tile.color, 4, Color.TRANSPARENT, 0, 0))
			column.add_child(bar)
			if Game.reduced_motion: bar.value = clampf(float(tile.ratio), 0.0, 1.0)
			else:
				var grow := bar.create_tween()
				grow.tween_interval(0.25 + 0.08 * i)
				grow.tween_property(bar, "value", clampf(float(tile.ratio), 0.0, 1.0), 0.5)
		var note := UIK.text(column, String(tile.note), 12, UIK.INK)
		note.max_lines_visible = 3
		UIK.pop(card, 0.06 * i)
	var left := UIK.panel(self, Rect2(24, 292, 500, 362))
	var column_left := UIK.scroll(left, Rect2(20, 12, 464, 340))
	column_left.add_theme_constant_override("separation", 4)
	fill_left(column_left, zone)
	var right := UIK.panel(self, Rect2(536, 292, 720, 362))
	right_column = UIK.scroll(right, Rect2(22, 12, 680, 340))
	right_column.add_theme_constant_override("separation", 5)
	fill_right()
	var model := UIK.label(self, Game.t("Kilograms, credits, W, Wh, MB and times are a game model, not NASA figures.", "Kilogramos, créditos, W, Wh, MB y tiempos son un modelo de juego, no cifras de la NASA."), 12, Color(UIK.PAPER, 0.7))
	model.position = Vector2(28, 664)
	var buttons := UIK.row(self, 10)
	buttons.position = Vector2(536, 662)
	if report.get("sandbox", false):
		UIK.button(buttons, Game.t("Back to Sandbox", "Volver a Sandbox"), func() -> void: Game.go("design"), "go", Vector2(250, 48))
	else:
		UIK.button(buttons, Game.t("Earth station", "Base terrestre"), func() -> void: Game.go("hub"), "go", Vector2(200, 48))
		UIK.button(buttons, Game.t("Redesign and retry", "Rediseñar y reintentar"), func() -> void: Game.go("design"), "primary", Vector2(250, 48))
	wait_button(buttons).custom_minimum_size = Vector2(250, 48)
	Game.sfx("done" if grade in ["S", "A", "B"] else "bad")
	UIK.pop(left, 0.3)
	UIK.pop(right, 0.4)
	UIK.focus_first(buttons)

func clock_text(seconds: float) -> String:
	if seconds < 90.0: return "%d s" % int(round(seconds))
	return "%d min %02d s" % [int(seconds) / 60, int(seconds) % 60]

func fill_left(column: VBoxContainer, zone: Dictionary) -> void:
	var build: Dictionary = report.get("build", Game.build)
	var plan: Dictionary = report.get("plan", Game.plan)
	UIK.label(column, Game.t("MISSION OVERVIEW", "RESUMEN DE MISIÓN"), 13, UIK.RUST, "bold")
	var reason: String = {"player": Game.t("ended by the team", "terminada por el equipo"), "time": Game.t("mission time ran out", "se agotó el tiempo de misión"), "wheels": Game.t("the rover could not continue", "el rover no pudo continuar")}.get(String(report.get("reason", "player")), "")
	UIK.text(column, Game.t("Destination: Jezero Crater · %s. Duration %s of %s (%s).", "Destino: cráter Jezero · %s. Duración %s de %s (%s).") % [Game.tt(zone.name), clock_text(float(report.get("time", 0.0))), clock_text(float(report.get("time_limit", 0.0))), reason], 14, UIK.INK)
	if plan.has("profile") and not report.get("sandbox", false):
		UIK.text(column, Game.t("Plan: %s · %s · %s · priority: %s.", "Plan: %s · %s · %s · prioridad: %s.") % [Game.tt(Data.PROFILES[String(plan.profile)].name), Game.tt(Data.WINDOWS[String(plan.window)].name), Game.tt(Data.SITES[String(plan.site)].name), Game.tt(Data.PRIORITIES[String(plan.priority)].name)], 14, UIK.INK)
	UIK.label(column, Game.t("REQUIRED OBJECTIVES", "OBJETIVOS REQUERIDOS"), 13, UIK.RUST, "bold")
	for goal in report.get("goals", []):
		if not goal.opt: UIK.text(column, ("✓  " if goal.done else "✗  ") + "%s  (%d/%d)" % [goal.text, int(minf(goal.value, goal.need)), int(goal.need)], 14, UIK.GOOD if goal.done else UIK.BAD)
	UIK.label(column, Game.t("OPTIONAL OBJECTIVES", "OBJETIVOS OPCIONALES"), 13, UIK.TEAL, "bold")
	for goal in report.get("goals", []):
		if goal.opt: UIK.text(column, ("✓  " if goal.done else "–  ") + "%s  (%d/%d)%s" % [goal.text, int(minf(goal.value, goal.need)), int(goal.need), "" if goal.done or float(goal.value) > 0.0 else Game.t("  · skipped", "  · no intentado")], 14, UIK.GOOD if goal.done else UIK.MUTED)
	UIK.label(column, Game.t("THE PATH OF YOUR DATA", "EL CAMINO DE TUS DATOS"), 13, UIK.RUST, "bold")
	var generated := float(report.get("collected", 0.0)) + float(report.get("unrecorded", 0.0))
	UIK.text(column, Game.t("Generated %d MB  →  recorded %d MB  →  received on Earth %d MB  →  %d science points", "Generado %d MB  →  grabado %d MB  →  recibido en la Tierra %d MB  →  %d puntos de ciencia") % [int(round(generated)), int(round(float(report.get("collected", 0.0)))), int(round(float(report.get("received", 0.0)))), int(report.get("science", 0))], 14, UIK.NAVY)
	var lost := int(report.get("lost", 0))
	var dropped := int(report.get("unrecorded", 0))
	if lost > 0 or dropped > 0: UIK.text(column, Game.t("Never transmitted: %d MB  ·  never recorded (memory full): %d MB", "Sin transmitir: %d MB  ·  sin grabar (memoria llena): %d MB") % [lost, dropped], 14, UIK.BAD)
	var received := float(report.get("received", 0.0))
	if received >= 1.0: UIK.text(column, Game.t("Real-world scale: over Perseverance's UHF relay (up to about 2 Mbps, NASA) %d MB need roughly %s of orbiter pass.", "A escala real: por el relevo UHF de Perseverance (hasta unos 2 Mbps, NASA) %d MB requieren alrededor de %s de paso del orbitador.") % [int(round(received)), clock_text(received * 8.0 / float(Data.REAL_LINK.uhf_mbps))], 13, UIK.TEAL)
	UIK.label(column, Game.t("SCIENCE RESULTS (from this mission only)", "RESULTADOS CIENTÍFICOS (solo de esta misión)"), 13, UIK.RUST, "bold")
	UIK.text(column, Game.t("Rocks investigated: %d  ·  photos: %d  ·  analyses: %d  ·  samples: %d  ·  findings reported at the right certainty on the first try: %d of %d", "Rocas investigadas: %d  ·  fotos: %d  ·  análisis: %d  ·  muestras: %d  ·  hallazgos informados con la certeza correcta al primer intento: %d de %d") % [int(report.get("rocks", 0)), int(report.get("photos", 0)), int(report.get("analyses", 0)), int(report.get("cached", 0)), int(report.get("quiz_right", 0)), int(report.get("quiz_asked", 0))], 14, UIK.INK)
	var samples: Array = report.get("samples", [])
	if not samples.is_empty():
		UIK.label(column, Game.t("SAMPLE CATALOGUE (FICTIONAL GAME SAMPLES)", "CATÁLOGO DE MUESTRAS (MUESTRAS FICTICIAS DEL JUEGO)"), 13, UIK.RUST, "bold")
		for i in range(samples.size()):
			var sample: Dictionary = samples[i]
			var rock: Dictionary = Data.ROCKS[sample.type]
			var context := (Game.t("site documented, %d photo(s)", "sitio documentado, %d foto(s)") % int(sample.get("photos", 1))) if sample.documented else Game.t("no context image", "sin imagen de contexto")
			var kind := Game.t("core", "núcleo") if String(sample.get("tool", "drill")) == "drill" else Game.t("regolith", "regolito")
			UIK.text(column, "2M-%s-%02d  ·  %s (%s%s)  ·  %s" % [String(report.get("zone", "x")).substr(0, 1).to_upper(), i + 1, Game.tt(rock.name), kind, Game.t(", partial", ", parcial") if sample.get("partial", false) else "", context], 14, UIK.GOOD if sample.documented else UIK.SAND)
			if int(rock.analog) >= 0:
				var real: Dictionary = Data.REAL_SAMPLES[int(rock.analog)]
				UIK.text(column, Game.t("     Real sample of a similar kind: %s (%s), sample %d, sol %d — NASA.", "     Muestra real de tipo parecido: %s (%s), muestra %d, sol %d — NASA.") % [String(real.name), Game.tt(real.kind), int(real.number), int(real.sol)], 12, UIK.MUTED)
		UIK.link(column, Game.t("See the real Perseverance samples and photos (NASA)", "Ver las muestras y fotos reales de Perseverance (NASA)"), Data.SAMPLES_URL)

func fill_right() -> void:
	for child in right_column.get_children(): child.queue_free()
	var found := causes()
	UIK.label(right_column, Game.t("WHY IT TURNED OUT THIS WAY", "POR QUÉ SALIÓ ASÍ"), 13, UIK.RUST, "bold")
	for line in found.why: UIK.text(right_column, "•  " + String(line), 14, UIK.INK)
	UIK.label(right_column, Game.t("WHAT YOUR DESIGN DID WELL", "LO QUE TU DISEÑO HIZO BIEN"), 13, UIK.GOOD, "bold")
	for line in found.good: UIK.text(right_column, "✓  " + String(line), 14, UIK.INK)
	UIK.label(right_column, Game.t("FOR YOUR NEXT MISSION · your decision", "PARA TU PRÓXIMA MISIÓN · tú decides"), 13, UIK.TEAL, "bold")
	for line in found.next: UIK.text(right_column, "→  " + String(line), 14, UIK.TEAL)
	if not report.get("sandbox", false) and Game.history.size() > 1:
		var advice: Dictionary = Data.recommendations(Game.history)[0]
		UIK.text(right_column, Game.t("Across your last missions — %s: %s", "En tus últimas misiones — %s: %s") % [Game.tt(advice.issue), Game.tt(advice.why)], 13, UIK.MUTED)
	UIK.text(right_column, "%s: %s" % [Game.owen(), Game.t("Remember: a successful mission is not only about how many samples we collect. It is about the quality of the data, the decisions we make and what we learn when things do not go as planned.", "Recuerda: una misión exitosa no depende solo de cuántas muestras recolectamos. Depende de la calidad de los datos, de las decisiones que tomamos y de lo que aprendemos cuando las cosas no salen como esperábamos.")], 14, UIK.NAVY)
	var toggle := UIK.button(right_column, Game.t("Hide the planned vs. actual table", "Ocultar la tabla de planeado y real") if detail_open else Game.t("Show planned vs. actual and how each score is calculated", "Ver planeado frente a real y cómo se calcula cada puntuación"), func() -> void:
		detail_open = not detail_open
		fill_right(), "ghost", Vector2(0, 36))
	toggle.add_theme_font_size_override("font_size", 14)
	if detail_open:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 16)
		right_column.add_child(grid)
		for item in [[Game.t("", ""), Game.t("PLANNED", "PLANEADO"), Game.t("ACTUAL", "REAL")],
			[Game.t("Required objectives", "Objetivos requeridos"), str(int(report.get("required", 0))), str(int(report.get("done", 0)))],
			[Game.t("Data on Earth", "Datos en la Tierra"), "%d MB" % int(Data.need_mb(String(report.zone), report.get("plan", Game.plan))), "%d MB" % int(report.get("received", 0))],
			[Game.t("Mission time", "Tiempo de misión"), clock_text(float(report.get("time_limit", 0))), clock_text(float(report.get("time", 0)))],
			[Game.t("Budget", "Presupuesto"), "%d cr" % int(report.get("budget", 0)), "%d cr" % int(report.get("cost", 0))],
			[Game.t("Mass", "Masa"), "%d kg" % int(report.get("mass_cap", 0)), "%d kg" % int(report.get("mass", 0))],
			[Game.t("Rover health", "Salud del rover"), "100%", "%d%%" % int(report.get("integrity", 0))]]:
			for cell in item: UIK.label(grid, String(cell), 13, UIK.INK, "bold")
		UIK.text(right_column, Game.t("How the scores work — Mission success: required objectives done ÷ required. Scientific return: science points received ÷ this zone's reference (%d). Data return: MB received ÷ MB generated, each MB counted once. Schedule: 100 if you finish in 60%% of the time, 60 at the limit. Budget: share of the payload budget that produced data. Resource efficiency: 100 − 12 per safe mode − half the health lost − 5 per memory-full event. Grade = 30%% mission + 25%% science + 15%% data + 10%% each of the others; S and A need every required objective.", "Cómo se puntúa — Éxito de misión: objetivos requeridos cumplidos ÷ requeridos. Retorno científico: puntos de ciencia recibidos ÷ referencia de esta zona (%d). Retorno de datos: MB recibidos ÷ MB generados, cada MB contado una vez. Cronograma: 100 si terminas en el 60%% del tiempo, 60 en el límite. Presupuesto: parte del presupuesto de carga útil que produjo datos. Eficiencia de recursos: 100 − 12 por modo seguro − la mitad de la salud perdida − 5 por cada memoria llena. Nota = 30%% misión + 25%% ciencia + 15%% datos + 10%% cada una de las demás; S y A exigen todos los objetivos requeridos.") % int(report.get("science_ref", 0)), 12, UIK.MUTED)
	var sources := UIK.row(right_column, 8)
	UIK.link(sources, Game.t("NASA: science objectives", "NASA: objetivos científicos"), String(Data.SOURCES[0][1]))
	UIK.link(sources, Game.t("NASA: instruments", "NASA: instrumentos"), String(Data.SOURCES[1][1]))

## Seis dimensiones. ratio < 0 significa "no aplica" (no hay dato fiable): no se inventa un número.
func dimensions() -> Array:
	var dims: Dictionary = report.get("dims", {})
	var out: Array = []
	var done := int(report.get("done", 0))
	var required := int(report.get("required", 0))
	out.append({"name": Game.t("Mission success", "Éxito de misión"), "value": "%d / %d" % [done, required], "ratio": float(dims.get("mission", 0.0)) / 100.0, "color": UIK.GOOD, "note": Game.t("required objectives · %d optional", "objetivos requeridos · %d opcionales") % int(report.get("optional_done", 0))})
	out.append({"name": Game.t("Scientific return", "Retorno científico"), "value": "%d%%" % int(round(float(dims.get("science", 0.0)))), "ratio": float(dims.get("science", 0.0)) / 100.0, "color": UIK.TEAL, "note": Game.t("%d science points on Earth", "%d puntos de ciencia en la Tierra") % int(report.get("science", 0))})
	var data := float(dims.get("data", -1.0))
	if data >= 0.0: out.append({"name": Game.t("Data return", "Retorno de datos"), "value": "%d%%" % int(round(data)), "ratio": data / 100.0, "color": UIK.MINT.darkened(0.2), "note": Game.t("%d of %d MB received", "%d de %d MB recibidos") % [int(round(float(report.get("received", 0.0)))), int(round(float(report.get("collected", 0.0)) + float(report.get("unrecorded", 0.0))))]})
	else: out.append({"name": Game.t("Data return", "Retorno de datos"), "value": "—", "ratio": -1.0, "color": UIK.TEAL, "note": Game.t("not applicable: no data was generated", "no aplica: no se generaron datos")})
	var note := Game.t("ended early", "terminó antes")
	if String(report.get("reason", "")) == "time": note = Game.t("time ran out", "se agotó el tiempo")
	elif done == required and required > 0: note = Game.t("done with %s to spare", "listo, sobraron %s") % clock_text(maxf(0.0, float(report.get("time_limit", 0.0)) - float(report.get("time", 0.0))))
	out.append({"name": Game.t("Schedule", "Cronograma"), "value": "%d%%" % int(round(float(dims.get("schedule", 0.0)))), "ratio": float(dims.get("schedule", 0.0)) / 100.0, "color": UIK.SAND, "note": note})
	var budget := float(dims.get("budget", -1.0))
	var unused: Array = report.get("unused", [])
	if budget >= 0.0: out.append({"name": Game.t("Budget", "Presupuesto"), "value": "%d%%" % int(round(budget)), "ratio": budget / 100.0, "color": UIK.ORANGE, "note": (Game.t("of the payload was used · %d of %d cr spent", "de la carga útil se usó · %d de %d cr gastados") % [int(report.get("cost", 0)), int(report.get("budget", 0))])})
	else: out.append({"name": Game.t("Budget", "Presupuesto"), "value": "—", "ratio": -1.0, "color": UIK.ORANGE, "note": Game.t("not applicable: no science payload", "no aplica: sin carga científica")})
	out.append({"name": Game.t("Resource efficiency", "Eficiencia de recursos"), "value": "%d%%" % int(round(float(dims.get("resource", 0.0)))), "ratio": float(dims.get("resource", 0.0)) / 100.0, "color": UIK.RUST, "note": Game.t("health %d%% · %d safe mode(s) · %d Wh used", "salud %d%% · %d modo(s) seguro(s) · %d Wh usados") % [int(report.get("integrity", 0)), int(report.get("safe", 0)), int(report.get("energy_used", 0))]})
	return out

## Análisis de causas: conecta el resultado con el diseño, el plan y la operación.
func causes() -> Dictionary:
	var why: Array = []
	var good: Array = []
	var next: Array = []
	var build: Dictionary = report.get("build", Game.build)
	var reason := String(report.get("reason", ""))
	var flight: Dictionary = report.get("flight", {})
	for note in report.get("readiness", []):
		if note.ok or note.opt: continue
		why.append(Game.t("\"%s\" was out of reach from launch: the design %s.", "«%s» quedó fuera de alcance desde el lanzamiento: el diseño %s.") % [Game.tt(note.text), Game.tt(note.why)])
	if why.size() > 0: next.append(Game.t("Read the scientific limitations in Mission Readiness before launching: each one names the missing instrument.", "Lee las limitaciones científicas en Mission Readiness antes de lanzar: cada una nombra el instrumento que falta."))
	var safe := int(report.get("safe", 0))
	if safe > 0:
		var line := Game.t("The battery ran empty %d time(s) and the rover waited in safe mode. It stores %d Wh", "La batería se agotó %d vez/veces y el rover esperó en modo seguro. Guarda %d Wh") % [safe, int(report.get("battery", 0))]
		line += Game.t(", and solar panels give nothing at night while the heaters keep running.", ", y los paneles solares no dan nada de noche mientras los calentadores siguen encendidos.") if report.get("solar", false) else "."
		why.append(line)
		next.append(Game.t("More stored energy (Extended Battery) or steady power (RTG) costs mass and credits. Or run fewer demanding activities per charge.", "Más energía almacenada (Batería extendida) o energía constante (RTG) cuesta masa y créditos. O haz menos actividades exigentes por carga."))
	var dropped := int(report.get("unrecorded", 0))
	if dropped >= 1:
		why.append(Game.t("%d MB of measurements were never recorded: the %d MB memory was full.", "%d MB de mediciones nunca se grabaron: la memoria de %d MB estaba llena.") % [dropped, int(report.get("memory", 0))])
		next.append(Game.t("Large Storage holds more between passes; the Advanced Computer compresses data. Or transmit before the memory fills.", "Almacenamiento grande guarda más entre pasos; la Computadora avanzada comprime datos. O transmite antes de que la memoria se llene."))
	var lost := int(report.get("lost", 0))
	if lost >= 1:
		var line2 := Game.t("%d MB stayed on the rover and never became science on Earth.", "%d MB se quedaron en el rover y nunca se volvieron ciencia en la Tierra.") % lost
		if not Data.has(build, "hga"): line2 += Game.t(" With the UHF relay alone, data only moves while an orbiter is overhead.", " Solo con el relevo UHF, los datos se mueven únicamente mientras pasa un orbitador.")
		why.append(line2)
		next.append(Game.t("Leave time for a last transmission. A second antenna gives a link outside orbiter passes.", "Deja tiempo para una última transmisión. Una segunda antena da enlace fuera de los pasos del orbitador."))
	var landing := float(flight.get("damage", 0.0))
	if landing >= 6.0: why.append(Game.t("The landing alone cost %d%% of rover health: %s on the %s.", "Solo el aterrizaje costó %d%% de salud: %s en %s.") % [int(landing), Data.comp_name(String(build.chassis)), Game.tt(Data.SITES[String(report.get("plan", {}).get("site", "flat"))].name).to_lower()])
	if float(report.get("integrity", 100.0)) < 60.0:
		why.append(Game.t("The rover ended at %d%% health. %s and %s set how much each rock and collision hurt.", "El rover terminó con %d%% de salud. %s y %s fijaron cuánto dañó cada roca y cada choque.") % [int(report.get("integrity", 0)), Data.comp_name(String(build.wheels)), Data.comp_name(String(build.chassis))])
		next.append(Game.t("Reinforced wheels resist sharp rock and a stronger chassis absorbs collisions, at the price of mass. Or plan a route around the dark patches.", "Las ruedas reforzadas resisten la roca afilada y un chasis más fuerte absorbe choques, a cambio de masa. O planea una ruta que rodee las manchas oscuras."))
	var unused: Array = report.get("unused", [])
	if not unused.is_empty():
		var names: Array = []
		var idle_mass := 0
		var idle_cost := 0
		for id in unused:
			names.append(Data.comp_name(id))
			idle_mass += int(Data.COMPONENTS[id].mass)
			idle_cost += int(Data.COMPONENTS[id].cost)
		why.append(Game.t("Flown to Mars but never used: %s (%d kg and %d cr).", "Viajó a Marte pero nunca se usó: %s (%d kg y %d cr).") % [", ".join(names), idle_mass, idle_cost])
		next.append(Game.t("Payload you will not use is mass and budget that could buy battery, memory or mobility.", "La carga que no vas a usar es masa y presupuesto que podrían comprar batería, memoria o movilidad."))
	if int(report.get("failed_samples", 0)) > 0: why.append(Game.t("A coring attempt came back empty: the rock was fragile. Reviewing the images before drilling shows which rocks will crumble.", "Un intento de extracción volvió vacío: la roca era frágil. Revisar las imágenes antes de perforar muestra qué rocas se desmoronan."))
	if reason == "time" and int(report.get("done", 0)) < int(report.get("required", 0)):
		why.append(Game.t("Mission time ran out with required objectives pending. This %d kg rover drove %d m.", "El tiempo de misión se agotó con objetivos requeridos pendientes. Este rover de %d kg recorrió %d m.") % [int(report.get("mass", 0)), int(float(report.get("driven", 0.0)) / 10.0)])
		next.append(Game.t("A lighter rover is faster and cheaper to drive. AutoNav, or landing near the outcrops, saves driving time.", "Un rover más ligero es más rápido y barato de conducir. AutoNav, o aterrizar junto a los afloramientos, ahorra tiempo de conducción."))
	if String(flight.get("energy_choice", "")) == "save": good.append(Game.t("Energy-saving mode in cruise: the rover landed with a full battery.", "Modo de ahorro en el crucero: el rover aterrizó con la batería llena."))
	if safe == 0: good.append(Game.t("The energy system covered every activity: no safe mode.", "El sistema de energía cubrió todas las actividades: sin modo seguro."))
	if lost < 1 and float(report.get("received", 0.0)) > 1.0: good.append(Game.t("Everything recorded reached Earth.", "Todo lo grabado llegó a la Tierra."))
	if unused.is_empty() and float(report.get("dims", {}).get("budget", -1.0)) >= 0.0: good.append(Game.t("Every science payload you paid for produced data.", "Toda la carga científica que pagaste produjo datos."))
	var samples: Array = report.get("samples", [])
	if not samples.is_empty() and samples.all(func(sample: Dictionary) -> bool: return sample.documented): good.append(Game.t("Every sample was documented with its site before collection.", "Todas las muestras se documentaron con su sitio antes de recolectarlas."))
	if int(report.get("cost", 0)) < int(report.get("budget", 1)) * 0.75: good.append(Game.t("The mission flew on less than 75% of its budget.", "La misión voló con menos del 75% de su presupuesto."))
	if why.is_empty(): why.append(Game.t("The design fit the science: every instrument the zone needed was on board, and the data came home.", "El diseño encajó con la ciencia: todos los instrumentos que la zona pedía iban a bordo y los datos llegaron a casa."))
	if good.is_empty(): good.append(Game.t("The rover reached Mars and returned real measurements. That is a base to improve on.", "El rover llegó a Marte y devolvió mediciones reales. Es una base sobre la que mejorar."))
	if next.is_empty(): next.append(Game.t("Try the same zone with a lighter or cheaper rover, or a harder mission profile, and compare the two reports.", "Prueba la misma zona con un rover más ligero o más barato, o un perfil más exigente, y compara los dos informes."))
	return {"why": why.slice(0, 5), "good": good.slice(0, 3), "next": next.slice(0, 3)}

func verdict() -> String:
	var reason := String(report.get("reason", ""))
	var opening := ""
	var who := Game.player_name if Game.player_name != "" else Game.t("Commander", "Comandante")
	if reason == "wheels": opening = Game.t("We lost mobility before the plan was done. ", "Perdimos movilidad antes de terminar el plan. ")
	elif reason == "time" and int(report.get("done", 0)) < int(report.get("required", 0)): opening = Game.t("We ran out of mission time. ", "Se nos acabó el tiempo de misión. ")
	match grade:
		"S": return opening + Game.t("Outstanding, %s. The design fit the science, the data came home and the evidence was reported with care.", "Sobresaliente, %s. El diseño encajó con la ciencia, los datos llegaron a casa y la evidencia se informó con cuidado.") % who
		"A": return opening + Game.t("Excellent work, %s. The team on Earth has what it needs to tell this zone's story.", "Excelente trabajo, %s. El equipo en la Tierra tiene lo necesario para contar la historia de esta zona.") % who
		"B": return opening + Game.t("A solid mission, %s. Some objectives or megabytes stayed out of reach: look at what held them back.", "Una misión sólida, %s. Algunos objetivos o megabytes quedaron fuera de alcance: mira qué los frenó.") % who
		"C": return opening + Game.t("We learned something, %s, but much of the plan did not reach Earth. Rethink the design or the route.", "Aprendimos algo, %s, pero buena parte del plan no llegó a la Tierra. Replantea el diseño o la ruta.") % who
	return opening + Game.t("Very little science came home, %s. In engineering, finding the problem is part of the job: change one decision and try again.", "Muy poca ciencia volvió a casa, %s. En ingeniería, detectar el problema también es parte del trabajo: cambia una decisión e inténtalo otra vez.") % who

func paint() -> void:
	Art.badge(self, Vector2(1180, 76), 54.0 + (sin(time * 2.0) * 2.0 if not Game.reduced_motion else 0.0), grade, time)
	draw_string(UIK.bold_font, Vector2(1120, 150), Game.t("GRADE", "NOTA"), HORIZONTAL_ALIGNMENT_CENTER, 120, 13, UIK.CREAM)
