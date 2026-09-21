class_name RTSUnit
extends CharacterBody3D
## Single RTS unit. Data comes from UnitDefinition; visuals tint by faction.
## States: IDLE / MOVING / CHASING / ATTACKING / DEAD.
## Path is computed once per order (NavigationAgent3D); scans are staggered
## so 100+ units never all repath/scan on the same frame.

signal died(unit: RTSUnit)
signal damaged(unit: RTSUnit)
## Emitted each time this unit fires (Phase 1.5 FX hook; no Phase 1 listener).
signal fired(attacker: RTSUnit, target_pos: Vector3)

enum State { IDLE, MOVING, CHASING, ATTACKING, DEAD }

const SCAN_INTERVAL: float = 0.25
const CHASE_REPATH_INTERVAL: float = 0.5
const SEPARATION_RADIUS: float = 1.8
const SEPARATION_FORCE: float = 7.0
const ENEMY_LEASH: float = 34.0
const STICK_GRAVITY: float = -4.0

@export var definition: UnitDefinition

var faction_id: StringName = &"gearforge"
var is_player: bool = true
var max_hp: float = 100.0
var hp: float = 100.0
var move_speed: float = 6.0
var attack_damage: float = 12.0
var attack_range: float = 13.0
var attack_interval: float = 1.0
var sight_range: float = 24.0

var state: int = State.IDLE
var selected: bool = false
## Phase 1.5 match maps set this true so front lines stay readable.
## Phase 1 default (false) keeps the original show-on-damage/select behavior.
var always_show_hp: bool = false
var guard_pos: Vector3 = Vector3.ZERO
## Damageable target: an RTSUnit or an RTSBuilding (duck-typed via
## is_alive/take_damage/is_player). Phase 1 maps only contain units.
var forced_target: Node3D = null
var attack_moving: bool = false
var attack_move_dest: Vector3 = Vector3.ZERO
var move_dest: Vector3 = Vector3.ZERO
var has_move_order: bool = false
var kills: int = 0
## True once the unit has dealt or taken damage. Only bloodied idle units
## are re-pointed by the map battle pulse, so fresh reserves are never stolen.
var bloodied: bool = false

var _cooldown: float = 0.0
var _scan_left: float = 0.0
var _repath_left: float = 0.0
var _stuck_time: float = 0.0
var _last_order_dist: float = -1.0
var _push_left: float = 0.0
var _soft_target: Node3D = null
var _soft_left: float = 0.0
var _sep: Vector3 = Vector3.ZERO
var _sep_tick: int = 0
var _map_nav: Node = null

static var _mats: Dictionary = {}

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var body_mesh: MeshInstance3D = $Body
@onready var head_mesh: MeshInstance3D = $Head
@onready var ring: MeshInstance3D = $SelectionRing
@onready var hp_bg: MeshInstance3D = $HpBg
@onready var hp_fg: MeshInstance3D = $HpFg


static func team_materials() -> Dictionary:
	if _mats.is_empty():
		var body_p := StandardMaterial3D.new()
		body_p.albedo_color = Color(0.20, 0.45, 0.95, 1.0)
		body_p.roughness = 0.75
		var head_p := StandardMaterial3D.new()
		head_p.albedo_color = Color(0.12, 0.28, 0.65, 1.0)
		head_p.roughness = 0.7
		var body_e := StandardMaterial3D.new()
		body_e.albedo_color = Color(0.92, 0.26, 0.20, 1.0)
		body_e.roughness = 0.75
		var head_e := StandardMaterial3D.new()
		head_e.albedo_color = Color(0.62, 0.14, 0.12, 1.0)
		head_e.roughness = 0.7
		var ring_m := StandardMaterial3D.new()
		ring_m.albedo_color = Color(1.0, 0.9, 0.2, 1.0)
		ring_m.emission_enabled = true
		ring_m.emission = Color(1.0, 0.85, 0.2, 1.0)
		ring_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var hpbg := StandardMaterial3D.new()
		hpbg.albedo_color = Color(0.08, 0.08, 0.08, 0.9)
		hpbg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hpbg.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		var hpf := StandardMaterial3D.new()
		hpf.albedo_color = Color(0.25, 0.9, 0.3, 1.0)
		hpf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hpf.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_mats = {
			"body_p": body_p, "head_p": head_p,
			"body_e": body_e, "head_e": head_e,
			"ring": ring_m, "hpbg": hpbg, "hpf": hpf,
		}
	return _mats


## Called by the spawner right after instantiate(), before add_child().
func setup(def: UnitDefinition, player_flag: bool) -> void:
	if def != null:
		definition = def
		faction_id = def.faction_id
		max_hp = def.max_hp
		move_speed = def.move_speed
		attack_damage = def.attack_damage
		attack_range = def.attack_range
		attack_interval = def.attack_interval_sec
		sight_range = def.sight_range
	is_player = player_flag
	hp = max_hp


