class_name AbilityDefinition
extends Resource
## Ability data template (active or passive).

@export var id: StringName = &"overdrive"
@export var display_name: String = "Overdrive"
@export var description: String = ""
@export var cooldown_sec: float = 30.0
@export var aether_cost: int = 25
@export var range: float = 0.0
@export var icon: Texture2D
