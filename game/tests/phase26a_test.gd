extends SceneTree
## Phase 2.6A building set foundation test: 5 GLBs load with expected mesh
## counts, ground contact, footprint bounds, RTSBuilding wrap (alive +
## selectable), showcase set row + city block present.
## Usage: godot --headless --path game --script res://tests/phase26a_test.gd

var _frame := 0
var _showcase: Node


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/phase26a_building_showcase.tscn")


func _fail(message: String) -> bool:
	print("PHASE26A_TEST NG ", message)
	quit(1)
	return true


func _meshes(node: Node) -> Array:
	var result: Array = []
	if node is GeometryInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_meshes(child))
	return result


func _bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in _meshes(node):
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var mbox: AABB = mi.mesh.get_aabb()
		mbox = mi.global_transform * mbox
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
	_showcase = get_first_node_in_group("building_showcase")
	if _showcase == null:
		return _fail("showcase missing")
	var set_row := _showcase.get_node_or_null("SetRow")
	var block := _showcase.get_node_or_null("CityBlock")
	if set_row == null or set_row.get_child_count() != 5:
		return _fail("want 5 set-row buildings")
	if block == null or block.get_child_count() != 5:
		return _fail("want 5 city-block buildings")
	# [node_name_part, want_meshes, footprint_x, footprint_z, yaw_deg, min_h, max_h]
	var specs := [
		["HQ", 6, 15.2, 13.2, 12.0, 10.0, 15.0],
		["Barracks", 6, 15.0, 8.0, -8.0, 4.0, 7.0],
		["Factory", 6, 14.0, 14.5, 5.0, 8.0, 13.0],
		["Boiler", 6, 13.0, 10.0, -6.0, 8.0, 12.0],
		["Aether", 6, 9.0, 9.0, 10.0, 9.0, 13.0],
	]
	for spec in specs:
		var found: RTSBuilding = null
		for c in set_row.get_children():
			if (c.name as String).ends_with(spec[0]):
				found = c as RTSBuilding
		if found == null:
			return _fail("%s missing in set row" % spec[0])
		if not found.is_alive():
			return _fail("%s not alive" % spec[0])
		found.set_selected(true)
		if not found.selected:
			return _fail("%s not selectable" % spec[0])
		found.set_selected(false)
		var visual: Node3D = null
		for c in found.get_children():
			if c is Node3D and not (c is CollisionShape3D) and _meshes(c).size() > 1:
				visual = c as Node3D
		if visual == null:
			return _fail("%s GLB visual missing" % spec[0])
		var meshes := _meshes(visual)
		if meshes.size() != int(spec[1]):
			return _fail("%s want %d meshes, got %d" % [spec[0], int(spec[1]), meshes.size()])
		var bounds := _bounds(visual)
		if bounds.position.y < -0.05:
			return _fail("%s below ground: %.2f" % [spec[0], bounds.position.y])
		# Yaw expands the world-space AABB: allow the rotated expectation.
		var yaw := deg_to_rad(float(spec[4]))
		var ex := float(spec[2]) * absf(cos(yaw)) + float(spec[3]) * absf(sin(yaw)) + 0.4
		var ez := float(spec[2]) * absf(sin(yaw)) + float(spec[3]) * absf(cos(yaw)) + 0.4
		if bounds.size.x > ex or bounds.size.z > ez:
			return _fail("%s footprint overflow: %s want (%s, %s)" % [spec[0], str(bounds.size), str(ex), str(ez)])
		if bounds.size.y < float(spec[5]) or bounds.size.y > float(spec[6]):
			return _fail("%s height out of range: %.2f" % [spec[0], bounds.size.y])
		var col_found := false
		for c in found.get_children():
			if c is CollisionShape3D:
				col_found = true
		if not col_found:
			return _fail("%s collision missing" % spec[0])
	var titan := _showcase.get_node_or_null("UnitsRoot/ScaleTitan")
	if titan == null:
		return _fail("scale titan missing")
	print("PHASE26A_TEST OK set=5 block=5 meshes=6x5 select+collision OK")
	quit(0)
	return true
