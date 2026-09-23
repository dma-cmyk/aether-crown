class_name ProductionTerrain
extends Node3D
## Phase 2.10: Gemini Production Terrain Foundation integration.
##
## Single source of truth for the canonical-match terrain:
## - Loads the 140x140 production GLB (visual, PBR textured).
## - Loads the 141x141 16-bit heightmap and exposes get_height() via
##   bilinear sampling (same parametric field Blender baked).
## - Builds a low-res (2m step) heightfield collision surface so units /
##   walkers / projectiles interact with the real elevation.
## - Builds the MapNav NavigationMesh directly from the heightfield with a
##   slope walkability gate (cliffs / ravine walls unpathable, bridge deck
##   walkable).
##
## Coordinate frame matches the Blender generator:
## X/Z in [-70, 70], heightmap pixel (ix, iz) = world (-70 + ix, -70 + iz).

const TerrainGLB: PackedScene = preload("res://assets/models/map/aether_crown_terrain_foundation.glb")
const HEIGHTMAP_PATH: String = "res://../blender/exports/map/aether_crown_terrain_heightmap.png"

const MAP_HALF: float = 70.0
const GRID_N: int = 141
const HEIGHT_MIN: float = 0.0
const HEIGHT_MAX: float = 26.0
## Collision heightfield resolution (m). Half of the source 1m grid: enough
## for cliff faces (2m of horizontal run per step) at ~4.9k verts / 9.8k tris.
const COL_STEP: float = 2.0
## Navmesh slope gate: a nav quad is walkable only if its steepest edge is
## below this rise/run. 0.60 (~31 deg) accepts the authored ramps while
## rejecting ravine / plateau cliff walls (>= ~1.8 rise per 3m run).
const NAV_MAX_SLOPE: float = 0.60

var _heights: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	add_to_group("production_terrain")


## Loads the heightmap only. The map calls this first so height queries
## (and override registration) work before collision/nav are built.
func load_data() -> void:
	_load_heightmap()


## Spawns GLB visual + collision. Collision heights are sampled through
## `height_fn` (MapNav.get_ground_height: terrain + deck/ramp overrides)
## so physics, navmesh and ground-snap share ONE height field.
func build(visual_parent: Node3D, collision_parent: Node3D, height_fn: Callable) -> void:
	_load_heightmap()
	_spawn_visual(visual_parent)
	_build_collision(collision_parent, height_fn)


func _spawn_visual(visual_parent: Node3D) -> void:
	var inst := TerrainGLB.instantiate() as Node3D
	inst.name = "ProductionTerrainVisual"
	visual_parent.add_child(inst)


## 16-bit grayscale heightmap -> metric heights. Values are normalized to
## [HEIGHT_MIN, HEIGHT_MAX] by the Blender exporter.
func _load_heightmap() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(HEIGHTMAP_PATH))
	if img == null:
		push_error("PRODUCTION_TERRAIN: heightmap load failed: " + HEIGHTMAP_PATH)
		return
	if img.get_width() != GRID_N or img.get_height() != GRID_N:
		push_error("PRODUCTION_TERRAIN: heightmap size %dx%d != %d" % [img.get_width(), img.get_height(), GRID_N])
		return
	_heights.resize(GRID_N * GRID_N)
	for iz in range(GRID_N):
		for ix in range(GRID_N):
			var v: float = img.get_pixel(ix, iz).r
			_heights[iz * GRID_N + ix] = HEIGHT_MIN + v * (HEIGHT_MAX - HEIGHT_MIN)
	print("PRODUCTION_TERRAIN_HEIGHTMAP ok n=%d h[center]=%.2f" % [GRID_N, get_height(0.0, 0.0)])


## Bilinear height sample at world (x, z). Outside the map -> 0.
func get_height(x: float, z: float) -> float:
	if _heights.is_empty():
		return 0.0
	var fx: float = clampf(x + MAP_HALF, 0.0, float(GRID_N - 1))
	var fz: float = clampf(z + MAP_HALF, 0.0, float(GRID_N - 1))
	var ix: int = int(fx)
	var iz: int = int(fz)
	var ix1: int = mini(ix + 1, GRID_N - 1)
	var iz1: int = mini(iz + 1, GRID_N - 1)
	var tx: float = fx - float(ix)
	var tz: float = fz - float(iz)
	var h00: float = _heights[iz * GRID_N + ix]
	var h10: float = _heights[iz * GRID_N + ix1]
	var h01: float = _heights[iz1 * GRID_N + ix]
	var h11: float = _heights[iz1 * GRID_N + ix1]
	var hx0: float = lerpf(h00, h10, tx)
	var hx1: float = lerpf(h01, h11, tx)
	return lerpf(hx0, hx1, tz)


