class_name BuildingDefinition
extends Resource
## Building data template. See UnitDefinition for usage pattern.

@export var id: StringName = &"gearforge_factory"
@export var display_name: String = "Gearforge Factory"
@export var description: String = ""
@export var faction_id: StringName = &"gearforge"

@export_group("Costs")
@export var cost_metal: int = 200
@export var cost_aether: int = 0
@export var build_time_sec: float = 20.0

@export_group("Stats")
@export var max_hp: float = 800.0
@export var footprint: Vector2 = Vector2(4, 4)  # meters, XZ
@export var blocks_navigation: bool = true

@export_group("Presentation")
@export var scene: PackedScene
@export var icon: Texture2D
@export var poly_budget: String = "mid"
