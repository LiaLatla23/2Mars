class_name Art
## Arte low-poly dibujado por código: facetas planas, luz desde arriba a la izquierda.
## Todo el arte del juego es vectorial y original (salvo el logotipo 2MARS del equipo);
## no usa imágenes ni emblemas oficiales.

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

## Rover visto desde arriba. El dibujo refleja las piezas REALMENTE instaladas en el diseño.
## base_offset/base_scale: transformación de cámara ya activa en el lienzo (se restaura al terminar).
static func rover(canvas: CanvasItem, pos: Vector2, heading: float, build: Dictionary, scale: float = 1.0, time: float = 0.0, lamp: bool = false, base_offset: Vector2 = Vector2.ZERO, base_scale: float = 1.0) -> void:
	var parts: Array = Data.installed(build)
	var unit := Vector2(scale, scale) * base_scale
	var chassis := String(build.get("chassis", "chassis_std"))
	var half_l: float = {"chassis_light": 24.0, "chassis_std": 27.0, "chassis_reinf": 30.0}.get(chassis, 27.0)
	var half_w: float = {"chassis_light": 12.0, "chassis_std": 14.0, "chassis_reinf": 16.0}.get(chassis, 14.0)
	canvas.draw_set_transform(base_offset + (pos + Vector2(7, 9) * scale) * base_scale, heading, unit)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-half_l - 7, -half_w - 10), Vector2(half_l + 7, -half_w - 10), Vector2(half_l + 11, 0), Vector2(half_l + 7, half_w + 10), Vector2(-half_l - 7, half_w + 10)]), Color(0.1, 0.05, 0.05, 0.22))
	canvas.draw_set_transform(base_offset + pos * base_scale, heading, unit)
	if lamp: canvas.draw_colored_polygon(PackedVector2Array([Vector2(26, -6), Vector2(150, -58), Vector2(150, 58), Vector2(26, 6)]), Color(1.0, 0.95, 0.75, 0.13))
	# Movilidad: ruedas y suspensión
	var wheels := String(build.get("wheels", "wheels_std"))
	var wheel_w: float = {"wheels_light": 6.0, "wheels_std": 8.0, "wheels_reinf": 11.0}.get(wheels, 8.0)
	var rocker := "rocker" in parts
	var track := half_w + 6.0
	for side in [-1.0, 1.0]:
		if rocker:
			canvas.draw_line(Vector2(-half_l + 4, side * track), Vector2(0, side * (track - 5)), Color("#c9ced6"), 3.0)
			canvas.draw_line(Vector2(0, side * (track - 5)), Vector2(half_l - 4, side * track), Color("#c9ced6"), 3.0)
			canvas.draw_circle(Vector2(0, side * (track - 5)), 3.0, Color("#FFAD45"))
		for x in [-half_l + 4.0, 0.0, half_l - 4.0]:
			canvas.draw_line(Vector2(x * 0.6, side * 8), Vector2(x, side * (track - 1)), Color("#7d8b93"), 3.0)
			var wheel := Rect2(x - 8, side * track - wheel_w * 0.5, 16, wheel_w)
			canvas.draw_rect(wheel, Color("#23262d"))
			var treads := 3 if wheels == "wheels_reinf" else 2
			for i in range(treads): canvas.draw_rect(Rect2(wheel.position + Vector2(2 + i * (12.0 / treads), 1), Vector2(2.5, wheel.size.y - 2)), Color("#59656c") if wheels != "wheels_light" else Color("#8d99a1"))
	# Estructura: chasis y cubierta
	var body := Color("#f5efdf") if chassis != "chassis_reinf" else Color("#e6dcc4")
	canvas.draw_rect(Rect2(-half_l, -half_w + 3, half_l * 2, half_w * 2), Color("#b9b3a4"))
	canvas.draw_rect(Rect2(-half_l, -half_w, half_l * 2, half_w * 2 - 2), body)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-half_l, -half_w), Vector2(4, -half_w), Vector2(-half_l, 6)]), Color("#fffaf0"))
	if chassis == "chassis_reinf": canvas.draw_rect(Rect2(-half_l, -half_w, half_l * 2, half_w * 2 - 2), Color("#AA5D40"), false, 2.0)
	if chassis == "chassis_light":
		for i in range(3): canvas.draw_circle(Vector2(-half_l + 10 + i * 14, half_w - 6), 2.2, Color("#cfc8b6"))
	if String(build.get("deck", "")) == "deck_ext":
		canvas.draw_rect(Rect2(-half_l - 9, -half_w + 2, 10, half_w * 2 - 6), Color("#d9cfb6"))
		canvas.draw_rect(Rect2(-half_l - 9, -half_w + 2, 10, 3), Color("#fffaf0"))
	# Energía
	if String(build.get("power", "solar")) == "solar":
		canvas.draw_rect(Rect2(-half_l - 3, -half_w + 1, 26, half_w * 2 - 4), Color("#2f5f8f"))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-half_l - 3, -half_w + 1), Vector2(-half_l + 23, -half_w + 1), Vector2(-half_l - 3, 4)]), Color("#3f7fb5"))
		for i in range(1, 3): canvas.draw_line(Vector2(-half_l - 3 + i * 8.6, -half_w + 1), Vector2(-half_l - 3 + i * 8.6, half_w - 3), Color("#1f3f66"), 1.0)
		canvas.draw_line(Vector2(-half_l - 3, -1), Vector2(-half_l + 23, -1), Color("#1f3f66"), 1.0)
	else:
		canvas.draw_rect(Rect2(-half_l - 15, -7, 17, 14), Color("#3b4047"))
		for i in range(4): canvas.draw_line(Vector2(-half_l - 13 + i * 4.5, -10), Vector2(-half_l - 13 + i * 4.5, 10), Color("#565d66"), 2.0)
		canvas.draw_circle(Vector2(-half_l, 0), 3.0, Color("#FFAD45"))
	if "battery_ext" in parts:
		canvas.draw_rect(Rect2(-8, half_w - 9, 16, 7), Color("#293746"))
		canvas.draw_rect(Rect2(-6, half_w - 8, 4, 5), Color("#FFAD45"))
		canvas.draw_rect(Rect2(0, half_w - 8, 4, 5), Color("#FFAD45"))
	# Computación
	if "storage" in parts: canvas.draw_rect(Rect2(-18, half_w - 9, 8, 7), Color("#91C6BB"))
	if "navsens" in parts:
		for side in [-1.0, 1.0]: canvas.draw_circle(Vector2(half_l - 3, side * (half_w - 4)), 2.4, Color("#293746"))
	if "autonav" in parts: canvas.draw_circle(Vector2(half_l - 10, 0), 2.6, Color("#91C6BB"))
	# Comunicaciones
	if "hga" in parts:
		var dish := PackedVector2Array()
		for i in range(6): dish.append(Vector2(-2, -4) + Vector2.from_angle(TAU * i / 6.0) * 9.0)
		canvas.draw_colored_polygon(dish, Color("#FFAD45"))
		canvas.draw_colored_polygon(PackedVector2Array([dish[3], dish[4], dish[5], Vector2(-2, -4)]), Color("#ffc97a"))
		canvas.draw_circle(Vector2(-2, -4), 2.0, Color("#191922"))
	if "uhf" in parts:
		canvas.draw_line(Vector2(-12, -half_w + 5), Vector2(-12, -half_w - 6), Color("#7d8b93"), 2.5)
		canvas.draw_circle(Vector2(-12, -half_w - 6), 2.4, Color("#293746"))
	# Ciencia
	if "moxie" in parts: canvas.draw_rect(Rect2(6, 1, 11, 9), Color("#d9a441"))
	if "meda" in parts:
		canvas.draw_line(Vector2(17, -9), Vector2(8, -half_w - 10), Color("#7d8b93"), 1.5)
		canvas.draw_circle(Vector2(8, -half_w - 10), 2.0, Color("#3d8b82"))
	if "rimfax" in parts: canvas.draw_colored_polygon(PackedVector2Array([Vector2(-half_l, half_w - 6), Vector2(-half_l - 9, half_w), Vector2(-half_l, half_w)]), Color("#3d8b82"))
	if "mastcam" in parts or "supercam" in parts:
		canvas.draw_circle(Vector2(18, -8), 4.0, Color("#59656c"))
		canvas.draw_rect(Rect2(19, -14, 12, 11), Color("#fffaf0"))
		canvas.draw_rect(Rect2(19, -5, 12, 2), Color("#b9b3a4"))
		if "supercam" in parts: canvas.draw_circle(Vector2(27, -9), 3.2, Color("#293746"))
		if "mastcam" in parts:
			canvas.draw_circle(Vector2(22, -9), 1.6, Color("#191922"))
			if not "supercam" in parts: canvas.draw_circle(Vector2(28, -9), 1.6, Color("#191922"))
	# Muestreo
	var arm := String(build.get("arm", ""))
	if arm != "":
		var reach := 1.0 if arm == "arm_std" else 1.45
		var swing := sin(time * 2.0) * 1.5
		var elbow := Vector2(half_l - 1 + 12 * reach, 12 + swing)
		var hand := Vector2(half_l - 1 + 19 * reach, 3 + swing)
		canvas.draw_line(Vector2(half_l - 1, 7), elbow, Color("#8b98a0"), 4.0)
		canvas.draw_line(elbow, hand, Color("#a7b2b8"), 3.0)
		canvas.draw_circle(hand, 4.5, Color("#AA5D40") if "drill" in parts else Color("#c9ced6"))
		if "pixl" in parts: canvas.draw_circle(hand + Vector2(-3, -4), 2.0, Color("#FFAD45"))
		if "sherloc" in parts: canvas.draw_circle(hand + Vector2(3, -4), 2.0, Color("#91C6BB"))
		if "drill" in parts: canvas.draw_line(hand, hand + Vector2(6, 0), Color("#59656c"), 2.0)
	if "regolith" in parts: canvas.draw_colored_polygon(PackedVector2Array([Vector2(half_l - 2, -half_w + 2), Vector2(half_l + 8, -half_w - 1), Vector2(half_l + 8, -half_w + 6)]), Color("#b98a5a"))
	canvas.draw_set_transform(base_offset, 0.0, Vector2(base_scale, base_scale))

