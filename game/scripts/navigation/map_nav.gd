class_name MapNav
extends NavigationRegion3D
## Builds the Phase 1 ground visual + collision + NavigationMesh at runtime.
## Single source of truth for terrain height. Obstacles are registered by the
## map script before build(); their cells are cut out of the navmesh.

const MAP_HALF: float = 60.0
const GROUND_STEP: float = 2.0
const NAV_STEP: float = 3.0
const BASE_FLATTEN_RADIUS: float = 14.0
const NAV_MARGIN: float = 0.6

var player_base: Vector3 = Vector3(-38, 0, -38)
var enemy_base: Vector3 = Vector3(38, 0, 38)

var _circles: Array = [] # each: [Vector2(x,z), radius]
var _rects: Array = [] # each: [Vector2 center, Vector2 size]


func _ready() -> void:
	add_to_group("map_nav")


func register_obstacle_circle(pos: Vector3, radius: float) -> void:
	_circles.append([Vector2(pos.x, pos.z), radius])


func register_obstacle_rect(center: Vector3, size: Vector2) -> void:
	_rects.append([Vector2(center.x, center.z), size])


func get_ground_height(x: float, z: float) -> float:
	var h := 0.8 * sin(x * 0.08) * cos(z * 0.07) + 0.4 * sin(x * 0.21 + z * 0.13)
	var dp := Vector2(x - player_base.x, z - player_base.z).length()
	var de := Vector2(x - enemy_base.x, z - enemy_base.z).length()
	var d := minf(dp, de)
	var f := clampf((d - 6.0) / (BASE_FLATTEN_RADIUS - 6.0), 0.0, 1.0)
	return h * f


func is_blocked(x: float, z: float) -> bool:
	for c in _circles:
		if Vector2(x, z).distance_to(c[0]) < float(c[1]) + NAV_MARGIN:
			return true
	for r in _rects:
		var center: Vector2 = r[0]
		var size: Vector2 = r[1]
		var d: Vector2 = (Vector2(x, z) - center).abs()
		var half: Vector2 = size * 0.5 + Vector2(NAV_MARGIN, NAV_MARGIN)
		if d.x < half.x and d.y < half.y:
			return true
	return false


func clamp_inside(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, -MAP_HALF + 2.0, MAP_HALF - 2.0)
	pos.z = clampf(pos.z, -MAP_HALF + 2.0, MAP_HALF - 2.0)
	pos.y = get_ground_height(pos.x, pos.z)
	return pos


## ground_parent: Node3D to hold the generated ground StaticBody.
func build(ground_parent: Node3D) -> void:
	_build_ground(ground_parent)
	_build_navmesh()


func _grid_count(step: float) -> int:
	return int(MAP_HALF * 2.0 / step)


func _build_ground(ground_parent: Node3D) -> void:
	var n := _grid_count(GROUND_STEP)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in range(n):
		for ix in range(n):
			var x0 := -MAP_HALF + float(ix) * GROUND_STEP
			var z0 := -MAP_HALF + float(iz) * GROUND_STEP
			var x1 := x0 + GROUND_STEP
			var z1 := z0 + GROUND_STEP
			var p00 := Vector3(x0, get_ground_height(x0, z0), z0)
			var p10 := Vector3(x1, get_ground_height(x1, z0), z0)
			var p01 := Vector3(x0, get_ground_height(x0, z1), z1)
			var p11 := Vector3(x1, get_ground_height(x1, z1), z1)
			var uv00 := Vector2(ix, iz) / float(n) * 8.0
			var uv10 := Vector2(ix + 1, iz) / float(n) * 8.0
			var uv01 := Vector2(ix, iz + 1) / float(n) * 8.0
			var uv11 := Vector2(ix + 1, iz + 1) / float(n) * 8.0
			_add_tri(st, p00, p01, p10, uv00, uv01, uv10)
			_add_tri(st, p10, p01, p11, uv10, uv01, uv11)
	st.generate_normals()
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.32, 0.22, 1.0)
	mat.roughness = 0.95
	var mi := MeshInstance3D.new()
	mi.name = "GroundMesh"
	mi.mesh = mesh
	mi.material_override = mat
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var concave := ConcavePolygonShape3D.new()
	concave.set_faces(mesh.get_faces())
	col.shape = concave
	body.add_child(col)
	ground_parent.add_child(body)


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uva: Vector2, uvb: Vector2, uvc: Vector2) -> void:
	st.set_uv(uva)
	st.add_vertex(a)
	st.set_uv(uvb)
	st.add_vertex(b)
	st.set_uv(uvc)
	st.add_vertex(c)


func _build_navmesh() -> void:
	var n := _grid_count(NAV_STEP)
	var index_of: Dictionary = {}
	var verts := PackedVector3Array()
	for iz in range(n + 1):
		for ix in range(n + 1):
			var x := -MAP_HALF + float(ix) * NAV_STEP
			var z := -MAP_HALF + float(iz) * NAV_STEP
			index_of[Vector2i(ix, iz)] = verts.size()
			verts.append(Vector3(x, get_ground_height(x, z) + 0.15, z))
	var navmesh := NavigationMesh.new()
	navmesh.vertices = verts
	navmesh.agent_radius = 0.4
	navmesh.agent_height = 1.7
	var quads := 0
	for iz in range(n):
		for ix in range(n):
			var cx := -MAP_HALF + (float(ix) + 0.5) * NAV_STEP
			var cz := -MAP_HALF + (float(iz) + 0.5) * NAV_STEP
			if is_blocked(cx, cz):
				continue
			var poly := PackedInt32Array([
				int(index_of[Vector2i(ix, iz)]),
				int(index_of[Vector2i(ix, iz + 1)]),
				int(index_of[Vector2i(ix + 1, iz + 1)]),
				int(index_of[Vector2i(ix + 1, iz)]),
			])
			navmesh.add_polygon(poly)
			quads += 1
	navigation_mesh = navmesh
	print("MAPNAV_READY quads=", quads, " obstacles=", _circles.size() + _rects.size())
