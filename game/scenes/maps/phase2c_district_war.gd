extends Node3D
## Phase 2C district-war map: Phase 2B territory war + 2 district slots per
## capturable city (Industry / Military / Aether Works). Districts cost
## Material + Aether up front, take 12s, and stick to the city on capture
## (bonuses follow the new owner). Production stays HQ-only. Victory and
## defeat still come from HQ destruction only. No tiers, no upgrades,
## no selling, no free placement (Phase 2D+).

const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const MarksmanScene: PackedScene = preload("res://scenes/units/marksman.tscn")
const HeavyScene: PackedScene = preload("res://scenes/units/heavy_guard.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")
const MarksmanDef: UnitDefinition = preload("res://resources/units/gf_marksman.tres")
const HeavyDef: UnitDefinition = preload("res://resources/units/gf_heavy_guard.tres")
const HqDef: BuildingDefinition = preload("res://resources/buildings/gf_hq.tres")
const WestDef: CityDefinition = preload("res://resources/cities/west_city.tres")
const CentralDef: CityDefinition = preload("res://resources/cities/central_city.tres")
const EastDef: CityDefinition = preload("res://resources/cities/east_city.tres")
const PlayerBaseTerritoryDef: TerritoryDefinition = preload("res://resources/territories/player_base.tres")
const WestTerritoryDef: TerritoryDefinition = preload("res://resources/territories/west.tres")
const CentralTerritoryDef: TerritoryDefinition = preload("res://resources/territories/central.tres")
const EastTerritoryDef: TerritoryDefinition = preload("res://resources/territories/east.tres")
const EnemyBaseTerritoryDef: TerritoryDefinition = preload("res://resources/territories/enemy_base.tres")
const IndustryDef: DistrictDefinition = preload("res://resources/districts/industry.tres")
const MilitaryDef: DistrictDefinition = preload("res://resources/districts/military.tres")
const AetherWorksDef: DistrictDefinition = preload("res://resources/districts/aether_works.tres")

const START_MATERIAL: float = 120.0
const BASE_INCOME: float = 2.0
const MAX_POP: int = 40
const DISTRICT_AI_INTERVAL: float = 7.0
const PLAYER_BASE_POS := Vector3(-30, 0, -30)
const ENEMY_BASE_POS := Vector3(30, 0, 30)
const WEST_CITY_POS := Vector3(-20, 0, 4)
const CENTRAL_CITY_POS := Vector3(0, 0, 0)
const EAST_CITY_POS := Vector3(20, 0, -4)

const ROCKS: Array = [
	[Vector2(-10, -14), 2.0], [Vector2(12, 12), 1.8], [Vector2(-28, -8), 1.6],
	[Vector2(8, -18), 2.2], [Vector2(-6, 18), 1.7], [Vector2(26, 8), 1.9],
]
const TREES: Array = [
	Vector2(-26, -18), Vector2(-14, -24), Vector2(14, 22), Vector2(26, 16),
	Vector2(-8, 12), Vector2(10, -10), Vector2(-34, 10), Vector2(34, -12),
]

var player_hq: RTSBuilding
var enemy_hq: RTSBuilding
var cities: Array = []
var kills_by_player: int = 0
var kills_by_enemy: int = 0
## Test hook: automated tests disable the re-engagement pulse for
## deterministic capture phases. Always true in real play.
var pulse_enabled: bool = true

var _elapsed: float = 0.0
var _perf_left: float = 5.0
var _pulse_left: float = 4.0
var _district_ai_left: float = DISTRICT_AI_INTERVAL
var _territory_owners: Dictionary = {}

@onready var map_nav: MapNav = $MapNav
@onready var obstacles_root: Node3D = $ObstaclesRoot
@onready var deco_root: Node3D = $DecoRoot
@onready var buildings_root: Node3D = $BuildingsRoot
@onready var units_root: Node3D = $UnitsRoot
@onready var fx_root: Node3D = $FxRoot
@onready var orders: OrderManager = $OrderManager
@onready var selection: SelectionManager = $SelectionManager
@onready var economy_p: RTSEconomy = $EconomyP
@onready var economy_e: RTSEconomy = $EconomyE
@onready var queue_p: ProductionQueue = $QueueP
@onready var queue_e: ProductionQueue = $QueueE
@onready var match_mgr: MatchManager = $MatchManager
@onready var strategist: EnemyStrategist = $Strategist
@onready var territories: TerritoryController = $TerritoryController
@onready var districts: DistrictController = $DistrictController


