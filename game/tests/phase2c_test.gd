extends SceneTree
## Phase 2C integration test (headless). Covers: 2 slots per city, no
## initial districts, ownership-gated building, exact payment, build timer,
## industry/military/aether-works bonuses, duplicate/slot/busy rejection,
## CONTESTED bonus retention, capture inheritance + bonus transfer + pop
## migration, enemy AI building with payment, HUD district display, HQ
## combat, Victory/Defeat, Restart with full reset.
## Usage: godot --headless --path game --script res://tests/phase2c_test.gd

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
var _dist: DistrictController
var _west: RTSCity
var _central: RTSCity
var _east: RTSCity

var _mat_before: float = 0.0
var _ae_before: float = 0.0
var _mat_keep: float = 0.0
var _ae_keep: float = 0.0


func _initialize() -> void:
	# change_scene (not manual add_child) so current_scene is set and the
	# in-game Restart path (reload_current_scene) works under test.
	change_scene_to_file("res://scenes/maps/phase2c_district_war.tscn")


func _grab() -> void:
	_map = get_first_node_in_group("match_map")
	_eco_p = _map.get("economy_p") as RTSEconomy
	_eco_e = _map.get("economy_e") as RTSEconomy
	_mm = _map.get("match_mgr") as MatchManager
	_orders = _map.get("orders") as OrderManager
	_strat = _map.get("strategist") as EnemyStrategist
	_dist = _map.get("districts") as DistrictController
	var cities: Array = _map.get("cities")
	_west = (cities[0] as RTSCity) if cities.size() > 0 else null
	_central = (cities[1] as RTSCity) if cities.size() > 1 else null
	_east = (cities[2] as RTSCity) if cities.size() > 2 else null


func _fail(message: String) -> bool:
	print("PHASE2C_TEST NG ", message)
	quit(1)
	return true


func _ok(message: String) -> void:
	print("PHASE2C_TEST ok: ", message)


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


func _complete_count(city: RTSCity) -> int:
	var n := 0
	for s in _dist.slots_for(city):
		if int((s as Dictionary)["state"]) == DistrictController.STATE_COMPLETE:
			n += 1
	return n


func _mil_count(player_side: bool) -> int:
	var want := 1 if player_side else 2
	var n := 0
	for s in _dist.slots:
		var slot := s as Dictionary
		if int(slot["state"]) != DistrictController.STATE_COMPLETE:
			continue
		var city := slot["city"] as RTSCity
		if city != null and city.owner_side == want and str(slot["district"]) == "military":
			n += 1
	return n


func _move_all(units: Array, center: Vector3, spread: float = 2.0) -> void:
	var i := 0
	for u in units:
		var n := u as Node3D
		var a := TAU * float(i) / float(maxi(1, units.size()))
		n.global_position = center + Vector3(cos(a) * spread, 0, sin(a) * spread)
		i += 1


func _hud_dist_info() -> String:
	var label := _map.get_node("HUD/DistrictBox/DistInfo") as Label
	return label.text if label != null else ""


