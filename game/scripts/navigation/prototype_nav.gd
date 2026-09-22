class_name PrototypeNav
extends NavigationRegion3D
## Flat navmesh for the prototype battlefield (Phase 2.6). Unlike MapNav it
## builds no ground visual or heightfield: the prototype plane is flat at
## y=0, so get_ground_height is 0 everywhere. Building footprints are
## registered before build() and their cells are cut out of the navmesh.

const MAP_HALF: float = 90.0
const NAV_STEP: float = 3.0
const NAV_MARGIN: float = 0.8

var _rects: Array = [] # each: [Vector2 center, Vector2 size]


func _ready() -> void:
	add_to_group("map_nav")


func register_obstacle_rect(center: Vector3, size: Vector2) -> void:
	_rects.append([Vector2(center.x, center.z), size])


func get_ground_height(_x: float, _z: float) -> float:
	return 0.0


func is_blocked(x: float, z: float) -> bool:
	for r in _rects:
		var center: Vector2 = r[0]
		var half: Vector2 = r[1] * 0.5 + Vector2(NAV_MARGIN, NAV_MARGIN)
		var d: Vector2 = (Vector2(x, z) - center).abs()
		if d.x < half.x and d.y < half.y:
			return true
	return false


func clamp_inside(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, -MAP_HALF + 2.0, MAP_HALF - 2.0)
	pos.z = clampf(pos.z, -MAP_HALF + 2.0, MAP_HALF - 2.0)
	pos.y = 0.0
	return pos


## Same grid construction as MapNav._build_navmesh, minus heightfield.
func build() -> void:
	var n := int(MAP_HALF * 2.0 / NAV_STEP)
	var index_of: Dictionary = {}
	var verts := PackedVector3Array()
	for iz in range(n + 1):
		for ix in range(n + 1):
			var x := -MAP_HALF + float(ix) * NAV_STEP
			var z := -MAP_HALF + float(iz) * NAV_STEP
			index_of[Vector2i(ix, iz)] = verts.size()
			verts.append(Vector3(x, 0.15, z))
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
	print("PROTOTYPE_NAV_READY quads=", quads, " obstacles=", _rects.size())
