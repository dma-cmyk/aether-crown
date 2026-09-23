extends Node3D
## Aether Crown RTS Production Terrain Foundation 01 Showcase
##
## Evaluates:
## - Overall Battlefield Scale & 3-Tier Elevation (0m Ravine -> 8m Central -> 16m Plateaus)
## - Three Distinct Strategic Routes (North ridge, Central highway, South lowland)
## - Central Battlefield Arena & Clash Capacity (wide open clash area)
## - Industrial Ravine & Heavy Military Bridge Slot Compatibility (32m span at X=18m)
## - Fortress Approach Bottleneck & Fortress Gate Plateau (Gate + Walls fit naturally)
## - Player & Enemy Industrial High Grounds (Spacious staging pads)
##
## Controls:
## - 1..9, 0, J, K, L, M: Switch Camera Presets (1-14)
## - WASD / Arrows: Pan camera
## - Q / E or Mouse Wheel: Zoom
## - C: Capture full screenshot set (14 images)
## - H: Toggle HUD overlay

const TerrainGLB: PackedScene = preload("res://assets/models/map/aether_crown_terrain_foundation.glb")

const ASSETS: Dictionary = {
	"bridge_heavy": preload("res://assets/models/map/gearforge_bridge_heavy.glb"),
	"fortress_gate": preload("res://assets/models/map/gearforge_fortress_gate.glb"),
	"wall_straight": preload("res://assets/models/map/gearforge_wall_straight.glb"),
	"wall_tower": preload("res://assets/models/map/gearforge_wall_tower.glb"),
	"defensive_bastion": preload("res://assets/models/map/gearforge_defensive_bastion.glb"),
	"hq_command": preload("res://assets/models/gearforge_hq_command.glb"),
	"factory": preload("res://assets/models/gearforge_factory.glb"),
	"aether_well": preload("res://assets/models/gearforge_aether_well.glb"),
	"boiler_works": preload("res://assets/models/gearforge_boiler_works.glb"),
	"barracks": preload("res://assets/models/gearforge_barracks.glb"),
	"walker": preload("res://assets/models/gearforge_walker.glb"),
	"quad_walker": preload("res://assets/models/gearforge_medium_quad_walker.glb"),
}

const PRESETS: Array = [
	{"name": "01_full_isometric_overview", "target": Vector3(0, 8, 0), "dist": 135.0, "pitch": 48.0, "yaw": -40.0},
	{"name": "02_top_view", "target": Vector3(0, 8, 0), "dist": 185.0, "pitch": 88.0, "yaw": -45.0},
	{"name": "03_player_plateau", "target": Vector3(-32, 12, -32), "dist": 55.0, "pitch": 38.0, "yaw": -35.0},
	{"name": "04_three_routes", "target": Vector3(-12, 8, 0), "dist": 90.0, "pitch": 50.0, "yaw": -45.0},
	{"name": "05_central_battlefield", "target": Vector3(-10, 8, 0), "dist": 55.0, "pitch": 36.0, "yaw": -35.0},
	{"name": "06_industrial_ravine", "target": Vector3(18, 4, -4), "dist": 62.0, "pitch": 44.0, "yaw": -68.0},
	{"name": "07_heavy_bridge_reference", "target": Vector3(18, 8, 0), "dist": 45.0, "pitch": 35.0, "yaw": -48.0},
	{"name": "08_fortress_approach", "target": Vector3(30, 10, 10), "dist": 54.0, "pitch": 36.0, "yaw": -55.0},
	{"name": "09_fortress_plateau", "target": Vector3(38, 12, 20), "dist": 48.0, "pitch": 35.0, "yaw": -45.0},
	{"name": "10_enemy_plateau", "target": Vector3(34, 15, 36), "dist": 55.0, "pitch": 38.0, "yaw": -35.0},
	{"name": "11_low_angle_elevation", "target": Vector3(10, 8, 0), "dist": 50.0, "pitch": 18.0, "yaw": -48.0},
	{"name": "12_walker_traversal_scale", "target": Vector3(18, 8, 0), "dist": 28.0, "pitch": 25.0, "yaw": -45.0},
	{"name": "13_terrain_only_isometric", "target": Vector3(0, 8, 0), "dist": 135.0, "pitch": 48.0, "yaw": -40.0},
	{"name": "14_three_routes_top_debug", "target": Vector3(0, 8, 0), "dist": 185.0, "pitch": 88.0, "yaw": -45.0},
	{"name": "15_material_overview", "target": Vector3(0, 8, 0), "dist": 125.0, "pitch": 46.0, "yaw": -42.0},
	{"name": "16_grass_dirt_transition", "target": Vector3(-16, 9, -10), "dist": 32.0, "pitch": 38.0, "yaw": -35.0},
	{"name": "17_cliff_surface", "target": Vector3(18, 5, -8), "dist": 35.0, "pitch": 28.0, "yaw": -60.0},
	{"name": "18_central_surface", "target": Vector3(-6, 8, 0), "dist": 38.0, "pitch": 32.0, "yaw": -40.0},
	{"name": "19_fortress_surface", "target": Vector3(36, 12, 18), "dist": 40.0, "pitch": 34.0, "yaw": -48.0},
	{"name": "20_rts_distance_material", "target": Vector3(-8, 8, 0), "dist": 65.0, "pitch": 48.0, "yaw": -45.0},
]