func _hud_dist_slots() -> Array:
	var out: Array = []
	for i in range(2):
		var label := _map.get_node("HUD/DistrictBox/DistSlot%d" % i) as Label
		out.append(label.text if label != null else "")
	return out


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		0:
			if _frame < 10:
				return false
			_grab()
			_strat.ai_enabled = false
			_map.set("pulse_enabled", false)
			if _dist.slots.size() != 6:
				return _fail("want 6 slots, got %d" % _dist.slots.size())
			for c in [_west, _central, _east]:
				if _dist.slots_for(c as RTSCity).size() != 2:
					return _fail("city without 2 slots")
				for s in _dist.slots_for(c as RTSCity):
					if int((s as Dictionary)["state"]) != DistrictController.STATE_EMPTY:
						return _fail("initial district present")
			for c in [_west, _central, _east]:
				(c as RTSCity).capture_time_sec = 1.0
			_map.IndustryDef.build_time_sec = 1.0
			_map.MilitaryDef.build_time_sec = 1.0
			_map.AetherWorksDef.build_time_sec = 1.0
			if _eco_p.pop_max != 40:
				return _fail("pop cap not 40 at start")
			if _map.try_build_player("central_city", "industry") != "not_owner":
				return _fail("neutral city build allowed")
			_eco_p.material = 1000.0
			_eco_p.aether = 1000.0
			_ok("2 slots/city, no initial districts, neutral build rejected")
			_goto(20, 150)
		20:
			if not _expired():
				return false
			if not _hud_dist_info().begins_with("Districts: West City"):
				return _fail("HUD district panel wrong at start")
			_ok("HUD district panel at start")
			var squad := _units(true)
			(squad[0] as Node3D).global_position = _west.global_position + Vector3(2, 0, 0)
			(squad[1] as Node3D).global_position = _west.global_position + Vector3(-2, 0, 0)
			_goto(2, 600)
		2:
			if _west.owner_side != RTSCity.Owner.PLAYER:
				if _expired():
					return _fail("player could not capture west")
				return false
			_mat_before = 1000.0
			_ae_before = 1000.0
			_eco_p.material = 10.0
			if _map.try_build_player("west_city", "industry") != "no_material":
				return _fail("no_material not enforced")
			_eco_p.material = 1000.0
			_eco_p.aether = 5.0
			if _map.try_build_player("west_city", "industry") != "no_aether":
				return _fail("no_aether not enforced")
			_eco_p.aether = 1000.0
			if _map.try_build_player("west_city", "industry") != "ok":
				return _fail("west industry rejected")
			if absf(_eco_p.material - (_mat_before - 140.0)) > 0.01:
				return _fail("material not deducted 140")
			if absf(_eco_p.aether - (_ae_before - 25.0)) > 0.01:
				return _fail("aether not deducted 25")
			if _map.try_build_player("west_city", "industry") != "duplicate":
				return _fail("duplicate industry allowed")
			if _map.try_build_player("west_city", "military") != "busy":
				return _fail("busy not enforced")
			_ok("industry paid exactly, duplicate/busy/resource rejections work")
			_goto(3, 400)
		3:
			if _complete_count(_west) != 1:
				if _expired():
					return _fail("industry never completed")
				return false
			if absf(_eco_p.bonus_income - 2.25) > 0.02:
				return _fail("industry bonus missing (got %.2f)" % _eco_p.bonus_income)
			_ok("industry complete, material income 2.25/s")
			if _map.try_build_player("west_city", "military") != "ok":
				return _fail("west military rejected")
			_goto(4, 400)
		4:
			if _complete_count(_west) != 2:
				if _expired():
					return _fail("military never completed")
				return false
			if _eco_p.pop_max != 46:
				return _fail("pop cap not 46 (got %d)" % _eco_p.pop_max)
			if _map.try_build_player("west_city", "aether_works") != "no_slot":
				return _fail("3rd district allowed")
			var texts: Array = _map.call("district_slot_texts", "west_city")
			if not str(texts[0]).contains("Industry") or not str(texts[1]).contains("Military"):
				return _fail("HUD slot texts wrong: %s" % str(texts))
			_ok("military complete, pop 46, no 3rd slot, HUD slots show both")
			var squad := _units(true)
			(squad[2] as Node3D).global_position = _central.global_position + Vector3(2, 0, 0)
			(squad[3] as Node3D).global_position = _central.global_position + Vector3(-2, 0, 0)
			_goto(5, 600)
		5:
			if _central.owner_side != RTSCity.Owner.PLAYER:
				if _expired():
					return _fail("player could not capture central")
				return false
			if _map.try_build_player("central_city", "aether_works") != "ok":
				return _fail("central aether works rejected")
			_goto(6, 400)
		6:
			if _complete_count(_central) != 1:
				if _expired():
					return _fail("aether works never completed")
				return false
			if absf(_eco_p.bonus_aether - 1.35) > 0.03:
				return _fail("aether works bonus missing (got %.2f)" % _eco_p.bonus_aether)
			_ok("aether works complete, aether income 1.35/s (0.35+0.8+0.2)")
			var foes := _units(false)
			(foes[0] as Node3D).global_position = _central.global_position + Vector3(0, 0, 4)
			_goto(7, 90)
		7:
			if not _expired():
				return false
			if not _central.contested:
				return _fail("CONTESTED not detected on central")
			_mat_keep = _eco_p.bonus_income
			_ae_keep = _eco_p.bonus_aether
			_goto(8, 40)
		8:
			if not _expired():
				return false
			if not _central.contested:
				return _fail("CONTESTED lost too early")
			if absf(_eco_p.bonus_income - _mat_keep) > 0.01 or absf(_eco_p.bonus_aether - _ae_keep) > 0.01:
				return _fail("district bonus changed during CONTESTED")
			_ok("CONTESTED keeps district bonuses")
			for u in _units(true) + _units(false):
				var n := u as Node3D
				var d: Vector3 = n.global_position - _central.global_position
				d.y = 0.0
				if d.length() < 14.0:
					var home: Vector3 = _map.player_hq.global_position if (u as RTSUnit).is_player else _map.enemy_hq.global_position
					n.global_position = home + Vector3(6, 0, 6)
			var foes := _units(false)
			(foes[1] as Node3D).global_position = _east.global_position + Vector3(2, 0, 0)
			(foes[2] as Node3D).global_position = _east.global_position + Vector3(-2, 0, 0)
			_goto(9, 600)
		9:
			if _east.owner_side != RTSCity.Owner.ENEMY:
				if _expired():
					return _fail("enemy could not capture east")
				return false
			if _map.try_build_player("east_city", "industry") != "not_owner":
				return _fail("enemy city build allowed for player")
			_eco_e.material = 1000.0
			_eco_e.aether = 1000.0
			var ae0: float = _eco_e.aether
			_dist.enemy_ai_tick(_eco_e)
			var built := 0
			for s in _dist.slots_for(_east):
				if int((s as Dictionary)["state"]) != DistrictController.STATE_EMPTY:
					built += 1
			if built == 0:
				return _fail("enemy AI built nothing")
			if _eco_e.aether > ae0 - 20.0:
				return _fail("enemy did not pay aether (%.1f -> %.1f)" % [ae0, _eco_e.aether])
			_ok("enemy AI built a district in East and paid aether")
			for u in _units(true):
				var n := u as Node3D
				var d: Vector3 = n.global_position - _west.global_position
				d.y = 0.0
				if d.length() < 14.0:
					var home: Vector3 = _map.player_hq.global_position
					n.global_position = home + Vector3(6, 0, 6)
			var foes2 := _units(false)
			(foes2[0] as Node3D).global_position = _west.global_position + Vector3(2, 0, 0)
			(foes2[1] as Node3D).global_position = _west.global_position + Vector3(-2, 0, 0)
			_mat_before = _eco_p.bonus_income
			_ae_before = _eco_e.bonus_income
			_goto(10, 600)
		10:
			if _west.owner_side != RTSCity.Owner.ENEMY:
				if _expired():
					return _fail("enemy could not recapture west")
				return false
			if _complete_count(_west) != 2:
				return _fail("districts destroyed on capture")
			var names: Array = []
			for s in _dist.slots_for(_west):
				names.append(str((s as Dictionary)["district"]))
			if not names.has("industry") or not names.has("military"):
				return _fail("districts not inherited: %s" % str(names))
			if not _eco_p.bonus_income < _mat_before - 0.5:
				return _fail("player bonus not reduced (%.2f was %.2f)" % [_eco_p.bonus_income, _mat_before])
			if not _eco_e.bonus_income > _ae_before:
				return _fail("enemy bonus not increased")
			if _eco_p.pop_max != 40 + 6 * _mil_count(true):
				return _fail("player pop cap wrong (%d)" % _eco_p.pop_max)
			if _eco_e.pop_max != 40 + 6 * _mil_count(false):
				return _fail("enemy pop cap wrong (%d)" % _eco_e.pop_max)
			_ok("capture inherits districts, bonuses + pop caps migrate")
			_strat.ai_enabled = false
			_kill_all(false)
			_goto(11, 120)
		11:
			if not _units(false).is_empty():
				if _expired():
					return _fail("cleanup kills failed")
				return false
			var hq_pos: Vector3 = _map.enemy_hq.global_position
			var h1 = _map.spawn_unit(HevDef, true, hq_pos + Vector3(10, 0, 0))
			var h2 = _map.spawn_unit(HevDef, true, hq_pos + Vector3(-10, 0, 0))
			_map.enemy_hq.hp = 30.0
			_orders.issue_attack([h1, h2], _map.enemy_hq)
			_goto(12, 2000)
		12:
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
			_goto(13, 300)
		13:
			if not _expired():
				return false
			_grab()
			if not _assert_fresh("restart#1"):
				return true
			_strat.ai_enabled = false
			_map.set("pulse_enabled", false)
			for c in [_west, _central, _east]:
				(c as RTSCity).capture_time_sec = 1.0
			_kill_all(true)
			var hq_pos: Vector3 = _map.player_hq.global_position
			var e1 = _map.spawn_unit(HevDef, false, hq_pos + Vector3(10, 0, 0))
			var e2 = _map.spawn_unit(HevDef, false, hq_pos + Vector3(-10, 0, 0))
			_map.player_hq.hp = 30.0
			_orders.issue_attack([e1, e2], _map.player_hq)
			_goto(14, 2000)
		14:
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
			_goto(15, 300)
		15:
			if _expired():
				_goto(16, 1)
			return false
		16:
			if not _expired():
				return false
			_grab()
			if not _assert_fresh("restart#2"):
				return true
			print("PHASE2C_TEST OK")
			quit(0)
			return true
	return false


