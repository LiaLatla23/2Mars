extends BaseScreen
## Lanzamiento, crucero y entrada-descenso-aterrizaje (guion fase 3).
## Secuencias cortas y saltables; las decisiones y el diseño fijan el estado con el que el
## rover empieza en Marte (Game.flight). La arquitectura de aterrizaje es un MODELO DEL JUEGO
## inspirado en Mars 2020: no reproduce una misión real paso a paso.

var phase := "prep"       # prep | countdown | ascent | cruise | event | edl | landed
var clock := 0.0
var stage: Control
var cruise := 0.0
var events_done := 0
var edl_step := 0
var flight := {"charge": 0.85, "damage": 0.0, "near": 0.0, "delay": 0.0, "comm_choice": "", "energy_choice": ""}
var finished := false
var skip_button: Button
var last_count := -1
var status_lines: Array = []
var checks: Array = []
var clip: VideoStreamPlayer      # cinemática opcional (assets/video/*.ogv); si falta, se usa la animación nativa
var overlay: Control

const EDL := [
	["Atmospheric entry confirmed.", "Entrada atmosférica confirmada."],
	["Heat shield operating correctly.", "Escudo térmico funcionando correctamente."],
	["Parachute deployed.", "Paracaídas desplegado."],
	["Initiating final descent.", "Iniciando descenso final."],
	["Surface contact confirmed!", "¡Contacto con la superficie confirmado!"]
]

func _ready() -> void:
	backdrop = "none"
	skip_button = UIK.button(self, Game.t("Skip  [Esc]", "Saltar  [Esc]"), skip, "ghost", Vector2(150, 40))
	skip_button.position = Vector2(1110, 20)
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.visible = false
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(paint_overlay)
	add_child(overlay)
	portraits.append(overlay)
	show_prep()

## Cinemática pregrabada opcional. Devuelve false si no hay archivo, si el motor no puede
## cargarlo o si el jugador pidió movimiento reducido: entonces se ve la animación nativa.
func play_clip(id: String, loop: bool = false) -> bool:
	stop_clip()
	var path := "res://assets/video/%s.ogv" % id
	if Game.reduced_motion or not ResourceLoader.exists(path): return false
	var stream: Resource = load(path)
	if not stream is VideoStream: return false
	clip = VideoStreamPlayer.new()
	clip.stream = stream
	clip.expand = true
	clip.loop = loop
	clip.volume_db = -80.0
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	move_child(clip, 0)
	clip.play()
	return true

func stop_clip() -> void:
	if is_instance_valid(clip): clip.queue_free()
	clip = null

func has_clip() -> bool:
	return is_instance_valid(clip)

func new_stage() -> void:
	if is_instance_valid(stage): stage.queue_free()
	stage = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	if is_instance_valid(overlay): move_child(overlay, -1)
	move_child(skip_button, -1)

