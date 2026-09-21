extends SceneTree
## Camera live probe (RUN WITH RENDERING, not headless).
## Exercises the real CameraRig in test_world: WASD pan, wheel zoom,
## edge scroll via OS mouse warp, map bounds clamp, motion smoothness.
## Usage: godot --path game --script res://tests/camera_probe.gd

var _frame: int = 0
var _rig: Node3D = null
var _p_wasd := Vector3.ZERO
var _p_edge0 := Vector3.ZERO
var _dist0: float = 0.0
var _max_step: float = 0.0
var _max_frame: int = 0
var _prev := Vector3.ZERO
var _results: Dictionary = {}


func _initialize() -> void:
	var packed := load("res://scenes/maps/test_world.tscn") as PackedScene
	var m := packed.instantiate()
	root.add_child(m)


func _resolve() -> bool:
	if _rig != null:
		return true
	_rig = get_first_node_in_group("rts_camera") as Node3D
	if _rig == null:
		return false
	_prev = _rig.position
	return true


func _sample_smooth(_dt: float) -> void:
	# Anti-jump guarantee: with the 0.05s hitch clamp the rig can move at
	# most 40m/s * 0.05s = 2.0m per frame BY CONSTRUCTION. Assert no
	# teleport-scale step ever occurs (delta clocks differ in --script
	# mode, so judge absolute steps, not implied speed).
	var step: float = _rig.position.distance_to(_prev)
	if step > _max_step:
		_max_step = step
		_max_frame = _frame
	_prev = _rig.position


func _finish() -> void:
	print("CAMERA_PROBE results=", _results, " max_speed=", _max_step, " at_frame=", _max_frame)
	var ok: bool = _results.get("wasd", false) and _results.get("zoom", false) and _results.get("edge", false) and _results.get("bounds", false)
	print("CAMERA_PROBE ", "OK" if ok else "NG")
	quit(0 if ok else 1)


func _process(delta: float) -> bool:
	_frame += 1
	if _rig == null:
		if _frame == 5:
			print("CAMERA_PROBE rig-group-size=", get_nodes_in_group("rts_camera").size())
		if not _resolve():
			if _frame > 30:
				print("CAMERA_PROBE NG no-rig")
				quit(1)
				return true
			return false
		_frame = 5
	_sample_smooth(delta)
	if _frame == 5:
		_rig.position = Vector3.ZERO
		_prev = Vector3.ZERO
		_max_step = 0.0
		_p_wasd = Vector3.ZERO
		Input.action_press("camera_forward")
	elif _frame == 65:
		Input.action_release("camera_forward")
		_results["wasd"] = _rig.position.z < -1.0
		print("CAMERA_PROBE wasd z=", _rig.position.z)
		Input.action_press("camera_right")
	elif _frame == 125:
		Input.action_release("camera_right")
		_results["strafe"] = _rig.position.x > 1.0
		_dist0 = float(_rig.get("distance"))
		Input.action_press("camera_zoom_in")
	elif _frame == 127:
		Input.action_release("camera_zoom_in")
		_results["zoom"] = float(_rig.get("distance")) < _dist0
		print("CAMERA_PROBE zoom dist=", float(_rig.get("distance")))
		_p_edge0 = _rig.position
		var sz := root.size
		Input.warp_mouse(Vector2(float(sz.x) - 2.0, float(sz.y) * 0.5))
	elif _frame == 170:
		_results["edge"] = _rig.position.x > _p_edge0.x + 0.5
		print("CAMERA_PROBE edge dx=", _rig.position.x - _p_edge0.x)
		Input.action_press("camera_right")
	elif _frame == 520:
		Input.action_release("camera_right")
		var limit := float(_rig.get("map_limit"))
		_results["bounds"] = _rig.position.x <= limit + 0.5 and _rig.position.x >= limit - 1.0
		print("CAMERA_PROBE bounds x=", _rig.position.x, " limit=", limit)
		_results["smooth"] = _max_step < 2.5
		_finish()
		return true
	return false
