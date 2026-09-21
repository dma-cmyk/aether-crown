class_name FactionDefinition
extends Resource
## Faction data template.

@export var id: StringName = &"gearforge"
@export var display_name: String = "Gearforge"
@export var description: String = "Steam-machine faction (placeholder)."
@export var primary_color: Color = Color(0.91, 0.70, 0.29, 1.0)
@export var secondary_color: Color = Color(0.16, 0.18, 0.24, 1.0)
@export var starting_units: Array[UnitDefinition] = []
@export var starting_buildings: Array[BuildingDefinition] = []
