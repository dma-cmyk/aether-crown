extends Node3D
## Gearforge Map Production Kit 01 Showcase Scene
## Demonstrates the 14 modular environment assets:
## - Heavy Aether Bridge (Titan-capable 14m deck, 32m span)
## - Modular Cliff Set (straight, corner in/out, ramp, large plateau)
## - Fortress Gate & Defensive Wall Set (gate, straight, corner, tower, bastion)
## - Road Slabs & Industrial Edge Props (road, barrier, heavy pipeline)
##
## Controls:
## - WASD / Arrows: Pan camera
## - Q / E or Mouse Wheel: Zoom
## - 1: Overview Preset
## - 2: Bridge Focus Preset
## - 3: Fortress Gate Focus Preset
## - 4: Asset Palette Row Preset
## - H: Toggle HUD

const ASSETS: Dictionary = {
	"bridge_heavy": preload("res://assets/models/map/gearforge_bridge_heavy.glb"),
	"cliff_straight": preload("res://assets/models/map/gearforge_cliff_straight.glb"),
	"cliff_corner_in": preload("res://assets/models/map/gearforge_cliff_corner_in.glb"),
	"cliff_corner_out": preload("res://assets/models/map/gearforge_cliff_corner_out.glb"),
	"cliff_ramp": preload("res://assets/models/map/gearforge_cliff_ramp.glb"),
	"cliff_large": preload("res://assets/models/map/gearforge_cliff_large.glb"),
	"fortress_gate": preload("res://assets/models/map/gearforge_fortress_gate.glb"),
	"wall_straight": preload("res://assets/models/map/gearforge_wall_straight.glb"),
	"wall_corner": preload("res://assets/models/map/gearforge_wall_corner.glb"),
	"wall_tower": preload("res://assets/models/map/gearforge_wall_tower.glb"),
	"defensive_bastion": preload("res://assets/models/map/gearforge_defensive_bastion.glb"),
	"road_straight": preload("res://assets/models/map/gearforge_road_straight.glb"),
	"road_barrier": preload("res://assets/models/map/gearforge_road_barrier.glb"),
	"industrial_pipe_straight": preload("res://assets/models/map/gearforge_industrial_pipe_straight.glb"),
	"trench_industrial": preload("res://assets/models/map/gearforge_trench_industrial.glb"),
}

const TitanGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const QuadWalkerGLB: PackedScene = preload("res://assets/models/gearforge_medium_quad_walker.glb")
const WalkerGLB: PackedScene = preload("res://assets/models/gearforge_walker.glb")

@onready var rig: Node3D = $CameraRig
@onready var hud: CanvasLayer = $HUD
@onready var readout: Label = $HUD/Readout

var _elapsed: float = 0.0
var _total_tris: int = 21990


func _ready() -> void:
	_build_ground_plane()
	_assemble_diorama()
	_assemble_palette_row()
	_place_scale_units()
	_set_view(Vector3(0, 0, 32), 48.0)
	print("GEARFORGE_MAP_KIT_01_SHOWCASE_READY: 15 modular assets loaded successfully.")


func _build_ground_plane() -> void:
	# Bottom canyon floor plane (Y = 0)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(160, 160)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.12, 0.11, 0.10)
	floor_mat.roughness = 0.92
	floor_mat.metallic = 0.05
	
	var floor_inst := MeshInstance3D.new()
	floor_inst.mesh = floor_mesh
	floor_inst.material_override = floor_mat
	floor_inst.position = Vector3(0, 0, 0)
	$GroundRoot.add_child(floor_inst)


func _instantiate_asset(asset_key: String, pos: Vector3, rot_y_deg: float = 0.0, parent: Node = null) -> Node3D:
	if not ASSETS.has(asset_key):
		push_error("Unknown asset key: " + asset_key)
		return null
	var scene: PackedScene = ASSETS[asset_key]
	var inst: Node3D = scene.instantiate()
	inst.position = pos
	inst.rotation_degrees = Vector3(0, rot_y_deg, 0)
	if parent != null:
		parent.add_child(inst)
	else:
		add_child(inst)
	return inst


