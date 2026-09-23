extends SceneTree
## Phase 2.10 screenshot set on the canonical strategic match (Gemini
## Production Terrain). Beats: terrain overview, player plateau, three
## routes, central battlefield, heavy bridge battle, ravine, fortress
## approach, enemy plateau, mixed army, max zoom-out, victory, defeat.
## Usage: godot --path game --script res://tests/phase210_capture.gd
const WalDef: UnitDefinition = preload("res://resources/units/gf_walker.tres")
const InfDef: UnitDefinition = preload("res://resources/units/2d_infantry.tres")

const OUT_DIR := "res://../docs/screenshots/phase210"

var _map: Node = null
var _rig: Node3D = null

func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase2d_strategic_match.tscn")
	_run()

func _run() -> void:
	for i in range(120):
		await self.process_frame
		_map = get_first_node_in_group("match_map")
		if _map != null:
			break
	if _map == null:
		push_error("PHASE210_CAPTURE map never loaded")
		quit(1)
		return
	_rig = (_map as Node).get_node("CameraRig") as Node3D
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	for i in range(40):
		await self.process_frame

	# 01: Full strategic overview (terrain + 3 routes + bridge + fortress).
	_view(Vector3(0, 0, 0), 78.0)
	await _capture("p210_01_terrain_overview")

	# 02: Player Industrial Plateau (HQ + Aether plant).
	_view(Vector3(-32, 0, -32), 26.0)
	await _capture("p210_02_player_plateau")

	# 03: North route (mountain ridge toward North Relay).
	_view(Vector3(-8, 0, -22), 34.0)
	await _capture("p210_03_north_route")

	# 04: Central battlefield arena.
	_view(Vector3(-8, 0, 0), 28.0)
	await _capture("p210_04_central_battlefield")

	# 05: South route (lowland toward South Works).
	_view(Vector3(-8, 0, 16), 30.0)
	await _capture("p210_05_south_route")

	# 06: Heavy Bridge battle (walker crossing the deck).
	var eco: RTSEconomy = _map.get("economy_p")
	eco.material = 220.0
	eco.aether = 40.0
	var q: ProductionQueue = _map.get("queue_p")
	q.try_enqueue(WalDef, eco)
	q.set("progress_sec", 999.0)
	await _sim_frames(30)
	var w := _player_walkers()
	if not w.is_empty():
		(w[0] as VisualWalker).global_position = Vector3(2, 0, 0)
		(w[0] as VisualWalker).order_move(Vector3(32, 0, 0))
	# Enemy defenders at the east bank.
	var eco_e: RTSEconomy = _map.get("economy_e")
	eco_e.material = 220.0
	eco_e.aether = 40.0
	var qe: ProductionQueue = _map.get("queue_e")
	qe.try_enqueue(WalDef, eco_e)
	qe.set("progress_sec", 999.0)
	await _sim_frames(30)
	var we := _enemy_walkers()
	if not we.is_empty():
		(we[0] as VisualWalker).global_position = Vector3(28, 0, 0)
	await _sim_frames(170)
	_view(Vector3(16, 0, 0), 26.0)
	await _capture("p210_06_heavy_bridge_battle")

	# 07: Industrial ravine (gorge + aether veins, low angle).
	_view(Vector3(18, 0, -16), 30.0)
	await _capture("p210_07_industrial_ravine")

	# 08: Fortress approach (gate + walls on the plateau).
	_view(Vector3(36, 0, 18), 26.0)
	await _capture("p210_08_fortress_approach")

	# 09: Enemy Industrial Plateau (HQ fortress).
	_view(Vector3(34, 0, 36), 28.0)
	await _capture("p210_09_enemy_plateau")

	# 10: 10-20 unit mixed army battle on the central route.
	var hq_e: RTSBuilding = _map.get("enemy_hq")
	var spot := Vector3(10, 0, -6)
	for i in range(8):
		_map.call("spawn_unit", InfDef, true, spot + Vector3(float(i % 4) * 2.0, 0, float(i / 4) * 2.0))
	for i in range(6):
		_map.call("spawn_unit", InfDef, false, Vector3(20, 0, 4) + Vector3(float(i % 3) * 2.0, 0, float(i / 3) * 2.0))
	var all: Array = []
	all.append_array(_player_units())
	all.append_array(_player_walkers())
	(_map.get("orders") as OrderManager).issue_attack_move(all, hq_e.global_position)
	await _sim_frames(220)
	_view(Vector3(20, 0, 2), 30.0)
	await _capture("p210_10_mixed_army_battle")

	# 11: Maximum zoom-out (whole 140m map readable).
	_view(Vector3(0, 0, 0), 60.0)
	_rig.set("distance", 60.0)
	_rig.call("_update_camera_offset")
	await _capture("p210_11_max_zoomout")

	# 12: Victory overlay (end_game pauses the tree; unpause to capture).
	hq_e.take_damage(999999.0, null)
	paused = false
	for i in range(30):
		await self.process_frame
	_view(Vector3(0, 0, 0), 50.0)
	await _capture("p210_12_victory")

	# 13 (bonus): Defeat overlay (fresh scene for a clean loss).
	print("PHASE210_CAPTURE part1 done")
	change_scene_to_file("res://scenes/maps/phase2d_strategic_match.tscn")
	for i in range(140):
		await self.process_frame
	_map = get_first_node_in_group("match_map")
	_rig = (_map as Node).get_node("CameraRig") as Node3D
	var hq_p: RTSBuilding = _map.get("player_hq")
	hq_p.take_damage(999999.0, null)
	paused = false
	for i in range(30):
		await self.process_frame
	_view(Vector3(-32, 0, -32), 40.0)
	await _capture("p210_13_defeat")

	# 14 (bonus): three-routes top-down readability.
	_view(Vector3(0, 0, 0), 95.0)
	await _capture("p210_14_map_size_eval")

	print("PHASE210_CAPTURE_DONE shots=14")
	quit(0)

func _view(pos: Vector3, dist: float) -> void:
	_rig.position = Vector3(pos.x, 0, pos.z + dist)
	_rig.set("distance", dist)
	_rig.call("_update_camera_offset")

func _sim_frames(n: int) -> void:
	for i in range(n):
		await self.physics_frame

func _capture(name_text: String) -> void:
	for i in range(14):
		await self.process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(name_text + ".png")
	var err := root.get_texture().get_image().save_png(path)
	if err != OK:
		push_error("CAPTURE_FAILED %s (%d)" % [path, err])
	else:
		print("PHASE210_CAPTURE_OK %s" % path)

func _player_units() -> Array:
	var out: Array = []
	for o in get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_alive() and u.is_player:
			out.append(u)
	return out

func _player_walkers() -> Array:
	var out: Array = []
	for w in get_nodes_in_group("visual_walkers"):
		if bool((w as Node).call("is_alive")) and bool((w as Node).get("is_player")):
			out.append(w)
	return out

func _enemy_walkers() -> Array:
	var out: Array = []
	for w in get_nodes_in_group("visual_walkers"):
		if bool((w as Node).call("is_alive")) and not bool((w as Node).get("is_player")):
			out.append(w)
	return out
