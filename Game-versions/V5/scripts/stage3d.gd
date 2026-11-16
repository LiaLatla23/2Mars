class_name Stage3D
extends Control
## Escenario 3D reutilizable de 2Mars (V4): taller con el rover sobre una plataforma, paisaje
## de Marte para menús y base, y visor de piezas. Dibuja en un SubViewport propio, a la
## resolución real de la ventana multiplicada por la calidad elegida en Ajustes.

var viewport: SubViewport
var view: TextureRect
var world: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var rover: Rover3D
var orbit := Vector3(0.75, 0.3, 6.6)      # giro, elevación, distancia
var goal := Vector3(0.75, 0.3, 6.6)
var focus := Vector3(0, 0.95, 0)
var zoom_range := Vector2(4.2, 9.0)
var interactive := false
var dragging := false
var spin := 0.0                           # giro automático (rad/s) cuando nadie arrastra
var parallax := 0.0                       # desplazamiento suave de cámara con el ratón
var sway := 0.0                           # vaivén lento de cámara
var clock := 0.0
var movers: Array = []
var marker: MeshInstance3D
var marker_local := Vector3.ZERO
var marker_on := false
var pixels := Vector2i.ZERO
var noise := FastNoiseLite.new()
var frozen := false                      # fondo decorativo: no se redibuja en todos los fotogramas
var every := 1
var tick_count := 0
var fixed_camera := false                # true: la pantalla coloca la cámara (globo de misiones)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

static func make(parent: Node, rect: Rect2, transparent: bool = false) -> Stage3D:
	var stage := Stage3D.new()
	stage.position = rect.position
	stage.size = rect.size
	parent.add_child(stage)
	stage.setup(transparent)
	return stage

func setup(transparent: bool) -> void:
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = transparent
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][Game.quality]
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	camera = Camera3D.new()
	camera.fov = 34.0
	camera.near = 0.1
	camera.far = 400.0
	world.add_child(camera)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#191922")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff1dc")
	env.ambient_light_energy = 0.32
	var holder := WorldEnvironment.new()
	holder.environment = env
	world.add_child(holder)
	sun = DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-48), deg_to_rad(-38), 0)
	sun.light_energy = 0.38
	sun.shadow_enabled = Game.quality > 0
	sun.directional_shadow_max_distance = 40.0
	world.add_child(sun)
	view = TextureRect.new()
	view.texture = viewport.get_texture()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	Geo3D.outline = Game.quality > 0
	noise.seed = 11
	noise.frequency = 0.07
	fit()

## Ajusta el tamaño de render a los píxeles reales que ocupa el control en la ventana.
func fit() -> void:
	var factor := 1.0
	if is_inside_tree(): factor = get_viewport().get_final_transform().get_scale().x
	var want := Vector2i((size * factor * Game.render_scale()).round()).clamp(Vector2i(64, 64), Vector2i(2560, 1440))
	if want != pixels:
		pixels = want
		viewport.size = want
		if frozen: viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

## Fondo decorativo: se redibuja cada N fotogramas (1 = todos). Sigue vivo y con movimiento;
## solo gasta menos. Lo usan los fondos de los menús según la calidad (Game.backdrop_step).
func throttle(step: int) -> void:
	every = maxi(1, step)
	frozen = every > 1
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE if frozen else SubViewport.UPDATE_ALWAYS

func enable_orbit(on: bool = true) -> void:
	interactive = on
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	if not interactive: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT: dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP: goal.z = maxf(zoom_range.x, goal.z - 0.5)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: goal.z = minf(zoom_range.y, goal.z + 0.5)
	elif event is InputEventMouseMotion and dragging:
		goal.x -= event.relative.x * 0.011
		goal.y = clampf(goal.y + event.relative.y * 0.007, 0.06, 1.15)

func nudge(yaw: float, zoom: float = 0.0) -> void:
	goal.x += yaw
	goal.z = clampf(goal.z + zoom, zoom_range.x, zoom_range.y)

