extends SceneTree
## Phase 2B integration test (headless). Covers: 5 territories exist, fixed
## base owners, city-linked ownership shifts (player/enemy/recapture),
## CONTESTED keeps territory owner, neutral grants no Aether, West/Central/
## East Aether rates, Aether loss on recapture, Material spec unchanged,
## territory + Aether HUD consistency, frontline generation/updates,
## HQ combat, Victory/Defeat, Restart with full reset.
## Usage: godot --headless --path game --script res://tests/phase2b_test.gd

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
var _terr: TerritoryController
var _west: RTSCity
var _central: RTSCity
var _east: RTSCity

var _ae_rate_west: float = 0.0


func _initialize() -> void:
	# change_scene (not manual add_child) so current_scene is set and the
	# in-game Restart path (reload_current_scene) works under test.
	change_scene_to_file("res://scenes/maps/phase2b_territory_war.tscn")


func _grab() -> void:
	_map = get_first_node_in_group("match_map")
	_eco_p = _map.get("economy_p") as RTSEconomy
	_eco_e = _map.get("economy_e") as RTSEconomy
	_mm = _map.get("match_mgr") as MatchManager
	_orders = _map.get("orders") as OrderManager
	_strat = _map.get("strategist") as EnemyStrategist
	_terr = _map.get("territories") as TerritoryController
	var cities: Array = _map.get("cities")
	_west = (cities[0] as RTSCity) if cities.size() > 0 else null
	_central = (cities[1] as RTSCity) if cities.size() > 1 else null
	_east = (cities[2] as RTSCity) if cities.size() > 2 else null


func _fail(message: String) -> bool:
	print("PHASE2B_TEST NG ", message)
	quit(1)
	return true


func _ok(message: String) -> void:
	print("PHASE2B_TEST ok: ", message)


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


func _region(id: String) -> TerritoryRegion:
	return _terr.region_by_id(StringName(id))


func _pair_keys() -> Array:
	var keys: Array = []
	for p in _terr.frontline_pairs():
		var a := str((p as Array)[0])
		var b := str((p as Array)[1])
		keys.append(a + "|" + b if a < b else b + "|" + a)
	return keys


func _has_hard_frontline() -> bool:
	for p in _terr.frontline_pairs():
		if bool((p as Array)[2]):
			return true
	return false


func _check_hud_terr(want: String) -> bool:
	var summary := _map.get_node("HUD/TerritoryBox/TerritorySummary") as Label
	if summary == null or summary.text != want:
		return false
	for i in range(5):
		var line := _map.get_node("HUD/TerritoryBox/TerrLine%d" % i) as Label
		if line == null or line.text.is_empty():
			return false
	return true


func _check_hud_aether(rate: String) -> bool:
	var label := _map.get_node("HUD/TopBar/AetherLabel") as Label
	if label == null:
		return false
	return label.text.begins_with("Aether: ") and label.text.contains("(+%s/s)" % rate)


