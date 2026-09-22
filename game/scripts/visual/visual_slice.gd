extends Node3D
## Phase 1.75 Visual Vertical Slice: Gearforge city block + infantry skirmish
## + titan + airship. Independent from phase1_5_match (gameplay baseline).
## Reuses Phase 1 systems untouched: camera, selection, orders, unit combat,
## MapNav ground/nav. Visual-only code lives here + VisualFX/VisualTitan/
## TitanShell/VisualAirship. No Phase 2 systems (no economy/research/etc).

const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const MarksmanScene: PackedScene = preload("res://scenes/units/marksman.tscn")
const HeavyScene: PackedScene = preload("res://scenes/units/heavy_guard.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")
const MarksmanDef: UnitDefinition = preload("res://resources/units/gf_marksman.tres")
const HeavyDef: UnitDefinition = preload("res://resources/units/gf_heavy_guard.tres")
const HallGLB: PackedScene = preload("res://assets/models/gearforge_civic_hall.glb")
const BoilerGLB: PackedScene = preload("res://assets/models/gearforge_boiler_house.glb")

const PLAYER_BASE := Vector3(-26, 0, -16)
const ENEMY_BASE := Vector3(18, 0, 14)
const CITY_CENTER := Vector3(-10, 0, -8)
const POP_MAX: int = 40

var material_demo: float = 120.0
var titan: VisualTitan = null
var airship: VisualAirship = null

var _elapsed: float = 0.0
var _perf_left: float = 5.0

@onready var map_nav: MapNav = $MapNav
@onready var ground_root: Node3D = $GroundRoot
@onready var city_root: Node3D = $CityRoot
@onready var units_root: Node3D = $UnitsRoot
@onready var fx_root: Node3D = $FxRoot
@onready var orders: OrderManager = $OrderManager
@onready var selection: SelectionManager = $SelectionManager


func _ready() -> void:
	add_to_group("visual_slice")
	fx_root.add_to_group("visual_fx_root")
	map_nav.player_base = PLAYER_BASE
	map_nav.enemy_base = ENEMY_BASE
	_register_city_obstacles()
	map_nav.build(ground_root)
	_build_city()
	_build_roads()
	_build_enemy_camp()
	_spawn_armies()
	_spawn_titan()
	_spawn_airship()
	_hud().call("setup", self)
	_opening_orders()
	var rig := $CameraRig as Node3D
	rig.position = Vector3(CITY_CENTER.x, 0, CITY_CENTER.z + 4.0)
	print("VISUAL_READY units=%d titan=%s airship=%s" % [_count_units(), str(titan != null), str(airship != null)])


func _process(delta: float) -> void:
	_elapsed += delta
	material_demo = minf(material_demo + delta * 2.0, 999.0)
	_perf_left -= delta
	if _perf_left <= 0.0:
		_perf_left = 5.0
		_log_perf()


func _log_perf() -> void:
	var p := 0
	var e := 0
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_alive():
			if u.is_player:
				p += 1
			else:
				e += 1
	print("VISUAL_PERF t=%ds fps=%d p=%d e=%d fx=%d emitters=%d mat=%d" % [
		int(_elapsed), Engine.get_frames_per_second(), p, e,
		VisualFX.live_count(), VisualFX.emitter_count(), int(material_demo),
	])


func alive_counts() -> Array:
	var p := 0
	var e := 0
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_alive():
			if u.is_player:
				p += 1
			else:
				e += 1
	return [p, e]


func _count_units() -> int:
	return get_tree().get_nodes_in_group("rts_units").size()


func _ground_y(x: float, z: float) -> float:
	return map_nav.get_ground_height(x, z)


# ------------------------------------------------------------ city layout
func _register_city_obstacles() -> void:
	# Civic hall footprint + two boiler houses. Rects cut navmesh + block slots.
	map_nav.register_obstacle_rect(Vector3(-12, 0, -10), Vector2(13, 11))
	map_nav.register_obstacle_rect(Vector3(0, 0, -14), Vector2(9, 7))
	map_nav.register_obstacle_rect(Vector3(-20, 0, 0), Vector2(9, 7))


