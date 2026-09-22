extends SceneTree
## Phase 2A integration test (headless). Covers: 3 cities exist, all neutral
## at start, player capture, enemy capture, CONTESTED freeze, player and
## enemy recapture, Material bonus up/down with ownership, city-count HUD
## consistency, enemy AI city targeting, HQ combat, Victory/Defeat, Restart.
## Usage: godot --headless --path game --script res://tests/phase2a_test.gd

const InfDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")
const HevDef: UnitDefinition = preload("res://resources/units/gf_heavy_guard.tres")

var _frame: int = 0
var _phase: int = 0
var _deadline: int = 0

var _map: Node = null
var _eco_p: RTSEconomy
var _eco_e: RTSEconomy
var _mm: MatchManager
var _orders: OrderManager
var _strat: EnemyStrategist
var _west: RTSCity
var _central: RTSCity
var _east: RTSCity

var _mat0: float = 0.0
var _prog0: float = 0.0


func _initialize() -> void:
	# change_scene (not manual add_child) so current_scene is set and the
	# in-game Restart path (reload_current_scene) works under test.
	change_scene_to_file("res://scenes/maps/phase2a_city_war.tscn")


func _grab() -> void:
	_map = get_first_node_in_group("match_map")
	_eco_p = _map.get("economy_p") as RTSEconomy
	_eco_e = _map.get("economy_e") as RTSEconomy
	_mm = _map.get("match_mgr") as MatchManager
	_orders = _map.get("orders") as OrderManager
	_strat = _map.get("strategist") as EnemyStrategist
	var cities: Array = _map.get("cities")
	_west = (cities[0] as RTSCity) if cities.size() > 0 else null
	_central = (cities[1] as RTSCity) if cities.size() > 1 else null
	_east = (cities[2] as RTSCity) if cities.size() > 2 else null


func _fail(message: String) -> bool:
	print("PHASE2A_TEST NG ", message)
	quit(1)
	return true


func _ok(message: String) -> void:
	print("PHASE2A_TEST ok: ", message)


func _units(player_flag: bool) -> Array:
	var list: Array = []
	for o in get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_alive() and u.is_player == player_flag:
			list.append(u)
	return list


func _goto(next: int, wait_frames: int) -> void:
	_phase = next
	_deadline = _frame + wait_frames


func _kill_all(player_flag: bool) -> void:
	for u in _units(player_flag):
		(u as RTSUnit).take_damage(99999.0, null)


func _expired() -> bool:
	return _frame >= _deadline


func _move_all(units: Array, center: Vector3, spread: float = 2.0) -> void:
	var i := 0
	for u in units:
		var n := u as Node3D
		var a := TAU * float(i) / float(maxi(1, units.size()))
		n.global_position = center + Vector3(cos(a) * spread, 0, sin(a) * spread)
		i += 1


func _counts_text() -> String:
	var c: Dictionary = _map.call("city_counts")
	return "Cities: P %d / N %d / E %d" % [int(c["player"]), int(c["neutral"]), int(c["enemy"])]