## Fondo espacial de menús (referencias 1-9): cielo nocturno, Marte, luna, terreno low-poly y base.
static func space(canvas: CanvasItem, size: Vector2, time: float = 0.0, ground: bool = true, dim: float = 0.0) -> void:
	gradient(canvas, Rect2(Vector2.ZERO, size), Color("#191922"), Color("#293746"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in range(110):
		var at := Vector2(rng.randf() * size.x, rng.randf() * size.y * 0.8)
		var twinkle := 0.45 + 0.4 * sin(time * (0.6 + rng.randf() * 1.6) + i)
		var r := rng.randf_range(0.8, 2.2)
		canvas.draw_circle(at, r, Color(1.0, 0.96, 0.84, twinkle if not Game.reduced_motion else 0.7))
		if i % 17 == 0:
			canvas.draw_line(at - Vector2(r * 4, 0), at + Vector2(r * 4, 0), Color(1, 0.96, 0.84, twinkle * 0.6), 1.0)
			canvas.draw_line(at - Vector2(0, r * 4), at + Vector2(0, r * 4), Color(1, 0.96, 0.84, twinkle * 0.6), 1.0)
	planet(canvas, Vector2(size.x * 0.83, size.y * 0.3), size.y * 0.42, time * 0.05, Color("#c9603f"), 7)
	planet(canvas, Vector2(size.x * 0.12, size.y * 0.15), size.y * 0.035, time * 0.1, Color("#9aa0b4"), 3)
	if ground:
		ridge(canvas, 0, size.x, size.y * 0.74, size.y * 0.16, 31, Color("#7a3f3a"), 8)
		ridge(canvas, 0, size.x, size.y * 0.8, size.y * 0.1, 47, Color("#93492f"), 6)
		canvas.draw_rect(Rect2(0, size.y * 0.8, size.x, size.y * 0.2), Color("#a8552f"))
		var dune := PackedVector2Array([Vector2(0, size.y * 0.9), Vector2(size.x * 0.35, size.y * 0.84), Vector2(size.x * 0.7, size.y * 0.9), Vector2(size.x, size.y * 0.85), Vector2(size.x, size.y), Vector2(0, size.y)])
		canvas.draw_colored_polygon(dune, Color("#c66a3a"))
		# Base con domo y antena, como en las referencias
		var base := Vector2(size.x * 0.84, size.y * 0.8)
		canvas.draw_rect(Rect2(base + Vector2(-70, -30), Vector2(64, 30)), Color("#d9cfb6"))
		canvas.draw_rect(Rect2(base + Vector2(-70, -30), Vector2(64, 6)), Color("#fffaf0"))
		for i in range(3): canvas.draw_rect(Rect2(base + Vector2(-62 + i * 20, -18), Vector2(12, 8)), Color(1.0, 0.75, 0.35, 0.8 + 0.2 * sin(time * 2.0 + i)))
		var dome := PackedVector2Array()
		for i in range(9): dome.append(base + Vector2(40, 0) + Vector2(cos(PI + PI * i / 8.0) * 46, sin(PI + PI * i / 8.0) * 40))
		canvas.draw_colored_polygon(dome, Color("#e9c98a"))
		for i in range(1, 8): canvas.draw_line(base + Vector2(40, 0), dome[i], Color("#AA5D40"), 1.5)
		canvas.draw_polyline(dome, Color("#AA5D40"), 2.0)
		var dish := Vector2(size.x * 0.07, size.y * 0.76)
		canvas.draw_line(dish, dish + Vector2(0, 44), Color("#8b98a0"), 4.0)
		canvas.draw_colored_polygon(PackedVector2Array([dish + Vector2(-30, -8), dish + Vector2(24, -30), dish + Vector2(30, -14), dish + Vector2(-12, 14)]), Color("#e6dcc4"))
		canvas.draw_line(dish + Vector2(4, -10), dish + Vector2(26, -44), Color("#8b98a0"), 2.0)
		canvas.draw_circle(dish + Vector2(26, -44), 3.0, Color(1.0, 0.4, 0.3, 0.6 + 0.4 * sin(time * 3.0)))
		rock(canvas, Vector2(size.x * 0.2, size.y * 0.93), 44, 5, Color("#7a3524"))
		rock(canvas, Vector2(size.x * 0.62, size.y * 0.95), 30, 8, Color("#8a3d29"))
	if dim > 0.0: canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.07, 0.1, dim))

