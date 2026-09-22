class_name DistrictVisual
extends RefCounted
## Static primitive builders for Phase 2C districts (no Blender assets).
## 1 district = 1 main visual + a few props, all shadowless. Foundation
## frame for BUILDING state, distinct silhouette per type:
## industry = factory + chimney + orange glow, military = barracks + banner,
## aether_works = tower + cyan crystals + ring. Gearforge palette kept.

const FACTION_BLUE := Color(0.25, 0.55, 1.0, 1.0)
const FACTION_RED := Color(1.0, 0.30, 0.22, 1.0)


static func faction_color(player_side: bool) -> Color:
	return FACTION_BLUE if player_side else FACTION_RED


static func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


static func _glow_mat(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _cylinder(parent: Node3D, top_r: float, bot_r: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = height
	mesh.radial_segments = 8
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Static scaffolding look for BUILDING state (no per-frame blinking).
static func build_foundation(parent: Node3D) -> void:
	var slab_mat := _mat(Color(0.38, 0.36, 0.34, 1.0), 0.0, 0.95)
	var frame_mat := _mat(Color(0.55, 0.42, 0.20, 1.0), 0.6, 0.5)
	_box(parent, Vector3(3.4, 0.25, 3.0), Vector3(0, 0.12, 0), slab_mat)
	for sx in [-1.4, 1.4]:
		for sz in [-1.2, 1.2]:
			_box(parent, Vector3(0.18, 2.2, 0.18), Vector3(sx, 1.2, sz), frame_mat)
	_box(parent, Vector3(3.2, 0.18, 2.8), Vector3(0, 2.3, 0), frame_mat)


static func build_district(parent: Node3D, visual_type: StringName, player_side: bool) -> void:
	match visual_type:
		&"military":
			_build_military(parent, player_side)
		&"aether_works":
			_build_aether_works(parent)
		_:
			_build_industry(parent)


static func _build_industry(parent: Node3D) -> void:
	var iron := _mat(Color(0.25, 0.24, 0.27, 1.0), 0.4, 0.6)
	var brass := _mat(Color(0.55, 0.42, 0.20, 1.0), 0.6, 0.5)
	var copper := _mat(Color(0.65, 0.35, 0.18, 1.0), 0.7, 0.45)
	_box(parent, Vector3(3.0, 1.8, 2.4), Vector3(0, 0.9, 0), iron)
	_box(parent, Vector3(3.3, 0.3, 2.7), Vector3(0, 1.95, 0), brass)
	_cylinder(parent, 0.35, 0.45, 3.0, Vector3(-0.9, 3.0, -0.4), copper)
	_box(parent, Vector3(0.8, 0.6, 0.15), Vector3(0.6, 0.7, 1.25), _glow_mat(Color(1.0, 0.5, 0.15, 1.0)))
	var pipe := _cylinder(parent, 0.22, 0.22, 2.6, Vector3(1.0, 0.5, -0.6), copper)
	pipe.rotation.z = PI * 0.5


static func _build_military(parent: Node3D, player_side: bool) -> void:
	var dark := _mat(Color(0.22, 0.23, 0.27, 1.0), 0.3, 0.7)
	var brass := _mat(Color(0.55, 0.42, 0.20, 1.0), 0.6, 0.5)
	_box(parent, Vector3(3.0, 2.0, 2.4), Vector3(0, 1.0, 0), dark)
	_box(parent, Vector3(3.3, 0.25, 2.7), Vector3(0, 2.1, 0), brass)
	# Antenna (turret-like vertical accent)
	_cylinder(parent, 0.06, 0.06, 3.0, Vector3(-1.0, 3.5, -0.6), brass)
	_box(parent, Vector3(0.5, 0.18, 0.5), Vector3(-1.0, 5.0, -0.6), _glow_mat(faction_color(player_side), 1.5))
	# Banner pole + faction flag
	_cylinder(parent, 0.07, 0.07, 3.4, Vector3(1.2, 1.9, 0.8), dark)
	_box(parent, Vector3(1.1, 0.7, 0.08), Vector3(1.75, 3.2, 0.8), _mat(faction_color(player_side), 0.0, 0.7))


static func _build_aether_works(parent: Node3D) -> void:
	var stone := _mat(Color(0.35, 0.34, 0.38, 1.0), 0.0, 0.95)
	var cyan := Color(0.3, 0.9, 1.0, 1.0)
	_cylinder(parent, 0.7, 1.0, 2.2, Vector3(0, 1.1, 0), stone)
	for i in range(2):
		var c := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 0.32
		cm.height = 0.9
		cm.radial_segments = 6
		cm.rings = 3
		c.mesh = cm
		c.position = Vector3(-0.5 + float(i), 2.6, 0)
		c.material_override = _glow_mat(cyan, 2.2)
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(c)
	var ring := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 1.3
	rm.outer_radius = 1.55
	ring.mesh = rm
	ring.position = Vector3(0, 0.15, 0)
	ring.material_override = _glow_mat(cyan, 1.2)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
