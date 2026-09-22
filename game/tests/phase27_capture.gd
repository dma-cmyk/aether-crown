extends SceneTree
## Phase 2.7 screenshot set on the canonical strategic match. Drives a
## scripted-but-real match slice (normal gameplay calls only) and captures
## the loop beats: match start, city capture, walker production, army
## battle, and victory. Usage:
##   godot --path game --script res://tests/phase27_capture.gd
const WalDef: UnitDefinition = preload("res://resources/units/gf_walker.tres")
const InfDef: UnitDefinition = preload("res://resources/units/2d_infantry.tres")

const OUT_DIR := "res://../docs/screenshots/phase27"

var _map: Node = null
var _rig: Node3D = null


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase2d_strategic_match.tscn")
	_run()


func _run() -> void:
	# Scene loads on the next idle frames; wait for the map group.
	for i in range(120):
		await self.process_frame
		_map = get_first_node_in_group("match_map")
		if _map != null:
			break
	if _map == null:
		push_error("PHASE27_CAPTURE map never loaded")
		quit(1)
		return
	_rig = (_map as Node).get_node("CameraRig") as Node3D
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	for i in range(40):
		await self.process_frame

	# Beat 1: match start (base + HUD).
	_view(Vector3(-32, 0, -32), 30.0)
	await _capture("p27_01_match_start")

	# Beat 2: city capture — move the starting army onto West and let the
	# capture timer run.
	(_map.get("orders") as OrderManager).issue_attack_move(_player_units(), Vector3(-22, 0, 4))
	await _sim_frames(420)
	_view(Vector3(-22, 0, 4), 24.0)
	await _capture("p27_02_city_capture")

	# Beat 3: walker production — real queue, real spawn (test-side wallet
	# top-up so the screenshot does not wait for income).
	var eco: RTSEconomy = _map.get("economy_p")
	eco.material = 220.0
	eco.aether = 40.0
	var q: ProductionQueue = _map.get("queue_p")
	q.try_enqueue(WalDef, eco)
	q.set("progress_sec", 999.0)
	await _sim_frames(40)
	var w := _player_walkers()
	if not w.is_empty():
		_view((w[0] as Node3D).global_position, 18.0)
	await _capture("p27_03_walker_production")

	# Beat 4: combined battle — reinforce a real fight at the enemy HQ.
	var hq_e: RTSBuilding = _map.get("enemy_hq")
	var spot := hq_e.global_position + Vector3(-14, 0, -14)
	for i in range(4):
		_map.call("spawn_unit", InfDef, false, spot + Vector3(float(i) * 2.0, 0, 2.0))
	var all: Array = []
	all.append_array(_player_units())
	all.append_array(_player_walkers())
	(_map.get("orders") as OrderManager).issue_attack_move(all, hq_e.global_position)
	await _sim_frames(240)
	_view(hq_e.global_position + Vector3(-8, 0, -8), 26.0)
	await _capture("p27_04_army_battle")

	# Beat 5: victory — destroy the enemy HQ through the real damage API.
	hq_e.take_damage(999999.0, null)
	await _sim_frames(40)
	_view(Vector3(0, 0, 0), 40.0)
	await _capture("p27_05_victory")

	print("PHASE27_CAPTURE_DONE shots=5")
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
		print("PHASE27_CAPTURE_OK %s" % path)


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
