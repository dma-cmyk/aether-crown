extends Node3D
## Prototype battlefield: blue base (west) vs red placeholder base (east),
## midfield clash with walkers / titan / infantry, one airship per side.
## Atmosphere verification only: no gameplay logic, no balance changes.
##
## Capture (windowed, Iris Xe):
##   godot --path game res://scenes/maps/prototype_battlefield.tscn -- --capture-proto
##   godot --path game res://scenes/maps/prototype_battlefield.tscn -- --capture-proto-polish
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
const POLISH_SCREENSHOT_DIR := "res://../docs/screenshots/prototype_polish"

var _fps_min := 9999
var _fps_sum := 0
var _fps_samples := 0
var _elapsed := 0.0
var _capture_active := false
var _benchmark_active := false
var _benchmark_reported := false
var _ring_mat: StandardMaterial3D
var _screenshot_dir := SCREENSHOT_DIR

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
	if args.has("--capture-proto-polish"):
		_screenshot_dir = POLISH_SCREENSHOT_DIR
		_capture_active = true
		call_deferred("_capture_polish_set")
	elif args.has("--capture-proto"):
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
	# Faction zones remain readable without becoming the dominant colors. A
	# neutral ash midfield replaces the previous full-height yellow divider.
	_add_flat(Vector3(-55, 0, 0), Vector3(70, 0.06, 112), _mat(Color(0.065, 0.12, 0.23, 1.0), 0.0, 1.0))
	_add_flat(Vector3(55, 0, 0), Vector3(70, 0.06, 112), _mat(Color(0.23, 0.075, 0.055, 1.0), 0.0, 1.0))
	_add_flat(Vector3(0, 0, 0), Vector3(24, 0.07, 112), _mat(Color(0.16, 0.14, 0.12, 1.0), 0.0, 0.98))
	# Dashed brass survey line identifies the contested axis without becoming a wall.
	var boundary := _mat(Color(0.58, 0.39, 0.14, 1.0), 0.65, 0.58)
	for z in range(-48, 49, 12):
		_add_flat(Vector3(0, 0.02, float(z)), Vector3(1.0, 0.10, 6.0), boundary)
	# Main road west-east + wider base spurs.
	var road := _mat(Color(0.22, 0.20, 0.19, 1.0), 0.0, 0.95)
	_add_flat(Vector3(0, 0.03, 4), Vector3(120, 0.11, 6.0), road)
	_add_flat(Vector3(-52, 0.03, -7), Vector3(6.0, 0.11, 30.0), road)
	_add_flat(Vector3(52, 0.03, 7), Vector3(6.0, 0.11, 30.0), road)

	# Role pads create a base hierarchy before the individual models are read.
	var base_pad := _mat(Color(0.18, 0.19, 0.22, 1.0), 0.35, 0.82)
	var factory_pad := _mat(Color(0.20, 0.18, 0.16, 1.0), 0.45, 0.76)
	var power_pad := _mat(Color(0.055, 0.18, 0.25, 1.0), 0.25, 0.65)
	_add_flat(Vector3(-54, 0.07, -18), Vector3(19, 0.12, 17), base_pad)
	_add_flat(Vector3(-66, 0.07, 7), Vector3(18, 0.12, 18), factory_pad)
	_add_flat(Vector3(-38, 0.07, -18), Vector3(12, 0.12, 12), power_pad)
	_add_flat(Vector3(-43, 0.07, 6), Vector3(25, 0.12, 14), base_pad)


func _add_flat(pos: Vector3, size: Vector3, material: Material) -> void:
	var slab := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	slab.mesh = mesh
	slab.material_override = material
	slab.position = pos
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(slab)


func _box(parent: Node3D, name_text: String, size: Vector3, pos: Vector3,
		material: Material, yaw_deg := 0.0) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = name_text
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = material
	item.position = pos
	item.rotation.y = deg_to_rad(yaw_deg)
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(item)
	return item


func _cylinder(parent: Node3D, name_text: String, radius: float, height: float,
		pos: Vector3, material: Material, segments := 10) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = name_text
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	item.mesh = mesh
	item.material_override = material
	item.position = pos
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(item)
	return item


