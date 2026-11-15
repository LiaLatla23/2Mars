extends BaseScreen
## ETAPA 1 · MISSION DESIGN — el taller (referencias 11-16).
## El jugador arma el rover con el catálogo del libro de ingeniería dentro de los límites del
## plan. Cada pieza se puede previsualizar (antes/después) antes de instalarla, y Mission
## Readiness evalúa el diseño real en cuatro categorías.

var build: Dictionary
var category := "structure"
var cards_area: VBoxContainer
var right: Panel
var compare: VBoxContainer
var owen_label: Label
var banner: Label
var cat_buttons := {}
var prev_mass := -1.0
var prev_cost := -1.0
var sandbox := false
var coach_step := -1
var coach: Dictionary = {}
var changed := false
var viewer: Stage3D            # visor 3D del rover (V4)
var preview_id := ""           # pieza que se está previsualizando (puede no estar instalada)
var preview_tag: Label
const PREVIEW := Rect2(716, 60, 548, 318)
const CAT_ICON := {"structure": "crate_tech", "mobility": "comp_wheel", "power": "comp_battery", "science": "comp_analyzer", "sampling": "comp_drill", "computing": "mat_chip", "comms": "up_range"}

func _ready() -> void:
	backdrop = "workshop"
	backdrop_dim = 0.42
	sandbox = Game.mode == "sandbox"
	build = (Game.sandbox.build if sandbox else Game.build).duplicate(true)
	banner = UIK.heading(self, "", 34, UIK.CREAM)
	banner.position = Vector2(24, 10)
	var top := UIK.row(self, 8)
	top.position = Vector2(716, 16)
	var zone: Dictionary = Data.ZONES[Game.zone]
	UIK.chip(top, " SANDBOX " if sandbox else " %s · %s " % [Game.tt(zone.goal).to_upper(), Game.tt(zone.name)], UIK.MINT if sandbox else Color(String(zone.color)))
	if not sandbox: coop_banner(Vector2(716, 40), Game.t("reviews impact", "revisa el impacto"), Game.t("builds", "construye"))
	back_button(Game.t("GO BACK", "VOLVER"), "menu" if sandbox else "hub", Vector2(1124, 8)).custom_minimum_size = Vector2(140, 40)
	var cats := UIK.column(self, Rect2(16, 66, 190, 640), 6)
	for item in Data.CATEGORIES:
		var id := String(item.id)
		var b := UIK.icon_button(cats, Game.tt(item.name), String(CAT_ICON[id]), func() -> void: open_category(id), "primary", Vector2(190, 52))
		b.add_theme_font_size_override("font_size", 15)
		cat_buttons[id] = b
	UIK.icon_button(cats, Game.t("Hangar", "Hangar"), "nav_rovers", open_hangar, "teal", Vector2(190, 46))
	UIK.button(cats, Game.t("Reset design", "Reiniciar diseño"), reset_build, "ghost", Vector2(190, 40)).add_theme_font_size_override("font_size", 15)
	if sandbox: UIK.button(cats, Game.t("Sandbox limits", "Límites de Sandbox"), open_sandbox_limits, "yellow", Vector2(190, 44)).add_theme_font_size_override("font_size", 15)
	var middle := UIK.panel(self, Rect2(216, 66, 488, 640))
	cards_area = UIK.scroll(middle, Rect2(14, 12, 462, 616))
	cards_area.add_theme_constant_override("separation", 6)
	# visor 3D grande: el rover real del jugador, con órbita y zoom
	viewer = Stage3D.make(self, PREVIEW)
	viewer.workshop()
	viewer.show_rover(build)
	viewer.goal = Vector3(0.8, 0.3, 7.6)
	viewer.orbit = viewer.goal
	viewer.focus = Vector3(0, 0.95, 0)
	viewer.zoom_range = Vector2(4.6, 10.0)
	viewer.spin = 0.14
	viewer.enable_orbit()
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", UIK.box(Color(0, 0, 0, 0), 10, UIK.INK, 4, 0))
	frame.position = PREVIEW.position
	frame.size = PREVIEW.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var name_tag := UIK.heading(self, Game.rover_name if not sandbox else "SANDBOX", 24, UIK.CREAM)
	name_tag.position = PREVIEW.position + Vector2(14, PREVIEW.size.y - 40)
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint := UIK.label(self, Game.t("Drag or Q/E to rotate · wheel to zoom", "Arrastra o Q/E para girar · rueda para acercar"), 13, UIK.PAPER, "bold")
	hint.position = PREVIEW.position + Vector2(14, 8)
	hint.add_theme_color_override("font_outline_color", UIK.INK)
	hint.add_theme_constant_override("outline_size", 5)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_tag = UIK.chip(self, "", UIK.ORANGE)
	preview_tag.position = PREVIEW.position + Vector2(PREVIEW.size.x - 190, PREVIEW.size.y - 34)
	preview_tag.visible = false
	right = UIK.panel(self, Rect2(716, 386, 548, 320))
	open_category(category)
	Motion.stagger(cats.get_children(), 0.03, Vector2(-20, 0))
	if sandbox and not bool(Game.hints_seen.get("sandbox_intro", false)): sandbox_intro()
	elif not sandbox and not bool(Game.tutorial.get("workshop", false)):
		welcome()
		start_coach()

