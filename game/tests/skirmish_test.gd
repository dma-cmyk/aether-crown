extends SceneTree
## Phase 1 integration test (headless): click-select, box-select, move and
## attack orders through the real SelectionManager/OrderManager + physics.
## Usage: godot --headless --path game --script res://tests/skirmish_test.gd

var _frame: int = 0
var _map: Node = null
var _sel = null
var _orders = null
var _cam: Camera3D = null
var _phase: int = 0
var _target: RTSUnit = null


func _initialize() -> void:
	var packed := load("res://scenes/maps/phase1_battlefield.tscn") as PackedScene
	_map = packed.instantiate()
	root.add_child(_map)


func _first_player() -> RTSUnit:
	for o in get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_player and u.is_alive():
			return u
	return null


func _screen_of(u: RTSUnit) -> Vector2:
	return _cam.unproject_position(u.global_position + Vector3(0, 1, 0))


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 10:
		_sel = get_first_node_in_group("selection_manager")
		_orders = get_first_node_in_group("order_manager")
		var rig := get_first_node_in_group("rts_camera") as Node3D
		_cam = rig.get_node("Camera3D") as Camera3D
		var u := _first_player()
		if u == null:
			print("SKIRMISH_TEST NG no-player-unit")
			quit(1)
			return true
		_sel._click_select(_screen_of(u), false)
		print("SKIRMISH_TEST click-selected=", _sel.selected_count())
		if _sel.selected_count() < 1:
			print("SKIRMISH_TEST NG click-select")
			quit(1)
			return true
		_phase = 1
	elif _phase == 1 and _frame == 20:
		# Headless viewport is tiny (64px); build the box from projected
		# points instead of window size so the box logic itself is tested.
		var lo := Vector2.INF
		var hi := -Vector2.INF
		for o in get_nodes_in_group("rts_units"):
			var u := o as RTSUnit
			if u == null or not u.is_player or not u.is_alive():
				continue
			if _cam.is_position_behind(u.global_position):
				continue
			var sp := _screen_of(u)
			lo.x = minf(lo.x, sp.x)
			lo.y = minf(lo.y, sp.y)
			hi.x = maxf(hi.x, sp.x)
			hi.y = maxf(hi.y, sp.y)
		print("SKIRMISH_TEST project-box=", Rect2(lo, hi - lo))
		_sel._box_select(lo - Vector2(4, 4), hi + Vector2(4, 4), false)
		print("SKIRMISH_TEST box-selected=", _sel.selected_count())
		if _sel.selected_count() < 2:
			print("SKIRMISH_TEST NG box-select")
			quit(1)
			return true
		_orders.issue_move(_sel.selected, Vector3(0, 0, 0))
		_phase = 2
	elif _phase == 2 and _frame == 140:
		var moving := 0
		for o in _sel.selected:
			var u := o as RTSUnit
			if u != null and (u.state != RTSUnit.State.IDLE or u.has_move_order):
				moving += 1
		print("SKIRMISH_TEST moving-or-arrived=", moving, "/", _sel.selected_count())
		if moving == 0:
			print("SKIRMISH_TEST NG move-order")
			quit(1)
			return true
		var foe: RTSUnit = null
		var best_d := INF
		var centroid := Vector3.ZERO
		var cnt := 0
		for o in _sel.selected:
			var u := o as RTSUnit
			if u != null and u.is_alive():
				centroid += u.global_position
				cnt += 1
		if cnt > 0:
			centroid /= float(cnt)
		for o in get_nodes_in_group("rts_units"):
			var u := o as RTSUnit
			if u != null and not u.is_player and u.is_alive():
				var d := centroid.distance_to(u.global_position)
				if d < best_d:
					best_d = d
					foe = u
		print("SKIRMISH_TEST nearest-foe-dist=", best_d)
		_target = foe
		_orders.issue_attack(_sel.selected, foe)
		# March the enemy side toward our group too so melee is reached
		# within the test window (both sides closing halves the distance).
		var foes: Array = []
		for o in get_nodes_in_group("rts_units"):
			var u := o as RTSUnit
			if u != null and not u.is_player and u.is_alive():
				foes.append(u)
		_orders.issue_attack_move(foes, centroid)
		_phase = 3
	elif _phase == 3 and _frame == 1300:
		var hp_left := -1.0
		if is_instance_valid(_target):
			hp_left = (_target as RTSUnit).hp
		var chasing := 0
		for o in _sel.selected:
			var u := o as RTSUnit
			if u != null and u.is_alive() and (u.state == RTSUnit.State.CHASING or u.state == RTSUnit.State.ATTACKING):
				chasing += 1
		print("SKIRMISH_TEST target-hp-left=", hp_left, " chasing=", chasing)
		if hp_left >= 90.0:
			print("SKIRMISH_TEST NG attack-order (no damage)")
			quit(1)
			return true
		print("SKIRMISH_TEST OK")
		quit(0)
		return true
	return false