func _process(delta: float) -> void:
	clock += delta
	fit()
	if frozen:
		tick_count += 1
		if tick_count % every == 0: viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	if spin != 0.0 and not dragging and not Game.reduced_motion: goal.x += spin * delta
	orbit = orbit.lerp(goal, 1.0 - exp(-delta * 11.0))
	if fixed_camera: return
	var look := focus
	var yaw := orbit.x
	var pitch := orbit.y
	if not Game.reduced_motion:
		if sway > 0.0: yaw += sin(clock * 0.21) * sway
		if parallax > 0.0 and is_visible_in_tree():
			var mouse := (get_local_mouse_position() / size - Vector2(0.5, 0.5)).clamp(Vector2(-0.6, -0.6), Vector2(0.6, 0.6))
			yaw -= mouse.x * parallax
			pitch = clampf(pitch + mouse.y * parallax * 0.5, 0.02, 1.2)
	camera.position = look + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * orbit.z
	camera.look_at(look, Vector3.UP)
	for mover in movers:
		var node: Node3D = mover.node
		if not is_instance_valid(node): continue
		match String(mover.kind):
			"spin": node.rotate_y(delta * float(mover.speed))
			"blink":
				var m: StandardMaterial3D = (node as MeshInstance3D).material_override
				m.emission_energy_multiplier = 2.4 if fmod(clock + float(mover.phase), 1.6) < 0.35 else 0.15
			"pulse": node.scale = Vector3.ONE * (1.0 + 0.04 * sin(clock * float(mover.speed)))
			"bob": node.position.y = float(mover.base) + sin(clock * float(mover.speed)) * float(mover.amount)
	if marker != null:
		marker.visible = marker_on and is_instance_valid(rover)
		if marker.visible:
			marker.position = rover.to_global(marker_local) + Vector3(0, 0.55 + sin(clock * 5.0) * 0.06, 0)
			marker.rotate_y(delta * 2.4)

# ------------------------------------------------------------------ rover
func show_rover(build: Dictionary, at: Vector3 = Vector3(0, 0.16, 0), facing: float = 0.5) -> Rover3D:
	if not is_instance_valid(rover):
		rover = Rover3D.new()
		rover.edge = 0.02 if Game.quality > 0 else 0.0
		world.add_child(rover)
	rover.position = at
	rover.rotation.y = facing
	rover.set_build(build)
	return rover

## Marca dónde va una pieza: resalta la malla y deja un rombo flotando encima.
func point_at(id: String) -> void:
	if not is_instance_valid(rover): return
	rover.highlight(id)
	marker_on = id != "" and rover.parts.has(id)
	if not marker_on: return
	marker_local = rover.anchor(id)
	if marker == null:
		marker = MeshInstance3D.new()
		var gem := CylinderMesh.new()
		gem.top_radius = 0.0
		gem.bottom_radius = 0.13
		gem.height = 0.26
		gem.radial_segments = 4
		marker.mesh = gem
		marker.material_override = Geo3D.mat(Color("#FFAD45"), 1.6)
		marker.rotation.x = PI
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(marker)

