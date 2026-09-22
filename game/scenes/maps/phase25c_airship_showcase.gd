extends Node3D
## Phase 2.5C art-only Airship showcase. Uses the production GLB directly,
## leaves gameplay/balance untouched, and captures the review set.
## Capture:
## godot --path game res://scenes/maps/phase25c_airship_showcase.tscn -- --capture-phase25c
## Benchmark:
## godot --path game res://scenes/maps/phase25c_airship_showcase.tscn -- --benchmark-phase25c

const AirshipGLB: PackedScene = preload("res://assets/models/gearforge_airship.glb")
const TitanGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const CivicGLB: PackedScene = preload("res://assets/models/gearforge_civic_core.glb")
const IndustryGLB: PackedScene = preload("res://assets/models/gearforge_industry_works.glb")
const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

const SCREENSHOT_DIR := "res://../docs/screenshots/phase25c"
## Keel-centre altitude. The hull bottom sits 5.13 m below the origin, so this
## clears the 11.39 m Titan with a readable gap for the scale comparison.
const CRUISE_ALTITUDE := 17.4

var airship: Node3D
var titan: Node3D
var _fps_min := 9999
var _fps_sum := 0
var _fps_samples := 0
var _elapsed := 0.0
var _benchmark_active := false
var _benchmark_reported := false
var _silhouette_material: StandardMaterial3D
var _mesh_overrides: Dictionary = {}

@onready var camera: Camera3D = $ReviewCamera
@onready var readout: Label = $HUD/Readout