# ------------------------------------------------------------------ preparación
func show_prep() -> void:
	phase = "prep"
	new_stage()
	var build := Game.build
	var cap := Game.limits()
	var s := Data.stats(build)
	checks = Data.check(build, Game.zone, Game.plan)
	var head := UIK.heading(stage, Game.t("LAUNCH PREPARATION", "PREPARACIÓN DE LANZAMIENTO"), 40)
	head.position = Vector2(30, 16)
	var panel := UIK.panel(stage, Rect2(30, 90, 470, 500), Color(UIK.INK, 0.9))
	var column := UIK.column(panel, Rect2(24, 16, 422, 470), 6)
	UIK.label(column, "%s  ·  %s" % [Game.mission_name, Game.rover_name], 22, UIK.CREAM, "title")
	UIK.label(column, Game.t("YOUR CONFIGURATION", "TU CONFIGURACIÓN"), 14, UIK.MINT, "bold")
	for item in [[Game.t("Mass", "Masa"), "%d / %d kg" % [int(s.mass), int(cap.mass)]], [Game.t("Budget", "Presupuesto"), "%d / %d cr" % [Data.cost(build), int(cap.budget)]],
		[Game.t("Power", "Energía"), "%d W · %d Wh" % [int(s.gen_w), int(s.battery)]], [Game.t("Memory", "Memoria"), "%d MB" % int(s.memory)],
		[Game.t("Link", "Enlace"), ("UHF" if s.uhf else "") + (" + " if s.uhf and s.direct else "") + (Game.t("high-gain", "alta ganancia") if s.direct else "")],
		[Game.t("Payload", "Carga útil"), ", ".join(Data.instruments(build).map(func(id: String) -> String: return Data.comp_name(id))) if not Data.instruments(build).is_empty() else Game.t("none", "ninguna")]]:
		var line := UIK.row(column, 8)
		UIK.label(line, String(item[0]), 15, UIK.PAPER, "bold").custom_minimum_size.x = 100
		UIK.text(line, String(item[1]), 15, UIK.CREAM)
	UIK.label(column, Game.t("FINAL CHECKS", "COMPROBACIONES FINALES"), 14, UIK.MINT, "bold")
	var finals := [[Game.t("Mass within the launcher's limit", "Masa dentro del límite del lanzador"), int(s.mass) <= int(cap.mass)], [Game.t("Budget approved", "Presupuesto aprobado"), Data.cost(build) <= int(cap.budget)],
		[Game.t("Link to Earth available", "Enlace con la Tierra disponible"), s.uhf or s.direct], [Game.t("Payload fits and is compatible", "La carga útil cabe y es compatible"), Data.count_level(checks, "blocker") == 0]]
	for i in range(finals.size()):
		var ok: bool = finals[i][1]
		var label := UIK.label(column, ("✓  " if ok else "✗  ") + String(finals[i][0]), 15, UIK.GO if ok else UIK.BAD, "bold")
		UIK.pop(label, 0.25 * (i + 1))
	var risks := Data.count_level(checks, "risk")
	var index := Data.readiness_index(checks, Game.zone)
	UIK.chip(column, "  %s  %d / 100  " % [Game.t("READINESS INDEX", "ÍNDICE DE PREPARACIÓN"), index], UIK.GOOD if index >= 75 else UIK.SAND).add_theme_font_size_override("font_size", 16)
	UIK.text(column, Game.t("Game estimate from your design: %d operational risk(s), %d required objective(s) out of reach. Not a NASA probability.", "Estimación del juego según tu diseño: %d riesgo(s) operativo(s), %d objetivo(s) requerido(s) fuera de alcance. No es una probabilidad de la NASA.") % [risks, Data.count_level(checks, "limit")], 13, UIK.MUTED)
	var go := UIK.button(stage, Game.t("LAUNCH NOW!", "¡LANZAR AHORA!"), start_countdown, "go", Vector2(470, 76))
	go.position = Vector2(30, 610)
	go.add_theme_font_size_override("font_size", 34)
	go.disabled = Data.count_level(checks, "blocker") > 0
	var back := UIK.button(stage, Game.t("← Workshop", "← Taller"), func() -> void: Game.go("design"), "ghost", Vector2(170, 44))
	back.position = Vector2(520, 626)
	UIK.focus_first(stage)

func start_countdown() -> void:
	phase = "countdown"
	clock = 0.0
	last_count = -1
	new_stage()
	skip_button.visible = true
	Game.unlock("first_launch")

func skip() -> void:
	match phase:
		"countdown", "ascent": start_cruise()
		"cruise":
			# Saltar el crucero no salta las decisiones: lleva al siguiente evento pendiente.
			if events_done == 0: cruise = 0.34
			elif events_done == 1: cruise = 0.69
			else: start_edl()
		"edl": land()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and skip_button.visible and phase in ["countdown", "ascent", "cruise", "edl"]: skip()

# ------------------------------------------------------------------ bucle
func tick(delta: float) -> void:
	clock += delta
	match phase:
		"countdown":
			var count := 5 - int(clock)
			if count != last_count and count > 0:
				last_count = count
				Game.sfx("click", 0.8)
			if clock >= 5.0 or Game.reduced_motion:
				phase = "ascent"
				clock = 0.0
				Game.sfx("launch")
				play_clip("launch")
		"ascent":
			var over := clock >= 4.2 if not has_clip() else (clock >= 7.5 or (clock > 1.0 and not clip.is_playing()))
			if over or Game.reduced_motion: start_cruise()
		"cruise":
			cruise = minf(1.0, cruise + delta / (9.0 if not Game.reduced_motion else 1.5))
			if events_done == 0 and cruise >= 0.35: comm_event()
			elif events_done == 1 and cruise >= 0.7: energy_event()
			elif cruise >= 1.0: start_edl()
		"edl":
			var per := 1.7 if not Game.reduced_motion else 0.5
			var step := int(clock / per)
			if step != edl_step and step < EDL.size():
				edl_step = step
				status_lines.append(Game.tt(EDL[step]))
				Game.sfx("data", 0.9 + step * 0.08)
			if clock >= per * EDL.size(): land()