func _ready() -> void:
	add_to_group("match_map")
	map_nav.player_base = PLAYER_BASE_POS
	map_nav.enemy_base = ENEMY_BASE_POS
	map_nav.register_obstacle_rect(PLAYER_BASE_POS, Vector2(8, 7))
	map_nav.register_obstacle_rect(ENEMY_BASE_POS, Vector2(8, 7))
	_build_decor()
	map_nav.build($GroundRoot)
	_build_road()
	_spawn_hq(true, PLAYER_BASE_POS)
	_spawn_hq(false, ENEMY_BASE_POS)
	_spawn_city($WestCity as RTSCity, WestDef, WEST_CITY_POS)
	_spawn_city($CentralCity as RTSCity, CentralDef, CENTRAL_CITY_POS)
	_spawn_city($EastCity as RTSCity, EastDef, EAST_CITY_POS)
	economy_p.setup(true, START_MATERIAL, BASE_INCOME, MAX_POP, 0.0, 0.0)
	economy_e.setup(false, START_MATERIAL, BASE_INCOME, MAX_POP, 0.0, 0.0)
	queue_p.unit_ready.connect(_on_player_unit_ready)
	queue_e.unit_ready.connect(_on_enemy_unit_ready)
	match_mgr.game_over.connect(_on_game_over)
	_setup_territories()
	_setup_districts()
	_wire_strategist()
	_spawn_initial_army(true)
	_spawn_initial_army(false)
	_hud().call("setup", self)
	print("DISTRICT_WAR_READY p_hq=%s e_hq=%s cities=%d territories=%d" % [str(player_hq.global_position), str(enemy_hq.global_position), cities.size(), territories.regions.size()])


func is_playing() -> bool:
	return match_mgr.is_playing()


## Counts per owner side for HUD/tests: {"player": p, "neutral": n, "enemy": e}.
func city_counts() -> Dictionary:
	var counts := {"player": 0, "neutral": 0, "enemy": 0}
	for c in cities:
		var city := c as RTSCity
		if city == null:
			continue
		match city.owner_side:
			RTSCity.Owner.PLAYER:
				counts["player"] = int(counts["player"]) + 1
			RTSCity.Owner.ENEMY:
				counts["enemy"] = int(counts["enemy"]) + 1
			_:
				counts["neutral"] = int(counts["neutral"]) + 1
	return counts


func city_status_lines() -> Array:
	var lines: Array = []
	for c in cities:
		var city := c as RTSCity
		if city != null:
			lines.append(city.status_text())
	return lines


func territory_counts() -> Dictionary:
	return territories.counts()


func territory_status_lines() -> Array:
	return territories.status_lines()


func frontline_pairs() -> Array:
	return territories.frontline_pairs()


func get_city(city_id: String) -> RTSCity:
	for c in cities:
		var city := c as RTSCity
		if city != null and str(city.city_id) == city_id:
			return city
	return null


## Player-facing build entry (used by the HUD). Returns a result code.
func try_build_player(city_id: String, district_id: String) -> String:
	var city := get_city(city_id)
	if city == null:
		return "not_owner"
	return districts.try_build(city, StringName(district_id), economy_p, true)


func district_slot_texts(city_id: String) -> Array:
	var city := get_city(city_id)
	if city == null:
		return []
	return districts.slot_texts(city)


func _setup_districts() -> void:
	districts.setup(cities, [IndustryDef, MilitaryDef, AetherWorksDef])
	districts.districts_changed.connect(_on_districts_changed)


func _on_districts_changed() -> void:
	_recalc_all_bonuses()


## Single event-driven bonus recalc: city material + industry, territory
## aether + aether works, pop cap + military. Called on district events,
## city ownership change, and territory change. Never per-frame.
func _recalc_all_bonuses() -> void:
	var mat_p := 0.0
	var mat_e := 0.0
	for c in cities:
		var city := c as RTSCity
		if city == null:
			continue
		if city.owner_side == RTSCity.Owner.PLAYER:
			mat_p += city.income_bonus
		elif city.owner_side == RTSCity.Owner.ENEMY:
			mat_e += city.income_bonus
	economy_p.bonus_income = mat_p + districts.material_for(true)
	economy_e.bonus_income = mat_e + districts.material_for(false)
	economy_p.bonus_aether = territories.aether_for(true) + districts.aether_for(true)
	economy_e.bonus_aether = territories.aether_for(false) + districts.aether_for(false)
	economy_p.pop_max = MAX_POP + districts.pop_for(true)
	economy_e.pop_max = MAX_POP + districts.pop_for(false)


