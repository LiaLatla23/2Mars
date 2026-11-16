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
	node.pressed.connect(func() -> void: Game.sfx("select" if kind == "go" else "click"))
	node.pressed.connect(callback)
	node.mouse_entered.connect(func() -> void: Game.sfx("hover"))
	parent.add_child(node)
	# Respuesta compartida (scripts/motion.gd). Las acciones principales llevan imán leve y brillo.
	var hero := kind in ["go", "primary"] and min_size.y >= 50.0
	Motion.attach(node, 4.0 if hero else 0.0, 1.04, 0.012 if hero else 0.0)
	if kind == "go" and min_size.y >= 50.0: Motion.shine(node)
	return node

## Compatibilidad con V3: el rebote ahora lo resuelve Motion.
static func bounce(_node: Control, _target: float) -> void:
	pass

# ------------------------------------------------------------------ imágenes e iconos (V4)
static var textures := {}

## Textura por nombre corto ("nav_home") o ruta completa. Devuelve null si no existe.
static func tex(id: String) -> Texture2D:
	var path := id if id.begins_with("res://") else "res://assets/icons/%s.png" % id
	if not textures.has(path): textures[path] = load(path) if ResourceLoader.exists(path) else null
	return textures[path]

static func picture(parent: Node, texture: Texture2D, size: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = size
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

## Botón con icono ilustrado a la izquierda (navegación y categorías).
static func icon_button(parent: Node, caption: String, icon_id: String, callback: Callable, kind: String = "primary", min_size: Vector2 = Vector2(220, 52)) -> Button:
	var node := button(parent, caption, callback, kind, min_size)
	node.icon = tex(icon_id)
	node.expand_icon = true
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.add_theme_constant_override("icon_max_width", int(min_size.y - 14.0))
	node.add_theme_constant_override("h_separation", 10)
	return node

## Tarjeta ilustrada pulsable: imagen grande, nombre corto y una línea de cifras o estado.
## opts: image (Texture2D), title, sub, tag, accent (Color), tile (Color del fondo de la imagen),
## selected, locked, done.
static func tile(parent: Node, min_size: Vector2, callback: Callable, opts: Dictionary) -> Button:
	var node := Button.new()
	node.custom_minimum_size = min_size
	node.focus_mode = Control.FOCUS_NONE if Game.input_mode == "mouse" else Control.FOCUS_ALL
	node.clip_contents = true
	var selected := bool(opts.get("selected", false))
	var locked := bool(opts.get("locked", false))
	var accent: Color = opts.get("accent", ORANGE)
	var base: Color = (accent.lerp(PAPER, 0.55) if selected else PAPER)
	if locked: base = Color("#d9d2c2")
	node.add_theme_stylebox_override("normal", box(base, 16, INK if selected else Color(INK, 0.75), 4 if selected else 3, 5 if selected else 3))
	node.add_theme_stylebox_override("hover", box(base.lightened(0.25), 16, INK, 4, 8))
	node.add_theme_stylebox_override("pressed", box(base.darkened(0.08), 16, INK, 4, 1))
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), 16, accent, 5, 0))
	node.add_theme_stylebox_override("disabled", box(Color("#d9d2c2"), 16, Color(INK, 0.4), 2, 0))
	node.pressed.connect(func() -> void: Game.sfx("select"))
	node.pressed.connect(callback)
	node.mouse_entered.connect(func() -> void: Game.sfx("hover"))
	parent.add_child(node)
	var has_text := String(opts.get("title", "")) != ""
	var two_lines := String(opts.get("title", "")).length() > int(min_size.x / 9.5)   # nombres largos: dos líneas, sin encoger la letra
	var title_h := 0.0 if not has_text else (40.0 if two_lines else 22.0)
	var text_h := title_h + (18.0 if String(opts.get("sub", "")) != "" else 0.0)
	var art := Rect2(8, 8, min_size.x - 16, min_size.y - 18 - text_h)
	if opts.has("tile"):
		var plate := Panel.new()
		plate.add_theme_stylebox_override("panel", box(opts.tile, 11, Color(INK, 0.35), 2, 0))
		plate.position = art.position
		plate.size = art.size
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(plate)
	if opts.get("image") != null:
		var image := picture(node, opts.image, art.size - Vector2(8, 8))
		image.position = art.position + Vector2(4, 4)
		if locked: image.modulate = Color(0.25, 0.27, 0.32, 0.55)
	if has_text:
		var name_label := label(node, String(opts.title), 15, INK, "bold")
		# el ajuste de línea va ANTES del tamaño: si no, la etiqueta se queda con el ancho del texto
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if two_lines else TextServer.AUTOWRAP_OFF
		name_label.clip_text = not two_lines
		name_label.add_theme_constant_override("line_spacing", -4)
		name_label.max_lines_visible = 2
		name_label.tooltip_text = String(opts.title)
		name_label.position = Vector2(8, min_size.y - text_h - 8)
		name_label.size = Vector2(min_size.x - 16, title_h)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if String(opts.get("sub", "")) != "":
		var sub_label := label(node, String(opts.sub), 13, NAVY, "bold")
		sub_label.clip_text = true
		sub_label.tooltip_text = String(opts.sub)
		sub_label.position = Vector2(6, min_size.y - 25)
		sub_label.size = Vector2(min_size.x - 12, 18)
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_label.clip_text = true
		sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if String(opts.get("tag", "")) != "":
		var tag := chip(node, String(opts.tag), opts.get("tag_color", NAVY))
		tag.position = Vector2(12, 12)
		tag.add_theme_font_size_override("font_size", 12)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bool(opts.get("done", false)) or locked:
		var mark := picture(node, tex("pin_completed" if not locked else "pin_locked"), Vector2(34, 34))
		mark.position = Vector2(min_size.x - 40, 6)
	Motion.attach(node, 3.0, 1.05, 0.015)
	return node