func start_cruise() -> void:
	if phase in ["cruise", "event", "edl", "landed"]: return
	phase = "cruise"
	clock = 0.0
	new_stage()
	play_clip("cruise", true)
	var note := UIK.heading(stage, Game.t("CRUISE TO MARS", "CRUCERO A MARTE"), 34)
	note.position = Vector2(30, 16)
	var fact := UIK.text(stage, Game.t("The real trip takes about seven months: Perseverance launched on 30 July 2020 and landed on 18 February 2021.", "El viaje real dura unos siete meses: Perseverance despegó el 30 de julio de 2020 y aterrizó el 18 de febrero de 2021."), 16, UIK.PAPER)
	fact.position = Vector2(34, 66)
	fact.size = Vector2(700, 50)

# ------------------------------------------------------------------ eventos de crucero
func owen_modal(heading_text: String, body: String, alert: bool = false) -> VBoxContainer:
	UIK.close_modal(self)
	var content := UIK.modal(self, Vector2(820, 470), heading_text)
	if alert: (content.get_child(0) as Label).add_theme_color_override("font_color", UIK.BAD)
	var line := UIK.row(content, 14)
	var face := Control.new()
	face.custom_minimum_size = Vector2(116, 116)
	line.add_child(face)
	portrait(face, Rect2(0, 0, 116, 116), not alert)
	type_in(UIK.text(line, body, 17, UIK.INK))
	return content

func comm_event() -> void:
	phase = "event"
	Game.sfx("warn")
	var content := owen_modal(Game.t("ALERT: COMMUNICATION TEMPORARILY INTERRUPTED", "ALERTA: COMUNICACIÓN TEMPORALMENTE INTERRUMPIDA"),
		Game.t("We have lost contact with %s. That does not necessarily mean something is damaged: we may simply be in a period with no link available. Before deciding anything, let's look at the state of the systems.", "Hemos perdido el contacto con %s. Eso no significa necesariamente que algo esté dañado: puede que estemos en un periodo sin enlace disponible. Antes de decidir nada, revisemos el estado de los sistemas.") % Game.rover_name, true)
	for item in [["check", Game.t("1  Check the communication status", "1  Revisar el estado de comunicación")], ["wait", Game.t("2  Wait for the next contact opportunity", "2  Esperar la siguiente oportunidad de contacto")], ["log", Game.t("3  Consult the event log", "3  Consultar el registro de eventos")]]:
		var id := String(item[0])
		UIK.button(content, String(item[1]), func() -> void: comm_answer(id), "primary", Vector2(0, 46)).alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIK.focus_first(content)

func comm_answer(id: String) -> void:
	if flight.comm_choice == "": flight.comm_choice = id
	var body := ""
	match id:
		"check": body = Game.t("The main systems keep working and there is no sign of a failure. A break in communication does not mean we have lost control of the mission.", "Los sistemas principales siguen funcionando y no hay indicios de una falla. Una interrupción de comunicación no significa que hayamos perdido el control de la misión.")
		"wait": body = Game.t("Good decision. We keep watching and wait for the next communication opportunity.", "Buena decisión. Mantendremos la supervisión y esperaremos la próxima oportunidad de comunicación.")
		"log": body = Game.t("Event log: «Scheduled antenna switch. No ground station in view for this pass. All subsystems nominal before loss of signal.» A planned gap, then.", "Registro de eventos: «Cambio de antena programado. Ninguna estación terrestre a la vista en este paso. Todos los subsistemas nominales antes de la pérdida de señal». Una pausa prevista, entonces.")
	var content := owen_modal(Game.t("Mission control", "Control de misión"), body)
	UIK.button(content, Game.t("Wait for the link", "Esperar el enlace"), comm_restored, "go", Vector2(280, 48)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content)

func comm_restored() -> void:
	Game.sfx("link")
	var content := owen_modal(Game.t("Connection restored", "Conexión restablecida"), Game.t("Connection restored! We have new telemetry and everything looks correct. Sometimes knowing when to wait is also part of operating a space mission.", "¡Conexión restablecida! Tenemos nueva telemetría y todo parece correcto. A veces, saber cuándo esperar también es parte de operar una misión espacial."))
	var telemetry := UIK.card(content, Game.t("TELEMETRY RECEIVED", "TELEMETRÍA RECIBIDA"), UIK.GOOD)
	UIK.text(telemetry, Game.t("Power bus nominal · thermal nominal · %s asleep and healthy inside the aeroshell.", "Bus de energía nominal · térmico nominal · %s dormido y en buen estado dentro de la cápsula.") % Game.rover_name, 15, UIK.INK)
	UIK.button(content, Game.t("Continue the cruise", "Continuar el crucero"), resume_cruise, "go", Vector2(280, 48)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content)

