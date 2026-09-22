extends Node3D
## Prototype battlefield: blue base (west) vs red placeholder base (east),
## midfield clash with walkers / titan / infantry, one airship per side.
## Atmosphere verification only: no gameplay logic, no balance changes.
##
## Capture (windowed, Iris Xe):
##   godot --path game res://scenes/maps/prototype_battlefield.tscn -- --capture-proto
## Benchmark:
##   ... -- --benchmark-proto [--res-720p]

const HQGLB: PackedScene = preload("res://assets/models/gearforge_hq_command.glb")
const BarracksGLB: PackedScene = preload("res://assets/models/gearforge_barracks.glb")
const FactoryGLB: PackedScene = preload("res://assets/models/gearforge_factory.glb")
const BoilerGLB: PackedScene = preload("res://assets/models/gearforge_boiler_works.glb")
const AetherGLB: PackedScene = preload("res://assets/models/gearforge_aether_well.glb")
const TitanGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const WalkerGLB: PackedScene = preload("res://assets/models/gearforge_walker_prototype.glb")
const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

const SCREENSHOT_DIR := "res://../docs/screenshots/prototype"

var _fps_min := 9999
var _fps_sum := 0
var _fps_samples := 0
var _elapsed := 0.0
var _capture_active := false
var _benchmark_active := false
var _benchmark_reported := false
var _ring_mat: StandardMaterial3D

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
	add_to_group("prototype_battlefield")
	_build_ground()
	_build_blue_base()
	_build_red_base()
	_build_midfield()
	_build_airships()
	_build_infantry()
	# Pre-selected demo: HQ (set_selected in _build_blue_base order: first
	# child) + WalkerBlue0 ring + 3 blue infantry show the selection look.
	($BlueBase.get_child(0) as RTSBuilding).set_selected(true)
	_set_view(52.0, Vector3(0, 0, -4.0))
	var args := OS.get_cmdline_user_args()
	if args.has("--capture-proto"):
		_capture_active = true
		call_deferred("_capture_set")
	elif args.has("--benchmark-proto"):
		_benchmark_active = true
		if args.has("--res-720p"):
			DisplayServer.window_set_size(Vector2i(1280, 720))
		else:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		print("PHASE_PROTO_BENCHMARK_START warmup=3s duration=15s")
	print("PROTOTYPE_READY blue=%d red=%d mid=%d units=%d" % [
		$BlueBase.get_child_count(), $RedBase.get_child_count(),
		$Midfield.get_child_count(), $UnitsRoot.get_child_count()])


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	if _elapsed > 3.0 and fps > 0:
		_fps_min = mini(_fps_min, fps)
		_fps_sum += fps
		_fps_samples += 1
	if readout != null:
		readout.text = "PROTOTYPE // BLUE vs RED // FPS %d" % fps
	if _benchmark_active and not _benchmark_reported and _elapsed >= 15.0:
		_benchmark_reported = true
		var average := _fps_sum / maxi(1, _fps_samples)
		print("PHASE_PROTO_BENCHMARK_DONE fps_min=%d fps_avg=%d samples=%d" % [
			_fps_min, average, _fps_samples
		])
		get_tree().quit(0)


func _mat(color: Color, metallic := 0.0, roughness := 0.9, emission := 0.0) -> StandardMaterial3D:
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
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(260, 260)
	ground.mesh = plane
	ground.material_override = _mat(Color(0.105, 0.125, 0.12, 1.0), 0.0, 0.98)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(ground)
	# Zone tints: blue west / red east / contested middle strip (muted).
	_add_flat(Vector3(-55, 0, 0), Vector3(70, 0.06, 120), _mat(Color(0.08, 0.16, 0.32, 1.0), 0.0, 1.0))
	_add_flat(Vector3(55, 0, 0), Vector3(70, 0.06, 120), _mat(Color(0.30, 0.09, 0.07, 1.0), 0.0, 1.0))
	_add_flat(Vector3(0, 0, 0), Vector3(8, 0.08, 120), _mat(Color(0.55, 0.45, 0.25, 1.0), 0.3, 0.8))
	# Main road west-east + base spurs.
	var road := _mat(Color(0.22, 0.20, 0.19, 1.0), 0.0, 0.95)
	_add_flat(Vector3(0, 0, 6), Vector3(120, 0.1, 4.0), road)
	_add_flat(Vector3(-48, 0, -8), Vector3(4.0, 0.1, 28.0), road)
	_add_flat(Vector3(48, 0, 8), Vector3(4.0, 0.1, 28.0), road)


func _add_flat(pos: Vector3, size: Vector3, material: Material) -> void:
	var slab := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	slab.mesh = mesh
	slab.material_override = material
	slab.position = pos
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(slab)


