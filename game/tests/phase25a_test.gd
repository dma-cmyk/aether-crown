extends SceneTree
## Phase 2.5A showcase test (headless). Verifies the art showcase scene
## loads: representative city + 2 district assets present, 2 fixed
## territories with a hard frontline, 5v5 skirmish running, no errors.
## Usage: godot --headless --path game --script res://tests/phase25a_test.gd

var _frame: int = 0
var _map: Node = null


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase25a_showcase.tscn")


func _fail(message: String) -> bool:
	print("PHASE25A_TEST NG ", message)
	quit(1)
	return true


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 10:
		return false
	if _frame == 10:
		_map = get_first_node_in_group("art_showcase")
		if _map == null:
			return _fail("showcase map missing")
		for path in ["CivicCore", "Industry", "AetherWorks", "TerritoryController", "GroundRoot", "UnitsRoot"]:
			if _map.get_node_or_null(path) == null:
				return _fail(path + " missing")
		var ctrl := _map.get_node("TerritoryController") as TerritoryController
		if ctrl.regions.size() != 2:
			return _fail("want 2 territories")
		var hard := false
		for p in ctrl.frontline_pairs():
			if bool((p as Array)[2]):
				hard = true
		if not hard:
			return _fail("no hard frontline")
		var n := 0
		for o in get_nodes_in_group("rts_units"):
			var u := o as RTSUnit
			if u != null and u.is_alive():
				n += 1
		if n != 10:
			return _fail("want 10 units, got %d" % n)
		print("PHASE25A_TEST ok: city + 2 districts + 2 territories (hard frontline) + 10 units")
	if _frame > 400:
		print("PHASE25A_TEST OK")
		quit(0)
		return true
	return false
