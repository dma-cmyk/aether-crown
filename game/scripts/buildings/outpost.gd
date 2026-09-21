class_name RTSOutpost
extends StaticBody3D
## Central neutral outpost (Phase 1.5). Captured by standing units inside
## the radius for capture_time_sec. Both sides inside => CONTESTED (frozen).
## Not damageable: units ignore it, so it never interferes with targeting.
## Owner bonus is applied to economies by the match map.

signal ownership_changed(new_owner: int)
signal progress_changed

enum Owner { NEUTRAL, PLAYER, ENEMY }

const TICK: float = 0.25

var owner_side: int = Owner.NEUTRAL
var challenger: int = -1
var progress_sec: float = 0.0
var capture_time_sec: float = 15.0
var capture_radius: float = 8.0
var contested: bool = false

var _tick_left: float = 0.0
var _crystal_mat: StandardMaterial3D
var _flag_mat: StandardMaterial3D
var _bar_fg: MeshInstance3D
var _bar_bg: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group("outposts")
	collision_layer = 1 # world only: never selectable/attackable
	collision_mask = 0
	_build_visual()


func reset_outpost() -> void:
	owner_side = Owner.NEUTRAL
	challenger = -1
	progress_sec = 0.0
	contested = false
	_refresh_visuals()
	progress_changed.emit()


func progress_fraction() -> float:
	if capture_time_sec <= 0.0:
		return 0.0
	return clampf(progress_sec / capture_time_sec, 0.0, 1.0)


func owner_name() -> String:
	match owner_side:
		Owner.PLAYER:
			return "PLAYER"
		Owner.ENEMY:
			return "ENEMY"
	return "NEUTRAL"


func _process(delta: float) -> void:
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK
	_capture_tick(TICK)


func _capture_tick(dt: float) -> void:
	var players := 0
	var enemies := 0
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u == null or not u.is_alive():
			continue
		var dx := u.global_position.x - global_position.x
		var dz := u.global_position.z - global_position.z
		if dx * dx + dz * dz > capture_radius * capture_radius:
			continue
		if u.is_player:
			players += 1
		else:
			enemies += 1
	var was_contested := contested
	var old_frac := progress_fraction()
	contested = players > 0 and enemies > 0
	if contested:
		pass # frozen
	elif players > 0 and enemies == 0:
		_advance(Owner.PLAYER, dt)
	elif enemies > 0 and players == 0:
		_advance(Owner.ENEMY, dt)
	else:
		progress_sec = maxf(0.0, progress_sec - dt)
		if progress_sec <= 0.0:
			challenger = -1
	if contested != was_contested or absf(progress_fraction() - old_frac) > 0.001:
		_refresh_visuals()
		progress_changed.emit()


func _advance(side: int, dt: float) -> void:
	if owner_side == side:
		progress_sec = maxf(0.0, progress_sec - dt)
		if progress_sec <= 0.0:
			challenger = -1
		return
	if challenger != side:
		challenger = side
		progress_sec = 0.0
	progress_sec += dt
	if progress_sec >= capture_time_sec:
		owner_side = side
		challenger = -1
		progress_sec = 0.0
		_refresh_visuals()
		ownership_changed.emit(owner_side)


func owner_color() -> Color:
	match owner_side:
		Owner.PLAYER:
			return Color(0.25, 0.55, 1.0, 1.0)
		Owner.ENEMY:
			return Color(1.0, 0.30, 0.22, 1.0)
	return Color(0.55, 0.55, 0.58, 1.0)