func _setup_territories() -> void:
	territories.setup([PlayerBaseTerritoryDef, WestTerritoryDef, CentralTerritoryDef, EastTerritoryDef, EnemyBaseTerritoryDef])
	for c in cities:
		territories.bind_city(c as RTSCity)
	_snapshot_territory_owners()
	territories.territories_changed.connect(_on_territories_changed)
	_recalc_all_bonuses()


func _snapshot_territory_owners() -> void:
	_territory_owners.clear()
	for r in territories.regions:
		var region := r as TerritoryRegion
		if region != null:
			_territory_owners[region.region_id] = region.owner_side


func _on_territories_changed() -> void:
	_recalc_all_bonuses()
	for r in territories.regions:
		var region := r as TerritoryRegion
		if region == null:
			continue
		var old: int = int(_territory_owners.get(region.region_id, -99))
		if old != region.owner_side:
			_territory_owners[region.region_id] = region.owner_side
			print("DISTRICT_TERRITORY_SHIFT %s -> %s aether=%.2f/s" % [region.display_name, region.owner_name(), region.definition.aether_income_bonus])
			_hud().call("toast", "%s: %s (Aether +%.2f/s)" % [region.display_name, region.owner_name(), region.definition.aether_income_bonus])


func _process(delta: float) -> void:
	_elapsed += delta
	_perf_left -= delta
	if _perf_left <= 0.0:
		_perf_left = 5.0
		_log_perf()
	_pulse_left -= delta
	if _pulse_left <= 0.0:
		_pulse_left = 4.0
		if pulse_enabled:
			_battle_pulse()
	_district_ai_left -= delta
	if _district_ai_left <= 0.0:
		_district_ai_left = DISTRICT_AI_INTERVAL
		if match_mgr.is_playing():
			strategist.district_saving = districts.enemy_wants_saving(economy_e)
			districts.enemy_ai_tick(economy_e)


# ------------------------------------------------------------- battle pulse
## Same Phase 1.5 rule (bloodied idle only, single O(n) pass, 4s cadence).
func _battle_pulse() -> void:
	if not match_mgr.is_playing():
		return
	var p_idle: Array = []
	var e_idle: Array = []
	var p_pos := Vector3.ZERO
	var p_n := 0
	var e_pos := Vector3.ZERO
	var e_n := 0
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u == null or not u.is_alive():
			continue
		if u.is_player:
			p_pos += u.global_position
			p_n += 1
			if u.state == RTSUnit.State.IDLE and u.bloodied:
				p_idle.append(u)
		else:
			e_pos += u.global_position
			e_n += 1
			if u.state == RTSUnit.State.IDLE and u.bloodied:
				e_idle.append(u)
	if p_n > 0 and e_n == 0 and enemy_hq != null and enemy_hq.is_alive() and not p_idle.is_empty():
		orders.issue_attack_move(p_idle, enemy_hq.global_position)
		return
	if e_n > 0 and p_n == 0 and player_hq != null and player_hq.is_alive() and not e_idle.is_empty():
		orders.issue_attack_move(e_idle, player_hq.global_position)
		return
	if p_n == 0 or e_n == 0:
		return
	if p_idle.is_empty() and e_idle.is_empty():
		return
	orders.issue_attack_move(p_idle, e_pos / float(e_n))
	orders.issue_attack_move(e_idle, p_pos / float(p_n))


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
	var cc := city_counts()
	var tc := territory_counts()
	var dc := _district_count()
	print("DISTRICT_PERF t=%s fps=%d p=%d e=%d kills_p=%d kills_e=%d mat_p=%d mat_e=%d ae_p=%.1f ae_e=%.1f ai=%s cities=P%d/N%d/E%d terr=P%d/N%d/E%d dist=%d" % [
		match_mgr.format_time(), Engine.get_frames_per_second(), p, e,
		kills_by_player, kills_by_enemy,
		int(economy_p.material), int(economy_e.material),
		economy_p.aether, economy_e.aether,
		strategist.plan_name(),
		int(cc["player"]), int(cc["neutral"]), int(cc["enemy"]),
		int(tc["player"]), int(tc["neutral"]), int(tc["enemy"]),
		dc,
	])


