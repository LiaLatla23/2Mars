class_name Motion
## Sistema de movimiento compartido de 2Mars (V4).
##
## - Hover/foco, pulsación, efecto magnético e inclinación se resuelven con un muelle por control
##   (clase Fx): no hay colas de tweens que se acumulen y repetir hover o pulsar deprisa solo
##   cambia el objetivo del muelle. La integración usa pasos fijos, así que es independiente del
##   framerate.
## - El efecto es SOLO visual: se aplica al transform del canvas item en RenderingServer, de modo
##   que el rectángulo del control (y su área de clic) no se mueve.
## - Con «movimiento reducido» se anulan escalado, imán, inclinación, entradas y destellos; los
##   estados (hover, foco, seleccionado, deshabilitado) siguen viéndose por color y borde.
##
## Rangos de partida (ajustables): hover/foco ~130 ms · pulsación ~80 ms · panel 220 ms ·
## escalonado 28 ms por elemento con tope de 340 ms.

const PANEL := 0.22
const STAGGER := 0.028
const STAGGER_CAP := 0.34
const SHINE := "shader_type canvas_item;\nuniform float period = 4.0;\nuniform float span = 220.0;\nuniform float strength = 0.3;\nuniform float phase = 0.0;\nvarying vec2 local;\nvoid vertex() { local = VERTEX; }\nvoid fragment() {\n\tfloat t = fract((TIME + phase) / period) * 3.2 - 1.0;\n\tfloat x = (local.x + local.y * 0.7) / span;\n\tfloat band = smoothstep(0.16, 0.0, abs(x - t));\n\tCOLOR.rgb += band * strength * COLOR.a;\n}\n"

static var shine_shader: Shader

class Fx extends Node:
	var target: Control
	var lift := 1.04          # escala al pasar el cursor o recibir foco
	var magnet := 0.0         # px máximos de desplazamiento visual hacia el cursor
	var tilt := 0.0           # rad máximos de inclinación
	var hovered := false
	var focused := false
	var press := 0.0
	var scale_now := 1.0
	var scale_vel := 0.0
	var offset_now := Vector2.ZERO
	var tilt_now := 0.0
	var intro := 1.0          # 0..1 (1 = entrada terminada)
	var intro_delay := 0.0
	var intro_from := Vector2(0, 16)

	func wake() -> void:
		set_process(true)

	func enter(delay: float, from: Vector2 = Vector2(0, 16)) -> void:
		if Game.reduced_motion or not is_instance_valid(target): return
		intro = 0.0
		intro_delay = delay
		intro_from = from
		target.modulate.a = 0.0
		wake()

	func _process(delta: float) -> void:
		if not is_instance_valid(target) or not target.is_inside_tree():
			return
		var reduced: bool = Game.reduced_motion
		var active := (hovered or focused) and not reduced and not (target is BaseButton and (target as BaseButton).disabled)
		press = maxf(0.0, press - delta)
		var goal := 1.0
		if press > 0.0 and not reduced: goal = 0.955
		elif active: goal = lift
		# muelle subamortiguado: pequeño rebote controlado, pasos fijos de 1/240 s
		var left := minf(delta, 0.1)
		while left > 0.0:
			var step := minf(left, 1.0 / 240.0)
			var stiffness := 3600.0 if press > 0.0 else 1500.0
			scale_vel += (-stiffness * (scale_now - goal) - 46.0 * scale_vel) * step
			scale_now += scale_vel * step
			left -= step
		var want_offset := Vector2.ZERO
		var want_tilt := 0.0
		if active and hovered and magnet > 0.0:
			var half := target.size * 0.5
			var pull := ((target.get_local_mouse_position() - half) / half).clamp(Vector2(-1, -1), Vector2(1, 1))
			want_offset = pull * magnet
			want_tilt = pull.x * tilt
		var blend := 1.0 - exp(-delta * 16.0)
		offset_now = offset_now.lerp(want_offset, blend)
		tilt_now = lerpf(tilt_now, want_tilt, blend)
		var slide := Vector2.ZERO
		if intro < 1.0:
			if intro_delay > 0.0: intro_delay -= delta
			else: intro = minf(1.0, intro + delta / 0.24)
			var eased := 1.0 - pow(1.0 - intro, 3.0)
			target.modulate.a = eased
			slide = intro_from * (1.0 - eased)
		var resting := intro >= 1.0 and absf(scale_now - 1.0) < 0.0008 and absf(scale_vel) < 0.002 and offset_now.length() < 0.05 and absf(tilt_now) < 0.0005 and not active and press <= 0.0
		if resting:
			scale_now = 1.0
			scale_vel = 0.0
			offset_now = Vector2.ZERO
			tilt_now = 0.0
			set_process(false)
		var pivot := target.size * 0.5
		var xform := Transform2D(tilt_now, Vector2(scale_now, scale_now), 0.0, Vector2.ZERO)
		xform.origin = target.position + offset_now + slide + pivot - xform.basis_xform(pivot)
		RenderingServer.canvas_item_set_transform(target.get_canvas_item(), xform)

