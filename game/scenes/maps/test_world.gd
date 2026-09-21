extends Node3D
## Test world bootstrap: log + FPS label update. Keeps test scene observable from CLI.

@onready var fps_label: Label = get_node_or_null("UI/FPSLabel") as Label


func _ready() -> void:
	print("TEST_WORLD_READY camera=", get_node_or_null("CameraRig/Camera3D") != null, " turret=", get_node_or_null("Turret") != null)


func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS: %d | WASD move | Wheel/E,Q zoom | Esc pause" % Engine.get_frames_per_second()