## Planeta facetado con una franja de sombra; spin desplaza las facetas (rotación lenta).
static func planet(canvas: CanvasItem, center: Vector2, radius: float, spin: float, base: Color, bands: int = 6) -> void:
	canvas.draw_circle(center, radius * 1.04, Color(base, 0.18))
	canvas.draw_circle(center, radius, base)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(radius * 7.0) + bands
	for i in range(bands * 4):
		var lon := rng.randf() * TAU + (spin if not Game.reduced_motion else 0.0)
		var lat := rng.randf_range(-1.1, 1.1)
		var x := cos(lat) * sin(lon)
		if cos(lat) * cos(lon) < 0.0: continue
		var at := center + Vector2(x, sin(lat)) * radius * 0.92
		var r := radius * rng.randf_range(0.08, 0.22) * maxf(0.3, cos(lat) * cos(lon))
		canvas.draw_colored_polygon(blob(at, r, r * 0.7, i + 3, 6, 0.25), shade(base, rng.randf_range(-0.22, 0.14)))
	# Sombra del lado nocturno: media luna abajo a la derecha
	var night := PackedVector2Array()
	for i in range(17):
		var a := -PI * 0.5 + PI * i / 16.0
		night.append(center + (Vector2(cos(a), sin(a)) * radius).rotated(0.6))
	for i in range(17):
		var b := PI * 0.5 - PI * i / 16.0
		night.append(center + (Vector2(cos(b) * 0.42, sin(b)) * radius).rotated(0.6))
	canvas.draw_colored_polygon(night, Color(0.05, 0.04, 0.1, 0.34))

