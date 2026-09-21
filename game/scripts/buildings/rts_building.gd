class_name RTSBuilding
extends StaticBody3D
## Shared building base for HQs (Phase 1.5). Damage API mirrors RTSUnit
## (take_damage / is_alive / is_player / died / damaged) so combat code can
## treat units and buildings through the same duck-typed interface without
## duplicating damage logic. Outposts are NOT buildings (not damageable).

signal died(building: RTSBuilding)
signal damaged(building: RTSBuilding)

var definition: BuildingDefinition
var faction_id: StringName = &"gearforge"
var is_player: bool = true
var display_name: String = "Building"
var max_hp: float = 1200.0
var hp: float = 1200.0
var selected: bool = false

var _ring: MeshInstance3D
var _hp_bg: MeshInstance3D
var _hp_fg: MeshInstance3D
var _bar_height: float = 7.5
var _ring_radius: float = 6.0

static var _mats: Dictionary = {}


static func shared_materials() -> Dictionary:
	if _mats.is_empty():
		var ring_m := StandardMaterial3D.new()
		ring_m.albedo_color = Color(1.0, 0.9, 0.2, 1.0)
		ring_m.emission_enabled = true
		ring_m.emission = Color(1.0, 0.85, 0.2, 1.0)
		ring_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var hpbg := StandardMaterial3D.new()
		hpbg.albedo_color = Color(0.08, 0.08, 0.08, 0.9)
		hpbg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hpbg.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		var hpf := StandardMaterial3D.new()
		hpf.albedo_color = Color(0.35, 0.75, 1.0, 1.0)
		hpf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hpf.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_mats = {"ring": ring_m, "hpbg": hpbg, "hpf": hpf}
	return _mats


## Called by the map right after construction, before add_child().
func setup(def: BuildingDefinition, player_flag: bool) -> void:
	if def != null:
		definition = def
		faction_id = def.faction_id
		display_name = def.display_name
		max_hp = def.max_hp
	is_player = player_flag
	hp = max_hp


func _ready() -> void:
	add_to_group("rts_buildings")
	collision_layer = 3 # 1 world (ground clicks land) + 2 selectable/attackable
	collision_mask = 0
	var m := shared_materials()
	_ring = MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = _ring_radius
	ring_mesh.bottom_radius = _ring_radius
	ring_mesh.height = 0.08
	_ring.mesh = ring_mesh
	_ring.material_override = m["ring"]
	_ring.position = Vector3(0, 0.1, 0)
	add_child(_ring)
	_hp_bg = MeshInstance3D.new()
	var bg_mesh := PlaneMesh.new()
	bg_mesh.size = Vector2(6.0, 0.5)
	_hp_bg.mesh = bg_mesh
	_hp_bg.material_override = m["hpbg"]
	_hp_bg.position = Vector3(0, _bar_height, 0)
	add_child(_hp_bg)
	_hp_fg = MeshInstance3D.new()
	var fg_mesh := PlaneMesh.new()
	fg_mesh.size = Vector2(6.0, 0.5)
	_hp_fg.mesh = fg_mesh
	_hp_fg.material_override = m["hpf"]
	_hp_fg.position = Vector3(0, _bar_height, 0.02)
	add_child(_hp_fg)
	_refresh_visuals()


func is_alive() -> bool:
	return hp > 0.0


func set_selected(value: bool) -> void:
	selected = value
	_refresh_visuals()


func take_damage(amount: float, _attacker: Node) -> void:
	if not is_alive():
		return
	hp = maxf(0.0, hp - amount)
	damaged.emit(self)
	_refresh_visuals()
	if hp <= 0.0:
		_die()


func _die() -> void:
	died.emit(self)
	set_deferred("collision_layer", 0)
	if _ring != null:
		_ring.visible = false
	if _hp_bg != null:
		_hp_bg.visible = false
	if _hp_fg != null:
		_hp_fg.visible = false
	# Collapse: sink + tip, then free. MatchManager reacts to died already.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y - 3.0, 1.2)
	tw.tween_property(self, "rotation:z", 0.12, 1.2)
	tw.chain().tween_callback(queue_free)


func _refresh_visuals() -> void:
	if _ring != null:
		_ring.visible = selected and is_alive()
	var show_hp := is_alive() and (selected or hp < max_hp)
	if _hp_bg != null:
		_hp_bg.visible = show_hp
	if _hp_fg != null:
		_hp_fg.visible = show_hp
		if show_hp:
			var frac := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
			_hp_fg.scale = Vector3(maxf(0.001, frac), 1.0, 1.0)
			_hp_fg.position = Vector3(-3.0 * (1.0 - frac), _bar_height, 0.02)
