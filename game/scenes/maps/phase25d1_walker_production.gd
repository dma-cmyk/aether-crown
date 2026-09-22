extends Node3D
## Phase 2.5D.1 Ironstride production showcase: real VisualWalker wrappers
## (collision + distance LOD + selection + faction plates) with Titan / HQ /
## infantry scale references. Gameplay/balance untouched.
##
## Capture (windowed, Iris Xe):
##   godot --path game res://scenes/maps/phase25d1_walker_production.tscn -- --capture-25d1
## Benchmarks:
##   ... -- --benchmark-25d1            (auto LOD)
##   ... -- --benchmark-25d1-lod0       (forced LOD0)
##   ... -- --benchmark-25d1-lod1       (forced LOD1)

const TitanGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const HQGLB: PackedScene = preload("res://assets/models/gearforge_hq_command.glb")
const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

const SCREENSHOT_DIR := "res://../docs/screenshots/phase25d1"

var walker_blue: VisualWalker
var walker_red: VisualWalker
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
	add_to_group("walker_production_showcase")
	_build_ground()
	_spawn_walkers()
	_place_scale_refs()
	_set_view(22.0, Vector3.ZERO)
	var args := OS.get_cmdline_user_args()
	if args.has("--benchmark-25d1-lod0"):
		_force_lod = 0
	elif args.has("--benchmark-25d1-lod1"):
		_force_lod = 1
	if _force_lod >= 0:
		walker_blue.set_lod(_force_lod)
		walker_red.set_lod(_force_lod)
	if args.has("--capture-25d1"):
		_capture_active = true
		call_deferred("_capture_set")
	elif args.has("--benchmark-25d1") or _force_lod >= 0:
		_benchmark_active = true
		if args.has("--res-720p"):
			DisplayServer.window_set_size(Vector2i(1280, 720))
		else:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		print("PHASE25D1_BENCHMARK_START warmup=3s duration=15s force_lod=%d" % _force_lod)
	print("PHASE25D1_SHOWCASE_READY blue=%s red=%s" % [str(walker_blue != null), str(walker_red != null)])


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	if _elapsed > 3.0 and fps > 0:
		_fps_min = mini(_fps_min, fps)
		_fps_sum += fps
		_fps_samples += 1
	if readout != null:
		readout.text = "LOD%d // FPS %d" % [walker_blue.lod_level, fps]
	if _benchmark_active and not _benchmark_reported and _elapsed >= 15.0:
		_benchmark_reported = true
		var average := _fps_sum / maxi(1, _fps_samples)
		print("PHASE25D1_BENCHMARK_DONE fps_min=%d fps_avg=%d samples=%d lod=%d" % [
			_fps_min, average, _fps_samples, walker_blue.lod_level
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
	plane.size = Vector2(160, 160)
	ground.mesh = plane
	ground.material_override = _mat(Color(0.105, 0.125, 0.12, 1.0), 0.0, 0.98)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(ground)


func _spawn_walkers() -> void:
	walker_blue = VisualWalker.new()
	walker_blue.name = "WalkerBlue"
	walker_blue.setup(true)
	$WalkerRoot.add_child(walker_blue)
	walker_blue.position = Vector3(-3.2, 0, 0)
	walker_blue.rotation.y = deg_to_rad(-14.0)
	walker_red = VisualWalker.new()
	walker_red.name = "WalkerRed"
	walker_red.setup(false)
	$WalkerRoot.add_child(walker_red)
	walker_red.position = Vector3(3.4, 0, -1.0)
	walker_red.rotation.y = deg_to_rad(168.0)


func _place_scale_refs() -> void:
	var titan := TitanGLB.instantiate() as Node3D
	titan.name = "ScaleTitan"
	titan.position = Vector3(-13, 0, -8)
	titan.rotation.y = deg_to_rad(-18.0)
	$ScaleRoot.add_child(titan)
	for c in _all_meshes(titan):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var hq := HQGLB.instantiate() as Node3D
	hq.name = "ScaleHQ"
	hq.position = Vector3(13, 0, -10)
	hq.rotation.y = deg_to_rad(10.0)
	$ScaleRoot.add_child(hq)
	for c in _all_meshes(hq):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for i in range(4):
		var unit := InfantryScene.instantiate() as RTSUnit
		unit.name = "ScaleInfantry%02d" % i
		unit.setup(InfantryDef, true)
		unit.position = Vector3(-3.0 + float(i) * 1.8, 0, 5.5)
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
		print("PHASE25D1_CAPTURE_OK ", path)


func _capture_set() -> void:
	var absolute_dir := ProjectSettings.globalize_path(SCREENSHOT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	$HUD.visible = false
	await get_tree().create_timer(1.0).timeout

	# Overview: both walkers + scale refs.
	walker_blue.unlock_lod()
	walker_red.unlock_lod()
	_set_view(26.0, Vector3.ZERO)
	for i in range(30):
		await get_tree().process_frame
	await _capture("walker_production_overview")

	# Selection: blue selected (ring + HP bar), red plain.
	walker_blue.set_selected(true)
	_set_view(15.0, Vector3(-2, 0, 0))
	await _capture("walker_selection")

	# LOD0 forced, close framing.
	walker_blue.set_lod(0)
	walker_red.set_lod(0)
	_set_view(13.0, Vector3(-2, 0, 0))
	await _capture("walker_lod0")

	# LOD1 forced, same framing: pop comparison.
	walker_blue.set_lod(1)
	walker_red.set_lod(1)
	_set_view(13.0, Vector3(-2, 0, 0))
	await _capture("walker_lod1")
	walker_blue.set_selected(false)

	# Titan scale: walker vs 11.39 m Titan.
	walker_blue.unlock_lod()
	walker_red.unlock_lod()
	_set_view(24.0, Vector3(-8, 0, -4))
	await _capture("walker_titan_scale")

	# Frontline integration: walkers + infantry + HQ mass.
	_set_view(30.0, Vector3(4, 0, -2))
	await _capture("walker_frontline_integration")

	print("PHASE25D1_CAPTURE_DONE shots=6")
	get_tree().quit(0)
