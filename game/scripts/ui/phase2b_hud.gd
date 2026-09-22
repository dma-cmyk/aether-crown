extends CanvasLayer
## Phase 2B territory-war HUD: phase2a_hud plus an Aether line in the top bar
## and a Territories box (counts + one status line per region). Phase 2A HUD
## untouched.

var _map: Node3D
var _eco_p: RTSEconomy
var _eco_e: RTSEconomy
var _queue_p: ProductionQueue
var _match: MatchManager
var _sel: SelectionManager
var _strat: EnemyStrategist
var _defs: Array[UnitDefinition] = []
var _hq_selected: RTSBuilding

var _accum: float = 0.0
var _toast_left: float = 0.0

@onready var _mat_label: Label = $TopBar/MatLabel
@onready var _ae_label: Label = $TopBar/AetherLabel
@onready var _pop_label: Label = $TopBar/PopLabel
@onready var _time_label: Label = $TopBar/TimeLabel
@onready var _fps_label: Label = $DebugBox/FpsLabel
@onready var _units_label: Label = $DebugBox/UnitsLabel
@onready var _ai_label: Label = $DebugBox/AiLabel
@onready var _cities_summary: Label = $CitiesBox/CitiesSummary
@onready var _city_line0: Label = $CitiesBox/CityLine0
@onready var _city_line1: Label = $CitiesBox/CityLine1
@onready var _city_line2: Label = $CitiesBox/CityLine2
@onready var _terr_summary: Label = $TerritoryBox/TerritorySummary
@onready var _terr_lines: Array = [
	$TerritoryBox/TerrLine0, $TerritoryBox/TerrLine1, $TerritoryBox/TerrLine2,
	$TerritoryBox/TerrLine3, $TerritoryBox/TerrLine4,
]
@onready var _sel_panel: PanelContainer = $SelPanel
@onready var _sel_title: Label = $SelPanel/SelVBox/SelTitle
@onready var _sel_info: Label = $SelPanel/SelVBox/SelInfo
@onready var _prod_row: HBoxContainer = $SelPanel/SelVBox/ProdRow
@onready var _prod_status: Label = $SelPanel/SelVBox/ProdStatus
@onready var _toast_label: Label = $ToastLabel
@onready var _overlay: Control = $EndOverlay
@onready var _result_label: Label = $EndOverlay/Center/EndVBox/ResultLabel


func _ready() -> void:
	($SelPanel/SelVBox/ProdRow/BtnInf as Button).pressed.connect(_produce.bind(0))
	($SelPanel/SelVBox/ProdRow/BtnMar as Button).pressed.connect(_produce.bind(1))
	($SelPanel/SelVBox/ProdRow/BtnHev as Button).pressed.connect(_produce.bind(2))
	($EndOverlay/Center/EndVBox/RestartButton as Button).pressed.connect(_on_restart)
	_sel_panel.visible = false
	_overlay.visible = false
	_toast_label.visible = false


func setup(map_node: Node3D) -> void:
	_map = map_node
	_eco_p = map_node.get("economy_p") as RTSEconomy
	_eco_e = map_node.get("economy_e") as RTSEconomy
	_queue_p = map_node.get("queue_p") as ProductionQueue
	_match = map_node.get("match_mgr") as MatchManager
	_sel = map_node.get("selection") as SelectionManager
	_strat = map_node.get("strategist") as EnemyStrategist
	_defs = [
		map_node.InfantryDef as UnitDefinition,
		map_node.MarksmanDef as UnitDefinition,
		map_node.HeavyDef as UnitDefinition,
	]
	($SelPanel/SelVBox/ProdRow/BtnInf as Button).text = "Infantry (%d)" % _defs[0].cost_metal
	($SelPanel/SelVBox/ProdRow/BtnMar as Button).text = "Marksman (%d)" % _defs[1].cost_metal
	($SelPanel/SelVBox/ProdRow/BtnHev as Button).text = "Heavy (%d)" % _defs[2].cost_metal
	if _sel != null:
		_sel.selection_changed.connect(_refresh_selection)
	if _queue_p != null:
		_queue_p.queue_changed.connect(_refresh_selection)
	_refresh_selection()


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			_toast_label.visible = false
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	if _map == null:
		return
	_refresh_top()
	_refresh_debug()
	_refresh_cities()
	_refresh_territories()
	_refresh_selection()


