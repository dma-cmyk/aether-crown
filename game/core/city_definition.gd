class_name CityDefinition
extends Resource
## City data template (Phase 2A). Income bonus is Material/sec granted to
## the owning faction. No Aether, no districts, no growth stages (Phase 2B+).

@export var id: StringName = &"west_city"
@export var display_name: String = "West City"
@export var description: String = ""

@export_group("Capture")
@export var capture_time_sec: float = 12.0
@export var capture_radius: float = 8.0

@export_group("Economy")
@export var income_bonus: float = 1.5 # Material per second for the owner