func _place_building(parent: Node3D, building_name: String, pos: Vector3, yaw_deg: float,
		foot_x: float, foot_z: float, bar_h: float, player_flag: bool, selected := false) -> RTSBuilding:
	var b := RTSBuilding.new()
	b.name = "%s_%s" % [parent.name, building_name]
	b.setup(null, player_flag)
	b.display_name = building_name
	parent.add_child(b)
	b.position = pos
	b.rotation.y = deg_to_rad(yaw_deg)
	var visual := (_glb_for(building_name).instantiate()) as Node3D
	b.add_child(visual)
	for c in _all_meshes(visual):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(foot_x, 6.0, foot_z)
	col.shape = shape
	col.position = Vector3(0, 3.0, 0)
	b.add_child(col)
	b.set("_ring_radius", maxf(foot_x, foot_z) * 0.62)
	b.set("_bar_height", bar_h)
	if selected:
		b.set_selected(true)
	return b


func _banner(parent: Node3D, pos: Vector3, player_flag: bool) -> void:
	var color := Color(0.25, 0.55, 1.0, 1.0) if player_flag else Color(1.0, 0.30, 0.22, 1.0)
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.09
	cm.bottom_radius = 0.11
	cm.height = 6.0
	cm.radial_segments = 8
	pole.mesh = cm
	pole.material_override = _mat(Color(0.20, 0.20, 0.22, 1.0), 0.6, 0.6)
	pole.position = pos + Vector3(0, 3.0, 0)
	parent.add_child(pole)
	var flag := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(1.6, 1.0, 0.08)
	flag.mesh = fm
	flag.material_override = _mat(color, 0.0, 0.6, 1.2)
	flag.position = pos + Vector3(0.85, 5.2, 0)
	parent.add_child(flag)


func _build_blue_base() -> void:
	_place_building($BlueBase, "HQ", Vector3(-52, 0, -14), 12.0, 15.0, 13.0, 13.5, true)
	_place_building($BlueBase, "Barracks", Vector3(-50, 0, 2), -6.0, 15.0, 8.0, 6.0, true)
	_place_building($BlueBase, "Factory", Vector3(-64, 0, 8), 90.0, 14.0, 14.5, 12.0, true)
	_place_building($BlueBase, "Aether", Vector3(-38, 0, -16), 8.0, 9.0, 9.0, 12.0, true)
	_place_building($BlueBase, "Boiler", Vector3(-38, 0, 8), -10.0, 13.0, 10.0, 11.0, true)
	for bx in [-44.0, -56.0]:
		_banner($BlueBase, Vector3(bx, 0, -2), true)
	# Mooring mast for the blue airship.
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.5
	mm.bottom_radius = 0.7
	mm.height = 13.0
	mm.radial_segments = 10
	mast.mesh = mm
	mast.material_override = _mat(Color(0.25, 0.24, 0.27, 1.0), 0.6, 0.6)
	mast.position = Vector3(-46, 6.5, -24)
	$BlueBase.add_child(mast)


func _build_red_base() -> void:
	# Placeholder red base: production shells + red banners + darkObstacles.
	_place_building($RedBase, "Factory", Vector3(54, 0, 10), -95.0, 14.0, 14.5, 12.0, false)
	_place_building($RedBase, "Boiler", Vector3(52, 0, -6), 6.0, 13.0, 10.0, 11.0, false)
	_place_building($RedBase, "Barracks", Vector3(64, 0, -2), 88.0, 15.0, 8.0, 6.0, false)
	_place_building($RedBase, "Aether", Vector3(64, 0, 12), -8.0, 9.0, 9.0, 12.0, false, true)
	for bx in [46.0, 58.0]:
		_banner($RedBase, Vector3(bx, 0, 0), false)
	# Red fieldworks: dark barricade blocks across the front.
	var dark := _mat(Color(0.20, 0.16, 0.14, 1.0), 0.0, 0.9)
	for i in range(5):
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.4, 1.1, 0.7)
		b.mesh = bm
		b.material_override = dark
		b.position = Vector3(30 + float(i % 2) * 1.5, 0.55, -14 + float(i) * 6.0)
		b.rotation.y = 0.3 * float(i)
		$RedBase.add_child(b)


func _walker_ring() -> StandardMaterial3D:
	if _ring_mat == null:
		_ring_mat = StandardMaterial3D.new()
		_ring_mat.albedo_color = Color(1.0, 0.9, 0.2, 1.0)
		_ring_mat.emission_enabled = true
		_ring_mat.emission = Color(1.0, 0.85, 0.2, 1.0)
		_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _ring_mat