## Cifra resumida con icono: lo esencial para decidir de un vistazo.
static func stat(parent: Node, icon_id: String, value: String, caption: String, color: Color = NAVY) -> HBoxContainer:
	var line := row(parent, 6)
	if icon_id != "" and tex(icon_id) != null: picture(line, tex(icon_id), Vector2(30, 30))
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", -4)
	line.add_child(words)
	label(words, value, 18, color, "title")
	label(words, caption, 12, MUTED, "bold")
	return line

## Texto con ajuste de línea dentro de un rectángulo fijo (recorta lo que no quepa y deja el
## texto completo en el tooltip). Úsalo fuera de contenedores en vez de fijar size a un Label.
static func note(parent: Node, rect: Rect2, content: String, size: int = 14, color: Color = INK, lines: int = 3) -> Label:
	var holder := column(parent, rect, 0)
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var node := text(holder, content, size, color)
	node.max_lines_visible = lines
	node.add_theme_constant_override("line_spacing", -2)
	node.tooltip_text = content
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	return node

## Par de barras finas para comparar antes (gris) y después (color).
static func duo(parent: Node, before: float, after: float, color: Color) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(60, 18)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.draw.connect(func() -> void:
		bar(node, Rect2(0, 1, node.size.x, 7), before, MUTED, Color(NAVY, 0.14))
		bar(node, Rect2(0, 10, node.size.x, 7), after, color, Color(NAVY, 0.14)))
	parent.add_child(node)
	return node

## Barra de progreso con estilo del juego (valor real, animada).
static func gauge(parent: Node, ratio: float, color: Color = ORANGE, height: float = 14.0, back: Color = Color(0.16, 0.22, 0.27, 0.2)) -> ProgressBar:
	var bar_node := ProgressBar.new()
	bar_node.max_value = 1.0
	bar_node.show_percentage = false
	bar_node.custom_minimum_size = Vector2(60, height)
	bar_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for pair in [["background", back], ["fill", color]]:
		var style := box(pair[1], int(height * 0.5), Color.TRANSPARENT, 0, 0)
		style.set_content_margin_all(0)   # sin márgenes: la barra mide exactamente su alto
		bar_node.add_theme_stylebox_override(String(pair[0]), style)
	parent.add_child(bar_node)
	Motion.fill(bar_node, clampf(ratio, 0.0, 1.0))
	return bar_node

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
	if title != "":
		var head := label(content, title, 30, NAVY, "title")
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # un título largo baja de línea; no se sale del panel
		head.custom_minimum_size.x = size.x - 52
	pop(area)
	Motion.slide_in(area, Vector2(0, 26))
	return content

static func close_modal(host: Control) -> void:
	for child in host.get_children():
		if child.is_in_group("modal"):
			child.remove_from_group("modal")
			child.queue_free()