## Taller de la base terrestre (referencias 10-16): hangar con ventanales y pórtico.
static func workshop(canvas: CanvasItem, size: Vector2, time: float = 0.0) -> void:
	gradient(canvas, Rect2(Vector2.ZERO, size), Color("#3a4c63"), Color("#293746"))
	# Ventanales con cielo de la Tierra
	for i in range(5):
		var x := 40.0 + i * (size.x - 80.0) / 5.0
		var pane := Rect2(x, 40, (size.x - 80.0) / 5.0 - 14.0, size.y * 0.42)
		gradient(canvas, pane, Color("#8fc3e0"), Color("#f5db98"))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(pane.position.x, pane.end.y), Vector2(pane.position.x + pane.size.x * 0.35, pane.end.y - 60 - i * 6), Vector2(pane.position.x + pane.size.x * 0.7, pane.end.y - 26), Vector2(pane.end.x, pane.end.y - 50), pane.end]), Color("#5f8f84"))
		canvas.draw_rect(pane, Color("#191922"), false, 4.0)
		canvas.draw_line(Vector2(pane.position.x, pane.position.y + pane.size.y * 0.5), Vector2(pane.end.x, pane.position.y + pane.size.y * 0.5), Color("#191922"), 3.0)
	# Pórtico grúa
	canvas.draw_rect(Rect2(0, 18, size.x, 18), Color("#FFAD45"))
	for i in range(int(size.x / 40.0) + 1): canvas.draw_line(Vector2(i * 40.0, 18), Vector2(i * 40.0 + 20, 36), Color("#191922"), 3.0)
	var hook := size.x * 0.5 + sin(time * 0.3) * 120.0
	canvas.draw_line(Vector2(hook, 36), Vector2(hook, 86), Color("#191922"), 3.0)
	canvas.draw_rect(Rect2(hook - 16, 80, 32, 14), Color("#AA5D40"))
	# Suelo con marcas
	gradient(canvas, Rect2(0, size.y * 0.5, size.x, size.y * 0.5), Color("#4a5a70"), Color("#293746"))
	for i in range(9): canvas.draw_line(Vector2(size.x * 0.5 + (i - 4) * 70.0, size.y * 0.5), Vector2(size.x * 0.5 + (i - 4) * 240.0, size.y), Color(1, 1, 1, 0.05), 2.0)
	canvas.draw_rect(Rect2(0, size.y * 0.5 - 4, size.x, 8), Color("#191922"))

