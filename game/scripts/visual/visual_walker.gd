class_name VisualWalker
extends CharacterBody3D
## Production Ironstride walker wrapper (Phase 2.5D.1). Same integration
## pattern as VisualTitan / VisualAirship, sized for a 4.5 m line unit:
## LOD0/LOD1 ownership + distance switch, separated lightweight collision,
## faction-tinted selection ring + HP bar, faction plate overlays (the shared
## GLB stays Gearforge neutral), anchor access for future FX / recoil /
## walk work. Phase 2.6 added gameplay: real HP + take_damage (VisualTitan
## pattern), RTSUnit-compatible order API (order_move / order_attack /
## order_attack_move), staggered auto-engage and muzzle/tracer FX. Numbers
## come from gf_walker.tres (data-driven; no hardcoded balance here).

signal selected_changed(walker: VisualWalker)
signal died(walker: VisualWalker)
signal damaged(walker: VisualWalker)
## Emitted each time the cannon fires (FX / audio hook).
signal fired(walker: VisualWalker, target_pos: Vector3)

const WalkerLOD0: PackedScene = preload("res://assets/models/gearforge_walker.glb")
const WalkerLOD1: PackedScene = preload("res://assets/models/gearforge_walker_lod1.glb")
const WalkerDef: UnitDefinition = preload("res://resources/units/gf_walker.tres")

## LOD switch: LOD0 below LOD_NEAR_MAX, LOD1 above LOD_FAR_MIN.
## Closer band than the Titan (4.5 m hull reads near only).
const LOD_NEAR_MAX: float = 22.0
const LOD_FAR_MIN: float = 26.0
const LOD_CHECK_INTERVAL: float = 0.25
## Selection ring radius: encircles the 3.54 m footprint with margin,
## well below Titan-scale markers.
const RING_RADIUS: float = 2.2
const SCAN_INTERVAL: float = 0.25
const STUCK_TIMEOUT: float = 2.0
const ARRIVE_DIST: float = 1.6
const MUZZLE_FALLBACK := Vector3(0, 3.8, 2.7)

var is_player: bool = true
var selected: bool = false
var hp: float = 700.0
var max_hp: float = 700.0
var move_speed: float = 3.6
var attack_damage: float = 34.0
var attack_range: float = 17.0
var attack_interval: float = 2.2
var sight_range: float = 26.0
## Active LOD level (0 = production close, 1 = RTS distance).
var lod_level: int = 0
## When true (tests/showcase/benchmarks), set_lod() holds and the distance
## auto-switch is skipped. Gameplay default is false (auto).
var lod_locked: bool = false
## Match maps set this true so front lines stay readable (RTSUnit parity).
var always_show_hp: bool = false
## When false, the walker never fires (showcase scenes). Gameplay maps
## leave it true.
var combat_enabled: bool = true
var guard_pos: Vector3 = Vector3.ZERO

var forced_target: Node3D = null
var attack_moving: bool = false
var attack_move_dest: Vector3 = Vector3.ZERO
var move_dest: Vector3 = Vector3.ZERO
var has_move_order: bool = false

var _visual_lod0: Node3D = null
var _visual_lod1: Node3D = null
var _lod_check_left: float = 0.0
var _camera: Camera3D = null
var _ring: MeshInstance3D = null
var _hp_bg: MeshInstance3D = null
var _hp_fg: MeshInstance3D = null
var _healthbar_anchor: Node3D = null
var _cooldown: float = 0.0
var _scan_left: float = 0.0
var _stuck_time: float = 0.0
var _last_order_dist: float = -1.0
var _slide_dir := Vector3.ZERO
var _slide_left: float = 0.0
var _muzzle: Node3D = null
var _fx_root: Node3D = null


func setup(player_flag: bool, def: UnitDefinition = null) -> void:
	is_player = player_flag
	var d := def if def != null else WalkerDef
	max_hp = d.max_hp
	move_speed = d.move_speed
	attack_damage = d.attack_damage
	attack_range = d.attack_range
	attack_interval = d.attack_interval_sec
	sight_range = d.sight_range
	hp = max_hp


