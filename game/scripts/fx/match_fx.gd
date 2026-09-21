class_name MatchFX
extends RefCounted
## Minimal event-driven combat FX (Phase 1.5). No particle systems yet:
## small emissive flashes + a rising "READY" label. Global live-node cap
## keeps worst-case cost bounded during 50v50 brawls.

static var _live: int = 0
const MAX_LIVE: int = 60


static func live_count() -> int:
	return _live


static func muzzle(parent: Node3D, pos: Vector3, player_flag: bool) -> void:
	var color := Color(0.5, 0.75, 1.0, 1.0) if player_flag else Color(1.0, 0.5, 0.35, 1.0)
	_flash(parent, pos + Vector3(0, 1.2, 0), color, 0.28, 0.09)


static func hit(parent: Node3D, pos: Vector3, player_victim: bool) -> void:
	var color := Color(0.4, 0.65, 1.0, 1.0) if player_victim else Color(1.0, 0.45, 0.3, 1.0)
	_flash(parent, pos + Vector3(0, 1.0, 0), color, 0.45, 0.16)


static func death(parent: Node3D, pos: Vector3, player_flag: bool) -> void:
	var color := Color(0.35, 0.6, 1.0, 1.0) if player_flag else Color(1.0, 0.4, 0.25, 1.0)
	_flash(parent, pos + Vector3(0, 0.8, 0), color, 0.9, 0.45)


static func production_ready(parent: Node3D, pos: Vector3, unit_name: String) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if _live >= MAX_LIVE:
		return
	_live += 1
	var label := Label3D.new()
	label.text = "%s READY" % unit_name
	label.font_size = 64
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.5, 1.0, 0.5, 1.0)
	parent.add_child(label)
	label.global_position = pos + Vector3(0, 7.0, 0)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y + 2.0, 1.4)
	tw.tween_property(label, "modulate:a", 0.0, 1.4)
	tw.chain().tween_callback(_finished.bind(label))


static func _flash(parent: Node3D, pos: Vector3, color: Color, size: float, dur: float) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if _live >= MAX_LIVE:
		return
	_live += 1
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 1.8, dur)
	tw.tween_property(mi, "transparency", 1.0, dur)
	tw.chain().tween_callback(_finished.bind(mi))


static func _finished(n: Node) -> void:
	_live = maxi(0, _live - 1)
	if is_instance_valid(n):
		n.queue_free()
