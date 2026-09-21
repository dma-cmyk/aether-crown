extends SceneTree
## Phase 1.5 integration test (headless). Covers: economy growth, outpost
## capture/bonus/CONTESTED/recapture, production consume/blocks, population,
## all 3 unit types, enemy AI (spend/DEFEND/CAPTURE/HQ attack), HQ combat,
## Victory/Defeat, Restart x2 with a fresh match each time.
## Usage: godot --headless --path game --script res://tests/phase1_5_test.gd

const InfDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")
const MarDef: UnitDefinition = preload("res://resources/units/gf_marksman.tres")
const HevDef: UnitDefinition = preload("res://resources/units/gf_heavy_guard.tres")

var _frame: int = 0
var _phase: int = 0
var _deadline: int = 0

var _map: Node = null
var _eco_p: RTSEconomy
var _eco_e: RTSEconomy
var _q_p: ProductionQueue
var _q_e: ProductionQueue
var _mm: MatchManager
var _sel: SelectionManager
var _orders: OrderManager
var _outpost: RTSOutpost
var _strat: EnemyStrategist

var _mat0: float = 0.0
var _prog0: float = 0.0
var _base_counts := {}


func _initialize() -> void:
	# change_scene (not manual add_child) so current_scene is set and the
	# in-game Restart path (reload_current_scene) works under test.
	change_scene_to_file("res://scenes/maps/phase1_5_match.tscn")


func _grab() -> void:
	_map = get_first_node_in_group("match_map")
	_eco_p = _map.get("economy_p") as RTSEconomy
	_eco_e = _map.get("economy_e") as RTSEconomy
	_q_p = _map.get("queue_p") as ProductionQueue
	_q_e = _map.get("queue_e") as ProductionQueue
	_mm = _map.get("match_mgr") as MatchManager
	_sel = _map.get("selection") as SelectionManager
	_orders = _map.get("orders") as OrderManager
	_outpost = _map.get("outpost") as RTSOutpost
	_strat = _map.get("strategist") as EnemyStrategist


func _fail(message: String) -> bool:
	print("PHASE15_TEST NG ", message)
	quit(1)
	return true