func _ground_ring(name_text: String, pos: Vector3, radius: float, material: Material) -> void:
	var item := MeshInstance3D.new()
	item.name = name_text
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.10
	mesh.outer_radius = radius + 0.10
	mesh.rings = 40
	mesh.ring_segments = 6
	item.mesh = mesh
	item.material_override = material
	item.position = pos
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	$GroundRoot.add_child(item)


func _place_building(parent: Node3D, building_name: String, pos: Vector3, yaw_deg: float,
		foot_x: float, foot_z: float, bar_h: float, player_flag: bool,
		selected := false, visual_scale := 1.0) -> RTSBuilding:
	var b := RTSBuilding.new()
	b.name = "%s_%s" % [parent.name, building_name]
	b.setup(null, player_flag)
	b.display_name = building_name
	parent.add_child(b)
	b.position = pos
	b.rotation.y = deg_to_rad(yaw_deg)
	var visual := (_glb_for(building_name).instantiate()) as Node3D
	visual.scale = Vector3.ONE * visual_scale
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
	b.set_meta("prototype_role", building_name)
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


func _decorate_blue_base() -> void:
	var iron := _mat(Color(0.16, 0.17, 0.19, 1.0), 0.72, 0.62)
	var steel := _mat(Color(0.34, 0.36, 0.40, 1.0), 0.78, 0.48)
	var brass := _mat(Color(0.56, 0.38, 0.13, 1.0), 0.78, 0.44)
	var cyan := _mat(Color(0.16, 0.70, 1.0, 1.0), 0.0, 0.35, 2.2)

	# HQ: formal command courtyard and paired beacons reinforce centrality.
	_ground_ring("HQCommandRing", Vector3(-54, 0.16, -18), 8.2, brass)
	for sx in [-1.0, 1.0]:
		var p := Vector3(-54 + sx * 7.5, 1.25, -25.0)
		_cylinder($BlueBase, "HQBeaconPost", 0.18, 2.5, p, iron, 8)
		_cylinder($BlueBase, "HQBeaconGlow", 0.28, 0.24,
			p + Vector3(0, 1.34, 0), cyan, 8)

	# Factory: apron lanes, cargo blocks and a clear deployment axis.
	_add_flat(Vector3(-57, 0.15, 7), Vector3(10, 0.10, 8),
		_mat(Color(0.25, 0.23, 0.20, 1.0), 0.2, 0.88))
	for z in [4.5, 7.0, 9.5]:
		_box($BlueBase, "FactoryLane", Vector3(8.0, 0.08, 0.16),
			Vector3(-57, 0.23, z), brass)
	for i in range(3):
		_box($BlueBase, "FactoryCargo%02d" % i, Vector3(1.1, 0.9, 1.1),
			Vector3(-58.5 + float(i) * 1.35, 0.55, 11.2),
			steel if i % 2 == 0 else iron, float(i) * 12.0)

	# Power: a containment ring and four low emitters make the energy role
	# readable even when the central coil is partially occluded.
	_ground_ring("AetherContainment", Vector3(-38, 0.17, -18), 5.3, cyan)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(-38 + sx * 4.2, 0.85, -18 + sz * 4.2)
			_cylinder($BlueBase, "AetherPylon", 0.24, 1.7, p, iron, 8)
			_cylinder($BlueBase, "AetherPylonGlow", 0.32, 0.18,
				p + Vector3(0, 0.92, 0), cyan, 8)

	# Support/Barracks: compact communication mast, deliberately lower than HQ.
	var mast_pos := Vector3(-43.5, 2.5, 6.0)
	_cylinder($BlueBase, "SupportMast", 0.18, 5.0, mast_pos, iron, 8)
	_box($BlueBase, "SupportCrossbar", Vector3(3.0, 0.16, 0.16),
		mast_pos + Vector3(0, 1.45, 0), brass)
	_box($BlueBase, "SupportSignal", Vector3(0.42, 0.42, 0.42),
		mast_pos + Vector3(0, 2.65, 0), cyan, 45.0)