func resume_cruise() -> void:
	UIK.close_modal(self)
	events_done += 1
	phase = "cruise"

func energy_event() -> void:
	phase = "event"
	Game.sfx("warn", 1.2)
	var s := Data.stats(Game.build)
	var margin := Game.t("Your extended battery gives us margin.", "Tu batería extendida nos da margen.") if Data.has(Game.build, "battery_ext") else Game.t("With the standard battery, margin is small.", "Con la batería de serie, el margen es pequeño.")
	var content := owen_modal(Game.t("Energy review", "Revisión de energía"), Game.t("Energy use is higher than planned. We are not in a critical situation, but we should check which systems are drawing power and whether we need them all. %s", "El consumo de energía es mayor de lo previsto. No estamos en una situación crítica, pero conviene revisar qué sistemas usan energía y si necesitamos todos activos. %s") % margin)
	for item in [["keep", Game.t("Keep the current configuration", "Mantener la configuración actual")], ["save", Game.t("Activate energy-saving mode", "Activar el modo de ahorro energético")], ["review", Game.t("Review the scheduled activities", "Revisar las actividades programadas")]]:
		var id := String(item[0])
		UIK.button(content, String(item[1]), func() -> void: energy_answer(id, s), "primary", Vector2(0, 46)).alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIK.focus_first(content)

func energy_answer(id: String, s: Dictionary) -> void:
	if id == "review":
		var content := owen_modal(Game.t("Scheduled activities", "Actividades programadas"), Game.t("These are the loads during cruise. The instrument check-out is the only one we can postpone.", "Estas son las cargas durante el crucero. La verificación de instrumentos es la única que podemos posponer."))
		var card := UIK.card(content, Game.t("POWER DRAW (game model, from your design)", "CONSUMO (modelo de juego, según tu diseño)"), UIK.ORANGE)
		UIK.text(card, Game.t("Flight computer: %d W  ·  heaters: %d W  ·  instrument check-out: %d instrument(s)", "Computadora de vuelo: %d W  ·  calentadores: %d W  ·  verificación de instrumentos: %d instrumento(s)") % [int(s.idle_w), int(Data.MODEL.heater_w), Data.instruments(Game.build).size()], 15, UIK.INK)
		var line := UIK.row(content, 10)
		UIK.button(line, Game.t("Keep everything on", "Mantener todo encendido"), func() -> void: energy_answer("keep", s), "primary", Vector2(300, 46))
		UIK.button(line, Game.t("Energy-saving mode", "Modo de ahorro"), func() -> void: energy_answer("save", s), "primary", Vector2(300, 46))
		UIK.focus_first(line)
		return
	flight.energy_choice = id
	var body := ""
	if id == "save":
		flight.charge = 1.0
		flight.delay = 12.0
		body = Game.t("Excellent. We have cut the systems that are not essential at this stage, so %s will arrive with a full battery. The instrument check-out moves to the surface: it will use a little mission time.", "Excelente. Hemos reducido los sistemas que no son esenciales en esta etapa, así que %s llegará con la batería llena. La verificación de instrumentos pasa a la superficie: gastará un poco de tiempo de misión.") % Game.rover_name
	else:
		flight.charge = 0.8
		flight.delay = 0.0
		body = Game.t("Understood. We keep current performance and keep watching. %s will land with about 80%% battery and its instruments already checked. Every decision has consequences to weigh.", "De acuerdo. Mantenemos el rendimiento actual y seguimos supervisando. %s aterrizará con cerca del 80%% de batería y sus instrumentos ya verificados. Cada decisión tiene consecuencias que considerar.") % Game.rover_name
	var content2 := owen_modal(Game.t("Mission control", "Control de misión"), body)
	UIK.button(content2, Game.t("Continue the cruise", "Continuar el crucero"), resume_cruise, "go", Vector2(280, 48)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content2)

