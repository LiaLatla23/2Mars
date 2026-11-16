class_name OpsWorld
extends Control
## Mundo 3D de la exploración (V4). Es la PRESENTACIÓN del estado de misión que calcula
## scripts/screens/ops.gd: lee su posición, rumbo, rocas, zonas de riesgo, remolinos y acciones,
## y no decide ninguna regla. Cámara ortográfica ligeramente inclinada para conservar la
## lectura cenital. El relieve es visual: los riesgos del terreno siguen viniendo de ops.patches.

const S := 0.03                      # unidades 3D por píxel del mundo de juego
const TILT := 0.576                  # rad (33°) de inclinación respecto a la vertical
const ROVER_SCALE := 0.85
const SUN_DAY := 0.34
const AMBIENT_DAY := 0.3
const AMBIENT_NIGHT := 0.2

var ops: Control
var viewport: SubViewport
var view: TextureRect
var world: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var lamp: OmniLight3D
var rover: Rover3D
var rover2: Rover3D            # Expedición: rover del otro jugador
var viewport2: SubViewport
var camera2: Camera3D
var view2: TextureRect
var focus2 := Vector2.ZERO
var noise := FastNoiseLite.new()
var ky := cos(TILT)
var focus := Vector2.ZERO
var targets: Array = []
var sites: Array = []
var devils: Array = []
var tracks: MultiMeshInstance3D
var dust: CPUParticles3D
var last_pos := Vector2.ZERO
var pixels := Vector2i.ZERO
var clock := 0.0
var ground := Color("#c66a47")

static func make(screen: Control) -> OpsWorld:
	var node := OpsWorld.new()
	node.ops = screen
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.show_behind_parent = true
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(node)
	screen.move_child(node, 0)
	node.build()
	return node

# ------------------------------------------------------------------ geometría del terreno
func mask(p: Vector2, patch: Dictionary) -> float:
	var offset: Vector2 = p - patch.pos
	var d := pow(offset.x / float(patch.rx), 2) + pow(offset.y / float(patch.ry), 2)
	return clampf((1.0 - d) * 2.2, 0.0, 1.0)

func height(p: Vector2) -> float:
	var h := noise.get_noise_2d(p.x * 0.25, p.y * 0.25) * 0.8 + noise.get_noise_2d(p.x * 0.9 + 300.0, p.y * 0.9) * 0.12
	for patch in ops.patches:
		var m := mask(p, patch)
		if m <= 0.0: continue
		match String(patch.kind):
			"slope": h += m * m * 1.5
			"cold": h -= m * 0.7
			"sand": h += m * (0.1 + 0.09 * sin(p.y * 0.07 + p.x * 0.012))
	var pad := clampf(1.0 - p.distance_to(ops.LANDING) / 150.0, 0.0, 1.0)
	return lerpf(h, 0.0, pad)

func to3(p: Vector2, lift: float = 0.0) -> Vector3:
	return Vector3(p.x * S, height(p) + lift, p.y * S)

func tint(p3: Vector2, h: float, n: Vector3) -> Color:
	var p := p3 / S
	var shade := 0.7 + 0.34 * pow(clampf(n.y, 0.0, 1.0), 6.0) + noise.get_noise_2d(p.x * 0.6 + 70.0, p.y * 0.6) * 0.1
	var color := ground
	for patch in ops.patches:
		var m := mask(p, patch)
		if m <= 0.0: continue
		match String(patch.kind):
			"sand": color = color.lerp(Art.shade(ground, 0.26), m)
			"sharp": color = color.lerp(Art.shade(ground, -0.24), m)
			"slope": color = color.lerp(Art.shade(ground, -0.14 + 0.1 * sin(h * 9.0)), m)
			"cold": color = color.lerp(Color(0.36, 0.44, 0.62), m * 0.6)
	var pad := p.distance_to(ops.LANDING)
	if pad < 82.0: color = color.lerp(Art.shade(ground, -0.2), 0.8 if pad > 62.0 or pad < 26.0 else 0.35)
	var out := maxf(maxf(-p.x, p.x - ops.WORLD.x), maxf(-p.y, p.y - ops.WORLD.y))
	if out > 0.0: shade *= clampf(1.0 - out / 420.0, 0.35, 1.0)
	return Color(color.r * shade, color.g * shade, color.b * shade)