func _build_blue_base() -> void:
	_place_building($BlueBase, "HQ", Vector3(-54, 0, -18), 10.0,
		15.0, 13.0, 14.5, true, false, 1.08)
	_place_building($BlueBase, "Barracks", Vector3(-50, 0, 5), -6.0,
		15.0, 8.0, 6.0, true)
	_place_building($BlueBase, "Factory", Vector3(-66, 0, 7), 90.0,
		14.0, 14.5, 12.0, true)
	_place_building($BlueBase, "Aether", Vector3(-38, 0, -18), 8.0,
		9.0, 9.0, 12.5, true, false, 1.05)
	_place_building($BlueBase, "Boiler", Vector3(-36, 0, 6), -10.0,
		13.0, 10.0, 11.0, true)
	for bx in [-44.0, -56.0]:
		_banner($BlueBase, Vector3(bx, 0, -5), true)
	_decorate_blue_base()
	# Mooring mast for the blue airship.
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.5
	mm.bottom_radius = 0.7
	mm.height = 13.0
	mm.radial_segments = 10
	mast.mesh = mm
	mast.material_override = _mat(Color(0.25, 0.24, 0.27, 1.0), 0.6, 0.6)
	mast.position = Vector3(-60, 6.5, -29)
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
	shape.size = Vector3(2.8, 4.4, 2.5)
	col.shape = shape
	col.position = Vector3(0, 2.2, 0)
	root.add_child(col)
	# Small faction plates keep the shared industrial walker readable in a
	# mixed formation without recoloring the production materials.
	var faction_color := Color(0.14, 0.64, 1.0, 1.0) if player_flag else Color(1.0, 0.22, 0.12, 1.0)
	var faction_mat := _mat(faction_color, 0.15, 0.38, 1.8)
	for sx in [-1.0, 1.0]:
		_box(root, "FactionPlate", Vector3(0.30, 0.10, 0.48),
			Vector3(sx * 0.95, -0.64, 3.20), faction_mat)
	var ring := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 1.62
	rm.outer_radius = 1.78
	rm.rings = 32
	rm.ring_segments = 6
	ring.mesh = rm
	ring.material_override = _walker_ring()
	ring.position = Vector3(0, 0.1, 0)
	ring.visible = selected
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	root.set_meta("selected", selected)
	return root


func _build_midfield() -> void:
	# Blue walkers advance in a loose wedge; enough negative space remains
	# around each silhouette for infantry scale comparison.
	_place_walker("WalkerBlue0", Vector3(-13, 0, 2), -90.0, true, true)
	_place_walker("WalkerBlue1", Vector3(-19, 0, -6), -84.0, true)
	_place_walker("WalkerBlue2", Vector3(-20, 0, 9), -96.0, true)
	# Red walkers form a visible opposing line just behind field cover.
	_place_walker("WalkerRed0", Vector3(15, 0, -2), 90.0, false)
	_place_walker("WalkerRed1", Vector3(20, 0, 7), 96.0, false)
	# Blue titan anchoring the midfield.
	var titan := (TitanGLB.instantiate()) as Node3D
	titan.name = "MidTitan"
	titan.position = Vector3(-8, 0, -14)
	titan.rotation.y = deg_to_rad(-78.0)
	$Midfield.add_child(titan)
	for c in _all_meshes(titan):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# A broken defensive line and two impact cues focus the battle without
	# filling every patch of terrain. Their low height preserves unit reads.
	var cover_mat := _mat(Color(0.22, 0.20, 0.18, 1.0), 0.45, 0.72)
	var scorch_mat := _mat(Color(0.055, 0.045, 0.038, 1.0), 0.0, 1.0)
	for i in range(5):
		var z := -10.0 + float(i) * 5.0
		_box($Midfield, "FrontCover%02d" % i, Vector3(2.8, 1.0, 0.72),
			Vector3(5.0 + float(i % 2) * 1.8, 0.5, z), cover_mat,
			-18.0 if i % 2 == 0 else 14.0)
	_box($Midfield, "BrokenCover", Vector3(1.7, 0.7, 0.65),
		Vector3(1.8, 0.35, 5.8), cover_mat, 28.0)
	_ground_ring("ImpactScorchA", Vector3(1.5, 0.14, -5.8), 1.4, scorch_mat)
	_ground_ring("ImpactScorchB", Vector3(9.0, 0.14, 8.5), 0.9, scorch_mat)
	_box($Midfield, "BlueTracer", Vector3(3.0, 0.08, 0.08),
		Vector3(0.5, 1.35, 0.2), _mat(Color(0.16, 0.72, 1.0, 1.0), 0.0, 0.3, 2.8))
	_box($Midfield, "RedTracer", Vector3(2.4, 0.08, 0.08),
		Vector3(8.5, 1.15, -3.5), _mat(Color(1.0, 0.24, 0.10, 1.0), 0.0, 0.3, 2.5))


