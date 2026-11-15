class_name BaseScreen
extends Control
## Base de todas las pantallas: reloj, fondo, logotipo, panel de la Dra. Owen, historias
## opcionales («¡Espera!») y confirmación doble del cooperativo.

var time := 0.0
var backdrop := "space"      # space | workshop | plain | none
var backdrop_dim := 0.0
var gate: Dictionary = {}    # confirmación doble activa en cooperativo
var portraits: Array = []
var typing: Array = []
var notice_at := Vector2(445, 6)   # zona reservada para el aviso de logro en esta pantalla
var scene3d: Stage3D              # fondo 3D opcional (taller, paisaje de Marte)

func _process(delta: float) -> void:
	time += delta
	tick(delta)
	portraits = portraits.filter(func(node: Variant) -> bool: return is_instance_valid(node))
	for node in portraits: node.queue_redraw()
	queue_redraw()

func tick(_delta: float) -> void:
	pass

## Fondo 3D a pantalla completa, detrás de todo lo demás. kind: vista | workshop | mars_workshop.
func stage_backdrop(kind: String) -> Stage3D:
	backdrop = "none"
	scene3d = Stage3D.make(self, Rect2(0, 0, 1280, 720))
	scene3d.show_behind_parent = true
	move_child(scene3d, 0)
	if kind == "vista":
		scene3d.vista()
		scene3d.goal = Vector3(0.0, 0.07, 27.0)
		scene3d.orbit = scene3d.goal
		scene3d.sway = 0.035
		scene3d.parallax = 0.03
	else:
		scene3d.workshop(kind == "mars_workshop")
		scene3d.parallax = 0.04
	if Game.quality == 0: scene3d.freeze.call_deferred()   # calidad baja: el fondo no se redibuja en cada fotograma
	return scene3d

