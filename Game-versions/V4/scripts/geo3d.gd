class_name Geo3D
## Utilidades 3D de 2Mars (V4): materiales planos con contorno oscuro, primitivas, rocas
## low-poly, mallas de terreno con sombreado plano y fondos de cielo. Todo es geometría
## generada por código: no hay modelos importados.

const INK := Color("#191922")

static var mats := {}
static var hull: StandardMaterial3D
static var rock_meshes: Array = []
static var outline := true     # la calidad baja apaga el contorno

static func mat(color: Color, emission: float = 0.0, vertex_colors: bool = false) -> StandardMaterial3D:
	var key := "%s|%.2f|%s" % [color.to_html(), emission, vertex_colors]
	if mats.has(key): return mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.86
	m.vertex_color_use_as_albedo = vertex_colors
	m.vertex_color_is_srgb = vertex_colors
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	mats[key] = m
	return m

static func flat(color: Color, alpha: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	if alpha or color.a < 1.0: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func hull_mat() -> StandardMaterial3D:
	if hull == null:
		hull = StandardMaterial3D.new()
		hull.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hull.albedo_color = INK
		hull.cull_mode = BaseMaterial3D.CULL_FRONT
	return hull

## Contorno por casco escalado: una copia de la malla, algo mayor, que solo dibuja caras traseras.
static func edge_of(node: MeshInstance3D, grow: Vector3) -> void:
	if not outline: return
	var shell := MeshInstance3D.new()
	shell.mesh = node.mesh
	shell.material_override = hull_mat()
	shell.scale = grow
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.set_meta("hull", true)
	node.add_child(shell)

static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO, emission: float = 0.0, edge: float = 0.02) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat(color, emission)
	node.position = pos
	node.rotation = rot
	parent.add_child(node)
	if edge > 0.0: edge_of(node, Vector3(1.0 + 2.0 * edge / size.x, 1.0 + 2.0 * edge / size.y, 1.0 + 2.0 * edge / size.z))
	return node

static func cyl(parent: Node3D, top: float, bottom: float, height: float, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO, segments: int = 10, emission: float = 0.0, edge: float = 0.02) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	node.mesh = mesh
	node.material_override = mat(color, emission)
	node.position = pos
	node.rotation = rot
	parent.add_child(node)
	if edge > 0.0:
		var wide := maxf(maxf(top, bottom), 0.01)
		edge_of(node, Vector3(1.0 + edge / wide, 1.0 + 2.0 * edge / height, 1.0 + edge / wide))
	return node

static func strut(parent: Node3D, a: Vector3, b: Vector3, thick: float, color: Color, edge: float = 0.02) -> MeshInstance3D:
	var node := box(parent, Vector3(maxf(0.01, a.distance_to(b)), thick, thick), (a + b) * 0.5, color, Vector3.ZERO, 0.0, edge)
	var dir := (b - a).normalized()
	node.rotation = Vector3(0.0, atan2(-dir.z, dir.x), asin(clampf(dir.y, -1.0, 1.0)))
	return node

