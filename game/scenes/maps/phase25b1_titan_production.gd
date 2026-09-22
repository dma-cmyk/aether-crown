extends Node3D
## Phase 2.5B.1 production showcase: real VisualTitan (collision r3.0 +
## distance LOD) with scale infantry for footprint/selection checks.
## Gameplay/balance untouched; main scenes unchanged.
##
## Capture (windowed, Iris Xe):
##   godot --path game res://scenes/maps/phase25b1_titan_production.tscn -- --capture-25b1
## Benchmarks:
##   ... -- --benchmark-25b1        (auto LOD, strategic distance)
##   ... -- --benchmark-25b1-lod0   (forced LOD0)
##   ... -- --benchmark-25b1-lod1   (forced LOD1)
##   ... -- --benchmark-25b1 --stress-25b1  (3 titans, auto LOD)

const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

const SCREENSHOT_DIR := "res://../docs/screenshots/phase25b1"

var titan: VisualTitan
var extra_titans: Array = []
var _fps_min := 9999
var _fps_sum := 0
var _fps_samples := 0
var _elapsed := 0.0
var _capture_active := false
var _benchmark_active := false
var _benchmark_reported := false
var _force_lod := -1

@onready var rig: Node3D = $CameraRig
@onready var readout: Label = $HUD/Readout


func _ready() -> void:
	add_to_group("titan_production_showcase")
	_build_ground()
	_spawn_titan(Vector3.ZERO)
	_place_scale_units()
	_set_view(26.0, Vector3.ZERO)
	var args := OS.get_cmdline_user_args()
	if args.has("--benchmark-25b1-lod0"):
		_force_lod = 0
	elif args.has("--benchmark-25b1-lod1"):
		_force_lod = 1
	if _force_lod >= 0:
		titan.set_lod(_force_lod)
	if args.has("--stress-25b1"):
		_spawn_titan(Vector3(-14, 0, -6))
		_spawn_titan(Vector3(14, 0, -6))
	if args.has("--capture-25b1"):
		_capture_active = true
		call_deferred("_capture_set")
	elif args.has("--benchmark-25b1") or _force_lod >= 0:
		_benchmark_active = true
		if args.has("--res-720p"):
			DisplayServer.window_set_size(Vector2i(1280, 720))
		else:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		_set_view(43.0, Vector3.ZERO)
		print("PHASE25B1_BENCHMARK_START warmup=3s duration=15s force_lod=%d stress=%s" % [
			_force_lod, str(args.has("--stress-25b1"))
		])
	print("PHASE25B1_SHOWCASE_READY titan=%s lod=%d collision_r=%.1f extra=%d" % [
		str(titan != null), titan.lod_level, _collision_radius(), extra_titans.size()
	])


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	if _elapsed > 3.0 and fps > 0:
		_fps_min = mini(_fps_min, fps)
		_fps_sum += fps
		_fps_samples += 1
	if readout != null:
		readout.text = "LOD%d // collision r3.0 // FPS %d" % [titan.lod_level, fps]
	if _benchmark_active and not _benchmark_reported and _elapsed >= 15.0:
		_benchmark_reported = true
		var average := _fps_sum / maxi(1, _fps_samples)
		print("PHASE25B1_BENCHMARK_DONE fps_min=%d fps_avg=%d samples=%d lod=%d" % [
			_fps_min, average, _fps_samples, titan.lod_level
		])
		get_tree().quit(0)


func _collision_radius() -> float:
	for c in titan.get_children():
		var cs := c as CollisionShape3D
		if cs != null and cs.shape is CylinderShape3D:
			return (cs.shape as CylinderShape3D).radius
	return -1.0


