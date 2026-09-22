extends Node3D
## Phase 2.5A art showcase: ONE representative city (civic core GLB) + TWO
## district production assets (industry + aether works GLBs) + territory
## overlay + frontline + 5v5 live skirmish, in a single lightweight scene.
## No gameplay logic changes: existing maps, units, and systems untouched.
## Proves art direction + GLB pipeline + Iris Xe performance.

const CivicCore: PackedScene = preload("res://assets/models/gearforge_civic_core.glb")
const IndustryWorks: PackedScene = preload("res://assets/models/gearforge_industry_works.glb")
const AetherWorks: PackedScene = preload("res://assets/models/gearforge_aether_works.glb")
const InfantryScene: PackedScene = preload("res://scenes/units/infantry.tscn")
const InfantryDef: UnitDefinition = preload("res://resources/units/gf_infantry.tres")

var kills: int = 0

var _elapsed: float = 0.0
var _perf_left: float = 5.0
var _fps_min: int = 9999
var _fps_sum: int = 0
var _fps_n: int = 0

@onready var units_root: Node3D = $UnitsRoot
@onready var fps_label: Label = $HUD/FpsLabel


func _ready() -> void:
	add_to_group("art_showcase")
	_build_ground()
	_place_asset(CivicCore, Vector3(0, 0, -6), "CivicCore")
	_place_asset(IndustryWorks, Vector3(-15, 0, 8), "Industry")
	_place_asset(AetherWorks, Vector3(15, 0, 8), "AetherWorks")
	_setup_territories()
	_spawn_skirmish()
	print("ART_SHOWCASE_READY")


func _place_asset(scene: PackedScene, pos: Vector3, tag: String) -> void:
	var n := scene.instantiate() as Node3D
	n.position = pos
	n.name = tag
	add_child(n)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(120, 120)
	ground.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.26, 0.32, 0.22, 1.0)
	mat.roughness = 1.0
	ground.material_override = mat
	$GroundRoot.add_child(ground)


func _setup_territories() -> void:
	var ctrl := TerritoryController.new()
	ctrl.name = "TerritoryController"
	add_child(ctrl)
	var west := TerritoryDefinition.new()
	west.id = &"showcase_west"
	west.display_name = "Showcase West"
	west.fixed_owner = TerritoryRegion.Owner.PLAYER
	west.center = Vector3(-8, 0, 2)
	west.size = Vector2(34, 30)
	west.neighbor_ids = ["showcase_east"] as Array[String]
	var east := TerritoryDefinition.new()
	east.id = &"showcase_east"
	east.display_name = "Showcase East"
	east.fixed_owner = TerritoryRegion.Owner.ENEMY
	east.center = Vector3(14, 0, 4)
	east.size = Vector2(30, 30)
	east.neighbor_ids = ["showcase_west"] as Array[String]
	ctrl.setup([west, east])
	ctrl.refresh()


func _spawn_skirmish() -> void:
	for i in range(5):
		var p := _spawn_unit(true, Vector3(-8.0 + float(i) * 1.6, 0, -16.0))
		var e := _spawn_unit(false, Vector3(6.0 + float(i) * 1.6, 0, 14.0))
		p.order_attack_move(Vector3(8, 0, 12))
		e.order_attack_move(Vector3(-8, 0, -12))


func _spawn_unit(player_flag: bool, pos: Vector3) -> RTSUnit:
	var u := (InfantryScene.instantiate()) as RTSUnit
	u.setup(InfantryDef, player_flag)
	u.position = pos
	u.always_show_hp = true
	units_root.add_child(u)
	u.guard_pos = u.global_position
	u.died.connect(_on_unit_died)
	return u


func _on_unit_died(_unit: RTSUnit) -> void:
	kills += 1


func _process(delta: float) -> void:
	_elapsed += delta
	_perf_left -= delta
	if _perf_left <= 0.0:
		_perf_left = 5.0
		var f := Engine.get_frames_per_second()
		_fps_min = mini(_fps_min, f)
		_fps_sum += f
		_fps_n += 1
		var p := 0
		var e := 0
		for o in get_tree().get_nodes_in_group("rts_units"):
			var u := o as RTSUnit
			if u != null and u.is_alive():
				if u.is_player:
					p += 1
				else:
					e += 1
		print("SHOWCASE_PERF t=%ds fps=%d p=%d e=%d kills=%d" % [int(_elapsed), f, p, e, kills])
	if fps_label != null:
		fps_label.text = "FPS: %d  Units P/E  Test" % Engine.get_frames_per_second()