func _ok(message: String) -> void:
	print("PHASE15_TEST ok: ", message)


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


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		0:
			if _frame < 10:
				return false
			_grab()
			_strat.ai_enabled = false
			_map.set("pulse_enabled", false)
			_outpost.capture_time_sec = 1.0
			if _units(true).size() != 5 or _units(false).size() != 5:
				return _fail("initial armies want 5v5")
			if _map.player_hq == null or not _map.player_hq.is_alive():
				return _fail("no player HQ")
			if _map.enemy_hq == null or not _map.enemy_hq.is_alive():
				return _fail("no enemy HQ")
			if absf(_eco_p.material - 150.0) > 0.01:
				return _fail("start material not 150")
			if _eco_p.pop_used != 0 or _eco_p.pop_max != 40:
				return _fail("start pop not 0/40")
			if _outpost.owner_side != RTSOutpost.Owner.NEUTRAL:
				return _fail("outpost not neutral at start")
			_ok("initial state 5v5, HQs alive, 150 material, neutral outpost")
			var rig := get_first_node_in_group("rts_camera") as Node3D
			var hq_pos: Vector3 = _map.player_hq.global_position
			rig.position = Vector3(hq_pos.x, 0, hq_pos.z)
			_mat0 = _eco_p.material
			_goto(1, 600)
		1:
			if _eco_p.material > _mat0:
				_ok("material grows %d -> %d" % [int(_mat0), int(_eco_p.material)])
			elif not _expired():
				return false
			else:
				return _fail("material did not grow")
			var rig := get_first_node_in_group("rts_camera") as Node3D
			var cam := rig.get_node("Camera3D") as Camera3D
			var hq_pos: Vector3 = _map.player_hq.global_position
			_sel._click_select(cam.unproject_position(hq_pos + Vector3(0, 3, 0)), false)
			if not _sel.selected.has(_map.player_hq):
				return _fail("HQ click-select missed")
			_ok("HQ selectable via click")
			_sel.clear_selection()
			var squad := _units(true)
			(squad[0] as Node3D).global_position = _outpost.global_position + Vector3(2, 0, 0)
			(squad[1] as Node3D).global_position = _outpost.global_position + Vector3(-2, 0, 0)
			_goto(2, 600)
		2:
			if _outpost.owner_side == RTSOutpost.Owner.PLAYER:
				if absf(_eco_p.bonus_income - 3.0) > 0.01:
					return _fail("outpost bonus not applied")
				_ok("player captured outpost, income bonus +3/s")
				var foes := _units(false)
				(foes[0] as Node3D).global_position = _outpost.global_position + Vector3(0, 0, 3)
				_goto(3, 90)
				return false
			if _expired():
				return _fail("player could not capture outpost")
		3:
			if not _expired():
				return false
			if not _outpost.contested:
				return _fail("CONTESTED not detected")
			_prog0 = _outpost.progress_fraction()
			_goto(4, 30)
		4:
			if not _expired():
				return false
			if not _outpost.contested:
				return _fail("CONTESTED lost too early")
			if absf(_outpost.progress_fraction() - _prog0) > 0.01:
				return _fail("capture progressed while CONTESTED")
			_ok("CONTESTED freezes capture")
			for u in _units(true):
				var home: Vector3 = _map.player_hq.global_position
				(u as Node3D).global_position = home + Vector3(randf() * 6.0 - 3.0, 0, 8.0)
			_goto(5, 800)
		5:
			if _outpost.owner_side == RTSOutpost.Owner.ENEMY:
				if absf(_eco_e.bonus_income - 3.0) > 0.01:
					return _fail("enemy bonus not applied")
				if absf(_eco_p.bonus_income) > 0.01:
					return _fail("player bonus not cleared")
				_ok("enemy recaptured outpost, bonus switched")
				for u in _units(false):
					var n := u as Node3D
					var d: Vector3 = n.global_position - _outpost.global_position
					d.y = 0.0
					if d.length() < 12.0:
						var home: Vector3 = _map.enemy_hq.global_position
						n.global_position = home + Vector3(6, 0, 6)
				_goto(6, 1)
				return false
			if _expired():
				return _fail("enemy could not recapture outpost")
		6:
			if not _expired():
				return false
			var before: float = _eco_p.material
			if _q_p.try_enqueue(InfDef, _eco_p) != "ok":
				return _fail("infantry enqueue rejected")
			if absf(_eco_p.material - (before - 50.0)) > 0.01:
				return _fail("material not consumed")
			_eco_p.material = 10.0
			if _q_p.try_enqueue(MarDef, _eco_p) != "no_material":
				return _fail("production allowed without material")
			_eco_p.material = 600.0
			_eco_p.pop_used = 40
			if _q_p.try_enqueue(InfDef, _eco_p) != "no_pop":
				return _fail("production allowed over pop cap")
			_eco_p.pop_used = 0
			if _q_p.try_enqueue(InfDef, _eco_p) != "ok":
				return _fail("2nd infantry rejected")
			if _q_p.try_enqueue(MarDef, _eco_p) != "ok":
				return _fail("marksman rejected")
			if _q_p.try_enqueue(HevDef, _eco_p) != "ok":
				return _fail("heavy rejected")
			_ok("production consume/block rules work")
			_base_counts = _counts_by_id(true)
			_q_p.progress_sec = 999.0
			_goto(7, 40)
		7:
			_q_p.progress_sec = 999.0
			var want: int = _units(true).size()
			if want >= 9:
				var after := _counts_by_id(true)
				var di: int = int(after.get("gf_infantry", 0)) - int(_base_counts.get("gf_infantry", 0))
				var dm: int = int(after.get("gf_marksman", 0)) - int(_base_counts.get("gf_marksman", 0))
				var dh: int = int(after.get("gf_heavy_guard", 0)) - int(_base_counts.get("gf_heavy_guard", 0))
				if di != 2 or dm != 1 or dh != 1:
					return _fail("unit mix wrong inf=%d mar=%d hev=%d" % [di, dm, dh])
				if _eco_p.pop_used != 5:
					return _fail("pop_used=%d want 5" % _eco_p.pop_used)
				_ok("all 3 unit types produced, pop 5")
				for u in _units(true):
					if str((u as RTSUnit).definition.id) == "gf_heavy_guard":
						(u as RTSUnit).take_damage(99999.0, null)
						break
				_goto(8, 15)
				return false
			if _expired():
				return _fail("production never completed")
		8:
			if not _expired():
				return false
			if _eco_p.pop_used != 3:
				return _fail("pop not refunded on death (%d)" % _eco_p.pop_used)
			_ok("death refunds population")
			_strat.ai_enabled = true
			_goto(9, 700)
		9:
			if _strat.plan != EnemyStrategist.Plan.DEFEND_OUTPOST:
				if _expired():
					return _fail("AI did not enter DEFEND (plan=%d)" % _strat.plan)
				return false
			if _q_e.is_empty() and _units(false).size() <= 5 and _eco_e.material >= 150.0:
				return _fail("AI never spent material on first think")
			_ok("AI DEFEND_OUTPOST with enemy-owned outpost, wallet in use")
			_eco_e.material = 600.0
			_outpost.reset_outpost()
			_eco_p.bonus_income = 0.0
			_eco_e.bonus_income = 0.0
			_goto(10, 700)
		10:
			if _strat.plan != EnemyStrategist.Plan.CAPTURE_OUTPOST:
				if _expired():
					return _fail("AI did not enter CAPTURE (plan=%d)" % _strat.plan)
				return false
			_ok("AI spends material on units (mat=%d queue=%d)" % [int(_eco_e.material), _q_e.queue.size()])
			_goto(11, 1)
		11:
			if not _expired():
				return false
			var moving := false
			for u in _units(false):
				if (u as RTSUnit).attack_moving:
					moving = true
			if not moving:
				return _fail("AI army not moving to outpost")
			_ok("AI marches on outpost")
			var hq_pos: Vector3 = _map.enemy_hq.global_position
			for i in range(5):
				_map.spawn_unit(InfDef, false, hq_pos + Vector3(8.0 + float(i), 0, 8.0))
			_goto(12, 700)
		12:
			if _strat.plan != EnemyStrategist.Plan.ATTACK_PLAYER_HQ:
				if _expired():
					return _fail("AI did not attack HQ (plan=%d)" % _strat.plan)
				return false
			var struck := false
			var hq_pos: Vector3 = _map.player_hq.global_position
			for u in _units(false):
				var unit := u as RTSUnit
				if unit.attack_moving:
					var d: Vector3 = unit.attack_move_dest - hq_pos
					d.y = 0.0
					if d.length() < 18.0:
						struck = true
			if not struck:
				if _expired():
					return _fail("AI not converging on player HQ")
				return false
			_ok("AI attacks player HQ")
			_strat.ai_enabled = false
			_q_e.queue.clear()
			_kill_all(false)
			_goto(13, 120)
		13:
			if not _units(false).is_empty():
				if _expired():
					return _fail("cleanup kills failed")
				return false
			var hq_pos: Vector3 = _map.enemy_hq.global_position
			var h1 = _map.spawn_unit(HevDef, true, hq_pos + Vector3(10, 0, 0))
			var h2 = _map.spawn_unit(HevDef, true, hq_pos + Vector3(-10, 0, 0))
			_map.enemy_hq.hp = 30.0
			_orders.issue_attack([h1, h2], _map.enemy_hq)
			_goto(14, 2000)
		14:
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
			_goto(15, 300)
		15:
			if not _expired():
				return false
			_grab()
			if not _assert_fresh("restart#1"):
				return true
			_strat.ai_enabled = false
			_map.set("pulse_enabled", false)
			_outpost.capture_time_sec = 1.0
			_kill_all(true)
			var hq_pos: Vector3 = _map.player_hq.global_position
			var e1 = _map.spawn_unit(HevDef, false, hq_pos + Vector3(10, 0, 0))
			var e2 = _map.spawn_unit(HevDef, false, hq_pos + Vector3(-10, 0, 0))
			_map.player_hq.hp = 30.0
			_orders.issue_attack([e1, e2], _map.player_hq)
			_goto(16, 2000)
		16:
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
			_goto(17, 300)
		17:
			if _expired():
				_goto(18, 1)
			return false
		18:
			if not _expired():
				return false
			_grab()
			if not _assert_fresh("restart#2"):
				return true
			print("PHASE15_TEST OK")
			quit(0)
			return true
	return false


