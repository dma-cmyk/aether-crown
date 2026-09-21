class_name OrderManager
extends Node3D
## Issues orders to unit groups. Path is set once per order; units never
## repath every frame. Group moves use grid slots so units do not stack.

const SLOT_SPACING: float = 2.4

var _map_nav: Node = null


func _ready() -> void:
	add_to_group("order_manager")
	_map_nav = get_tree().get_first_node_in_group("map_nav")


func issue_move(units: Array, dest: Vector3) -> void:
	var slots := formation_slots(dest, units.size())
	for i in range(units.size()):
		var u := units[i] as RTSUnit
		if u != null and u.is_alive():
			u.order_move(slots[i])


func issue_attack(units: Array, target: RTSUnit) -> void:
	if target == null or not target.is_alive():
		return
	for u in units:
		var unit := u as RTSUnit
		if unit != null and unit.is_alive():
			unit.order_attack(target)


func issue_attack_move(units: Array, dest: Vector3) -> void:
	var slots := formation_slots(dest, units.size())
	for i in range(units.size()):
		var u := units[i] as RTSUnit
		if u != null and u.is_alive():
			u.order_attack_move(slots[i])


func formation_slots(center: Vector3, count: int) -> Array:
	var slots: Array = []
	if count <= 0:
		return slots
	if count == 1:
		slots.append(_clamp_slot(center))
		return slots
	var cols := int(ceil(sqrt(float(count))))
	var rows := int(ceil(float(count) / float(cols)))
	var ox := (float(cols) - 1.0) * SLOT_SPACING * 0.5
	var oz := (float(rows) - 1.0) * SLOT_SPACING * 0.5
	for i in range(count):
		var cx := float(i % cols) * SLOT_SPACING - ox
		var cz := float(i / cols) * SLOT_SPACING - oz
		slots.append(_clamp_slot(center + Vector3(cx, 0, cz)))
	return slots


func _clamp_slot(p: Vector3) -> Vector3:
	if _map_nav != null and _map_nav.has_method("clamp_inside"):
		return _map_nav.call("clamp_inside", p)
	return p