func _mat(color: Color, metallic := 0.0, roughness := 0.8, emission := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material


func _build_ground() -> void:
	var ground_mat := _mat(Color(0.105, 0.125, 0.12, 1.0), 0.0, 0.98)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(220, 220)
	ground.mesh = plane
	ground.material_override = ground_mat
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(ground)
	# Footprint reference rings: collision r3.0 (inner, gameplay) vs
	# visual half-width 3.88 (outer). Static dressing only.
	var inner := _mat(Color(0.2, 0.7, 1.0, 1.0), 0.0, 0.6, 1.5)
	_add_flat_ring($GroundRoot, 3.0, inner)
	var outer := _mat(Color(1.0, 0.6, 0.2, 1.0), 0.0, 0.6, 1.5)
	_add_flat_ring($GroundRoot, 3.88, outer)


func _add_flat_ring(parent: Node3D, radius: float, material: Material) -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.05
	mesh.outer_radius = radius + 0.05
	mesh.rings = 48
	mesh.ring_segments = 6
	ring.mesh = mesh
	ring.material_override = material
	ring.position = Vector3(0, 0.05, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)


func _spawn_titan(pos: Vector3) -> VisualTitan:
	var t := VisualTitan.new()
	t.setup(true, pos, pos)
	t.hold_position = true
	$TitanRoot.add_child(t)
	t.position = pos
	if titan == null:
		titan = t
	else:
		extra_titans.append(t)
	return t


func _place_scale_units() -> void:
	# Four infantry just outside the r3.0 footprint (+body r0.35): they must
	# read as standing clear of the hull, not clipping into the feet.
	var positions := [
		Vector3(3.6, 0, 1.2), Vector3(-3.6, 0, 1.2),
		Vector3(0.6, 0, -3.7), Vector3(-0.6, 0, 3.7),
	]
	for i in range(positions.size()):
		var unit := InfantryScene.instantiate() as RTSUnit
		unit.name = "FootprintInfantry%02d" % i
		unit.setup(InfantryDef, true)
		unit.position = positions[i]
		unit.rotation.y = atan2(-positions[i].x, -positions[i].z) + PI
		$UnitsRoot.add_child(unit)
		unit.process_mode = Node.PROCESS_MODE_DISABLED


func _all_meshes(node: Node) -> Array:
	var result: Array = []
	if node is GeometryInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_all_meshes(child))
	return result


func _set_view(distance: float, target: Vector3) -> void:
	rig.set("distance", distance)
	rig.position = Vector3(target.x, 0.0, target.z + distance)
	rig.call("_update_camera_offset")


func _capture(name_text: String) -> void:
	for i in range(12):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(SCREENSHOT_DIR.path_join(name_text + ".png"))
	var error := get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		push_error("CAPTURE_FAILED %s error=%d" % [path, error])
	else:
		print("PHASE25B1_CAPTURE_OK ", path)


func _capture_set() -> void:
	var absolute_dir := ProjectSettings.globalize_path(SCREENSHOT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	$HUD.visible = false
	get_tree().debug_collisions_hint = true
	await get_tree().create_timer(1.0).timeout

	titan.set_lod(0)
	titan.set_selected(false)
	_set_view(19.0, Vector3.ZERO)
	await _capture("titan_lod0")

	titan.set_lod(1)
	_set_view(19.0, Vector3.ZERO)
	await _capture("titan_lod1")

	# Strategic shot uses the real auto-switch (no lock): distance 43 must
	# settle on LOD1 by itself.
	titan.unlock_lod()
	_set_view(43.0, Vector3.ZERO)
	for i in range(30):
		await get_tree().process_frame
	print("PHASE25B1_AUTO_LOD distance=43 lod=%d (want 1)" % titan.lod_level)
	await _capture("titan_lod_strategic")
	var strategic_lod := titan.lod_level

	# Collision check: selection disc off so the footprint rings (cyan r3.0
	# gameplay collision, orange r3.88 visual half-width) and adjacent
	# infantry read clearly. Debug collision wireframes on.
	titan.set_lod(0)
	titan.set_selected(false)
	_set_view(16.0, Vector3.ZERO)
	await _capture("titan_collision_check")

	var shots := 4
	if OS.get_cmdline_user_args().has("--stress-25b1"):
		_spawn_titan(Vector3(-14, 0, -6))
		_spawn_titan(Vector3(14, 0, -6))
		titan.unlock_lod()
		_set_view(48.0, Vector3(0, 0, -2.0))
		for i in range(30):
			await get_tree().process_frame
		await _capture("titan_multi_stress")
		shots = 5

	print("PHASE25B1_CAPTURE_DONE shots=%d lod_strategic=%d" % [shots, strategic_lod])
	get_tree().quit(0)
