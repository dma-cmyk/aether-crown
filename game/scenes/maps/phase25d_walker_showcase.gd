extends Node3D
## Phase 2.5D art-only Walker showcase. Uses the production GLB directly and
## touches no gameplay system: RTSUnit integration, collision, selection, LOD
## and animation are the next (Muse Spark) pass.
##
## Capture (windowed, Iris Xe):
##   godot --path game res://scenes/maps/phase25d_walker_showcase.tscn -- --capture-25d
## Benchmark:
##   godot --path game res://scenes/maps/phase25d_walker_showcase.tscn -- --benchmark-25d

const WalkerGLB: PackedScene = preload("res://assets/models/gearforge_walker.glb")
const PrototypeGLB: PackedScene = preload("res://assets/models/gearforge_walker_prototype.glb")
const TitanGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const BarracksGLB: PackedScene = preload("res://assets/models/gearforge_barracks.glb")
const FactoryGLB: PackedScene = preload("res://assets/models/gearforge_factory.glb")
const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

const SCREENSHOT_DIR := "res://../docs/screenshots/phase25d"

## Squad placements for the overview shots: [x, z, yaw_deg, is_player].
const SQUAD := [
	[-6.5, 2.0, 8.0, true],
	[0.0, -1.5, -4.0, true],
	[6.5, 1.6, -14.0, true],
]

var walker: Node3D
var _fps_min := 9999
var _fps_sum := 0
var _fps_samples := 0
var _elapsed := 0.0
var _benchmark_active := false
var _benchmark_reported := false

@onready var camera: Camera3D = $ReviewCamera
@onready var readout: Label = $HUD/Readout


