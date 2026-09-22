extends SceneTree
## Phase 2.7 playable-convergence test on the canonical strategic match:
## walker production (material+aether+supply+queue+spawn+rally), walker
## orders/selection/combat/death, enemy walker production through the same
## economy, plus the existing loop anchors (city capture, victory, defeat,
## restart are covered by phase2d_test — here they are spot-checked).
## No production-code hacks: force-completion uses the queue's public
## progress field, same as phase2d_test.
## Usage: godot --headless --path game --script res://tests/phase27_test.gd

var _frame := 0
var _phase := 0
var _deadline := 0
var _map: Node = null
var _eco_p: RTSEconomy = null
var _eco_e: RTSEconomy = null
var _q_p: ProductionQueue = null
var _q_e: ProductionQueue = null
var _mm: MatchManager = null
var _orders: OrderManager = null
var _strat: EnemyStrategist = null
var _walker_def: UnitDefinition = null
var _produced: VisualWalker = null
var _enemy_walker: VisualWalker = null
var _move_from := Vector3.INF


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase2d_strategic_match.tscn")


func _fail(message: String) -> bool:
	print("PHASE27_TEST NG ", message)
	quit(1)
	return true


func _ok(message: String) -> void:
	print("PHASE27_TEST ok: ", message)


func _goto(next: int, wait_frames: int) -> void:
	_phase = next
	_deadline = _frame + wait_frames


func _walkers(player_flag: int) -> Array:
	# player_flag: -1 = any, 0 = enemy, 1 = player
	var out: Array = []
	for w in get_nodes_in_group("visual_walkers"):
		if not bool((w as Node).call("is_alive")):
			continue
		if player_flag == -1 or int(bool((w as Node).get("is_player"))) == player_flag:
			out.append(w)
	return out


func _grab() -> void:
	_map = get_first_node_in_group("match_map")
	_eco_p = _map.get("economy_p") as RTSEconomy
	_eco_e = _map.get("economy_e") as RTSEconomy
	_q_p = _map.get("queue_p") as ProductionQueue
	_q_e = _map.get("queue_e") as ProductionQueue
	_mm = _map.get("match_mgr") as MatchManager
	_orders = _map.get("orders") as OrderManager
	_strat = _map.get("strategist") as EnemyStrategist
	_walker_def = _map.get("WalkerDef") as UnitDefinition


func _process(_delta: float) -> bool:
	return false


# Waits run on physics frames: walker movement is move_and_slide-based.
func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	if _frame > _deadline and _phase > 0:
		return _fail("timeout at phase %d" % _phase)
	match _phase:
		0:
			return _p0_static()
		1:
			return _p1_pay_and_queue()
		2:
			return _p2_spawn_and_rally()
		3:
			return _p3_orders()
		31:
			return _p31()
		4:
			return _p4_combat_and_death()
		40:
			return _p40_spawn_duel()
		41:
			return _p41_kill_check()
		42:
			return _p42_death_check()
		5:
			return _p5_selection()
		6:
			return _p6_enemy_walker()
		61:
			return _p61_enemy_spawned()
		7:
			return _p7_loop_anchor()
		71:
			return _p71_victory()
		72:
			return _p72_restart()
	return false


func _p0_static() -> bool:
	_grab()
	if _map == null:
		return _fail("strategic match missing")
	if _walker_def == null or _walker_def.id != &"gf_walker":
		return _fail("WalkerDef not wired into the match")
	if _walker_def.cost_metal != 150 or _walker_def.cost_aether != 20 or _walker_def.supply_cost != 3:
		return _fail("walker def values changed unexpectedly")
	if _strat.get("walker_def") == null:
		return _fail("strategist walker_def not wired")
	var hud := _map.get_node_or_null("HUD")
	if hud == null or hud.get_node_or_null("SelPanel/SelVBox/ProdRow/BtnWal") == null:
		return _fail("walker production button missing")
	_ok("match loads, WalkerDef+strategist+HUD wired (150M/20A/pop3)")
	_goto(1, 60)
	return false


