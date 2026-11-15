class_name Rover3D
extends Node3D
## Rover 3D de 2Mars (V4). Geometría procedural low-poly: cada pieza instalada en el diseño
## (Data.COMPONENTS) tiene su propia malla, así que el modelo refleja el rover real del jugador.
## El modelo mira hacia +X. Es arte del juego inspirado en Perseverance, no un modelo de la NASA.

const C_BODY := Color("#f6eeda")
const C_DARK := Color("#293746")
const C_INK := Color("#191922")
const C_ORANGE := Color("#FFAD45")
const C_RUST := Color("#AA5D40")
const C_MINT := Color("#91C6BB")
const C_METAL := Color("#b3bec9")
const C_PANEL := Color("#2d62b8")
const C_GOLD := Color("#e3b54c")
const C_TYRE := Color("#3a3f4c")

static var glow_mat: StandardMaterial3D

var edge := 0.02                # grosor del contorno oscuro en unidades del modelo

var build: Dictionary = {}
var parts := {}                 # id de pieza -> Array[Node3D]
var wheels: Array = []          # {root, steer, spin, radius, front}
var body: Node3D
var head: Node3D
var dish: Node3D
var shoulder: Node3D
var elbow: Node3D
var turret: Node3D
var puck: Node3D
var drill_bit: Node3D
var rings: Array = []           # anillos de transmisión
var beam: MeshInstance3D
var action := ""
var action_time := 0.0
var target_local := Vector3(1.6, 0.2, 0.0)
var arm_pose := Vector3(1.45, 0.25, 2.5)      # yaw, hombro, codo (plegado)
var glow_id := ""
var glow_left := 0.0
var clock := 0.0
var steer_now := 0.0
var bob := 0.0
var dims := Vector3(1.8, 0.52, 1.1)
var deck_y := 1.06
var wheel_r := 0.3

# ------------------------------------------------------------------ primitivas (con contorno)
func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO, emission: float = 0.0) -> MeshInstance3D:
	return Geo3D.box(parent, size, pos, color, rot, emission, edge)

func cyl(parent: Node3D, top: float, bottom: float, height: float, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO, segments: int = 10, emission: float = 0.0) -> MeshInstance3D:
	return Geo3D.cyl(parent, top, bottom, height, pos, color, rot, segments, emission, edge)

func strut(parent: Node3D, a: Vector3, b: Vector3, thick: float, color: Color) -> MeshInstance3D:
	return Geo3D.strut(parent, a, b, thick, color, edge)

func group(id: String, parent: Node3D = null) -> Node3D:
	var node := Node3D.new()
	node.name = id
	(parent if parent != null else body).add_child(node)
	if not parts.has(id): parts[id] = []
	parts[id].append(node)
	return node

func has_part(id: String) -> bool:
	return Data.has(build, id)

# ------------------------------------------------------------------ construcción
func set_build(next: Dictionary) -> void:
	build = next.duplicate(true)
	for child in get_children(): child.free()
	parts = {}
	wheels = []
	rings = []
	head = null
	dish = null
	shoulder = null
	elbow = null
	turret = null
	puck = null
	drill_bit = null
	beam = null
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	make_chassis()
	make_mobility()
	make_power()
	make_mast()
	make_payload()
	make_arm()
	make_comms()
	make_effects()