func _place_glb(packed: PackedScene, pos: Vector3, yaw: float, shadow_on: bool) -> Node3D:
	var n := packed.instantiate() as Node3D
	city_root.add_child(n)
	n.position = Vector3(pos.x, _ground_y(pos.x, pos.z), pos.z)
	n.rotation.y = yaw
	for c in _all_meshes(n):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n


func _all_meshes(n: Node) -> Array:
	var out: Array = []
	if n is GeometryInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_all_meshes(c))
	return out


func _vent_world(base: Vector3, yaw: float, local_xz: Vector2, height: float) -> Vector3:
	var c := cos(yaw)
	var s := sin(yaw)
	var rx := local_xz.x * c - local_xz.y * s
	var rz := local_xz.x * s + local_xz.y * c
	return Vector3(base.x + rx, _ground_y(base.x, base.z) + height, base.z + rz)


func _build_city() -> void:
	var hall_pos := Vector3(-12, 0, -10)
	_place_glb(HallGLB, hall_pos, 0.25, true)
	# Hall chimney steam + smoke (Blender stack at local x=3.6, lip height 6.4).
	var hall_stack := _vent_world(hall_pos, 0.25, Vector2(3.6, 0.0), 6.6)
	VisualFX.steam_vent(fx_root, hall_stack)
	VisualFX.smoke_vent(fx_root, hall_stack + Vector3(0.4, 0.6, 0))

	var b1_pos := Vector3(0, 0, -14)
	_place_glb(BoilerGLB, b1_pos, -0.3, true)
	var b1_stack := _vent_world(b1_pos, -0.3, Vector2(2.2, 0.0), 9.3)
	VisualFX.steam_vent(fx_root, b1_stack)

	var b2_pos := Vector3(-20, 0, 0)
	_place_glb(BoilerGLB, b2_pos, 0.9, true)
	var b2_stack := _vent_world(b2_pos, 0.9, Vector2(2.2, 0.0), 9.3)
	VisualFX.smoke_vent(fx_root, b2_stack)

	_build_pavement(Vector3(-10, 0, -8), Vector2(30, 24))
	_build_props()
	_build_lamps()


func _mat(color: Color, rough: float = 0.8, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, shadow_on: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _build_pavement(center: Vector3, size: Vector2) -> void:
	var mat := _mat(Color(0.30, 0.29, 0.30, 1.0), 0.95)
	var slab := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.12, size.y)
	slab.mesh = mesh
	slab.material_override = mat
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	city_root.add_child(slab)
	slab.position = Vector3(center.x, _ground_y(center.x, center.z) + 0.06, center.z)


func _build_roads() -> void:
	var mat := _mat(Color(0.36, 0.31, 0.24, 1.0), 1.0)
	var points: Array[Vector3] = [Vector3(-8, 0, -4), Vector3(2, 0, 2), ENEMY_BASE]
	for s in range(points.size() - 1):
		var a: Vector3 = points[s]
		var b: Vector3 = points[s + 1]
		var steps := 8
		for i in range(steps):
			var t0 := float(i) / float(steps)
			var t1 := float(i + 1) / float(steps)
			var p0 := a.lerp(b, t0)
			var p1 := a.lerp(b, t1)
			var mid := (p0 + p1) * 0.5
			var length := p0.distance_to(p1)
			var seg := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(3.0, 0.08, length + 0.3)
			seg.mesh = bm
			seg.material_override = mat
			seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			city_root.add_child(seg)
			seg.rotation.y = atan2(p1.x - p0.x, p1.z - p0.z)
			seg.position = Vector3(mid.x, (_ground_y(p0.x, p0.z) + _ground_y(p1.x, p1.z)) * 0.5 + 0.07, mid.z)