func _check_hud(want: String) -> bool:
	var summary := _map.get_node("HUD/CitiesBox/CitiesSummary") as Label
	if summary == null or summary.text != want:
		return false
	for i in range(3):
		var line := _map.get_node("HUD/CitiesBox/CityLine%d" % i) as Label
		if line == null or line.text.is_empty():
			return false
	return true


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		0:
			if _frame < 10:
				return false
			_grab()
			_strat.ai_enabled = false
			_map.set("pulse_enabled", false)
			if _map.get("cities").size() != 3:
				return _fail("want 3 cities")
			if _west == null or str(_west.city_id) != "west_city":
				return _fail("west city missing")
			if _central == null or str(_central.city_id) != "central_city":
				return _fail("central city missing")
			if _east == null or str(_east.city_id) != "east_city":
				return _fail("east city missing")
			for c in [_west, _central, _east]:
				(c as RTSCity).capture_time_sec = 1.0
				if (c as RTSCity).owner_side != RTSCity.Owner.NEUTRAL:
					return _fail("city not neutral at start")
			if _units(true).size() != 5 or _units(false).size() != 5:
				return _fail("initial armies want 5v5")
			if _map.player_hq == null or not _map.player_hq.is_alive():
				return _fail("no player HQ")
			if _map.enemy_hq == null or not _map.enemy_hq.is_alive():
				return _fail("no enemy HQ")
			if absf(_eco_p.material - 120.0) > 0.01:
				return _fail("start material not 120")
			if _eco_p.pop_used != 0 or _eco_p.pop_max != 40:
				return _fail("start pop not 0/40")
			for c in [_west, _central, _east]:
				if (c as RTSCity).owner_side != RTSCity.Owner.NEUTRAL:
					return _fail("city not neutral at start")
			_ok("initial state 5v5, HQs alive, 120 material")
			_goto(20, 150)
		20:
			if not _expired():
				return false
			for c in [_west, _central, _east]:
				if (c as RTSCity).owner_side != RTSCity.Owner.NEUTRAL:
					return _fail("city not neutral at start")
			if not _check_hud("Cities: P 0 / N 3 / E 0"):
				return _fail("HUD city counts wrong at start")
			_ok("3 cities neutral, HUD P0/N3/E0")
			_mat0 = _eco_p.material
			_goto(1, 600)
		1:
			if _eco_p.material > _mat0:
				_ok("material grows %d -> %d" % [int(_mat0), int(_eco_p.material)])
			elif not _expired():
				return false
			else:
				return _fail("material did not grow")
			var squad := _units(true)
			(squad[0] as Node3D).global_position = _west.global_position + Vector3(2, 0, 0)
			(squad[1] as Node3D).global_position = _west.global_position + Vector3(-2, 0, 0)
			_goto(2, 600)
		2:
			if _west.owner_side == RTSCity.Owner.PLAYER:
				if absf(_eco_p.bonus_income - 1.5) > 0.01:
					return _fail("west bonus not applied")
				_ok("player captured West, income +1.5/s")
				_goto(22, 40)
				return false
			if _expired():
				return _fail("player could not capture west")
		22:
			if not _expired():
				return false
			if not _check_hud("Cities: P 1 / N 2 / E 0"):
				return _fail("HUD counts wrong after west capture")
			_ok("HUD P1/N2/E0")
			var foes := _units(false)
			(foes[0] as Node3D).global_position = _east.global_position + Vector3(2, 0, 0)
			(foes[1] as Node3D).global_position = _east.global_position + Vector3(-2, 0, 0)
			_goto(3, 600)
		3:
			if _east.owner_side == RTSCity.Owner.ENEMY:
				if absf(_eco_e.bonus_income - 1.5) > 0.01:
					return _fail("east bonus not applied")
				if absf(_eco_p.bonus_income - 1.5) > 0.01:
					return _fail("west bonus lost")
				_ok("enemy captured East, both bonuses +1.5/s")
				_goto(23, 40)
				return false
			if _expired():
				return _fail("enemy could not capture east")
		23:
			if not _expired():
				return false
			if not _check_hud("Cities: P 1 / N 1 / E 1"):
				return _fail("HUD counts wrong after east capture")
			_ok("HUD P1/N1/E1")
			var squad := _units(true)
			var foes := _units(false)
			(squad[2] as Node3D).global_position = _central.global_position + Vector3(2, 0, 0)
			(foes[2] as Node3D).global_position = _central.global_position + Vector3(-2, 0, 0)
			_goto(4, 90)
		4:
			if not _expired():
				return false
			if not _central.contested:
				return _fail("CONTESTED not detected on central")
			_prog0 = _central.progress_fraction()
			_goto(5, 30)
		5:
			if not _expired():
				return false
			if not _central.contested:
				return _fail("CONTESTED lost too early")
			if absf(_central.progress_fraction() - _prog0) > 0.01:
				return _fail("capture progressed while CONTESTED")
			_ok("CONTESTED freezes capture on central")
			# Evacuate Central so it stays NEUTRAL for the rest of the test.
			for u in _units(true) + _units(false):
				var n := u as Node3D
				var d: Vector3 = n.global_position - _central.global_position
				d.y = 0.0
				if d.length() < 14.0:
					var home: Vector3 = _map.player_hq.global_position if (u as RTSUnit).is_player else _map.enemy_hq.global_position
					n.global_position = home + Vector3(6, 0, 6)
			# Player recaptures East: pull enemies out, send players in.
			for u in _units(false):
				var n := u as Node3D
				var d: Vector3 = n.global_position - _east.global_position
				d.y = 0.0
				if d.length() < 14.0:
					var home: Vector3 = _map.enemy_hq.global_position
					n.global_position = home + Vector3(6, 0, 6)
			var squad := _units(true)
			(squad[0] as Node3D).global_position = _east.global_position + Vector3(2, 0, 0)
			(squad[1] as Node3D).global_position = _east.global_position + Vector3(-2, 0, 0)
			_goto(6, 600)
		6:
			if _east.owner_side == RTSCity.Owner.PLAYER:
				if absf(_eco_p.bonus_income - 3.0) > 0.01:
					return _fail("double bonus not applied (got %.1f)" % _eco_p.bonus_income)
				if absf(_eco_e.bonus_income) > 0.01:
					return _fail("enemy bonus not cleared")
				_ok("player recaptured East, income +3.0/s")
				_goto(24, 40)
				return false
			if _expired():
				return _fail("player could not recapture east")
		24:
			if not _expired():
				return false
			if not _check_hud("Cities: P 2 / N 1 / E 0"):
				return _fail("HUD counts wrong after recapture")
			_ok("HUD P2/N1/E0")
			# Enemy recaptures West: pull players out, send enemies in.
			for u in _units(true):
				var n := u as Node3D
				var d: Vector3 = n.global_position - _west.global_position
				d.y = 0.0
				if d.length() < 14.0:
					var home: Vector3 = _map.player_hq.global_position
					n.global_position = home + Vector3(6, 0, 6)
			var foes := _units(false)
			(foes[0] as Node3D).global_position = _west.global_position + Vector3(2, 0, 0)
			(foes[1] as Node3D).global_position = _west.global_position + Vector3(-2, 0, 0)
			_goto(7, 600)
			return false
		7:
			if _west.owner_side == RTSCity.Owner.ENEMY:
				if absf(_eco_e.bonus_income - 1.5) > 0.01:
					return _fail("enemy bonus not restored")
				if absf(_eco_p.bonus_income - 1.5) > 0.01:
					return _fail("player bonus wrong after loss (got %.1f)" % _eco_p.bonus_income)
				_ok("enemy recaptured West, income drops to +1.5/s")
				_goto(25, 40)
				return false
			if _expired():
				return _fail("enemy could not recapture west")
		25:
			if not _expired():
				return false
			if not _check_hud("Cities: P 1 / N 1 / E 1"):
				return _fail("HUD counts wrong after enemy recapture")
			_ok("HUD P1/N1/E1")
			# AI city targeting: gather a 5-unit enemy army at home, enable AI.
			var home: Vector3 = _map.enemy_hq.global_position
			_move_all(_units(false), home + Vector3(8, 0, 8), 2.0)
			_strat.ai_enabled = true
			_goto(8, 700)
			return false
			if _expired():
				return _fail("enemy could not recapture west")
		8:
			if _strat.plan != EnemyStrategist.Plan.CAPTURE_CITY and _strat.plan != EnemyStrategist.Plan.DEFEND_CITY:
				if _expired():
					return _fail("AI did not pick a city plan (plan=%d)" % _strat.plan)
				return false
			if _strat.target_city == null:
				return _fail("AI city plan without target")
			_ok("AI targets %s (plan=%s)" % [_strat.target_city.display_name, _strat.plan_name()])
			_strat.ai_enabled = false
			_kill_all(false)
			_goto(9, 120)
		9:
			if not _units(false).is_empty():
				if _expired():
					return _fail("cleanup kills failed")
				return false
			var hq_pos: Vector3 = _map.enemy_hq.global_position
			var h1 = _map.spawn_unit(HevDef, true, hq_pos + Vector3(10, 0, 0))
			var h2 = _map.spawn_unit(HevDef, true, hq_pos + Vector3(-10, 0, 0))
			_map.enemy_hq.hp = 30.0
			_orders.issue_attack([h1, h2], _map.enemy_hq)
			_goto(10, 2000)
		10:
			if _mm.phase == MatchManager.Phase.PLAYING:
				if _expired():
					return _fail("enemy HQ never fell")
				return false
			if _mm.phase != MatchManager.Phase.VICTORY:
				return _fail("wrong end phase")
			if not paused:
				return _fail("tree not paused on victory")
			if not ((_map.get_node("HUD/EndOverlay") as Control).visible):
				return _fail("victory overlay hidden")
			_ok("VICTORY on enemy HQ kill, full stop")
			_mm.restart()
			_goto(11, 300)
		11:
			if not _expired():
				return false
			_grab()
			if not _assert_fresh("restart#1"):
				return true
			_strat.ai_enabled = false
			_map.set("pulse_enabled", false)
			for c in [_west, _central, _east]:
				(c as RTSCity).capture_time_sec = 1.0
			_goto(26, 120)
		26:
			if not _expired():
				return false
			if not _check_hud("Cities: P 0 / N 3 / E 0"):
				print("PHASE2A_TEST NG restart#1: HUD not reset")
				quit(1)
				return true
			_ok("restart#1 HUD reset P0/N3/E0")
			_kill_all(true)
			var hq_pos: Vector3 = _map.player_hq.global_position
			var e1 = _map.spawn_unit(HevDef, false, hq_pos + Vector3(10, 0, 0))
			var e2 = _map.spawn_unit(HevDef, false, hq_pos + Vector3(-10, 0, 0))
			_map.player_hq.hp = 30.0
			_orders.issue_attack([e1, e2], _map.player_hq)
			_goto(12, 2000)
		12:
			if _mm.phase == MatchManager.Phase.PLAYING:
				if _expired():
					return _fail("player HQ never fell")
				return false
			if _mm.phase != MatchManager.Phase.DEFEAT:
				return _fail("wrong end phase")
			if not ((_map.get_node("HUD/EndOverlay") as Control).visible):
				return _fail("defeat overlay hidden")
			_ok("DEFEAT on player HQ kill")
			_mm.restart()
			_goto(13, 300)
		13:
			if _expired():
				_goto(14, 1)
			return false
		14:
			if not _expired():
				return false
			_grab()
			if not _assert_fresh("restart#2"):
				return true
			print("PHASE2A_TEST OK")
			quit(0)
			return true
	return false


