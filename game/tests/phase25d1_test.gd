extends SceneTree
## Phase 2.5D.1 Ironstride production test: VisualWalker wrappers load
## with LOD0/LOD1 (4 groups + 4 pivots), 2-box collision, selection
## markers, faction plates, 8 anchors, sane bounds (infantry < walker <
## titan), both factions, default scale, forced + auto LOD switch.
## Usage: godot --headless --path game --script res://tests/phase25d1_test.gd

const GLB_ANCHORS := [
	"muzzle", "center_anchor", "reactor_anchor",
	"exhaust_l", "exhaust_r", "weapon_secondary", "piston_l", "piston_r",
]
const PIVOTS := ["leg_l_pivot", "leg_r_pivot", "turret_pivot", "hull_pivot"]

var _frame := 0
var _showcase: Node
var _blue: VisualWalker
var _red: VisualWalker
var _phase := 0
var _wait := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase25d1_walker_production.tscn")


func _fail(message: String) -> bool:
	print("PHASE25D1_TEST NG ", message)
	quit(1)
	return true


func _meshes(node: Node) -> Array:
	var result: Array = []
	if node is GeometryInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_meshes(child))
	return result


func _check_walker(w: VisualWalker, tag: String) -> bool:
	if w == null or not (w is VisualWalker):
		return _fail(tag + " is not VisualWalker")
	if not w.scale.is_equal_approx(Vector3.ONE):
		return _fail(tag + " production scale must stay 1.0")
	var lod0_meshes := _meshes(w.get("_visual_lod0") as Node)
	var lod1_meshes := _meshes(w.get("_visual_lod1") as Node)
	if lod0_meshes.size() != 4:
		return _fail(tag + " want LOD0 4 groups, got %d" % lod0_meshes.size())
	if lod1_meshes.size() != 4:
		return _fail(tag + " want LOD1 4 groups, got %d" % lod1_meshes.size())
	for anchor_name in GLB_ANCHORS + PIVOTS:
		var a0 := (w.get("_visual_lod0") as Node3D).find_child(anchor_name, true, true) as Node3D
		var a1 := (w.get("_visual_lod1") as Node3D).find_child(anchor_name, true, true) as Node3D
		if a0 == null or a1 == null:
			return _fail(tag + " " + anchor_name + " missing in LOD0/LOD1")
		if (a0 as Node3D).position.distance_to((a1 as Node3D).position) > 0.05:
			return _fail(tag + " " + anchor_name + " LOD0/LOD1 mismatch")
	# Muzzle must sit forward of the hull (weapon FX hookup sanity).
	var muzzle := w.find_anchor("muzzle")
	if muzzle == null:
		return _fail(tag + " find_anchor(muzzle) failed")
	var shapes := 0
	for c in w.get_children():
		if c is CollisionShape3D:
			shapes += 1
	if shapes != 2:
		return _fail(tag + " want 2 collision shapes, got %d" % shapes)
	if w.get("_ring") == null or w.get("_hp_bg") == null:
		return _fail(tag + " selection markers missing")
	var plates := 0
	for c in w.get_children():
		var cn := c.name as String
		if cn == "FactionPlateL" or cn == "FactionPlateR":
			plates += 1
	if plates != 2:
		return _fail(tag + " want 2 faction plates, got %d" % plates)
	if w.get("_healthbar_anchor") == null:
		return _fail(tag + " healthbar_anchor missing")
	return false


func _check_static() -> bool:
	_blue = _showcase.get_node_or_null("WalkerRoot/WalkerBlue") as VisualWalker
	_red = _showcase.get_node_or_null("WalkerRoot/WalkerRed") as VisualWalker
	if _check_walker(_blue, "blue"):
		return true
	if _check_walker(_red, "red"):
		return true
	if not _blue.is_player or _red.is_player:
		return _fail("faction flags wrong")
	# Scale hierarchy: infantry 1.8 < walker 4.54 < titan 11.39.
	# LOD meshes store pivot-relative vertices, so measure world AABBs.
	# Height is yaw-invariant; footprint uses the max horizontal extent.
	var bounds := AABB()
	var first := true
	for m in _meshes(_blue.get("_visual_lod0") as Node):
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var mbox: AABB = mi.global_transform * mi.mesh.get_aabb()
		if first:
			bounds = mbox
			first = false
		else:
			bounds = bounds.merge(mbox)
	if bounds.size.y < 4.0 or bounds.size.y > 5.2:
		return _fail("walker height %.2f outside 4.0-5.2" % bounds.size.y)
	var foot := maxf(bounds.size.x, bounds.size.z)
	if foot < 3.0 or foot > 4.8:
		return _fail("walker footprint %.2f outside 3.0-4.8" % foot)
	if bounds.position.y < -0.05:
		return _fail("walker below ground")
	# Player walker selectable, enemy not; no take_damage yet (combat scope).
	var sel := SelectionManager.new()
	root.add_child(sel)
	if not bool(sel.call("_is_owned_selectable", _blue)):
		sel.queue_free()
		return _fail("player walker not selectable")
	if bool(sel.call("_is_owned_selectable", _red)):
		sel.queue_free()
		return _fail("enemy walker must not be selectable")
	# Player walker selectable, enemy not. Phase 2.6: walkers expose
	# take_damage + order API (RTSUnit parity) for combat.
	if _red.has_method("take_damage") == false:
		sel.queue_free()
		return _fail("walker must expose take_damage (Phase 2.6)")
	if not _red.has_method("order_move") or not _red.has_method("order_attack"):
		sel.queue_free()
		return _fail("walker must expose order API (Phase 2.6)")
	if _red.max_hp < 100.0:
		sel.queue_free()
		return _fail("walker HP must come from gf_walker.tres")
	sel.queue_free()
	print("PHASE25D1_STATIC OK groups=4 anchors=8 pivots=4 collision=2 height=%.2f" % bounds.size.y)
	return false


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	_showcase = get_first_node_in_group("walker_production_showcase")
	if _showcase == null:
		return _fail("showcase missing")
	if _phase == 0:
		if _check_static():
			return true
		_phase = 1
		_blue.set_lod(1)
		_wait = 5
		return false
	if _phase == 1:
		_wait -= 1
		if _wait > 0:
			return false
		if _blue.lod_level != 1:
			return _fail("set_lod(1) did not hold")
		if (_blue.get("_visual_lod0") as Node3D).visible:
			return _fail("LOD0 still visible at lod 1")
		if not (_blue.get("_visual_lod1") as Node3D).visible:
			return _fail("LOD1 hidden at lod 1")
		if _blue.find_anchor("muzzle") == null:
			return _fail("muzzle lost after LOD swap")
		_phase = 2
		# Auto-switch: far view must settle on LOD1 by itself.
		_blue.unlock_lod()
		_showcase.call("_set_view", 60.0, Vector3.ZERO)
		_wait = 40
		return false
	if _phase == 2:
		_wait -= 1
		if _wait > 0:
			return false
		if _blue.lod_level != 1:
			return _fail("auto LOD at distance 60 want 1, got %d" % _blue.lod_level)
		_phase = 3
		_showcase.call("_set_view", 12.0, Vector3(-3, 0, 0))
		_wait = 40
		return false
	if _phase == 3:
		_wait -= 1
		if _wait > 0:
			return false
		if _blue.lod_level != 0:
			return _fail("auto LOD at distance 12 want 0, got %d" % _blue.lod_level)
		print("PHASE25D1_TEST OK lod_swap=forced+auto anchors=parity collision=2")
		quit(0)
		return true
	return false
