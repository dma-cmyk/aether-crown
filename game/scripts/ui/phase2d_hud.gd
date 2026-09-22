extends CanvasLayer
## Phase 2D strategic-match HUD: phase2c_hud with clipping fixes (build
## buttons stacked vertically, district panel bottom-anchored) plus a
## one-line strategic overview. World-click selection untouched.

var _map: Node3D
var _eco_p: RTSEconomy
var _eco_e: RTSEconomy
var _queue_p: ProductionQueue
var _match: MatchManager
var _sel: SelectionManager
var _strat: EnemyStrategist
var _defs: Array[UnitDefinition] = []
var _hq_selected: RTSBuilding
var _mgmt_city: String = "west_foundry"
var _debug_visible: bool = false

var _accum: float = 0.0
var _toast_left: float = 0.0

@onready var _mat_label: Label = $TopBar/MatLabel
@onready var _ae_label: Label = $TopBar/AetherLabel
@onready var _pop_label: Label = $TopBar/PopLabel
@onready var _time_label: Label = $TopBar/TimeLabel
@onready var _fps_label: Label = $DebugBox/FpsLabel
@onready var _units_label: Label = $DebugBox/UnitsLabel
@onready var _ai_label: Label = $DebugBox/AiLabel
@onready var _overview_label: Label = $DebugBox/OverviewLabel
@onready var _cities_summary: Label = $CitiesBox/CitiesSummary
@onready var _city_lines: Array = [
	$CitiesBox/CityLine0, $CitiesBox/CityLine1, $CitiesBox/CityLine2,
	$CitiesBox/CityLine3, $CitiesBox/CityLine4,
]
@onready var _terr_summary: Label = $TerritoryBox/TerritorySummary
@onready var _terr_lines: Array = [
	$TerritoryBox/TerrLine0, $TerritoryBox/TerrLine1, $TerritoryBox/TerrLine2,
	$TerritoryBox/TerrLine3, $TerritoryBox/TerrLine4, $TerritoryBox/TerrLine5,
	$TerritoryBox/TerrLine6,
]
@onready var _dist_info: Label = $DistrictBox/DistInfo
@onready var _dist_slot0: Label = $DistrictBox/DistSlot0
@onready var _dist_slot1: Label = $DistrictBox/DistSlot1
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
	($SelPanel/SelVBox/ProdRow/BtnWal as Button).pressed.connect(_produce.bind(3))
	($EndOverlay/Center/EndVBox/RestartButton as Button).pressed.connect(_on_restart)
	($DistrictBox/CityRow/BtnW as Button).pressed.connect(_mgmt_select.bind("west_foundry"))
	($DistrictBox/CityRow/BtnN as Button).pressed.connect(_mgmt_select.bind("north_relay"))
	($DistrictBox/CityRow/BtnC as Button).pressed.connect(_mgmt_select.bind("central_nexus"))
	($DistrictBox/CityRow/BtnS as Button).pressed.connect(_mgmt_select.bind("south_works"))
	($DistrictBox/CityRow/BtnE as Button).pressed.connect(_mgmt_select.bind("east_bastion"))
	($DistrictBox/BuildCol/BtnIndustry as Button).pressed.connect(_mgmt_build.bind("industry"))
	($DistrictBox/BuildCol/BtnMilitary as Button).pressed.connect(_mgmt_build.bind("military"))
	($DistrictBox/BuildCol/BtnAether as Button).pressed.connect(_mgmt_build.bind("aether_works"))
	_sel_panel.visible = false
	_overlay.visible = false
	_toast_label.visible = false
	$DebugBox.visible = false


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
		map_node.WalkerDef as UnitDefinition,
	]
	($SelPanel/SelVBox/ProdRow/BtnInf as Button).text = "Infantry (%d)" % _defs[0].cost_metal
	($SelPanel/SelVBox/ProdRow/BtnMar as Button).text = "Marksman (%dM/%dA)" % [_defs[1].cost_metal, _defs[1].cost_aether]
	($SelPanel/SelVBox/ProdRow/BtnHev as Button).text = "Heavy (%dM/%dA)" % [_defs[2].cost_metal, _defs[2].cost_aether]
	($SelPanel/SelVBox/ProdRow/BtnWal as Button).text = "Walker (%dM/%dA)" % [_defs[3].cost_metal, _defs[3].cost_aether]
	var ind := map_node.IndustryDef as DistrictDefinition
	var mil := map_node.MilitaryDef as DistrictDefinition
	var aew := map_node.AetherWorksDef as DistrictDefinition
	($DistrictBox/BuildCol/BtnIndustry as Button).text = "Industry (%dM/%dA)" % [ind.material_cost, ind.aether_cost]
	($DistrictBox/BuildCol/BtnMilitary as Button).text = "Military (%dM/%dA)" % [mil.material_cost, mil.aether_cost]
	($DistrictBox/BuildCol/BtnAether as Button).text = "Aether (%dM/%dA)" % [aew.material_cost, aew.aether_cost]
	if _sel != null:
		_sel.selection_changed.connect(_refresh_selection)
	if _queue_p != null:
		_queue_p.queue_changed.connect(_refresh_selection)
	_refresh_selection()