func _place_walker(walker_name: String, pos: Vector3, yaw_deg: float, player_flag: bool, selected := false) -> Node3D:
	var root := Node3D.new()
	root.name = walker_name
	root.set_meta("is_player", player_flag)
	root.set_meta("selected", selected)
	$Midfield.add_child(root)
	root.position = pos
	root.rotation.y = deg_to_rad(yaw_deg)
	var visual := (WalkerGLB.instantiate()) as Node3D
	root.add_child(visual)
	for c in _all_meshes(visual):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.6, 4.2, 2.2)
	col.shape = shape
	col.position = Vector3(0, 2.1, 0)
	root.add_child(col)
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 1.9
	rm.bottom_radius = 1.9
	rm.height = 0.08
	ring.mesh = rm
	ring.material_override = _walker_ring()
	ring.position = Vector3(0, 0.1, 0)
	ring.visible = selected
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	root.set_meta("selected", selected)
	return root


func _build_midfield() -> void:
	# Blue walkers advancing east in wedge.
	_place_walker("WalkerBlue0", Vector3(-14, 0, 2), 90.0, true, true)
	_place_walker("WalkerBlue1", Vector3(-18, 0, -4), 95.0, true)
	_place_walker("WalkerBlue2", Vector3(-18, 0, 8), 85.0, true)
	# Red walkers holding west of their barricades.
	_place_walker("WalkerRed0", Vector3(22, 0, -2), -90.0, false)
	_place_walker("WalkerRed1", Vector3(26, 0, 6), -95.0, false)
	# Blue titan anchoring the midfield.
	var titan := (TitanGLB.instantiate()) as Node3D
	titan.name = "MidTitan"
	titan.position = Vector3(-6, 0, -12)
	titan.rotation.y = deg_to_rad(75.0)
	$Midfield.add_child(titan)
	for c in _all_meshes(titan):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _build_airships() -> void:
	var blue := VisualAirship.new()
	blue.name = "AirshipBlue"
	blue.is_player = true
	blue.center = Vector3(-48, 0, -10)
	$UnitsRoot.add_child(blue)
	blue.global_position = blue.center + Vector3(0, VisualAirship.CRUISE_HEIGHT, 0)
	var red := VisualAirship.new()
	red.name = "AirshipRed"
	red.is_player = false
	red.center = Vector3(52, 0, 2)
	$UnitsRoot.add_child(red)
	red.global_position = red.center + Vector3(0, VisualAirship.CRUISE_HEIGHT, 0)


func _build_infantry() -> void:
	var blue_spots := [
		Vector3(-44, 0, 6), Vector3(-42.4, 0, 6.8), Vector3(-40.8, 0, 6),
		Vector3(-10, 0, 8), Vector3(-8.4, 0, 8.8), Vector3(-6.8, 0, 8),
		Vector3(-2, 0, -4), Vector3(-0.4, 0, -3.2),
	]
	var red_spots := [
		Vector3(36, 0, -6), Vector3(37.6, 0, -5.2), Vector3(39.2, 0, -6),
		Vector3(34, 0, 8), Vector3(35.6, 0, 8.8), Vector3(37.2, 0, 8),
		Vector3(12, 0, 0), Vector3(13.6, 0, 0.8),
	]
	_place_squad(blue_spots, true)
	_place_squad(red_spots, false)


func _place_squad(spots: Array, player_flag: bool) -> void:
	for i in range(spots.size()):
		var unit := InfantryScene.instantiate() as RTSUnit
		unit.name = "%sProto%02d" % ["Blue" if player_flag else "Red", i]
		unit.setup(InfantryDef, player_flag)
		unit.position = spots[i]
		unit.rotation.y = (PI * 0.5) if player_flag else (-PI * 0.5)
		$UnitsRoot.add_child(unit)
		unit.process_mode = Node.PROCESS_MODE_DISABLED
		if player_flag and i < 3:
			unit.set_selected(true)


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
		print("PROTOTYPE_CAPTURE_OK ", path)


func _capture_set() -> void:
	var absolute_dir := ProjectSettings.globalize_path(SCREENSHOT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	$HUD.visible = false
	await get_tree().create_timer(1.0).timeout

	_set_view(70.0, Vector3(0, 0, 0))
	await _capture("proto_overview")

	_set_view(40.0, Vector3(-48, 0, -6))
	await _capture("proto_blue_base")

	_set_view(14.0, Vector3(-14, 0, 2))
	await _capture("proto_walker_close")

	# Airship shot: wide blue-base framing — the cruising hull reads in the
	# upper frame with the base below (same geometry as the overview).
	_set_view(55.0, Vector3(-48, 0, -10))
	await _capture("proto_airship")

	_set_view(22.0, Vector3(-64, 0, 8))
	await _capture("proto_factory_close")

	_set_view(20.0, Vector3(-38, 0, -16))
	await _capture("proto_aether_close")

	_set_view(50.0, Vector3(54, 0, 2))
	await _capture("proto_red_base")

	_set_view(26.0, Vector3(-30, 0, 2))
	await _capture("proto_selection")

	print("PROTOTYPE_CAPTURE_DONE shots=8")
	get_tree().quit(0)