# ------------------------------------------------------------------ taller
func workshop(mars: bool = false) -> void:
	env.background_color = Color("#20283a")
	env.ambient_light_color = Color("#ffe9cf") if not mars else Color("#ffd2b0")
	env.ambient_light_energy = 0.34
	sun.light_color = Color("#fff3df")
	sun.rotation = Vector3(deg_to_rad(-52), deg_to_rad(28), 0)
	var floor_col := Color("#d8cbb4") if not mars else Color("#c9a183")
	Geo3D.box(world, Vector3(40, 0.2, 40), Vector3(0, -0.1, 0), floor_col, Vector3.ZERO, 0.0, 0.0)
	for i in range(-5, 6):
		Geo3D.box(world, Vector3(0.05, 0.01, 40), Vector3(i * 2.4, 0.005, 0), floor_col.darkened(0.12), Vector3.ZERO, 0.0, 0.0)
		Geo3D.box(world, Vector3(40, 0.01, 0.05), Vector3(0, 0.005, i * 2.4), floor_col.darkened(0.12), Vector3.ZERO, 0.0, 0.0)
	# plataforma del rover
	Geo3D.cyl(world, 2.7, 2.9, 0.16, Vector3(0, 0.08, 0), Color("#293746"), Vector3.ZERO, 28)
	Geo3D.cyl(world, 2.45, 2.45, 0.02, Vector3(0, 0.17, 0), Color("#34475c"), Vector3.ZERO, 28, 0.0, 0.0)
	var glow := Geo3D.ring(world, Vector3(0, 0.19, 0), 2.62, 0.12, Color("#91C6BB"))
	movers.append({"node": glow, "kind": "pulse", "speed": 2.0})
	for i in range(6):
		var a := TAU * i / 6.0
		Geo3D.box(world, Vector3(0.5, 0.03, 0.12), Vector3(cos(a) * 2.2, 0.185, sin(a) * 2.2), Color("#FFAD45"), Vector3(0, -a, 0), 0.6, 0.0)
	# pared del fondo con ventanales
	var wall := Color("#aeb9c6") if not mars else Color("#8b6d68")
	Geo3D.box(world, Vector3(40, 12, 0.4), Vector3(0, 6, -11), wall, Vector3.ZERO, 0.0, 0.0)
	for i in range(-2, 3):
		var x := i * 6.4
		if mars: Geo3D.sky(world, Vector3(x, 4.4, -10.75), Vector2(5.2, 6.0), Color("#3b2a5e"), Color("#f08a4b"), Color("#b4553f"))
		else: Geo3D.sky(world, Vector3(x, 4.4, -10.75), Vector2(5.2, 6.0), Color("#69b4ec"), Color("#fdeccb"), Color("#b9e0f7"))
		Geo3D.box(world, Vector3(0.22, 6.2, 0.2), Vector3(x - 2.7, 4.4, -10.7), Color("#293746"))
		Geo3D.box(world, Vector3(0.22, 6.2, 0.2), Vector3(x + 2.7, 4.4, -10.7), Color("#293746"))
		Geo3D.box(world, Vector3(5.6, 0.2, 0.2), Vector3(x, 4.4, -10.7), Color("#293746"))
		for hill in [[-0.9, 1.9, 9, Color("#6b8f7a") if not mars else Color("#8a4630")], [1.2, 1.5, 4, Color("#8fb39a") if not mars else Color("#a55a3c")]]:
			var mound := Geo3D.rock(world, Vector3(x + float(hill[0]), 1.4, -10.72), float(hill[1]), i + int(hill[2]), hill[3], 0.55, 0.0)
			mound.rotation.y = 0.0
			mound.scale.z = 0.05
	# puente grúa
	Geo3D.box(world, Vector3(26, 0.5, 0.6), Vector3(0, 8.6, -3.0), Color("#f2b632"))
	for x in [-12.6, 12.6]: Geo3D.box(world, Vector3(0.6, 9.0, 0.6), Vector3(x, 4.3, -3.0), Color("#f2b632"))
	var hook := Node3D.new()
	hook.position = Vector3(1.4, 7.4, -3.0)
	world.add_child(hook)
	Geo3D.box(hook, Vector3(1.1, 0.6, 0.9), Vector3(0, 0.6, 0), Color("#293746"))
	Geo3D.box(hook, Vector3(0.06, 1.6, 0.06), Vector3(0, -0.5, 0), Color("#b3bec9"), Vector3.ZERO, 0.0, 0.0)
	Geo3D.box(hook, Vector3(0.4, 0.2, 0.3), Vector3(0, -1.35, 0), Color("#f2b632"))
	movers.append({"node": hook, "kind": "bob", "base": 7.4, "speed": 0.5, "amount": 0.12})
	# estanterías, cajas y pantallas con planos
	var tones := [Color("#e8744a"), Color("#3f7fd0"), Color("#f2b632"), Color("#b3bec9"), Color("#91C6BB")]
	for side in [-1.0, 1.0]:
		for row in range(3):
			Geo3D.box(world, Vector3(4.6, 0.14, 1.3), Vector3(side * 9.2, 0.9 + row * 1.25, -6.0), Color("#5c6b7c"))
			for n in range(4):
				var w := 0.6 + 0.2 * ((n + row) % 3)
				Geo3D.box(world, Vector3(w, 0.7 + 0.15 * (n % 2), 0.9), Vector3(side * 9.2 - 1.7 + n * 1.12, 1.35 + row * 1.25 + 0.07 * (n % 2), -6.0), tones[(n + row * 2 + (0 if side < 0 else 2)) % tones.size()])
		for n in range(2): Geo3D.box(world, Vector3(0.16, 4.2, 0.16), Vector3(side * 9.2 - 2.2 + n * 4.4, 2.1, -6.0), Color("#293746"))
		var screen := Geo3D.box(world, Vector3(3.2, 1.9, 0.12), Vector3(side * 6.0, 3.1, -10.6), Color("#2a66c8"), Vector3.ZERO, 0.9)
		for n in range(4): Geo3D.box(screen, Vector3(2.6 - n * 0.5, 0.04, 0.02), Vector3(0, -0.6 + n * 0.36, 0.07), Color("#bfe1ff"), Vector3.ZERO, 1.2, 0.0)
		Geo3D.box(world, Vector3(1.5, 1.0, 1.1), Vector3(side * 7.4, 0.5, -3.6), tones[0 if side < 0 else 1])
		Geo3D.box(world, Vector3(1.0, 0.7, 0.9), Vector3(side * 7.2, 1.35, -3.6), tones[2])
		Geo3D.cyl(world, 0.5, 0.5, 1.1, Vector3(side * 5.6, 0.55, -5.0), Color("#3f7fd0"), Vector3.ZERO, 10)
	focus = Vector3(0, 1.05, 0)
	bake()

