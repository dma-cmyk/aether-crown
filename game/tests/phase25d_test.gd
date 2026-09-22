extends SceneTree
## Phase 2.5D production walker asset test (art-only).
## Usage: godot --headless --path game --script res://tests/phase25d_test.gd

const ANCHORS := [
	"muzzle", "center_anchor", "reactor_anchor", "exhaust_l", "exhaust_r",
	"weapon_secondary", "piston_l", "piston_r",
]
const PIVOTS := ["leg_l_pivot", "leg_r_pivot", "turret_pivot", "hull_pivot"]

var _frame := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase25d_walker_showcase.tscn")


func _fail(message: String) -> bool:
	print("PHASE25D_TEST NG ", message)
	quit(1)
	return true


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	var showcase := get_first_node_in_group("walker_showcase")
	if showcase == null:
		return _fail("showcase missing")
	var root := showcase.get_node_or_null("WalkerRoot/IronstrideHero") as Node3D
	if root == null:
		return _fail("IronstrideHero missing")
	var walker := root.get_child(0) as Node3D
	if walker == null:
		return _fail("walker GLB missing")

	# Four independently transformable groups keep walk / recoil / traverse
	# animation possible in the next pass.
	var meshes := _find_type(walker, "MeshInstance3D")
	if meshes.size() != 4:
		return _fail("want 4 group meshes, got %d" % meshes.size())
	var surfaces := 0
	var materials: Dictionary = {}
	var textures := 0
	for item in meshes:
		var mesh_instance := item as MeshInstance3D
		if (mesh_instance.get_parent() as Node3D) == null or not PIVOTS.has(mesh_instance.get_parent().name):
			return _fail("%s is not parented to a pivot" % mesh_instance.name)
		var mesh := mesh_instance.mesh
		surfaces += mesh.get_surface_count()
		for i in range(mesh.get_surface_count()):
			var material := mesh.surface_get_material(i) as BaseMaterial3D
			if material == null:
				continue
			materials[material.resource_name] = true
			for slot in [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_NORMAL,
					BaseMaterial3D.TEXTURE_ROUGHNESS, BaseMaterial3D.TEXTURE_METALLIC,
					BaseMaterial3D.TEXTURE_EMISSION]:
				if material.get_texture(slot) != null:
					textures += 1
	if surfaces != 17:
		return _fail("want 17 surfaces, got %d" % surfaces)
	if materials.size() != 5:
		return _fail("want 5 shared materials, got %d" % materials.size())
	if textures != 0:
		return _fail("want 0 textures, got %d" % textures)
	for pivot_name in PIVOTS:
		if walker.find_child(pivot_name, true, true) == null:
			return _fail(pivot_name + " missing")
	for anchor_name in ANCHORS:
		if walker.find_child(anchor_name, true, true) == null:
			return _fail(anchor_name + " missing")

	# Front is Godot +Z, matching every other Gearforge asset.
	var muzzle := walker.find_child("muzzle", true, true) as Node3D
	if muzzle.position.z <= 1.0:
		return _fail("muzzle is not forward (+Z), z=%.2f" % muzzle.position.z)

	var bounds := _local_aabb(walker)
	if bounds.size.y < 4.0 or bounds.size.y > 5.0:
		return _fail("walker height %.2f outside the 4-5m class" % bounds.size.y)
	if absf(bounds.position.y) > 0.05:
		return _fail("origin is not ground centre, base y=%.3f" % bounds.position.y)
	# Scale hierarchy: clearly above infantry, clearly below the Titan.
	var titan := showcase.get_node_or_null("TitanRoot/TitanScaleReference") as Node3D
	if titan == null:
		return _fail("titan scale reference missing")
	var titan_height := _local_aabb(titan).size.y
	if bounds.size.y >= titan_height * 0.5:
		return _fail("walker %.2f is not clearly smaller than titan %.2f" % [bounds.size.y, titan_height])
	if bounds.size.y <= 1.8 * 2.0:
		return _fail("walker %.2f is not clearly larger than infantry" % bounds.size.y)
	if showcase.get_node("UnitsRoot").get_child_count() != 6:
		return _fail("want 6 scale infantry")
	if showcase.get_node("SquadRoot").get_child_count() != 3:
		return _fail("want 3 squad walkers")

	print("PHASE25D_TEST OK meshes=4 surfaces=%d materials=5 textures=0 anchors=%d pivots=4 size=%.2fx%.2fx%.2f" % [
		surfaces, ANCHORS.size(), bounds.size.x, bounds.size.z, bounds.size.y
	])
	quit(0)
	return true


## Measured in the asset's own space so a yawed showcase pose cannot shrink it.
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