func _ready() -> void:
	add_to_group("rts_units")
	_scan_left = randf() * SCAN_INTERVAL
	_sep_tick = int(randf() * 3.0)
	_map_nav = get_tree().get_first_node_in_group("map_nav")
	var m := team_materials()
	if is_player:
		body_mesh.material_override = m["body_p"]
		head_mesh.material_override = m["head_p"]
	else:
		body_mesh.material_override = m["body_e"]
		head_mesh.material_override = m["head_e"]
	ring.material_override = m["ring"]
	hp_bg.material_override = m["hpbg"]
	hp_fg.material_override = m["hpf"]
	guard_pos = global_position
	nav.max_speed = move_speed
	_refresh_visuals()


func is_alive() -> bool:
	return state != State.DEAD


func set_selected(value: bool) -> void:
	selected = value
	_refresh_visuals()


func order_move(dest: Vector3) -> void:
	if not is_alive():
		return
	forced_target = null
	attack_moving = false
	move_dest = dest
	has_move_order = true
	state = State.MOVING
	_stuck_time = 0.0
	_last_order_dist = -1.0
	nav.target_position = dest


func order_attack(target: Node3D) -> void:
	if not is_alive() or not _is_foe_target(target):
		return
	attack_moving = false
	has_move_order = false
	forced_target = target
	state = State.CHASING
	_repath_left = 0.0


## Shared damageable check: enemy unit or enemy building, alive.
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


func order_attack_move(dest: Vector3) -> void:
	if not is_alive():
		return
	forced_target = null
	has_move_order = false
	attack_moving = true
	attack_move_dest = dest
	state = State.MOVING
	_stuck_time = 0.0
	_last_order_dist = -1.0
	nav.target_position = dest


func take_damage(amount: float, attacker: RTSUnit) -> void:
	if not is_alive():
		return
	hp = maxf(0.0, hp - amount)
	bloodied = true
	if attacker != null and is_instance_valid(attacker):
		attacker.bloodied = true
	damaged.emit(self)
	_refresh_visuals()
	if hp <= 0.0:
		_die(attacker)


func _die(attacker: RTSUnit) -> void:
	state = State.DEAD
	if attacker != null and is_instance_valid(attacker):
		attacker.kills += 1
		attacker.on_confirmed_kill()
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	ring.visible = false
	hp_bg.visible = false
	hp_fg.visible = false
	died.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "rotation:x", -PI * 0.5, 0.35)
	tw.tween_interval(2.0)
	tw.tween_callback(queue_free)


## Event-driven reacquire after a kill: one wide scan (no per-frame cost).
## Result is a soft target, so normal scan/leash rules still apply.
func on_confirmed_kill() -> void:
	if not is_alive():
		return
	bloodied = true
	if forced_target != null or attack_moving or has_move_order:
		return
	var foe := _nearest_enemy(sight_range * 2.5)
	if foe != null:
		_soft_target = foe
		_soft_left = 3.0


func _valid_soft_target() -> Node3D:
	if _soft_target != null:
		if not is_instance_valid(_soft_target) or not _is_foe_target(_soft_target):
			_soft_target = null
			_soft_left = 0.0
			return null
		if _flat_dist(global_position, _soft_target.global_position) > sight_range * 2.5:
			_soft_target = null
			_soft_left = 0.0
			return null
		return _soft_target
	return null


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	_scan_left -= delta
	_repath_left -= delta
	_soft_left = maxf(0.0, _soft_left - delta)
	if forced_target != null and not _is_foe_target(forced_target):
		forced_target = null
		state = State.IDLE

	var enemy: Node3D = forced_target
	if enemy == null and _scan_left <= 0.0:
		_scan_left = SCAN_INTERVAL
		enemy = _nearest_enemy(sight_range)
	if enemy == null and _soft_left > 0.0:
		enemy = _valid_soft_target()

	if forced_target != null:
		_engage(forced_target, delta, true)
	elif attack_moving:
		if enemy != null:
			_engage(enemy, delta, true)
		else:
			_move_along_path(attack_move_dest, delta)
			if _order_arrived(attack_move_dest, delta):
				attack_moving = false
				state = State.IDLE
	elif has_move_order:
		_move_along_path(move_dest, delta)
		if _order_arrived(move_dest, delta):
			has_move_order = false
			state = State.IDLE
	elif enemy != null:
		_engage(enemy, delta, false)
	else:
		state = State.IDLE
		velocity = Vector3(0, STICK_GRAVITY, 0)
		move_and_slide()
		_snap_ground()