func _check_hud_cities(want: String) -> bool:
	var summary := _map.get_node("HUD/CitiesBox/CitiesSummary") as Label
	return summary != null and summary.text == want


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		0:
			if _frame < 10:
				return false
			_grab()
			_strat.ai_enabled = false
			_map.set("pulse_enabled", false)
			if _terr.regions.size() != 5:
				return _fail("want 5 territories")
			if _region("player_base") == null or _region("player_base").owner_side != TerritoryRegion.Owner.PLAYER:
				return _fail("player base not PLAYER")
			if _region("enemy_base") == null or _region("enemy_base").owner_side != TerritoryRegion.Owner.ENEMY:
				return _fail("enemy base not ENEMY")
			for id in ["west", "central", "east"]:
				if _region(id) == null or _region(id).owner_side != TerritoryRegion.Owner.NEUTRAL:
					return _fail(id + " not neutral at start")
			for c in [_west, _central, _east]:
				(c as RTSCity).capture_time_sec = 1.0
			if _units(true).size() != 5 or _units(false).size() != 5:
				return _fail("initial armies want 5v5")
			if absf(_eco_p.aether) > 0.001 or absf(_eco_e.aether) > 0.001:
				return _fail("aether not 0 at start")
			if absf(_eco_p.aether_per_sec()) > 0.001:
				return _fail("neutral aether income not 0")
			var keys := _pair_keys()
			if keys.size() != 2 or not keys.has("player_base|west") or not keys.has("east|enemy_base"):
				return _fail("initial frontlines wrong: %s" % str(keys))
			if _has_hard_frontline():
				return _fail("hard frontline at start")
			_ok("5 territories, fixed bases, city regions neutral, 2 soft frontlines, aether 0")
			_goto(20, 150)
		20:
			if not _expired():
				return false
			if not _check_hud_terr("Territories: P 1 / N 3 / E 1"):
				return _fail("HUD territories wrong at start")
			if not _check_hud_aether("0.00"):
				return _fail("HUD aether wrong at start")
			if not _check_hud_cities("Cities: P 0 / N 3 / E 0"):
				return _fail("HUD cities wrong at start")
			_ok("HUD territories/aether/cities at start")
			var squad := _units(true)
			(squad[0] as Node3D).global_position = _west.global_position + Vector3(2, 0, 0)
			(squad[1] as Node3D).global_position = _west.global_position + Vector3(-2, 0, 0)
			_goto(2, 600)
		2:
			if _west.owner_side == RTSCity.Owner.PLAYER:
				if _region("west").owner_side != TerritoryRegion.Owner.PLAYER:
					return _fail("west territory did not follow city")
				if absf(_eco_p.bonus_income - 1.5) > 0.01:
					return _fail("material spec changed (want +1.5)")
				if absf(_eco_p.bonus_aether - 0.35) > 0.01:
					return _fail("west aether not +0.35 (got %.2f)" % _eco_p.bonus_aether)
				_ae_rate_west = _eco_p.aether_per_sec()
				_ok("West captured: territory PLAYER, material +1.5/s, aether +0.35/s")
				_goto(22, 60)
				return false
			if _expired():
				return _fail("player could not capture west")
		22:
			if not _expired():
				return false
			if not _check_hud_terr("Territories: P 2 / N 2 / E 1"):
				return _fail("HUD territories wrong after west")
			if not _check_hud_aether("0.35"):
				return _fail("HUD aether wrong after west")
			var keys := _pair_keys()
			if keys.has("player_base|west"):
				return _fail("stale frontline player_base|west")
			if not keys.has("central|west"):
				return _fail("missing frontline central|west")
			_ok("HUD + frontline updated after West (P2/N2/E1)")
			var squad := _units(true)
			(squad[2] as Node3D).global_position = _central.global_position + Vector3(2, 0, 0)
			(squad[3] as Node3D).global_position = _central.global_position + Vector3(-2, 0, 0)
			_goto(3, 600)
		3:
			if _central.owner_side == RTSCity.Owner.PLAYER:
				if _region("central").owner_side != TerritoryRegion.Owner.PLAYER:
					return _fail("central territory did not follow city")
				if _eco_p.aether_per_sec() <= _ae_rate_west + 0.5:
					return _fail("central aether not higher (rate=%.2f)" % _eco_p.aether_per_sec())
				if absf(_eco_p.bonus_aether - 1.15) > 0.02:
					return _fail("central total not 1.15 (got %.2f)" % _eco_p.bonus_aether)
				if _eco_p.aether <= 0.0:
					return _fail("aether stockpile not growing")
				_ok("Central captured: territory PLAYER, aether 1.15/s, stockpile growing")
				var foes := _units(false)
				(foes[0] as Node3D).global_position = _east.global_position + Vector3(2, 0, 0)
				(foes[1] as Node3D).global_position = _east.global_position + Vector3(-2, 0, 0)
				_goto(4, 600)
				return false
			if _expired():
				return _fail("player could not capture central")
		4:
			if _east.owner_side == RTSCity.Owner.ENEMY:
				if _region("east").owner_side != TerritoryRegion.Owner.ENEMY:
					return _fail("east territory did not follow city")
				if absf(_eco_e.bonus_aether - 0.35) > 0.01:
					return _fail("enemy aether not +0.35 (got %.2f)" % _eco_e.bonus_aether)
				if not _has_hard_frontline():
					return _fail("no hard frontline central|east (P vs E)")
				_ok("East captured by enemy: territory ENEMY, enemy aether +0.35/s, HARD frontline")
				var foes := _units(false)
				(foes[2] as Node3D).global_position = _central.global_position + Vector3(0, 0, 4)
				_goto(5, 90)
				return false
			if _expired():
				return _fail("enemy could not capture east")
		5:
			if not _expired():
				return false
			if not _central.contested:
				return _fail("CONTESTED not detected on central")
			if _region("central").owner_side != TerritoryRegion.Owner.PLAYER:
				return _fail("territory owner changed during CONTESTED")
			if absf(_eco_p.bonus_aether - 1.15) > 0.02:
				return _fail("aether income changed during CONTESTED")
			_ok("CONTESTED keeps territory owner + aether income")
			for u in _units(true) + _units(false):
				var n := u as Node3D
				var d: Vector3 = n.global_position - _central.global_position
				d.y = 0.0
				if d.length() < 14.0:
					var home: Vector3 = _map.player_hq.global_position if (u as RTSUnit).is_player else _map.enemy_hq.global_position
					n.global_position = home + Vector3(6, 0, 6)
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
			_goto(6, 600)
		6:
			if _west.owner_side == RTSCity.Owner.ENEMY:
				if _region("west").owner_side != TerritoryRegion.Owner.ENEMY:
					return _fail("west territory did not flip to ENEMY")
				if absf(_eco_p.bonus_aether - 0.8) > 0.02:
					return _fail("player aether not reduced to 0.8 (got %.2f)" % _eco_p.bonus_aether)
				if absf(_eco_e.bonus_aether - 0.7) > 0.02:
					return _fail("enemy aether not 0.7 (got %.2f)" % _eco_e.bonus_aether)
				if absf(_eco_p.bonus_income - 1.5) > 0.01:
					return _fail("material spec changed after loss")
				_ok("Enemy recaptured West: territory ENEMY, player aether 0.8/s, enemy 0.7/s")
				_goto(26, 60)
				return false
			if _expired():
				return _fail("enemy could not recapture west")
		26:
			if not _expired():
				return false
			if not _check_hud_terr("Territories: P 2 / N 0 / E 3"):
				return _fail("HUD territories wrong after recapture")
			if not _check_hud_aether("0.80"):
				return _fail("HUD aether wrong after recapture")
			_ok("HUD territories P2/N0/E3, aether +0.80/s")
			var home: Vector3 = _map.enemy_hq.global_position
			_move_all(_units(false), home + Vector3(8, 0, 8), 2.0)
			_strat.ai_enabled = true
			_goto(8, 700)
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
			_goto(27, 120)
		27:
			if not _expired():
				return false
			if not _check_hud_terr("Territories: P 1 / N 3 / E 1"):
				print("PHASE2B_TEST NG restart#1: HUD territories not reset")
				quit(1)
				return true
			if not _check_hud_aether("0.00"):
				print("PHASE2B_TEST NG restart#1: HUD aether not reset")
				quit(1)
				return true
			_ok("restart#1 HUD reset")
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
			print("PHASE2B_TEST OK")
			quit(0)
			return true
	return false