func build() -> void:
	ground = Color(String(ops.zone.ground))
	noise.seed = hash(Game.zone) % 1000
	noise.frequency = 0.01
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][Game.quality]
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.5
	camera.far = 200.0
	world.add_child(camera)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = ground.darkened(0.6)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var holder := WorldEnvironment.new()
	holder.environment = env
	world.add_child(holder)
	sun = DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-35), 0)
	sun.shadow_enabled = Game.quality > 0
	sun.directional_shadow_max_distance = 70.0
	world.add_child(sun)
	view = TextureRect.new()
	view.texture = viewport.get_texture()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	Geo3D.outline = Game.quality > 0
	# suelo con relieve (se extiende más allá del borde jugable para que no se vea el vacío)
	var land := MeshInstance3D.new()
	var margin := 620.0
	land.mesh = Geo3D.terrain(Rect2((Vector2(-margin, -margin)) * S, (Vector2(ops.WORLD) + Vector2(margin, margin) * 2.0) * S), 30.0 * S,
		func(p: Vector2) -> float: return height(p / S), tint)
	land.material_override = Geo3D.mat(Color.WHITE, 0.0, true)
	world.add_child(land)
	# piedras sueltas (decoración; no chocan, igual que en V3)
	var clutter := MultiMesh.new()
	clutter.transform_format = MultiMesh.TRANSFORM_3D
	clutter.use_colors = true
	clutter.mesh = Geo3D.rock_mesh(3)
	clutter.instance_count = ops.shards.size()
	for i in range(ops.shards.size()):
		var shard: Dictionary = ops.shards[i]
		var size := 0.1 + 0.22 * float((i * 37) % 10) / 10.0
		clutter.set_instance_transform(i, Transform3D(Basis().rotated(Vector3.UP, i * 1.7).scaled(Vector3(size, size * 0.7, size)), to3(shard.pos, size * 0.2)))
		clutter.set_instance_color(i, shard.color)
	var pebbles := MultiMeshInstance3D.new()
	pebbles.multimesh = clutter
	pebbles.material_override = Geo3D.mat(Color.WHITE, 0.0, true)
	world.add_child(pebbles)
	# rocas afiladas dentro de las zonas de desgaste
	# V5 · rocas de relleno y aristas: decorado estático, se une en una malla por material
	var decor := Node3D.new()
	world.add_child(decor)
	for patch in ops.patches:
		if String(patch.kind) != "sharp": continue
		var local := RandomNumberGenerator.new()
		local.seed = int(patch.seed) + 50
		for i in range(18):
			var at: Vector2 = patch.pos + Vector2(local.randf_range(-0.7, 0.7) * float(patch.rx), local.randf_range(-0.7, 0.7) * float(patch.ry))
			var tall := local.randf_range(0.35, 0.7)
			Geo3D.cyl(decor, 0.0, tall * 0.5, tall, to3(at, tall * 0.45), Art.shade(ground, -0.42), Vector3(0, local.randf() * TAU, local.randf_range(-0.2, 0.2)), 4, 0.0, 0.04)
	for item in ops.obstacles:
		var r := float(item.r) * S
		Geo3D.rock(decor, to3(item.pos, r * 0.25), r, int(item.seed), item.color, 0.8, 0.05)
	Geo3D.merge(decor)
	for item in ops.targets:
		var info: Dictionary = Data.ROCKS[item.type]
		var r2 := float(item.r) * S
		var soil: bool = info.klass == "soil"
		var node := Geo3D.rock(world, to3(item.pos, r2 * (0.05 if soil else 0.3)), r2 * (1.25 if soil else 1.0), int(item.seed), Color(String(info.color)), 0.22 if soil else 0.85, 0.05)
		var ring := Geo3D.ring(world, to3(item.pos, 0.12), r2 + 0.5, 0.11, UIK.YELLOW)
		targets.append({"item": item, "node": node, "ring": ring, "soil": soil, "base": node.scale})
	for site in ops.sites:
		var mark := Geo3D.ring(world, to3(site.pos, 0.14), float(site.r) * S, 0.1, UIK.PAPER)
		mark.visible = "rimfax" in ops.has
		sites.append({"item": site, "ring": mark})
	for devil in ops.devils:
		var twister := Node3D.new()
		world.add_child(twister)
		for i in range(5):
			var layer := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.bottom_radius = 0.25 + i * 0.22
			cone.top_radius = 0.5 + i * 0.26
			cone.height = 0.75
			cone.radial_segments = 7
			cone.rings = 1
			layer.mesh = cone
			layer.material_override = Geo3D.flat(Color(Art.shade(ground, 0.3), 0.34 - i * 0.04), true)
			layer.position.y = 0.4 + i * 0.7
			layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			twister.add_child(layer)
		devils.append({"item": devil, "node": twister})
	# huellas de las ruedas
	var prints := MultiMesh.new()
	prints.transform_format = MultiMesh.TRANSFORM_3D
	prints.use_colors = true
	var mark2 := BoxMesh.new()
	mark2.size = Vector3(0.3, 0.02, 0.16)
	prints.mesh = mark2
	prints.instance_count = 180
	prints.visible_instance_count = 0
	tracks = MultiMeshInstance3D.new()
	tracks.multimesh = prints
	var track_mat := Geo3D.flat(Color.WHITE, true)
	track_mat.vertex_color_use_as_albedo = true
	track_mat.vertex_color_is_srgb = true
	tracks.material_override = track_mat
	tracks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(tracks)
	# rover del jugador
	rover = Rover3D.new()
	rover.edge = 0.05 if Game.quality > 0 else 0.0
	rover.scale = Vector3.ONE * ROVER_SCALE
	world.add_child(rover)
	rover.set_build(ops.build)
	if ops.expedition():
		# Expedición: segundo rover en el mismo mundo y segunda cámara que mira la misma escena
		rover2 = Rover3D.new()
		rover2.edge = rover.edge
		rover2.scale = Vector3.ONE * ROVER_SCALE
		world.add_child(rover2)
		rover2.set_build(ops.build)
		viewport2 = SubViewport.new()
		viewport2.world_3d = viewport.find_world_3d()
		viewport2.msaa_3d = viewport.msaa_3d
		viewport2.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport2)
		camera2 = Camera3D.new()
		camera2.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera2.near = 0.5
		camera2.far = 200.0
		viewport2.add_child(camera2)
		view2 = TextureRect.new()
		view2.texture = viewport2.get_texture()
		view2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view2.stretch_mode = TextureRect.STRETCH_SCALE
		view2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view2.show_behind_parent = true
		ops.add_child(view2)
		ops.move_child(view2, 1)
	lamp = OmniLight3D.new()
	lamp.light_color = Color("#ffe2a8")
	lamp.omni_range = 7.0
	lamp.light_energy = 0.0
	world.add_child(lamp)
	if Game.quality > 0:
		dust = CPUParticles3D.new()
		var puff := SphereMesh.new()
		puff.radius = 0.16
		puff.height = 0.32
		puff.radial_segments = 6
		puff.rings = 3
		dust.mesh = puff
		dust.material_override = Geo3D.flat(Color(Art.shade(ground, 0.25), 0.4), true)
		dust.amount = 16
		dust.lifetime = 0.8
		dust.direction = Vector3(0, 1, 0)
		dust.spread = 50.0
		dust.initial_velocity_min = 0.4
		dust.initial_velocity_max = 0.9
		dust.gravity = Vector3(0, 0.4, 0)
		dust.scale_amount_min = 0.5
		dust.scale_amount_max = 1.2
		dust.emitting = false
		world.add_child(dust)
	last_pos = ops.pos
	fit()
	sync(0.0)