func _engage(enemy: Node3D, delta: float, aggressive: bool) -> void:
	var to: Vector3 = enemy.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if not is_player and not aggressive:
		if _flat_dist(global_position, guard_pos) > ENEMY_LEASH:
			forced_target = null
			order_move(guard_pos)
			return
	if dist <= attack_range:
		state = State.ATTACKING
		velocity = Vector3(0, STICK_GRAVITY, 0)
		move_and_slide()
		_face(to, delta)
		if _cooldown <= 0.0:
			_cooldown = attack_interval
			fired.emit(self, enemy.global_position)
			enemy.take_damage(attack_damage, self)
	else:
		state = State.CHASING
		if _repath_left <= 0.0:
			_repath_left = CHASE_REPATH_INTERVAL
			nav.target_position = enemy.global_position
		_move_along_path(enemy.global_position, delta)


func _move_along_path(_dest: Vector3, delta: float) -> void:
	state = State.MOVING if forced_target == null and not attack_moving else state
	_ensure_path(_dest, delta)
	if nav.is_navigation_finished():
		velocity = Vector3(0, STICK_GRAVITY, 0)
		move_and_slide()
		_snap_ground()
		return
	var next: Vector3 = nav.get_next_path_position()
	var dir: Vector3 = next - global_position
	dir.y = 0.0
	_sep_tick += 1
	if _sep_tick % 3 == 0:
		_sep = _compute_separation()
	if dir.length() < 0.05:
		dir = Vector3.ZERO
	else:
		dir = dir.normalized()
	var vel: Vector3 = (dir * move_speed) + _sep
	if vel.length() > move_speed:
		vel = vel.normalized() * move_speed
	velocity = Vector3(vel.x, STICK_GRAVITY, vel.z)
	move_and_slide()
	_snap_ground()
	if dir.length() > 0.01:
		_face(dir, delta)


func _compute_separation() -> Vector3:
	var push := Vector3.ZERO
	var others := get_tree().get_nodes_in_group("rts_units")
	for o in others:
		if o == self:
			continue
		var u := o as RTSUnit
		if u == null or not u.is_alive():
			continue
		var d: Vector3 = global_position - u.global_position
		d.y = 0.0
		var dist := d.length()
		if dist > 0.01 and dist < SEPARATION_RADIUS:
			push += d.normalized() * (1.0 - dist / SEPARATION_RADIUS)
	if push.length() > 1.0:
		push = push.normalized()
	return push * SEPARATION_FORCE


## Scans live foes: enemy units plus enemy buildings (HQs). Phase 1 maps
## have no buildings, so Phase 1 behavior is unchanged.
func _nearest_enemy(max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	var others := get_tree().get_nodes_in_group("rts_units")
	others.append_array(get_tree().get_nodes_in_group("rts_buildings"))
	for o in others:
		if o == self:
			continue
		var n := o as Node3D
		if n == null:
			continue
		if not _is_foe_target(n):
			continue
		var d := _flat_dist(global_position, n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best


## Path requests issued before the agent joins the navigation map are
## dropped by the server, so retry (throttled, not every frame) until the
## target becomes reachable. Stuck fallback still bounds unreachable goals.
func _ensure_path(dest: Vector3, delta: float) -> void:
	if nav.is_target_reachable():
		return
	_push_left -= delta
	if _push_left <= 0.0:
		_push_left = 0.5
		nav.target_position = dest


func _flat_dist(a: Vector3, b: Vector3) -> float:
	var dx := a.x - b.x
	var dz := a.z - b.z
	return sqrt(dx * dx + dz * dz)


## Arrival with stuck fallback: if the slot is inside an obstacle and the
## unit cannot get closer for ~2s, accept current position (prevents
## permanent MOVING state). Path is still computed only once per order.
func _order_arrived(dest: Vector3, delta: float) -> bool:
	var d := _flat_dist(global_position, dest)
	if d <= 1.0:
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
	if _stuck_time >= 2.0:
		_stuck_time = 0.0
		_last_order_dist = -1.0
		return true
	return false


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	var target_yaw := atan2(dir.x, dir.z) + PI
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 10.0))


func _snap_ground() -> void:
	if _map_nav != null and _map_nav.has_method("get_ground_height"):
		var p := global_position
		p.y = float(_map_nav.call("get_ground_height", p.x, p.z))
		global_position = p


func _refresh_visuals() -> void:
	ring.visible = selected and is_alive()
	var show_hp := is_alive() and (always_show_hp or selected or hp < max_hp)
	hp_bg.visible = show_hp
	hp_fg.visible = show_hp
	if show_hp:
		var frac := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
		var half_w := 0.45
		if hp_fg.mesh is PlaneMesh:
			half_w = (hp_fg.mesh as PlaneMesh).size.x * 0.5
		hp_fg.scale = Vector3(maxf(0.001, frac), 1.0, 1.0)
		hp_fg.position = Vector3(-half_w * (1.0 - frac), hp_bg.position.y, hp_fg.position.z)