## Iconos vectoriales de los seis factores, categorías y navegación (mismo trazo y sombra).
static func icon(canvas: CanvasItem, kind: String, c: Vector2, s: float, color: Color = Color("#191922")) -> void:
	var w := maxf(2.0, s * 0.12)
	match kind:
		"time":
			canvas.draw_arc(c, s * 0.42, 0, TAU, 24, color, w, true)
			canvas.draw_line(c, c + Vector2(0, -s * 0.28), color, w)
			canvas.draw_line(c, c + Vector2(s * 0.2, s * 0.08), color, w)
		"data":
			for i in range(3): canvas.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.36 + i * s * 0.27), Vector2(s * 0.72, s * 0.18)), color)
		"budget":
			canvas.draw_circle(c, s * 0.42, color)
			canvas.draw_circle(c, s * 0.26, Color(color.inverted(), 0.35))
			canvas.draw_line(c + Vector2(0, -s * 0.2), c + Vector2(0, s * 0.2), Color("#fff5dc"), w)
		"mass":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.26, -s * 0.12), c + Vector2(s * 0.26, -s * 0.12), c + Vector2(s * 0.42, s * 0.4), c + Vector2(-s * 0.42, s * 0.4)]), color)
			canvas.draw_arc(c + Vector2(0, -s * 0.2), s * 0.14, 0, TAU, 12, color, w, true)
		"energy":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.1, -s * 0.46), c + Vector2(-s * 0.3, s * 0.06), c + Vector2(-s * 0.02, s * 0.06), c + Vector2(-s * 0.12, s * 0.46), c + Vector2(s * 0.3, -s * 0.1), c + Vector2(s * 0.02, -s * 0.1)]), color)
		"comms":
			canvas.draw_circle(c + Vector2(-s * 0.2, s * 0.2), s * 0.1, color)
			for i in range(1, 4): canvas.draw_arc(c + Vector2(-s * 0.2, s * 0.2), s * 0.2 * i, -PI * 0.5, 0, 10, color, w, true)
		"science":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, -s * 0.44), c + Vector2(s * 0.1, -s * 0.44), c + Vector2(s * 0.1, -s * 0.1), c + Vector2(s * 0.38, s * 0.4), c + Vector2(-s * 0.38, s * 0.4), c + Vector2(-s * 0.1, -s * 0.1)]), color)
		"sampling":
			canvas.draw_rect(Rect2(c + Vector2(-s * 0.12, -s * 0.44), Vector2(s * 0.24, s * 0.6)), color)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.12, s * 0.16), c + Vector2(s * 0.12, s * 0.16), c + Vector2(0, s * 0.46)]), color)
		"mobility":
			canvas.draw_arc(c, s * 0.38, 0, TAU, 20, color, w * 1.6, true)
			canvas.draw_circle(c, s * 0.1, color)
			for i in range(4): canvas.draw_line(c, c + Vector2.from_angle(TAU * i / 4.0 + 0.4) * s * 0.36, color, w * 0.8)
		"structure":
			canvas.draw_rect(Rect2(c - Vector2(s * 0.4, s * 0.26), Vector2(s * 0.8, s * 0.52)), color, false, w)
			canvas.draw_line(c - Vector2(s * 0.4, s * 0.26), c + Vector2(s * 0.4, s * 0.26), color, w)
			canvas.draw_line(c + Vector2(-s * 0.4, s * 0.26), c + Vector2(s * 0.4, -s * 0.26), color, w)
		"launch":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.48), c + Vector2(s * 0.18, -s * 0.1), c + Vector2(s * 0.18, s * 0.26), c + Vector2(-s * 0.18, s * 0.26), c + Vector2(-s * 0.18, -s * 0.1)]), color)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.18, s * 0.1), c + Vector2(-s * 0.36, s * 0.36), c + Vector2(-s * 0.18, s * 0.26)]), color)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.18, s * 0.1), c + Vector2(s * 0.36, s * 0.36), c + Vector2(s * 0.18, s * 0.26)]), color)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, s * 0.3), c + Vector2(s * 0.1, s * 0.3), c + Vector2(0, s * 0.5)]), Color("#FFAD45"))
		"mars":
			canvas.draw_circle(c, s * 0.42, color)
			canvas.draw_circle(c + Vector2(-s * 0.12, -s * 0.1), s * 0.1, Color(1, 1, 1, 0.25))
			canvas.draw_circle(c + Vector2(s * 0.14, s * 0.12), s * 0.07, Color(0, 0, 0, 0.2))
		"lock":
			canvas.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.04), Vector2(s * 0.6, s * 0.44)), color)
			canvas.draw_arc(c + Vector2(0, -s * 0.06), s * 0.2, PI, TAU, 12, color, w, true)
		"check":
			canvas.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.34, 0), c + Vector2(-s * 0.08, s * 0.26), c + Vector2(s * 0.36, -s * 0.28)]), color, w * 1.4)
		"warn":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.44), c + Vector2(s * 0.44, s * 0.38), c + Vector2(-s * 0.44, s * 0.38)]), color)
			canvas.draw_line(c + Vector2(0, -s * 0.16), c + Vector2(0, s * 0.12), Color("#fff5dc"), w)
			canvas.draw_circle(c + Vector2(0, s * 0.25), w * 0.6, Color("#fff5dc"))
		"trophy":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.4), c + Vector2(s * 0.3, -s * 0.4), c + Vector2(s * 0.16, s * 0.08), c + Vector2(-s * 0.16, s * 0.08)]), color)
			canvas.draw_rect(Rect2(c + Vector2(-s * 0.05, s * 0.08), Vector2(s * 0.1, s * 0.2)), color)
			canvas.draw_rect(Rect2(c + Vector2(-s * 0.24, s * 0.28), Vector2(s * 0.48, s * 0.12)), color)