# ------------------------------------------------------------------ aterrizaje
func start_edl() -> void:
	if phase in ["edl", "landed"]: return
	UIK.close_modal(self)
	phase = "edl"
	clock = 0.0
	edl_step = -1
	status_lines = []
	new_stage()
	play_clip("landing")
	var head := UIK.heading(stage, Game.t("SEVEN MINUTES OF TERROR", "SIETE MINUTOS DE TERROR"), 34)
	head.position = Vector2(30, 16)

## El resultado del aterrizaje sale del diseño y del sitio elegido (modelo de juego).
func landing_outcome() -> void:
	var s := Data.stats(Game.build)
	var cap := Game.limits()
	var site: Dictionary = Data.SITES[String(Game.plan.get("site", "flat"))]
	var load_factor := 0.7 + 0.6 * float(s.mass) / float(cap.mass)
	flight.damage = roundf((2.0 + 7.0 * float(site.stress)) * float(s.hull) * load_factor)
	flight.near = float(site.near) * (1.0 if Data.has(Game.build, "navsens") else 0.5)
	flight.navsens = Data.has(Game.build, "navsens")

func land() -> void:
	if phase == "landed": return
	phase = "landed"
	UIK.close_modal(self)   # ningún evento de crucero ni historia queda abierto al tocar la superficie
	stop_clip()
	skip_button.visible = false
	landing_outcome()
	Game.flight = flight.duplicate(true)
	Game.unlock("touchdown")
	Game.sfx("done")
	new_stage()
	var rover := Game.rover_name
	var owen := owen_panel(stage, Rect2(140, 400, 1000, 300), Game.t("Surface contact confirmed! %s has landed on Mars. Welcome officially to Mars, %s. Now comes the most exciting part: exploring, investigating and discovering. Remember: every move, photo and analysis uses resources we must manage carefully. We want scientifically useful information, not just as many rocks as possible.", "¡Contacto con la superficie confirmado! %s ha aterrizado en Marte. Bienvenido oficialmente a Marte, %s. Ahora empieza lo más emocionante: explorar, investigar y descubrir. Recuerda: cada movimiento, fotografía y análisis usa recursos que hay que administrar con cuidado. Queremos información científicamente útil, no solo tantas rocas como podamos.") % [rover, Game.player_name], Game.t("Systems integration", "Integración de sistemas"))
	var column: VBoxContainer = owen.column
	var result := UIK.card(column, Game.t("LANDING REPORT · consequences of your design", "INFORME DE ATERRIZAJE · consecuencias de tu diseño"), UIK.ORANGE)
	var chassis := Data.comp_name(String(Game.build.chassis))
	UIK.text(result, Game.t("Rover health: %d%%. Landing stress cost %d%% (%s on the %s).", "Salud del rover: %d%%. El aterrizaje costó %d%% (%s en %s).") % [int(100.0 - float(flight.damage)), int(flight.damage), chassis, Game.tt(Data.SITES[String(Game.plan.get("site", "flat"))].name).to_lower()], 15, UIK.INK)
	UIK.text(result, Game.t("Battery on arrival: %d%%.  Landing precision: %s.", "Batería al llegar: %d%%.  Precisión de aterrizaje: %s.") % [int(float(flight.charge) * 100.0), (Game.t("high, thanks to the navigation sensors", "alta, gracias a los sensores de navegación") if flight.navsens else Game.t("standard, no navigation sensors", "estándar, sin sensores de navegación"))], 15, UIK.INK)
	var line := UIK.row(column, 10)
	UIK.button(line, Game.t("Begin surface operations →", "Iniciar operaciones en superficie →"), begin_ops, "go", Vector2(360, 46))
	wait_button(line)
	UIK.focus_first(line)

func begin_ops() -> void:
	if finished: return   # exactamente una vez, aunque se pulse rápido
	finished = true
	Game.go("ops")