func _move_all(units: Array, center: Vector3, spread: float = 2.0) -> void:
	var i := 0
	for u in units:
		var n := u as Node3D
		var a := TAU * float(i) / float(maxi(1, units.size()))
		n.global_position = center + Vector3(cos(a) * spread, 0, sin(a) * spread)
		i += 1


func _assert_fresh(tag: String) -> bool:
	if paused:
		print("PHASE2B_TEST NG %s: still paused" % tag)
		quit(1)
		return false
	if _mm.phase != MatchManager.Phase.PLAYING:
		print("PHASE2B_TEST NG %s: not playing" % tag)
		quit(1)
		return false
	if not _map.player_hq.is_alive() or not _map.enemy_hq.is_alive():
		print("PHASE2B_TEST NG %s: HQ dead" % tag)
		quit(1)
		return false
	if absf(_map.player_hq.hp - _map.player_hq.max_hp) > 0.01:
		print("PHASE2B_TEST NG %s: player HQ hp not reset" % tag)
		quit(1)
		return false
	if absf(_eco_p.material - 120.0) > 40.0:
		print("PHASE2B_TEST NG %s: material not reset (%d)" % [tag, int(_eco_p.material)])
		quit(1)
		return false
	if absf(_eco_p.aether) > 0.01 or absf(_eco_e.aether) > 0.01:
		print("PHASE2B_TEST NG %s: aether not reset (p=%.2f e=%.2f)" % [tag, _eco_p.aether, _eco_e.aether])
		quit(1)
		return false
	if _eco_p.pop_used != 0:
		print("PHASE2B_TEST NG %s: pop not reset" % tag)
		quit(1)
		return false
	for c in [_west, _central, _east]:
		if (c as RTSCity).owner_side != RTSCity.Owner.NEUTRAL:
			print("PHASE2B_TEST NG %s: city not neutral" % tag)
			quit(1)
			return false
	if _region("player_base").owner_side != TerritoryRegion.Owner.PLAYER:
		print("PHASE2B_TEST NG %s: player base territory wrong" % tag)
		quit(1)
		return false
	if _region("enemy_base").owner_side != TerritoryRegion.Owner.ENEMY:
		print("PHASE2B_TEST NG %s: enemy base territory wrong" % tag)
		quit(1)
		return false
	for id in ["west", "central", "east"]:
		if _region(id).owner_side != TerritoryRegion.Owner.NEUTRAL:
			print("PHASE2B_TEST NG %s: %s territory not neutral" % [tag, id])
			quit(1)
			return false
	var keys := _pair_keys()
	if keys.size() != 2 or not keys.has("player_base|west") or not keys.has("east|enemy_base"):
		print("PHASE2B_TEST NG %s: frontlines not reset: %s" % [tag, str(keys)])
		quit(1)
		return false
	if _units(true).size() != 5 or _units(false).size() != 5:
		print("PHASE2B_TEST NG %s: armies not 5v5" % tag)
		quit(1)
		return false
	_ok("%s: fresh match state (aether 0, territories + frontlines reset)" % tag)
	return true