## Roca low-poly: icosaedro deformado con caras planas y un tono por cara.
static func rock_mesh(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + 13
	var t := (1.0 + sqrt(5.0)) * 0.5
	var raw := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var points: Array = []
	for p in raw:
		var v: Vector3 = (p as Vector3).normalized() * rng.randf_range(0.72, 1.12)
		v.y = v.y * 0.78 + 0.08
		points.append(v)
	var faces := [0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for i in range(0, faces.size(), 3):
		var a: Vector3 = points[faces[i]]
		var b: Vector3 = points[faces[i + 2]]
		var c: Vector3 = points[faces[i + 1]]
		var n := (b - a).cross(c - a).normalized()
		if n.dot((a + b + c) / 3.0) < 0.0:
			var swap := b
			b = c
			c = swap
			n = -n
		var tone := rng.randf_range(0.82, 1.08)
		for v in [a, c, b]:
			verts.append(v)
			normals.append(n)
			colors.append(Color(tone, tone, tone))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func rock(parent: Node3D, pos: Vector3, radius: float, seed_value: int, color: Color, squash: float = 1.0, edge: float = 0.05) -> MeshInstance3D:
	if rock_meshes.is_empty():
		for i in range(8): rock_meshes.append(rock_mesh(i + 1))
	var node := MeshInstance3D.new()
	node.mesh = rock_meshes[absi(seed_value) % rock_meshes.size()]
	node.material_override = mat(color, 0.0, true)
	node.position = pos
	node.rotation.y = float(seed_value % 628) * 0.01
	node.scale = Vector3(radius, radius * squash, radius)
	parent.add_child(node)
	if edge > 0.0: edge_of(node, Vector3.ONE * (1.0 + edge / maxf(0.05, radius)))
	return node

## Terreno con caras planas. height y tint son Callables(Vector2 xz) -> float / Color.
static func terrain(area: Rect2, step: float, height: Callable, tint: Callable) -> ArrayMesh:
	var nx := int(ceil(area.size.x / step))
	var nz := int(ceil(area.size.y / step))
	var heights := PackedFloat32Array()
	heights.resize((nx + 1) * (nz + 1))
	for j in range(nz + 1):
		for i in range(nx + 1):
			heights[j * (nx + 1) + i] = height.call(area.position + Vector2(i * step, j * step))
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(nx * nz * 6)
	normals.resize(nx * nz * 6)
	colors.resize(nx * nz * 6)
	var at := 0
	for j in range(nz):
		for i in range(nx):
			var x0 := area.position.x + i * step
			var z0 := area.position.y + j * step
			var p00 := Vector3(x0, heights[j * (nx + 1) + i], z0)
			var p10 := Vector3(x0 + step, heights[j * (nx + 1) + i + 1], z0)
			var p01 := Vector3(x0, heights[(j + 1) * (nx + 1) + i], z0 + step)
			var p11 := Vector3(x0 + step, heights[(j + 1) * (nx + 1) + i + 1], z0 + step)
			var flip := (i + j) % 2 == 0
			var tris := [p00, p10, p11, p00, p11, p01] if flip else [p00, p10, p01, p10, p11, p01]
			for k in range(2):
				var a: Vector3 = tris[k * 3]
				var b: Vector3 = tris[k * 3 + 1]
				var c: Vector3 = tris[k * 3 + 2]
				var n := (c - a).cross(b - a).normalized()
				var mid := (a + b + c) / 3.0
				var col: Color = tint.call(Vector2(mid.x, mid.z), mid.y, n)
				for v in [a, b, c]:
					verts[at] = v
					normals[at] = n
					colors[at] = col
					at += 1
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## Plano vertical con degradado (cielo de fondo). No recibe luz.
static func sky(parent: Node3D, center: Vector3, size: Vector2, top: Color, bottom: Color, mid: Color = Color(0, 0, 0, 0)) -> MeshInstance3D:
	var half := size * 0.5
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var rows := [[-half.y, bottom], [0.0 if mid.a > 0.0 else -half.y, mid if mid.a > 0.0 else bottom], [half.y, top]]
	for r in range(2):
		var y0: float = rows[r][0]
		var y1: float = rows[r + 1][0]
		var c0: Color = rows[r][1]
		var c1: Color = rows[r + 1][1]
		for item in [[-half.x, y0, c0], [half.x, y0, c0], [half.x, y1, c1], [-half.x, y0, c0], [half.x, y1, c1], [-half.x, y1, c1]]:
			verts.append(Vector3(item[0], item[1], 0))
			colors.append(item[2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var m := flat(Color.WHITE)
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	node.material_override = m
	node.position = center
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

## Anillo plano sobre el suelo (marcadores de objetivo, plataformas, sitios de radar).
static func ring(parent: Node3D, pos: Vector3, radius: float, thick: float, color: Color, emission: float = 1.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thick
	torus.outer_radius = radius
	torus.rings = 28
	torus.ring_segments = 4
	node.mesh = torus
	var m := flat(color, true)
	node.material_override = m
	node.position = pos
	node.scale = Vector3(1, 0.25, 1)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.set_meta("emission", emission)
	parent.add_child(node)
	return node

## Globo low-poly (geometría real): malla de latitud/longitud con caras planas y un tono por
## cara. Es una representación artística de Marte, no un mapa de datos.
static func globe_mesh(base: Color, seed_value: int = 4) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 1.1
	var lon_n := 40
	var lat_n := 20
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var point := func(i: int, j: int) -> Vector3:
		var lat := -PI * 0.5 + PI * j / lat_n
		var lon := TAU * i / lon_n
		return Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
	for j in range(lat_n):
		for i in range(lon_n):
			var a: Vector3 = point.call(i, j)
			var b: Vector3 = point.call(i + 1, j)
			var c: Vector3 = point.call(i + 1, j + 1)
			var d: Vector3 = point.call(i, j + 1)
			for tri in [[a, c, b], [a, d, c]]:
				var p0: Vector3 = tri[0]
				var p1: Vector3 = tri[1]
				var p2: Vector3 = tri[2]
				if p0.distance_to(p1) < 0.0001 or p1.distance_to(p2) < 0.0001 or p0.distance_to(p2) < 0.0001: continue
				var mid := ((p0 + p1 + p2) / 3.0).normalized()
				var tone := 0.5 + 0.5 * noise.get_noise_3dv(mid * 2.2) + 0.25 * noise.get_noise_3dv(mid * 6.0 + Vector3(9, 3, 1))
				var col := base.darkened(0.38).lerp(base.lightened(0.18), clampf(tone, 0.0, 1.0))
				if absf(mid.y) > 0.9: col = Color(0.96, 0.9, 0.82)
				for v in [p0, p1, p2]:
					verts.append(v)
					normals.append(mid)
					colors.append(col)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
