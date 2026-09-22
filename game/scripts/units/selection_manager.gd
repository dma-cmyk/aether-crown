class_name SelectionManager
extends Node3D
## RTS selection: left-click single, drag box multi, Shift adds.
## Right-click orders go through OrderManager. Left-click while an
## attack-move is pending issues attack-move instead of selecting.
## Scales to 100+ units: box test is a single O(n) projection pass.

signal selection_changed

const DRAG_THRESHOLD_PX: float = 8.0
const WORLD_MASK: int = 1
const UNIT_MASK: int = 2

var selected: Array = []
var attack_move_pending: bool = false

var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO
var _rig: Node3D = null
var _camera: Camera3D = null
var _orders: OrderManager = null
var _box: Control = null


func _ready() -> void:
	add_to_group("selection_manager")
	_rig = get_tree().get_first_node_in_group("rts_camera") as Node3D
	if _rig != null:
		_camera = _rig.get_node_or_null("Camera3D") as Camera3D
	_refresh_refs()


## Sibling _ready order is not guaranteed, so resolve late-registered refs
## lazily (OrderManager/SelectionBox may ready after this node).
func _refresh_refs() -> void:
	if _orders == null:
		_orders = get_tree().get_first_node_in_group("order_manager") as OrderManager
	if _box == null:
		_box = get_tree().get_first_node_in_group("selection_box") as Control


func get_camera() -> Camera3D:
	return _camera


func clear_selection() -> void:
	for u in selected:
		if is_instance_valid(u) and (u as Node).has_method("set_selected"):
			(u as Node).call("set_selected", false)
	selected.clear()
	selection_changed.emit()


func selected_count() -> int:
	_prune()
	return selected.size()


func selected_avg_hp() -> float:
	_prune()
	if selected.is_empty():
		return 0.0
	var sum := 0.0
	for u in selected:
		var n := u as Node
		var hp: float = float(n.get("hp"))
		var max_hp: float = maxf(1.0, float(n.get("max_hp")))
		sum += clampf(hp / max_hp, 0.0, 1.0)
	return sum / float(selected.size())


func _prune() -> void:
	var kept: Array = []
	for u in selected:
		var n := u as Node
		if is_instance_valid(n) and n.has_method("is_alive") and bool(n.call("is_alive")):
			kept.append(u)
	selected = kept


func _unhandled_input(event: InputEvent) -> void:
	if _camera == null:
		return
	if event.is_action_pressed("attack_move"):
		attack_move_pending = true
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_begin_press(mb.position)
			else:
				_end_press(mb.position, Input.is_key_pressed(KEY_SHIFT))
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_issue_right_click(mb.position)
	elif event is InputEventMouseMotion and _dragging:
		_drag_current = (event as InputEventMouseMotion).position
		_update_box()


func _over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null


func _begin_press(pos: Vector2) -> void:
	if _over_ui():
		_dragging = false
		return
	_dragging = true
	_drag_start = pos
	_drag_current = pos
	_update_box()


func _end_press(pos: Vector2, additive: bool) -> void:
	if not _dragging:
		return
	_dragging = false
	_hide_box()
	if _over_ui():
		return
	if _drag_start.distance_to(pos) >= DRAG_THRESHOLD_PX:
		_box_select(_drag_start, pos, additive)
		return
	if attack_move_pending:
		attack_move_pending = false
		_click_attack_move(pos)
		return
	_click_select(pos, additive)


func _click_select(pos: Vector2, additive: bool) -> void:
	var target := _pick_target(pos)
	if _is_owned_selectable(target):
		if additive:
			if not selected.has(target):
				selected.append(target)
				(target as Node).call("set_selected", true)
		else:
			clear_selection()
			selected.append(target)
			(target as Node).call("set_selected", true)
		selection_changed.emit()
	elif not additive:
		clear_selection()