func _ready() -> void:
	add_to_group("visual_walkers")
	# Scanned as an RTSUnit foe target (same group trick as VisualTitan);
	# walker stays OUT of rts_units so box-select casts never see it.
	add_to_group("rts_buildings")
	collision_layer = 2
	collision_mask = 3
	_visual_lod0 = WalkerLOD0.instantiate() as Node3D
	add_child(_visual_lod0)
	_visual_lod1 = WalkerLOD1.instantiate() as Node3D
	_visual_lod1.visible = false
	add_child(_visual_lod1)
	for visual in [_visual_lod0, _visual_lod1]:
		for c in _find_meshes(visual):
			(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_build_collision()
	_build_faction_plates()
	_build_code_anchors()
	_build_markers()
	_resolve_muzzle()
	_fx_root = get_parent() as Node3D
	guard_pos = global_position
	_scan_left = randf() * SCAN_INTERVAL
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
	selected_changed.emit(self)


## Duck-typed damage API (RTSUnit/RTSBuilding/VisualTitan parity). The
## attacker is accepted but not required: walkers do not track kills yet.
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
	if _fx_root != null:
		VisualFX.explosion(_fx_root, global_position, true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation:z", 0.42, 1.2)
	tw.tween_property(self, "position:y", position.y - 1.8, 1.4)
	tw.chain().tween_callback(queue_free)


## --- Order API (RTSUnit-compatible names; OrderManager duck-types) ---

func order_move(dest: Vector3) -> void:
	if not is_alive():
		return
	forced_target = null
	attack_moving = false
	move_dest = dest
	has_move_order = true
	_stuck_time = 0.0
	_last_order_dist = -1.0


func order_attack(target: Node3D) -> void:
	if not is_alive() or not _is_foe_target(target):
		return
	attack_moving = false
	has_move_order = false
	forced_target = target


func order_attack_move(dest: Vector3) -> void:
	if not is_alive():
		return
	forced_target = null
	has_move_order = false
	attack_moving = true
	attack_move_dest = dest
	_stuck_time = 0.0
	_last_order_dist = -1.0


## Same duck-typed foe check as RTSUnit._is_foe_target.
func _is_foe_target(n: Node) -> bool:
	if n == null or n == self:
		return false
	if not is_instance_valid(n):
		return false
	if not n.has_method("is_alive") or not n.has_method("take_damage"):
		return false
	if not bool(n.call("is_alive")):
		return false
	if not ("is_player" in n):
		return false
	return bool(n.get("is_player")) != is_player


## Two boxes cover torso and legs; the thin cannon barrel and foot tips
## are excluded on purpose so the hitbox never overshoots the visual.
## Positions/sizes are Godot space (x right, y up, z = former Blender -Y).
func _build_collision() -> void:
	_add_box_shape(Vector3(2.2, 1.2, 2.0), Vector3(0, 3.0, 0.0), "torso")
	_add_box_shape(Vector3(3.5, 2.4, 2.3), Vector3(0, 1.2, 0.15), "legs")


func _add_box_shape(size: Vector3, pos: Vector3, shape_name: String) -> void:
	var col := CollisionShape3D.new()
	col.name = "Collision_" + shape_name
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	add_child(col)


## Faction plates ride on the outer shoulder faces. Overlay boxes only:
## the shared GLB and palette stay neutral for both factions.
func _build_faction_plates() -> void:
	var color := Color(0.14, 0.64, 1.0, 1.0) if is_player else Color(1.0, 0.22, 0.12, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.15
	mat.roughness = 0.38
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	for sx in [-1.0, 1.0]:
		var plate := MeshInstance3D.new()
		plate.name = "FactionPlateL" if sx < 0.0 else "FactionPlateR"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, 0.55, 0.9)
		plate.mesh = mesh
		plate.material_override = mat
		plate.position = Vector3(sx * 1.34, 3.18, 0.1)
		plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plate)


func _build_code_anchors() -> void:
	_healthbar_anchor = Node3D.new()
	_healthbar_anchor.name = "healthbar_anchor"
	_healthbar_anchor.position = Vector3(0, 5.2, 0)
	add_child(_healthbar_anchor)


func _build_markers() -> void:
	var tint := Color(0.14, 0.64, 1.0, 1.0) if is_player else Color(1.0, 0.22, 0.12, 1.0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = tint
	ring_mat.emission_enabled = true
	ring_mat.emission = tint
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring = MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = RING_RADIUS - 0.16
	ring_mesh.outer_radius = RING_RADIUS
	ring_mesh.rings = 40
	ring_mesh.ring_segments = 6
	_ring.mesh = ring_mesh
	_ring.material_override = ring_mat
	_ring.position = Vector3(0, 0.1, 0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
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
	bg_mesh.size = Vector2(4.0, 0.4)
	_hp_bg.mesh = bg_mesh
	_hp_bg.material_override = hpbg_mat
	_hp_bg.position = Vector3(0, 5.2, 0)
	_hp_bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_bg)
	_hp_fg = MeshInstance3D.new()
	var fg_mesh := PlaneMesh.new()
	fg_mesh.size = Vector2(4.0, 0.4)
	_hp_fg.mesh = fg_mesh
	_hp_fg.material_override = hpf_mat
	_hp_fg.position = Vector3(0, 5.2, 0.02)
	_hp_fg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_fg)


func _refresh_visuals() -> void:
	var show := selected and is_alive()
	if _ring != null:
		_ring.visible = show
	var show_hp := is_alive() and (always_show_hp or selected or hp < max_hp)
	if _hp_bg != null:
		_hp_bg.visible = show_hp
	if _hp_fg != null:
		_hp_fg.visible = show_hp
		if show_hp:
			var frac := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
			var half_w := 2.0
			if _hp_fg.mesh is PlaneMesh:
				half_w = (_hp_fg.mesh as PlaneMesh).size.x * 0.5
			_hp_fg.scale = Vector3(maxf(0.001, frac), 1.0, 1.0)
			_hp_fg.position = Vector3(-half_w * (1.0 - frac), _hp_bg.position.y, _hp_fg.position.z)


## Anchor access for future FX / recoil / walk work. GLB anchors
## (muzzle, center, reactor, exhausts, secondary, pistons) and pivots
## (leg_l/r, turret, hull) resolve inside the active LOD visual.
func find_anchor(anchor_name: String) -> Node3D:
	var visual := _active_visual()
	if visual != null:
		var node := visual.find_child(anchor_name, true, true) as Node3D
		if node != null:
			return node
	return null


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


func _process(delta: float) -> void:
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
	_resolve_muzzle()


func _resolve_muzzle() -> void:
	_muzzle = find_anchor("muzzle")


## --- Combat + movement (Phase 2.6) ---
## Straight-line steering (no navmesh dependency): path is trivial on the
## flat prototype field; separation comes from move_and_slide collision.
## Scans are staggered so many walkers never scan on the same frame.

func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if not combat_enabled:
		return
	_scan_left -= delta
	if forced_target != null and not _is_foe_target(forced_target):
		forced_target = null
	var enemy: Node3D = forced_target
	if enemy == null and _scan_left <= 0.0:
		_scan_left = SCAN_INTERVAL
		enemy = _nearest_enemy(sight_range)
	if forced_target != null:
		_engage(forced_target, delta)
	elif attack_moving:
		if enemy != null:
			_engage(enemy, delta)
		else:
			_steer_toward(attack_move_dest, delta)
			if _order_arrived(attack_move_dest, delta):
				attack_moving = false
	elif has_move_order:
		_steer_toward(move_dest, delta)
		if _order_arrived(move_dest, delta):
			has_move_order = false
	elif enemy != null:
		_engage(enemy, delta)
	else:
		velocity = Vector3.ZERO
		move_and_slide()


func _engage(enemy: Node3D, delta: float) -> void:
	var to: Vector3 = enemy.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist <= attack_range:
		velocity = Vector3.ZERO
		move_and_slide()
		_face(to, delta)
		if _cooldown <= 0.0:
			_cooldown = attack_interval
			_fire_at(enemy)
	else:
		_steer_toward(enemy.global_position, delta)


func _fire_at(enemy: Node3D) -> void:
	var from_pos := global_position + MUZZLE_FALLBACK
	if _muzzle != null and is_instance_valid(_muzzle):
		from_pos = _muzzle.global_position
	var aim: Vector3 = enemy.global_position
	if _fx_root != null:
		VisualFX.muzzle(_fx_root, from_pos, is_player, true)
		VisualFX.tracer(_fx_root, from_pos, aim, is_player)
	fired.emit(self, aim)
	enemy.take_damage(attack_damage, self)


func _steer_toward(dest: Vector3, delta: float) -> void:
	var to: Vector3 = dest - global_position
	to.y = 0.0
	if to.length() < 0.1:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var dir := to.normalized()
	# Obstacle slide (Phase 2.7): straight steering pins the walker on
	# circular blockers (city/HQ/rock collisions). Blending a tangent that
	# follows the contact normal lets it walk around instead of stalling —
	# the same "slide along the wall" players expect, without full navmesh.
	var blended := dir
	if _slide_left > 0.0:
		_slide_left -= delta
		blended = (dir + _slide_dir * 0.9).normalized()
	elif is_on_wall():
		var n := get_wall_normal()
		n.y = 0.0
		if n.length() > 0.1:
			var tangent := Vector3(-n.z, 0.0, n.x).normalized()
			if tangent.dot(dir) < 0.0:
				tangent = -tangent
			_slide_dir = tangent
			_slide_left = 0.4
			blended = (dir + tangent * 0.9).normalized()
	velocity = Vector3(blended.x * move_speed, 0.0, blended.z * move_speed)
	move_and_slide()
	_face(blended, delta)


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	var target_yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 4.0))


