extends Node3D
## Phase 1 skirmish map: terrain+nav via MapNav, obstacles, two bases,
## 25v25 default spawns, HUD wiring, PERF log, CLI args for load tests.
## CLI: --units-per-side=N --auto-battle

const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const PlayerDef: UnitDefinition = preload("res://resources/units/gearforge_infantry.tres")
const EnemyDef: UnitDefinition = preload("res://resources/units/ember_raider.tres")

const ROCKS: Array = [
	[Vector2(-15, -5), 2.2], [Vector2(-5, 15), 1.8], [Vector2(10, -12), 2.4],
	[Vector2(20, 8), 1.6], [Vector2(-25, 20), 2.0], [Vector2(25, -25), 2.2],
	[Vector2(0, -30), 1.7], [Vector2(-10, 30), 2.1], [Vector2(30, 25), 1.8],
	[Vector2(-30, -15), 1.9],
]
const TREES: Array = [
	Vector2(-20, 5), Vector2(-8, -18), Vector2(5, 22), Vector2(15, -2),
	Vector2(28, -8), Vector2(-28, 8), Vector2(12, 32), Vector2(-12, -32),
	Vector2(35, 10), Vector2(-35, -5), Vector2(0, 8), Vector2(8, 0),
	Vector2(-3, -8), Vector2(22, 30),
]

var kills_by_player: int = 0
var kills_by_enemy: int = 0
var _elapsed: float = 0.0
var _perf_left: float = 5.0
var _auto_battle: bool = false

@onready var map_nav: MapNav = $MapNav
@onready var obstacles_root: Node3D = $ObstaclesRoot
@onready var bases_root: Node3D = $BasesRoot
@onready var units_root: Node3D = $UnitsRoot
@onready var orders: OrderManager = $OrderManager
@onready var selection: SelectionManager = $SelectionManager


func _ready() -> void:
	add_to_group("phase1_map")
	var args := OS.get_cmdline_user_args()
	var per_side := 25
	for a in args:
		if a.begins_with("--units-per-side="):
			per_side = clampi(int(a.get_slice("=", 1)), 1, 100)
		if a == "--auto-battle":
			_auto_battle = true
	_build_static()
	map_nav.build($GroundRoot)
	spawn_side(true, per_side)
	spawn_side(false, per_side)
	print("PHASE1_READY players=", per_side, " enemies=", per_side, " auto_battle=", _auto_battle)
	if _auto_battle:
		_order_all_attack_move()


func _process(delta: float) -> void:
	_elapsed += delta
	_perf_left -= delta
	if _perf_left <= 0.0:
		_perf_left = 5.0
		_log_perf()


func _log_perf() -> void:
	var p := 0
	var e := 0
	var states := [0, 0, 0, 0, 0]
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u == null or not u.is_alive():
			continue
		if u.is_player:
			p += 1
		else:
			e += 1
		if u.state >= 0 and u.state < 5:
			states[u.state] += 1
	print("PERF t=%.1f fps=%d alive_p=%d alive_e=%d kills_p=%d kills_e=%d idle=%d move=%d chase=%d atk=%d" % [
		_elapsed, Engine.get_frames_per_second(), p, e,
		kills_by_player, kills_by_enemy,
		states[0], states[1], states[2], states[3],
	])


# ---------------------------------------------------------------- static map

func _build_static() -> void:
	for r in ROCKS:
		var pos := r[0] as Vector2
		_place_rock(Vector3(pos.x, 0, pos.y), float(r[1]))
	for t in TREES:
		_place_tree(Vector3(t.x, 0, t.y))
	_build_base(map_nav.player_base, true)
	_build_base(map_nav.enemy_base, false)


func _ground_y(x: float, z: float) -> float:
	return map_nav.get_ground_height(x, z)


func _place_rock(pos: Vector3, radius: float) -> void:
	pos.y = _ground_y(pos.x, pos.z)
	map_nav.register_obstacle_circle(pos, radius)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 4
	mesh.radius = radius
	mesh.height = radius * 1.4
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0, radius * 0.35, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.44, 0.42, 1.0)
	mat.roughness = 0.95
	mi.material_override = mat
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius * 0.9
	col.shape = shape
	col.position = mi.position
	body.add_child(mi)
	body.add_child(col)
	obstacles_root.add_child(body)


