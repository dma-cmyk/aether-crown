class_name VisualAirship
extends Node3D
## Visual Slice Gearforge airship (Phase 1.75). Lightweight by design: slow
## cruise on a circular patrol at fixed altitude, gentle bob, faction glow
## from the GLB itself. Optional light bombardment every few seconds using
## a small TitanShell so the sky contributes to the battle readably.
## No aviation AI, no docking, no Phase 2 systems.

const AirshipGLB: PackedScene = preload("res://assets/models/gearforge_airship.glb")
const AirshipLOD1: PackedScene = preload("res://assets/models/gearforge_airship_lod1.glb")

## Phase 2.5C: the production hull is 35.45 m long and 11.38 m tall, so the
## Phase 1.75 altitude put it inside the skyline. Altitude is visual only -
## _nearest_foe measures horizontal distance, so bombardment is unchanged.
const CRUISE_HEIGHT: float = 26.0
const CRUISE_RADIUS: float = 22.0
const CRUISE_SPEED: float = 0.09
const BOMB_INTERVAL: float = 6.0
const BOMB_DAMAGE: float = 35.0
const BOMB_SPLASH: float = 3.0
## Phase 2.5C.1 LOD switch: LOD0 below LOD_NEAR_MAX, LOD1 above
## LOD_FAR_MIN. Wider band than the Titan (35 m hull reads far).
const LOD_NEAR_MAX: float = 40.0
const LOD_FAR_MIN: float = 45.0
const LOD_CHECK_INTERVAL: float = 0.25
## Ground projection ring radius (selection): inside the 35 m hull so the
## marker reads as "this ship" without painting the whole battlefield.
const PROJ_RING_RADIUS: float = 11.0

var is_player: bool = true
var bombard_enabled: bool = true
var center: Vector3 = Vector3.ZERO
## Per-instance visual controls. Defaults preserve existing gameplay scenes;
## showcase/prototype scenes may shrink and berth the production hull without
## changing the shared airship asset or combat balance.
var cruise_height: float = CRUISE_HEIGHT
var cruise_radius: float = CRUISE_RADIUS
var cruise_speed: float = CRUISE_SPEED

var _angle: float = 0.6
var _bomb_left: float = 4.0
var _bob_t: float = 0.0
var _fx_root: Node3D = null
## Phase 2.5C.1 production state. The airship is not damageable yet
## (combat scope excluded): hp stays full, take_damage is intentionally absent
## so units cannot auto/force-attack it. Selection + display only.
var selected: bool = false
var hp: float = 1.0
var max_hp: float = 1.0
## Active LOD level (0 = production close, 1 = RTS distance).
var lod_level: int = 0
## When true (tests/showcase/benchmarks), set_lod() holds and the distance
## auto-switch is skipped. Gameplay default is false (auto).
var lod_locked: bool = false
var _visual_lod0: Node3D = null
var _visual_lod1: Node3D = null
var _lod_check_left: float = 0.0
var _camera: Camera3D = null
var _hp_bg: MeshInstance3D = null
var _hp_fg: MeshInstance3D = null
var _proj_ring: MeshInstance3D = null
var _center_anchor: Node3D = null
var _selection_anchor: Node3D = null
var _healthbar_anchor: Node3D = null


func _ready() -> void:
	add_to_group("visual_airships")
	_visual_lod0 = AirshipGLB.instantiate() as Node3D
	add_child(_visual_lod0)
	_visual_lod1 = AirshipLOD1.instantiate() as Node3D
	_visual_lod1.visible = false
	add_child(_visual_lod1)
	for visual in [_visual_lod0, _visual_lod1]:
		for c in _find_meshes(visual):
			(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_collision()
	_build_code_anchors()
	_build_markers()
	_refresh_visuals()
	_fx_root = get_parent() as Node3D


func is_alive() -> bool:
	return true


func set_selected(value: bool) -> void:
	selected = value
	_refresh_visuals()


func _find_meshes(n: Node) -> Array:
	var out: Array = []
	if n is GeometryInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_meshes(c))
	return out


func _process(delta: float) -> void:
	_angle += cruise_speed * delta
	_bob_t += delta
	var target := Vector3(center.x + cos(_angle) * cruise_radius,
		cruise_height + sin(_bob_t * 0.7) * 0.6,
		center.z + sin(_angle) * cruise_radius)
	global_position = global_position.lerp(target, minf(1.0, delta * 1.5))
	var dir := Vector3(-sin(_angle), 0, cos(_angle))
	if dir.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 1.5))
	_bomb_left -= delta
	if bombard_enabled and _bomb_left <= 0.0:
		_bomb_left = BOMB_INTERVAL
		_try_bombard()
	_update_lod_throttled(delta)
	_track_projection()


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


## Lightweight primitive hitbox: mesh collision is never used directly.
## Two boxes cover the hull mass and the twin lift cells; thin nose/tail
## tips and weapon barrels are intentionally excluded so the hitbox never
## reads as an oversized flying wall. Gondola/bridge clicks resolve through
## the hull box (same StaticBody).
func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	_add_box_shape(body, Vector3(4.8, 25.0, 4.6), Vector3(0, -0.5, 0.2), "hull")
	_add_box_shape(body, Vector3(13.4, 28.5, 5.6), Vector3(0, -0.15, 3.3), "cells")
	_add_box_shape(body, Vector3(4.2, 7.0, 3.6), Vector3(0, -7.3, -2.6), "gondola")


