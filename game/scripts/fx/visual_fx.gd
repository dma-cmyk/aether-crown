class_name VisualFX
extends RefCounted
## Visual Slice FX (Phase 1.75). One step above MatchFX: emissive flashes +
## short GPUParticles3D bursts + tracers, all under hard caps for Iris Xe.
## Rules: MAX_LIVE one-shot nodes, MAX_EMITTERS looping vents, short
## lifetimes, auto-free, shadows OFF on every FX node.

static var _live: int = 0
static var _emitters: int = 0
const MAX_LIVE: int = 80
const MAX_EMITTERS: int = 12


static func live_count() -> int:
	return _live


static func emitter_count() -> int:
	return _emitters


static func muzzle(parent: Node3D, pos: Vector3, player_flag: bool, big: bool = false) -> void:
	var color := Color(0.55, 0.78, 1.0, 1.0) if player_flag else Color(1.0, 0.55, 0.30, 1.0)
	var size := 0.85 if big else 0.32
	_flash(parent, pos + Vector3(0, 1.2, 0), color, size, 0.12)
	_burst(parent, pos + Vector3(0, 1.2, 0), color, 10 if big else 6, 0.35, 4.0, 0.16)


static func tracer(parent: Node3D, from_pos: Vector3, to_pos: Vector3, player_flag: bool) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if _live >= MAX_LIVE:
		return
	var a := from_pos + Vector3(0, 1.3, 0)
	var b := to_pos + Vector3(0, 1.0, 0)
	var length := a.distance_to(b)
	if length < 0.5 or length > 60.0:
		return
	_live += 1
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.09, 0.09, length)
	mi.mesh = mesh
	var color := Color(0.55, 0.80, 1.0, 1.0) if player_flag else Color(1.0, 0.55, 0.30, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = (a + b) * 0.5
	mi.look_at(b, Vector3.UP)
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "transparency", 1.0, 0.14)
	tw.chain().tween_callback(_finished.bind(mi))


static func hit(parent: Node3D, pos: Vector3, player_victim: bool) -> void:
	var color := Color(0.45, 0.68, 1.0, 1.0) if player_victim else Color(1.0, 0.50, 0.30, 1.0)
	_flash(parent, pos + Vector3(0, 1.0, 0), color, 0.5, 0.16)
	_burst(parent, pos + Vector3(0, 1.0, 0), color, 8, 0.4, 3.5, 0.14)


static func explosion(parent: Node3D, pos: Vector3, big: bool = false) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var ground := pos + Vector3(0, 0.6, 0)
	_flash(parent, ground, Color(1.0, 0.75, 0.35, 1.0), 2.2 if big else 1.2, 0.25)
	_burst(parent, ground, Color(1.0, 0.55, 0.20, 1.0), 26 if big else 14, 0.7, 7.0, 0.22)
	_burst(parent, ground + Vector3(0, 0.5, 0), Color(0.25, 0.24, 0.26, 0.9), 12 if big else 8, 1.1, 2.5, 0.35)


static func death(parent: Node3D, pos: Vector3, player_flag: bool) -> void:
	var color := Color(0.40, 0.65, 1.0, 1.0) if player_flag else Color(1.0, 0.42, 0.25, 1.0)
	_flash(parent, pos + Vector3(0, 0.8, 0), color, 0.9, 0.4)
	_burst(parent, pos + Vector3(0, 0.6, 0), color, 10, 0.6, 3.0, 0.2)


## Looping chimney steam vent (white-ish). Caller owns the node; counted
## in _emitters so maps cannot spawn unlimited vents.
static func steam_vent(parent: Node3D, pos: Vector3) -> GPUParticles3D:
	return _vent(parent, pos, Color(0.85, 0.88, 0.92, 0.55), 14, 1.8, 2.2, Vector3(0, 3.0, 0))


## Looping chimney smoke vent (dark). Same ownership/cap rules as steam.
static func smoke_vent(parent: Node3D, pos: Vector3) -> GPUParticles3D:
	return _vent(parent, pos, Color(0.22, 0.21, 0.22, 0.6), 10, 2.4, 1.8, Vector3(0.6, 2.4, 0))


static func _vent(parent: Node3D, pos: Vector3, color: Color, amount: int, lifetime: float, speed: float, drift: Vector3) -> GPUParticles3D:
	if parent == null or not is_instance_valid(parent):
		return null
	if _emitters >= MAX_EMITTERS:
		return null
	_emitters += 1
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = false
	p.explosiveness = 0.0
	p.randomness = 0.6
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-6, -2, -6), Vector3(12, 12, 12))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(drift.x * 0.2, 1.0, drift.z * 0.2)
	pm.spread = 18.0
	pm.initial_velocity_min = speed * 0.7
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(drift.x * 0.4, 1.2, drift.z * 0.4)
	pm.damping_min = 0.5
	pm.damping_max = 1.0
	pm.scale_min = 0.35
	pm.scale_max = 0.8
	pm.color = color
	p.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.44
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	p.draw_pass_1 = mesh
	p.material_override = mat
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.tree_exiting.connect(_on_vent_freed)
	return p


static func _on_vent_freed() -> void:
	_emitters = maxi(0, _emitters - 1)


static func _burst(parent: Node3D, pos: Vector3, color: Color, amount: int, lifetime: float, speed: float, size: float) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if _live >= MAX_LIVE:
		return
	_live += 1
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 0.9
	p.randomness = 0.7
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-8, -8, -8), Vector3(16, 16, 16))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 45.0
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -4.0, 0)
	pm.damping_min = 1.0
	pm.damping_max = 2.0
	pm.scale_min = size * 0.7
	pm.scale_max = size * 1.3
	pm.color = color
	p.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	p.draw_pass_1 = mesh
	p.material_override = mat
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	var tree := parent.get_tree()
	if tree != null:
		tree.create_timer(lifetime + 0.6).timeout.connect(_finished.bind(p))
	else:
		p.queue_free()
		_live = maxi(0, _live - 1)


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
	mat.emission_energy_multiplier = 2.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 1.7, dur)
	tw.tween_property(mi, "transparency", 1.0, dur)
	tw.chain().tween_callback(_finished.bind(mi))


static func _finished(n: Variant) -> void:
	_live = maxi(0, _live - 1)
	if is_instance_valid(n) and n is Node:
		(n as Node).queue_free()
