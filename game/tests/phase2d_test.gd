extends SceneTree
## Phase 2D integration test (headless). Covers: 5 cities / 7 territories /
## initial owners, capture + territory + aether linkage, district build +
## inheritance, unit Aether costs (0/8/15), production payment + rejection,
## enemy payment + district + units, saving/emergency logic, frontline
## updates, HUD consistency + clipping structure, population, HQ combat,
## Victory/Defeat, Restart with full reset.
## Usage: godot --headless --path game --script res://tests/phase2d_test.gd

const HevDef: UnitDefinition = preload("res://resources/units/2d_heavy_guard.tres")
const MarDef: UnitDefinition = preload("res://resources/units/2d_marksman.tres")
const InfDef: UnitDefinition = preload("res://resources/units/2d_infantry.tres")

var _frame: int = 0
var _phase: int = 0
var _deadline: int = 0

var _map: Node = null
var _eco_p: RTSEconomy
var _eco_e: RTSEconomy
var _q_p: ProductionQueue
var _q_e: ProductionQueue
var _mm: MatchManager
var _orders: OrderManager
var _strat: EnemyStrategist
var _terr: TerritoryController
var _dist: DistrictController
var _cities: Dictionary = {}


func _initialize() -> void:
	# change_scene (not manual add_child) so current_scene is set and the
	# in-game Restart path (reload_current_scene) works under test.
	change_scene_to_file("res://scenes/maps/phase2d_strategic_match.tscn")


func _grab() -> void:
	_map = get_first_node_in_group("match_map")
	_eco_p = _map.get("economy_p") as RTSEconomy
	_eco_e = _map.get("economy_e") as RTSEconomy
	_q_p = _map.get("queue_p") as ProductionQueue
	_q_e = _map.get("queue_e") as ProductionQueue
	_mm = _map.get("match_mgr") as MatchManager
	_orders = _map.get("orders") as OrderManager
	_strat = _map.get("strategist") as EnemyStrategist
	_terr = _map.get("territories") as TerritoryController
	_dist = _map.get("districts") as DistrictController
	_cities = {
		"west": _map.get_city("west_foundry"),
		"north": _map.get_city("north_relay"),
		"central": _map.get_city("central_nexus"),
		"south": _map.get_city("south_works"),
		"east": _map.get_city("east_bastion"),
	}


func _fail(message: String) -> bool:
	print("PHASE2D_TEST NG ", message)
	quit(1)
	return true


func _ok(message: String) -> void:
	print("PHASE2D_TEST ok: ", message)


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


