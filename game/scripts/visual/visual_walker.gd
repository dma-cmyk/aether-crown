class_name VisualWalker
extends CharacterBody3D
## Production Ironstride walker wrapper (Phase 2.5D.1). Same integration
## pattern as VisualTitan / VisualAirship, sized for a 4.5 m line unit:
## LOD0/LOD1 ownership + distance switch, separated lightweight collision,
## faction-tinted selection ring + HP bar, faction plate overlays (the shared
## GLB stays Gearforge neutral), anchor access for future FX / recoil /
## walk work. No combat yet: not damageable, take_damage intentionally
## absent so units cannot auto/force-attack it.

signal selected_changed(walker: VisualWalker)

const WalkerLOD0: PackedScene = preload("res://assets/models/gearforge_walker.glb")
const WalkerLOD1: PackedScene = preload("res://assets/models/gearforge_walker_lod1.glb")

## LOD switch: LOD0 below LOD_NEAR_MAX, LOD1 above LOD_FAR_MIN.
## Closer band than the Titan (4.5 m hull reads near only).
const LOD_NEAR_MAX: float = 22.0
const LOD_FAR_MIN: float = 26.0
const LOD_CHECK_INTERVAL: float = 0.25
## Selection ring radius: encircles the 3.54 m footprint with margin,
## well below Titan-scale markers.
const RING_RADIUS: float = 2.2

var is_player: bool = true
var selected: bool = false
var hp: float = 1.0
var max_hp: float = 1.0
## Active LOD level (0 = production close, 1 = RTS distance).
var lod_level: int = 0
## When true (tests/showcase/benchmarks), set_lod() holds and the distance
## auto-switch is skipped. Gameplay default is false (auto).
var lod_locked: bool = false

var _visual_lod0: Node3D = null
var _visual_lod1: Node3D = null
var _lod_check_left: float = 0.0
var _camera: Camera3D = null
var _ring: MeshInstance3D = null
var _hp_bg: MeshInstance3D = null
var _hp_fg: MeshInstance3D = null
var _healthbar_anchor: Node3D = null


func setup(player_flag: bool) -> void:
	is_player = player_flag


func _ready() -> void:
	add_to_group("visual_walkers")
	collision_layer = 2
	collision_mask = 3
	_visual_lod0 = WalkerLOD0.instantiate() as Node3D
	add_child(_visual_lod0)
	_visual_lod1 = WalkerLOD1.instantiate() as Node3D
	_visual_lod1.visible = false
	add_child(_visual_lod1)
	for visual in [_visual_lod0, _visual_lod1]:
		for c in _find_meshes(visual):
			(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_build_collision()
	_build_faction_plates()
	_build_code_anchors()
	_build_markers()
	_refresh_visuals()


func _find_meshes(n: Node) -> Array:
	var out: Array = []
	if n is GeometryInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_meshes(c))
	return out


func is_alive() -> bool:
	return true


func set_selected(value: bool) -> void:
	selected = value
	_refresh_visuals()
	selected_changed.emit(self)


## Two boxes cover torso and legs; the thin cannon barrel and foot tips
## are excluded on purpose so the hitbox never overshoots the visual.
## Positions/sizes are Godot space (x right, y up, z = former Blender -Y).
func _build_collision() -> void:
	_add_box_shape(Vector3(2.2, 1.2, 2.0), Vector3(0, 3.0, 0.0), "torso")
	_add_box_shape(Vector3(3.5, 2.4, 2.3), Vector3(0, 1.2, 0.15), "legs")


func _add_box_shape(size: Vector3, pos: Vector3, shape_name: String) -> void:
	var col := CollisionShape3D.new()
	col.name = "Collision_" + shape_name
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	add_child(col)


## Faction plates ride on the outer shoulder faces. Overlay boxes only:
## the shared GLB and palette stay neutral for both factions.
func _build_faction_plates() -> void:
	var color := Color(0.14, 0.64, 1.0, 1.0) if is_player else Color(1.0, 0.22, 0.12, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.15
	mat.roughness = 0.38
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	for sx in [-1.0, 1.0]:
		var plate := MeshInstance3D.new()
		plate.name = "FactionPlateL" if sx < 0.0 else "FactionPlateR"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, 0.55, 0.9)
		plate.mesh = mesh
		plate.material_override = mat
		plate.position = Vector3(sx * 1.34, 3.18, 0.1)
		plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plate)