func _refresh_top() -> void:
	_mat_label.text = "Material: %d (+%d/s)" % [int(_eco_p.material), int(_eco_p.income_per_sec())]
	_ae_label.text = "Aether: %.1f (+%.2f/s)" % [_eco_p.aether, _eco_p.aether_per_sec()]
	_pop_label.text = "Pop: %d / %d" % [_eco_p.pop_used, _eco_p.pop_max]
	_time_label.text = "Time: %s" % _match.format_time()


func _refresh_debug() -> void:
	_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
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
	_units_label.text = "Units: P %d / E %d" % [players, enemies]
	_ai_label.text = "AI: %s" % _strat.plan_name()


func _refresh_cities() -> void:
	var counts: Dictionary = _map.call("city_counts")
	_cities_summary.text = "Cities: P %d / N %d / E %d" % [
		int(counts.get("player", 0)), int(counts.get("neutral", 0)), int(counts.get("enemy", 0))]
	var lines: Array = _map.call("city_status_lines")
	var labels: Array = [_city_line0, _city_line1, _city_line2]
	for i in range(labels.size()):
		if i < lines.size():
			(labels[i] as Label).text = str(lines[i])
		else:
			(labels[i] as Label).text = ""


func _refresh_territories() -> void:
	var counts: Dictionary = _map.call("territory_counts")
	_terr_summary.text = "Territories: P %d / N %d / E %d" % [
		int(counts.get("player", 0)), int(counts.get("neutral", 0)), int(counts.get("enemy", 0))]
	var lines: Array = _map.call("territory_status_lines")
	for i in range(_terr_lines.size()):
		if i < lines.size():
			(_terr_lines[i] as Label).text = str(lines[i])
		else:
			(_terr_lines[i] as Label).text = ""


func _refresh_selection() -> void:
	_hq_selected = null
	if _sel == null or _sel.selected.is_empty():
		_sel_panel.visible = false
		return
	_sel._prune()
	if _sel.selected.is_empty():
		_sel_panel.visible = false
		return
	_sel_panel.visible = true
	var hq: RTSBuilding = null
	var units := 0
	for u in _sel.selected:
		if u is RTSBuilding:
			hq = u as RTSBuilding
		elif u is RTSUnit:
			units += 1
	if hq != null:
		_hq_selected = hq
		_sel_title.text = hq.display_name
		_sel_info.text = "HP: %d / %d" % [int(hq.hp), int(hq.max_hp)]
		_prod_row.visible = true
		_refresh_production()
	elif units > 0:
		var first := _sel.selected[0] as RTSUnit
		var uname := "Unit"
		var utype := ""
		if first != null and first.definition != null:
			uname = first.definition.display_name
			utype = str(first.definition.id)
		_sel_title.text = "%s x%d" % [uname, units]
		_sel_info.text = "Avg HP %d%%  Type: %s" % [int(_sel.selected_avg_hp() * 100.0), utype]
		_prod_row.visible = false
		_prod_status.text = ""
	else:
		_sel_panel.visible = false


func _refresh_production() -> void:
	if _hq_selected == null:
		return
	var front := _queue_p.front()
	if front == null:
		_prod_status.text = "Queue: empty"
	else:
		_prod_status.text = "%s %d%% (%ds left)  queued: %d" % [
			front.display_name,
			int(_queue_p.front_fraction() * 100.0),
			int(ceil(_queue_p.front_remaining())),
			_queue_p.queue.size(),
		]


func _produce(index: int) -> void:
	if _hq_selected == null or not is_instance_valid(_hq_selected):
		return
	if _match != null and not _match.is_playing():
		return
	var result: String = _queue_p.try_enqueue(_defs[index], _eco_p)
	match result:
		"ok":
			pass
		"no_material":
			toast("Need Material (%d)" % _defs[index].cost_metal)
		"no_pop":
			toast("Population full (%d/%d)" % [_eco_p.pop_used, _eco_p.pop_max])
		"queue_full":
			toast("Queue full (max %d)" % ProductionQueue.MAX_QUEUED)
	_refresh_selection()


func _unhandled_input(event: InputEvent) -> void:
	if _hq_selected == null or not is_instance_valid(_hq_selected):
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		match (event as InputEventKey).keycode:
			KEY_1:
				_produce(0)
			KEY_2:
				_produce(1)
			KEY_3:
				_produce(2)


func toast(message: String) -> void:
	_toast_label.text = message
	_toast_label.visible = true
	_toast_left = 3.0


func show_end(player_won: bool) -> void:
	_result_label.text = "VICTORY" if player_won else "DEFEAT"
	_result_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if player_won else Color(1.0, 0.35, 0.3))
	_overlay.visible = true


func _on_restart() -> void:
	if _match != null:
		_match.restart()
