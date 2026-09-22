extends Node3D
## Phase 2.5C.1 Crownhammer production showcase: real VisualAirship
## (collision + distance LOD + selection markers) with Titan / HQ /
## infantry scale references. Gameplay/balance untouched.
##
## Capture (windowed, Iris Xe):
##   godot --path game res://scenes/maps/phase25c1_airship_production.tscn -- --capture-25c1
## Benchmarks:
##   ... -- --benchmark-25c1            (auto LOD)
##   ... -- --benchmark-25c1-lod0       (forced LOD0)
##   ... -- --benchmark-25c1-lod1       (forced LOD1)

const TitanGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const HQGLB: PackedScene = preload("res://assets/models/gearforge_hq_command.glb")
const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

const SCREENSHOT_DIR := "res://../docs/screenshots/phase25c1"

var ship: VisualAirship
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
	add_to_group("airship_production_showcase")
	_build_ground()
	_spawn_ship()
	_place_scale_refs()
	_set_view(52.0, Vector3.ZERO)
	var args := OS.get_cmdline_user_args()
	if args.has("--benchmark-25c1-lod0"):
		_force_lod = 0
	elif args.has("--benchmark-25c1-lod1"):
		_force_lod = 1
	if _force_lod >= 0:
		ship.set_lod(_force_lod)
	if args.has("--capture-25c1"):
		_capture_active = true
		call_deferred("_capture_set")
	elif args.has("--benchmark-25c1") or _force_lod >= 0:
		_benchmark_active = true
		if args.has("--res-720p"):
			DisplayServer.window_set_size(Vector2i(1280, 720))
		else:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		print("PHASE25C1_BENCHMARK_START warmup=3s duration=15s force_lod=%d" % _force_lod)
	print("PHASE25C1_SHOWCASE_READY ship=%s lod=%d" % [str(ship != null), ship.lod_level])


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	if _elapsed > 3.0 and fps > 0:
		_fps_min = mini(_fps_min, fps)
		_fps_sum += fps
		_fps_samples += 1
	if readout != null:
		readout.text = "LOD%d // FPS %d" % [ship.lod_level, fps]
	if _benchmark_active and not _benchmark_reported and _elapsed >= 15.0:
		_benchmark_reported = true
		var average := _fps_sum / maxi(1, _fps_samples)
		print("PHASE25C1_BENCHMARK_DONE fps_min=%d fps_avg=%d samples=%d lod=%d" % [
			_fps_min, average, _fps_samples, ship.lod_level
		])
		get_tree().quit(0)


func _mat(color: Color, metallic := 0.0, roughness := 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(220, 220)
	ground.mesh = plane
	ground.material_override = _mat(Color(0.105, 0.125, 0.12, 1.0), 0.0, 0.98)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(ground)


func _spawn_ship() -> void:
	ship = VisualAirship.new()
	ship.name = "ProductionShip"
	ship.is_player = true
	ship.center = Vector3.ZERO
	ship.cruise_height = 26.0
	ship.cruise_radius = 14.0
	ship.cruise_speed = 0.05
	ship.bombard_enabled = false
	$ShipRoot.add_child(ship)
	ship.global_position = Vector3(14, 26.0, 0)


func _place_scale_refs() -> void:
	var titan := TitanGLB.instantiate() as Node3D
	titan.name = "ScaleTitan"
	titan.position = Vector3(-24, 0, -4)
	titan.rotation.y = deg_to_rad(-18.0)
	$ScaleRoot.add_child(titan)
	for c in _all_meshes(titan):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var hq := HQGLB.instantiate() as Node3D
	hq.name = "ScaleHQ"
	hq.position = Vector3(24, 0, -6)
	hq.rotation.y = deg_to_rad(10.0)
	$ScaleRoot.add_child(hq)
	for c in _all_meshes(hq):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for i in range(4):
		var unit := InfantryScene.instantiate() as RTSUnit
		unit.name = "ScaleInfantry%02d" % i
		unit.setup(InfantryDef, true)
		unit.position = Vector3(-6 + float(i) * 2.0, 0, 10)
		unit.rotation.y = PI
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
		print("PHASE25C1_CAPTURE_OK ", path)


func _capture_set() -> void:
	var absolute_dir := ProjectSettings.globalize_path(SCREENSHOT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	$HUD.visible = false
	await get_tree().create_timer(1.0).timeout

	# Overview: whole ship + scale refs.
	ship.unlock_lod()
	_set_view(62.0, Vector3.ZERO)
	for i in range(30):
		await get_tree().process_frame
	await _capture("airship_production_overview")

	# Titan scale: ship holds cruise, titan grounded left.
	_set_view(46.0, Vector3(-12, 0, -2))
	await _capture("airship_titan_scale")

	# Base scale: HQ grounded right.
	_set_view(44.0, Vector3(12, 0, -3))
	await _capture("airship_base_scale")

	# Selection: markers on, closer framing.
	ship.set_selected(true)
	_set_view(40.0, Vector3(4, 0, 0))
	await _capture("airship_selection")

	# LOD0 forced, whole-ship framing.
	ship.set_lod(0)
	_set_view(58.0, Vector3(4, 0, 0))
	await _capture("airship_lod0")

	# LOD1 forced, same framing: pop comparison.
	ship.set_lod(1)
	_set_view(58.0, Vector3(4, 0, 0))
	await _capture("airship_lod1")
	ship.set_selected(false)

	print("PHASE25C1_CAPTURE_DONE shots=6 lod=%d" % ship.lod_level)
	get_tree().quit(0)