## Emblemas de equipo de lanzamiento (6 opciones originales).
const EMBLEMS := 6
static func emblem(canvas: CanvasItem, index: int, c: Vector2, r: float) -> void:
	var tones := [Color("#FFAD45"), Color("#91C6BB"), Color("#AA5D40"), Color("#F5DB98"), Color("#6f8fc4"), Color("#d1495b")]
	var tone: Color = tones[index % tones.size()]
	var shield := PackedVector2Array()
	for i in range(8): shield.append(c + Vector2.from_angle(TAU * i / 8.0 + PI / 8.0) * r)
	canvas.draw_colored_polygon(shield, Color("#191922"))
	var inner := PackedVector2Array()
	for i in range(8): inner.append(c + Vector2.from_angle(TAU * i / 8.0 + PI / 8.0) * r * 0.86)
	canvas.draw_colored_polygon(inner, tone)
	canvas.draw_colored_polygon(PackedVector2Array([inner[5], inner[6], inner[7], c]), tone.lightened(0.18))
	var kinds := ["launch", "mars", "mobility", "science", "comms", "energy"]
	icon(canvas, kinds[index % kinds.size()], c, r * 1.1, Color("#191922"))

## Cohete para la secuencia de lanzamiento (arquitectura genérica del juego).
static func rocket(canvas: CanvasItem, base: Vector2, scale: float, flame: float, time: float) -> void:
	var k := func(x: float, y: float) -> Vector2: return base + Vector2(x, y) * scale
	if flame > 0.0:
		for i in range(3):
			var f := flame * (1.0 - i * 0.22) * (0.9 + 0.1 * sin(time * 30.0 + i))
			canvas.draw_colored_polygon(PackedVector2Array([k.call(-16 + i * 5, 0), k.call(16 - i * 5, 0), k.call(0, 90 * f)]), [Color("#AA5D40"), Color("#FFAD45"), Color("#fff5dc")][i])
	for side in [-1.0, 1.0]:
		canvas.draw_colored_polygon(PackedVector2Array([k.call(side * 20, -150), k.call(side * 34, -130), k.call(side * 34, -6), k.call(side * 20, -6)]), Color("#e6dcc4"))
		canvas.draw_colored_polygon(PackedVector2Array([k.call(side * 20, -150), k.call(side * 27, -172), k.call(side * 34, -130)]), Color("#FFAD45"))
	canvas.draw_rect(Rect2(k.call(-20, -250), Vector2(40, 250) * scale), Color("#fffaf0"))
	canvas.draw_rect(Rect2(k.call(6, -250), Vector2(14, 250) * scale), Color("#d9cfb6"))
	canvas.draw_rect(Rect2(k.call(-20, -160), Vector2(40, 14) * scale), Color("#FFAD45"))
	canvas.draw_rect(Rect2(k.call(-20, -80), Vector2(40, 8) * scale), Color("#293746"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-20, -250), k.call(-24, -262), k.call(-14, -310), k.call(0, -330), k.call(14, -310), k.call(24, -262), k.call(20, -250)]), Color("#fffaf0"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(0, -330), k.call(14, -310), k.call(24, -262), k.call(20, -250), k.call(6, -250)]), Color("#d9cfb6"))
	canvas.draw_rect(Rect2(k.call(-26, -10), Vector2(52, 10) * scale), Color("#293746"))

