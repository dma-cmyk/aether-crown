class_name TitanShell
extends Node3D
## Visual Slice titan projectile: emissive tracer shell flying straight to a
## ground point, then AoE damage + VisualFX explosion. Self-frees on impact
## or lifetime expiry so FX load stays bounded.

signal impacted(pos: Vector3)

var target_pos: Vector3 = Vector3.ZERO
var speed: float = 26.0
var damage: float = 90.0
var splash_radius: float = 4.0
var is_player: bool = true
var life_left: float = 4.0

var _mesh: MeshInstance3D = null


static func fire(parent: Node3D, from_pos: Vector3, to_pos: Vector3, player_flag: bool, big_damage: float = 90.0, radius: float = 4.0) -> TitanShell:
	var shell := TitanShell.new()
	shell.target_pos = to_pos
	shell.is_player = player_flag
	shell.damage = big_damage
	shell.splash_radius = radius
	parent.add_child(shell)
	shell.global_position = from_pos
	return shell


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.9
	mesh.radial_segments = 8
	mesh.rings = 4
	_mesh.mesh = mesh
	var color := Color(0.6, 0.82, 1.0, 1.0) if is_player else Color(1.0, 0.55, 0.28, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh.material_override = mat
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	if target_pos.distance_to(global_position) > 0.1:
		look_at(target_pos, Vector3.UP)


func _physics_process(delta: float) -> void:
	life_left -= delta
	if life_left <= 0.0:
		queue_free()
		return
	var to: Vector3 = target_pos - global_position
	var dist := to.length()
	var step := speed * delta
	if dist <= maxf(step, 0.6):
		_impact()
		return
	global_position += to.normalized() * step
	if _mesh != null:
		_mesh.scale = Vector3(1.0, 1.0, 2.2)


func _impact() -> void:
	var pos := target_pos
	var fx_parent := get_parent() as Node3D
	_apply_splash(pos)
	if fx_parent != null:
		VisualFX.explosion(fx_parent, pos, true)
	impacted.emit(pos)
	queue_free()


func _apply_splash(pos: Vector3) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var victims: Array[Node] = []
	victims.append_array(tree.get_nodes_in_group("rts_units"))
	victims.append_array(tree.get_nodes_in_group("rts_buildings"))
	victims.append_array(tree.get_nodes_in_group("visual_titans"))
	for o in victims:
		var n := o as Node3D
		if n == null or n == self or not is_instance_valid(n):
			continue
		if not n.has_method("is_alive") or not n.has_method("take_damage"):
			continue
		if not bool(n.call("is_alive")):
			continue
		if not ("is_player" in n):
			continue
		if bool(n.get("is_player")) == is_player:
			continue
		var d: Vector3 = n.global_position - pos
		d.y = 0.0
		if d.length() <= splash_radius:
			var attacker: RTSUnit = null
			n.call("take_damage", damage, attacker)
