extends Node
## GameManager - minimal autoload for RTS session state.
## Keep this small. Do not add unrelated singletons here.
## Future systems (match state, pause, speed) go through this entry point.

var is_paused: bool = false
var game_speed: float = 1.0

signal pause_changed(paused: bool)
signal game_speed_changed(speed: float)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_paused(value: bool) -> void:
	if is_paused == value:
		return
	is_paused = value
	get_tree().paused = value
	pause_changed.emit(value)


func toggle_pause() -> void:
	set_paused(not is_paused)


func set_game_speed(value: float) -> void:
	game_speed = clampf(value, 0.0, 4.0)
	Engine.time_scale = game_speed
	game_speed_changed.emit(game_speed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		toggle_pause()
		get_viewport().set_input_as_handled()