# ------------------------------------------------------------------ paisaje de Marte

## V5 · une el decorado estático (todo menos lo que se anima) para reducir llamadas de dibujo.
func bake() -> void:
	var live: Array = [camera]
	for mover in movers: live.append(mover.node)
	if is_instance_valid(rover): live.append(rover)
	Geo3D.merge(world, live)

func ground_height(p: Vector2) -> float:
	return noise.get_noise_2d(p.x, p.y) * 0.9 + noise.get_noise_2d(p.x * 3.1 + 40.0, p.y * 3.1) * 0.22 + maxf(0.0, -p.y - 14.0) * 0.12

func vista(base: bool = true) -> void:
	env.background_color = Color("#141733")
	env.ambient_light_color = Color("#ffb48a")
	env.ambient_light_energy = 0.3
	sun.light_color = Color("#ffd9b0")
	sun.rotation = Vector3(deg_to_rad(-24), deg_to_rad(64), 0)
	sun.directional_shadow_max_distance = 80.0
	Geo3D.sky(world, Vector3(0, 28, -120), Vector2(420, 130), Color("#12142e"), Color("#f08a4b"), Color("#5a3566"))
	var stars := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dot := BoxMesh.new()
	dot.size = Vector3(0.35, 0.35, 0.05)
	mm.mesh = dot
	mm.instance_count = 150
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in range(mm.instance_count):
		var s := rng.randf_range(0.5, 1.6)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, 1)).rotated(Vector3.FORWARD, 0.78), Vector3(rng.randf_range(-190, 190), rng.randf_range(22, 88), -118)))
	stars.multimesh = mm
	stars.material_override = Geo3D.flat(Color("#fff3d6"))
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(stars)
	# planeta vecino y luna, en capas lejanas para dar profundidad
	var planet := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 21.0
	ball.height = 42.0
	ball.radial_segments = 22
	ball.rings = 11
	planet.mesh = ball
	planet.material_override = Geo3D.mat(Color("#d9643a"))
	planet.position = Vector3(58, 40, -112)
	planet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(planet)
	for spot in [[Vector3(-8, 6, 19.0), 5.0], [Vector3(5, -7, 19.4), 3.6], [Vector3(-1, 11, 17.6), 3.0]]:
		Geo3D.cyl(planet, spot[1], spot[1], 0.4, spot[0], Color("#b94f30"), Vector3(PI * 0.5, 0, 0), 12, 0.0, 0.0)
	movers.append({"node": planet, "kind": "spin", "speed": 0.02})
	var moon := Geo3D.rock(world, Vector3(-76, 62, -110), 5.5, 3, Color("#8f8aa6"), 1.0, 0.0)
	movers.append({"node": moon, "kind": "spin", "speed": 0.05})
	# suelo y sierras
	var tint := func(p: Vector2, h: float, n: Vector3) -> Color:
		var shade := 0.82 + 0.3 * clampf(n.y, 0.0, 1.0) - 0.2 * clampf(-p.y / 70.0, 0.0, 1.0) + noise.get_noise_2d(p.x * 2.0, p.y * 2.0 + 90.0) * 0.08
		return Color("#c66a47").lerp(Color("#8f4030"), clampf(0.5 - h * 0.35, 0.0, 1.0)) * Color(shade, shade, shade)
	var land := MeshInstance3D.new()
	land.mesh = Geo3D.terrain(Rect2(-80, -78, 160, 124), 2.0, ground_height, tint)
	land.material_override = Geo3D.mat(Color.WHITE, 0.0, true)
	world.add_child(land)
	for i in range(26):
		var far := rng.randf_range(-70.0, -18.0)
		var x := rng.randf_range(-66.0, 66.0)
		var big := rng.randf_range(2.5, 7.5) * (1.0 + (-far - 18.0) / 60.0)
		Geo3D.rock(world, Vector3(x, ground_height(Vector2(x, far)) + big * 0.2, far), big, i, Color("#a9502f").lerp(Color("#5a3550"), clampf((-far - 18.0) / 60.0, 0.0, 0.85)), rng.randf_range(0.5, 1.1), 0.0)
	for i in range(34):
		var z := rng.randf_range(-16.0, 12.0)
		var x2 := rng.randf_range(-24.0, 24.0)
		if absf(x2) < 3.2 and absf(z) < 3.2: continue
		Geo3D.rock(world, Vector3(x2, ground_height(Vector2(x2, z)) + 0.1, z), rng.randf_range(0.25, 1.1), i + 30, Color("#8a4630").lerp(Color("#c0613f"), rng.randf()), rng.randf_range(0.5, 0.9), 0.04)
	if base: outpost(Vector3(15, 0, -15))
	focus = Vector3(0, 2.2, 0)
	camera.fov = 42.0

	bake()