func _build_airships() -> void:
	var blue := VisualAirship.new()
	blue.name = "AirshipBlue"
	blue.is_player = true
	blue.center = Vector3(-58, 0, 7)
	blue.cruise_height = 23.0
	blue.cruise_radius = 9.0
	blue.cruise_speed = 0.035
	blue.bombard_enabled = false
	blue.scale = Vector3.ONE * 0.46
	blue.set("_angle", -PI * 0.5)
	$UnitsRoot.add_child(blue)
	blue.global_position = blue.center + Vector3(0, blue.cruise_height, -blue.cruise_radius)
	var red := VisualAirship.new()
	red.name = "AirshipRed"
	red.is_player = false
	red.center = Vector3(58, 0, 19)
	red.cruise_height = 25.0
	red.cruise_radius = 10.0
	red.cruise_speed = 0.03
	red.bombard_enabled = false
	red.scale = Vector3.ONE * 0.44
	red.set("_angle", -PI * 0.5)
	$UnitsRoot.add_child(red)
	red.global_position = red.center + Vector3(0, red.cruise_height, -red.cruise_radius)


func _build_infantry() -> void:
	var blue_spots := [
		Vector3(-44, 0, 8), Vector3(-42.4, 0, 8.8), Vector3(-40.8, 0, 8),
		Vector3(-10.5, 0, 5.7), Vector3(-8.9, 0, 6.5), Vector3(-7.3, 0, 5.7),
		Vector3(-4.0, 0, -4.2), Vector3(-2.4, 0, -3.4), Vector3(-0.8, 0, -4.2),
	]
	var red_spots := [
		Vector3(35, 0, -7), Vector3(36.6, 0, -6.2), Vector3(38.2, 0, -7),
		Vector3(27, 0, 9), Vector3(28.6, 0, 9.8), Vector3(30.2, 0, 9),
		Vector3(10.0, 0, 1.0), Vector3(11.6, 0, 1.8), Vector3(13.2, 0, 1.0),
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
	var path := ProjectSettings.globalize_path(_screenshot_dir.path_join(name_text + ".png"))
	var error := get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		push_error("CAPTURE_FAILED %s error=%d" % [path, error])
	else:
		print("PROTOTYPE_CAPTURE_OK ", path)


func _capture_set() -> void:
	var absolute_dir := ProjectSettings.globalize_path(_screenshot_dir)
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


func _capture_polish_set() -> void:
	var absolute_dir := ProjectSettings.globalize_path(_screenshot_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	$HUD.visible = false
	await get_tree().create_timer(1.0).timeout

	_set_view(70.0, Vector3(0, 0, -2))
	await _capture("rts_overview")

	_set_view(46.0, Vector3(-51, 0, -4))
	await _capture("blue_base_roles")

	_set_view(34.0, Vector3(0, 0, 0))
	await _capture("frontline_clash")

	_set_view(16.0, Vector3(-13, 0, 2))
	await _capture("walker_scale")

	_set_view(38.0, Vector3(-51, 0, -5))
	await _capture("building_role_angle")

	_set_view(50.0, Vector3(-54, 0, -5))
	await _capture("airship_support")

	print("PROTOTYPE_POLISH_CAPTURE_DONE shots=6")
	get_tree().quit(0)
