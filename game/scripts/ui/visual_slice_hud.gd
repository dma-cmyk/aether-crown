extends CanvasLayer
## Visual Slice HUD (Phase 1.75): product-look direction check only.
## Shows Material / Population / selection info / command hints / faction
## identity + FPS + unit/FX counts. No economy/production logic.

var _map: Node3D = null

var _accum: float = 0.0
var _mat_value: float = 120.0

@onready var _mat_label: Label = $TopBar/MatLabel
@onready var _pop_label: Label = $TopBar/PopLabel
@onready var _faction_label: Label = $TopBar/FactionLabel
@onready var _fps_label: Label = $DebugBox/FpsLabel
@onready var _units_label: Label = $DebugBox/UnitsLabel
@onready var _fx_label: Label = $DebugBox/FxLabel
@onready var _sel_panel: PanelContainer = $SelPanel
@onready var _sel_title: Label = $SelPanel/SelVBox/SelTitle
@onready var _sel_info: Label = $SelPanel/SelVBox/SelInfo
@onready var _sel: SelectionManager = null


func setup(map_node: Node3D) -> void:
	_map = map_node
	_sel = map_node.get("selection") as SelectionManager
	if _sel != null:
		_sel.selection_changed.connect(_refresh_selection)
	($CmdBox/CmdAttack as Button).pressed.connect(_cmd_attack_mid)
	($CmdBox/CmdHold as Button).pressed.connect(_cmd_hold)
	_refresh_selection()


func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	if _map == null:
		return
	_refresh_top()
	_refresh_debug()
	_refresh_selection()


func _counts() -> Array:
	var p := 0
	var e := 0
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u == null or not u.is_alive():
			continue
		if u.is_player:
			p += 1
		else:
			e += 1
	var titan_alive := 0
	for o in get_tree().get_nodes_in_group("visual_titans"):
		var t := o as Node
		if t != null and bool(t.call("is_alive")):
			titan_alive += 1
	return [p, e, titan_alive]


func _refresh_top() -> void:
	_mat_value = float(_map.get("material_demo"))
	var c := _counts()
	_mat_label.text = "Material: %d (+2/s)" % int(_mat_value)
	_pop_label.text = "Pop: %d / %d" % [c[0], POP_MAX]
	_faction_label.text = "GEARFORGE // VISUAL SLICE"


const POP_MAX: int = 40


func _refresh_debug() -> void:
	var c := _counts()
	_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	_units_label.text = "Units: P %d / E %d  Titan x%d" % [c[0], c[1], c[2]]
	_fx_label.text = "FX: %d live, %d vents" % [VisualFX.live_count(), VisualFX.emitter_count()]


func _refresh_selection() -> void:
	if _sel == null:
		_sel_panel.visible = false
		return
	_sel._prune()
	if _sel.selected.is_empty():
		_sel_panel.visible = false
		return
	_sel_panel.visible = true
	var units := 0
	var titan_sel := false
	var first: RTSUnit = null
	for u in _sel.selected:
		if u is RTSUnit:
			units += 1
			if first == null:
				first = u as RTSUnit
		elif u is VisualTitan:
			titan_sel = true
	if titan_sel:
		var t := _map.get("titan") as VisualTitan
		if t != null:
			_sel_title.text = "Aether Siege Engine (Titan)"
			_sel_info.text = "HP: %d / %d  Cannon: AoE  |  Slow patrol, hold near city" % [int(t.hp), int(t.max_hp)]
		else:
			_sel_title.text = "Titan"
			_sel_info.text = "--"
	elif units > 0 and first != null:
		var uname := "Unit"
		var utype := ""
		if first.definition != null:
			uname = first.definition.display_name
			utype = str(first.definition.id)
		_sel_title.text = "%s x%d" % [uname, units]
		_sel_info.text = "Avg HP %d%%  Type: %s" % [int(_sel.selected_avg_hp() * 100.0), utype]
	else:
		_sel_panel.visible = false


func _cmd_attack_mid() -> void:
	if _map == null:
		return
	var orders: OrderManager = _map.get("orders") as OrderManager
	var sel: SelectionManager = _map.get("selection") as SelectionManager
	if orders == null or sel == null or sel.selected.is_empty():
		return
	sel._prune()
	orders.issue_attack_move(sel.selected, Vector3(2, 0, 2))


func _cmd_hold() -> void:
	if _map == null:
		return
	var sel: SelectionManager = _map.get("selection") as SelectionManager
	if sel == null or sel.selected.is_empty():
		return
	sel._prune()
	for u in sel.selected:
		if u is RTSUnit:
			(u as RTSUnit).order_move((u as RTSUnit).global_position)
