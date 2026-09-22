extends SceneTree
## Phase 2.6 playable-slice test on the prototype battlefield: production
## queue -> gate spawn -> rally move, walker force-attack via OrderManager,
## box-select covers walkers, ground collision picks, camera south clamp is
## zoom-proportional, red auto-wave produces. Sandbox economy: no balance
## assertions, flow only.
## Usage: godot --headless --path game --script res://tests/phase26_test.gd

var _frame := 0
var _phase := 0
var _wait := 0
var _map: Node = null
var _produced: VisualWalker = null
var _walker_count0 := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/prototype_battlefield.tscn")


func _fail(message: String) -> bool:
	print("PHASE26_TEST NG ", message)
	quit(1)
	return true


func _walkers() -> Array:
	var out: Array = []
	for w in get_nodes_in_group("visual_walkers"):
		if (w as Node).get_parent() != null:
			out.append(w)
	return out


func _blue_walkers() -> Array:
	var out: Array = []
	for w in _walkers():
		if bool((w as Node).get("is_player")) and bool((w as Node).call("is_alive")):
			out.append(w)
	return out


func _check_static() -> bool:
	_map = get_first_node_in_group("prototype_battlefield")
	if _map == null:
		return _fail("scene missing")
	# Managers wired in the tscn.
	if get_first_node_in_group("selection_manager") == null:
		return _fail("SelectionManager missing")
	if get_first_node_in_group("order_manager") == null:
		return _fail("OrderManager missing")
	if get_first_node_in_group("selection_box") == null:
		return _fail("SelectionBox missing")
	if get_first_node_in_group("map_nav") == null:
		return _fail("PrototypeNav missing")
	# Ground collision (world layer) present for move-order picks.
	var ground := _map.get_node_or_null("GroundRoot/GroundBody") as StaticBody3D
	if ground == null or ground.collision_layer != 1:
		return _fail("ground collision missing")
	# Infantry are live (no longer frozen since Phase 2.6).
	var units := _map.get_node_or_null("UnitsRoot")
	if units == null:
		return _fail("UnitsRoot missing")
	for c in units.get_children():
		if c is RTSUnit and c.process_mode == Node.PROCESS_MODE_DISABLED:
			return _fail("infantry still frozen: %s" % c.name)
	# Walkers carry real combat stats from gf_walker.tres.
	_walker_count0 = _walkers().size()
	if _walker_count0 < 5:
		return _fail("want >=5 walkers, got %d" % _walker_count0)
	for w in _walkers():
		if (w as VisualWalker).max_hp < 100.0:
			return _fail("walker def HP not applied: %s" % (w as Node).name)
	# Production plumbing.
	if _map.get("_queue_blue") == null or _map.get("_queue_red") == null:
		return _fail("production queues missing")
	if _map.get("_econ_blue") == null:
		return _fail("economy missing")
	# Camera south clamp is zoom-proportional (Phase 2.6 fix).
	var rig := _map.get_node_or_null("CameraRig") as Node3D
	if rig == null:
		return _fail("camera rig missing")
	rig.set("distance", 60.0)
	rig.position.z = 9999.0
	rig.call("_process", 0.016)
	var limit := float(rig.get("map_limit"))
	if rig.position.z < limit + 40.0:
		return _fail("south clamp too tight at zoom 60: z=%.1f limit=%.1f" % [rig.position.z, limit])
	if rig.position.z > limit + 61.0:
		return _fail("south clamp too loose at zoom 60: z=%.1f limit=%.1f" % [rig.position.z, limit])
	rig.position = Vector3(0, 0, 48)
	rig.set("distance", 28.0)
	print("PHASE26_STATIC OK managers+nav+ground+defs camera_south=%.1f/%.1f" % [rig.position.z, limit])
	return false


