class_name VisualAirship
extends Node3D
## Visual Slice Gearforge airship (Phase 1.75). Lightweight by design: slow
## cruise on a circular patrol at fixed altitude, gentle bob, faction glow
## from the GLB itself. Optional light bombardment every few seconds using
## a small TitanShell so the sky contributes to the battle readably.
## No aviation AI, no docking, no Phase 2 systems.

const AirshipGLB: PackedScene = preload("res://assets/models/gearforge_airship.glb")

## Phase 2.5C: the production hull is 35.45 m long and 11.38 m tall, so the
## Phase 1.75 altitude put it inside the skyline. Altitude is visual only -
## _nearest_foe measures horizontal distance, so bombardment is unchanged.
const CRUISE_HEIGHT: float = 26.0
const CRUISE_RADIUS: float = 22.0
const CRUISE_SPEED: float = 0.09
const BOMB_INTERVAL: float = 6.0
const BOMB_DAMAGE: float = 35.0
const BOMB_SPLASH: float = 3.0

var is_player: bool = true
var bombard_enabled: bool = true
var center: Vector3 = Vector3.ZERO

var _angle: float = 0.6
var _bomb_left: float = 4.0
var _bob_t: float = 0.0
var _fx_root: Node3D = null


func _ready() -> void:
	add_to_group("visual_airships")
	var visual := AirshipGLB.instantiate() as Node3D
	add_child(visual)
	for c in _find_meshes(visual):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx_root = get_parent() as Node3D


func _find_meshes(n: Node) -> Array:
	var out: Array = []
	if n is GeometryInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_meshes(c))
	return out


func _process(delta: float) -> void:
	_angle += CRUISE_SPEED * delta
	_bob_t += delta
	var target := Vector3(center.x + cos(_angle) * CRUISE_RADIUS, CRUISE_HEIGHT + sin(_bob_t * 0.7) * 0.6, center.z + sin(_angle) * CRUISE_RADIUS)
	global_position = global_position.lerp(target, minf(1.0, delta * 1.5))
	var dir := Vector3(-sin(_angle), 0, cos(_angle))
	if dir.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 1.5))
	_bomb_left -= delta
	if bombard_enabled and _bomb_left <= 0.0:
		_bomb_left = BOMB_INTERVAL
		_try_bombard()


func _try_bombard() -> void:
	var foe := _nearest_foe(45.0)
	if foe == null:
		return
	var fx := _resolve_fx()
	if fx == null:
		return
	VisualFX.muzzle(fx, global_position, is_player, false)
	TitanShell.fire(fx, global_position + Vector3(0, -1.0, 0), (foe as Node3D).global_position, is_player, BOMB_DAMAGE, BOMB_SPLASH)


func _nearest_foe(max_dist: float) -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node3D = null
	var best_d := max_dist
	for o in tree.get_nodes_in_group("rts_units"):
		var n := o as Node3D
		if n == null or not is_instance_valid(n):
			continue
		if not n.has_method("is_alive") or not bool(n.call("is_alive")):
			continue
		if not ("is_player" in n) or bool(n.get("is_player")) == is_player:
			continue
		var dx := n.global_position.x - global_position.x
		var dz := n.global_position.z - global_position.z
		var d := sqrt(dx * dx + dz * dz)
		if d < best_d:
			best_d = d
			best = n
	return best


func _resolve_fx() -> Node3D:
	if _fx_root != null and is_instance_valid(_fx_root):
		return _fx_root
	var tree := get_tree()
	if tree != null:
		var fx := tree.get_first_node_in_group("visual_fx_root") as Node3D
		if fx != null:
			_fx_root = fx
			return fx
	return get_parent() as Node3D