## Base del equipo: cúpula, módulos, antena y torre con baliza.
func outpost(at: Vector3) -> void:
	var y := ground_height(Vector2(at.x, at.z))
	var root := Node3D.new()
	root.position = Vector3(at.x, y, at.z)
	world.add_child(root)
	var dome := MeshInstance3D.new()
	var half := SphereMesh.new()
	half.radius = 4.2
	half.height = 4.2
	half.is_hemisphere = true
	half.radial_segments = 10
	half.rings = 4
	dome.mesh = half
	dome.material_override = Geo3D.mat(Color("#ffd98a"), 0.9)
	root.add_child(dome)
	for i in range(5):
		var a := TAU * i / 10.0
		var bar := Geo3D.box(root, Vector3(8.5, 0.16, 0.16), Vector3(0, 0.06, 0), Color("#293746"), Vector3(0, a, 0), 0.0, 0.0)
		bar.position.y = 0.1
		Geo3D.cyl(root, 4.25, 4.25, 0.12, Vector3(0, 0.6 + i * 0.75, 0), Color("#293746"), Vector3.ZERO, 10, 0.0, 0.0).scale = Vector3(cos(asin(minf(0.99, (0.6 + i * 0.75) / 4.2))), 1, cos(asin(minf(0.99, (0.6 + i * 0.75) / 4.2))))
	Geo3D.cyl(root, 4.5, 4.7, 0.5, Vector3(0, 0.1, 0), Color("#e9e2d2"), Vector3.ZERO, 10)
	for n in range(3):
		var px := 6.5 + n * 4.3
		Geo3D.box(root, Vector3(3.8, 2.0, 2.6), Vector3(px, 1.2, 0.6), Color("#e9e2d2"))
		Geo3D.box(root, Vector3(3.9, 0.3, 2.7), Vector3(px, 1.9, 0.6), Color("#FFAD45"))
		for k in range(3): Geo3D.box(root, Vector3(0.6, 0.5, 0.06), Vector3(px - 1.1 + k * 1.1, 1.2, 1.93), Color("#ffe08a"), Vector3.ZERO, 1.8, 0.0)
		for leg in [-1.3, 1.3]: Geo3D.box(root, Vector3(0.25, 0.5, 0.25), Vector3(px + leg, 0.25, 0.6), Color("#293746"))
	var tower := Vector3(-8.5, 0, 3.0)
	Geo3D.cyl(root, 0.1, 0.22, 9.0, tower + Vector3(0, 4.5, 0), Color("#b3bec9"), Vector3.ZERO, 6)
	var lamp := Geo3D.box(root, Vector3(0.4, 0.4, 0.4), tower + Vector3(0, 9.2, 0), Color("#ff5a4f"), Vector3.ZERO, 2.0, 0.0)
	lamp.material_override = lamp.material_override.duplicate()
	movers.append({"node": lamp, "kind": "blink", "phase": 0.0})
	# antena parabólica sobre una loma, a la izquierda
	var hill := Vector3(-34 - at.x, 0, -4 - at.z + 2.0)
	var hy := ground_height(Vector2(-34, -17)) - y
	Geo3D.rock(root, hill + Vector3(0, hy + 0.6, 0), 5.0, 6, Color("#7a3d2e"), 0.45, 0.0)
	Geo3D.cyl(root, 0.25, 0.4, 3.2, hill + Vector3(0, hy + 3.4, 0), Color("#e9e2d2"), Vector3.ZERO, 6)
	var dish := Node3D.new()
	dish.position = hill + Vector3(0, hy + 5.2, 0)
	dish.rotation = Vector3(deg_to_rad(-38), deg_to_rad(40), 0)
	root.add_child(dish)
	Geo3D.cyl(dish, 2.6, 0.9, 0.7, Vector3.ZERO, Color("#e9e2d2"), Vector3.ZERO, 10)
	Geo3D.cyl(dish, 0.06, 0.06, 1.8, Vector3(0, 1.1, 0), Color("#293746"), Vector3.ZERO, 5)
	var tip := Geo3D.box(dish, Vector3(0.3, 0.3, 0.3), Vector3(0, 2.0, 0), Color("#ff5a4f"), Vector3.ZERO, 2.0, 0.0)
	tip.material_override = tip.material_override.duplicate()
	movers.append({"node": tip, "kind": "blink", "phase": 0.8})

