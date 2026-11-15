class_name UIK
## Kit de interfaz de ToMars: paleta cálida, paneles redondeados y botones con rebote.

const NAVY := Color("#264653")
const INK := Color("#1b3540")
const TEAL := Color("#2a9d8f")
const MINT := Color("#8fd3c1")
const YELLOW := Color("#e9c46a")
const SAND := Color("#f4a261")
const CORAL := Color("#e76f51")
const CREAM := Color("#fff4e0")
const PAPER := Color("#fffaf0")
const MUTED := Color("#6b8791")
const GOOD := Color("#3aa66b")
const BAD := Color("#d1495b")

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
	style.shadow_color = Color(0.07, 0.14, 0.17, 0.28)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0, shadow * 0.6)
	style.set_content_margin_all(14)
	style.anti_aliasing = true
	return style

static func panel(parent: Node, rect: Rect2, bg: Color = CREAM, radius: int = 20) -> Panel:
	var node := Panel.new()
	node.add_theme_stylebox_override("panel", box(bg, radius))
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
	node.focus_mode = Control.FOCUS_NONE
	var base: Color = {"primary": CORAL, "teal": TEAL, "ghost": PAPER, "dark": NAVY, "yellow": YELLOW}.get(kind, CORAL)
	var ink: Color = NAVY if kind in ["ghost", "yellow"] else PAPER
	node.add_theme_stylebox_override("normal", box(base, 16, base.darkened(0.25), 0, 4))
	node.add_theme_stylebox_override("hover", box(base.lightened(0.12), 16, base.darkened(0.25), 0, 7))
	node.add_theme_stylebox_override("pressed", box(base.darkened(0.12), 16, base.darkened(0.25), 0, 1))
	node.add_theme_stylebox_override("disabled", box(Color(base.lerp(Color("#b9c4c4"), 0.75), 0.85), 16, Color.TRANSPARENT, 0, 0))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(state, ink)
	node.add_theme_color_override("font_disabled_color", Color(NAVY, 0.45))
	node.add_theme_font_override("font", bold_font)
	node.add_theme_font_size_override("font_size", 19)
	node.pressed.connect(func() -> void: Game.sfx("click"))
	node.pressed.connect(callback)
	node.mouse_entered.connect(func() -> void: bounce(node, 1.04))
	node.mouse_exited.connect(func() -> void: bounce(node, 1.0))
	parent.add_child(node)
	return node

static func bounce(node: Control, target: float) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree(): return
	node.pivot_offset = node.size * 0.5
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2(target, target), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
	parent.add_child(area)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	area.add_child(content)
	return content

static func chip(parent: Node, caption: String, color: Color = TEAL) -> Label:
	var node := label(parent, caption, 14, PAPER, "bold")
	node.add_theme_stylebox_override("normal", box(color, 10, Color.TRANSPARENT, 0, 0))
	return node

static func pop(node: Control, delay: float = 0.0) -> void:
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", 1.0, 0.25)

static func bar(canvas: CanvasItem, rect: Rect2, ratio: float, color: Color, back: Color = Color(0.15, 0.27, 0.32, 0.25)) -> void:
	var radius := rect.size.y * 0.5
	var back_style := box(back, int(radius), Color.TRANSPARENT, 0, 0)
	canvas.draw_style_box(back_style, rect)
	var width := maxf(rect.size.y, rect.size.x * clampf(ratio, 0.0, 1.0))
	if ratio > 0.005: canvas.draw_style_box(box(color, int(radius), Color.TRANSPARENT, 0, 0), Rect2(rect.position, Vector2(width, rect.size.y)))