func make_chassis() -> void:
	var kind := String(build.get("chassis", "chassis_std"))
	dims = {"chassis_light": Vector3(1.62, 0.42, 0.96), "chassis_reinf": Vector3(1.96, 0.62, 1.2)}.get(kind, Vector3(1.8, 0.52, 1.1))
	var g := group(kind)
	var cy := 0.5 + dims.y * 0.5
	box(g, dims, Vector3(0, cy, 0), C_BODY)
	box(g, Vector3(dims.x * 0.92, 0.08, dims.z * 0.92), Vector3(0, 0.5 - 0.02, 0), C_DARK)
	box(g, Vector3(dims.x + 0.02, 0.09, dims.z + 0.02), Vector3(0, cy - dims.y * 0.18, 0), C_ORANGE)
	if kind == "chassis_reinf":
		for side in [-1.0, 1.0]:
			box(g, Vector3(0.14, dims.y + 0.1, dims.z + 0.12), Vector3(side * (dims.x * 0.5 - 0.02), cy, 0), C_DARK)
			box(g, Vector3(dims.x * 0.7, 0.1, 0.07), Vector3(0, cy + 0.12, side * (dims.z * 0.5 + 0.03)), C_METAL)
	elif kind == "chassis_light":
		for i in range(3): box(g, Vector3(0.05, dims.y * 0.6, dims.z + 0.03), Vector3(-0.5 + i * 0.5, cy, 0), C_MINT)
	deck_y = 0.5 + dims.y
	var deck_kind := String(build.get("deck", "deck_compact"))
	var d := group(deck_kind)
	var plate := Vector3(dims.x + 0.5, 0.07, dims.z + 0.4) if deck_kind == "deck_ext" else Vector3(dims.x + 0.06, 0.07, dims.z + 0.06)
	box(d, plate, Vector3(-0.04 if deck_kind == "deck_ext" else 0.0, deck_y + 0.035, 0), C_DARK)
	box(d, Vector3(plate.x - 0.12, 0.02, plate.z - 0.12), Vector3(-0.04 if deck_kind == "deck_ext" else 0.0, deck_y + 0.08, 0), Color("#3b4d61"))
	if deck_kind == "deck_ext":
		for side in [-1.0, 1.0]: box(d, Vector3(plate.x, 0.05, 0.06), Vector3(-0.04, deck_y + 0.1, side * (plate.z * 0.5 - 0.03)), C_MINT)
	deck_y += 0.09
	var cpu := String(build.get("computer", "cpu_basic"))
	var c := group(cpu)
	if cpu == "cpu_adv":
		box(c, Vector3(0.42, 0.16, 0.34), Vector3(-0.18, deck_y + 0.08, -0.02), C_METAL)
		for i in range(4): box(c, Vector3(0.03, 0.07, 0.3), Vector3(-0.33 + i * 0.1, deck_y + 0.19, -0.02), C_DARK)
		box(c, Vector3(0.05, 0.05, 0.05), Vector3(0.0, deck_y + 0.18, 0.12), C_ORANGE, Vector3.ZERO, 1.6)
	else:
		box(c, Vector3(0.3, 0.09, 0.24), Vector3(-0.18, deck_y + 0.045, -0.02), C_METAL)
		box(c, Vector3(0.04, 0.03, 0.04), Vector3(-0.08, deck_y + 0.1, 0.06), C_MINT, Vector3.ZERO, 1.2)