func _place_tree(pos: Vector3) -> void:
	pos.y = _ground_y(pos.x, pos.z)
	map_nav.register_obstacle_circle(pos, 0.6)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.22
	trunk_mesh.height = 1.4
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0, 0.7, 0)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.35, 0.24, 0.15, 1.0)
	bark.roughness = 0.95
	trunk.material_override = bark
	var top := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 1.3
	cone.height = 2.4
	top.mesh = cone
	top.position = Vector3(0, 2.4, 0)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.16, 0.38, 0.18, 1.0)
	leaf.roughness = 0.9
	top.material_override = leaf
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 3.0
	col.shape = shape
	col.position = Vector3(0, 1.5, 0)
	body.add_child(trunk)
	body.add_child(top)
	body.add_child(col)
	obstacles_root.add_child(body)


func _build_base(center: Vector3, is_player: bool) -> void:
	var tint := Color(0.20, 0.45, 0.95, 1.0) if is_player else Color(0.92, 0.26, 0.20, 1.0)
	var pad := MeshInstance3D.new()
	var pad_mesh := BoxMesh.new()
	pad_mesh.size = Vector3(18, 0.12, 18)
	pad.mesh = pad_mesh
	pad.position = Vector3(center.x, 0.06, center.z)
	var pad_mat := StandardMaterial3D.new()
	pad_mat.albedo_color = Color(tint.r * 0.4, tint.g * 0.4, tint.b * 0.4, 1.0)
	pad_mat.roughness = 0.9
	pad.material_override = pad_mat
	bases_root.add_child(pad)
	for i in range(2):
		var off := Vector3(-5.0 + float(i) * 10.0, 0, -5.0)
		var bpos := center + off
		var size := Vector3(5, 3, 4)
		map_nav.register_obstacle_rect(bpos, Vector2(size.x, size.z))
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector3(bpos.x, 1.5, bpos.z)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.roughness = 0.7
		mi.material_override = mat
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(mi)
		body.add_child(col)
		bases_root.add_child(body)


# ---------------------------------------------------------------- units

func spawn_side(is_player: bool, count: int) -> void:
	var base := map_nav.player_base if is_player else map_nav.enemy_base
	var foe := map_nav.enemy_base if is_player else map_nav.player_base
	var cols := int(ceil(sqrt(float(maxi(count, 1)))))
	for i in range(count):
		var cx := float(i % cols) * 2.2 - float(cols) * 1.1
		var cz := float(i / cols) * 2.2
		var pos := map_nav.clamp_inside(base + Vector3(cx, 0, 4.0 + cz))
		_spawn_unit(is_player, pos, foe)


func _spawn_unit(is_player: bool, pos: Vector3, look_at: Vector3) -> RTSUnit:
	var u := InfantryScene.instantiate() as RTSUnit
	u.setup(PlayerDef if is_player else EnemyDef, is_player)
	u.position = pos
	var d: Vector3 = look_at - pos
	d.y = 0.0
	if d.length() > 0.01:
		u.rotation.y = atan2(d.x, d.z) + PI
	units_root.add_child(u)
	u.guard_pos = u.global_position
	u.died.connect(_on_unit_died)
	return u


func _on_unit_died(unit: RTSUnit) -> void:
	if unit.is_player:
		kills_by_enemy += 1
	else:
		kills_by_player += 1
	if selection != null and selection.selected.has(unit):
		selection.selected.erase(unit)
		unit.set_selected(false)


func _order_all_attack_move() -> void:
	var players: Array = []
	var enemies: Array = []
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u == null or not u.is_alive():
			continue
		if u.is_player:
			players.append(u)
		else:
			enemies.append(u)
	orders.issue_attack_move(players, map_nav.enemy_base)
	orders.issue_attack_move(enemies, map_nav.player_base)


func add_skirmish_units(count: int) -> void:
	for i in range(count):
		var a := randf() * TAU
		var r := 6.0 + randf() * 6.0
		_spawn_unit(true, map_nav.clamp_inside(map_nav.player_base + Vector3(cos(a) * r, 0, sin(a) * r)), map_nav.enemy_base)
		_spawn_unit(false, map_nav.clamp_inside(map_nav.enemy_base + Vector3(cos(a) * r, 0, sin(a) * r)), map_nav.player_base)
	print("SKIRMISH_ADD n=", count)


func set_skirmish_units(per_side: int) -> void:
	_clear_units()
	spawn_side(true, per_side)
	spawn_side(false, per_side)
	print("SKIRMISH_SET n=", per_side)


func reset_skirmish() -> void:
	_clear_units()
	kills_by_player = 0
	kills_by_enemy = 0
	spawn_side(true, 25)
	spawn_side(false, 25)
	print("SKIRMISH_RESET")


func _clear_units() -> void:
	if selection != null:
		selection.clear_selection()
	for o in get_tree().get_nodes_in_group("rts_units"):
		(o as Node).queue_free()