# All waits run on physics frames: headless _process is uncapped, so
# walker movement (move_and_slide) only advances during physics ticks.
func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	if _phase == 0:
		if _check_static():
			return true
		# Enqueue one blue walker through the sandbox production path.
		var result := _map.call("try_produce_walker") as String
		if result != "ok":
			return _fail("try_produce_walker -> %s" % result)
		_phase = 1
		_wait = 20
		return false
	if _phase == 1:
		_wait -= 1
		if _wait > 0:
			return false
		var q: ProductionQueue = _map.get("_queue_blue")
		if q.is_empty():
			return _fail("blue queue empty right after enqueue")
		if q.front() == null or q.front().id != &"gf_walker":
			return _fail("blue queue front is not gf_walker")
		if q.front_fraction() <= 0.0:
			return _fail("blue queue not progressing")
		print("PHASE26_QUEUE OK remaining=%.1f" % q.front_remaining())
		# Skip the build wait: force-complete to keep the test short.
		q.set("progress_sec", 999.0)
		_phase = 2
		_wait = 10
		return false
	if _phase == 2:
		_wait -= 1
		if _wait > 0:
			return false
		if _walkers().size() != _walker_count0 + 1:
			return _fail("want +1 walker after production, got %d (was %d)" % [_walkers().size(), _walker_count0])
		for w in _walkers():
			if (w as Node3D).name.begins_with("WalkerBlueP"):
				_produced = w
		if _produced == null:
			return _fail("produced walker not found")
		var spawn: Vector3 = _map.get("WALKER_SPAWN_BLUE")
		if _produced.global_position.distance_to(spawn) > 8.0:
			return _fail("produced walker too far from gate: %s" % str(_produced.global_position))
		print("PHASE26_PRODUCE OK %s at %s" % [_produced.name, str(_produced.global_position)])
		_phase = 3
		_wait = 240
		return false
	if _phase == 3:
		# Produced walker received a rally move order at spawn. 240 frames
		# (~4s at 3.6 m/s) covers the ~18m gate->rally lane.
		_wait -= 1
		if _wait > 0:
			return false
		var rally: Vector3 = _map.get("WALKER_RALLY_BLUE")
		var d := _produced.global_position.distance_to(rally)
		if d > 7.0:
			return _fail("produced walker did not approach rally (d=%.1f)" % d)
		print("PHASE26_RALLY OK d=%.1f" % d)
		_phase = 4
		_wait = 5
		return false
	if _phase == 4:
		# OrderManager duck-typing: explicit move order on the walker.
		_wait -= 1
		if _wait > 0:
			return false
		var orders := get_first_node_in_group("order_manager") as OrderManager
		var from := _produced.global_position
		orders.issue_move([_produced], Vector3(-30, 0, 12))
		_phase = 5
		_wait = 150
		_last_from = from
		return false
	if _phase == 5:
		_wait -= 1
		if _wait > 0:
			return false
		if _produced.global_position.distance_to(_last_from) < 4.0:
			return _fail("walker did not move after issue_move")
		print("PHASE26_MOVE OK moved=%.1f" % _produced.global_position.distance_to(_last_from))
		_phase = 6
		_wait = 5
		return false
	if _phase == 6:
		# Force-attack: blue walker vs red walker via OrderManager.
		_wait -= 1
		if _wait > 0:
			return false
		var orders := get_first_node_in_group("order_manager") as OrderManager
		var red: VisualWalker = null
		for w in _walkers():
			if not bool((w as Node).get("is_player")) and bool((w as Node).call("is_alive")):
				red = w
				break
		if red == null:
			return _fail("no live red walker")
		# Teleport next to the target so the attack lands quickly.
		_produced.global_position = red.global_position + Vector3(6, 0, 0)
		orders.issue_attack([_produced], red)
		_red_target = red
		_red_hp0 = red.hp
		_phase = 7
		_wait = 240
		return false
	if _phase == 7:
		_wait -= 1
		if _wait > 0:
			return false
		if is_instance_valid(_red_target) and _red_target.hp >= _red_hp0:
			return _fail("force-attack dealt no damage (hp %.0f)" % _red_target.hp)
		var hp_now := 0.0
		if is_instance_valid(_red_target):
			hp_now = _red_target.hp
		print("PHASE26_ATTACK OK red hp %.0f -> %.0f" % [_red_hp0, hp_now])
		_phase = 8
		_wait = 5
		return false
	if _phase == 8:
		# Box-select covers walkers (Phase 2.6 selection extension).
		_wait -= 1
		if _wait > 0:
			return false
		var sel := get_first_node_in_group("selection_manager") as SelectionManager
		var cam := sel.get_camera()
		if cam == null:
			return _fail("selection camera missing")
		sel.clear_selection()
		# Frame the walker on screen, then box around its projection.
		var rig := _map.get_node_or_null("CameraRig") as Node3D
		rig.position = Vector3(_produced.global_position.x, 0, _produced.global_position.z + 22.0)
		rig.set("distance", 22.0)
		rig.call("_process", 0.016)
		var sp := cam.unproject_position(_produced.global_position + Vector3(0, 1, 0))
		sel.call("_box_select", sp - Vector2(120, 120), sp + Vector2(120, 120), false)
		if not sel.selected.has(_produced):
			return _fail("box-select missed walker")
		print("PHASE26_BOXSEL OK selected=%d" % sel.selected_count())
		sel.clear_selection()
		_phase = 9
		_wait = 5
		return false
	if _phase == 9:
		# Red auto-wave eventually enqueues/produces on its own timer.
		_wait -= 1
		if _wait > 0:
			return false
		var rq: ProductionQueue = _map.get("_queue_red")
		if rq.queue.is_empty():
			# Wave timer may not have fired yet; wait a bounded time.
			_red_wait += 1
			if _red_wait < 400:
				return false
			return _fail("red wave never enqueued")
		print("PHASE26_REDWAVE OK queued=%d" % rq.queue.size())
		print("PHASE26_TEST OK produce+rally+move+attack+boxsel+camera+redwave")
		quit(0)
		return true
	return false


var _last_from := Vector3.ZERO
var _red_target: VisualWalker = null
var _red_hp0 := 0.0
var _red_wait := 0
