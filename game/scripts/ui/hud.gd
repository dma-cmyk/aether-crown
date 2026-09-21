extends CanvasLayer
## Phase 1 debug HUD: FPS, unit counts, selection info, spawn controls.

var _accum := 0.0

@onready var fps_label: Label = $TopLeft/FpsLabel
@onready var units_label: Label = $TopLeft/UnitsLabel
@onready var selected_label: Label = $TopLeft/SelectedLabel
@onready var mode_label: Label = $TopLeft/ModeLabel


func _ready() -> void:
	($TopRight/AddButton as Button).pressed.connect(_on_add)
	($TopRight/MaxButton as Button).pressed.connect(_on_max)
	($TopRight/ResetButton as Button).pressed.connect(_on_reset)


func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	var fps := Engine.get_frames_per_second()
	var players := 0
	var enemies := 0
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u == null or not u.is_alive():
			continue
		if u.is_player:
			players += 1
		else:
			enemies += 1
	var sel := get_tree().get_first_node_in_group("selection_manager") as SelectionManager
	var sel_text := "Selected: 0"
	var mode := ""
	if sel != null:
		var n := sel.selected_count()
		if n > 0:
			sel_text = "Selected: %d (avg HP %d%%)" % [n, int(sel.selected_avg_hp() * 100.0)]
		if sel.attack_move_pending:
			mode = " [A: click target]"
	fps_label.text = "FPS: %d" % fps
	units_label.text = "Units: P %d / E %d" % [players, enemies]
	selected_label.text = sel_text
	mode_label.text = "LMB select | Drag box | Shift add | RMB move/attack | A+click attack-move | Esc pause" + mode


func _map() -> Node:
	return get_tree().get_first_node_in_group("phase1_map")


func _on_add() -> void:
	var m := _map()
	if m != null and m.has_method("add_skirmish_units"):
		m.call("add_skirmish_units", 25)


func _on_max() -> void:
	var m := _map()
	if m != null and m.has_method("set_skirmish_units"):
		m.call("set_skirmish_units", 50)


func _on_reset() -> void:
	var m := _map()
	if m != null and m.has_method("reset_skirmish"):
		m.call("reset_skirmish")