func _district_count() -> int:
	var n := 0
	for s in districts.slots:
		if int((s as Dictionary)["state"]) == DistrictController.STATE_COMPLETE:
			n += 1
	return n


# ------------------------------------------------------------------ static
func _ground_y(x: float, z: float) -> float:
	return map_nav.get_ground_height(x, z)


func _build_decor() -> void:
	for r in ROCKS:
		var pos := r[0] as Vector2
		_place_rock(Vector3(pos.x, 0, pos.y), float(r[1]))
	for t in TREES:
		_place_tree(Vector3(t.x, 0, t.y))


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


## Dirt road HQ -> West -> Central -> East -> HQ, visual only (no nav change).
func _build_road() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.32, 0.24, 1.0)
	mat.roughness = 1.0
	var points: Array[Vector3] = [PLAYER_BASE_POS, WEST_CITY_POS, CENTRAL_CITY_POS, EAST_CITY_POS, ENEMY_BASE_POS]
	for s in range(points.size() - 1):
		var a: Vector3 = points[s]
		var b: Vector3 = points[s + 1]
		var steps := 6
		for i in range(steps):
			var t0 := float(i) / float(steps)
			var t1 := float(i + 1) / float(steps)
			var p0 := a.lerp(b, t0)
			var p1 := a.lerp(b, t1)
			var mid := (p0 + p1) * 0.5
			var length := p0.distance_to(p1)
			var seg := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(3.2, 0.08, length + 0.3)
			seg.mesh = bm
			seg.material_override = mat
			deco_root.add_child(seg)
			var yaw := atan2(p1.x - p0.x, p1.z - p0.z)
			seg.rotation.y = yaw
			seg.position = Vector3(mid.x, (_ground_y(p0.x, p0.z) + _ground_y(p1.x, p1.z)) * 0.5 + 0.07, mid.z)


# ------------------------------------------------------------------ actors
func _spawn_hq(player_flag: bool, pos: Vector3) -> void:
	var hq := RTSBuilding.new()
	hq.setup(HqDef, player_flag)
	hq.position = Vector3(pos.x, _ground_y(pos.x, pos.z), pos.z)
	HqVisual.build(hq, player_flag)
	buildings_root.add_child(hq)
	hq.damaged.connect(_on_building_damaged)
	if player_flag:
		player_hq = hq
		hq.died.connect(_on_player_hq_died)
	else:
		enemy_hq = hq
		hq.died.connect(_on_enemy_hq_died)


func _spawn_city(node: RTSCity, def: CityDefinition, pos: Vector3) -> void:
	node.setup(def)
	node.position = Vector3(pos.x, _ground_y(pos.x, pos.z), pos.z)
	map_nav.register_obstacle_circle(node.position, 2.0)
	node.ownership_changed.connect(_on_city_owner_changed.bind(node))
	cities.append(node)


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


func _spawn_initial_army(player_flag: bool) -> void:
	var base := PLAYER_BASE_POS if player_flag else ENEMY_BASE_POS
	var foe := ENEMY_BASE_POS if player_flag else PLAYER_BASE_POS
	var fwd: Vector3 = (foe - base)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var side := Vector3(-fwd.z, 0, fwd.x)
	var defs: Array = [InfantryDef, InfantryDef, InfantryDef, InfantryDef, MarksmanDef]
	for i in range(defs.size()):
		var across := (float(i) - 2.0) * 2.4
		var pos := base + fwd * 9.0 + side * across
		var u := spawn_unit(defs[i], player_flag, pos)
		var d: Vector3 = foe - u.global_position
		if d.length() > 0.01:
			u.rotation.y = atan2(d.x, d.z) + PI


func _find_spawn(hq_pos: Vector3, attack_dir: Vector3) -> Vector3:
	for r in [7.5, 9.5, 11.5]:
		for k in range(8):
			var a := TAU * float(k) / 8.0
			var q: Vector3 = hq_pos + attack_dir * r + Vector3(cos(a) * 2.0, 0, sin(a) * 2.0)
			q = map_nav.clamp_inside(q)
			if not map_nav.is_blocked(q.x, q.z):
				return q
	return map_nav.clamp_inside(hq_pos + attack_dir * 8.0)


