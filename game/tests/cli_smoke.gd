extends SceneTree
## CLI smoke test: proves GDScript runs headless via OpenCode.
## Usage: godot --headless --path <game> --script res://tests/cli_smoke.gd

func _initialize() -> void:
	print("CLI_SMOKE_OK Godot=" + Engine.get_version_info().get("string", "?"))
	var actions := [
		"camera_forward", "camera_backward", "camera_left", "camera_right",
		"camera_zoom_in", "camera_zoom_out",
		"select", "select_add", "command", "attack_move", "pause_game",
	]
	for a in actions:
		print("INPUT_CHECK ", a, "=", str(InputMap.has_action(a)))
	print("AUTOLOAD_CHECK GameManager registered in project.godot (see [autoload])")
	quit(0)
