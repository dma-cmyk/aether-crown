extends SceneTree
## Phase 1.5 full-match playtest driver (headless, fast sim).
## Drives a simple player strategy at 2s ticks with time_scale 8:
##   capture outpost -> build army -> destroy enemy HQ.
## Modes: --mode=player-win (default) | --mode=enemy-win (player idle).
## Prints a timeline and the final sim-time result.
## Usage: godot --headless --path game --script res://tests/phase1_5_playtest.gd -- --mode=player-win

const InfDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")
const MarDef: UnitDefinition = preload("res://resources/units/gf_marksman.tres")
const HevDef: UnitDefinition = preload("res://resources/units/gf_heavy_guard.tres")

var _frame: int = 0
var _map: Node = null
var _mode: String = "player-win"
var _think_left: float = 0.0
var _log_left: float = 0.0
var _done: bool = false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			_mode = a.get_slice("=", 1)
	Engine.time_scale = 8.0
	change_scene_to_file("res://scenes/maps/phase1_5_match.tscn")
	print("PLAYTEST mode=", _mode, " time_scale=8")


func _units(player_flag: bool) -> Array:
	var list: Array = []
	for o in get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_alive() and u.is_player == player_flag:
			list.append(u)
	return list


func _process(delta: float) -> bool:
	_frame += 1
	if _map == null:
		_map = get_first_node_in_group("match_map")
		if _map == null:
			return false
	var mm: MatchManager = _map.get("match_mgr")
	if not mm.is_playing():
		if not _done:
			_done = true
			var won := mm.phase == MatchManager.Phase.VICTORY
			print("PLAYTEST_RESULT mode=", _mode, " won=", won, " sim_time=", mm.format_time(),
				" kills_p=", _map.kills_by_player, " kills_e=", _map.kills_by_enemy)
			print("PLAYTEST OK" if (won == (_mode == "player-win")) else "PLAYTEST NG unexpected outcome")
			quit(0 if (won == (_mode == "player-win")) else 1)
		return _done
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = 2.0
		if _mode == "player-win":
			_player_think()
	_log_left -= delta
	if _log_left <= 0.0:
		_log_left = 15.0
		var outpost: RTSOutpost = _map.get("outpost")
		var eco_p: RTSEconomy = _map.get("economy_p")
		var eco_e: RTSEconomy = _map.get("economy_e")
		var strat: EnemyStrategist = _map.get("strategist")
		print("PLAYTEST t=", mm.format_time(), " p=", _units(true).size(), " e=", _units(false).size(),
			" mat_p=", int(eco_p.material), " mat_e=", int(eco_e.material),
			" outpost=", outpost.owner_name(), " ai=", strat.plan_name(),
			" hq_p=", int(_map.player_hq.hp), " hq_e=", int(_map.enemy_hq.hp))
	if mm.elapsed > 15.0 * 60.0:
		print("PLAYTEST NG timeout, no result in 15 sim-minutes")
		quit(1)
		return true
	return false


func _player_think() -> void:
	var eco_p: RTSEconomy = _map.get("economy_p")
	var q_p: ProductionQueue = _map.get("queue_p")
	var orders: OrderManager = _map.get("orders")
	var outpost: RTSOutpost = _map.get("outpost")
	var force := _units(true)
	# Production: keep queue fed, infantry-heavy mix with marksman/heavy.
	if q_p.queue.size() < 2:
		var heavies := 0
		var marksmen := 0
		for u in force:
			var id := str((u as RTSUnit).definition.id)
			if id == "gf_heavy_guard":
				heavies += 1
			elif id == "gf_marksman":
				marksmen += 1
		var pick: UnitDefinition = null
		if force.size() >= 5 and heavies * 3 < force.size() and eco_p.can_afford(float(HevDef.cost_metal)):
			pick = HevDef
		elif marksmen * 2 < force.size() and eco_p.can_afford(float(MarDef.cost_metal)):
			pick = MarDef
		elif eco_p.can_afford(float(InfDef.cost_metal)):
			pick = InfDef
		if pick != null:
			q_p.try_enqueue(pick, eco_p)
	# Orders: big army -> enemy HQ, else contest/hold the outpost.
	var calm: Array = []
	for u in force:
		var unit := u as RTSUnit
		if unit.state == RTSUnit.State.IDLE or unit.state == RTSUnit.State.MOVING:
			calm.append(unit)
	if calm.is_empty():
		return
	if force.size() >= 12:
		orders.issue_attack_move(calm, (_map.enemy_hq as RTSBuilding).global_position)
	else:
		orders.issue_attack_move(calm, (outpost as RTSOutpost).global_position)