## Cápsula de entrada con escudo térmico (modelo simplificado del juego).
static func capsule(canvas: CanvasItem, c: Vector2, scale: float, heat: float, time: float) -> void:
	var k := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * scale
	if heat > 0.0:
		for i in range(4):
			var grow := 1.0 + i * 0.35 + 0.08 * sin(time * 22.0 + i)
			canvas.draw_colored_polygon(PackedVector2Array([k.call(-46 * grow, 6), k.call(0, 30 + 26 * grow), k.call(46 * grow, 6), k.call(30 * grow, -70 * grow), k.call(-30 * grow, -70 * grow)]), Color(1.0, 0.62 - i * 0.1, 0.25, heat * (0.34 - i * 0.07)))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-44, 0), k.call(-26, -34), k.call(26, -34), k.call(44, 0)]), Color("#fffaf0"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(0, -34), k.call(26, -34), k.call(44, 0), k.call(0, 0)]), Color("#d9cfb6"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-44, 0), k.call(44, 0), k.call(26, 16), k.call(-26, 16)]), Color("#AA5D40").lerp(Color("#FFAD45"), heat))

static func parachute(canvas: CanvasItem, c: Vector2, scale: float, open: float) -> void:
	var top := c + Vector2(0, -170 * scale)
	var canopy := PackedVector2Array()
	for i in range(11): canopy.append(top + Vector2(cos(PI + PI * i / 10.0) * 90 * open, sin(PI + PI * i / 10.0) * 60) * scale)
	for i in range(10):
		canvas.draw_colored_polygon(PackedVector2Array([canopy[i], canopy[i + 1], top + Vector2((i - 4.5) * 16 * open, 6) * scale]), Color("#FFAD45") if i % 2 == 0 else Color("#fff5dc"))
		canvas.draw_line(canopy[i], c + Vector2(0, -34 * scale), Color(1, 1, 1, 0.45), 1.0)
	canvas.draw_line(canopy[10], c + Vector2(0, -34 * scale), Color(1, 1, 1, 0.45), 1.0)