func _assert_fresh(tag: String) -> bool:
	if paused:
		print("PHASE2C_TEST NG %s: still paused" % tag)
		quit(1)
		return false
	if _mm.phase != MatchManager.Phase.PLAYING:
		print("PHASE2C_TEST NG %s: not playing" % tag)
		quit(1)
		return false
	if not _map.player_hq.is_alive() or not _map.enemy_hq.is_alive():
		print("PHASE2C_TEST NG %s: HQ dead" % tag)
		quit(1)
		return false
	if absf(_map.player_hq.hp - _map.player_hq.max_hp) > 0.01:
		print("PHASE2C_TEST NG %s: player HQ hp not reset" % tag)
		quit(1)
		return false
	if absf(_eco_p.material - 120.0) > 40.0:
		print("PHASE2C_TEST NG %s: material not reset (%d)" % [tag, int(_eco_p.material)])
		quit(1)
		return false
	if absf(_eco_p.aether) > 0.5 or absf(_eco_e.aether) > 0.5:
		print("PHASE2C_TEST NG %s: aether not reset" % tag)
		quit(1)
		return false
	if _eco_p.pop_max != 40 or _eco_e.pop_max != 40:
		print("PHASE2C_TEST NG %s: pop cap not reset" % tag)
		quit(1)
		return false
	if _eco_p.pop_used != 0:
		print("PHASE2C_TEST NG %s: pop not reset" % tag)
		quit(1)
		return false
	for c in [_west, _central, _east]:
		if (c as RTSCity).owner_side != RTSCity.Owner.NEUTRAL:
			print("PHASE2C_TEST NG %s: city not neutral" % tag)
			quit(1)
			return false
	for s in _dist.slots:
		if int((s as Dictionary)["state"]) != DistrictController.STATE_EMPTY:
			print("PHASE2C_TEST NG %s: district not cleared" % tag)
			quit(1)
			return false
	var tc: Dictionary = _map.call("territory_counts")
	if int(tc.get("player", -1)) != 1 or int(tc.get("neutral", -1)) != 3 or int(tc.get("enemy", -1)) != 1:
		print("PHASE2C_TEST NG %s: territories not reset" % tag)
		quit(1)
		return false
	if _units(true).size() != 5 or _units(false).size() != 5:
		print("PHASE2C_TEST NG %s: armies not 5v5" % tag)
		quit(1)
		return false
	_ok("%s: fresh match state (districts cleared, pop 40, aether 0, territories reset)" % tag)
	return true
