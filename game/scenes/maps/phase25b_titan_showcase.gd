extends Node3D
## Phase 2.5B art-only Titan showcase. It uses the production GLB directly,
## keeps gameplay/balance untouched, and can capture the required review set.
## Capture:
## godot --path game res://scenes/maps/phase25b_titan_showcase.tscn -- --capture-phase25b

const TitanGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const CivicGLB: PackedScene = preload("res://assets/models/gearforge_civic_core.glb")
const IndustryGLB: PackedScene = preload("res://assets/models/gearforge_industry_works.glb")
const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

const SCREENSHOT_DIR := "res://../docs/screenshots/phase25b"

var titan: Node3D
var _fps_min := 9999
var _fps_sum := 0
var _fps_samples := 0
var _elapsed := 0.0
var _capture_active := false
var _benchmark_active := false
var _benchmark_reported := false
var _silhouette_material: StandardMaterial3D
var _mesh_overrides: Dictionary = {}

@onready var rig: Node3D = $CameraRig
@onready var readout: Label = $HUD/Readout


func _ready() -> void:
	add_to_group("titan_showcase")
	_build_ground()
	_build_set_dressing()
	_place_titan()
	_place_buildings()
	_place_scale_units()
	_set_view(26.0, Vector3.ZERO, -22.0)
	print("PHASE25B_SHOWCASE_READY titan=%s meshes=%d units=%d" % [
		str(titan != null), _all_meshes(titan).size(), $UnitsRoot.get_child_count()
	])
	if OS.get_cmdline_user_args().has("--capture-phase25b"):
		_capture_active = true
		call_deferred("_capture_set")
	elif OS.get_cmdline_user_args().has("--benchmark-phase25b"):
		_benchmark_active = true
		print("PHASE25B_BENCHMARK_START warmup=3s duration=15s")


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	if _elapsed > 3.0 and fps > 0:
		_fps_min = mini(_fps_min, fps)
		_fps_sum += fps
		_fps_samples += 1
	if readout != null:
		readout.text = "11.39m // CROWNSPIKE AETHER SIEGE CANNON // FPS %d" % fps
	if _benchmark_active and not _benchmark_reported and _elapsed >= 15.0:
		_benchmark_reported = true
		var average := _fps_sum / maxi(1, _fps_samples)
		print("PHASE25B_BENCHMARK_DONE fps_min=%d fps_avg=%d samples=%d" % [
			_fps_min, average, _fps_samples
		])
		get_tree().quit(0)


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


