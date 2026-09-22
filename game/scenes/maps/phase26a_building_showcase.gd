extends Node3D
## Phase 2.6A building set showcase: 5 production buildings in a set row,
## a small city block for density/scale checks, plus Titan + infantry for
## scale comparison. Buildings are wrapped in RTSBuilding (selection +
## footprint collision) to verify gameplay compatibility without touching
## existing maps or balance.
##
## Capture (windowed, Iris Xe):
##   godot --path game res://scenes/maps/phase26a_building_showcase.tscn -- --capture-26a
## Benchmarks:
##   ... -- --benchmark-26a          (set row view)
##   ... -- --benchmark-26a-block    (city block view)
##   ... -- --benchmark-26a --res-720p

const HQGLB: PackedScene = preload("res://assets/models/gearforge_hq_command.glb")
const BarracksGLB: PackedScene = preload("res://assets/models/gearforge_barracks.glb")
const FactoryGLB: PackedScene = preload("res://assets/models/gearforge_factory.glb")
const BoilerGLB: PackedScene = preload("res://assets/models/gearforge_boiler_works.glb")
const AetherGLB: PackedScene = preload("res://assets/models/gearforge_aether_well.glb")
const TitanGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

const SCREENSHOT_DIR := "res://../docs/screenshots/phase26a"

## Set-row placements: name -> [x, z, yaw_deg, footprint_x, footprint_z, bar_h].
const SET_ROW := [
	["HQ", -32.0, 0.0, 12.0, 15.0, 13.0, 13.5],
	["Barracks", -16.0, 0.0, -8.0, 15.0, 8.0, 6.0],
	["Factory", 0.0, 0.0, 5.0, 14.0, 14.5, 12.0],
	["Boiler", 15.0, 0.0, -6.0, 13.0, 10.0, 11.0],
	["Aether", 30.0, 0.0, 10.0, 9.0, 9.0, 12.0],
]

## City block placements (tighter, street-like, yaw variance).
const BLOCK := [
	["HQ", -8.0, -30.0, 4.0, 15.0, 13.0, 13.5],
	["Factory", 8.0, -31.0, -5.0, 14.0, 14.5, 12.0],
	["Boiler", -8.0, -42.0, -3.0, 13.0, 10.0, 11.0],
	["Aether", 9.0, -44.0, 6.0, 9.0, 9.0, 12.0],
	["Barracks", 20.0, -36.0, -90.0, 15.0, 8.0, 6.0],
]

var _fps_min := 9999
var _fps_sum := 0
var _fps_samples := 0
var _elapsed := 0.0
var _capture_active := false
var _benchmark_active := false
var _benchmark_reported := false

@onready var rig: Node3D = $CameraRig
@onready var readout: Label = $HUD/Readout


func _glb_for(building_name: String) -> PackedScene:
	match building_name:
		"HQ":
			return HQGLB
		"Barracks":
			return BarracksGLB
		"Factory":
			return FactoryGLB
		"Boiler":
			return BoilerGLB
	return AetherGLB


