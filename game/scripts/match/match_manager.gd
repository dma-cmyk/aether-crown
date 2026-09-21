class_name MatchManager
extends Node
## Match lifecycle for Phase 1.5: timer, VICTORY/DEFEAT, full stop, restart.
## End of game pauses the tree (units, AI, production, projectiles all stop);
## the end-screen overlay runs with PROCESS_MODE_ALWAYS so Restart works.

signal game_over(player_won: bool)

enum Phase { PLAYING, VICTORY, DEFEAT }

var phase: int = Phase.PLAYING
var elapsed: float = 0.0


func _process(delta: float) -> void:
	if phase == Phase.PLAYING:
		elapsed += delta


func is_playing() -> bool:
	return phase == Phase.PLAYING


func end_game(player_won: bool) -> void:
	if phase != Phase.PLAYING:
		return
	phase = Phase.VICTORY if player_won else Phase.DEFEAT
	game_over.emit(player_won)
	get_tree().paused = true


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func format_time() -> String:
	var total := int(elapsed)
	return "%d:%02d" % [total / 60, total % 60]