## Owned player unit, player building (HQ), player Titan, player airship,
## or player walker. Enemy/outpost are not selectable. Titans, airships and
## walkers accept click-select only; box-select stays rts_units.
func _is_owned_selectable(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	if not n.has_method("is_alive") or not n.has_method("set_selected"):
		return false
	if not bool(n.call("is_alive")):
		return false
	if not ("is_player" in n) or not bool(n.get("is_player")):
		return false
	return (n is RTSUnit) or (n is RTSBuilding) or (n is VisualTitan) or (n is VisualAirship) or (n is VisualWalker)


func _box_select(a: Vector2, b: Vector2, additive: bool) -> void:
	var rect := Rect2(a, b).abs()
	if not additive:
		clear_selection()
	var units := get_tree().get_nodes_in_group("rts_units")
	for o in units:
		var u := o as RTSUnit
		if u == null or not u.is_alive() or not u.is_player:
			continue
		if _camera.is_position_behind(u.global_position + Vector3(0, 1, 0)):
			continue
		var sp: Vector2 = _camera.unproject_position(u.global_position + Vector3(0, 1, 0))
		if rect.has_point(sp) and not selected.has(u):
			selected.append(u)
			u.set_selected(true)
	selection_changed.emit()


func _click_attack_move(pos: Vector2) -> void:
	if selected.is_empty():
		return
	_prune()
	_refresh_refs()
	if _orders == null:
		return
	var target := _pick_target(pos)
	if _is_foe_damageable(target):
		_orders.issue_attack(selected, target)
		return
	var ground := _pick_ground(pos)
	if ground != Vector3.INF:
		_orders.issue_attack_move(selected, ground)


func _issue_right_click(pos: Vector2) -> void:
	if _over_ui() or selected.is_empty():
		attack_move_pending = false
		return
	_prune()
	if selected.is_empty():
		return
	attack_move_pending = false
	_refresh_refs()
	if _orders == null:
		return
	var target := _pick_target(pos)
	if _is_foe_damageable(target):
		_orders.issue_attack(selected, target)
		return
	var ground := _pick_ground(pos)
	if ground != Vector3.INF:
		_orders.issue_move(selected, ground)


## Enemy unit or enemy building: valid attack target for player selection.
func _is_foe_damageable(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	if not n.has_method("is_alive") or not n.has_method("take_damage"):
		return false
	if not bool(n.call("is_alive")):
		return false
	if not ("is_player" in n):
		return false
	return not bool(n.get("is_player"))


## Picks the topmost damageable under the cursor: player/enemy unit,
## building, Titan, airship, or walker. Phase 1 maps only spawn units, so
## Phase 1 picks are unchanged. Titan/airship/walker colliders resolve to
## the visual root, enabling click-select (own) and force-attack orders
## (foe Titans; airships and walkers expose no take_damage yet, so foe
## clicks there fall through to ground orders).
func _pick_target(pos: Vector2) -> Node3D:
	var params := PhysicsRayQueryParameters3D.create(_ray_origin(pos), _ray_origin(pos) + _ray_dir(pos) * 300.0)
	params.collision_mask = UNIT_MASK
	var hit := _space().intersect_ray(params)
	if hit.is_empty():
		return null
	var node := hit.get("collider") as Node
	while node != null and not (node is RTSUnit) and not (node is RTSBuilding) and not (node is VisualTitan) and not (node is VisualAirship) and not (node is VisualWalker):
		node = node.get_parent()
	return node as Node3D


func _pick_unit(pos: Vector2) -> RTSUnit:
	return _pick_target(pos) as RTSUnit


func _pick_ground(pos: Vector2) -> Vector3:
	var params := PhysicsRayQueryParameters3D.create(_ray_origin(pos), _ray_origin(pos) + _ray_dir(pos) * 500.0)
	params.collision_mask = WORLD_MASK
	var hit := _space().intersect_ray(params)
	if hit.is_empty():
		return Vector3.INF
	return hit.get("position")


func _ray_origin(pos: Vector2) -> Vector3:
	return _camera.project_ray_origin(pos)


func _ray_dir(pos: Vector2) -> Vector3:
	return _camera.project_ray_normal(pos)


func _space() -> PhysicsDirectSpaceState3D:
	return _camera.get_world_3d().direct_space_state


func _update_box() -> void:
	_refresh_refs()
	if _box != null and _box.has_method("set_box"):
		_box.call("set_box", _drag_start, _drag_current)


func _hide_box() -> void:
	if _box != null and _box.has_method("hide_box"):
		_box.call("hide_box")