func _assert_fresh(tag: String) -> bool:
	if paused:
		print("PHASE2A_TEST NG %s: still paused" % tag)
		quit(1)
		return false
	if _mm.phase != MatchManager.Phase.PLAYING:
		print("PHASE2A_TEST NG %s: not playing" % tag)
		quit(1)
		return false
	if not _map.player_hq.is_alive() or not _map.enemy_hq.is_alive():
		print("PHASE2A_TEST NG %s: HQ dead" % tag)
		quit(1)
		return false
	if absf(_map.player_hq.hp - _map.player_hq.max_hp) > 0.01:
		print("PHASE2A_TEST NG %s: player HQ hp not reset" % tag)
		quit(1)
		return false
	if absf(_eco_p.material - 120.0) > 40.0:
		print("PHASE2A_TEST NG %s: material not reset (%d)" % [tag, int(_eco_p.material)])
		quit(1)
		return false
	if _eco_p.pop_used != 0:
		print("PHASE2A_TEST NG %s: pop not reset" % tag)
		quit(1)
		return false
	for c in [_west, _central, _east]:
		if (c as RTSCity).owner_side != RTSCity.Owner.NEUTRAL:
			print("PHASE2A_TEST NG %s: city not neutral" % tag)
			quit(1)
			return false
	if _units(true).size() != 5 or _units(false).size() != 5:
		print("PHASE2A_TEST NG %s: armies not 5v5" % tag)
		quit(1)
		return false
	_ok("%s: fresh match state" % tag)
	return true
