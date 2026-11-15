class_name UIK
## Kit de interfaz de 2Mars: paleta del equipo, paneles redondeados, botones con rebote,
## medidores animados y tarjetas. Todo el texto visible se pasa ya traducido (Game.t).

# Paleta del equipo: #191922 · #293746 · #F5DB98 · #91C6BB · #FFAD45 · #AA5D40
const INK := Color("#191922")
const NAVY := Color("#293746")
const CREAM := Color("#F5DB98")
const MINT := Color("#91C6BB")
const ORANGE := Color("#FFAD45")
const RUST := Color("#AA5D40")
# Derivados de la paleta (mismos tonos, distinto valor) y alias que ya usaba el juego.
const TEAL := Color("#3d8b82")
const YELLOW := Color("#FFAD45")
const SAND := Color("#e58f47")
const CORAL := Color("#AA5D40")
const PAPER := Color("#fff5dc")
const MUTED := Color("#6f7f8c")
const GOOD := Color("#4fae6a")
const GO := Color("#62c462")
const BAD := Color("#d1495b")
const P1 := Color("#FFAD45")   # Comandante (cooperativo)
const P2 := Color("#91C6BB")   # Ingeniero/Científico (cooperativo)

static var title_font: Font
static var body_font: Font
static var bold_font: Font

static func setup() -> void:
	if title_font != null: return
	title_font = variation("res://assets/fonts/Fredoka.ttf", 600)
	bold_font = variation("res://assets/fonts/Nunito.ttf", 800)
	body_font = variation("res://assets/fonts/Nunito.ttf", 600)

static func variation(path: String, weight: int) -> Font:
	var font := FontVariation.new()
	font.base_font = load(path)
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return font

static func box(bg: Color, radius: int = 18, border: Color = Color.TRANSPARENT, border_width: int = 0, shadow: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	style.shadow_color = Color(0.03, 0.03, 0.06, 0.35)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0, shadow * 0.6)
	style.set_content_margin_all(14)
	style.anti_aliasing = true
	return style

static func panel(parent: Node, rect: Rect2, bg: Color = PAPER, radius: int = 20) -> Panel:
	var node := Panel.new()
	node.add_theme_stylebox_override("panel", box(bg, radius, Color(INK, 0.55), 3))
	node.position = rect.position
	node.size = rect.size
	parent.add_child(node)
	return node

static func label(parent: Node, text: String, size: int = 20, color: Color = NAVY, kind: String = "body") -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", title_font if kind == "title" else (bold_font if kind == "bold" else body_font))
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

## Título con contorno oscuro, como en las referencias del equipo.
static func heading(parent: Node, text: String, size: int = 40, color: Color = PAPER) -> Label:
	var node := label(parent, text, size, color, "title")
	node.add_theme_color_override("font_outline_color", INK)
	node.add_theme_constant_override("outline_size", maxi(6, size / 5))
	return node