func _assert_fresh(tag: String) -> bool:
	if paused:
		print("PHASE15_TEST NG %s: still paused" % tag)
		quit(1)
		return false
	if _mm.phase != MatchManager.Phase.PLAYING:
		print("PHASE15_TEST NG %s: not playing" % tag)
		quit(1)
		return false
	if not _map.player_hq.is_alive() or not _map.enemy_hq.is_alive():
		print("PHASE15_TEST NG %s: HQ dead" % tag)
		quit(1)
		return false
	if absf(_map.player_hq.hp - _map.player_hq.max_hp) > 0.01:
		print("PHASE15_TEST NG %s: player HQ hp not reset" % tag)
		quit(1)
		return false
	if absf(_eco_p.material - 150.0) > 40.0:
		print("PHASE15_TEST NG %s: material not reset (%d)" % [tag, int(_eco_p.material)])
		quit(1)
		return false
	if _eco_p.pop_used != 0:
		print("PHASE15_TEST NG %s: pop not reset" % tag)
		quit(1)
		return false
	if _outpost.owner_side != RTSOutpost.Owner.NEUTRAL:
		print("PHASE15_TEST NG %s: outpost not neutral" % tag)
		quit(1)
		return false
	if _units(true).size() != 5 or _units(false).size() != 5:
		print("PHASE15_TEST NG %s: armies not 5v5" % tag)
		quit(1)
		return false
	_ok("%s: fresh match state" % tag)
	return true


func _counts_by_id(player_flag: bool) -> Dictionary:
	var d := {}
	for u in _units(player_flag):
		var id := str((u as RTSUnit).definition.id)
		d[id] = int(d.get(id, 0)) + 1
	return d