func _ready() -> void:
	add_to_group("airship_showcase")
	_build_ground()
	_build_set_dressing()
	_place_airship()
	_place_titan()
	_place_buildings()
	_place_scale_units()
	_set_view(Vector3(46, 40, 52), Vector3(0, CRUISE_ALTITUDE, 0), 72.0)
	print("PHASE25C_SHOWCASE_READY airship=%s meshes=%d titan=%s units=%d" % [
		str(airship != null), _all_meshes(airship).size(), str(titan != null),
		$UnitsRoot.get_child_count()
	])
	if OS.get_cmdline_user_args().has("--capture-phase25c"):
		call_deferred("_capture_set")
	elif OS.get_cmdline_user_args().has("--benchmark-phase25c"):
		_benchmark_active = true
		print("PHASE25C_BENCHMARK_START warmup=3s duration=15s")


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	if _elapsed > 3.0 and fps > 0:
		_fps_min = mini(_fps_min, fps)
		_fps_sum += fps
		_fps_samples += 1
	if readout != null:
		readout.text = "35.5m // TWIN-CELL AETHER DREADNOUGHT // FPS %d" % fps
	if _benchmark_active and not _benchmark_reported and _elapsed >= 15.0:
		_benchmark_reported = true
		var average := _fps_sum / maxi(1, _fps_samples)
		print("PHASE25C_BENCHMARK_DONE fps_min=%d fps_avg=%d samples=%d" % [
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
	parent.add_child(item)
	return item


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	ground.material_override = _mat(Color(0.105, 0.125, 0.12, 1.0), 0.0, 0.98)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(ground)

	var iron := _mat(Color(0.16, 0.17, 0.19, 1.0), 0.75, 0.62)
	var steel := _mat(Color(0.31, 0.33, 0.37, 1.0), 0.8, 0.45)
	_box($GroundRoot, "Apron", Vector3(52.0, 0.30, 34.0), Vector3(0, -0.16, 0), iron)
	for x in [-18.0, -6.0, 6.0, 18.0]:
		_box($GroundRoot, "DeckSeamX", Vector3(0.14, 0.04, 33.0), Vector3(x, 0.02, 0), steel)


func _build_set_dressing() -> void:
	var iron := _mat(Color(0.19, 0.20, 0.23, 1.0), 0.72, 0.62)
	var copper := _mat(Color(0.52, 0.25, 0.10, 1.0), 0.78, 0.48)
	var brass := _mat(Color(0.55, 0.39, 0.15, 1.0), 0.80, 0.42)
	var glow := _mat(Color(0.20, 0.68, 1.0, 1.0), 0.0, 0.38, 2.4)
	# Mooring masts give the airship a berth and a vertical scale ruler.
	for x in [-21.0, 21.0]:
		_cylinder($SetDressing, "MooringMast", 0.70, 13.0, Vector3(x, 6.5, -6.0), iron)
		_cylinder($SetDressing, "MastCollar", 1.05, 0.40, Vector3(x, 12.4, -6.0), brass)
		_cylinder($SetDressing, "MastLamp", 0.55, 0.22, Vector3(x, 13.1, -6.0), glow)
		_cylinder($SetDressing, "PressureTank", 1.30, 3.4, Vector3(x, 1.7, 7.0), copper)
		_cylinder($SetDressing, "TankCap", 1.40, 0.22, Vector3(x, 3.4, 7.0), brass)


func _place_airship() -> void:
	airship = AirshipGLB.instantiate() as Node3D
	airship.name = "AirshipAsset"
	airship.position = Vector3(0, CRUISE_ALTITUDE, 0)
	$AirshipRoot.add_child(airship)
	for mesh in _all_meshes(airship):
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _place_titan() -> void:
	titan = TitanGLB.instantiate() as Node3D
	titan.name = "TitanScaleReference"
	titan.position = Vector3(6.0, 0, 6.0)
	titan.rotation.y = deg_to_rad(-24.0)
	$TitanRoot.add_child(titan)


func _place_buildings() -> void:
	var civic := CivicGLB.instantiate() as Node3D
	civic.name = "CivicScaleReference"
	civic.position = Vector3(-24.0, 0, -14.0)
	civic.rotation.y = deg_to_rad(14.0)
	$SetDressing.add_child(civic)
	var industry := IndustryGLB.instantiate() as Node3D
	industry.name = "IndustryScaleReference"
	industry.position = Vector3(24.0, 0, -13.0)
	industry.rotation.y = deg_to_rad(-18.0)
	$SetDressing.add_child(industry)


func _place_scale_units() -> void:
	var positions := [
		Vector3(-9.0, 0, 9.0), Vector3(-7.4, 0, 9.8), Vector3(-5.8, 0, 9.0),
		Vector3(-4.2, 0, 9.8), Vector3(-2.6, 0, 9.0), Vector3(-1.0, 0, 9.8),
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


func _set_view(cam_pos: Vector3, target: Vector3, airship_yaw_degrees: float) -> void:
	if airship != null:
		airship.rotation.y = deg_to_rad(airship_yaw_degrees)
	camera.position = cam_pos
	camera.look_at(target, Vector3.UP)


func _set_silhouette(enabled: bool) -> void:
	if _silhouette_material == null:
		_silhouette_material = _mat(Color(0.008, 0.01, 0.014, 1.0), 0.0, 1.0)
	for mesh_variant in _all_meshes(airship):
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
		print("PHASE25C_CAPTURE_OK ", path)


func _capture_set() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	$HUD.visible = false
	await get_tree().create_timer(1.0).timeout

	var focus := Vector3(0, CRUISE_ALTITUDE, 0)
	$UnitsRoot.visible = false
	$TitanRoot.visible = false
	$SetDressing.visible = false

	_set_view(Vector3(24, 26, 26), focus, 72.0)
	await _capture("airship_close")

	_set_view(Vector3(40, 34, 44), focus, 72.0)
	await _capture("airship_mid")

	_set_view(Vector3(66, 62, 72), focus, 72.0)
	await _capture("airship_strategic")

	# The GLB faces Godot +Z, so yaw 0 puts the bow toward a camera on +Z.
	_set_view(Vector3(2, 22, 46), focus, 0.0)
	await _capture("airship_front")

	_set_view(Vector3(2, 22, 46), focus, 180.0)
	await _capture("airship_back")

	_set_view(Vector3(26, 2.0, 30), focus, 72.0)
	await _capture("airship_underside")

	$UnitsRoot.visible = true
	$TitanRoot.visible = true
	_set_view(Vector3(44, 26, 46), Vector3(2, 11.0, 2), 72.0)
	await _capture("airship_with_titan")

	$SetDressing.visible = true
	_set_view(Vector3(56, 38, 60), Vector3(0, 10.0, -2), 72.0)
	await _capture("airship_in_scene")

	$UnitsRoot.visible = false
	$TitanRoot.visible = false
	$SetDressing.visible = false
	_set_view(Vector3(40, 34, 44), focus, 72.0)
	_set_silhouette(true)
	await _capture("airship_silhouette_check")
	_set_silhouette(false)

	var fps_avg := 0
	if _fps_samples > 0:
		fps_avg = _fps_sum / _fps_samples
	print("PHASE25C_CAPTURE_DONE shots=9 fps_min=%d fps_avg=%d" % [_fps_min, fps_avg])
	get_tree().quit(0)