func _build_visual() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.42, 0.42, 0.45, 1.0)
	stone.roughness = 0.95
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.20, 0.20, 0.23, 1.0)
	dark.roughness = 0.9
	_crystal_mat = StandardMaterial3D.new()
	_crystal_mat.albedo_color = owner_color()
	_crystal_mat.emission_enabled = true
	_crystal_mat.emission = owner_color()
	_crystal_mat.emission_energy_multiplier = 1.5
	_flag_mat = StandardMaterial3D.new()
	_flag_mat.albedo_color = owner_color()
	_flag_mat.roughness = 0.7

	# Platform + radius ring (shows capture area)
	var plat := MeshInstance3D.new()
	var plat_mesh := CylinderMesh.new()
	plat_mesh.top_radius = 4.0
	plat_mesh.bottom_radius = 4.4
	plat_mesh.height = 0.4
	plat_mesh.radial_segments = 24
	plat.mesh = plat_mesh
	plat.position = Vector3(0, 0.2, 0)
	plat.material_override = stone
	add_child(plat)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = capture_radius - 0.18
	ring_mesh.outer_radius = capture_radius
	ring.mesh = ring_mesh
	ring.position = Vector3(0, 0.15, 0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.8, 0.8, 0.85, 0.5)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	add_child(ring)

	# Pillar + floating crystal
	var pillar := MeshInstance3D.new()
	var pillar_mesh := CylinderMesh.new()
	pillar_mesh.top_radius = 0.7
	pillar_mesh.bottom_radius = 1.0
	pillar_mesh.height = 3.4
	pillar_mesh.radial_segments = 8
	pillar.mesh = pillar_mesh
	pillar.position = Vector3(0, 2.0, 0)
	pillar.material_override = dark
	add_child(pillar)
	var crystal := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.7
	cm.height = 1.6
	cm.radial_segments = 8
	cm.rings = 4
	crystal.mesh = cm
	crystal.position = Vector3(0, 4.4, 0)
	crystal.material_override = _crystal_mat
	add_child(crystal)

	# Banner pole + flag
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.08
	pole_mesh.height = 5.0
	pole.mesh = pole_mesh
	pole.position = Vector3(2.8, 2.9, 0)
	pole.material_override = dark
	add_child(pole)
	var flag := MeshInstance3D.new()
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(1.4, 0.9, 0.08)
	flag.mesh = flag_mesh
	flag.position = Vector3(3.6, 4.9, 0)
	flag.material_override = _flag_mat
	add_child(flag)

	# Capture progress bar (billboard) + status label
	_bar_bg = MeshInstance3D.new()
	var bg_mesh := PlaneMesh.new()
	bg_mesh.size = Vector2(4.0, 0.35)
	_bar_bg.mesh = bg_mesh
	_bar_bg.position = Vector3(0, 6.2, 0)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.08, 0.08, 0.08, 0.9)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_bar_bg.material_override = bg_mat
	add_child(_bar_bg)
	_bar_fg = MeshInstance3D.new()
	var fg_mesh := PlaneMesh.new()
	fg_mesh.size = Vector2(4.0, 0.35)
	_bar_fg.mesh = fg_mesh
	_bar_fg.position = Vector3(0, 6.2, 0.02)
	var fg_mat := StandardMaterial3D.new()
	fg_mat.albedo_color = Color(1.0, 0.85, 0.25, 1.0)
	fg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_bar_fg.material_override = fg_mat
	add_child(_bar_fg)
	_label = Label3D.new()
	_label.position = Vector3(0, 7.0, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 48
	_label.pixel_size = 0.01
	_label.modulate = Color(1, 1, 1, 1)
	add_child(_label)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 4.0
	col.shape = shape
	col.position = Vector3(0, 2.0, 0)
	add_child(col)
	_refresh_visuals()


func _refresh_visuals() -> void:
	if _crystal_mat != null:
		_crystal_mat.albedo_color = owner_color()
		_crystal_mat.emission = owner_color()
	if _flag_mat != null:
		_flag_mat.albedo_color = owner_color()
	if _bar_fg != null:
		var frac := progress_fraction()
		_bar_fg.visible = frac > 0.001
		_bar_bg.visible = frac > 0.001
		_bar_fg.scale = Vector3(maxf(0.001, frac), 1.0, 1.0)
		_bar_fg.position = Vector3(-2.0 * (1.0 - frac), 6.2, 0.02)
	if _label != null:
		if contested:
			_label.text = "CONTESTED"
		elif challenger >= 0:
			var who := "PLAYER" if challenger == Owner.PLAYER else "ENEMY"
			_label.text = "%s %s %d%%" % [owner_name(), who, int(progress_fraction() * 100.0)]
		else:
			_label.text = owner_name()