func _complete_count(city: RTSCity) -> int:
	var n := 0
	for s in _dist.slots_for(city):
		if int((s as Dictionary)["state"]) == DistrictController.STATE_COMPLETE:
			n += 1
	return n


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		0:
			if _frame < 10:
				return false
			_grab()
			_strat.ai_enabled = false
			_map.set("pulse_enabled", false)
			if (_map.get("cities") as Array).size() != 5:
				return _fail("want 5 cities")
			for key in ["west", "north", "central", "south", "east"]:
				if _cities[key] == null:
					return _fail(key + " city missing")
				(_cities[key] as RTSCity).capture_time_sec = 1.0
			if _terr.regions.size() != 7:
				return _fail("want 7 territories")
			if _region("2d_player_base").owner_side != TerritoryRegion.Owner.PLAYER:
				return _fail("player base not PLAYER")
			if _region("2d_enemy_base").owner_side != TerritoryRegion.Owner.ENEMY:
				return _fail("enemy base not ENEMY")
			for id in ["2d_west", "2d_north", "2d_central", "2d_south", "2d_east"]:
				if _region(id).owner_side != TerritoryRegion.Owner.NEUTRAL:
					return _fail(id + " not neutral")
			if _map.player_hq == null or not _map.player_hq.is_alive():
				return _fail("no player HQ")
			if _map.enemy_hq == null or not _map.enemy_hq.is_alive():
				return _fail("no enemy HQ")
			if absf(_eco_p.material - 120.0) > 0.01:
				return _fail("start material not 120")
			if absf(_eco_p.aether - 0.0) > 0.1:
				return _fail("aether not 0")
			if InfDef.cost_aether != 0 or MarDef.cost_aether != 8 or HevDef.cost_aether != 15:
				return _fail("unit aether costs wrong")
			if _units(true).size() != 5 or _units(false).size() != 5:
				return _fail("initial armies want 5v5")
			var keys := _pair_keys()
			if keys.size() != 2 or not keys.has("2d_player_base|2d_west") or not keys.has("2d_east|2d_enemy_base"):
				return _fail("initial frontlines wrong: %s" % str(keys))
			_map.IndustryDef.build_time_sec = 1.0
			_map.MilitaryDef.build_time_sec = 1.0
			_map.AetherWorksDef.build_time_sec = 1.0
			_eco_p.material = 1000.0
			_eco_p.aether = 1000.0
			_ok("5 cities, 7 territories, correct owners, aether costs 0/8/15, 2 soft frontlines")
			_goto(20, 150)
		20:
			if not _expired():
				return false
			if not _check_hud("Cities: P 0 / N 5 / E 0", "Territories: P 1 / N 5 / E 1"):
				return _fail("HUD counts wrong at start")
			var ov := _map.get_node("HUD/DebugBox/OverviewLabel") as Label
			if ov == null or ov.text.is_empty() or not ov.text.contains("W:N"):
				return _fail("strategic overview missing")
			if not _check_clipping():
				return _fail("HUD clipping structure wrong")
			_ok("HUD counts + overview + clipping structure at start")
			var squad := _units(true)
			(squad[0] as Node3D).global_position = (_cities["west"] as Node3D).global_position + Vector3(2, 0, 0)
			(squad[1] as Node3D).global_position = (_cities["west"] as Node3D).global_position + Vector3(-2, 0, 0)
			_goto(2, 600)
		2:
			if (_cities["west"] as RTSCity).owner_side != RTSCity.Owner.PLAYER:
				if _expired():
					return _fail("player could not capture west")
				return false
			if _region("2d_west").owner_side != TerritoryRegion.Owner.PLAYER:
				return _fail("west territory did not follow")
			if absf(_eco_p.bonus_aether - 0.25) > 0.01:
				return _fail("west aether not +0.25 (got %.2f)" % _eco_p.bonus_aether)
			_ok("West captured: territory PLAYER, aether +0.25/s")
			# Unit aether costs: infantry free, marksman/heavy gated.
			_eco_p.aether = 0.0
			if _q_p.try_enqueue(InfDef, _eco_p) != "ok":
				return _fail("infantry rejected without aether")
			_q_p.queue.clear()
			if _q_p.try_enqueue(MarDef, _eco_p) != "no_aether":
				return _fail("marksman allowed without aether")
			if _q_p.try_enqueue(HevDef, _eco_p) != "no_aether":
				return _fail("heavy allowed without aether")
			_eco_p.aether = 100.0
			var m0: float = _eco_p.material
			if _q_p.try_enqueue(MarDef, _eco_p) != "ok":
				return _fail("marksman rejected with aether")
			if absf(_eco_p.aether - 92.0) > 0.01:
				return _fail("aether not deducted 8")
			if absf(_eco_p.material - (m0 - 100.0)) > 0.01:
				return _fail("material not deducted 100")
			_q_p.queue.clear()
			_eco_p.material = 1000.0
			_eco_p.aether = 1000.0
			_ok("production pays material+aether, rejects without aether")
			if _map.try_build_player("west_foundry", "industry") != "ok":
				return _fail("west industry rejected")
			_goto(3, 400)
		3:
			if _complete_count(_cities["west"]) != 1:
				if _expired():
					return _fail("industry never completed")
				return false
			if absf(_eco_p.bonus_income - 1.50) > 0.02:
				return _fail("industry bonus missing")
			_ok("industry complete, material income 2.25/s")
			var squad := _units(true)
			(squad[2] as Node3D).global_position = (_cities["north"] as Node3D).global_position + Vector3(2, 0, 0)
			(squad[3] as Node3D).global_position = (_cities["north"] as Node3D).global_position + Vector3(-2, 0, 0)
			_goto(4, 600)
		4:
			if (_cities["north"] as RTSCity).owner_side != RTSCity.Owner.PLAYER:
				if _expired():
					return _fail("player could not capture north")
				return false
			if _map.try_build_player("north_relay", "military") != "ok":
				return _fail("north military rejected")
			_goto(5, 400)
		5:
			if _complete_count(_cities["north"]) != 1:
				if _expired():
					return _fail("military never completed")
				return false
			if _eco_p.pop_max != 66:
				return _fail("pop cap not 66")
			_ok("military complete, pop 66 (multi-city districts work)")
			var foes := _units(false)
			(foes[0] as Node3D).global_position = (_cities["east"] as Node3D).global_position + Vector3(2, 0, 0)
			(foes[1] as Node3D).global_position = (_cities["east"] as Node3D).global_position + Vector3(-2, 0, 0)
			_goto(6, 600)
		6:
			if (_cities["east"] as RTSCity).owner_side != RTSCity.Owner.ENEMY:
				if _expired():
					return _fail("enemy could not capture east")
				return false
			_eco_e.material = 1000.0
			_eco_e.aether = 1000.0
			# Saving logic first (slots still empty): funded enemy, intact
			# army, no threat -> saving on.
			var home: Vector3 = _map.enemy_hq.global_position
			_move_all(_units(false), home + Vector3(8, 0, 8), 2.0)
			_map.call("_district_tick")
			if not _strat.district_saving:
				return _fail("saving not engaged")
			_ok("saving engaged with intact army")
			var ae0: float = _eco_e.aether
			var m0: float = _eco_e.material
			_q_e.queue.clear()
			if _q_e.try_enqueue(HevDef, _eco_e) != "ok":
				return _fail("enemy heavy rejected")
			if absf(_eco_e.aether - (ae0 - 15.0)) > 0.01:
				return _fail("enemy did not pay aether")
			if absf(_eco_e.material - (m0 - 150.0)) > 0.01:
				return _fail("enemy did not pay material")
			_q_e.queue.clear()
			_dist.enemy_ai_tick(_eco_e)
			var built := 0
			for s in _dist.slots_for(_cities["east"]):
				if int((s as Dictionary)["state"]) != DistrictController.STATE_EMPTY:
					built += 1
			if built == 0:
				return _fail("enemy AI built nothing")
			if _eco_e.aether > 1000.0 - 20.0:
				return _fail("enemy district not paid")
			_ok("enemy pays aether for units and builds a district")
			# Threat: contest the enemy city -> saving off, production free.
			var foes2 := _units(false)
			(foes2[2] as Node3D).global_position = (_cities["east"] as Node3D).global_position + Vector3(0, 0, 4)
			var squad := _units(true)
			(squad[4] as Node3D).global_position = (_cities["east"] as Node3D).global_position + Vector3(2, 0, 0)
			_goto(7, 120)
		7:
			if not _expired():
				return false
			if not (_cities["east"] as RTSCity).contested:
				return _fail("threat not detected on east")
			_map.call("_district_tick")
			if _strat.district_saving:
				return _fail("saving not released under threat")
			_q_e.queue.clear()
			_eco_e.material = 1000.0
			_eco_e.aether = 1000.0
			_strat.district_saving = false
			_strat._produce(_strat.army())
			if _q_e.queue.is_empty():
				return _fail("emergency production blocked")
			_ok("threat releases saving, emergency production works")
			for u in _units(true):
				var n := u as Node3D
				var d: Vector3 = n.global_position - (_cities["east"] as Node3D).global_position
				d.y = 0.0
				if d.length() < 14.0:
					var h: Vector3 = _map.player_hq.global_position
					n.global_position = h + Vector3(6, 0, 6)
			for u in _units(true):
				var n := u as Node3D
				var d: Vector3 = n.global_position - (_cities["north"] as Node3D).global_position
				d.y = 0.0
				if d.length() < 14.0:
					var h: Vector3 = _map.player_hq.global_position
					n.global_position = h + Vector3(6, 0, 6)
			var foes := _units(false)
			(foes[0] as Node3D).global_position = (_cities["north"] as Node3D).global_position + Vector3(2, 0, 0)
			(foes[1] as Node3D).global_position = (_cities["north"] as Node3D).global_position + Vector3(-2, 0, 0)
			_goto(8, 600)
		8:
			if (_cities["north"] as RTSCity).owner_side != RTSCity.Owner.ENEMY:
				if _expired():
					return _fail("enemy could not recapture north")
				return false
			if _complete_count(_cities["north"]) != 1:
				return _fail("military destroyed on capture")
			if _eco_p.pop_max != 60:
				return _fail("player pop cap not restored")
			if _eco_e.pop_max != 66:
				return _fail("enemy pop cap not migrated")
			if not _has_hard_frontline():
				return _fail("no hard frontline after shifts")
			_ok("north recaptured: district inherited, pop migrated, hard frontline live")
			var texts: Array = _map.call("district_slot_texts", "north_relay")
			if not _hud_district_ok(texts):
				return _fail("HUD district display wrong")
			_ok("HUD district display ok")
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
			for key in _cities:
				(_cities[key] as RTSCity).capture_time_sec = 1.0
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
			print("PHASE2D_TEST OK")
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