func mgmt_city() -> String:
	return _mgmt_city


func _mgmt_select(city_id: String) -> void:
	_mgmt_city = city_id
	_refresh_districts()


func _mgmt_build(district_id: String) -> void:
	if _map == null:
		return
	var result: String = _map.call("try_build_player", _mgmt_city, district_id)
	if result != "ok":
		toast("Build rejected: %s" % result)
	_refresh_districts()


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
	# Overview text is gameplay info (frontline read), so it stays fresh
	# even while the rest of the debug box is hidden behind F3.
	_refresh_debug()
	_refresh_cities()
	_refresh_territories()
	_refresh_districts()
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
	_overview_label.text = _map.call("strategic_overview")


func _refresh_cities() -> void:
	var counts: Dictionary = _map.call("city_counts")
	_cities_summary.text = "Cities: P %d / N %d / E %d" % [
		int(counts.get("player", 0)), int(counts.get("neutral", 0)), int(counts.get("enemy", 0))]
	var lines: Array = _map.call("city_status_lines")
	for i in range(_city_lines.size()):
		if i < lines.size():
			(_city_lines[i] as Label).text = str(lines[i])
		else:
			(_city_lines[i] as Label).text = ""


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


func _refresh_districts() -> void:
	var city := _map.call("get_city", _mgmt_city) as RTSCity
	if city == null:
		_dist_info.text = "Districts: --"
		_dist_slot0.text = ""
		_dist_slot1.text = ""
		return
	_dist_info.text = "Districts: %s (%s)" % [city.display_name, city.owner_name()]
	var texts: Array = _map.call("district_slot_texts", _mgmt_city)
	_dist_slot0.text = str(texts[0]) if texts.size() > 0 else ""
	_dist_slot1.text = str(texts[1]) if texts.size() > 1 else ""


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
		elif u is RTSUnit or u is VisualWalker:
			units += 1
	if hq != null:
		_hq_selected = hq
		_sel_title.text = hq.display_name
		_sel_info.text = "HP: %d / %d" % [int(hq.hp), int(hq.max_hp)]
		_prod_row.visible = true
		_refresh_production()
	elif units > 0:
		var first: Node = _sel.selected[0]
		var uname := "Unit"
		var utype := ""
		if first is RTSUnit and (first as RTSUnit).definition != null:
			uname = (first as RTSUnit).definition.display_name
			utype = str((first as RTSUnit).definition.id)
		elif first is VisualWalker:
			uname = "Ironstride Walker"
			utype = "gf_walker"
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
		"no_aether":
			toast("Need Aether (%d)" % _defs[index].cost_aether)
		"no_pop":
			toast("Population full (%d/%d)" % [_eco_p.pop_used, _eco_p.pop_max])
		"queue_full":
			toast("Queue full (max %d)" % ProductionQueue.MAX_QUEUED)
	_refresh_selection()


func _unhandled_input(event: InputEvent) -> void:
	# Debug readouts are opt-in (Phase 2.8): F3 toggles FPS/AI/unit debug
	# so the normal HUD stays on gameplay info only.
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_F3:
			_debug_visible = not _debug_visible
			$DebugBox.visible = _debug_visible
			return
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
			KEY_4:
				_produce(3)


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