## --- Collision -------------------------------------------------------------
## Low-res concave heightfield (COL_STEP). Concave trimesh is the standard
## static terrain collider; 9.8k tris is trivial for static physics.

func _build_collision(collision_parent: Node3D, height_fn: Callable) -> void:
	var n: int = int(MAP_HALF * 2.0 / COL_STEP)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in range(n):
		for ix in range(n):
			var x0: float = -MAP_HALF + float(ix) * COL_STEP
			var z0: float = -MAP_HALF + float(iz) * COL_STEP
			var x1: float = x0 + COL_STEP
			var z1: float = z0 + COL_STEP
			var p00 := Vector3(x0, float(height_fn.call(x0, z0)), z0)
			var p10 := Vector3(x1, float(height_fn.call(x1, z0)), z0)
			var p01 := Vector3(x0, float(height_fn.call(x0, z1)), z1)
			var p11 := Vector3(x1, float(height_fn.call(x1, z1)), z1)
			# Godot front faces are clockwise: order verts so the normal
			# points +Y (same winding as MapNav's proven ground builder).
			# NOTE: add_triangle_fan produces non-collidable geometry for
			# ConcavePolygonShape3D — plain add_vertex triplets only.
			st.add_vertex(p00)
			st.add_vertex(p10)
			st.add_vertex(p01)
			st.add_vertex(p10)
			st.add_vertex(p11)
			st.add_vertex(p01)
	var mesh: ArrayMesh = st.commit()
	var body := StaticBody3D.new()
	body.name = "ProductionTerrainBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var concave := ConcavePolygonShape3D.new()
	concave.set_faces(mesh.get_faces())
	col.shape = concave
	body.add_child(col)
	collision_parent.add_child(body)
	print("PRODUCTION_TERRAIN_COLLISION ok tris=%d" % int(mesh.get_faces().size() / 3))


## --- Navmesh ---------------------------------------------------------------
## Replaces MapNav's analytic grid. Same 3m cell convention and obstacle
## cutout, but vertices ride the real heightfield and quads failing the
## slope gate are dropped (cliffs / ravine walls become unpathable, so
## infantry routes follow the authored ramps and the bridge deck).

func build_navmesh(map_nav: MapNav) -> void:
	var step: float = MapNav.NAV_STEP
	var n: int = int(MAP_HALF * 2.0 / step)
	var index_of: Dictionary = {}
	var verts := PackedVector3Array()
	for iz in range(n + 1):
		for ix in range(n + 1):
			var x: float = -MAP_HALF + float(ix) * step
			var z: float = -MAP_HALF + float(iz) * step
			index_of[Vector2i(ix, iz)] = verts.size()
			verts.append(Vector3(x, map_nav.get_ground_height(x, z) + 0.15, z))
	var navmesh := NavigationMesh.new()
	navmesh.vertices = verts
	navmesh.agent_radius = 0.4
	navmesh.agent_height = 1.7
	var quads := 0
	var slope_cut := 0
	for iz in range(n):
		for ix in range(n):
			var cx: float = -MAP_HALF + (float(ix) + 0.5) * step
			var cz: float = -MAP_HALF + (float(iz) + 0.5) * step
			if map_nav.is_blocked(cx, cz):
				continue
			var i00 := Vector2i(ix, iz)
			var i01 := Vector2i(ix, iz + 1)
			var i11 := Vector2i(ix + 1, iz + 1)
			var i10 := Vector2i(ix + 1, iz)
			var h00: float = map_nav.get_ground_height(cx - step * 0.5, cz - step * 0.5)
			var h10: float = map_nav.get_ground_height(cx + step * 0.5, cz - step * 0.5)
			var h01: float = map_nav.get_ground_height(cx - step * 0.5, cz + step * 0.5)
			var h11: float = map_nav.get_ground_height(cx + step * 0.5, cz + step * 0.5)
			var max_rise: float = maxf(
				maxf(absf(h10 - h00), absf(h11 - h01)),
				maxf(absf(h01 - h00), absf(h11 - h10)))
			if max_rise / step > NAV_MAX_SLOPE:
				slope_cut += 1
				continue
			var poly := PackedInt32Array([
				int(index_of[i00]),
				int(index_of[i01]),
				int(index_of[i11]),
				int(index_of[i10]),
			])
			navmesh.add_polygon(poly)
			quads += 1
	map_nav.navigation_mesh = navmesh
	print("MAPNAV_READY quads=%d slope_cut=%d obstacles=%d" % [quads, slope_cut, map_nav._circles.size() + map_nav._rects.size()])