# ------------------------------------------------------------------ dibujo
func paint() -> void:
	var view := size
	match phase:
		"prep", "countdown", "ascent":
			var rise := 0.0
			if phase == "ascent": rise = pow(clock / 4.2, 2.2)
			Art.gradient(self, Rect2(Vector2.ZERO, view), Color("#6fa8d6").lerp(UIK.INK, rise), Color("#f5db98").lerp(UIK.NAVY, rise))
			var ground := view.y * 0.84 + rise * 900.0
			for i in range(5):
				var cx := fmod(i * 310.0 + time * 6.0, view.x + 300.0) - 150.0
				draw_colored_polygon(Art.blob(Vector2(cx, 150.0 + i * 46.0 + rise * 700.0), 90, 30, i + 2, 8, 0.2), Color(1, 1, 1, 0.5))
			draw_rect(Rect2(0, ground, view.x, view.y), Color("#5f8f84"))
			draw_rect(Rect2(0, ground + 30, view.x, view.y), Color("#4a7068"))
			var pad := Vector2(880, ground)
			draw_rect(Rect2(pad.x - 150, pad.y - 14, 300, 20), Color("#8b98a0"))
			# Torre de servicio
			draw_rect(Rect2(pad.x + 70, pad.y - 330, 46, 320), Color("#59656c"))
			for i in range(8): draw_line(Vector2(pad.x + 70, pad.y - 330 + i * 40), Vector2(pad.x + 116, pad.y - 290 + i * 40), UIK.INK, 3.0)
			draw_rect(Rect2(pad.x + 20, pad.y - 250, 60, 8), Color("#FFAD45"))
			var shake := Vector2(sin(time * 60.0), cos(time * 47.0)) * (3.0 if phase == "ascent" and clock < 1.6 and not Game.reduced_motion else 0.0)
			var lift := 0.0
			if phase == "ascent": lift = pow(clock / 4.2, 2.0) * 700.0 - rise * 900.0
			Art.rocket(self, pad + Vector2(0, -14 - lift) + shake, 1.0, 1.0 if phase == "ascent" else (0.25 if phase == "countdown" and clock > 4.0 else 0.0), time)
			if phase == "ascent":
				for i in range(10): draw_circle(pad + Vector2(sin(i * 2.3) * (40.0 + clock * 60.0), -10 - i * 6.0), 30.0 + clock * 26.0, Color(1, 1, 1, 0.16))
			if phase == "countdown":
				var count := maxi(1, 5 - int(clock))
				var beat := 1.0 + 0.25 * (1.0 - fmod(clock, 1.0))
				draw_string_outline(UIK.title_font, Vector2(180, 420), str(count), HORIZONTAL_ALIGNMENT_CENTER, 300, int(190 * beat), 18, UIK.INK)
				draw_string(UIK.title_font, Vector2(180, 420), str(count), HORIZONTAL_ALIGNMENT_CENTER, 300, int(190 * beat), UIK.ORANGE)
			if phase == "ascent":
				draw_string_outline(UIK.title_font, Vector2(80, 380), Game.t("LIFTOFF!", "¡DESPEGUE!"), HORIZONTAL_ALIGNMENT_CENTER, 520, 76, 14, UIK.INK)
				draw_string(UIK.title_font, Vector2(80, 380), Game.t("LIFTOFF!", "¡DESPEGUE!"), HORIZONTAL_ALIGNMENT_CENTER, 520, 76, UIK.CREAM)
		"cruise", "event":
			Art.space(self, view, time, false)
			draw_rect(Rect2(Vector2.ZERO, view), Color(UIK.INK, 0.5))
			var earth := Vector2(180, 520)
			var mars := Vector2(1090, 250)
			Art.planet(self, earth, 70, time * 0.1, Color("#4f86c6"), 5)
			Art.planet(self, mars, 54, time * 0.1, Color("#c9603f"), 5)
		"edl", "landed":
			var k := clampf(clock / (1.7 * EDL.size()), 0.0, 1.0) if phase == "edl" else 1.0
			Art.gradient(self, Rect2(Vector2.ZERO, view), UIK.INK.lerp(Color("#c98a5c"), k), Color("#7a3f3a").lerp(Color("#e3a877"), k))
			var horizon := view.y * (1.25 - 0.5 * k)
			Art.ridge(self, 0, view.x, horizon, 120.0 * k + 30.0, 21, Color("#93492f"), 7)
			draw_rect(Rect2(0, horizon, view.x, view.y), Color("#a8552f"))
			var c := Vector2(view.x * 0.62, lerpf(120.0, horizon - 70.0, k))
			if phase == "landed":
				Art.rover(self, Vector2(view.x * 0.62, horizon + 40.0), -0.2, Game.build, 3.2, time)
			else:
				if edl_step >= 2 and edl_step < 4: Art.parachute(self, c, 1.0, clampf((clock - 1.7 * 2.0) * 1.5, 0.1, 1.0))
				if edl_step == 3:
					for side in [-1.0, 1.0]: draw_colored_polygon(PackedVector2Array([c + Vector2(side * 26, 16), c + Vector2(side * 36, 16), c + Vector2(side * 31, 60 + sin(time * 30.0) * 8.0)]), UIK.ORANGE)
				Art.capsule(self, c, 1.0, 1.0 if edl_step <= 1 else 0.0, time)
				if edl_step >= 4:
					for i in range(8): draw_circle(Vector2(c.x + (i - 3.5) * 40.0, horizon + 10.0), 26.0 + sin(time * 5.0 + i) * 6.0, Color(0.9, 0.7, 0.5, 0.4))