@onready var rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var hud: CanvasLayer = $HUD
@onready var label_preset: Label = $HUD/Panel/VBox/PresetLabel
@onready var label_stats: Label = $HUD/Panel/VBox/StatsLabel
@onready var ref_assets_root: Node3D = $ReferenceAssetsRoot

var _current_preset_idx: int = 0
var _is_capturing: bool = false
var _cam_target: Vector3 = Vector3(0, 8, 0)
var _cam_dist: float = 135.0
var _cam_pitch: float = 48.0
var _cam_yaw: float = -40.0


func _ready() -> void:
	_spawn_terrain()
	_place_reference_diorama()
	apply_preset(0)
	print("TERRAIN_FOUNDATION_SHOWCASE_READY: Terrain and reference assets loaded.")


func _process(delta: float) -> void:
	# Manual pan controls
	var wish := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): wish.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): wish.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): wish.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): wish.x += 1.0

	if wish.length_squared() > 0.01:
		var rad_yaw := deg_to_rad(_cam_yaw)
		var fwd := Vector3(sin(rad_yaw), 0, -cos(rad_yaw))
		var rgt := Vector3(cos(rad_yaw), 0, sin(rad_yaw))
		var move := (rgt * wish.x + fwd * -wish.z).normalized()
		_cam_target += move * (30.0 * delta * (_cam_dist / 60.0))
		_update_camera()

	if Input.is_key_pressed(KEY_Q):
		_cam_dist = clampf(_cam_dist - 40.0 * delta, 10.0, 220.0)
		_update_camera()
	if Input.is_key_pressed(KEY_E):
		_cam_dist = clampf(_cam_dist + 40.0 * delta, 10.0, 220.0)
		_update_camera()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_1: apply_preset(0)
			KEY_2: apply_preset(1)
			KEY_3: apply_preset(2)
			KEY_4: apply_preset(3)
			KEY_5: apply_preset(4)
			KEY_6: apply_preset(5)
			KEY_7: apply_preset(6)
			KEY_8: apply_preset(7)
			KEY_9: apply_preset(8)
			KEY_0: apply_preset(9)
			KEY_J: apply_preset(10)
			KEY_K: apply_preset(11)
			KEY_L: apply_preset(12)
			KEY_M: apply_preset(13)
			KEY_C: capture_all_screenshots()
			KEY_H: hud.visible = not hud.visible


func _spawn_terrain() -> void:
	if TerrainGLB != null:
		var terrain_inst := TerrainGLB.instantiate()
		terrain_inst.name = "TerrainMeshInstance"
		$TerrainRoot.add_child(terrain_inst)
	else:
		push_error("Failed to preload terrain GLB!")


func _place_reference_diorama() -> void:
	var root := $ReferenceAssetsRoot

	# 1. Heavy Military Bridge in dedicated slot (X=18, Y=0, Z=0)
	# Rotated 90 deg so the 32m span connects West bank (X=2..10) to East bank (X=26..34) at Deck Z = 8.0m
	var bridge := _spawn_asset("bridge_heavy", Vector3(18.0, 0.0, 0.0), 90.0, root)
	if bridge != null:
		bridge.name = "BridgeReference"

	# 2. Fortress Complex on Gate Plateau (38, 11.8, 20)
	_spawn_asset("fortress_gate", Vector3(38.0, 11.8, 20.0), -55.0, root)
	_spawn_asset("wall_straight", Vector3(27.5, 11.8, 30.5), 35.0, root)
	_spawn_asset("wall_straight", Vector3(48.5, 11.8, 9.5), 35.0, root)
	_spawn_asset("wall_tower", Vector3(55.0, 11.8, 3.0), 0.0, root)
	_spawn_asset("defensive_bastion", Vector3(26.0, 9.0, -18.0), -30.0, root)

	# 3. Player Base HQ & Staging (around -32, 12.0, -32)
	_spawn_asset("hq_command", Vector3(-32.0, 12.0, -32.0), 45.0, root)
	_spawn_asset("aether_well", Vector3(-24.0, 12.0, -38.0), 30.0, root)
	_spawn_asset("barracks", Vector3(-38.0, 12.0, -24.0), 60.0, root)

	# 4. Enemy Base HQ (around 34, 15.5, 36)
	_spawn_asset("hq_command", Vector3(34.0, 15.5, 36.0), -135.0, root)

	# 5. Strategic Cities
	_spawn_asset("factory", Vector3(-22.0, 9.8, 4.0), 15.0, root)         # West Foundry
	_spawn_asset("aether_well", Vector3(2.0, 13.5, -18.0), 0.0, root)      # North Relay
	_spawn_asset("hq_command", Vector3(-12.0, 8.0, 0.0), 0.0, root, 0.72)  # Central Nexus
	_spawn_asset("boiler_works", Vector3(-2.0, 4.5, 20.0), -20.0, root)    # South Works

	# 6. Walkers for scale reference
	# Bridge crossing walker
	_spawn_asset("walker", Vector3(18.0, 8.0, 0.0), -90.0, root)
	# Central battle formation (West vs East)
	_spawn_asset("walker", Vector3(-14.0, 8.0, -5.0), -80.0, root)
	_spawn_asset("walker", Vector3(-14.0, 8.0, 5.0), -100.0, root)
	_spawn_asset("quad_walker", Vector3(-4.0, 8.0, -3.0), 90.0, root)
	_spawn_asset("quad_walker", Vector3(-4.0, 8.0, 3.0), 80.0, root)
	# Player Base staging
	_spawn_asset("walker", Vector3(-24.0, 12.0, -24.0), -45.0, root)
	_spawn_asset("quad_walker", Vector3(-26.0, 12.0, -18.0), -45.0, root)
	# Fortress defense walker
	_spawn_asset("walker", Vector3(35.0, 11.8, 17.0), 125.0, root)


