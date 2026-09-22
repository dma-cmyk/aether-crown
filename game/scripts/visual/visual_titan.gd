class_name VisualTitan
extends CharacterBody3D
## Visual Slice Gearforge titan (Phase 1.75). Lightweight on purpose: NO
## complex AI. Slow patrol between two points (or hold), cannon fires every
## few seconds at the nearest visible enemy with muzzle FX + TitanShell
## tracer + AoE explosion. Damageable/selectable so RTS combat reads well.
## GLB visual is instanced from res://assets/models/gearforge_titan.glb.

signal died(titan: VisualTitan)
signal damaged(titan: VisualTitan)

const TitanSceneGLB: PackedScene = preload("res://assets/models/gearforge_titan.glb")
const TitanSceneLOD1: PackedScene = preload("res://assets/models/gearforge_titan_lod1.glb")

const MAX_HP: float = 1500.0
const CANNON_INTERVAL: float = 3.2
const CANNON_RANGE: float = 30.0
const CANNON_DAMAGE: float = 90.0
const SPLASH: float = 4.0
const PATROL_SPEED: float = 1.6
## Phase 2.5B.1 LOD switch: LOD0 below LOD_NEAR_MAX, LOD1 above
## LOD_FAR_MIN. 2m hysteresis avoids pop flicker at the boundary.
const LOD_NEAR_MAX: float = 32.0
const LOD_FAR_MIN: float = 34.0
const LOD_CHECK_INTERVAL: float = 0.25

var is_player: bool = true
var hp: float = MAX_HP
var max_hp: float = MAX_HP
var selected: bool = false
var patrol_a: Vector3 = Vector3.ZERO
var patrol_b: Vector3 = Vector3.ZERO
var hold_position: bool = false

var _cooldown: float = 2.0
var _to_b: bool = true
var _fx_root: Node3D = null
var _muzzle: Node3D = null
var _ring: MeshInstance3D = null
var _hp_bg: MeshInstance3D = null
var _hp_fg: MeshInstance3D = null
## Active LOD level (0 = production close/mid, 1 = far/strategic).
var lod_level: int = 0
## When true (tests/showcase/benchmarks), set_lod() holds and the distance
## auto-switch is skipped. Gameplay default is false (auto).
var lod_locked: bool = false
var _visual_lod0: Node3D = null
var _visual_lod1: Node3D = null
var _lod_check_left: float = 0.0
var _camera: Camera3D = null


func setup(player_flag: bool, from_pos: Vector3, to_pos: Vector3) -> void:
	is_player = player_flag
	patrol_a = from_pos
	patrol_b = to_pos
	hp = MAX_HP
	max_hp = MAX_HP


func _ready() -> void:
	add_to_group("visual_titans")
	add_to_group("rts_buildings")
	collision_layer = 2
	collision_mask = 3
	_visual_lod0 = TitanSceneGLB.instantiate() as Node3D
	add_child(_visual_lod0)
	_visual_lod1 = TitanSceneLOD1.instantiate() as Node3D
	_visual_lod1.visible = false
	add_child(_visual_lod1)
	for visual in [_visual_lod0, _visual_lod1]:
		for c in _find_meshes(visual):
			(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_resolve_muzzle()
	_fx_root = get_parent() as Node3D
	_build_markers()
	_refresh_visuals()


func _find_meshes(n: Node) -> Array:
	var out: Array = []
	if n is GeometryInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_meshes(c))
	return out


func is_alive() -> bool:
	return hp > 0.0


func set_selected(value: bool) -> void:
	selected = value
	_refresh_visuals()


func take_damage(amount: float, _attacker: Node) -> void:
	if not is_alive():
		return
	hp = maxf(0.0, hp - amount)
	damaged.emit(self)
	_refresh_visuals()
	if hp <= 0.0:
		_die()


func _die() -> void:
	died.emit(self)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if _ring != null:
		_ring.visible = false
	if _hp_bg != null:
		_hp_bg.visible = false
	if _hp_fg != null:
		_hp_fg.visible = false
	var fx := _resolve_fx()
	if fx != null:
		VisualFX.explosion(fx, global_position, true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation:z", 0.35, 1.4)
	tw.tween_property(self, "position:y", position.y - 2.5, 1.6)
	tw.chain().tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	_cooldown -= delta
	if not hold_position:
		_patrol(delta)
	if _cooldown <= 0.0:
		_cooldown = CANNON_INTERVAL
		_try_fire()


## Distance LOD, throttled: camera lookup is cached, distance check runs
## 4x/sec. Hysteresis band [LOD_NEAR_MAX, LOD_FAR_MIN] prevents popping
## when the camera rests near the threshold.
func _process(delta: float) -> void:
	_lod_check_left -= delta
	if _lod_check_left > 0.0:
		return
	_lod_check_left = LOD_CHECK_INTERVAL
	_update_lod()


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
	_resolve_muzzle()


func _resolve_muzzle() -> void:
	_muzzle = null
	var visual := _active_visual()
	if visual != null:
		_muzzle = visual.find_child("muzzle", true, true) as Node3D
	if _muzzle == null:
		_muzzle = self


func _patrol(delta: float) -> void:
	var goal := patrol_b if _to_b else patrol_a
	var to: Vector3 = goal - global_position
	to.y = 0.0
	if to.length() < 1.5:
		_to_b = not _to_b
		return
	var dir := to.normalized()
	velocity = Vector3(dir.x * PATROL_SPEED, -4.0, dir.z * PATROL_SPEED)
	move_and_slide()
	var target_yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 2.0))