## Velo de color sobre el fondo (legibilidad de paneles claros u oscuros).
func shade(rect: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func _draw() -> void:
	match backdrop:
		"space": Art.space(self, size, time, true, backdrop_dim)
		"stars": Art.space(self, size, time, false, backdrop_dim)
		"workshop":
			Art.workshop(self, size, time)
			if backdrop_dim > 0.0: draw_rect(Rect2(Vector2.ZERO, size), Color(UIK.INK, backdrop_dim))
		"plain": Art.gradient(self, Rect2(Vector2.ZERO, size), UIK.INK, UIK.NAVY)
	paint()

func paint() -> void:
	pass

## Logotipo 2MARS del equipo.
func logo(rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load("res://assets/brand/logo_2mars.png")
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func title(text: String, pos: Vector2 = Vector2(212, 26), size_px: int = 40) -> Label:
	var node := UIK.heading(self, text, size_px)
	node.position = pos
	return node

func back_button(caption: String, target: String, pos: Vector2 = Vector2(1090, 24)) -> Button:
	var node := UIK.button(self, caption, func() -> void: Game.go(target), "ghost", Vector2(160, 46))
	node.position = pos
	return node

## Retrato animado de la Dra. Owen como nodo.
func portrait(parent: Node, rect: Rect2, happy: bool = true) -> Control:
	var node := Control.new()
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.draw.connect(func() -> void: Art.owen(node, Rect2(Vector2.ZERO, node.size), time, happy))
	parent.add_child(node)
	portraits.append(node)
	return node

## Panel de diálogo de la Dra. Owen: retrato + texto con máquina de escribir (se completa al
## instante con movimiento reducido). Devuelve {panel, label, column}.
func owen_panel(parent: Node, rect: Rect2, text: String, role: String = "", face_max: float = 118.0) -> Dictionary:
	var panel := UIK.panel(parent, rect)
	var face := minf(rect.size.y - 28.0, face_max)
	portrait(panel, Rect2(14, 14, face, face))
	var column := UIK.column(panel, Rect2(face + 28, 12, rect.size.x - face - 44, rect.size.y - 24), 4)
	UIK.label(column, Game.owen() + (" · " + role if role != "" else ""), 14, UIK.TEAL, "bold")
	var label := UIK.text(column, text, 17, UIK.INK)
	type_in(label)
	return {"panel": panel, "label": label, "column": column}

func type_in(label: Label) -> void:
	if Game.reduced_motion: return
	label.visible_ratio = 0.0
	var tween := Motion.tween(label, "type")
	tween.tween_property(label, "visible_ratio", 1.0, clampf(label.text.length() * 0.008, 0.25, 1.0))
	typing.append(label)

## Cualquier clic o tecla muestra de inmediato el texto que se está «escribiendo».
func finish_typing() -> void:
	for label in typing:
		if not is_instance_valid(label): continue
		var tween: Variant = (label as Label).get_meta("tw_type", null)
		if tween is Tween and (tween as Tween).is_valid(): (tween as Tween).kill()
		(label as Label).visible_ratio = 1.0
	typing = []

## Conversación opcional: «¡Espera! ¿No tienes algo más que contarme?»
func wait_button(parent: Node) -> Button:
	var node := UIK.button(parent, Game.t("Wait! Don't you have anything else to tell me?", "¡Espera! ¿No tienes algo más que contarme?"), show_story, "ghost", Vector2(0, 38))
	node.add_theme_font_size_override("font_size", 15)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # la frase es larga: que se parta en vez de ensanchar el panel
	node.custom_minimum_size.x = 250
	return node

func show_story(pick: String = "") -> void:
	var id := pick if pick != "" else Game.next_story()
	var story: Dictionary = Data.STORIES[id]
	var content := UIK.modal(self, Vector2(720, 400), Game.tt(story.title))
	var line := UIK.row(content, 14)
	var face := Control.new()
	face.custom_minimum_size = Vector2(110, 110)
	line.add_child(face)
	portrait(face, Rect2(0, 0, 110, 110))
	type_in(UIK.text(line, Game.tt(story.text), 17, UIK.INK))
	UIK.label(content, Game.t("Real mission history · source: ", "Historia real de misiones · fuente: ") + String(story.source), 13, UIK.MUTED, "bold")
	if story.has("url"): UIK.link(content, Game.t("Open the NASA page", "Abrir la página de la NASA"), String(story.url))
	var done := UIK.button(content, Game.t("Thanks", "Gracias"), func() -> void: UIK.close_modal(self), "primary", Vector2(200, 48))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Game.hear_story(id)
	UIK.focus_first(content)

## Cooperativo: una decisión compartida exige la confirmación de AMBOS roles.
## En un jugador se ejecuta directamente.
func coop_gate(heading: String, commander_task: String, engineer_task: String, on_ok: Callable) -> void:
	if not Game.coop:
		on_ok.call()
		return
	var content := UIK.modal(self, Vector2(760, 420), heading)
	var roles := UIK.row(content, 16)
	gate = {"p1": false, "p2": false, "ok": on_ok, "chips": {}}
	# Las teclas van con el ROL: Comandante = Intro, Ingeniero = F (o botón A del mando).
	for id in ["p1", "p2"]:
		var commander: bool = id == "p1"
		var player := 1 if commander != Game.coop_swapped else 2
		var card := UIK.card(roles, Game.t("PLAYER %d", "JUGADOR %d") % player, UIK.P1 if commander else UIK.P2)
		UIK.label(card, Game.t("Mission Commander", "Comandante de misión") if commander else Game.t("Rover Engineer & Scientist", "Ingeniero y científico del rover"), 20, UIK.NAVY, "title")
		UIK.text(card, commander_task if commander else engineer_task, 15, UIK.INK)
		var key := Game.t("Enter", "Intro") if commander else "F"
		var button := UIK.button(card, Game.t("Confirm  [%s]", "Confirmar  [%s]") % key, func() -> void: gate_press(id), "primary" if commander else "teal", Vector2(0, 46))
		button.focus_mode = Control.FOCUS_NONE
		gate.chips[id] = button
	UIK.text(content, Game.t("Both players must confirm. Talk it over first: the mission state is shared.", "Ambos jugadores deben confirmar. Háblenlo primero: el estado de la misión es compartido."), 15, UIK.MUTED)
	var cancel := UIK.button(content, Game.t("Not yet", "Todavía no"), gate_cancel, "ghost", Vector2(180, 42))
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func gate_cancel() -> void:
	gate = {}
	UIK.close_modal(self)

func gate_press(id: String) -> void:
	if gate.is_empty() or bool(gate[id]): return
	gate[id] = true
	Game.sfx("good")
	var button: Button = gate.chips[id]
	button.text = Game.t("Confirmed ✓", "Confirmado ✓")
	button.disabled = true
	if gate.p1 and gate.p2:
		var callback: Callable = gate.ok
		gate = {}
		UIK.close_modal(self)
		callback.call()

func _input(event: InputEvent) -> void:
	if not typing.is_empty() and ((event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo)): finish_typing()
	if gate.is_empty(): return
	if event.is_action_pressed("p1_confirm"):
		gate_press("p1")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("p2_confirm"):
		gate_press("p2")
		get_viewport().set_input_as_handled()

## Tira con los nombres de rol (solo en cooperativo).
func coop_banner(pos: Vector2, commander_does: String, engineer_does: String) -> void:
	if not Game.coop: return
	var line := UIK.row(self, 8)
	line.position = pos
	var commander_player := 2 if Game.coop_swapped else 1
	UIK.chip(line, " J%d · %s: %s " % [commander_player, Game.t("Commander", "Comandante"), commander_does], UIK.P1)
	UIK.chip(line, " J%d · %s: %s " % [3 - commander_player, Game.t("Engineer", "Ingeniero"), engineer_does], UIK.P2)
