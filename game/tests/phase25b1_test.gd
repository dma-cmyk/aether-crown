extends SceneTree
## Phase 2.5B.1 Titan productionization test: collision footprint, selection
## bounds, LOD1 asset, LOD switch, anchor parity.
## Usage: godot --headless --path game --script res://tests/phase25b1_test.gd

var _frame := 0
var _showcase: Node
var _titan: VisualTitan
var _phase := 0
var _wait := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase25b1_titan_production.tscn")


func _fail(message: String) -> bool:
	print("PHASE25B1_TEST NG ", message)
	quit(1)
	return true


func _meshes(node: Node) -> Array:
	var result: Array = []
	if node is GeometryInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_meshes(child))
	return result


func _collision_cylinder() -> CylinderShape3D:
	for c in _titan.get_children():
		var cs := c as CollisionShape3D
		if cs != null and cs.shape is CylinderShape3D:
			return cs.shape as CylinderShape3D
	return null


func _check_static() -> bool:
	_titan = _showcase.get_node_or_null("TitanRoot").get_child(0) as VisualTitan
	if _titan == null or not (_titan is VisualTitan):
		return _fail("titan is not VisualTitan")
	var col := _collision_cylinder()
	if col == null:
		return _fail("titan collision cylinder missing")
	if not is_equal_approx(col.radius, 3.0):
		return _fail("want collision radius 3.0, got %.2f" % col.radius)
	if not is_equal_approx(col.height, 9.0):
		return _fail("want collision height 9.0, got %.2f" % col.height)
	var lod0_meshes := _meshes(_titan.get("_visual_lod0") as Node)
	var lod1_meshes := _meshes(_titan.get("_visual_lod1") as Node)
	if lod0_meshes.size() != 8:
		return _fail("want LOD0 8 meshes, got %d" % lod0_meshes.size())
	if lod1_meshes.size() != 5:
		return _fail("want LOD1 5 meshes, got %d" % lod1_meshes.size())
	for anchor_name in ["muzzle", "reactor_anchor", "exhaust_l", "exhaust_r"]:
		var a0 := (_titan.get("_visual_lod0") as Node3D).find_child(anchor_name, true, true) as Node3D
		var a1 := (_titan.get("_visual_lod1") as Node3D).find_child(anchor_name, true, true) as Node3D
		if a0 == null or a1 == null:
			return _fail(anchor_name + " missing in LOD0/LOD1")
		var p0: Vector3 = (a0 as Node3D).position
		var p1: Vector3 = (a1 as Node3D).position
		if p0.distance_to(p1) > 0.05:
			return _fail(anchor_name + " LOD0/LOD1 mismatch")
	# Player titan must be click-selectable via SelectionManager logic.
	var sel := SelectionManager.new()
	root.add_child(sel)
	if not bool(sel.call("_is_owned_selectable", _titan)):
		sel.queue_free()
		return _fail("player titan not selectable")
	var foe := VisualTitan.new()
	foe.setup(false, Vector3.ZERO, Vector3.ZERO)
	root.add_child(foe)
	if bool(sel.call("_is_owned_selectable", foe)):
		foe.queue_free()
		sel.queue_free()
		return _fail("enemy titan must not be selectable")
	foe.queue_free()
	sel.queue_free()
	print("PHASE25B1_STATIC OK collision_r=3.0 lod0_meshes=8 lod1_meshes=5 anchors=4 select=player-only")
	return false


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	_showcase = get_first_node_in_group("titan_production_showcase")
	if _showcase == null:
		return _fail("showcase missing")
	if _phase == 0:
		if _check_static():
			return true
		_phase = 1
		# Force LOD1, then verify visibility swap + muzzle stays live.
		_titan.set_lod(1)
		_wait = 5
		return false
	if _phase == 1:
		_wait -= 1
		if _wait > 0:
			return false
		if _titan.lod_level != 1:
			return _fail("set_lod(1) did not hold")
		if (_titan.get("_visual_lod0") as Node3D).visible:
			return _fail("LOD0 still visible at lod 1")
		if not (_titan.get("_visual_lod1") as Node3D).visible:
			return _fail("LOD1 hidden at lod 1")
		if _titan.get("_muzzle") == null:
			return _fail("muzzle lost after LOD swap")
		_phase = 2
		# Auto-switch: unlock at strategic distance, expect LOD1.
		_titan.unlock_lod()
		_showcase.call("_set_view", 43.0, Vector3.ZERO)
		_wait = 40
		return false
	if _phase == 2:
		_wait -= 1
		if _wait > 0:
			return false
		if _titan.lod_level != 1:
			return _fail("auto LOD at distance 43 want 1, got %d" % _titan.lod_level)
		_phase = 3
		_showcase.call("_set_view", 20.0, Vector3.ZERO)
		_wait = 40
		return false
	if _phase == 3:
		_wait -= 1
		if _wait > 0:
			return false
		if _titan.lod_level != 0:
			return _fail("auto LOD at distance 20 want 0, got %d" % _titan.lod_level)
		print("PHASE25B1_TEST OK lod_swap=forced+auto anchors=parity collision=3.0")
		quit(0)
		return true
	return false
