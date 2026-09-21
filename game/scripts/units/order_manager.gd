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


func issue_attack(units: Array, target: Node3D) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("is_alive") or not target.has_method("take_damage"):
		return
	if not bool(target.call("is_alive")):
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
		p = _map_nav.call("clamp_inside", p)
		if _map_nav.has_method("is_blocked") and bool(_map_nav.call("is_blocked", p.x, p.z)):
			p = _nearest_free(p)
	return p


## Nudge a formation slot out of obstacle footprints (checked only on order,
## never per-frame). Spiral samples at 1.5m / 3m rings.
func _nearest_free(p: Vector3) -> Vector3:
	for r in [1.5, 3.0]:
		for k in range(8):
			var a := TAU * float(k) / 8.0
			var q := Vector3(p.x + cos(a) * r, 0, p.z + sin(a) * r)
			q = _map_nav.call("clamp_inside", q)
			if not bool(_map_nav.call("is_blocked", q.x, q.z)):
				return q
	return p