func _build_props() -> void:
	# Crates, barrels, machinery: small silhouette/colour accents, no shadows.
	var crate := _mat(Color(0.45, 0.33, 0.20, 1.0), 0.9)
	var barrel := _mat(Color(0.30, 0.32, 0.35, 1.0), 0.6)
	var brass := _mat(Color(0.60, 0.44, 0.20, 1.0), 0.45)
	var spots: Array = [
		Vector3(-5, 0, -6), Vector3(-4, 0, -5), Vector3(-4.5, 0, -3.5),
		Vector3(-19.5, 0, -3.5), Vector3(4, 0, -10), Vector3(-24, 0, 4),
	]
	for i in range(spots.size()):
		var sp: Vector3 = spots[i]
		sp.y = _ground_y(sp.x, sp.z)
		if i % 3 == 0:
			_box(city_root, Vector3(1.0, 1.0, 1.0), sp + Vector3(0, 0.5, 0), crate)
		elif i % 3 == 1:
			var b := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.45
			cm.bottom_radius = 0.45
			cm.height = 1.1
			cm.radial_segments = 10
			b.mesh = cm
			b.material_override = barrel
			b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			city_root.add_child(b)
			b.position = sp + Vector3(0, 0.55, 0)
		else:
			_box(city_root, Vector3(1.6, 0.8, 0.9), sp + Vector3(0, 0.4, 0), brass)


func _build_lamps() -> void:
	# Street lamps: warm emissive heads (faction-neutral), poles iron.
	var pole_mat := _mat(Color(0.18, 0.18, 0.20, 1.0), 0.7)
	var head_mat := _mat(Color(1.0, 0.82, 0.45, 1.0), 0.35, 2.0)
	var spots: Array = [
		Vector3(-4, 0, -3), Vector3(-16, 0, -4), Vector3(-2, 0, -8),
		Vector3(-22, 0, -4), Vector3(2, 0, -18),
	]
	for sp in spots:
		var base := Vector3((sp as Vector3).x, 0, (sp as Vector3).z)
		base.y = _ground_y(base.x, base.z)
		var pole := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.07
		cm.bottom_radius = 0.09
		cm.height = 3.2
		cm.radial_segments = 8
		pole.mesh = cm
		pole.material_override = pole_mat
		pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		city_root.add_child(pole)
		pole.position = base + Vector3(0, 1.6, 0)
		_box(city_root, Vector3(0.4, 0.4, 0.4), base + Vector3(0, 3.3, 0), head_mat)


func _build_enemy_camp() -> void:
	# Red-side readability only: barricades + red banners + braziers.
	var red := _mat(Color(0.92, 0.26, 0.20, 1.0), 0.6)
	var red_glow := _mat(Color(1.0, 0.30, 0.20, 1.0), 0.4, 1.8)
	var dark := _mat(Color(0.20, 0.16, 0.14, 1.0), 0.9)
	var fire := _mat(Color(1.0, 0.55, 0.20, 1.0), 0.4, 2.2)
	for i in range(5):
		var a := TAU * float(i) / 5.0
		var sp := ENEMY_BASE + Vector3(cos(a) * 6.0, 0, sin(a) * 6.0)
		sp.y = _ground_y(sp.x, sp.z)
		_box(city_root, Vector3(2.2, 1.0, 0.6), sp + Vector3(0, 0.5, 0), dark).rotation.y = a
	for k in range(2):
		var bp := ENEMY_BASE + Vector3(-4.0 + float(k) * 8.0, 0, -5.0)
		bp.y = _ground_y(bp.x, bp.z)
		var pole := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.08
		cm.bottom_radius = 0.08
		cm.height = 4.5
		cm.radial_segments = 8
		pole.mesh = cm
		pole.material_override = dark
		pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		city_root.add_child(pole)
		pole.position = bp + Vector3(0, 2.25, 0)
		_box(city_root, Vector3(1.0, 1.5, 0.08), bp + Vector3(0, 3.6, 0), red_glow)
		_box(city_root, Vector3(0.7, 0.7, 0.7), bp + Vector3(1.6, 0.35, 0), fire)
	_box(city_root, Vector3(3.0, 0.2, 3.0), Vector3(ENEMY_BASE.x, _ground_y(ENEMY_BASE.x, ENEMY_BASE.z) + 0.1, ENEMY_BASE.z), red)


# ------------------------------------------------------------------ actors
func _scene_for(def: UnitDefinition) -> PackedScene:
	if def == null:
		return InfantryScene
	match def.id:
		&"gf_marksman":
			return MarksmanScene
		&"gf_heavy_guard":
			return HeavyScene
	return InfantryScene