func fit() -> void:
	var factor := 1.0
	if is_inside_tree(): factor = get_viewport().get_final_transform().get_scale().x
	var want := Vector2i((size * factor * Game.render_scale()).round()).clamp(Vector2i(64, 64), Vector2i(2560, 1440))
	if want != pixels:
		pixels = want
		viewport.size = want
		if viewport2 != null: viewport2.size = want

# ------------------------------------------------------------------ cámara y conversión
func span() -> Vector2:
	return Vector2(size.x / ops.ZOOM, size.y / (ops.ZOOM * ky))

## Igual que to_screen, pero en la mitad derecha (cámara del jugador 2).
func to_screen2(p: Vector2, lift: float = 0.0) -> Vector2:
	return Vector2(642, 0) + size * 0.5 + Vector2((p.x - focus2.x) * ops.ZOOM, (p.y - focus2.y) * ops.ZOOM * ky - lift * sin(TILT) / S * ops.ZOOM)

## Mundo de juego (px) -> pantalla. lift = altura 3D del punto.
func to_screen(p: Vector2, lift: float = 0.0) -> Vector2:
	return size * 0.5 + Vector2((p.x - focus.x) * ops.ZOOM, (p.y - focus.y) * ops.ZOOM * ky - lift * sin(TILT) / S * ops.ZOOM)