func _ready() -> void:
	add_to_group("building_showcase")
	_build_ground()
	for entry in SET_ROW:
		_place_building($SetRow, entry)
	for entry in BLOCK:
		_place_building($CityBlock, entry)
	_place_titan()
	_place_scale_units()
	_set_view(34.0, Vector3(0, 0, -2.0))
	var args := OS.get_cmdline_user_args()
	if args.has("--capture-26a"):
		_capture_active = true
		call_deferred("_capture_set")
	elif args.has("--benchmark-26a") or args.has("--benchmark-26a-block"):
		_benchmark_active = true
		if args.has("--res-720p"):
			DisplayServer.window_set_size(Vector2i(1280, 720))
		else:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		if args.has("--benchmark-26a-block"):
			_set_view(40.0, Vector3(2, 0, -36.0))
		print("PHASE26A_BENCHMARK_START warmup=3s duration=15s block=%s" % str(args.has("--benchmark-26a-block")))
	print("PHASE26A_SHOWCASE_READY set=%d block=%d" % [$SetRow.get_child_count(), $CityBlock.get_child_count()])


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	if _elapsed > 3.0 and fps > 0:
		_fps_min = mini(_fps_min, fps)
		_fps_sum += fps
		_fps_samples += 1
	if readout != null:
		readout.text = "SET 5 + BLOCK 5 // FPS %d" % fps
	if _benchmark_active and not _benchmark_reported and _elapsed >= 15.0:
		_benchmark_reported = true
		var average := _fps_sum / maxi(1, _fps_samples)
		print("PHASE26A_BENCHMARK_DONE fps_min=%d fps_avg=%d samples=%d" % [
			_fps_min, average, _fps_samples
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
	# Block streets: simple paved strips to read the city block as streets.
	var street := _mat(Color(0.20, 0.19, 0.20, 1.0), 0.0, 0.95)
	_add_slab(Vector3(2, 0, -36), Vector3(44, 0.1, 3.2), street)
	_add_slab(Vector3(-1, 0, -30), Vector3(3.2, 0.1, 26.0), street)


func _add_slab(pos: Vector3, size: Vector3, material: Material) -> void:
	var slab := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	slab.mesh = mesh
	slab.material_override = material
	slab.position = pos
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(slab)


func _place_building(parent: Node3D, entry: Array) -> RTSBuilding:
	var building_name: String = entry[0]
	var b := RTSBuilding.new()
	b.name = "%s_%s" % [parent.name, building_name]
	b.setup(null, true)
	b.display_name = building_name
	parent.add_child(b)
	b.position = Vector3(entry[1], 0, entry[2])
	b.rotation.y = deg_to_rad(entry[3])
	var visual := (_glb_for(building_name).instantiate()) as Node3D
	b.add_child(visual)
	for c in _all_meshes(visual):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(entry[4], 6.0, entry[5])
	col.shape = shape
	col.position = Vector3(0, 3.0, 0)
	b.add_child(col)
	b.set("_ring_radius", maxf(entry[4], entry[5]) * 0.62)
	b.set("_bar_height", entry[6])
	return b


func _place_titan() -> void:
	var titan := TitanGLB.instantiate() as Node3D
	titan.name = "ScaleTitan"
	titan.position = Vector3(44, 0, -2)
	titan.rotation.y = deg_to_rad(-20.0)
	$UnitsRoot.add_child(titan)
	for c in _all_meshes(titan):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _place_scale_units() -> void:
	var spots := [
		Vector3(-20, 0, 5.5), Vector3(-18.4, 0, 6.2), Vector3(-16.8, 0, 5.5),
		Vector3(41, 0, 4.5), Vector3(42.6, 0, 5.2),
		Vector3(-2, 0, -33.5), Vector3(-0.4, 0, -34.2), Vector3(1.2, 0, -33.5),
	]
	for i in range(spots.size()):
		var unit := InfantryScene.instantiate() as RTSUnit
		unit.name = "ScaleInfantry%02d" % i
		unit.setup(InfantryDef, true)
		unit.position = spots[i]
		unit.rotation.y = PI + float(i) * 0.35
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
		print("PHASE26A_CAPTURE_OK ", path)


func _capture_set() -> void:
	var absolute_dir := ProjectSettings.globalize_path(SCREENSHOT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	$HUD.visible = false
	await get_tree().create_timer(1.0).timeout

	_set_view(46.0, Vector3(0, 0, -2.0))
	await _capture("building_set_overview")

	_set_view(24.0, Vector3(-32, 0, 0))
	await _capture("hq_close")

	_set_view(24.0, Vector3(0, 0, 0))
	await _capture("factory_close")

	_set_view(22.0, Vector3(30, 0, 0))
	await _capture("aether_works_close")

	_set_view(38.0, Vector3(2, 0, -36.0))
	await _capture("city_block_mid")

	_set_view(62.0, Vector3(0, 0, -38.0))
	await _capture("city_block_strategic")

	_set_view(30.0, Vector3(38, 0, -2.0))
	await _capture("building_scale_comparison")

	_set_view(14.0, Vector3(15, 0, 0))
	await _capture("modular_parts_overview")

	print("PHASE26A_CAPTURE_DONE shots=8")
	get_tree().quit(0)