static func fx_of(node: Control) -> Fx:
	if node.has_meta("fx") and is_instance_valid(node.get_meta("fx")): return node.get_meta("fx")
	var fx := Fx.new()
	fx.target = node
	fx.set_process(false)
	node.add_child(fx, false, Node.INTERNAL_MODE_BACK)
	node.set_meta("fx", fx)
	return fx

## Respuesta de hover, foco y pulsación para un control interactivo.
static func attach(node: Control, magnet: float = 0.0, lift: float = 1.04, tilt: float = 0.0) -> Fx:
	var fx := fx_of(node)
	fx.magnet = magnet
	fx.lift = lift
	fx.tilt = tilt
	if node.has_meta("fx_wired"): return fx
	node.set_meta("fx_wired", true)
	node.mouse_entered.connect(func() -> void:
		fx.hovered = true
		fx.wake())
	node.mouse_exited.connect(func() -> void:
		fx.hovered = false
		fx.wake())
	node.focus_entered.connect(func() -> void:
		fx.focused = true
		fx.wake())
	node.focus_exited.connect(func() -> void:
		fx.focused = false
		fx.wake())
	if node is BaseButton:
		(node as BaseButton).button_down.connect(func() -> void:
			fx.press = 0.085
			fx.wake())
	return fx

## Aparición escalonada (20-35 ms entre elementos, duración total limitada).
static func stagger(nodes: Array, step: float = STAGGER, from: Vector2 = Vector2(0, 16)) -> void:
	if Game.reduced_motion: return
	var index := 0
	for node in nodes:
		if not node is Control: continue
		fx_of(node).enter(minf(index * step, STAGGER_CAP), from)
		index += 1

## Tween con clave: cancela el anterior de la misma clave antes de crear el nuevo (sin colas).
static func tween(node: Node, key: String) -> Tween:
	var slot := "tw_" + key
	if node.has_meta(slot):
		var old: Variant = node.get_meta(slot)
		if old is Tween and (old as Tween).is_valid(): (old as Tween).kill()
	var fresh := node.create_tween()
	node.set_meta(slot, fresh)
	return fresh

## Cambio de panel (180-280 ms): desliza y funde. El control queda interactivo desde el inicio.
static func slide_in(node: Control, from: Vector2, seconds: float = PANEL) -> void:
	if Game.reduced_motion: return
	var home := node.position
	node.position = home + from
	node.modulate.a = 0.0
	var t := tween(node, "slide").set_parallel(true)
	t.tween_property(node, "position", home, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "modulate:a", 1.0, seconds * 0.8)

## Contador animado desde datos reales.
static func count(label: Label, from: float, to: float, format: String, seconds: float = 0.6) -> void:
	if Game.reduced_motion or is_equal_approx(from, to):
		label.text = format % int(round(to))
		return
	label.text = format % int(round(from))
	var t := tween(label, "count")
	t.tween_method(func(v: float) -> void: label.text = format % int(round(v)), from, to, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Barra que viaja hasta su valor real.
static func fill(bar: Range, to: float, seconds: float = 0.55, delay: float = 0.0) -> void:
	if Game.reduced_motion:
		bar.value = to
		return
	var t := tween(bar, "fill")
	if delay > 0.0: t.tween_interval(delay)
	t.tween_property(bar, "value", to, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Brillo deslizante ocasional (acciones principales y recompensas).
static func shine(node: Control, period: float = 4.0, strength: float = 0.3) -> void:
	if Game.reduced_motion: return
	if shine_shader == null:
		shine_shader = Shader.new()
		shine_shader.code = SHINE
	var material := ShaderMaterial.new()
	material.shader = shine_shader
	material.set_shader_parameter("period", period)
	material.set_shader_parameter("strength", strength)
	material.set_shader_parameter("span", maxf(120.0, node.custom_minimum_size.x))
	material.set_shader_parameter("phase", fmod(node.get_instance_id() * 0.37, period))
	node.material = material

## Celebración breve: salto de escala y regreso (recompensas y desbloqueos).
static func celebrate(node: Control) -> void:
	if Game.reduced_motion: return
	var fx := fx_of(node)
	fx.scale_now = 0.7
	fx.scale_vel = 6.0
	fx.wake()
