class_name DistrictDefinition
extends Resource
## District data template (Phase 2C). Districts are built into preset city
## slots (2 per capturable city): no free placement, no tiers, no upgrades.

@export var id: StringName = &"industry"
@export var display_name: String = "Industry"
@export var description: String = ""

@export_group("Cost")
@export var material_cost: int = 140
@export var aether_cost: int = 25
@export var build_time_sec: float = 12.0

@export_group("Bonus")
@export var material_income_bonus: float = 0.0 # Material/sec for the city owner
@export var aether_income_bonus: float = 0.0 # Aether/sec for the city owner
@export var population_bonus: int = 0 # Pop cap for the city owner

@export_group("Presentation")
@export var visual_type: StringName = &"industry"
