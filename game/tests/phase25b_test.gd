extends SceneTree
## Phase 2.5B Titan production asset test.
## Usage: godot --headless --path game --script res://tests/phase25b_test.gd

var _frame := 0
var _showcase: Node


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase25b_titan_showcase.tscn")


func _fail(message: String) -> bool:
	print("PHASE25B_TEST NG ", message)
	quit(1)
	return true


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	_showcase = get_first_node_in_group("titan_showcase")
	if _showcase == null:
		return _fail("showcase missing")
	var titan := _showcase.get_node_or_null("TitanRoot/TitanAsset") as Node3D
	if titan == null:
		return _fail("TitanAsset missing")
	var meshes := _find_type(titan, "GeometryInstance3D")
	if meshes.size() != 8:
		return _fail("want 8 material meshes, got %d" % meshes.size())
	for anchor_name in ["muzzle", "reactor_anchor", "exhaust_l", "exhaust_r"]:
		if titan.find_child(anchor_name, true, true) == null:
			return _fail(anchor_name + " missing")
	if _showcase.get_node("UnitsRoot").get_child_count() != 6:
		return _fail("want 6 scale units")
	if _showcase.get_node_or_null("SetDressing/CivicScaleReference") == null:
		return _fail("civic scale reference missing")
	if _showcase.get_node_or_null("SetDressing/IndustryScaleReference") == null:
		return _fail("industry scale reference missing")
	print("PHASE25B_TEST OK meshes=8 anchors=4 units=6 buildings=2")
	quit(0)
	return true


func _find_type(node: Node, type_name: String) -> Array:
	var result: Array = []
	if node.is_class(type_name):
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_type(child, type_name))
	return result
