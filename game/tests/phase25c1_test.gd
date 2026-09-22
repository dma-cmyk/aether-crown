extends SceneTree
## Phase 2.5C.1 Crownhammer production test: VisualAirship wrapper loads
## with LOD0/LOD1, 3-box collision, selection markers, 12 GLB + 3 code
## anchors, sane bounds, no ground penetration, faction + default scale,
## forced + auto LOD switch.
## Usage: godot --headless --path game --script res://tests/phase25c1_test.gd

const GLB_ANCHORS := [
	"muzzle", "weapon_l", "weapon_r", "reactor_anchor",
	"engine_l", "engine_r", "exhaust_l", "exhaust_r",
	"thruster_l", "thruster_r", "bow_lens", "bridge_anchor",
]
const CODE_ANCHORS := ["center_anchor", "selection_anchor", "healthbar_anchor"]

var _frame := 0
var _showcase: Node
var _ship: VisualAirship
var _phase := 0
var _wait := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase25c1_airship_production.tscn")


func _fail(message: String) -> bool:
	print("PHASE25C1_TEST NG ", message)
	quit(1)
	return true


func _meshes(node: Node) -> Array:
	var result: Array = []
	if node is GeometryInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_meshes(child))
	return result


func _check_static() -> bool:
	_ship = _showcase.get_node_or_null("ShipRoot/ProductionShip") as VisualAirship
	if _ship == null or not (_ship is VisualAirship):
		return _fail("ship is not VisualAirship")
	# Production defaults: full-size hull, gameplay cruise. Bombard stays
	# armed by default (the showcase disables it locally; prototype too).
	var fresh := VisualAirship.new()
	if not fresh.bombard_enabled:
		fresh.queue_free()
		return _fail("bombard must stay armed by default")
	if not is_equal_approx(fresh.cruise_height, 26.0):
		fresh.queue_free()
		return _fail("cruise height default changed")
	fresh.queue_free()
	if not _ship.scale.is_equal_approx(Vector3.ONE):
		return _fail("production scale must stay 1.0")
	if not _ship.is_player:
		return _fail("showcase ship must be player faction")
	var lod0_meshes := _meshes(_ship.get("_visual_lod0") as Node)
	var lod1_meshes := _meshes(_ship.get("_visual_lod1") as Node)
	if lod0_meshes.size() != 8:
		return _fail("want LOD0 8 meshes, got %d" % lod0_meshes.size())
	if lod1_meshes.size() != 6:
		return _fail("want LOD1 6 meshes, got %d" % lod1_meshes.size())
	for anchor_name in GLB_ANCHORS:
		var a0 := (_ship.get("_visual_lod0") as Node3D).find_child(anchor_name, true, true) as Node3D
		var a1 := (_ship.get("_visual_lod1") as Node3D).find_child(anchor_name, true, true) as Node3D
		if a0 == null or a1 == null:
			return _fail(anchor_name + " missing in LOD0/LOD1")
		if (a0 as Node3D).position.distance_to((a1 as Node3D).position) > 0.05:
			return _fail(anchor_name + " LOD0/LOD1 mismatch")
	for anchor_name in CODE_ANCHORS:
		if _ship.get_node_or_null(anchor_name) == null:
			return _fail(anchor_name + " missing")
	var body := _ship.get_node_or_null("CollisionBody") as StaticBody3D
	if body == null:
		return _fail("CollisionBody missing")
	if body.collision_layer != 2:
		return _fail("collision layer must be 2")
	var shapes := 0
	for c in body.get_children():
		if c is CollisionShape3D:
			shapes += 1
	if shapes != 3:
		return _fail("want 3 collision shapes, got %d" % shapes)
	if _ship.get("_proj_ring") == null or _ship.get("_hp_bg") == null:
		return _fail("selection markers missing")
	# Bounds sane: clearly larger than the Titan, not absurd.
	# Mesh space: x = width (~14), z = length (~35), y = height (~11).
	var lb := _local_aabb()
	if lb.size.z < 30.0:
		return _fail("airship length %.2f below 30m" % lb.size.z)
	if lb.size.x < 12.0:
		return _fail("airship width %.2f below 12m" % lb.size.x)
	# No ground penetration at cruise.
	if _ship.global_position.y < 15.0:
		return _fail("ship too low: %.2f" % _ship.global_position.y)
	# Player airship selectable, enemy not; foe airship has no take_damage
	# so it can never become a force-attack target (combat scope excluded).
	var sel := SelectionManager.new()
	root.add_child(sel)
	if not bool(sel.call("_is_owned_selectable", _ship)):
		sel.queue_free()
		return _fail("player airship not selectable")
	var foe := VisualAirship.new()
	foe.is_player = false
	root.add_child(foe)
	if bool(sel.call("_is_owned_selectable", foe)):
		foe.queue_free()
		sel.queue_free()
		return _fail("enemy airship must not be selectable")
	if foe.has_method("take_damage"):
		foe.queue_free()
		sel.queue_free()
		return _fail("airship must not expose take_damage yet")
	foe.queue_free()
	sel.queue_free()
	print("PHASE25C1_STATIC OK lod0=8 lod1=6 collision=3 anchors=15 select=player-only")
	return false


func _local_aabb() -> AABB:
	# Showcase may yaw the ship; measure in local space via mesh AABBs.
	var box := AABB()
	var first := true
	for m in _meshes(_ship.get("_visual_lod0") as Node):
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		# Mesh AABBs are pre-transform; LOD0 parts carry no node offsets,
		# so the merged mesh space matches the ship's local frame here.
		var mbox: AABB = mi.mesh.get_aabb()
		if first:
			box = mbox
			first = false
		else:
			box = box.merge(mbox)
	return box


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	_showcase = get_first_node_in_group("airship_production_showcase")
	if _showcase == null:
		return _fail("showcase missing")
	if _phase == 0:
		if _check_static():
			return true
		_phase = 1
		_ship.set_lod(1)
		_wait = 5
		return false
	if _phase == 1:
		_wait -= 1
		if _wait > 0:
			return false
		if _ship.lod_level != 1:
			return _fail("set_lod(1) did not hold")
		if (_ship.get("_visual_lod0") as Node3D).visible:
			return _fail("LOD0 still visible at lod 1")
		if not (_ship.get("_visual_lod1") as Node3D).visible:
			return _fail("LOD1 hidden at lod 1")
		_phase = 2
		# Auto-switch: far view must settle on LOD1 by itself.
		_ship.unlock_lod()
		_showcase.call("_set_view", 70.0, Vector3.ZERO)
		_wait = 40
		return false
	if _phase == 2:
		_wait -= 1
		if _wait > 0:
			return false
		if _ship.lod_level != 1:
			return _fail("auto LOD at distance 70 want 1, got %d" % _ship.lod_level)
		print("PHASE25C1_TEST OK lod_swap=forced+auto anchors=parity collision=3")
		quit(0)
		return true
	return false