func _check_hud(cities_want: String, terr_want: String) -> bool:
	var cs := _map.get_node("HUD/CitiesBox/CitiesSummary") as Label
	var ts := _map.get_node("HUD/TerritoryBox/TerritorySummary") as Label
	if cs == null or ts == null:
		return false
	return cs.text == cities_want and ts.text == terr_want


func _check_clipping() -> bool:
	# Right-edge boxes must stay inside the viewport (offset_right <= -8).
	for path in ["HUD/CitiesBox", "HUD/TerritoryBox", "HUD/DistrictBox"]:
		var box := _map.get_node(path) as Control
		if box == null or box.offset_right > -8.0:
			return false
	var db := _map.get_node("HUD/DistrictBox") as Control
	if db == null or db.anchor_top < 1.0 or db.anchor_bottom < 1.0 or db.offset_bottom > -8.0:
		return false
	var bc := _map.get_node("HUD/DistrictBox/BuildCol") as VBoxContainer
	return bc != null


func _hud_district_ok(texts: Array) -> bool:
	var s0 := _map.get_node("HUD/DistrictBox/DistSlot0") as Label
	var s1 := _map.get_node("HUD/DistrictBox/DistSlot1") as Label
	if s0 == null or s1 == null:
		return false
	var all := s0.text + "|" + s1.text + "|"
	for t in texts:
		all += str(t) + "|"
	return all.contains("Military")