func spawn_unit(def: UnitDefinition, player_flag: bool, pos: Vector3) -> RTSUnit:
	var u := (_scene_for(def).instantiate()) as RTSUnit
	u.setup(def, player_flag)
	u.position = map_nav.clamp_inside(pos)
	u.always_show_hp = true
	units_root.add_child(u)
	u.guard_pos = u.global_position
	u.died.connect(_on_unit_died)
	u.damaged.connect(_on_unit_damaged)
	u.fired.connect(_on_unit_fired)
	return u


func _spawn_armies() -> void:
	# 8 player (blue) vs 7 enemy (red) = 15 total, per spec 10-20.
	var p_defs: Array = [InfantryDef, InfantryDef, InfantryDef, InfantryDef, MarksmanDef, MarksmanDef, HeavyDef, HeavyDef]
	var e_defs: Array = [InfantryDef, InfantryDef, InfantryDef, InfantryDef, MarksmanDef, MarksmanDef, HeavyDef]
	_spawn_line(p_defs, true, PLAYER_BASE + Vector3(6, 0, 4))
	_spawn_line(e_defs, false, ENEMY_BASE + Vector3(-6, 0, -4))


func _spawn_line(defs: Array, player_flag: bool, anchor: Vector3) -> void:
	for i in range(defs.size()):
		var row := i / 4
		var col := i % 4
		var pos := anchor + Vector3(float(col) * 2.4 - 3.6, 0, float(row) * 2.4)
		var u := spawn_unit(defs[i] as UnitDefinition, player_flag, pos)
		var foe := ENEMY_BASE if player_flag else PLAYER_BASE
		var d: Vector3 = foe - u.global_position
		if d.length() > 0.01:
			u.rotation.y = atan2(d.x, d.z) + PI


func _spawn_titan() -> void:
	# Phase 1.8: patrol in open ground east/south of the civic hall so the
	# Titan silhouette reads against infantry/city instead of fusing with
	# the Annex. Points avoid hall/boiler obstacle rects (no nav change).
	titan = VisualTitan.new()
	titan.setup(true, Vector3(0, 0, -4), Vector3(4, 0, 2))
	units_root.add_child(titan)
	titan.position = map_nav.clamp_inside(Vector3(0, 0, -4))
	titan.died.connect(_on_titan_died)
	titan.damaged.connect(_on_titan_damaged)


func _spawn_airship() -> void:
	airship = VisualAirship.new()
	airship.is_player = true
	airship.center = CITY_CENTER
	units_root.add_child(airship)
	airship.global_position = CITY_CENTER + Vector3(0, VisualAirship.CRUISE_HEIGHT, 0)


func _opening_orders() -> void:
	# Demo battle: both sides attack-move toward mid so tracers/explosions
	# read immediately without player input.
	var p: Array = []
	var e: Array = []
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_alive():
			if u.is_player:
				p.append(u)
			else:
				e.append(u)
	orders.issue_attack_move(p, Vector3(2, 0, 2))
	orders.issue_attack_move(e, Vector3(-2, 0, -2))


# ------------------------------------------------------------------ combat FX
func _on_unit_died(unit: RTSUnit) -> void:
	VisualFX.death(fx_root, unit.global_position, unit.is_player)
	if selection != null and selection.selected.has(unit):
		selection.selected.erase(unit)
		unit.set_selected(false)


func _on_unit_damaged(unit: RTSUnit) -> void:
	if unit.is_alive():
		VisualFX.hit(fx_root, unit.global_position, unit.is_player)


func _on_unit_fired(attacker: RTSUnit, target_pos: Vector3) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	var from_pos: Vector3 = attacker.global_position
	VisualFX.muzzle(fx_root, from_pos + Vector3(0, 1.2, 0), attacker.is_player, false)
	VisualFX.tracer(fx_root, from_pos, target_pos, attacker.is_player)


func _on_titan_died(_t: VisualTitan) -> void:
	pass


func _on_titan_damaged(t: VisualTitan) -> void:
	if t.is_alive():
		VisualFX.hit(fx_root, t.global_position + Vector3(0, 5.0, 0), t.is_player)


func _hud() -> CanvasLayer:
	return $HUD as CanvasLayer
