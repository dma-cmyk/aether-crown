extends SceneTree
## Phase 2.5C airship production asset test.
## Usage: godot --headless --path game --script res://tests/phase25c_test.gd

const ANCHORS := [
	"muzzle", "weapon_l", "weapon_r", "reactor_anchor",
	"engine_l", "engine_r", "exhaust_l", "exhaust_r",
	"thruster_l", "thruster_r", "bow_lens", "bridge_anchor",
]

var _frame := 0
var _showcase: Node


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase25c_airship_showcase.tscn")


func _fail(message: String) -> bool:
	print("PHASE25C_TEST NG ", message)
	quit(1)
	return true


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	_showcase = get_first_node_in_group("airship_showcase")
	if _showcase == null:
		return _fail("showcase missing")
	var airship := _showcase.get_node_or_null("AirshipRoot/AirshipAsset") as Node3D
	if airship == null:
		return _fail("AirshipAsset missing")
	var meshes := _find_type(airship, "GeometryInstance3D")
	if meshes.size() != 8:
		return _fail("want 8 material meshes, got %d" % meshes.size())
	for anchor_name in ANCHORS:
		if airship.find_child(anchor_name, true, true) == null:
			return _fail(anchor_name + " missing")
	# The airship must stay clearly larger than the Titan it flies over.
	var bounds := _local_aabb(airship)
	if bounds.size.z < 30.0:
		return _fail("airship length %.2f below 30m" % bounds.size.z)
	if bounds.size.x < 12.0:
		return _fail("airship width %.2f below 12m" % bounds.size.x)
	if _showcase.get_node_or_null("TitanRoot/TitanScaleReference") == null:
		return _fail("titan scale reference missing")
	if _showcase.get_node("UnitsRoot").get_child_count() != 6:
		return _fail("want 6 scale units")
	print("PHASE25C_TEST OK meshes=8 anchors=%d length=%.2f width=%.2f height=%.2f" % [
		ANCHORS.size(), bounds.size.z, bounds.size.x, bounds.size.y
	])
	quit(0)
	return true


## Measured in the airship's own space: the showcase yaws the asset for
## review, and a world AABB would shrink the reported length.
func _local_aabb(root: Node3D) -> AABB:
	var to_local := root.global_transform.affine_inverse()
	var out := AABB()
	var first := true
	for item in _find_type(root, "VisualInstance3D"):
		var vis := item as VisualInstance3D
		var world := (to_local * vis.global_transform) * vis.get_aabb()
		if first:
			out = world
			first = false
		else:
			out = out.merge(world)
	return out


func _find_type(node: Node, type_name: String) -> Array:
	var result: Array = []
	if node.is_class(type_name):
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_type(child, type_name))
	return result
