extends Node
## Herramienta de desarrollo: renderiza la miniatura de cada pieza (modelo 3D del juego, aislada)
## y de cada tipo de roca. Salida: assets/parts/<id>.png y assets/rocks/<id>.png (256 px, alfa).
##   godot --path . res://tools/Thumbs.tscn      (necesita pantalla; no funciona con --headless)
var viewport: SubViewport
var world: Node3D
var camera: Camera3D

func frames(n: int) -> void:
	for i in range(n): await get_tree().process_frame

func _ready() -> void:
	Geo3D.outline = true
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.size = Vector2i(256, 256)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(camera)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff1dc")
	env.ambient_light_energy = 0.44
	var holder := WorldEnvironment.new()
	holder.environment = env
	world.add_child(holder)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-42), deg_to_rad(-30), 0)
	sun.light_energy = 0.5
	world.add_child(sun)
	for id in Data.COMPONENTS:
		var build := {"chassis": "chassis_std", "deck": "deck_compact", "wheels": "wheels_std", "power": "solar", "computer": "cpu_basic", "arm": "", "parts": []}
		for group in Data.GROUPS:
			if not id in group.options: continue
			if group.kind == "one": build[String(group.id)] = id
			elif group.kind == "optional": build.arm = id
			else: build.parts = [id]
		if id == "autonav": build.computer = "cpu_adv"
		var rover := Rover3D.new()
		rover.edge = 0.0
		world.add_child(rover)
		rover.set_build(build)
		rover.edge = clampf(span_of(rover.meshes_of(id)) * 0.011, 0.004, 0.03)   # contorno proporcional al encuadre
		rover.set_build(build)
		if rover.shoulder != null:
			rover.arm_pose = Vector3(0.5, -0.35, 1.1)
			rover.apply_arm()
		rover.set_process(false)
		var keep: Array = rover.meshes_of(id)
		for mesh in rover.find_children("*", "MeshInstance3D", true, false):
			if (mesh as Node).has_meta("hull"): continue
			(mesh as MeshInstance3D).visible = mesh in keep
		await shoot(keep, "res://assets/parts/%s.png" % id)
		rover.free()
	for id in Data.ROCKS:
		var info: Dictionary = Data.ROCKS[id]
		var soil: bool = info.klass == "soil"
		var holder2 := Node3D.new()
		world.add_child(holder2)
		var rock := Geo3D.rock(holder2, Vector3.ZERO, 1.0, id.hash() % 97, Color(String(info.color)), 0.3 if soil else 0.85, 0.05)
		rock.rotation.y = 0.6
		if not soil: Geo3D.rock(holder2, Vector3(0.9, -0.35, 0.5), 0.42, id.hash() % 31 + 2, Color(String(info.color)).darkened(0.12), 0.8, 0.05)
		var keep2: Array = holder2.find_children("*", "MeshInstance3D", true, false).filter(func(m: Variant) -> bool: return not (m as Node).has_meta("hull"))
		await shoot(keep2, "res://assets/rocks/%s.png" % id)
		holder2.free()
	print("THUMBS DONE")
	get_tree().quit()

func span_of(keep: Array) -> float:
	return bounds(keep).get_longest_axis_size()

func shoot(keep: Array, path: String) -> void:
	var box := bounds(keep)
	var centre := box.get_center()
	var dir := Vector3(sin(0.75) * cos(0.5), sin(0.5), cos(0.75) * cos(0.5))
	camera.size = maxf(0.35, box.get_longest_axis_size() * 1.5)
	camera.position = centre + dir * 20.0
	camera.look_at(centre, Vector3.UP)
	await frames(3)
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(path)

func bounds(keep: Array) -> AABB:
	var box := AABB()
	var first := true
	for mesh in keep:
		var m := mesh as MeshInstance3D
		var local := m.get_aabb()
		for i in range(8):
			var corner := m.global_transform * local.get_endpoint(i)
			if first:
				box = AABB(corner, Vector3.ZERO)
				first = false
			else: box = box.expand(corner)
	return box
