class_name TerritoryRegion
extends Node3D
## One pre-defined territory quad (Phase 2B). Static low-poly geometry built
## once; ownership/frontline changes only recolor materials or toggle
## visibility. Never rebuilt per-frame. No shadows, no shaders, no decals.

enum Owner { NEUTRAL, PLAYER, ENEMY } # same numbering as RTSCity.Owner
enum Frontline { NONE, SOFT, HARD } # SOFT: borders neutral. HARD: player vs enemy.

const OVERLAY_ALPHA: float = 0.09

var definition: TerritoryDefinition
var region_id: StringName = &""
var display_name: String = "Territory"
var owner_side: int = Owner.NEUTRAL
var frontline: int = Frontline.NONE

var _overlay_mat: StandardMaterial3D
var _border_mat: StandardMaterial3D
var _front_mat: StandardMaterial3D
var _front_strips: Array = []


## Called by the controller right after construction, before add_child().
## layer_index staggers overlay height to avoid z-fighting on overlaps.
func setup(def: TerritoryDefinition, layer_index: int = 0) -> void:
	definition = def
	if def != null:
		region_id = def.id
		display_name = def.display_name
	_build_visual(layer_index)


func set_region_owner(side: int) -> void:
	owner_side = side
	_refresh_colors()


## 0 = none, 1 = soft (vs neutral), 2 = hard (player vs enemy).
func set_frontline(level: int) -> void:
	frontline = level
	for s in _front_strips:
		(s as MeshInstance3D).visible = level != Frontline.NONE
	if _front_mat != null:
		_front_mat.emission_energy_multiplier = 3.0 if level == Frontline.HARD else 1.5


func owner_name() -> String:
	match owner_side:
		Owner.PLAYER:
			return "PLAYER"
		Owner.ENEMY:
			return "ENEMY"
	return "NEUTRAL"


func status_text() -> String:
	return "%s %s" % [display_name, owner_name()]


func owner_color() -> Color:
	match owner_side:
		Owner.PLAYER:
			return Color(0.25, 0.55, 1.0, 1.0)
		Owner.ENEMY:
			return Color(1.0, 0.30, 0.22, 1.0)
	return Color(0.75, 0.75, 0.78, 1.0)


func _build_visual(layer_index: int) -> void:
	var w: float = definition.size.x if definition != null else 24.0
	var d: float = definition.size.y if definition != null else 22.0
	_overlay_mat = StandardMaterial3D.new()
	_overlay_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay_mat.albedo_color = Color(owner_color(), OVERLAY_ALPHA)
	_border_mat = StandardMaterial3D.new()
	_border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_border_mat.albedo_color = owner_color()
	_front_mat = StandardMaterial3D.new()
	_front_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_front_mat.albedo_color = owner_color()
	_front_mat.emission_enabled = true
	_front_mat.emission = owner_color()
	_front_mat.emission_energy_multiplier = 1.2

	# Ground tint quad (very light, static)
	var overlay := MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(w, d)
	overlay.mesh = quad
	overlay.position = Vector3(0, 0.06 + float(layer_index) * 0.006, 0)
	overlay.material_override = _overlay_mat
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(overlay)

	# Perimeter border: 4 slim boxes, darkened so the base map stays readable;
	# frontline strips (below) carry the emphasis. Phase 2D polish.
	_add_edge(Vector3(w, 0.07, 0.14), Vector3(0, 0.09, -d * 0.5), _border_mat, false)
	_add_edge(Vector3(w, 0.07, 0.14), Vector3(0, 0.09, d * 0.5), _border_mat, false)
	_add_edge(Vector3(0.14, 0.07, d), Vector3(-w * 0.5, 0.09, 0), _border_mat, false)
	_add_edge(Vector3(0.14, 0.07, d), Vector3(w * 0.5, 0.09, 0), _border_mat, false)

	# Frontline glow strips (same perimeter, brighter, toggled)
	_add_edge(Vector3(w, 0.12, 0.5), Vector3(0, 0.14, -d * 0.5), _front_mat, true)
	_add_edge(Vector3(w, 0.12, 0.5), Vector3(0, 0.14, d * 0.5), _front_mat, true)
	_add_edge(Vector3(0.5, 0.12, d), Vector3(-w * 0.5, 0.14, 0), _front_mat, true)
	_add_edge(Vector3(0.5, 0.12, d), Vector3(w * 0.5, 0.14, 0), _front_mat, true)

	_build_aether_marker()
	_refresh_colors()


func _add_edge(size: Vector3, pos: Vector3, mat: Material, is_front: bool) -> void:
	var edge := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	edge.mesh = mesh
	edge.position = pos
	edge.material_override = mat
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(edge)
	if is_front:
		edge.visible = false
		_front_strips.append(edge)


## Lightweight Aether source marker (Phase 2B system validation only).
## One crystal for side regions, three brighter ones for Central.
func _build_aether_marker() -> void:
	var value: float = definition.aether_income_bonus if definition != null else 0.0
	if value <= 0.0:
		return
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.35, 0.34, 0.38, 1.0)
	stone.roughness = 0.95
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.3, 0.9, 1.0, 1.0)
	glow.emission_enabled = true
	glow.emission = Color(0.3, 0.9, 1.0, 1.0)
	glow.emission_energy_multiplier = 2.5 if value >= 0.8 else 1.5
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.0
	base_mesh.bottom_radius = 1.3
	base_mesh.height = 0.4
	base_mesh.radial_segments = 8
	base.mesh = base_mesh
	base.position = _marker_pos() + Vector3(0, 0.2, 0)
	base.material_override = stone
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(base)
	var count := 3 if value >= 0.8 else 1
	for i in range(count):
		var c := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 0.32
		cm.height = 0.85
		cm.radial_segments = 6
		cm.rings = 3
		c.mesh = cm
		var off := Vector3((float(i) - float(count - 1) * 0.5) * 0.8, 0.75, 0)
		c.position = _marker_pos() + off
		c.material_override = glow
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(c)


## Marker sits at the region center; cities already occupy their own spots,
## so nudge toward the region's south edge to stay out of the way.
func _marker_pos() -> Vector3:
	var d: float = definition.size.y if definition != null else 22.0
	return Vector3(0, 0, d * 0.5 - 2.5)


func _refresh_colors() -> void:
	var c := owner_color()
	var dim := Color(c.r * 0.65, c.g * 0.65, c.b * 0.65, 1.0)
	if _overlay_mat != null:
		_overlay_mat.albedo_color = Color(c, OVERLAY_ALPHA)
	if _border_mat != null:
		_border_mat.albedo_color = dim
	if _front_mat != null:
		_front_mat.albedo_color = c
		_front_mat.emission = c
	set_frontline(frontline)