func make_mobility() -> void:
	var kind := String(build.get("wheels", "wheels_std"))
	var width: float = {"wheels_light": 0.17, "wheels_reinf": 0.32}.get(kind, 0.24)
	wheel_r = {"wheels_light": 0.28, "wheels_reinf": 0.33}.get(kind, 0.3)
	var hub: Color = {"wheels_light": C_MINT, "wheels_reinf": C_ORANGE}.get(kind, C_METAL)
	var side_z := dims.z * 0.5 + 0.34
	var rocker := has_part("rocker")
	var legs := group("rocker") if rocker else group(kind)
	for side in [-1.0, 1.0]:
		var z: float = side * side_z
		var pivot := Vector3(0.12, 0.86, z - side * 0.12)
		var spots := [Vector3(1.02, wheel_r, z), Vector3(-0.02, wheel_r, z), Vector3(-1.02, wheel_r, z)]
		if rocker:
			var bogie := Vector3(-0.52, 0.62, z - side * 0.1)
			strut(legs, pivot, spots[0] + Vector3(0, 0.12, -side * 0.1), 0.1, C_MINT)
			strut(legs, pivot, bogie, 0.1, C_MINT)
			strut(legs, bogie, spots[1] + Vector3(0, 0.12, -side * 0.1), 0.085, C_ORANGE)
			strut(legs, bogie, spots[2] + Vector3(0, 0.12, -side * 0.1), 0.085, C_ORANGE)
			cyl(legs, 0.09, 0.09, 0.2, pivot, C_DARK, Vector3(PI * 0.5, 0, 0), 8)
			cyl(legs, 0.07, 0.07, 0.16, bogie, C_DARK, Vector3(PI * 0.5, 0, 0), 8)
		else:
			strut(legs, Vector3(1.02, 0.66, z - side * 0.14), Vector3(-1.02, 0.66, z - side * 0.14), 0.08, C_DARK)
		for i in range(3):
			var root := Node3D.new()
			root.position = spots[i]
			body.add_child(root)
			parts[kind] = parts.get(kind, []) + [root]
			var steer := Node3D.new()
			root.add_child(steer)
			box(steer, Vector3(0.07, 0.5 if rocker else 0.42, 0.07), Vector3(0, 0.22, -side * (width * 0.5 + 0.06)), C_DARK)
			var spin := Node3D.new()
			steer.add_child(spin)
			cyl(spin, wheel_r, wheel_r, width, Vector3.ZERO, C_TYRE, Vector3(PI * 0.5, 0, 0), 12)
			cyl(spin, wheel_r * 0.55, wheel_r * 0.55, width + 0.03, Vector3.ZERO, hub, Vector3(PI * 0.5, 0, 0), 8)
			var cleats := 10 if kind == "wheels_reinf" else (6 if kind == "wheels_light" else 8)
			for n in range(cleats):
				var a := TAU * n / cleats
				box(spin, Vector3(0.07, 0.05, width + 0.02), Vector3(cos(a) * wheel_r, sin(a) * wheel_r, 0), C_INK if kind != "wheels_light" else C_DARK, Vector3(0, 0, a + PI * 0.5))
			for n in range(3): box(spin, Vector3(wheel_r * 1.05, 0.04, width + 0.05), Vector3.ZERO, C_BODY, Vector3(0, 0, PI * n / 3.0))
			wheels.append({"root": root, "steer": steer, "spin": spin, "radius": wheel_r, "front": 1.0 if i == 0 else (-1.0 if i == 2 else 0.0), "base": spots[i], "lift": 0.0})

func make_power() -> void:
	if String(build.get("power", "solar")) == "rtg":
		var g := group("rtg")
		var holder := Node3D.new()
		holder.position = Vector3(-dims.x * 0.5 - 0.22, deck_y + 0.08, 0)
		holder.rotation = Vector3(0, 0, deg_to_rad(-52))
		g.add_child(holder)
		cyl(holder, 0.17, 0.17, 0.74, Vector3.ZERO, C_DARK, Vector3.ZERO, 8)
		for n in range(6): box(holder, Vector3(0.5, 0.6, 0.025), Vector3.ZERO, C_METAL, Vector3(0, PI * n / 6.0, 0))
		cyl(holder, 0.13, 0.17, 0.1, Vector3(0, 0.42, 0), C_ORANGE, Vector3.ZERO, 8, 1.4)
	else:
		var s := group("solar")
		for side in [-1.0, 1.0]:
			var wing := Node3D.new()
			wing.position = Vector3(-0.1, deck_y + 0.2, side * (dims.z * 0.5 + 0.42))
			wing.rotation = Vector3(side * deg_to_rad(-13), 0, 0)
			s.add_child(wing)
			box(wing, Vector3(1.7, 0.04, 0.82), Vector3.ZERO, C_PANEL)
			box(wing, Vector3(1.74, 0.03, 0.86), Vector3(0, -0.02, 0), C_BODY)
			for n in range(4): box(wing, Vector3(0.025, 0.05, 0.8), Vector3(-0.64 + n * 0.43, 0.0, 0), Color("#7fb2ee"))
			box(wing, Vector3(1.68, 0.05, 0.025), Vector3.ZERO, Color("#7fb2ee"))
			strut(s, Vector3(-0.1, deck_y, side * dims.z * 0.4), wing.position, 0.06, C_METAL)
	if has_part("battery_ext"):
		var b := group("battery_ext")
		box(b, Vector3(0.62, 0.26, 0.2), Vector3(-0.32, 0.72, dims.z * 0.5 + 0.1), C_ORANGE)
		for n in range(3): box(b, Vector3(0.05, 0.28, 0.22), Vector3(-0.52 + n * 0.2, 0.72, dims.z * 0.5 + 0.1), C_INK)
		box(b, Vector3(0.1, 0.05, 0.05), Vector3(-0.32, 0.88, dims.z * 0.5 + 0.1), C_MINT, Vector3.ZERO, 1.4)

