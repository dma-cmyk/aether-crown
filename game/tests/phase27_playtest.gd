extends SceneTree
## Phase 2.7 full-match playtest driver for the canonical strategic match.
## Plays a real match end-to-end at 2s think ticks with time_scale 8, using
## only normal gameplay paths (production queue, attack-move orders, city
## capture, district build). No debug damage, no wallet edits, no direct
## victory calls. Modes: --mode=player-win (default) | --mode=enemy-win
## (player idles, enemy AI must win). Prints timeline + result.
## Usage: godot --headless --path game --script res://tests/phase27_playtest.gd -- --mode=player-win

const InfDef: UnitDefinition = preload("res://resources/units/2d_infantry.tres")
const MarDef: UnitDefinition = preload("res://resources/units/2d_marksman.tres")
const HevDef: UnitDefinition = preload("res://resources/units/2d_heavy_guard.tres")
const WalDef: UnitDefinition = preload("res://resources/units/gf_walker.tres")

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
	Engine.time_scale = 3.0
	change_scene_to_file("res://scenes/maps/phase2d_strategic_match.tscn")
	print("PLAYTEST27 mode=", _mode, " time_scale=3")


func _units(player_flag: bool) -> Array:
	var list: Array = []
	for o in get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_alive() and u.is_player == player_flag:
			list.append(u)
	return list


func _walkers(player_flag: bool) -> Array:
	var out: Array = []
	for w in get_nodes_in_group("visual_walkers"):
		if bool((w as Node).call("is_alive")) and bool((w as Node).get("is_player")) == player_flag:
			out.append(w)
	return out


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
			print("PLAYTEST27_RESULT mode=", _mode, " won=", won, " sim_time=", mm.format_time(),
				" kills_p=", _map.kills_by_player, " kills_e=", _map.kills_by_enemy,
				" walkers_p=", _walkers(true).size(), " walkers_e=", _walkers(false).size(),
				" cities=", str(_map.city_counts()))
			print("PLAYTEST27 OK" if (won == (_mode == "player-win")) else "PLAYTEST27 NG unexpected outcome")
			quit(0 if (won == (_mode == "player-win")) else 1)
		return _done
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = 2.0
		if _mode == "player-win":
			_player_think()
	_log_left -= delta
	if _log_left <= 0.0:
		_log_left = 30.0
		var eco_p: RTSEconomy = _map.get("economy_p")
		var eco_e: RTSEconomy = _map.get("economy_e")
		var strat: EnemyStrategist = _map.get("strategist")
		print("PLAYTEST27 t=", mm.format_time(), " p=", _units(true).size(), " pw=", _walkers(true).size(),
			" e=", _units(false).size(), " ew=", _walkers(false).size(),
			" mat_p=", int(eco_p.material), " ae_p=%.0f" % eco_p.aether,
			" mat_e=", int(eco_e.material), " ai=", strat.plan_name(),
			" cities=", str(_map.city_counts()),
			" hq_p=", int(_map.player_hq.hp), " hq_e=", int(_map.enemy_hq.hp))
	if mm.elapsed > 25.0 * 60.0:
		print("PLAYTEST27 NG timeout, no result in 25 sim-minutes")
		quit(1)
		return true
	return false


## Simple but real strategy: hold production, capture nearby cities, build
## aether income, mix walkers in once funded, then death-ball the enemy HQ.
## Push thresholds count infantry-equivalents and scale modestly so the
## match runs its full loop (expand -> economy -> walkers -> siege).
func _player_think() -> void:
	var eco_p: RTSEconomy = _map.get("economy_p")
	var q_p: ProductionQueue = _map.get("queue_p")
	var orders: OrderManager = _map.get("orders")
	var force := _units(true)
	var walkers := _walkers(true)
	# Production: build toward the walker save — infantry expand the line
	# while saving, the walker goes in the moment the wallet covers it.
	if q_p.queue.size() < 2:
		var heavies := 0
		var marksmen := 0
		for u in force:
			var id := str((u as RTSUnit).definition.id)
			if id == "gf_heavy_guard":
				heavies += 1
			elif id == "gf_marksman":
				marksmen += 1
		# While saving for a walker, only cheap infantry (the save must
		# actually close; heavy/marksman spends would stall it forever).
		var saving := eco_p.material < float(WalDef.cost_metal)
		if saving and walkers.size() < 2:
			pass # hard hold: close the save before any spend
		elif walkers.size() * 6 < force.size() and eco_p.can_afford(float(WalDef.cost_metal)) and eco_p.aether >= float(WalDef.cost_aether):
			q_p.try_enqueue(WalDef, eco_p)
		elif not saving and force.size() >= 5 and heavies * 3 < force.size() and eco_p.can_afford(float(HevDef.cost_metal)) and eco_p.aether >= float(HevDef.cost_aether):
			q_p.try_enqueue(HevDef, eco_p)
		elif not saving and marksmen * 2 < force.size() and eco_p.can_afford(float(MarDef.cost_metal)) and eco_p.aether >= float(MarDef.cost_aether):
			q_p.try_enqueue(MarDef, eco_p)
		elif eco_p.can_afford(float(InfDef.cost_metal)):
			q_p.try_enqueue(InfDef, eco_p)
	# Districts: industry first (economy), then military (pop) on owned
	# cities — the same buttons the HUD exposes. Districts hold while the
	# first walker is unbuilt and the wallet is still saving toward one
	# (districts would dip the wallet below the walker price).
	var saving_for_walker := walkers.size() < 2 and eco_p.material < float(WalDef.cost_metal)
	if not saving_for_walker and eco_p.material > 80.0 and eco_p.aether > 10.0:
		for c in _map.cities:
			var city := c as RTSCity
			if city != null and city.owner_side == RTSCity.Owner.PLAYER:
				if _map.call("try_build_player", str(city.city_id), "industry") == "ok":
					break
	if not saving_for_walker and eco_p.material > 90.0 and eco_p.aether > 20.0:
		for c in _map.cities:
			var city := c as RTSCity
			if city != null and city.owner_side == RTSCity.Owner.PLAYER:
				if _map.call("try_build_player", str(city.city_id), "military") == "ok":
					break
	# Orders: calm units + walkers act together. Capture the whole map
	# first (economy/aether), then siege the enemy HQ. Expansion orders go
	# to units that are done fighting; the final push includes everyone.
	var calm: Array = []
	for u in force:
		var unit := u as RTSUnit
		if unit.state == RTSUnit.State.IDLE or unit.state == RTSUnit.State.MOVING:
			calm.append(unit)
	for w in walkers:
		calm.append(w)
	if calm.is_empty():
		return
	if force.size() >= 16:
		orders.issue_attack_move(calm, (_map.enemy_hq as RTSBuilding).global_position)
	else:
		var target := _expansion_target()
		orders.issue_attack_move(calm, target)


func _expansion_target() -> Vector3:
	for cid in ["west_foundry", "central_nexus", "north_relay", "south_works", "east_bastion"]:
		var city := _map.get_city(cid) as RTSCity
		if city != null and city.owner_side != RTSCity.Owner.PLAYER:
			return city.global_position
	return (_map.enemy_hq as RTSBuilding).global_position
