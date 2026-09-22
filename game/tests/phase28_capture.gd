extends SceneTree
## Phase 2.8 screenshot set on the canonical strategic match (production
## visuals). Six beats: player base, strategic overview, city capture,
## factory + walker production, combined battle, victory, enemy base.
## Usage: godot --path game --script res://tests/phase28_capture.gd
const WalDef: UnitDefinition = preload("res://resources/units/gf_walker.tres")
const InfDef: UnitDefinition = preload("res://resources/units/2d_infantry.tres")

const OUT_DIR := "res://../docs/screenshots/phase28"

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
		push_error("PHASE28_CAPTURE map never loaded")
		quit(1)
		return
	_rig = (_map as Node).get_node("CameraRig") as Node3D
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	for i in range(40):
		await self.process_frame

	# 1: Player base (production HQ + factory plant + banners).
	_view(Vector3(-32, 0, -32), 30.0)
	await _capture("p28_01_player_base")

	# 2: Strategic overview (bases + 5 cities + roads, production cities).
	_view(Vector3(0, 0, 0), 62.0)
	await _capture("p28_02_strategic_overview")

	# 3: City capture — starting army onto West (production Factory city).
	(_map.get("orders") as OrderManager).issue_attack_move(_player_units(), Vector3(-22, 0, 4))
	await _sim_frames(420)
	_view(Vector3(-22, 0, 4), 26.0)
	await _capture("p28_03_city_capture")

	# 4: Factory + walker production (spawn a walker at the player HQ).
	var eco: RTSEconomy = _map.get("economy_p")
	eco.material = 220.0
	eco.aether = 40.0
	var q: ProductionQueue = _map.get("queue_p")
	q.try_enqueue(WalDef, eco)
	q.set("progress_sec", 999.0)
	await _sim_frames(40)
	var w := _player_walkers()
	if not w.is_empty():
		_view((w[0] as Node3D).global_position + Vector3(4, 0, 2), 20.0)
	await _capture("p28_04_walker_production")

	# 5: Combined battle at the enemy HQ.
	var hq_e: RTSBuilding = _map.get("enemy_hq")
	var spot := hq_e.global_position + Vector3(-16, 0, -16)
	for i in range(4):
		_map.call("spawn_unit", InfDef, false, spot + Vector3(float(i) * 2.0, 0, 2.0))
	var all: Array = []
	all.append_array(_player_units())
	all.append_array(_player_walkers())
	(_map.get("orders") as OrderManager).issue_attack_move(all, hq_e.global_position)
	await _sim_frames(260)
	_view(hq_e.global_position + Vector3(-10, 0, -10), 28.0)
	await _capture("p28_05_army_battle")

	# 6: Victory overlay (real damage API on the enemy HQ).
	hq_e.take_damage(999999.0, null)
	await _sim_frames(40)
	_view(Vector3(0, 0, 0), 44.0)
	await _capture("p28_06_victory")

	# 7 (bonus): enemy base (production HQ, red banners).
	_view(Vector3(32, 0, 32), 30.0)
	await _capture("p28_07_enemy_base")

	print("PHASE28_CAPTURE_DONE shots=7")
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
		print("PHASE28_CAPTURE_OK %s" % path)


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