func make_mast() -> void:
	var foot := Vector3(dims.x * 0.5 - 0.3, deck_y, dims.z * 0.5 - 0.28)
	var tall := 0.95 if (has_part("mastcam") or has_part("supercam")) else 0.6
	var m := Node3D.new()
	body.add_child(m)
	cyl(m, 0.05, 0.07, tall, foot + Vector3(0, tall * 0.5, 0), C_BODY, Vector3.ZERO, 8)
	cyl(m, 0.1, 0.12, 0.08, foot + Vector3(0, 0.04, 0), C_DARK, Vector3.ZERO, 8)
	head = Node3D.new()
	head.position = foot + Vector3(0, tall, 0)
	m.add_child(head)
	box(head, Vector3(0.24, 0.2, 0.5), Vector3(0, 0.1, 0), C_BODY)
	for side in [-1.0, 1.0]: cyl(head, 0.05, 0.05, 0.05, Vector3(0.13, 0.1, side * 0.17), C_INK, Vector3(0, 0, PI * 0.5), 8)
	if has_part("mastcam"):
		var g := group("mastcam", head)
		for side in [-1.0, 1.0]:
			cyl(g, 0.075, 0.075, 0.16, Vector3(0.16, 0.1, side * 0.085), C_DARK, Vector3(0, 0, PI * 0.5), 8)
			cyl(g, 0.055, 0.055, 0.03, Vector3(0.25, 0.1, side * 0.085), C_ORANGE, Vector3(0, 0, PI * 0.5), 8, 0.8)
	if has_part("supercam"):
		var g2 := group("supercam", head)
		box(g2, Vector3(0.3, 0.26, 0.34), Vector3(0.0, 0.33, 0), C_BODY)
		cyl(g2, 0.11, 0.11, 0.08, Vector3(0.17, 0.33, 0), C_DARK, Vector3(0, 0, PI * 0.5), 10)
		cyl(g2, 0.07, 0.07, 0.03, Vector3(0.215, 0.33, 0), C_MINT, Vector3(0, 0, PI * 0.5), 10, 1.2)
	if has_part("meda"):
		var g3 := group("meda", m)
		for turn in [0.7, -0.7, 2.4]:
			var tip: Vector3 = foot + Vector3(cos(turn) * 0.34, tall * 0.62, sin(turn) * 0.34)
			strut(g3, foot + Vector3(0, tall * 0.55, 0), tip, 0.03, C_METAL)
			box(g3, Vector3(0.06, 0.06, 0.06), tip, C_MINT)
		box(g3, Vector3(0.16, 0.1, 0.16), Vector3(0.36, deck_y + 0.05, -0.06), C_METAL)
	if has_part("autonav"):
		var g4 := group("autonav", head)
		puck = Node3D.new()
		puck.position = Vector3(-0.02, (0.5 if has_part("supercam") else 0.24), 0)
		g4.add_child(puck)
		cyl(puck, 0.09, 0.11, 0.07, Vector3.ZERO, C_ORANGE, Vector3.ZERO, 8)
		box(puck, Vector3(0.05, 0.04, 0.2), Vector3(0, 0.05, 0), C_INK)
	if has_part("navsens"):
		var g5 := group("navsens")
		for side in [-1.0, 1.0]:
			box(g5, Vector3(0.1, 0.1, 0.16), Vector3(dims.x * 0.5 + 0.04, 0.5 + dims.y * 0.72, side * (dims.z * 0.5 - 0.16)), C_DARK)
			cyl(g5, 0.035, 0.035, 0.03, Vector3(dims.x * 0.5 + 0.1, 0.5 + dims.y * 0.72, side * (dims.z * 0.5 - 0.16)), C_MINT, Vector3(0, 0, PI * 0.5), 8, 1.4)