func _add_box_shape(parent: Node, size: Vector3, pos: Vector3, shape_name: String) -> void:
	var col := CollisionShape3D.new()
	col.name = "Collision_" + shape_name
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	parent.add_child(col)


## Code-side anchors for future VFX / weapon / UI hookup. GLB anchors
## (muzzle, weapon_l/r, reactor, engine/exhaust/thruster pairs, bow lens,
## bridge) stay the source of truth for weapon and FX positions.
func _build_code_anchors() -> void:
	_center_anchor = Node3D.new()
	_center_anchor.name = "center_anchor"
	add_child(_center_anchor)
	_selection_anchor = Node3D.new()
	_selection_anchor.name = "selection_anchor"
	_selection_anchor.position = Vector3(0, 7.5, 0)
	add_child(_selection_anchor)
	_healthbar_anchor = Node3D.new()
	_healthbar_anchor.name = "healthbar_anchor"
	_healthbar_anchor.position = Vector3(0, 8.6, 0)
	add_child(_healthbar_anchor)


## Selection read: HP bar on the hull (billboard, close/mid) + a subtle
## faction-colored ground projection ring (strategic). No giant ground disc.
func _build_markers() -> void:
	var tint := Color(0.35, 0.75, 1.0, 1.0) if is_player else Color(1.0, 0.35, 0.25, 1.0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = tint
	ring_mat.emission_enabled = true
	ring_mat.emission = tint
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_proj_ring = MeshInstance3D.new()
	var proj_mesh := TorusMesh.new()
	proj_mesh.inner_radius = PROJ_RING_RADIUS - 0.45
	proj_mesh.outer_radius = PROJ_RING_RADIUS
	proj_mesh.rings = 64
	proj_mesh.ring_segments = 8
	_proj_ring.mesh = proj_mesh
	_proj_ring.material_override = ring_mat
	_proj_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_proj_ring)
	var hpbg_mat := StandardMaterial3D.new()
	hpbg_mat.albedo_color = Color(0.08, 0.08, 0.08, 0.9)
	hpbg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hpbg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var hpf_mat := StandardMaterial3D.new()
	hpf_mat.albedo_color = tint
	hpf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hpf_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bg = MeshInstance3D.new()
	var bg_mesh := PlaneMesh.new()
	bg_mesh.size = Vector2(8.0, 0.6)
	_hp_bg.mesh = bg_mesh
	_hp_bg.material_override = hpbg_mat
	_hp_bg.position = Vector3(0, 8.6, 0)
	_hp_bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_bg)
	_hp_fg = MeshInstance3D.new()
	var fg_mesh := PlaneMesh.new()
	fg_mesh.size = Vector2(8.0, 0.6)
	_hp_fg.mesh = fg_mesh
	_hp_fg.material_override = hpf_mat
	_hp_fg.position = Vector3(0, 8.6, 0.02)
	_hp_fg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_fg)


func _refresh_visuals() -> void:
	var show := selected and is_alive()
	if _proj_ring != null:
		_proj_ring.visible = show
	if _hp_bg != null:
		_hp_bg.visible = show
	if _hp_fg != null:
		_hp_fg.visible = show


## Keeps the projection ring glued to the ground under the ship,
## independent of cruise altitude, bob and presentation scale.
func _track_projection() -> void:
	if _proj_ring == null:
		return
	_proj_ring.global_position = Vector3(global_position.x, 0.1, global_position.z)


func _active_visual() -> Node3D:
	return _visual_lod1 if lod_level == 1 else _visual_lod0


func camera_distance() -> float:
	if _camera == null or not is_instance_valid(_camera):
		var rig := get_tree().get_first_node_in_group("rts_camera") as Node3D
		if rig != null:
			_camera = rig.get_node_or_null("Camera3D") as Camera3D
	if _camera == null:
		return 0.0
	return _camera.global_position.distance_to(global_position)


func set_lod(level: int) -> void:
	lod_level = 1 if level == 1 else 0
	lod_locked = true
	_apply_lod()


func unlock_lod() -> void:
	lod_locked = false
	_lod_check_left = 0.0


func _update_lod_throttled(delta: float) -> void:
	_lod_check_left -= delta
	if _lod_check_left > 0.0:
		return
	_lod_check_left = LOD_CHECK_INTERVAL
	_update_lod()


func _update_lod() -> void:
	if lod_locked:
		return
	var d := camera_distance()
	if _camera == null:
		return
	if lod_level == 0 and d >= LOD_FAR_MIN:
		lod_level = 1
		_apply_lod()
	elif lod_level == 1 and d <= LOD_NEAR_MAX:
		lod_level = 0
		_apply_lod()


func _apply_lod() -> void:
	if _visual_lod0 != null:
		_visual_lod0.visible = lod_level == 0
	if _visual_lod1 != null:
		_visual_lod1.visible = lod_level == 1