func _assemble_diorama() -> void:
	var root := $DioramaRoot

	# 1. South Plateau Cliffface (Z = -16, Height = 8.0)
	_instantiate_asset("cliff_straight", Vector3(-8.0, 0.0, -16.0), 180.0, root)
	_instantiate_asset("cliff_straight", Vector3(8.0, 0.0, -16.0), 180.0, root)
	_instantiate_asset("cliff_corner_out", Vector3(-24.0, 0.0, -16.0), 180.0, root)
	_instantiate_asset("cliff_ramp", Vector3(-24.0, 0.0, -28.0), 90.0, root)

	# 2. North Plateau Cliffface (Z = 16, Height = 8.0)
	_instantiate_asset("cliff_straight", Vector3(-8.0, 0.0, 16.0), 0.0, root)
	_instantiate_asset("cliff_straight", Vector3(8.0, 0.0, 16.0), 0.0, root)
	_instantiate_asset("cliff_large", Vector3(-32.0, 0.0, 24.0), 0.0, root)
	_instantiate_asset("cliff_corner_in", Vector3(24.0, 0.0, 16.0), 0.0, root)

	# 2.5 Industrial Trench crossing under bridge (along X axis at Y=0)
	_instantiate_asset("trench_industrial", Vector3(-8.0, 0.0, 0.0), 90.0, root)
	_instantiate_asset("trench_industrial", Vector3(8.0, 0.0, 0.0), 90.0, root)

	# 3. Heavy Bridge (Crossing canyon from Z = -16 to Z = +16, Deck Y = 8.0)
	_instantiate_asset("gearforge_bridge_heavy" if ASSETS.has("gearforge_bridge_heavy") else "bridge_heavy", Vector3(0.0, 0.0, 0.0), 0.0, root)

	# 4. South Road Approach
	_instantiate_asset("road_straight", Vector3(0.0, 8.0, -24.0), 0.0, root)
	_instantiate_asset("road_barrier", Vector3(-6.6, 8.0, -20.0), 0.0, root)
	_instantiate_asset("road_barrier", Vector3(6.6, 8.0, -20.0), 0.0, root)
	_instantiate_asset("road_barrier", Vector3(-6.6, 8.0, -28.0), 0.0, root)
	_instantiate_asset("road_barrier", Vector3(6.6, 8.0, -28.0), 0.0, root)

	# 5. North Road & Fortress Line (Deck Y = 8.0)
	_instantiate_asset("road_straight", Vector3(0.0, 8.0, 24.0), 0.0, root)
	_instantiate_asset("fortress_gate", Vector3(0.0, 8.0, 28.0), 0.0, root)
	_instantiate_asset("wall_straight", Vector3(18.0, 8.0, 28.0), 0.0, root)
	_instantiate_asset("wall_corner", Vector3(30.0, 8.0, 28.0), 0.0, root)
	_instantiate_asset("wall_tower", Vector3(30.0, 8.0, 34.0), 0.0, root)
	_instantiate_asset("defensive_bastion", Vector3(18.0, 8.0, 32.0), 0.0, root)
	_instantiate_asset("wall_straight", Vector3(-18.0, 8.0, 28.0), 0.0, root)
	_instantiate_asset("wall_tower", Vector3(-28.0, 8.0, 28.0), 0.0, root)

	# 6. Industrial Pipelines running along canyon floor and cliff face
	_instantiate_asset("industrial_pipe_straight", Vector3(-14.0, 0.0, 0.0), 90.0, root)
	_instantiate_asset("industrial_pipe_straight", Vector3(-14.0, 0.0, 16.0), 90.0, root)


func _assemble_palette_row() -> void:
	var root := $PaletteRoot
	# Arrange all 15 assets in an inspection row along Z = -50
	var items := [
		["bridge_heavy", -48.0],
		["trench_industrial", -38.0],
		["cliff_straight", -28.0],
		["cliff_corner_in", -20.0],
		["cliff_corner_out", -12.0],
		["cliff_ramp", -4.0],
		["cliff_large", 6.0],
		["fortress_gate", 20.0],
		["wall_straight", 32.0],
		["wall_corner", 40.0],
		["wall_tower", 46.0],
		["defensive_bastion", 54.0],
		["road_straight", 62.0],
		["road_barrier", 68.0],
		["industrial_pipe_straight", 74.0],
	]
	for item in items:
		_instantiate_asset(item[0], Vector3(item[1], 0.0, -52.0), 0.0, root)


func _place_scale_units() -> void:
	var root := $UnitsRoot

	# Heavy Titan Crownpiercer (11.4m) crossing the center of the Heavy Bridge
	var titan: Node3D = TitanGLB.instantiate()
	titan.position = Vector3(0.0, 8.0, -4.0)
	root.add_child(titan)

	# Medium Quad-Walker Ironbastion (5.2m) guarding Fortress Gate
	var quad: Node3D = QuadWalkerGLB.instantiate()
	quad.position = Vector3(0.0, 8.0, 20.0)
	quad.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	root.add_child(quad)

	# Light Biped Walker Ironstride (4.5m) escorting on south bridge entrance
	var walker: Node3D = WalkerGLB.instantiate()
	walker.position = Vector3(-4.5, 8.0, -12.0)
	root.add_child(walker)


func _set_view(rig_pos: Vector3, dist: float) -> void:
	rig.position = rig_pos
	if rig.has_method("_update_camera_offset"):
		rig.distance = dist
		rig._update_camera_offset()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_set_view(Vector3(0, 0, 15), 48.0)
			KEY_2:
				_set_view(Vector3(0, 8, 0), 28.0)
			KEY_3:
				_set_view(Vector3(0, 8, 28), 26.0)
			KEY_4:
				_set_view(Vector3(15, 0, -45), 38.0)
			KEY_H:
				hud.visible = not hud.visible


func _process(delta: float) -> void:
	_elapsed += delta
	var fps := Engine.get_frames_per_second()
	readout.text = "14 MODULAR ASSETS // 13.5K TRIS // FPS: %d\n[1] Overview [2] Bridge [3] Gate [4] Palette Row [H] Hide HUD" % fps