func make_payload() -> void:
	if has_part("moxie"):
		var g := group("moxie")
		box(g, Vector3(0.3, 0.28, 0.3), Vector3(0.3, deck_y + 0.14, -dims.z * 0.5 + 0.22), C_GOLD)
		cyl(g, 0.05, 0.05, 0.12, Vector3(0.3, deck_y + 0.34, -dims.z * 0.5 + 0.22), C_METAL, Vector3.ZERO, 8)
	if has_part("storage"):
		var g2 := group("storage")
		for n in range(3):
			box(g2, Vector3(0.3, 0.07, 0.22), Vector3(-0.56, deck_y + 0.04 + n * 0.09, 0.22), C_DARK)
			box(g2, Vector3(0.03, 0.03, 0.03), Vector3(-0.4, deck_y + 0.04 + n * 0.09, 0.3), C_MINT, Vector3.ZERO, 1.6)
	if has_part("rimfax"):
		var g3 := group("rimfax")
		box(g3, Vector3(0.5, 0.09, 0.62), Vector3(-dims.x * 0.5 + 0.1, 0.4, 0), C_MINT)
		box(g3, Vector3(0.3, 0.05, 0.5), Vector3(-dims.x * 0.5 + 0.1, 0.34, 0), C_DARK)
	if has_part("regolith"):
		var g4 := group("regolith")
		box(g4, Vector3(0.26, 0.12, 0.34), Vector3(dims.x * 0.5 + 0.06, 0.42, 0.18), C_RUST)
		box(g4, Vector3(0.1, 0.05, 0.38), Vector3(dims.x * 0.5 + 0.2, 0.37, 0.18), C_METAL)

func tool_meshes(parent: Node3D, stowed: bool) -> void:
	var slots := [Vector3(0.06, 0.0, -0.13), Vector3(0.06, 0.0, 0.13), Vector3(0.1, 0.12, 0.0)]
	var used := 0
	for id in ["pixl", "sherloc", "drill"]:
		if not has_part(id): continue
		var g := group(id, parent)
		g.position = Vector3(-0.2 + used * 0.24, 0.07, 0.0) if stowed else slots[used]
		used += 1
		match id:
			"pixl":
				cyl(g, 0.085, 0.085, 0.12, Vector3.ZERO, C_GOLD, Vector3(0, 0, PI * 0.5), 6)
				cyl(g, 0.04, 0.04, 0.04, Vector3(0.08, 0, 0), C_INK, Vector3(0, 0, PI * 0.5), 6)
			"sherloc":
				box(g, Vector3(0.14, 0.13, 0.13), Vector3.ZERO, C_METAL)
				cyl(g, 0.04, 0.04, 0.03, Vector3(0.08, 0, 0), C_MINT, Vector3(0, 0, PI * 0.5), 8, 1.2)
			"drill":
				cyl(g, 0.07, 0.07, 0.2, Vector3.ZERO, C_ORANGE, Vector3(0, 0, PI * 0.5), 8)
				drill_bit = Node3D.new()
				drill_bit.position = Vector3(0.16, 0, 0)
				g.add_child(drill_bit)
				cyl(drill_bit, 0.0, 0.04, 0.16, Vector3.ZERO, C_METAL, Vector3(0, 0, -PI * 0.5), 5)

