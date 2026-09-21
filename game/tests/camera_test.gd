extends SceneTree
## Automated camera test (headless). Verifies WASD pan and wheel zoom logic
## by injecting Input actions and stepping frames.
## Usage: godot --headless --path game --script res://tests/camera_test.gd

var _rig: Node3D = null
var _frame: int = 0
var _z0: float = 0.0
var _dist0: float = 0.0
var _pan_ok: bool = false
var _zoom_ok: bool = false


func _initialize() -> void:
	_rig = Node3D.new()
	_rig.set_script(load("res://scripts/camera/camera_controller.gd"))
	_rig.set("edge_scroll_enabled", false)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	_rig.add_child(cam)
	root.add_child(_rig)
	_z0 = _rig.position.z
	_dist0 = float(_rig.get("distance"))
	Input.action_press("camera_forward")
	print("CAMERA_TEST start z=", _z0, " dist=", _dist0)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 30:
		Input.action_release("camera_forward")
		_pan_ok = _rig.position.z < _z0 - 1.0
		print("CAMERA_TEST pan z=", _rig.position.z, " ok=", _pan_ok)
		Input.action_press("camera_zoom_in")
	if _frame == 32:
		Input.action_release("camera_zoom_in")
		_zoom_ok = float(_rig.get("distance")) < _dist0
		print("CAMERA_TEST zoom dist=", float(_rig.get("distance")), " ok=", _zoom_ok)
		print("CAMERA_TEST result pan=", _pan_ok, " zoom=", _zoom_ok)
		quit(0 if (_pan_ok and _zoom_ok) else 1)
		return true
	return false