func _spawn_asset(key: String, pos: Vector3, rot_y_deg: float, parent: Node, scale_mult: float = 1.0) -> Node3D:
	if not ASSETS.has(key):
		return null
	var scene: PackedScene = ASSETS[key]
	var inst: Node3D = scene.instantiate()
	inst.position = pos
	inst.rotation_degrees = Vector3(0, rot_y_deg, 0)
	if scale_mult != 1.0:
		inst.scale = Vector3.ONE * scale_mult
	parent.add_child(inst)
	return inst


func _set_reference_assets_mode(mode: String) -> void:
	if ref_assets_root == null:
		return
	for child in ref_assets_root.get_children():
		if mode == "terrain_only":
			# Only keep bridge to show slot fit, hide buildings & walkers
			child.visible = (child.name == "BridgeReference")
		elif mode == "minimal":
			# Bridge and city markers only
			child.visible = (child.name == "BridgeReference" or "hq" in child.name.to_lower() or "factory" in child.name.to_lower())
		else:
			# "full": show all
			child.visible = true


func apply_preset(idx: int) -> void:
	if idx < 0 or idx >= PRESETS.size():
		return
	_current_preset_idx = idx
	var p: Dictionary = PRESETS[idx]
	_cam_target = p["target"]
	_cam_dist = float(p["dist"])
	_cam_pitch = float(p["pitch"])
	_cam_yaw = float(p["yaw"])

	# Handle asset density per preset
	if p["name"] == "13_terrain_only_isometric" or p["name"] == "14_three_routes_top_debug":
		_set_reference_assets_mode("terrain_only")
	else:
		_set_reference_assets_mode("full")

	_update_camera()

	if label_preset != null:
		label_preset.text = "Preset [%d/20]: %s" % [idx + 1, p["name"]]
	if label_stats != null:
		label_stats.text = "Terrain: 140x140m | 19,881 verts | 39,200 tris | Iris Xe Optimized\nPBR Textures: 4 Sets (1024x1024) | Keys: 1-9, 0, J, K, etc. | C (Capture All)"


func _update_camera() -> void:
	rig.position = _cam_target
	rig.rotation_degrees = Vector3(0, _cam_yaw, 0)

	var rad_pitch := deg_to_rad(_cam_pitch)
	var cy := sin(rad_pitch) * _cam_dist
	var cz := cos(rad_pitch) * _cam_dist
	camera.position = Vector3(0, cy, cz)
	camera.rotation_degrees = Vector3(-_cam_pitch, 0, 0)


func capture_all_screenshots() -> void:
	if _is_capturing:
		return
	_is_capturing = true
	var was_hud_visible := hud.visible
	hud.visible = false

	var out_dir := "res://../docs/screenshots/gemini_terrain_foundation"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	for i in range(PRESETS.size()):
		apply_preset(i)
		for f in range(6):
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var p_name: String = PRESETS[i]["name"]
		var path := ProjectSettings.globalize_path(out_dir.path_join(p_name + ".png"))
		img.save_png(path)
		print("SAVED_SCREENSHOT: ", path)

	hud.visible = was_hud_visible
	_is_capturing = false
	print("CAPTURE_ALL_COMPLETE: 14 screenshots saved to docs/screenshots/gemini_terrain_foundation/")