func make_arm() -> void:
	var kind := String(build.get("arm", ""))
	if kind == "":
		if has_part("pixl") or has_part("sherloc") or has_part("drill"):
			var crate := Node3D.new()
			crate.position = Vector3(0.5, deck_y, -0.2)
			body.add_child(crate)
			tool_meshes(crate, true)
		return
	var reach := 0.82 if kind == "arm_ext" else 0.58
	var g := group(kind)
	shoulder = Node3D.new()
	shoulder.position = Vector3(dims.x * 0.5 + 0.04, 0.5 + dims.y * 0.55, -dims.z * 0.5 + 0.2)
	g.add_child(shoulder)
	cyl(shoulder, 0.1, 0.1, 0.14, Vector3.ZERO, C_ORANGE, Vector3.ZERO, 8)
	var upper := Node3D.new()
	upper.name = "Upper"
	shoulder.add_child(upper)
	box(upper, Vector3(reach, 0.09, 0.09), Vector3(reach * 0.5, 0, 0), C_BODY)
	elbow = Node3D.new()
	elbow.position = Vector3(reach, 0, 0)
	upper.add_child(elbow)
	cyl(elbow, 0.075, 0.075, 0.14, Vector3.ZERO, C_ORANGE, Vector3(PI * 0.5, 0, 0), 8)
	box(elbow, Vector3(reach, 0.075, 0.075), Vector3(reach * 0.5, 0, 0), C_BODY if kind == "arm_std" else C_METAL)
	turret = Node3D.new()
	turret.position = Vector3(reach, 0, 0)
	elbow.add_child(turret)
	cyl(turret, 0.11, 0.11, 0.1, Vector3.ZERO, C_DARK, Vector3(0, 0, PI * 0.5), 8)
	tool_meshes(turret, false)
	apply_arm()

func make_comms() -> void:
	if has_part("hga"):
		var g := group("hga")
		var post := Vector3(-dims.x * 0.5 + 0.34, deck_y, -dims.z * 0.5 + 0.26)
		cyl(g, 0.035, 0.045, 0.34, post + Vector3(0, 0.17, 0), C_METAL, Vector3.ZERO, 6)
		dish = Node3D.new()
		dish.position = post + Vector3(0, 0.4, 0)
		dish.rotation = Vector3(0, 0, deg_to_rad(50))
		g.add_child(dish)
		cyl(dish, 0.36, 0.2, 0.07, Vector3.ZERO, C_BODY, Vector3.ZERO, 6)
		cyl(dish, 0.3, 0.3, 0.012, Vector3(0, 0.04, 0), C_GOLD, Vector3.ZERO, 6)
		cyl(dish, 0.02, 0.02, 0.2, Vector3(0, 0.14, 0), C_DARK, Vector3.ZERO, 5)
	if has_part("uhf"):
		var g2 := group("uhf")
		var foot := Vector3(-dims.x * 0.5 + 0.16, deck_y, dims.z * 0.5 - 0.18)
		cyl(g2, 0.04, 0.05, 0.5, foot + Vector3(0, 0.25, 0), C_BODY, Vector3.ZERO, 6)
		cyl(g2, 0.065, 0.065, 0.05, foot + Vector3(0, 0.5, 0), C_ORANGE, Vector3.ZERO, 6)
		cyl(g2, 0.07, 0.08, 0.06, foot + Vector3(0, 0.03, 0), C_DARK, Vector3.ZERO, 6)

func make_effects() -> void:
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(C_MINT, 0.0)
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(3):
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.9
		torus.outer_radius = 1.0
		torus.rings = 18
		torus.ring_segments = 4
		ring.mesh = torus
		ring.material_override = ring_mat.duplicate()
		ring.visible = false
		add_child(ring)
		rings.append(ring)
	beam = MeshInstance3D.new()
	var line := CylinderMesh.new()
	line.top_radius = 0.02
	line.bottom_radius = 0.02
	line.height = 1.0
	line.radial_segments = 5
	beam.mesh = line
	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.albedo_color = Color("#ff6b5e")
	beam.material_override = beam_mat
	beam.visible = false
	add_child(beam)

# ------------------------------------------------------------------ animación
func apply_arm() -> void:
	if shoulder == null: return
	shoulder.rotation = Vector3(0, arm_pose.x, 0)
	(shoulder.get_node("Upper") as Node3D).rotation = Vector3(0, 0, arm_pose.y)
	elbow.rotation = Vector3(0, 0, -arm_pose.z)