## Insignia de nota (S-D) para el informe.
static func badge(canvas: CanvasItem, c: Vector2, r: float, grade: String, time: float) -> void:
	var tone: Color = {"S": Color("#FFAD45"), "A": Color("#4fae6a"), "B": Color("#91C6BB"), "C": Color("#e58f47"), "D": Color("#d1495b")}.get(grade, Color("#6f7f8c"))
	var points := PackedVector2Array()
	var spin := time * 0.2 if not Game.reduced_motion else 0.0
	for i in range(8): points.append(c + Vector2.from_angle(TAU * i / 8.0 + spin) * r)
	var rim := PackedVector2Array()
	for i in range(8): rim.append(c + Vector2.from_angle(TAU * i / 8.0 + spin) * (r + 6.0))
	canvas.draw_colored_polygon(rim, Color("#191922"))
	canvas.draw_colored_polygon(points, tone)
	canvas.draw_colored_polygon(PackedVector2Array([points[0], points[1], points[2], c]), tone.lightened(0.2))
	canvas.draw_string_outline(UIK.title_font, c + Vector2(-r, r * 0.42), grade, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.2), 8, Color("#191922"))
	canvas.draw_string(UIK.title_font, c + Vector2(-r, r * 0.42), grade, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.2), Color("#fff5dc"))

## Retrato low-poly de la Dra. Owen, supervisora científica (personaje ficticio).
static func owen(canvas: CanvasItem, rect: Rect2, time: float = 0.0, happy: bool = true) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) / 200.0
	canvas.draw_circle(c, 96 * s, Color("#91C6BB"))
	canvas.draw_circle(c, 96 * s, Color("#3d8b82"), false, 5.0 * s, true)
	var bob := sin(time * 1.6) * 1.5 * s
	var o := c + Vector2(0, 8 * s + bob)
	var k := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-78, 92), k.call(-52, 46), k.call(-14, 34), k.call(14, 34), k.call(52, 46), k.call(78, 92)]), Color("#293746"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-14, 34), k.call(0, 60), k.call(14, 34)]), Color("#fffaf0"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-52, 46), k.call(-14, 34), k.call(-30, 92), k.call(-78, 92)]), Color("#34465a"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-46, -40), k.call(-30, -74), k.call(8, -84), k.call(42, -66), k.call(52, -30), k.call(50, 22), k.call(34, 2), k.call(-34, 2), k.call(-50, 24)]), Color("#dfe6ea"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(8, -84), k.call(42, -66), k.call(52, -30), k.call(50, 22), k.call(34, 2), k.call(20, -50)]), Color("#bcc8cf"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-12, 22), k.call(12, 22), k.call(10, 40), k.call(-10, 40)]), Color("#d99c79"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-32, -44), k.call(-8, -56), k.call(26, -50), k.call(36, -22), k.call(30, 8), k.call(8, 28), k.call(-10, 28), k.call(-30, 8), k.call(-36, -20)]), Color("#eab893"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(26, -50), k.call(36, -22), k.call(30, 8), k.call(8, 28), k.call(12, -14)]), Color("#d99c79"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-32, -44), k.call(-8, -56), k.call(26, -50), k.call(4, -36), k.call(-36, -20)]), Color("#f3c9a8"))
	canvas.draw_colored_polygon(PackedVector2Array([k.call(-36, -46), k.call(-8, -62), k.call(30, -54), k.call(8, -42), k.call(-20, -38), k.call(-40, -18)]), Color("#eef2f4"))
	for x in [-16.0, 16.0]:
		canvas.draw_rect(Rect2(k.call(x - 11, -22), Vector2(22, 15) * s), Color("#293746"), false, 2.5 * s)
		canvas.draw_circle(k.call(x, -14), 2.6 * s, Color("#293746"))
	canvas.draw_line(k.call(-5, -15), k.call(5, -15), Color("#293746"), 2.5 * s)
	if happy: canvas.draw_arc(k.call(0, 4), 9 * s, 0.25, PI - 0.25, 10, Color("#a8573f"), 2.5 * s, true)
	else: canvas.draw_line(k.call(-7, 10), k.call(7, 10), Color("#a8573f"), 2.5 * s)
	canvas.draw_arc(k.call(2, -38), 46 * s, PI + 0.35, TAU - 0.35, 16, Color("#FFAD45"), 5.0 * s, true)
	canvas.draw_rect(Rect2(k.call(-48, -30), Vector2(12, 22) * s), Color("#FFAD45"))
	canvas.draw_line(k.call(-42, -8), k.call(-22, 12), Color("#293746"), 2.5 * s)
	canvas.draw_circle(k.call(-22, 12), 3.5 * s, Color("#293746"))

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
