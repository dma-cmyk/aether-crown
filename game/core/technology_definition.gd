class_name TechnologyDefinition
extends Resource
## Technology data template.

@export var id: StringName = &"improved_boilers"
@export var display_name: String = "Improved Boilers"
@export var description: String = ""
@export var cost_metal: int = 150
@export var cost_aether: int = 50
@export var research_time_sec: float = 30.0
@export var prerequisites: Array[TechnologyDefinition] = []
@export var icon: Texture2D