func _ready() -> void:
	add_to_group("walker_showcase")
	_build_ground()
	_place_hero_walker()
	_place_squad()
	_place_prototype()
	_place_titan()
	_place_buildings()
	_place_infantry()
	_set_view(Vector3(7.5, 5.2, 9.5), Vector3(0, 2.2, 0), -28.0)
	print("PHASE25D_SHOWCASE_READY walker=%s meshes=%d squad=%d infantry=%d" % [
		str(walker != null), _all_meshes(walker).size(),
		$SquadRoot.get_child_count(), $UnitsRoot.get_child_count()
	])
	if OS.get_cmdline_user_args().has("--capture-25d"):
		call_deferred("_capture_set")
	elif OS.get_cmdline_user_args().has("--benchmark-25d"):
		_benchmark_active = true
		print("PHASE25D_BENCHMARK_START warmup=3s duration=15s")


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	if _elapsed > 3.0 and fps > 0:
		_fps_min = mini(_fps_min, fps)
		_fps_sum += fps
		_fps_samples += 1
	if readout != null:
		readout.text = "4.54m // FRONTLINE SUPPORT WALKER // FPS %d" % fps
	if _benchmark_active and not _benchmark_reported and _elapsed >= 15.0:
		_benchmark_reported = true
		var average := _fps_sum / maxi(1, _fps_samples)
		print("PHASE25D_BENCHMARK_DONE fps_min=%d fps_avg=%d samples=%d" % [
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


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	ground.mesh = plane
	ground.material_override = _mat(Color(0.105, 0.125, 0.12, 1.0), 0.0, 0.98)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(ground)
	var iron := _mat(Color(0.16, 0.17, 0.19, 1.0), 0.75, 0.62)
	var steel := _mat(Color(0.31, 0.33, 0.37, 1.0), 0.8, 0.45)
	_box($GroundRoot, "Apron", Vector3(34.0, 0.24, 26.0), Vector3(0, -0.13, 0), iron)
	for x in [-11.0, 0.0, 11.0]:
		_box($GroundRoot, "DeckSeam", Vector3(0.12, 0.04, 25.0), Vector3(x, 0.015, 0), steel)


func _spawn_walker(parent: Node3D, walker_name: String, pos: Vector3, yaw_deg: float,
		is_player: bool) -> Node3D:
	var root := Node3D.new()
	root.name = walker_name
	parent.add_child(root)
	root.position = pos
	root.rotation.y = deg_to_rad(yaw_deg)
	var visual := WalkerGLB.instantiate() as Node3D
	root.add_child(visual)
	for mesh in _all_meshes(visual):
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# Faction marking goes on the reserved shoulder plates only: the production
	# materials stay neutral so one GLB serves both sides.
	# Painted panel, not a lamp: the only cyan that should glow on this unit is
	# the Aether sensor slit, regulator and capacitor in the GLB itself.
	var faction := Color(0.10, 0.34, 0.74, 1.0) if is_player else Color(0.62, 0.11, 0.07, 1.0)
	var plate := _mat(faction, 0.10, 0.55, 0.0)
	for sx in [-1.0, 1.0]:
		_box(root, "FactionPlate", Vector3(0.10, 0.46, 0.72),
			Vector3(sx * 1.34, 3.18, 0.24), plate)
	return root


func _place_hero_walker() -> void:
	walker = _spawn_walker($WalkerRoot, "IronstrideHero", Vector3.ZERO, 0.0, true)


func _place_squad() -> void:
	for i in range(SQUAD.size()):
		var entry: Array = SQUAD[i]
		_spawn_walker($SquadRoot, "IronstrideSquad%d" % i,
			Vector3(float(entry[0]), 0.0, float(entry[1])), float(entry[2]), bool(entry[3]))


func _place_prototype() -> void:
	var proto := PrototypeGLB.instantiate() as Node3D
	proto.name = "WalkerPrototype"
	proto.position = Vector3(-5.2, 0, 0)
	$PrototypeRoot.add_child(proto)


func _place_titan() -> void:
	var titan := TitanGLB.instantiate() as Node3D
	titan.name = "TitanScaleReference"
	titan.position = Vector3(10.0, 0, -4.0)
	titan.rotation.y = deg_to_rad(-26.0)
	$TitanRoot.add_child(titan)


func _place_buildings() -> void:
	var barracks := BarracksGLB.instantiate() as Node3D
	barracks.name = "BarracksScaleReference"
	barracks.position = Vector3(-19.0, 0, -13.0)
	barracks.rotation.y = deg_to_rad(16.0)
	$BuildingRoot.add_child(barracks)
	var factory := FactoryGLB.instantiate() as Node3D
	factory.name = "FactoryScaleReference"
	factory.position = Vector3(5.0, 0, -18.0)
	factory.rotation.y = deg_to_rad(-8.0)
	$BuildingRoot.add_child(factory)


func _place_infantry() -> void:
	var positions := [
		Vector3(-3.0, 0, 4.4), Vector3(-1.9, 0, 5.2), Vector3(-0.8, 0, 4.4),
		Vector3(0.3, 0, 5.2), Vector3(1.4, 0, 4.4), Vector3(2.5, 0, 5.2),
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
	if node == null:
		return result
	if node is GeometryInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_all_meshes(child))
	return result


func _set_view(cam_pos: Vector3, target: Vector3, walker_yaw_degrees: float) -> void:
	if walker != null:
		walker.rotation.y = deg_to_rad(walker_yaw_degrees)
	camera.position = cam_pos
	camera.look_at(target, Vector3.UP)


func _capture(name_text: String) -> void:
	for i in range(12):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(SCREENSHOT_DIR.path_join(name_text + ".png"))
	var error := get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		push_error("CAPTURE_FAILED %s error=%d" % [path, error])
	else:
		print("PHASE25D_CAPTURE_OK ", path)


func _capture_set() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	$HUD.visible = false
	await get_tree().create_timer(1.0).timeout

	var focus := Vector3(0, 2.2, 0)
	$SquadRoot.visible = false
	$PrototypeRoot.visible = false
	$TitanRoot.visible = false
	$BuildingRoot.visible = false
	$UnitsRoot.visible = false

	# Model-distance orthodox views. Yaw 0 puts the bow toward a camera on +Z.
	_set_view(Vector3(0, 2.6, 8.6), focus, 0.0)
	await _capture("walker_front")

	_set_view(Vector3(0, 2.6, 8.6), focus, 90.0)
	await _capture("walker_side")

	_set_view(Vector3(0, 2.8, 8.6), focus, 180.0)
	await _capture("walker_rear")

	_set_view(Vector3(4.6, 4.3, 4.4), Vector3(-0.1, 3.5, 0.9), -62.0)
	await _capture("walker_weapon_close")

	# Prototype on the left, production walker on the right, same camera.
	$PrototypeRoot.visible = true
	_set_view(Vector3(3.6, 4.4, 10.5), Vector3(-2.6, 2.2, 0), -22.0)
	await _capture("walker_prototype_compare")
	$PrototypeRoot.visible = false

	# Scale relations.
	$UnitsRoot.visible = true
	_set_view(Vector3(6.0, 4.0, 9.5), Vector3(-0.4, 1.8, 2.0), -30.0)
	await _capture("walker_infantry_scale")

	$TitanRoot.visible = true
	_set_view(Vector3(10.0, 7.0, 16.0), Vector3(4.0, 3.2, -1.0), -26.0)
	await _capture("walker_titan_scale")

	# RTS-distance reads: squad, buildings, Titan, infantry together.
	$SquadRoot.visible = true
	$BuildingRoot.visible = true
	_set_view(Vector3(14.0, 11.0, 20.0), Vector3(-1.0, 2.0, -2.0), -18.0)
	await _capture("walker_production_overview")

	_set_view(Vector3(24.0, 22.0, 34.0), Vector3(-1.0, 2.0, -4.0), -18.0)
	await _capture("walker_rts_distance")

	var fps_avg := 0
	if _fps_samples > 0:
		fps_avg = _fps_sum / _fps_samples
	print("PHASE25D_CAPTURE_DONE shots=9 fps_min=%d fps_avg=%d" % [_fps_min, fps_avg])
	get_tree().quit(0)
