class_name RTSCity
extends StaticBody3D
## Capturable neutral city (Phase 2A). Capture rules mirror RTSOutpost
## (presence inside radius for capture_time_sec, both sides => CONTESTED,
## recapture supported) but cities are owned for a Material/sec bonus and
## are deliberately independent from outpost.gd: Phase 1.5 must keep working
## untouched, so this file duplicates the small capture state machine.
## Not damageable: never joins "rts_buildings", units ignore it.

signal ownership_changed(new_owner: int)
signal progress_changed

enum Owner { NEUTRAL, PLAYER, ENEMY }

const TICK: float = 0.25

var city_id: StringName = &"west_city"
var display_name: String = "City"
var owner_side: int = Owner.NEUTRAL
var challenger: int = -1
var progress_sec: float = 0.0
var capture_time_sec: float = 12.0
var capture_radius: float = 8.0
var income_bonus: float = 1.5
var contested: bool = false

var _tick_left: float = 0.0
var _flag_mat: StandardMaterial3D
var _glow_mat: StandardMaterial3D
var _ring_mat: StandardMaterial3D
var _bar_fg: MeshInstance3D
var _bar_bg: MeshInstance3D
var _label: Label3D


## Called by the map right after construction, before add_child().
func setup(def: CityDefinition) -> void:
	if def != null:
		city_id = def.id
		display_name = def.display_name
		capture_time_sec = def.capture_time_sec
		capture_radius = def.capture_radius
		income_bonus = def.income_bonus
	# The map calls setup() after _ready() (which already built the label
	# with default values), so refresh the visuals to pick up the data.
	_refresh_visuals()


func _ready() -> void:
	add_to_group("rts_cities")
	collision_layer = 1 # world only: never selectable/attackable
	collision_mask = 0
	_build_visual()


func reset_city() -> void:
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


func status_text() -> String:
	var text := "%s %s" % [display_name, owner_name()]
	if contested:
		text += " CONTESTED"
	elif challenger >= 0:
		text += " %d%%" % int(progress_fraction() * 100.0)
	return text


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
	return Color(0.75, 0.75, 0.78, 1.0)


func _build_visual() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.40, 0.38, 0.36, 1.0)
	stone.roughness = 0.95
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.55, 0.42, 0.20, 1.0)
	brass.metallic = 0.6
	brass.roughness = 0.5
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.20, 0.20, 0.23, 1.0)
	dark.roughness = 0.9
	_flag_mat = StandardMaterial3D.new()
	_flag_mat.albedo_color = owner_color()
	_flag_mat.roughness = 0.7
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.albedo_color = owner_color()
	_glow_mat.emission_enabled = true
	_glow_mat.emission = owner_color()
	_glow_mat.emission_energy_multiplier = 1.5
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = Color(0.8, 0.8, 0.85, 0.5)
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Pavement + capture radius ring
	var pave := MeshInstance3D.new()
	var pave_mesh := BoxMesh.new()
	pave_mesh.size = Vector3(12.0, 0.2, 10.0)
	pave.mesh = pave_mesh
	pave.position = Vector3(0, 0.1, 0)
	pave.material_override = stone
	add_child(pave)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = capture_radius - 0.18
	ring_mesh.outer_radius = capture_radius
	ring.mesh = ring_mesh
	ring.position = Vector3(0, 0.25, 0)
	ring.material_override = _ring_mat
	add_child(ring)

	# Central building: body + roof (Gearforge brass/stone language)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(4.0, 2.6, 3.4)
	body.mesh = body_mesh
	body.position = Vector3(0, 1.5, -0.6)
	body.material_override = stone
	add_child(body)
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(4.6, 0.4, 4.0)
	roof.mesh = roof_mesh
	roof.position = Vector3(0, 3.0, -0.6)
	roof.material_override = brass
	add_child(roof)
	var tower := MeshInstance3D.new()
	var tower_mesh := BoxMesh.new()
	tower_mesh.size = Vector3(1.2, 4.2, 1.2)
	tower.mesh = tower_mesh
	tower.position = Vector3(-1.2, 2.3, -0.6)
	tower.material_override = brass
	add_child(tower)

	# Supporting buildings (1-2 small sheds)
	var shed := MeshInstance3D.new()
	var shed_mesh := BoxMesh.new()
	shed_mesh.size = Vector3(2.2, 1.6, 2.0)
	shed.mesh = shed_mesh
	shed.position = Vector3(3.2, 1.0, 1.8)
	shed.material_override = dark
	add_child(shed)
	var shed2 := MeshInstance3D.new()
	shed2.mesh = shed_mesh
	shed2.position = Vector3(-3.4, 1.0, 1.6)
	shed2.material_override = dark
	add_child(shed2)

	# Ownership beacon: pole + flag + glow orb
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.08
	pole_mesh.height = 5.0
	pole.mesh = pole_mesh
	pole.position = Vector3(0, 2.7, 2.6)
	pole.material_override = dark
	add_child(pole)
	var flag := MeshInstance3D.new()
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(1.4, 0.9, 0.08)
	flag.mesh = flag_mesh
	flag.position = Vector3(0.8, 4.7, 2.6)
	flag.material_override = _flag_mat
	add_child(flag)
	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.45
	orb_mesh.height = 0.9
	orb_mesh.radial_segments = 8
	orb_mesh.rings = 4
	orb.mesh = orb_mesh
	orb.position = Vector3(0, 5.6, 2.6)
	orb.material_override = _glow_mat
	add_child(orb)

	# Capture progress bar (billboard) + status label
	_bar_bg = MeshInstance3D.new()
	var bg_mesh := PlaneMesh.new()
	bg_mesh.size = Vector2(4.0, 0.35)
	_bar_bg.mesh = bg_mesh
	_bar_bg.position = Vector3(0, 6.8, 2.6)
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
	_bar_fg.position = Vector3(0, 6.8, 2.62)
	var fg_mat := StandardMaterial3D.new()
	fg_mat.albedo_color = Color(1.0, 0.85, 0.25, 1.0)
	fg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_bar_fg.material_override = fg_mat
	add_child(_bar_fg)
	_label = Label3D.new()
	_label.position = Vector3(0, 7.6, 2.6)
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
	col.position = Vector3(0, 2.0, -0.6)
	add_child(col)
	_refresh_visuals()


func _refresh_visuals() -> void:
	if _flag_mat != null:
		_flag_mat.albedo_color = owner_color()
	if _glow_mat != null:
		_glow_mat.albedo_color = owner_color()
		_glow_mat.emission = owner_color()
	if _bar_fg != null:
		var frac := progress_fraction()
		_bar_fg.visible = frac > 0.001
		_bar_bg.visible = frac > 0.001
		_bar_fg.scale = Vector3(maxf(0.001, frac), 1.0, 1.0)
		_bar_fg.position = Vector3(-2.0 * (1.0 - frac), 6.8, 2.62)
	if _label != null:
		_label.text = status_text()