## Avance del rover: gira las ruedas según la distancia recorrida y orienta las de las esquinas.
func drive(distance: float, steer: float, delta: float) -> void:
	steer_now = lerpf(steer_now, clampf(steer, -0.6, 0.6), clampf(delta * 8.0, 0.0, 1.0))
	for wheel in wheels:
		(wheel.spin as Node3D).rotate_z(-distance / float(wheel.radius))
		(wheel.steer as Node3D).rotation.y = -steer_now * float(wheel.front)

## Suspensión: altura del terreno bajo cada rueda (relativa al centro) y balanceo del cuerpo.
func settle(lifts: Array, delta: float) -> void:
	var blend := clampf(delta * 12.0, 0.0, 1.0)
	var front := 0.0
	var rear := 0.0
	var left := 0.0
	var right := 0.0
	for i in range(mini(lifts.size(), wheels.size())):
		var wheel: Dictionary = wheels[i]
		wheel.lift = lerpf(float(wheel.lift), clampf(float(lifts[i]), -0.22, 0.22), blend)
		(wheel.root as Node3D).position.y = (wheel.base as Vector3).y + float(wheel.lift)
		if float(wheel.front) > 0.0: front += float(wheel.lift)
		elif float(wheel.front) < 0.0: rear += float(wheel.lift)
		if (wheel.base as Vector3).z < 0.0: left += float(wheel.lift)
		else: right += float(wheel.lift)
	body.rotation.z = lerpf(body.rotation.z, clampf((front - rear) * 0.22, -0.12, 0.12), blend)
	body.rotation.x = lerpf(body.rotation.x, clampf((right - left) * 0.16, -0.1, 0.1), blend)

func set_action(kind: String, target: Vector3 = Vector3(1.6, 0.2, 0.0)) -> void:
	if kind != action: action_time = 0.0
	action = kind
	target_local = target