func _box(parent: Node3D, name_text: String, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = name_text
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = pos
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(item)
	return item


func _cylinder(parent: Node3D, name_text: String, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = name_text
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	item.mesh = mesh
	item.position = pos
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(item)
	return item


func _build_ground() -> void:
	var ground_mat := _mat(Color(0.105, 0.125, 0.12, 1.0), 0.0, 0.98)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100, 100)
	ground.mesh = plane
	ground.material_override = ground_mat
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(ground)

	var iron := _mat(Color(0.16, 0.17, 0.19, 1.0), 0.75, 0.62)
	var steel := _mat(Color(0.31, 0.33, 0.37, 1.0), 0.8, 0.45)
	var brass := _mat(Color(0.50, 0.34, 0.12, 1.0), 0.8, 0.45)
	_box($GroundRoot, "TitanApron", Vector3(23.0, 0.30, 20.0), Vector3(0, -0.16, 0), iron)
	for x in [-7.5, -2.5, 2.5, 7.5]:
		_box($GroundRoot, "DeckSeamX", Vector3(0.10, 0.04, 19.5), Vector3(x, 0.02, 0), steel)
	for z in [-7.0, 0.0, 7.0]:
		_box($GroundRoot, "DeckSeamZ", Vector3(22.5, 0.04, 0.10), Vector3(0, 0.025, z), steel)
	for x in [-10.8, 10.8]:
		_box($GroundRoot, "ApronEdge", Vector3(0.24, 0.16, 20.2), Vector3(x, 0.06, 0), brass)


func _build_set_dressing() -> void:
	var iron := _mat(Color(0.19, 0.20, 0.23, 1.0), 0.72, 0.62)
	var copper := _mat(Color(0.52, 0.25, 0.10, 1.0), 0.78, 0.48)
	var brass := _mat(Color(0.55, 0.39, 0.15, 1.0), 0.80, 0.42)
	var glow := _mat(Color(0.20, 0.68, 1.0, 1.0), 0.0, 0.38, 2.4)
	for x in [-9.0, 9.0]:
		_cylinder($SetDressing, "PressureTank", 1.15, 3.1, Vector3(x, 1.55, -4.2), copper)
		_cylinder($SetDressing, "TankCap", 1.24, 0.20, Vector3(x, 3.10, -4.2), brass)
		_cylinder($SetDressing, "Stack", 0.34, 4.7, Vector3(x, 2.35, -8.0), iron)
		_cylinder($SetDressing, "StackLight", 0.42, 0.16, Vector3(x, 4.72, -8.0), glow)
	for x in [-7.0, 7.0]:
		_box($SetDressing, "AetherPylon", Vector3(0.55, 0.55, 1.4), Vector3(x, 0.70, 7.8), iron)
		_box($SetDressing, "AetherLamp", Vector3(0.30, 0.30, 0.48), Vector3(x, 1.48, 7.8), glow)


func _place_titan() -> void:
	titan = TitanGLB.instantiate() as Node3D
	titan.name = "TitanAsset"
	$TitanRoot.add_child(titan)
	for mesh in _all_meshes(titan):
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _place_buildings() -> void:
	var civic := CivicGLB.instantiate() as Node3D
	civic.name = "CivicScaleReference"
	civic.position = Vector3(-14.5, 0, -11.5)
	civic.rotation.y = deg_to_rad(12.0)
	$SetDressing.add_child(civic)
	var industry := IndustryGLB.instantiate() as Node3D
	industry.name = "IndustryScaleReference"
	industry.position = Vector3(14.5, 0, -11.0)
	industry.rotation.y = deg_to_rad(-16.0)
	$SetDressing.add_child(industry)


func _place_scale_units() -> void:
	var positions := [
		Vector3(-7.0, 0, 6.1), Vector3(-5.4, 0, 6.8), Vector3(-3.8, 0, 6.1),
		Vector3(4.0, 0, 6.0), Vector3(5.6, 0, 6.8), Vector3(7.2, 0, 6.0),
	]
	for i in range(positions.size()):
		var unit := InfantryScene.instantiate() as RTSUnit
		unit.name = "ScaleInfantry%02d" % i
		unit.setup(InfantryDef, true)
		unit.position = positions[i]
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


func _set_view(distance: float, target: Vector3, titan_yaw_degrees: float) -> void:
	if titan != null:
		titan.rotation.y = deg_to_rad(titan_yaw_degrees)
	rig.set("distance", distance)
	rig.position = Vector3(target.x, 0.0, target.z + distance)
	rig.call("_update_camera_offset")


func _set_silhouette(enabled: bool) -> void:
	if _silhouette_material == null:
		_silhouette_material = _mat(Color(0.008, 0.01, 0.014, 1.0), 0.0, 1.0)
	for mesh_variant in _all_meshes(titan):
		var mesh := mesh_variant as GeometryInstance3D
		if enabled:
			_mesh_overrides[mesh] = mesh.material_override
			mesh.material_override = _silhouette_material
		else:
			mesh.material_override = _mesh_overrides.get(mesh, null)
	if not enabled:
		_mesh_overrides.clear()
	var environment := ($WorldEnvironment as WorldEnvironment).environment
	environment.background_color = Color(0.68, 0.73, 0.76, 1.0) if enabled else Color(0.035, 0.045, 0.065, 1.0)


func _capture(name_text: String) -> void:
	for i in range(12):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(SCREENSHOT_DIR.path_join(name_text + ".png"))
	var error := get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		push_error("CAPTURE_FAILED %s error=%d" % [path, error])
	else:
		print("PHASE25B_CAPTURE_OK ", path)


func _capture_set() -> void:
	var absolute_dir := ProjectSettings.globalize_path(SCREENSHOT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	# Keep the review set art-only. FPS is recorded by the separate benchmark,
	# avoiding stale partial HUD redraws while the maximized window resizes.
	$HUD.visible = false
	await get_tree().create_timer(1.0).timeout

	$UnitsRoot.visible = false
	$SetDressing.visible = false
	_set_view(19.0, Vector3(0, 0, 0), -24.0)
	await _capture("titan_close")

	_set_view(25.0, Vector3(0, 0, 0), -22.0)
	await _capture("titan_mid")

	_set_view(43.0, Vector3(0, 0, 0), -22.0)
	await _capture("titan_zoomed_out")

	$UnitsRoot.visible = true
	_set_view(29.0, Vector3(0, 0, 1.0), -22.0)
	await _capture("titan_with_units")

	$SetDressing.visible = true
	_set_view(39.0, Vector3(0, 0, -3.0), -18.0)
	await _capture("titan_in_scene")

	$UnitsRoot.visible = false
	$SetDressing.visible = false
	_set_view(22.0, Vector3(0, 0, 0), 158.0)
	await _capture("titan_back_view")

	_set_view(24.0, Vector3(0, 0, 0), -22.0)
	_set_silhouette(true)
	await _capture("titan_silhouette_check")
	_set_silhouette(false)

	var fps_avg := 0
	if _fps_samples > 0:
		fps_avg = _fps_sum / _fps_samples
	print("PHASE25B_CAPTURE_DONE shots=7 fps_min=%d fps_avg=%d" % [_fps_min, fps_avg])
	get_tree().quit(0)