# ------------------------------------------------------------------ globo de Marte
## Globo 3D real con cámara ortográfica frontal: un punto (x, y, z) de la esfera cae en pantalla
## en (x, -y), igual que la proyección que usa la pantalla de misiones para sus marcadores.
func globe() -> MeshInstance3D:
	fixed_camera = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.4
	camera.position = Vector3(0, 0, 6)
	camera.rotation = Vector3.ZERO
	env.ambient_light_color = Color("#ffd2b0")
	env.ambient_light_energy = 0.3
	sun.rotation = Vector3(deg_to_rad(-32), deg_to_rad(-38), 0)
	sun.light_energy = 0.55
	sun.shadow_enabled = false
	var ball := MeshInstance3D.new()
	ball.mesh = Geo3D.globe_mesh(Color("#c96140"))
	ball.material_override = Geo3D.mat(Color.WHITE, 0.0, true)
	world.add_child(ball)
	var halo := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.14
	disc.bottom_radius = 1.14
	disc.height = 0.01
	disc.radial_segments = 48
	halo.mesh = disc
	halo.rotation.x = PI * 0.5
	halo.position.z = -1.5
	halo.material_override = Geo3D.flat(Color(1.0, 0.62, 0.36, 0.2), true)
	world.add_child(halo)
	return ball