func _p1_pay_and_queue() -> bool:
	# Fund the wallet to the walker price point (test-side economy only,
	# same pattern as phase2d_test's district funding): start 120M cannot
	# afford 150M, and waiting for income would only slow the suite.
	_eco_p.material = 200.0
	_eco_p.aether = 25.0
	var mat0 := _eco_p.material
	var result := _q_p.try_enqueue(_walker_def, _eco_p)
	if result != "ok":
		return _fail("walker enqueue rejected: %s" % result)
	if int(_eco_p.material) != int(mat0 - 150.0):
		return _fail("material not paid (%.0f -> %.0f)" % [mat0, _eco_p.material])
	if absf(_eco_p.aether - 5.0) > 0.01:
		return _fail("aether not paid")
	if _q_p.front() == null or _q_p.front().id != &"gf_walker":
		return _fail("queue front is not walker")
	# pop reservation: 40 max, queued walker reserves 3.
	if _eco_p.can_house(58, _q_p.queued_pop()):
		return _fail("walker supply not reserved in queued_pop")
	_ok("walker pays 150M/20A, queues, reserves 3 supply")
	_q_p.set("progress_sec", 999.0)
	_goto(2, 1400)
	return false


func _p2_spawn_and_rally() -> bool:
	# Phase 2 runs until the rally attack-move completes (~23s travel from
	# the HQ gate to midfield at 3.6 m/s), then phase 3 re-checks.
	if _walkers(1).is_empty():
		return false
	_produced = _walkers(1)[0]
	if not _produced.attack_moving and not _produced.has_move_order:
		if _eco_p.pop_used != 3:
			return _fail("pop_used want 3 after spawn, got %d" % _eco_p.pop_used)
		var hq: RTSBuilding = _map.get("player_hq")
		var spawn_d := _produced.global_position.distance_to(hq.global_position)
		if spawn_d > 55.0:
			return _fail("walker drifted too far (%.0fm)" % spawn_d)
		_ok("walker spawned, rallied %.0fm toward midfield, pop 3 used" % spawn_d)
		_goto(3, 60)
		return false
	return false


func _p3_orders() -> bool:
	# Issue an explicit move order toward the enemy base and verify the
	# walker covers ground. Checked on later physics frames (no busy loops).
	if _move_from == Vector3.INF:
		_move_from = _produced.global_position
		_orders.issue_move([_produced], _move_from + Vector3(14, 0, 14))
		_goto(31, 400)
		return false
	return false


func _p31() -> bool:
	var moved := _produced.global_position.distance_to(_move_from)
	if moved >= 4.0:
		_ok("walker move order works (moved %.1fm)" % moved)
		_goto(4, 60)
		return false
	if _frame >= _deadline:
		return _fail("walker did not move after issue_move (%.2fm)" % moved)
	return false


var _enemy_unit: RTSUnit = null
var _pop_before := 0


func _p4_combat_and_death() -> bool:
	# Hold the walker in place first so the duel is deterministic, then
	# spawn a weak enemy infantry next to it: auto-engage must kill it.
	_produced.order_move(_produced.global_position)
	_produced.guard_pos = _produced.global_position
	_goto(40, 60)
	return false


func _p40_spawn_duel() -> bool:
	_enemy_unit = _map.call("spawn_unit", _map.get("InfantryDef"), false, _produced.global_position + Vector3(6, 0, 0))
	if _enemy_unit == null:
		return _fail("failed to spawn enemy infantry")
	_enemy_unit.max_hp = 40.0
	_enemy_unit.hp = 40.0
	_pop_before = _eco_p.pop_used
	_goto(41, 600)
	return false


func _p41_kill_check() -> bool:
	if is_instance_valid(_enemy_unit) and _enemy_unit.is_alive():
		if _frame >= _deadline:
			return _fail("walker did not kill adjacent enemy infantry")
		return false
	# Walker death path: pop return + selection cleanup + FX.
	_produced.take_damage(9999.0, null)
	_goto(42, 240)
	return false


func _p42_death_check() -> bool:
	if is_instance_valid(_produced):
		if _frame >= _deadline:
			return _fail("walker did not die/free after lethal damage")
		return false
	if _eco_p.pop_used != _pop_before - 3:
		return _fail("walker death did not return supply (%d -> %d)" % [_pop_before, _eco_p.pop_used])
	_ok("walker combat kill + death (supply returned, freed)")
	_goto(5, 30)
	return false