## Bienvenida al taller (referencia 12): rótulo que entra y sale solo, sin bloquear nada.
func welcome() -> void:
	if Game.reduced_motion: return
	var sign := UIK.panel(self, Rect2(330, 250, 620, 150), UIK.PAPER, 10)
	sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign.z_index = 40
	sign.rotation = -0.06
	var words := UIK.heading(sign, Game.t("WELCOME TO THE WORKSHOP", "BIENVENIDO AL TALLER"), 40, UIK.ORANGE)
	words.position = Vector2(26, 26)
	UIK.label(sign, Game.t("Build your rover. Every part has a cost.", "Arma tu rover. Cada pieza tiene un costo."), 20, UIK.NAVY, "bold").position = Vector2(30, 92)
	var home := sign.position
	sign.position = home + Vector2(-900, 0)
	var t := sign.create_tween()
	t.tween_property(sign, "position", home, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.5)
	t.tween_property(sign, "position", home + Vector2(1100, 0), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(sign.queue_free)

# ------------------------------------------------------------------ catálogo
func open_category(id: String) -> void:
	category = id
	for item in Data.CATEGORIES:
		if String(item.id) == id: banner.text = Game.tt(item.name)
	for key in cat_buttons:
		var b: Button = cat_buttons[key]
		b.add_theme_stylebox_override("normal", UIK.box(UIK.ORANGE if key == id else UIK.CREAM, 16, UIK.INK, 4 if key == id else 2, 3))
	if coach_step == 0: coach_next()
	refresh(true)
	say_owen(category_line(id))

func refresh(animate: bool = false) -> void:
	for child in cards_area.get_children(): child.queue_free()
	var shown: Array = []
	for group in Data.GROUPS:
		if String(group.cat) != category: continue
		var hint: String = {"one": Game.t("choose one", "elige una"), "optional": Game.t("one or none", "una o ninguna"), "multi": Game.t("any combination", "cualquier combinación")}[String(group.kind)]
		UIK.label(cards_area, "%s  ·  %s" % [Game.tt(group.title).to_upper(), hint], 13, UIK.MUTED, "bold")
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		cards_area.add_child(grid)
		for id in group.options: shown.append(add_card(grid, String(id)))
	if category in ["science", "sampling"]: UIK.label(cards_area, Game.t("Payloads on deck: %d of %d", "Cargas útiles en cubierta: %d de %d") % [Data.payloads(build), Data.deck_slots(build)], 14, UIK.BAD if Data.payloads(build) > Data.deck_slots(build) else UIK.TEAL, "bold")
	if animate: Motion.stagger(shown)
	refresh_right()

func add_card(grid: GridContainer, id: String) -> Button:
	var info: Dictionary = Data.COMPONENTS[id]
	var active := Data.has(build, id)
	var power := ""
	if id in ["solar", "rtg"]: power = "+%d W" % int(info.power)
	elif int(info.power) > 0: power = "−%d W" % int(info.power)
	var card := UIK.tile(grid, Vector2(223, 136), func() -> void: install(id), {"image": UIK.tex("res://assets/parts/%s.png" % id), "title": Game.tt(info.name), "sub": "%d kg  ·  %d cr" % [int(info.mass), int(info.cost)],
		"tile": Color("#2a62b8"), "accent": UIK.MINT, "selected": active, "done": active, "tag": power, "tag_color": UIK.GOOD if id in ["solar", "rtg"] else UIK.RUST})
	card.mouse_entered.connect(func() -> void: preview(id))
	card.focus_entered.connect(func() -> void: preview(id))
	card.mouse_exited.connect(end_preview)
	return card

## Al dejar de señalar una pieza, el visor vuelve a mostrar el rover tal como está instalado.
func end_preview() -> void:
	if preview_id == "": return
	var was_ghost := not Data.has(build, preview_id)
	preview_id = ""
	preview_tag.visible = false
	if was_ghost: viewer.show_rover(build, viewer.rover.position, viewer.rover.rotation.y)
	viewer.point_at("")

## Devuelve el diseño que resultaría de pulsar esta pieza.
func applied(id: String) -> Dictionary:
	var out := build.duplicate(true)
	for group in Data.GROUPS:
		if not id in group.options: continue
		var key := String(group.id)
		match String(group.kind):
			"one": out[key] = id
			"optional": out[key] = "" if String(out.get(key, "")) == id else id
			"multi":
				var parts: Array = out.parts
				if id in parts: parts.erase(id)
				else: parts.append(id)
	return out

func install(id: String) -> void:
	var next := applied(id)
	if next.hash() == build.hash(): return
	prev_mass = Data.mass(build)
	prev_cost = Data.cost(build)
	var added := Data.has(next, id)
	build = next
	changed = true
	Game.sfx("attach" if added else "detach")
	persist()
	if coach_step == 2: coach_next()
	refresh()
	preview_id = ""
	viewer.show_rover(build, viewer.rover.position, viewer.rover.rotation.y)
	if added: viewer.rover.pop(id)   # animación de ensamblaje
	preview(id)
	say_owen(install_line(id, added))

func persist() -> void:
	if sandbox: Game.sandbox.build = build.duplicate(true)
	else: Game.build = build.duplicate(true)
	Game.save()

func reset_build() -> void:
	prev_mass = Data.mass(build)
	prev_cost = Data.cost(build)
	build = Data.default_build()
	persist()
	preview_id = ""
	viewer.show_rover(build, viewer.rover.position, viewer.rover.rotation.y)
	refresh()
	say_owen(Game.t("Back to the reference design: a camera, a composition instrument and a relay antenna.", "De vuelta al diseño de referencia: una cámara, un instrumento de composición y una antena de relevo."))

# ------------------------------------------------------------------ panel derecho
func cap() -> Dictionary:
	return Game.limits()

func refresh_right() -> void:
	for child in right.get_children(): child.queue_free()
	var limits := cap()
	var column := UIK.column(right, Rect2(16, 12, 282, 296), 5)
	UIK.meter(column, Game.t("MASS", "MASA"), Data.mass(build), float(limits.mass), "kg", prev_mass)
	UIK.meter(column, Game.t("BUDGET", "PRESUPUESTO"), Data.cost(build), float(limits.budget), "cr", prev_cost)
	prev_mass = -1.0
	prev_cost = -1.0
	var s := Data.stats(build)
	var night := Data.night_wh(build)
	var facts := UIK.row(column, 10)
	UIK.stat(facts, "up_power", "%d W" % int(s.gen_w), Game.t("generation", "generación"))
	UIK.stat(facts, "comp_battery", "%d Wh" % int(s.battery), Game.t("battery", "batería"))
	var facts2 := UIK.row(column, 10)
	UIK.stat(facts2, "up_speed", "%d" % int(s.speed), Game.t("speed", "velocidad"))
	UIK.stat(facts2, "up_storage", "%d MB" % int(s.memory), Game.t("memory", "memoria"))
	UIK.label(column, (Game.t("Night autonomy %d%%", "Autonomía nocturna %d%%") % int(100.0 * float(s.battery) / maxf(1.0, night))) if s.solar else Game.t("RTG: power all night", "RTG: energía toda la noche"), 13, UIK.TEAL, "bold")
	var checks := Data.check(build, Game.zone, Game.active_plan())
	var blockers := Data.count_level(checks, "blocker")
	var risks := Data.count_level(checks, "risk")
	var limits_count := Data.count_level(checks, "limit")
	var state := UIK.row(column, 4)
	for pair in [[blockers, Game.t("blockers", "bloqueos"), UIK.BAD], [risks, Game.t("risks", "riesgos"), UIK.SAND], [limits_count, Game.t("limits", "límites"), UIK.NAVY]]:
		var tag := UIK.chip(state, "%d %s" % [int(pair[0]), String(pair[1])], pair[2] if int(pair[0]) > 0 else UIK.GOOD)
		tag.add_theme_font_size_override("font_size", 13)
		tag.get_theme_stylebox("normal").content_margin_left = 7
		tag.get_theme_stylebox("normal").content_margin_right = 7
	var ready_button := UIK.button(column, Game.t("MISSION READINESS", "MISSION READINESS"), open_readiness, "go" if blockers == 0 else "danger", Vector2(282, 50))
	ready_button.add_theme_font_size_override("font_size", 18)
	var save := UIK.button(column, Game.t("Save design", "Guardar diseño"), save_design, "ghost", Vector2(282, 34))
	save.add_theme_font_size_override("font_size", 15)
	var side := UIK.column(right, Rect2(310, 12, 224, 296), 4)
	compare = UIK.column(side, Rect2(0, 0, 224, 178), 3)
	compare.custom_minimum_size = Vector2(224, 178)
	compare.clip_contents = true
	UIK.text(compare, Game.t("Point at a part: the viewer shows where it goes and this panel compares before and after.", "Señala una pieza: el visor muestra dónde va y este panel compara antes y después."), 14, UIK.MUTED)
	var owen := UIK.card(side, Game.owen().to_upper(), UIK.ORANGE, UIK.CREAM)
	owen_label = UIK.text(owen, "", 13, UIK.INK)
	owen_label.max_lines_visible = 3

func preview(id: String) -> void:
	if not is_instance_valid(compare): return
	if coach_step == 1 and not Data.has(build, id): coach_next()
	var installed := Data.has(build, id)
	var after_build := applied(id)
	# visor: resalta dónde va la pieza; si aún no está instalada, se muestra el rover resultante
	if preview_id != id:
		if not installed: viewer.show_rover(after_build, viewer.rover.position, viewer.rover.rotation.y)
		elif preview_id != "" and not Data.has(build, preview_id): viewer.show_rover(build, viewer.rover.position, viewer.rover.rotation.y)
		preview_id = id
		viewer.point_at(id)
		preview_tag.text = Game.t("  PREVIEW  ", "  VISTA PREVIA  ") if not installed else Game.t("  INSTALLED  ", "  INSTALADA  ")
		preview_tag.add_theme_stylebox_override("normal", UIK.box(UIK.ORANGE if not installed else UIK.MINT, 10, UIK.INK, 2, 0))
		preview_tag.visible = true
	for child in compare.get_children(): child.queue_free()
	var info: Dictionary = Data.COMPONENTS[id]
	UIK.text(compare, Game.tt(info.name), 17, UIK.NAVY).add_theme_font_override("font", UIK.title_font)
	var effect := UIK.text(compare, Game.tt(Data.EFFECTS[id]), 13, UIK.INK)
	effect.max_lines_visible = 3
	effect.custom_minimum_size.x = 0
	effect.tooltip_text = Game.tt(Data.EFFECTS[id])
	effect.mouse_filter = Control.MOUSE_FILTER_STOP
	var a := Data.stats(build)
	var b := Data.stats(after_build)
	var rows := [[Game.t("Mass", "Masa"), float(a.mass), float(b.mass), "kg", true], [Game.t("Cost", "Costo"), float(Data.cost(build)), float(Data.cost(after_build)), "cr", true],
		[Game.t("Battery", "Batería"), float(a.battery), float(b.battery), "Wh", false], [Game.t("Generation", "Generación"), float(a.gen_w), float(b.gen_w), "W", false],
		[Game.t("Driving draw", "Consumo al conducir"), float(a.drive_w) + float(a.idle_w), float(b.drive_w) + float(b.idle_w), "W", true], [Game.t("Speed", "Velocidad"), float(a.speed), float(b.speed), "", false],
		[Game.t("Mobility", "Movilidad"), float(a.mobility), float(b.mobility), "", false], [Game.t("Memory", "Memoria"), float(a.memory), float(b.memory), "MB", false],
		[Game.t("Science potential", "Potencial científico"), float(a.science), float(b.science), "", false]]
	UIK.label(compare, Game.t("NOW  →  IF YOU REMOVE IT", "AHORA  →  SI LA QUITAS") if installed else Game.t("NOW  →  AFTER", "AHORA  →  DESPUÉS"), 12, UIK.MUTED, "bold")
	var shown := 0
	for item in rows:
		if absf(float(item[1]) - float(item[2])) < 0.5 or shown >= 3: continue
		shown += 1
		var better: bool = (float(item[2]) < float(item[1])) == bool(item[4])
		var line := UIK.row(compare, 6)
		var stat_name := UIK.label(line, String(item[0]), 13, UIK.INK, "bold")
		stat_name.custom_minimum_size.x = 70
		stat_name.clip_text = true
		stat_name.tooltip_text = String(item[0])
		var top := maxf(float(item[1]), float(item[2]))
		UIK.duo(line, float(item[1]) / maxf(1.0, top), float(item[2]) / maxf(1.0, top), UIK.GOOD if better else UIK.RUST)
		UIK.label(line, "%d→%d %s" % [int(item[1]), int(item[2]), String(item[3])], 13, UIK.GOOD if better else UIK.RUST, "bold")
	if shown == 0: UIK.text(compare, Game.t("No change to the rover's numbers.", "No cambia las cifras del rover."), 13, UIK.MUTED)
	var problems := Data.check(after_build, Game.zone, Game.active_plan()).filter(func(item: Dictionary) -> bool: return item.level == "blocker")
	if not problems.is_empty(): UIK.text(compare, "⚠ " + Data.check_text(problems[0]), 13, UIK.BAD)

func say_owen(text: String) -> void:
	if not is_instance_valid(owen_label) or text == "": return
	owen_label.text = text
	type_in(owen_label)

## Líneas de la Dra. Owen del guion del equipo (fase 2), adaptadas a la pieza elegida.
func category_line(id: String) -> String:
	var rover := Game.rover_name
	match id:
		"structure": return Game.t("Let's start with the structure. The chassis is the rover's main support, and Mars doesn't exactly have comfortable roads.", "Empecemos por la estructura. El chasis es el soporte principal del rover, y Marte no tiene precisamente carreteras cómodas.")
		"mobility": return Game.t("Some wheels resist more, others save mass. Think about the terrain we will explore.", "Unas ruedas resisten más, otras ahorran masa. Piensa en el terreno que vamos a explorar.")
		"power": return Game.t("Without energy %s cannot move, analyse or talk to us. We must generate and store enough for the mission.", "Sin energía %s no podrá moverse, analizar ni comunicarse. Hay que generar y almacenar la suficiente para la misión.") % rover
		"science": return Game.t("These instruments will be our eyes and tools on Mars. We must choose the information we really need.", "Estos instrumentos serán nuestros ojos y herramientas en Marte. Hay que elegir la información que realmente necesitamos.")
		"sampling": return Game.t("An arm reaches the rock; the drill takes a core. Each tool also needs a place on the deck.", "Un brazo llega a la roca; el taladro saca un núcleo. Cada herramienta también necesita un lugar en la cubierta.")
		"computing": return Game.t("Memory holds your science until it can be sent. Autonomy lets the rover do more on its own.", "La memoria guarda tu ciencia hasta poder enviarla. La autonomía permite al rover hacer más por sí solo.")
		"comms": return Game.t("A mission doesn't end when we get information. We have to send it to Earth!", "Una misión no termina cuando obtenemos información. ¡Hay que enviarla a la Tierra!")
	return ""

func install_line(id: String, added: bool) -> String:
	if not added: return Game.t("Removed. That frees mass and budget for something else.", "Retirada. Eso libera masa y presupuesto para otra cosa.")
	match id:
		"wheels_light": return Game.t("Interesting choice. Less mass keeps the total under control, but will they resist the terrain we want to explore?", "Interesante elección. Menos masa ayuda a controlar el total, pero ¿resistirán el terreno que queremos explorar?")
		"wheels_reinf", "chassis_reinf": return Game.t("A robust option. It will help on difficult terrain, though we must account for the extra weight.", "Una opción robusta. Ayudará en terreno complicado, aunque hay que tener en cuenta el peso adicional.")
		"solar", "rtg": return Game.t("Watch the energy numbers change. Check mass and budget too: more power has consequences elsewhere.", "Observa cómo cambian las cifras de energía. Revisa también masa y presupuesto: más potencia tiene consecuencias en otros sistemas.")
		"battery_ext": return Game.t("More storage means a bigger reserve for demanding activities, and it also adds mass and cost.", "Más almacenamiento significa una reserva mayor para actividades exigentes, y también añade masa y costo.")
		"mastcam": return Game.t("This camera documents our discoveries. More observation means more data to store and transmit.", "Esta cámara documenta nuestros descubrimientos. Más observación significa más datos que guardar y transmitir.")
		"supercam", "pixl", "sherloc", "rimfax": return Game.t("This instrument investigates what rocks are made of. Its science potential is higher; so are its energy use, mass and cost.", "Este instrumento investiga de qué están hechas las rocas. Su potencial científico es mayor; también su consumo, masa y costo.")
		"uhf", "hga": return Game.t("A good antenna improves our link, but speed also depends on communication windows.", "Una buena antena mejora nuestro enlace, pero la velocidad también depende de las ventanas de comunicación.")
		"moxie": return Game.t("MOXIE is a technology demonstration: heavy and very power-hungry. Make sure the energy system can feed it.", "MOXIE es una demostración tecnológica: pesado y de mucho consumo. Asegúrate de que el sistema de energía pueda alimentarlo.")
	return Game.t("Installed. Look at what moved: every gain has a cost somewhere.", "Instalada. Mira qué se movió: cada ganancia tiene un costo en algún lado.")

# ------------------------------------------------------------------ readiness
## Preparación de misión (V4): primero los indicadores; cada uno abre sus explicaciones y los
## arreglos que el juego ya ofrecía. show = nivel a desplegar ("" elige el más grave con casos).
func open_readiness(show: String = "") -> void:
	if coach_step == 3: coach_next()
	UIK.close_modal(self)
	var checks := Data.check(build, Game.zone, Game.active_plan())
	var index := Data.readiness_index(checks, Game.zone)
	var content := UIK.modal(self, Vector2(980, 640), "Mission Readiness")
	var sections := [["blocker", Game.t("BLOCKERS", "BLOQUEOS"), Game.t("must be fixed before launch", "hay que resolverlos antes de lanzar"), UIK.BAD, "pin_locked"],
		["risk", Game.t("RISKS", "RIESGOS"), Game.t("you can launch; the mission gets harder", "puedes lanzar; la misión será más difícil"), UIK.SAND, "pin_anomaly"],
		["limit", Game.t("LIMITS", "LÍMITES"), Game.t("less science, no danger", "menos ciencia, sin peligro"), UIK.NAVY, "pin_exploration"],
		["tip", Game.t("TIPS", "CONSEJOS"), Game.t("optional recommendations", "recomendaciones opcionales"), UIK.TEAL, "pin_main"]]
	if show == "":
		for section in sections:
			if Data.count_level(checks, String(section[0])) > 0:
				show = String(section[0])
				break
	var head := UIK.row(content, 10)
	for section in sections:
		var level := String(section[0])
		var count := Data.count_level(checks, level)
		var tint: Color = section[3] if count > 0 else UIK.GOOD
		var b := UIK.icon_button(head, "%d  %s" % [count, String(section[1])], String(section[4]) if count > 0 else "pin_completed", func() -> void: open_readiness(level), "ghost", Vector2(164, 60))
		b.add_theme_stylebox_override("normal", UIK.box(tint.lerp(UIK.PAPER, 0.25 if level == show else 0.72), 16, UIK.INK, 4 if level == show else 2, 3))
		b.add_theme_font_size_override("font_size", 16)
		b.tooltip_text = String(section[2])
	var gauge_box := UIK.column(head, Rect2(0, 0, 0, 0), 2)
	gauge_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.label(gauge_box, "%s  %d/100" % [Game.t("READINESS", "PREPARACIÓN"), index], 16, UIK.NAVY, "title")
	UIK.gauge(gauge_box, index / 100.0, UIK.GOOD if index >= 75 else (UIK.SAND if index >= 40 else UIK.BAD), 16.0)
	var formula := UIK.label(gauge_box, Game.t("game estimate · hover for the formula", "estimación del juego · pasa el cursor"), 12, UIK.MUTED, "bold")
	formula.mouse_filter = Control.MOUSE_FILTER_STOP
	formula.tooltip_text = Game.t("A game estimate, not a NASA probability: 100 − 9 per risk − 60 × share of required objectives out of reach; 0 with any blocker.", "Estimación del juego, no una probabilidad de la NASA: 100 − 9 por riesgo − 60 × fracción de objetivos requeridos fuera de alcance; 0 con cualquier bloqueo.")
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(928, 386)
	content.add_child(holder)
	var list := UIK.scroll(holder, Rect2(0, 0, 928, 386))
	list.add_theme_constant_override("separation", 6)
	if show == "":
		UIK.label(list, Game.t("Everything checks out. No blockers, risks or limits.", "Todo en orden. Sin bloqueos, riesgos ni límites."), 20, UIK.GOOD, "title")
	for section in sections:
		if String(section[0]) != show: continue
		var items := checks.filter(func(item: Dictionary) -> bool: return item.level == section[0])
		UIK.label(list, "%s · %s" % [String(section[1]), String(section[2])], 14, section[3], "bold")
		if items.is_empty(): UIK.label(list, Game.t("None.", "Ninguno."), 15, UIK.GOOD, "bold")
		for item in items:
			var card := UIK.card(list, "", section[3])
			var line := UIK.row(card, 8)
			var words := UIK.column(line, Rect2(0, 0, 0, 0), 0)
			words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UIK.text(words, Data.check_text(item), 16, UIK.INK).add_theme_font_override("font", UIK.bold_font)
			UIK.text(words, Game.tt(item.why), 14, UIK.MUTED)
			if item.has("fix"):
				var fix: Dictionary = item.fix
				var b2 := UIK.button(line, Game.tt(fix.label), func() -> void: apply_fix(fix), "primary", Vector2(250, 40))
				b2.add_theme_font_size_override("font_size", 14)
				b2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var line2 := UIK.row(content, 12)
	UIK.button(line2, Game.t("Back to the workshop", "Volver al taller"), func() -> void: UIK.close_modal(self), "ghost", Vector2(260, 50))
	var blockers := Data.count_level(checks, "blocker")
	var caption := Game.t("TEST DRIVE ON MARS →", "PROBAR EN MARTE →") if sandbox else Game.t("GO FOR LAUNCH →", "LISTOS PARA LANZAR →")
	var go := UIK.button(line2, caption if blockers == 0 else Game.t("Fix %d blocker(s) first", "Resuelve %d bloqueo(s) primero") % blockers, func() -> void: launch(checks), "go", Vector2(420, 50))
	go.disabled = blockers > 0
	UIK.focus_first(line2)

func apply_fix(fix: Dictionary) -> void:
	prev_mass = Data.mass(build)
	prev_cost = Data.cost(build)
	if fix.has("add") and not Data.has(build, String(fix.add)): build.parts.append(String(fix.add))
	if fix.has("set"): build[String(fix.set[0])] = String(fix.set[1])
	Game.sfx("attach")
	persist()
	preview_id = ""
	viewer.show_rover(build, viewer.rover.position, viewer.rover.rotation.y)
	refresh()
	open_readiness()

func launch(checks: Array) -> void:
	var go := func() -> void:
		persist()
		Game.last_issue = checks
		if not sandbox and Data.count_level(checks, "risk") == 0: Game.unlock("clean_check")
		if not sandbox:
			Game.tutorial["workshop"] = true
			Game.save()
		Game.go("ops" if sandbox else "transit")
	if sandbox:
		Game.flight = {}
		go.call()
		return
	UIK.close_modal(self)
	coop_gate(Game.t("Rover design review", "Revisión del diseño del rover"),
		Game.t("Review the impact: %d risks, %d limitations. Authorise the launch?", "Revisa el impacto: %d riesgos, %d limitaciones. ¿Autorizas el lanzamiento?") % [Data.count_level(checks, "risk"), Data.count_level(checks, "limit")],
		Game.t("You proposed this configuration: %d kg, %d cr. Is it ready?", "Propusiste esta configuración: %d kg, %d cr. ¿Está lista?") % [Data.mass(build), Data.cost(build)], go)

# ------------------------------------------------------------------ hangar y Sandbox
func rovers() -> Array:
	if sandbox:
		if not Game.sandbox.has("rovers"): Game.sandbox["rovers"] = []
		return Game.sandbox.rovers
	return Game.saved_rovers

func save_design() -> void:
	var list := rovers()
	var label_name := Game.rover_name if not sandbox else Game.t("Sandbox rover", "Rover de Sandbox")
	list.append({"name": "%s · %d kg · %d cr" % [label_name, Data.mass(build), Data.cost(build)], "build": build.duplicate(true)})
	while list.size() > 6: list.pop_front()
	persist()
	Game.sfx("good")
	say_owen(Game.t("Design saved to the hangar. You can load it again at any time.", "Diseño guardado en el hangar. Puedes cargarlo de nuevo cuando quieras."))

func open_hangar() -> void:
	UIK.close_modal(self)
	var content := UIK.modal(self, Vector2(680, 520), Game.t("Hangar · saved rovers", "Hangar · rovers guardados"))
	var list := rovers()
	if list.is_empty(): UIK.text(content, Game.t("No saved designs yet. Use \"Save design\" to keep a configuration and compare it later.", "Aún no hay diseños guardados. Usa «Guardar diseño» para conservar una configuración y compararla después."), 17, UIK.INK)
	for i in range(list.size()):
		var entry: Dictionary = list[i]
		var line := UIK.row(content, 8)
		UIK.label(line, String(entry.name), 16, UIK.INK, "bold").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIK.button(line, Game.t("Load", "Cargar"), func() -> void: load_design(i), "primary", Vector2(110, 40))
		UIK.button(line, Game.t("Delete", "Borrar"), func() -> void: delete_design(i), "ghost", Vector2(110, 40))
	UIK.button(content, Game.t("Close", "Cerrar"), func() -> void: UIK.close_modal(self), "ghost", Vector2(200, 44)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content)

func load_design(index: int) -> void:
	prev_mass = Data.mass(build)
	prev_cost = Data.cost(build)
	build = Data.sanitize(rovers()[index].build)
	persist()
	UIK.close_modal(self)
	preview_id = ""
	viewer.show_rover(build, viewer.rover.position, viewer.rover.rotation.y)
	refresh()

func delete_design(index: int) -> void:
	rovers().remove_at(index)
	persist()
	open_hangar()

func sandbox_intro() -> void:
	Game.hints_seen["sandbox_intro"] = true
	Game.save()
	var content := UIK.modal(self, Vector2(700, 430), "Sandbox")
	var line := UIK.row(content, 14)
	var face := Control.new()
	face.custom_minimum_size = Vector2(110, 110)
	line.add_child(face)
	portrait(face, Rect2(0, 0, 110, 110))
	UIK.text(line, Game.t("This is a free lab. Build any rover, change the mass and budget limits, pick a zone and test-drive it on Mars. Reset whenever you like.\n\nSandbox has its own save: nothing here changes your campaign, its rovers or its progress.", "Este es un laboratorio libre. Construye cualquier rover, cambia los límites de masa y presupuesto, elige una zona y pruébalo en Marte. Reinicia cuando quieras.\n\nSandbox tiene su propio guardado: nada de aquí cambia tu campaña, sus rovers ni su progreso."), 17, UIK.INK)
	UIK.button(content, Game.t("Start experimenting", "Empezar a experimentar"), func() -> void: UIK.close_modal(self), "go", Vector2(300, 50)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content)

func open_sandbox_limits() -> void:
	UIK.close_modal(self)
	var content := UIK.modal(self, Vector2(720, 560), Game.t("Sandbox limits", "Límites de Sandbox"))
	for item in [["mass_cap", Game.t("Mass limit (kg)", "Límite de masa (kg)"), 250, 800, 10], ["budget_cap", Game.t("Budget (credits)", "Presupuesto (créditos)"), 1200, 6000, 100]]:
		var key := String(item[0])
		var caption := UIK.label(content, "%s: %d" % [String(item[1]), int(Game.sandbox[key])], 17, UIK.INK, "bold")
		var slider := HSlider.new()
		slider.min_value = item[2]
		slider.max_value = item[3]
		slider.step = item[4]
		slider.value = int(Game.sandbox[key])
		slider.custom_minimum_size = Vector2(600, 28)
		var text := String(item[1])
		slider.value_changed.connect(func(value: float) -> void:
			Game.sandbox[key] = int(value)
			caption.text = "%s: %d" % [text, int(value)])
		content.add_child(slider)
	UIK.label(content, Game.t("TEST ZONE", "ZONA DE PRUEBA"), 13, UIK.MUTED, "bold")
	var zones := UIK.row(content, 8)
	for id in Data.ZONE_ORDER:
		UIK.button(zones, Game.tt(Data.ZONES[id].name), func() -> void:
			Game.sandbox.zone = id
			Game.zone = id
			Game.save()
			Game.go("design"), "primary" if Game.zone == id else "ghost", Vector2(150, 44)).add_theme_font_size_override("font_size", 14)
	UIK.label(content, Game.t("SCIENCE PRIORITY", "PRIORIDAD CIENTÍFICA"), 13, UIK.MUTED, "bold")
	var priorities := UIK.row(content, 8)
	for id in Data.PRIORITY_ORDER:
		UIK.button(priorities, Game.tt(Data.PRIORITIES[id].name), func() -> void:
			Game.sandbox.priority = id
			open_sandbox_limits(), "primary" if String(Game.sandbox.get("priority", "context")) == id else "ghost", Vector2(150, 44)).add_theme_font_size_override("font_size", 14)
	UIK.text(content, Game.t("Heavier rovers spend more energy driving; stronger mobility adds mass; advanced instruments need power, deck space and memory.", "Los rovers pesados gastan más energía al conducir; más movilidad añade masa; los instrumentos avanzados piden energía, espacio en cubierta y memoria."), 14, UIK.MUTED)
	UIK.button(content, Game.t("Apply", "Aplicar"), func() -> void:
		Game.save()
		UIK.close_modal(self)
		refresh(), "go", Vector2(220, 46)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content)

# ------------------------------------------------------------------ tutorial del taller
const COACH := [
	["Welcome to the design area! This is where %s takes shape. Pick a category on the left.", "¡Bienvenido al área de diseño! Aquí es donde %s empieza a tomar forma. Elige una categoría a la izquierda."],
	["Point at a component you have NOT installed (or move to it with the keyboard). The panel on the right compares the rover now and after.", "Señala un componente que NO tengas instalado (o llega a él con el teclado). El panel de la derecha compara el rover ahora y después."],
	["Install it: click it or press Enter. Watch mass and budget move. Click again to remove it.", "Instálalo: haz clic o pulsa Intro. Mira cómo se mueven masa y presupuesto. Otro clic lo quita."],
	["Now open MISSION READINESS. Blockers stop the launch. Risks and limitations do not: they are trade-offs you accept.", "Ahora abre MISSION READINESS. Los bloqueos impiden lanzar. Los riesgos y limitaciones no: son compromisos que aceptas."]
]

func start_coach() -> void:
	coach_step = clampi(int(Game.tutorial.get("workshop_step", 0)), 0, COACH.size() - 1)
	show_coach()

func show_coach() -> void:
	if coach.has("panel") and is_instance_valid(coach.panel): coach.panel.queue_free()
	if coach_step < 0 or coach_step >= COACH.size(): return
	coach = owen_panel(self, Rect2(216, 560, 488, 146), Game.tt(COACH[coach_step]) % Game.rover_name if coach_step == 0 else Game.tt(COACH[coach_step]), Game.t("Tutorial %d/%d", "Tutorial %d/%d") % [coach_step + 1, COACH.size()], 84.0)
	fit_cards()
	var label: Label = coach.label
	label.add_theme_font_size_override("font_size", 14)
	var skip := UIK.button(coach.panel, Game.t("Skip", "Saltar"), end_coach, "ghost", Vector2(80, 30))
	skip.position = Vector2(398, 108)
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_size_override("font_size", 13)

func coach_next() -> void:
	coach_step += 1
	Game.tutorial["workshop_step"] = coach_step
	Game.sfx("good")
	if coach_step >= COACH.size(): end_coach()
	else: show_coach()

## Mientras el tutorial está en pantalla, la lista de piezas se acorta para que no la tape.
func fit_cards() -> void:
	var area := cards_area.get_parent() as ScrollContainer
	area.size.y = 480.0 if coach_step >= 0 else 616.0

func end_coach() -> void:
	coach_step = -1
	if coach.has("panel") and is_instance_valid(coach.panel): coach.panel.queue_free()
	fit_cards()
	Game.tutorial["workshop"] = true
	Game.save()

# ------------------------------------------------------------------ visor del rover
## El arrastre y la rueda del ratón los gestiona el propio visor 3D (Stage3D).
func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and event.physical_keycode == KEY_Q: viewer.nudge(-0.3)
	elif event.pressed and event.physical_keycode == KEY_E: viewer.nudge(0.3)
