class_name HqVisual
extends RefCounted
## Steampunk HQ look from Godot primitives only (Phase 1.5 placeholder).
## Shared by player and enemy HQs; faction tint is the only difference.
## Footprint ~7x6m, height ~6m — clearly bigger than infantry.

const SIZE := Vector3(7.0, 6.0, 6.0)


static func faction_colors(player_flag: bool) -> Dictionary:
	if player_flag:
		return {
			"trim": Color(0.20, 0.45, 0.95, 1.0),
			"trim_dark": Color(0.12, 0.28, 0.65, 1.0),
			"banner": Color(0.25, 0.55, 1.0, 1.0),
		}
	return {
		"trim": Color(0.92, 0.26, 0.20, 1.0),
		"trim_dark": Color(0.62, 0.14, 0.12, 1.0),
		"banner": Color(1.0, 0.30, 0.22, 1.0),
	}


static func _mat(color: Color, rough: float = 0.7, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


static func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bot
	mesh.height = h
	mesh.radial_segments = 12
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## Builds the visual + collision under `root` (an RTSBuilding). y=0 is ground.
static func build(root: RTSBuilding, player_flag: bool) -> void:
	var c := faction_colors(player_flag)
	var brass := _mat(Color(0.55, 0.42, 0.22, 1.0), 0.55)
	var iron := _mat(Color(0.22, 0.23, 0.26, 1.0), 0.8)
	var copper := _mat(Color(0.72, 0.38, 0.20, 1.0), 0.5)
	var trim: StandardMaterial3D = _mat(c["trim"], 0.6)
	var trim_dark: StandardMaterial3D = _mat(c["trim_dark"], 0.7)
	var glow: StandardMaterial3D = _mat(c["banner"], 0.4, 1.5)
	var glass := _mat(Color(1.0, 0.85, 0.45, 1.0), 0.3, 1.2)

	# Base pad
	_box(root, Vector3(9.0, 0.25, 8.0), Vector3(0, 0.12, 0), _mat(Color(0.16, 0.16, 0.18, 1.0), 0.9))
	_box(root, Vector3(9.2, 0.1, 8.2), Vector3(0, 0.3, 0), trim_dark)

	# Main hall + roof
	_box(root, Vector3(5.0, 3.0, 4.2), Vector3(-0.6, 1.8, 0), brass)
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(5.4, 1.4, 4.6)
	roof.mesh = prism
	roof.position = Vector3(-0.6, 4.0, 0)
	roof.material_override = iron
	root.add_child(roof)

	# Boiler tank (horizontal cylinder, steampunk core)
	var tank := _cyl(root, 1.1, 1.1, 3.2, Vector3(2.6, 1.6, 0.6), copper)
	tank.rotation.z = PI * 0.5
	for bx in [-1.0, 1.0]:
		var band := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.08
		torus.outer_radius = 1.22
		band.mesh = torus
		band.position = Vector3(2.6 + bx, 1.6, 0.6)
		band.rotation.y = PI * 0.5
		band.material_override = iron
		root.add_child(band)

	# Chimneys with glowing tops
	for cx in [Vector3(-2.2, 0, -1.2), Vector3(-2.2, 0, 1.2)]:
		_cyl(root, 0.35, 0.45, 3.6, Vector3(cx.x, 4.2, cx.z), iron)
		_cyl(root, 0.42, 0.42, 0.25, Vector3(cx.x, 6.0, cx.z), glow)

	# Gear emblem on the front wall (torus + hub + spokes)
	var gear := MeshInstance3D.new()
	var gear_mesh := TorusMesh.new()
	gear_mesh.inner_radius = 0.75
	gear_mesh.outer_radius = 1.0
	gear.mesh = gear_mesh
	gear.position = Vector3(-0.6, 2.0, 2.15)
	gear.material_override = trim
	root.add_child(gear)
	_cyl(root, 0.22, 0.22, 0.2, Vector3(-0.6, 2.0, 2.15), trim_dark).rotation.x = PI * 0.5
	_box(root, Vector3(0.18, 1.7, 0.1), Vector3(-0.6, 2.0, 2.12), trim_dark)
	_box(root, Vector3(1.7, 0.18, 0.1), Vector3(-0.6, 2.0, 2.12), trim_dark)

	# Windows (emissive slits) + faction banner poles
	for wx in [-1.8, 0.6]:
		_box(root, Vector3(0.8, 0.5, 0.1), Vector3(wx, 2.4, 2.12), glass)
	for px in [-3.6, 3.6]:
		_cyl(root, 0.08, 0.08, 4.5, Vector3(px, 2.5, -3.2), iron)
		_box(root, Vector3(0.9, 1.4, 0.06), Vector3(px, 4.2, -3.2), glow)

	# Pipes along the hall side
	var pipe := _cyl(root, 0.14, 0.14, 4.6, Vector3(-0.6, 0.8, 2.5), copper)
	pipe.rotation.z = PI * 0.5

	# Collision (footprint blocks movement + navmesh cutout is registered by map)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(7.0, 6.0, 6.0)
	col.shape = shape
	col.position = Vector3(0, 3.0, 0)
	root.add_child(col)
