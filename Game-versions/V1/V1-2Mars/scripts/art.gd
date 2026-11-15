class_name Art
## Arte low-poly dibujado por código: facetas planas, luz desde arriba a la izquierda.
## Todo el arte del juego es vectorial y original; no usa imágenes ni emblemas oficiales.

const LIGHT := Vector2(-0.64, -0.77)

static func shade(color: Color, amount: float) -> Color:
	return color.lightened(amount) if amount >= 0.0 else color.darkened(-amount)

static func blob(center: Vector2, rx: float, ry: float, seed_value: int, count: int = 9, jitter: float = 0.22) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array()
	for i in range(count):
		var angle := TAU * i / count + rng.randf_range(-0.18, 0.18)
		var reach := rng.randf_range(1.0 - jitter, 1.0 + jitter * 0.5)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry) * reach)
	return points

static func gradient(canvas: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	canvas.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), PackedColorArray([top, top, bottom, bottom]))

## Roca facetada con volumen: sombra, caras laterales y tapa.
static func rock(canvas: CanvasItem, pos: Vector2, radius: float, seed_value: int, base: Color, height: float = 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := 6 + seed_value % 3
	var ground := PackedVector2Array()
	for i in range(count):
		var angle := TAU * i / count + rng.randf_range(-0.2, 0.2)
		ground.append(pos + Vector2(cos(angle), sin(angle) * 0.78) * radius * rng.randf_range(0.8, 1.08))
	var shadow := PackedVector2Array()
	for point in ground: shadow.append(point + Vector2(radius * 0.34, radius * 0.26))
	canvas.draw_colored_polygon(shadow, Color(0.1, 0.05, 0.05, 0.2))
	var lift := radius * 0.62 * height
	var top := PackedVector2Array()
	for point in ground: top.append(pos + (point - pos) * 0.56 + Vector2(-radius * 0.06, -lift))
	var order: Array = range(count)
	order.sort_custom(func(a: int, b: int) -> bool: return ground[a].y + ground[(a + 1) % count].y < ground[b].y + ground[(b + 1) % count].y)
	for i in order:
		var next: int = (i + 1) % count
		var normal: Vector2 = ((ground[i] + ground[next]) * 0.5 - pos).normalized()
		var lit: float = normal.dot(-LIGHT) * -1.0
		canvas.draw_colored_polygon(PackedVector2Array([ground[i], ground[next], top[next], top[i]]), shade(base, lit * 0.2 - 0.08))
	canvas.draw_colored_polygon(top, shade(base, 0.16))
	canvas.draw_colored_polygon(PackedVector2Array([top[0], top[1], top[count / 2]]), shade(base, 0.26))

## Cordillera facetada para fondos.
static func ridge(canvas: CanvasItem, left: float, right: float, base_y: float, height: float, seed_value: int, color: Color, peaks: int = 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var step := (right - left) / peaks
	var previous := Vector2(left - step * 0.5, base_y)
	for i in range(peaks + 1):
		var peak := Vector2(left + step * i + rng.randf_range(-step * 0.2, step * 0.2), base_y - height * rng.randf_range(0.45, 1.0))
		var foot := Vector2(peak.x + step * rng.randf_range(0.45, 0.7), base_y)
		canvas.draw_colored_polygon(PackedVector2Array([previous, peak, Vector2(peak.x + step * 0.08, base_y)]), shade(color, 0.1))
		canvas.draw_colored_polygon(PackedVector2Array([peak, foot, Vector2(peak.x + step * 0.08, base_y)]), shade(color, -0.12))
		previous = Vector2(peak.x - step * 0.15, base_y)
	canvas.draw_rect(Rect2(left - step, base_y - 1, right - left + step * 2, 4), color)

## Paisaje marciano para menús: cielo, sol, mesetas y dunas.
static func landscape(canvas: CanvasItem, size: Vector2, time: float = 0.0, dusk: bool = false) -> void:
	var top := Color("#f6c28b") if not dusk else Color("#3d3466")
	var bottom := Color("#f4a261") if not dusk else Color("#e07a5f")
	gradient(canvas, Rect2(Vector2.ZERO, size), top, bottom)
	var sun := Vector2(size.x * 0.76, size.y * 0.3)
	for i in range(4): canvas.draw_circle(sun, 120.0 - i * 22.0 + sin(time * 0.8) * 3.0, Color(1.0, 0.95, 0.8, 0.1 + i * 0.05))
	canvas.draw_circle(sun, 44, Color("#fff1cf"))
	ridge(canvas, 0, size.x, size.y * 0.56, size.y * 0.2, 11, Color("#e58c5a") if not dusk else Color("#a65a5e"), 9)
	ridge(canvas, 0, size.x, size.y * 0.66, size.y * 0.16, 23, Color("#d9744a") if not dusk else Color("#8b4a55"), 6)
	canvas.draw_rect(Rect2(0, size.y * 0.66, size.x, size.y * 0.34), Color("#c9603f") if not dusk else Color("#7a3f4c"))
	var dune := PackedVector2Array([Vector2(0, size.y * 0.8), Vector2(size.x * 0.3, size.y * 0.72), Vector2(size.x * 0.62, size.y * 0.79), Vector2(size.x, size.y * 0.7), Vector2(size.x, size.y), Vector2(0, size.y)])
	canvas.draw_colored_polygon(dune, Color("#b9523a") if not dusk else Color("#693644"))
	var near := PackedVector2Array([Vector2(0, size.y * 0.92), Vector2(size.x * 0.4, size.y * 0.86), Vector2(size.x, size.y * 0.93), Vector2(size.x, size.y), Vector2(0, size.y)])
	canvas.draw_colored_polygon(near, Color("#a34631") if not dusk else Color("#57303d"))
	rock(canvas, Vector2(size.x * 0.1, size.y * 0.88), 46, 5, Color("#8f3f2f"))
	rock(canvas, Vector2(size.x * 0.9, size.y * 0.9), 60, 8, Color("#8f3f2f"))
	rock(canvas, Vector2(size.x * 0.58, size.y * 0.84), 24, 3, Color("#a04a35"))

## Rover visto desde arriba. El dibujo refleja las piezas elegidas en el diseño.
## base_offset/base_scale: transformación de cámara ya activa en el lienzo (se restaura al terminar).
static func rover(canvas: CanvasItem, pos: Vector2, heading: float, build: Dictionary, scale: float = 1.0, time: float = 0.0, lamp: bool = false, base_offset: Vector2 = Vector2.ZERO, base_scale: float = 1.0) -> void:
	var instruments: Array = build.get("instruments", [])
	var unit := Vector2(scale, scale) * base_scale
	canvas.draw_set_transform(base_offset + (pos + Vector2(7, 9) * scale) * base_scale, heading, unit)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-34, -24), Vector2(34, -24), Vector2(38, 0), Vector2(34, 24), Vector2(-34, 24)]), Color(0.1, 0.05, 0.05, 0.22))
	canvas.draw_set_transform(base_offset + pos * base_scale, heading, unit)
	if lamp: canvas.draw_colored_polygon(PackedVector2Array([Vector2(26, -6), Vector2(150, -58), Vector2(150, 58), Vector2(26, 6)]), Color(1.0, 0.95, 0.75, 0.13))
	var rugged: bool = String(build.get("wheels", "standard")) == "rugged"
	for x in [-23.0, 0.0, 23.0]:
		for side in [-1.0, 1.0]:
			canvas.draw_line(Vector2(x * 0.6, side * 8), Vector2(x, side * 19), Color("#7d8b93"), 3.0)
			var wheel := Rect2(x - 8, side * 20 - (5 if rugged else 4), 16, 10 if rugged else 8)
			canvas.draw_rect(wheel, Color("#2c3338"))
			canvas.draw_rect(Rect2(wheel.position + Vector2(2, 1), Vector2(3, wheel.size.y - 2)), Color("#59656c"))
			canvas.draw_rect(Rect2(wheel.position + Vector2(9, 1), Vector2(3, wheel.size.y - 2)), Color("#59656c"))
	canvas.draw_rect(Rect2(-27, -12, 54, 28), Color("#b9b3a4"))
	canvas.draw_rect(Rect2(-27, -15, 54, 26), Color("#f5f0e3"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-27, -15), Vector2(4, -15), Vector2(-27, 6)]), Color("#fffaf0"))
	if String(build.get("power", "solar")) == "solar":
		canvas.draw_rect(Rect2(-30, -14, 26, 24), Color("#2f6f9f"))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-30, -14), Vector2(-4, -14), Vector2(-30, 4)]), Color("#3f86bd"))
		for i in range(1, 3): canvas.draw_line(Vector2(-30 + i * 8.6, -14), Vector2(-30 + i * 8.6, 10), Color("#1f4f76"), 1.0)
		canvas.draw_line(Vector2(-30, -2), Vector2(-4, -2), Color("#1f4f76"), 1.0)
	else:
		canvas.draw_rect(Rect2(-42, -7, 17, 14), Color("#3b4047"))
		for i in range(4): canvas.draw_line(Vector2(-40 + i * 4.5, -10), Vector2(-40 + i * 4.5, 10), Color("#565d66"), 2.0)
		canvas.draw_circle(Vector2(-27, 0), 3.0, Color("#e76f51"))
	if String(build.get("comms", "uhf")) == "hga":
		var dish := PackedVector2Array()
		for i in range(6): dish.append(Vector2(2, -4) + Vector2.from_angle(TAU * i / 6.0) * 9.0)
		canvas.draw_colored_polygon(dish, Color("#e9c46a"))
		canvas.draw_colored_polygon(PackedVector2Array([dish[3], dish[4], dish[5], Vector2(2, -4)]), Color("#f3d98f"))
		canvas.draw_circle(Vector2(2, -4), 2.0, Color("#264653"))
	else:
		canvas.draw_line(Vector2(-2, -8), Vector2(-2, -19), Color("#7d8b93"), 2.0)
		canvas.draw_circle(Vector2(-2, -19), 2.0, Color("#264653"))
	if "moxie" in instruments: canvas.draw_rect(Rect2(6, 1, 11, 9), Color("#d9a441"))
	if "meda" in instruments:
		canvas.draw_line(Vector2(17, -9), Vector2(8, -24), Color("#7d8b93"), 1.5)
		canvas.draw_circle(Vector2(8, -24), 2.0, Color("#2a9d8f"))
	if "rimfax" in instruments: canvas.draw_colored_polygon(PackedVector2Array([Vector2(-27, 8), Vector2(-36, 14), Vector2(-27, 14)]), Color("#2a9d8f"))
	if "mastcam" in instruments or "supercam" in instruments:
		canvas.draw_circle(Vector2(18, -8), 4.0, Color("#59656c"))
		canvas.draw_rect(Rect2(19, -14, 12, 11), Color("#fffaf0"))
		canvas.draw_rect(Rect2(19, -5, 12, 2), Color("#b9b3a4"))
		if "supercam" in instruments: canvas.draw_circle(Vector2(27, -9), 3.2, Color("#264653"))
		else:
			canvas.draw_circle(Vector2(24, -9), 1.6, Color("#264653"))
			canvas.draw_circle(Vector2(28, -9), 1.6, Color("#264653"))
	if "arm" in instruments:
		var swing := sin(time * 2.0) * 1.5
		canvas.draw_line(Vector2(26, 7), Vector2(38, 12 + swing), Color("#8b98a0"), 4.0)
		canvas.draw_line(Vector2(38, 12 + swing), Vector2(45, 3 + swing), Color("#a7b2b8"), 3.0)
		canvas.draw_circle(Vector2(45, 3 + swing), 4.5, Color("#e76f51"))
	canvas.draw_set_transform(base_offset, 0.0, Vector2(base_scale, base_scale))