func _try_fire() -> void:
	var foe := _nearest_foe(CANNON_RANGE)
	if foe == null:
		return
	var aim: Vector3 = (foe as Node3D).global_position
	var face: Vector3 = aim - global_position
	face.y = 0.0
	if face.length() > 0.1:
		rotation.y = atan2(face.x, face.z)
	var fx := _resolve_fx()
	var from_pos: Vector3 = (_muzzle as Node3D).global_position if _muzzle != null else global_position + Vector3(0, 5.6, 0)
	if fx != null:
		VisualFX.muzzle(fx, from_pos, is_player, true)
		TitanShell.fire(fx, from_pos, aim, is_player, CANNON_DAMAGE, SPLASH)


func _nearest_foe(max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	var tree := get_tree()
	if tree == null:
		return null
	var candidates: Array[Node] = []
	candidates.append_array(tree.get_nodes_in_group("rts_units"))
	candidates.append_array(tree.get_nodes_in_group("visual_titans"))
	for o in candidates:
		if o == self:
			continue
		var n := o as Node3D
		if n == null or not is_instance_valid(n):
			continue
		if not n.has_method("is_alive"):
			continue
		if not bool(n.call("is_alive")):
			continue
		if not ("is_player" in n):
			continue
		if bool(n.get("is_player")) == is_player:
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


func _build_markers() -> void:
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.9, 0.2, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.85, 0.2, 1.0)
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring = MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 3.4
	ring_mesh.bottom_radius = 3.4
	ring_mesh.height = 0.08
	_ring.mesh = ring_mesh
	_ring.material_override = ring_mat
	_ring.position = Vector3(0, 0.12, 0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	var hpbg_mat := StandardMaterial3D.new()
	hpbg_mat.albedo_color = Color(0.08, 0.08, 0.08, 0.9)
	hpbg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hpbg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var hpf_mat := StandardMaterial3D.new()
	hpf_mat.albedo_color = Color(0.35, 0.75, 1.0, 1.0)
	hpf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hpf_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bg = MeshInstance3D.new()
	var bg_mesh := PlaneMesh.new()
	bg_mesh.size = Vector2(5.0, 0.45)
	_hp_bg.mesh = bg_mesh
	_hp_bg.material_override = hpbg_mat
	_hp_bg.position = Vector3(0, 11.0, 0)
	_hp_bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_bg)
	_hp_fg = MeshInstance3D.new()
	var fg_mesh := PlaneMesh.new()
	fg_mesh.size = Vector2(5.0, 0.45)
	_hp_fg.mesh = fg_mesh
	_hp_fg.material_override = hpf_mat
	_hp_fg.position = Vector3(0, 11.0, 0.02)
	_hp_fg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_fg)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	# Phase 2.5B.1 production footprint: radius 3.0 keeps infantry
	# (body r0.35-0.5) outside the sole outer edge (+/-2.39m) while staying
	# deliberately smaller than the visual half-width (3.88m) so corridors
	# are not over-blocked. Height 9.0 covers hull+sensor head; the thin
	# twin stacks above are excluded on purpose. Navmesh is untouched
	# (titan patrols, so no static obstacle); chasing units stop at
	# attack_range 13 which is well outside this radius.
	shape.radius = 3.0
	shape.height = 9.0
	col.shape = shape
	col.position = Vector3(0, 4.5, 0)
	add_child(col)


func _refresh_visuals() -> void:
	if _ring != null:
		_ring.visible = selected and is_alive()
	var show_hp := is_alive() and (selected or hp < max_hp)
	if _hp_bg != null:
		_hp_bg.visible = show_hp
	if _hp_fg != null:
		_hp_fg.visible = show_hp
		if show_hp:
			var frac := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
			_hp_fg.scale = Vector3(maxf(0.001, frac), 1.0, 1.0)
			_hp_fg.position = Vector3(-2.5 * (1.0 - frac), 11.0, 0.02)