func _rally_dir(player_flag: bool) -> Vector3:
	var hq_pos := player_hq.global_position if player_flag else enemy_hq.global_position
	var d := Vector3.ZERO - hq_pos
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3(0, 0, 1)


func _on_player_unit_ready(def: UnitDefinition) -> void:
	_produce_ready(def, true)


func _on_enemy_unit_ready(def: UnitDefinition) -> void:
	_produce_ready(def, false)


func _produce_ready(def: UnitDefinition, player_flag: bool) -> void:
	var eco := economy_p if player_flag else economy_e
	var hq := player_hq if player_flag else enemy_hq
	if hq == null or not hq.is_alive():
		return
	eco.on_unit_completed(def.supply_cost)
	var u := spawn_unit(def, player_flag, _find_spawn(hq.global_position, _rally_dir(player_flag)))
	MatchFX.production_ready(fx_root, hq.global_position, def.display_name)
	var dest := Vector3.ZERO
	if not player_flag and strategist != null:
		var plan_dest: Vector3 = strategist._plan_destination()
		if plan_dest != Vector3.INF:
			dest = plan_dest
	orders.issue_attack_move([u], dest)


func _on_unit_died(unit: RTSUnit) -> void:
	var pop_cost := 1
	if unit.definition != null:
		pop_cost = unit.definition.supply_cost
	if unit.is_player:
		kills_by_enemy += 1
		economy_p.on_unit_died(pop_cost)
	else:
		kills_by_player += 1
		economy_e.on_unit_died(pop_cost)
	MatchFX.death(fx_root, unit.global_position, unit.is_player)
	if selection != null and selection.selected.has(unit):
		selection.selected.erase(unit)
		unit.set_selected(false)


func _on_unit_damaged(unit: RTSUnit) -> void:
	if unit.is_alive():
		MatchFX.hit(fx_root, unit.global_position, unit.is_player)


func _on_unit_fired(attacker: RTSUnit, target_pos: Vector3) -> void:
	if attacker != null and is_instance_valid(attacker):
		MatchFX.muzzle(fx_root, target_pos, attacker.is_player)


func _on_building_damaged(building: RTSBuilding) -> void:
	if building.is_alive():
		MatchFX.hit(fx_root, building.global_position + Vector3(0, 3, 0), building.is_player)


func _on_player_hq_died(_hq: RTSBuilding) -> void:
	MatchFX.death(fx_root, player_hq.global_position + Vector3(0, 3, 0), true)
	match_mgr.end_game(false)


func _on_enemy_hq_died(_hq: RTSBuilding) -> void:
	MatchFX.death(fx_root, enemy_hq.global_position + Vector3(0, 3, 0), false)
	match_mgr.end_game(true)


func _on_game_over(player_won: bool) -> void:
	print("DISTRICT_OVER victory=" if player_won else "DISTRICT_OVER defeat=", player_won)
	_hud().call("show_end", player_won)


func _on_city_owner_changed(new_owner: int, city: RTSCity) -> void:
	_recalc_all_bonuses()
	print("DISTRICT_CITY %s -> %s" % [city.display_name, city.owner_name()])
	_hud().call("toast", "%s captured: %s (+%.1f/s)" % [city.display_name, city.owner_name(), city.income_bonus])


func _wire_strategist() -> void:
	strategist.economy = economy_e
	strategist.queue = queue_e
	strategist.orders = orders
	strategist.map_nav = map_nav
	strategist.match_mgr = match_mgr
	strategist.enemy_hq = enemy_hq
	strategist.player_hq = player_hq
	strategist.outpost = null
	strategist.cities = cities.duplicate()
	strategist.city_aether = {
		"west_city": WestTerritoryDef.aether_income_bonus,
		"central_city": CentralTerritoryDef.aether_income_bonus,
		"east_city": EastTerritoryDef.aether_income_bonus,
	}
	strategist.infantry_def = InfantryDef
	strategist.marksman_def = MarksmanDef
	strategist.heavy_def = HeavyDef


func _hud() -> CanvasLayer:
	return $HUD as CanvasLayer