## Primer plano del crucero y del aterrizaje: se dibuja por encima de la cinemática, si la hay.
func paint_overlay() -> void:
	var view := size
	match phase:
		"ascent":
			if has_clip():
				overlay.draw_string_outline(UIK.title_font, Vector2(80, 380), Game.t("LIFTOFF!", "¡DESPEGUE!"), HORIZONTAL_ALIGNMENT_CENTER, 520, 76, 14, UIK.INK)
				overlay.draw_string(UIK.title_font, Vector2(80, 380), Game.t("LIFTOFF!", "¡DESPEGUE!"), HORIZONTAL_ALIGNMENT_CENTER, 520, 76, UIK.CREAM)
		"cruise", "event":
			var earth := Vector2(180, 520)
			var mars := Vector2(1090, 250)
			if has_clip(): overlay.draw_rect(Rect2(Vector2.ZERO, view), Color(UIK.INK, 0.35))
			var path := PackedVector2Array()
			for i in range(41):
				var k := i / 40.0
				path.append(earth.lerp(mars, k) + Vector2(0, -210.0 * sin(k * PI)))
			for i in range(40):
				if i % 2 == 0: overlay.draw_line(path[i], path[i + 1], Color(UIK.PAPER, 0.35), 2.0)
			var at := earth.lerp(mars, cruise) + Vector2(0, -210.0 * sin(cruise * PI))
			var ahead := earth.lerp(mars, minf(1.0, cruise + 0.02)) + Vector2(0, -210.0 * sin(minf(1.0, cruise + 0.02) * PI))
			var dir := (ahead - at).normalized() if ahead != at else Vector2.RIGHT
			overlay.draw_set_transform(at, dir.angle() + PI * 0.5, Vector2.ONE)
			Art.capsule(overlay, Vector2.ZERO, 0.5, 0.0, time)
			overlay.draw_rect(Rect2(-34, 8, 20, 8), Color("#3f7fb5"))
			overlay.draw_rect(Rect2(14, 8, 20, 8), Color("#3f7fb5"))
			overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if phase == "event" and events_done == 0:
				for i in range(3): overlay.draw_arc(at, 30.0 + i * 16.0 + fmod(time * 30.0, 16.0), -0.6, 0.6, 8, Color(UIK.BAD, 0.6 - i * 0.18), 3.0)
			UIK.bar(overlay, Rect2(340, 660, 600, 16), cruise, UIK.ORANGE, Color(UIK.PAPER, 0.15))
			overlay.draw_string(UIK.bold_font, Vector2(340, 650), Game.t("Earth", "Tierra"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UIK.PAPER)
			overlay.draw_string(UIK.bold_font, Vector2(840, 650), Game.t("Mars", "Marte"), HORIZONTAL_ALIGNMENT_RIGHT, 100, 15, UIK.PAPER)
		"edl", "landed":
			for i in range(status_lines.size()):
				var box := Rect2(40, 100 + i * 58, 470, 48)
				overlay.draw_style_box(UIK.box(Color(UIK.INK, 0.85), 14, UIK.GO if i == status_lines.size() - 1 else Color(UIK.MINT, 0.5), 2, 0), box)
				overlay.draw_string(UIK.bold_font, box.position + Vector2(18, 31), "«%s»" % String(status_lines[i]), HORIZONTAL_ALIGNMENT_LEFT, 440, 18, UIK.PAPER)
			if phase == "edl": overlay.draw_string(UIK.body_font, Vector2(40, 700), Game.t("Simplified game model inspired by Mars 2020. A signal from Mars takes minutes to reach Earth: the rover lands on its own.", "Modelo de juego simplificado, inspirado en Mars 2020. Una señal desde Marte tarda minutos en llegar a la Tierra: el rover aterriza solo."), HORIZONTAL_ALIGNMENT_LEFT, 1200, 14, Color(UIK.PAPER, 0.85))