func to_world(point: Vector2) -> Vector2:
	var offset := point - size * 0.5
	return focus + Vector2(offset.x / ops.ZOOM, offset.y / (ops.ZOOM * ky))

func _process(delta: float) -> void:
	clock += delta
	fit()
	sync(delta)

func sync(delta: float) -> void:
	var pos: Vector2 = ops.pos
	var half := span() * 0.5
	if rover2 != null:
		# pantalla dividida fija: izquierda sigue al jugador 1, derecha al jugador 2
		position = Vector2.ZERO
		size = Vector2(638, 720)
		view2.position = Vector2(642, 0)
		view2.size = Vector2(638, 720)
		half = span() * 0.5
		focus = (ops.player_pos(0) as Vector2).clamp(half, Vector2(ops.WORLD) - half)
		focus2 = (ops.player_pos(1) as Vector2).clamp(half, Vector2(ops.WORLD) - half)
		camera2.size = size.y / ops.ZOOM * S
		var look2 := Vector3(focus2.x * S, 0.0, focus2.y * S)
		camera2.position = look2 + Vector3(0.0, cos(TILT), sin(TILT)) * 60.0
		camera2.look_at(look2, Vector3(0, 0, -1))
		var other: Vector2 = ops.mate.pos
		rover2.position = Vector3(other.x * S, height(other), other.y * S)
		rover2.rotation.y = -float(ops.mate.heading)
		rover2.visible = true
	else: focus = pos.clamp(half, Vector2(ops.WORLD) - half)
	camera.size = size.y / ops.ZOOM * S
	var look := Vector3(focus.x * S, 0.0, focus.y * S)
	camera.position = look + Vector3(0.0, cos(TILT), sin(TILT)) * 60.0
	camera.look_at(look, Vector3(0, 0, -1))
	# rover: posición sobre el relieve, giro de ruedas y suspensión
	var ground_y := height(pos)
	rover.position = Vector3(pos.x * S, ground_y, pos.y * S)
	rover.rotation.y = -float(ops.heading)
	var step: Vector2 = pos - last_pos
	last_pos = pos
	var forward := Vector2.from_angle(float(ops.heading))
	var moved := step.length() * S / ROVER_SCALE * signf(step.dot(forward) + 0.0001)
	var vel: Vector2 = ops.vel
	var steer := angle_difference(float(ops.heading), vel.angle()) if vel.length() > 8.0 else 0.0
	rover.drive(moved, steer, delta)
	var lifts: Array = []
	for wheel in rover.wheels:
		var base: Vector3 = wheel.base
		var at := pos + (Vector2(base.x, base.z) * ROVER_SCALE / S).rotated(float(ops.heading))
		lifts.append((height(at) - ground_y) / ROVER_SCALE)
	rover.settle(lifts, maxf(delta, 0.001))
	var moving := vel.length() > 12.0
	if dust != null:
		dust.emitting = moving and not Game.reduced_motion
		dust.position = rover.position - Vector3(forward.x, 0, forward.y) * 0.7 + Vector3(0, 0.15, 0)
	# acción visible del rover
	var action := ""
	var aim := Vector3(1.6, 0.2, 0.0)
	if bool(ops.transmitting): action = "transmit"
	elif float(ops.moxie_timer) >= 0.0: action = "moxie"
	elif String(ops.mode) == "minigame":
		action = {"mastcam": "image", "supercam": "laser", "pixl": "arm", "sherloc": "arm", "drill": "drill", "regolith": "arm", "rimfax": "radar"}.get(String(ops.game.get("id", "")), "")
		var target: Dictionary = ops.focus
		if target.has("pos"): aim = rover.to_local(to3(target.pos, float(target.get("r", 30.0)) * S * 0.6))
	rover.set_action(action, aim)
	# objetivos, sitios y remolinos
	for entry in targets:
		var item: Dictionary = entry.item
		var studied: bool = item.imaged or item.chem or item.pixl or item.sherloc or item.cached
		var ring: MeshInstance3D = entry.ring
		var m: StandardMaterial3D = ring.material_override
		var pulse := 1.0 + 0.06 * sin(clock * 3.0 + float(item.seed))
		ring.scale = Vector3(pulse, 0.25, pulse)
		m.albedo_color = Color(UIK.GOOD if studied else UIK.YELLOW, 0.95 if item == ops.focus else 0.7)
		if bool(item.crumbled) and not bool(entry.soil): (entry.node as Node3D).scale = (entry.base as Vector3) * Vector3(1.1, 0.4, 1.1)
	for entry in sites:
		var m2: StandardMaterial3D = (entry.ring as MeshInstance3D).material_override
		m2.albedo_color = Color(UIK.GOOD if bool(entry.item.scanned) else UIK.PAPER, 0.85)
	for entry in devils:
		var twister: Node3D = entry.node
		twister.position = to3(entry.item.pos)
		twister.rotate_y(delta * 5.0)
		for i in range(twister.get_child_count()): (twister.get_child(i) as Node3D).position.x = sin(clock * 3.0 + i * 0.9) * 0.12 * i
	var list: Array = ops.tracks
	var prints := tracks.multimesh
	prints.visible_instance_count = mini(180, list.size() * 2)
	for i in range(mini(90, list.size())):
		var here: Vector2 = list[i]
		var along: Vector2 = (list[mini(i + 1, list.size() - 1)] - list[maxi(i - 1, 0)]) as Vector2
		var turn := along.angle() if along.length() > 0.1 else float(ops.heading)
		var side := Vector2.from_angle(turn).orthogonal() * 19.0
		var fade := Color(0.3, 0.12, 0.08, 0.45 * i / maxf(1.0, list.size()))
		for k in range(2):
			prints.set_instance_transform(i * 2 + k, Transform3D(Basis().rotated(Vector3.UP, -turn), to3(here + side * (1.0 if k == 0 else -1.0), 0.03)))
			prints.set_instance_color(i * 2 + k, fade)
	# luz del día, noche y tormenta
	var day := float(ops.light())
	var storm: bool = ops.storming()
	sun.light_energy = lerpf(0.03, SUN_DAY, day) * (0.6 if storm else 1.0)
	sun.light_color = Color("#ffe6c4").lerp(Color("#ffb070"), 1.0 - day)
	env.ambient_light_color = Color("#3c4c86").lerp(Color("#ffd9bf") if not storm else Color("#f0a868"), day)
	env.ambient_light_energy = lerpf(AMBIENT_NIGHT, AMBIENT_DAY, day)
	lamp.light_energy = 1.4 * clampf(1.0 - day * 3.0, 0.0, 1.0)
	lamp.position = rover.position + Vector3(forward.x, 0, forward.y) * 1.6 + Vector3(0, 1.4, 0)