func _process(delta: float) -> void:
	clock += delta
	action_time += delta
	var blend := clampf(delta * 6.0, 0.0, 1.0)
	if body != null:
		for wheel in wheels: (wheel.root as Node3D).position.y = (wheel.base as Vector3).y + float(wheel.lift)
		body.position.y = lerpf(body.position.y, bob, blend)
	# cabeza: barre el entorno al fotografiar o disparar el láser
	if head != null:
		var aim := atan2(-target_local.z, target_local.x) if action in ["image", "laser"] else sin(clock * 0.5) * 0.25
		if action == "image": aim += sin(action_time * 4.0) * 0.18
		head.rotation.y = lerp_angle(head.rotation.y, aim, blend)
		head.rotation.z = lerpf(head.rotation.z, -0.3 if action in ["image", "laser"] else 0.0, blend)
	if puck != null: puck.rotate_y(delta * 3.0)
	# brazo: se despliega hacia el objetivo para contacto y perforación
	if shoulder != null:
		var want := Vector3(1.45, 0.25, 2.5)
		if action in ["arm", "drill"]:
			var flat := Vector2(target_local.x - shoulder.position.x, target_local.z - shoulder.position.z)
			want = Vector3(atan2(-flat.y, flat.x), -0.5 + sin(action_time * 2.0) * 0.04, 0.9)
		arm_pose = arm_pose.lerp(want, clampf(delta * 4.0, 0.0, 1.0))
		apply_arm()
	if drill_bit != null and action == "drill": drill_bit.rotate_x(delta * 26.0)
	# antena de alta ganancia: apunta arriba y oscila al transmitir
	if dish != null:
		var tilt := deg_to_rad(28) if action == "transmit" else deg_to_rad(50)
		dish.rotation.z = lerpf(dish.rotation.z, tilt, blend)
		dish.rotation.y = lerp_angle(dish.rotation.y, clock * 0.4 if action == "transmit" else 0.0, blend)
	for i in range(rings.size()):
		var ring: MeshInstance3D = rings[i]
		var on := action in ["transmit", "radar", "moxie"]
		ring.visible = on
		if not on: continue
		var phase := fmod(action_time * 0.7 + i / 3.0, 1.0)
		var m: StandardMaterial3D = ring.material_override
		if action == "radar":
			ring.position = Vector3(0, 0.06, 0)
			ring.scale = Vector3.ONE * (0.6 + phase * 2.6)
			m.albedo_color = Color(C_MINT, 0.8 * (1.0 - phase))
		elif action == "moxie":
			ring.position = Vector3(0.3, deck_y + 0.3 + phase * 0.9, -dims.z * 0.5 + 0.22)
			ring.scale = Vector3.ONE * (0.12 + phase * 0.2)
			m.albedo_color = Color(C_GOLD, 0.9 * (1.0 - phase))
		else:
			ring.position = Vector3(-dims.x * 0.5 + 0.2, deck_y + 0.6 + phase * 1.8, 0)
			ring.scale = Vector3.ONE * (0.15 + phase * 0.55)
			m.albedo_color = Color(C_MINT, 0.9 * (1.0 - phase))
	if beam != null:
		beam.visible = action == "laser" and head != null and fmod(action_time, 0.5) < 0.32
		if beam.visible:
			var from := head.global_position + Vector3(0, 0.33, 0) - global_position
			from = global_transform.basis.inverse() * from
			var to := target_local
			beam.position = (from + to) * 0.5
			beam.scale = Vector3(1, from.distance_to(to), 1)
			var dir := (to - from).normalized()
			beam.rotation = Vector3(0, atan2(-dir.z, dir.x), asin(clampf(dir.y, -1.0, 1.0)) - PI * 0.5)
	if glow_id != "":
		glow_left -= delta
		var level := 0.25 + 0.3 * (0.5 + 0.5 * sin(clock * 9.0))
		if glow_mat != null: glow_mat.albedo_color = Color(C_MINT, level * clampf(glow_left * 2.0, 0.0, 1.0))
		if glow_left <= 0.0: highlight("")

# ------------------------------------------------------------------ taller: resaltar y ensamblar
func meshes_of(id: String) -> Array:
	var out: Array = []
	for node in parts.get(id, []):
		if not is_instance_valid(node): continue
		if node is MeshInstance3D: out.append(node)
		out += (node as Node).find_children("*", "MeshInstance3D", true, false)
	return out.filter(func(mesh: Variant) -> bool: return not (mesh as Node).has_meta("hull"))

## Resalta dónde va instalada una pieza (brillo pulsante). "" lo apaga.
func highlight(id: String, seconds: float = 2.4) -> void:
	if glow_id != "":
		for mesh in meshes_of(glow_id): (mesh as MeshInstance3D).material_overlay = null
	glow_id = id if parts.has(id) else ""
	glow_left = seconds
	if glow_id == "": return
	if glow_mat == null:
		glow_mat = StandardMaterial3D.new()
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.albedo_color = Color(C_MINT, 0.4)
	for mesh in meshes_of(glow_id): (mesh as MeshInstance3D).material_overlay = glow_mat

## Punto del modelo (coordenadas locales) donde está la pieza; sirve para el marcador del taller.
func anchor(id: String) -> Vector3:
	var list: Array = meshes_of(id)
	if list.is_empty(): return Vector3(0, deck_y + 0.4, 0)
	var sum := Vector3.ZERO
	for mesh in list: sum += to_local((mesh as MeshInstance3D).global_position)
	return sum / list.size()

## Animación de ensamblaje: la pieza cae a su sitio con un pequeño rebote.
func pop(id: String) -> void:
	if Game.reduced_motion: return
	for node in parts.get(id, []):
		if not is_instance_valid(node): continue
		var n := node as Node3D
		var home := n.position
		var size := n.scale
		n.position = home + Vector3(0, 0.55, 0)
		n.scale = size * 0.6
		var tween := n.create_tween().set_parallel(true)
		tween.tween_property(n, "position", home, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(n, "scale", size, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