## Arrival with the same stuck fallback as RTSUnit: if progress stalls for
## ~2s (blocked slot), accept the current position.
func _order_arrived(dest: Vector3, delta: float) -> bool:
	var d: float = Vector2(global_position.x - dest.x, global_position.z - dest.z).length()
	if d <= ARRIVE_DIST:
		_stuck_time = 0.0
		_last_order_dist = -1.0
		return true
	if _last_order_dist < 0.0:
		_last_order_dist = d
		_stuck_time = 0.0
		return false
	if d < _last_order_dist - 0.3:
		_last_order_dist = d
		_stuck_time = 0.0
		return false
	_stuck_time += delta
	if _stuck_time >= STUCK_TIMEOUT:
		_stuck_time = 0.0
		_last_order_dist = -1.0
		return true
	return false


## Nearest live foe among rts_units + rts_buildings (RTSUnit parity; the
## walker joins rts_buildings itself so infantry can target it back).
func _nearest_enemy(max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	var others: Array = get_tree().get_nodes_in_group("rts_units")
	others.append_array(get_tree().get_nodes_in_group("rts_buildings"))
	for o in others:
		if o == self:
			continue
		var n := o as Node3D
		if n == null:
			continue
		if not _is_foe_target(n):
			continue
		var d: float = Vector2(global_position.x - n.global_position.x, global_position.z - n.global_position.z).length()
		if d < best_d:
			best_d = d
			best = n
	return best