static func text(parent: Node, content: String, size: int = 18, color: Color = NAVY, width: float = 0.0) -> Label:
	var node := label(parent, content, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if width > 0: node.custom_minimum_size.x = width
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

static func button(parent: Node, caption: String, callback: Callable, kind: String = "primary", min_size: Vector2 = Vector2(220, 52)) -> Button:
	var node := Button.new()
	node.text = caption
	node.custom_minimum_size = min_size
	# Con ratón puro el foco estorba; con teclado es imprescindible (se ve el borde de foco).
	node.focus_mode = Control.FOCUS_NONE if Game.input_mode == "mouse" else Control.FOCUS_ALL
	var base: Color = {"primary": ORANGE, "go": GO, "teal": MINT, "ghost": PAPER, "dark": NAVY, "yellow": CREAM, "danger": BAD, "rust": RUST}.get(kind, ORANGE)
	var ink: Color = PAPER if kind in ["dark", "danger", "rust"] else INK
	var edge := Color(INK, 0.9)
	node.add_theme_stylebox_override("normal", box(base, 16, edge, 3, 4))
	node.add_theme_stylebox_override("hover", box(base.lightened(0.14), 16, edge, 3, 7))
	node.add_theme_stylebox_override("pressed", box(base.darkened(0.14), 16, edge, 3, 1))
	node.add_theme_stylebox_override("focus", box(Color(base.lightened(0.14), 0.0), 16, PAPER if kind != "ghost" else ORANGE, 4, 0))
	node.add_theme_stylebox_override("disabled", box(Color(base.lerp(Color("#8a93a0"), 0.8), 0.75), 16, Color(INK, 0.35), 2, 0))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(state, ink)
	node.add_theme_color_override("font_disabled_color", Color(INK, 0.5))
	node.add_theme_font_override("font", bold_font)
	node.add_theme_font_size_override("font_size", 19)
	node.pressed.connect(func() -> void: Game.sfx("click", 1.0 if kind != "go" else 1.2))
	node.pressed.connect(callback)
	node.mouse_entered.connect(func() -> void:
		bounce(node, 1.04)
		Game.sfx("hover"))
	node.mouse_exited.connect(func() -> void: bounce(node, 1.0))
	node.focus_entered.connect(func() -> void: bounce(node, 1.04))
	node.focus_exited.connect(func() -> void: bounce(node, 1.0))
	parent.add_child(node)
	return node

static func bounce(node: Control, target: float) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree(): return
	if Game.reduced_motion:
		node.scale = Vector2.ONE
		return
	node.pivot_offset = node.size * 0.5
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2(target, target), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Da el foco al primer botón activo (modo teclado). No hace nada en modo ratón.
static func focus_first(root: Node) -> void:
	if Game.input_mode == "mouse" or not is_instance_valid(root): return
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button.focus_mode == Control.FOCUS_ALL and not button.disabled and button.is_visible_in_tree():
			button.grab_focus.call_deferred()
			return

static func column(parent: Node, rect: Rect2, gap: int = 10) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_constant_override("separation", gap)
	parent.add_child(node)
	return node

static func row(parent: Node, gap: int = 10) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	parent.add_child(node)
	return node

static func scroll(parent: Node, rect: Rect2) -> VBoxContainer:
	var area := ScrollContainer.new()
	area.position = rect.position
	area.size = rect.size
	area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	area.follow_focus = true
	parent.add_child(area)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	area.add_child(content)
	return content

static func chip(parent: Node, caption: String, color: Color = TEAL) -> Label:
	var node := label(parent, caption, 14, PAPER if color.get_luminance() < 0.55 else INK, "bold")
	var style := box(color, 10, Color.TRANSPARENT, 0, 0)
	style.set_content_margin_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	node.add_theme_stylebox_override("normal", style)
	return node

## Tarjeta que se ajusta a su contenido (para listas e informes).
static func card(parent: Node, title: String = "", accent: Color = MINT, bg: Color = PAPER) -> VBoxContainer:
	var holder := PanelContainer.new()
	var style := box(bg, 14, Color(INK, 0.35), 2, 2)
	style.border_width_left = 8
	style.border_color = accent
	style.set_content_margin_all(12)
	style.content_margin_left = 18
	holder.add_theme_stylebox_override("panel", style)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(holder)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	holder.add_child(content)
	if title != "": label(content, title, 14, MUTED, "bold")
	return content

static func pop(node: Control, delay: float = 0.0) -> void:
	if Game.reduced_motion: return
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", 1.0, 0.25)

## Medidor animado: la barra viaja desde el valor anterior y muestra la diferencia.
static func meter(parent: Node, caption: String, value: float, limit: float, unit: String, previous: float = -1.0, lower_is_better: bool = true) -> ProgressBar:
	var over := value > limit
	var line := row(parent, 8)
	var title_label := label(line, caption, 15, BAD if over else NAVY, "bold")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if previous >= 0.0 and absf(value - previous) > 0.5:
		var delta := value - previous
		var good := (delta < 0.0) == lower_is_better
		chip(line, "%s%d %s" % ["+" if delta > 0 else "−", int(absf(delta)), unit], GOOD if good else SAND)
	var amount := label(line, "%d / %d %s" % [int(value), int(limit), unit], 15, BAD if over else NAVY, "bold")
	var bar := ProgressBar.new()
	bar.max_value = limit
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	bar.add_theme_stylebox_override("background", box(Color(NAVY, 0.18), 7, Color.TRANSPARENT, 0, 0))
	bar.add_theme_stylebox_override("fill", box(BAD if over else (SAND if value > limit * 0.88 else TEAL), 7, Color.TRANSPARENT, 0, 0))
	parent.add_child(bar)
	var start := previous if previous >= 0.0 else value
	bar.value = minf(start, limit)
	if Game.reduced_motion or absf(start - value) < 0.5: bar.value = minf(value, limit)
	else:
		var tween := bar.create_tween()
		tween.tween_property(bar, "value", minf(value, limit), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_method(func(v: float) -> void: amount.text = "%d / %d %s" % [int(v), int(limit), unit], start, value, 0.45)
	return bar

static func bar(canvas: CanvasItem, rect: Rect2, ratio: float, color: Color, back: Color = Color(0.1, 0.12, 0.18, 0.3)) -> void:
	var radius := rect.size.y * 0.5
	var back_style := box(back, int(radius), Color.TRANSPARENT, 0, 0)
	canvas.draw_style_box(back_style, rect)
	var width := maxf(rect.size.y, rect.size.x * clampf(ratio, 0.0, 1.0))
	if ratio > 0.005: canvas.draw_style_box(box(color, int(radius), Color.TRANSPARENT, 0, 0), Rect2(rect.position, Vector2(width, rect.size.y)))

## Campo de texto con el estilo del juego.
static func field(parent: Node, value: String, max_length: int = 16, placeholder: String = "") -> LineEdit:
	var node := LineEdit.new()
	node.text = value
	node.max_length = max_length
	node.placeholder_text = placeholder
	node.custom_minimum_size = Vector2(0, 46)
	node.add_theme_font_override("font", bold_font)
	node.add_theme_font_size_override("font_size", 20)
	node.add_theme_color_override("font_color", INK)
	node.add_theme_color_override("font_placeholder_color", Color(INK, 0.4))
	node.add_theme_color_override("caret_color", INK)
	node.add_theme_stylebox_override("normal", box(PAPER, 12, Color(INK, 0.8), 3, 0))
	node.add_theme_stylebox_override("focus", box(PAPER, 12, ORANGE, 4, 0))
	parent.add_child(node)
	return node

## Enlace a una fuente: abre el navegador del sistema.
static func link(parent: Node, caption: String, url: String) -> Button:
	var node := button(parent, caption + "  ↗", func() -> void: OS.shell_open(url), "ghost", Vector2(0, 34))
	node.add_theme_font_size_override("font_size", 14)
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.tooltip_text = url
	return node

## Diálogo modal centrado sobre un velo; devuelve la columna de contenido.
static func modal(host: Control, size: Vector2, title: String = "") -> VBoxContainer:
	var veil := ColorRect.new()
	veil.name = "Modal"
	veil.add_to_group("modal")   # se cierra por grupo: el nombre puede cambiar si hay otro modal
	veil.color = Color(INK, 0.72)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.z_index = 50
	host.add_child(veil)
	var area := panel(veil, Rect2((Vector2(1280, 720) - size) * 0.5, size))
	var content := column(area, Rect2(26, 20, size.x - 52, size.y - 40), 10)
	if title != "": label(content, title, 30, NAVY, "title")
	pop(area)
	return content

static func close_modal(host: Control) -> void:
	for child in host.get_children():
		if child.is_in_group("modal"):
			child.remove_from_group("modal")
			child.queue_free()