## Retrato low-poly de la Dra. Owen, supervisora científica (personaje ficticio).
static func owen(canvas: CanvasItem, rect: Rect2, time: float = 0.0, happy: bool = true) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) / 200.0
	canvas.draw_circle(c, 96 * s, Color("#8fd3c1"))
	canvas.draw_circle(c, 96 * s, Color("#2a9d8f"), false, 5.0 * s, true)
	var bob := sin(time * 1.6) * 1.5 * s
	var o := c + Vector2(0, 8 * s + bob)
	var k := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-78, 92), k.call(-52, 46), k.call(-14, 34), k.call(14, 34), k.call(52, 46), k.call(78, 92)]), Color("#264653"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-14, 34), k.call(0, 60), k.call(14, 34)]), Color("#fffaf0"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-52, 46), k.call(-14, 34), k.call(-30, 92), k.call(-78, 92)]), Color("#2f5564"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-46, -40), k.call(-30, -74), k.call(8, -84), k.call(42, -66), k.call(52, -30), k.call(50, 22), k.call(34, 2), k.call(-34, 2), k.call(-50, 24)]), Color("#dfe6ea"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(8, -84), k.call(42, -66), k.call(52, -30), k.call(50, 22), k.call(34, 2), k.call(20, -50)]), Color("#bcc8cf"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-12, 22), k.call(12, 22), k.call(10, 40), k.call(-10, 40)]), Color("#d99c79"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-32, -44), k.call(-8, -56), k.call(26, -50), k.call(36, -22), k.call(30, 8), k.call(8, 28), k.call(-10, 28), k.call(-30, 8), k.call(-36, -20)]), Color("#eab893"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(26, -50), k.call(36, -22), k.call(30, 8), k.call(8, 28), k.call(12, -14)]), Color("#d99c79"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-32, -44), k.call(-8, -56), k.call(26, -50), k.call(4, -36), k.call(-36, -20)]), Color("#f3c9a8"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-36, -46), k.call(-8, -62), k.call(30, -54), k.call(8, -42), k.call(-20, -38), k.call(-40, -18)]), Color("#eef2f4"))
	for x in [-16.0, 16.0]:
		canvas.draw_rect(Rect2(k.call(x - 11, -22), Vector2(22, 15) * s), Color("#264653"), false, 2.5 * s)
		canvas.draw_circle(k.call(x, -14), 2.6 * s, Color("#264653"))
	canvas.draw_line(k.call(-5, -15), k.call(5, -15), Color("#264653"), 2.5 * s)
	if happy: canvas.draw_arc(k.call(0, 4), 9 * s, 0.25, PI - 0.25, 10, Color("#a8573f"), 2.5 * s, true)
	else: canvas.draw_line(k.call(-7, 10), k.call(7, 10), Color("#a8573f"), 2.5 * s)
	canvas.draw_arc(k.call(2, -38), 46 * s, PI + 0.35, TAU - 0.35, 16, Color("#e76f51"), 5.0 * s, true)
	canvas.draw_rect(Rect2(k.call(-48, -30), Vector2(12, 22) * s), Color("#e76f51"))
	canvas.draw_line(k.call(-42, -8), k.call(-22, 12), Color("#264653"), 2.5 * s)
	canvas.draw_circle(k.call(-22, 12), 3.5 * s, Color("#264653"))

static func dust_devil(canvas: CanvasItem, pos: Vector2, time: float, radius: float) -> void:
	for i in range(5):
		var k := float(i) / 4.0
		var wobble := Vector2(sin(time * 5.0 + i * 1.3) * radius * 0.18, -k * radius * 1.5)
		var points := blob(pos + wobble, radius * (0.45 + k * 0.5), radius * (0.2 + k * 0.16), i + int(time * 6.0) % 3, 7, 0.2)
		canvas.draw_colored_polygon(points, Color(0.96, 0.83, 0.66, 0.34 - k * 0.04))

static func orbiter(canvas: CanvasItem, pos: Vector2, scale: float = 1.0) -> void:
	canvas.draw_rect(Rect2(pos - Vector2(6, 5) * scale, Vector2(12, 10) * scale), Color("#fffaf0"))
	canvas.draw_rect(Rect2(pos + Vector2(-22, -4) * scale, Vector2(14, 8) * scale), Color("#3f86bd"))
	canvas.draw_rect(Rect2(pos + Vector2(8, -4) * scale, Vector2(14, 8) * scale), Color("#3f86bd"))
	canvas.draw_circle(pos + Vector2(0, 8) * scale, 3.0 * scale, Color("#e9c46a"))