func _p5_selection() -> bool:
	# Box-select must include walkers (Phase 2.6 rule on the match map).
	var w := _map.call("spawn_walker", true, Vector3(-24, 0, -24)) as VisualWalker
	var sel: SelectionManager = _map.get("selection")
	sel.clear_selection()
	var cam := sel.get_camera()
	var rig := _map.get_node_or_null("CameraRig") as Node3D
	rig.position = Vector3(w.global_position.x, 0, w.global_position.z + 22.0)
	rig.set("distance", 22.0)
	rig.call("_process", 0.016)
	var sp := cam.unproject_position(w.global_position + Vector3(0, 1, 0))
	sel.call("_box_select", sp - Vector2(140, 140), sp + Vector2(140, 140), false)
	if not sel.selected.has(w):
		return _fail("box-select missed walker on match map")
	# Mixed selection: walker + a player infantry together.
	var inf: RTSUnit = null
	for u in get_nodes_in_group("rts_units"):
		if (u as RTSUnit).is_player and (u as RTSUnit).is_alive():
			inf = u
			break
	if inf != null:
		var sp2 := cam.unproject_position(inf.global_position + Vector3(0, 1, 0))
		var a := Vector2(minf(sp.x, sp2.x) - 60, minf(sp.y, sp2.y) - 60)
		var b := Vector2(maxf(sp.x, sp2.x) + 60, maxf(sp.y, sp2.y) + 60)
		sel.clear_selection()
		sel.call("_box_select", a, b, false)
		if sel.selected_count() < 2:
			return _fail("mixed box-select got %d" % sel.selected_count())
	sel.clear_selection()
	w.take_damage(9999.0, null)
	# The AI keeps producing during the test; reset its queue so the walker
	# spawn check below is deterministic (test-side queue only).
	var q_e: ProductionQueue = _map.get("queue_e")
	q_e.queue.clear()
	q_e.set("progress_sec", 0.0)
	_ok("box-select + mixed selection include walkers")
	_goto(6, 60)
	return false


func _p6_enemy_walker() -> bool:
	# Enemy walker production through the strategist's own economy/queue.
	# The pick threshold needs a battalion (>=7), so reinforce the enemy
	# force to 7 via normal spawn before asking for a pick.
	var foes := 0
	for u in get_nodes_in_group("rts_units"):
		if not (u as RTSUnit).is_player and (u as RTSUnit).is_alive():
			foes += 1
	var need := 7 - foes
	for i in range(need):
		_map.call("spawn_unit", _map.get("InfantryDef"), false, Vector3(28, 0, 28) + Vector3(float(i) * 1.5, 0, 0))
	# Walker saving also gates on owning a city: grant East to the enemy
	# directly (capture mechanics are phase2d_test's scope).
	var east := _map.get_city("east_bastion") as RTSCity
	east.owner_side = RTSCity.Owner.ENEMY
	east.call("_refresh_visuals")
	_eco_e.material = 400.0
	_eco_e.aether = 60.0
	var mat0 := _eco_e.material
	var ae0 := _eco_e.aether
	var def := _strat.call("_pick_production", _strat.army()) as UnitDefinition
	if def == null or def.id != &"gf_walker":
		return _fail("strategist did not pick walker with funded wallet")
	_q_e.try_enqueue(def, _eco_e)
	if _q_e.queue.is_empty():
		return _fail("enemy walker enqueue failed")
	if int(_eco_e.material) != int(mat0 - 150.0) or absf(_eco_e.aether - (ae0 - 20.0)) > 0.01:
		return _fail("enemy did not pay walker costs")
	_q_e.set("progress_sec", 999.0)
	_goto(61, 120)
	return false


func _p61_enemy_spawned() -> bool:
	if _walkers(0).is_empty():
		if _frame >= _deadline:
			var q: ProductionQueue = _map.get("queue_e")
			print("PHASE27_DEBUG p6 q=%d eco=%.0f/%.1f walkers_any=%d" % [q.queue.size(), _eco_e.material, _eco_e.aether, _walkers(-1).size()])
			return _fail("enemy walker did not spawn")
		return false
	_enemy_walker = _walkers(0)[0]
	_ok("enemy AI pays and fields a walker (no free spawn)")
	_goto(7, 60)
	return false


func _p7_loop_anchor() -> bool:
	# Spot-check the loop anchors phase2d_test owns: victory + restart.
	var eh: RTSBuilding = _map.get("enemy_hq")
	eh.take_damage(999999.0, null)
	_goto(71, 60)
	return false


func _p71_victory() -> bool:
	if _mm.phase != MatchManager.Phase.VICTORY:
		return _fail("victory not reached on enemy HQ death")
	_ok("victory state reachable")
	_mm.restart()
	_goto(72, 240)
	return false


func _p72_restart() -> bool:
	var fresh := get_first_node_in_group("match_map")
	if fresh == null or fresh == _map:
		return _fail("restart did not reload the match")
	if not (fresh.get("match_mgr") as MatchManager).is_playing():
		return _fail("restarted match not playing")
	if _walkers(-1).size() != 0:
		return _fail("walkers survived restart")
	_ok("restart resets the match (fresh scene, no leftover walkers)")
	print("PHASE27_TEST OK production+payment+supply+spawn+rally+orders+combat+death+selection+enemywalker+victory+restart")
	quit(0)
	return true