func _build_code_anchors() -> void:
	_healthbar_anchor = Node3D.new()
	_healthbar_anchor.name = "healthbar_anchor"
	_healthbar_anchor.position = Vector3(0, 5.2, 0)
	add_child(_healthbar_anchor)


func _build_markers() -> void:
	var tint := Color(0.14, 0.64, 1.0, 1.0) if is_player else Color(1.0, 0.22, 0.12, 1.0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = tint
	ring_mat.emission_enabled = true
	ring_mat.emission = tint
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring = MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = RING_RADIUS - 0.16
	ring_mesh.outer_radius = RING_RADIUS
	ring_mesh.rings = 40
	ring_mesh.ring_segments = 6
	_ring.mesh = ring_mesh
	_ring.material_override = ring_mat
	_ring.position = Vector3(0, 0.1, 0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	var hpbg_mat := StandardMaterial3D.new()
	hpbg_mat.albedo_color = Color(0.08, 0.08, 0.08, 0.9)
	hpbg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hpbg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var hpf_mat := StandardMaterial3D.new()
	hpf_mat.albedo_color = tint
	hpf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hpf_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bg = MeshInstance3D.new()
	var bg_mesh := PlaneMesh.new()
	bg_mesh.size = Vector2(4.0, 0.4)
	_hp_bg.mesh = bg_mesh
	_hp_bg.material_override = hpbg_mat
	_hp_bg.position = Vector3(0, 5.2, 0)
	_hp_bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_bg)
	_hp_fg = MeshInstance3D.new()
	var fg_mesh := PlaneMesh.new()
	fg_mesh.size = Vector2(4.0, 0.4)
	_hp_fg.mesh = fg_mesh
	_hp_fg.material_override = hpf_mat
	_hp_fg.position = Vector3(0, 5.2, 0.02)
	_hp_fg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_fg)


func _refresh_visuals() -> void:
	var show := selected and is_alive()
	if _ring != null:
		_ring.visible = show
	if _hp_bg != null:
		_hp_bg.visible = show
	if _hp_fg != null:
		_hp_fg.visible = show


## Anchor access for future FX / recoil / walk work. GLB anchors
## (muzzle, center, reactor, exhausts, secondary, pistons) and pivots
## (leg_l/r, turret, hull) resolve inside the active LOD visual.
func find_anchor(anchor_name: String) -> Node3D:
	var visual := _active_visual()
	if visual != null:
		var node := visual.find_child(anchor_name, true, true) as Node3D
		if node != null:
			return node
	return null


func _active_visual() -> Node3D:
	return _visual_lod1 if lod_level == 1 else _visual_lod0


func camera_distance() -> float:
	if _camera == null or not is_instance_valid(_camera):
		var rig := get_tree().get_first_node_in_group("rts_camera") as Node3D
		if rig != null:
			_camera = rig.get_node_or_null("Camera3D") as Camera3D
	if _camera == null:
		return 0.0
	return _camera.global_position.distance_to(global_position)


func set_lod(level: int) -> void:
	lod_level = 1 if level == 1 else 0
	lod_locked = true
	_apply_lod()


func unlock_lod() -> void:
	lod_locked = false
	_lod_check_left = 0.0


func _process(delta: float) -> void:
	_lod_check_left -= delta
	if _lod_check_left > 0.0:
		return
	_lod_check_left = LOD_CHECK_INTERVAL
	_update_lod()


func _update_lod() -> void:
	if lod_locked:
		return
	var d := camera_distance()
	if _camera == null:
		return
	if lod_level == 0 and d >= LOD_FAR_MIN:
		lod_level = 1
		_apply_lod()
	elif lod_level == 1 and d <= LOD_NEAR_MAX:
		lod_level = 0
		_apply_lod()


func _apply_lod() -> void:
	if _visual_lod0 != null:
		_visual_lod0.visible = lod_level == 0
	if _visual_lod1 != null:
		_visual_lod1.visible = lod_level == 1