func _assert_fresh(tag: String) -> bool:
	if paused:
		print("PHASE2D_TEST NG %s: still paused" % tag)
		quit(1)
		return false
	if _mm.phase != MatchManager.Phase.PLAYING:
		print("PHASE2D_TEST NG %s: not playing" % tag)
		quit(1)
		return false
	if not _map.player_hq.is_alive() or not _map.enemy_hq.is_alive():
		print("PHASE2D_TEST NG %s: HQ dead" % tag)
		quit(1)
		return false
	if absf(_map.player_hq.hp - _map.player_hq.max_hp) > 0.01:
		print("PHASE2D_TEST NG %s: player HQ hp not reset" % tag)
		quit(1)
		return false
	if absf(_eco_p.material - 120.0) > 40.0:
		print("PHASE2D_TEST NG %s: material not reset (%d)" % [tag, int(_eco_p.material)])
		quit(1)
		return false
	if _eco_p.aether > 1.0 or _eco_e.aether > 1.0:
		print("PHASE2D_TEST NG %s: aether not reset" % tag)
		quit(1)
		return false
	if _eco_p.pop_max != 60 or _eco_e.pop_max != 60:
		print("PHASE2D_TEST NG %s: pop cap not reset" % tag)
		quit(1)
		return false
	if _eco_p.pop_used != 0:
		print("PHASE2D_TEST NG %s: pop not reset" % tag)
		quit(1)
		return false
	for key in _cities:
		if (_cities[key] as RTSCity).owner_side != RTSCity.Owner.NEUTRAL:
			print("PHASE2D_TEST NG %s: city not neutral" % tag)
			quit(1)
			return false
	for s in _dist.slots:
		if int((s as Dictionary)["state"]) != DistrictController.STATE_EMPTY:
			print("PHASE2D_TEST NG %s: district not cleared" % tag)
			quit(1)
			return false
	var tc: Dictionary = _map.call("territory_counts")
	if int(tc.get("player", -1)) != 1 or int(tc.get("neutral", -1)) != 5 or int(tc.get("enemy", -1)) != 1:
		print("PHASE2D_TEST NG %s: territories not reset" % tag)
		quit(1)
		return false
	var keys := _pair_keys()
	if keys.size() != 2 or not keys.has("2d_player_base|2d_west") or not keys.has("2d_east|2d_enemy_base"):
		print("PHASE2D_TEST NG %s: frontlines not reset: %s" % [tag, str(keys)])
		quit(1)
		return false
	if _units(true).size() != 5 or _units(false).size() != 5:
		print("PHASE2D_TEST NG %s: armies not 5v5" % tag)
		quit(1)
		return false
	_ok("%s: fresh match state (5 neutral, 7 territories, districts cleared, pop 60)" % tag)
	return true
