class_name UnitDefinition
extends Resource
## Unit data template. Balance numbers live here, not in unit scripts.
## Create instances as .tres under res://resources/units/

@export var id: StringName = &"gearforge_infantry"
@export var display_name: String = "Gearforge Infantry"
@export var description: String = ""
@export var faction_id: StringName = &"gearforge"

@export_group("Costs")
@export var cost_metal: int = 50
@export var cost_aether: int = 0
@export var build_time_sec: float = 5.0
@export var supply_cost: int = 1

@export_group("Combat")
@export var max_hp: float = 100.0
@export var move_speed: float = 5.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 12.0
@export var attack_interval_sec: float = 1.0
@export var sight_range: float = 20.0

@export_group("Presentation")
@export var scene: PackedScene
@export var icon: Texture2D
@export var poly_budget: String = "low_mid"  # low | low_mid | mid | mid_high (see docs/model_rules.md)
@export var lod_distances: Vector3 = Vector3(30.0, 60.0, 120.0)
