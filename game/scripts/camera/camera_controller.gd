extends Node3D
## Quarter-view RTS camera controller.
## WASD / arrows: pan (uses camera_forward/backward/left/right actions)
## Wheel / E,Q: zoom. Keeps pitch fixed for RTS readability.
## Works with window resize (no fixed-resolution assumptions).

@export var pan_speed: float = 18.0
@export var zoom_min: float = 8.0
@export var zoom_max: float = 60.0
@export var zoom_step: float = 4.0
@export var pitch_degrees: float = 50.0

var distance: float = 28.0

@onready var rig: Node3D = self


func _ready() -> void:
	rotation = Vector3(deg_to_rad(-pitch_degrees), 0.0, 0.0)
	_update_camera_offset()


func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("camera_left", "camera_right")
	input_dir.y = Input.get_axis("camera_forward", "camera_backward")
	if input_dir.length() > 0.01:
		var yaw := rotation.y
		var forward := Vector3(sin(yaw), 0.0, cos(yaw)) * -1.0
		var right := Vector3(cos(yaw), 0.0, -sin(yaw))
		# input.y: forward(-1)..backward(+1) -> move along -forward when pressing W
		var move := (right * input_dir.x) + (forward * -input_dir.y)
		if move.length() > 0.01:
			position += move.normalized() * pan_speed * delta * _zoom_speed_factor()

	if Input.is_action_just_pressed("camera_zoom_in"):
		distance = clampf(distance - zoom_step, zoom_min, zoom_max)
		_update_camera_offset()
	if Input.is_action_just_pressed("camera_zoom_out"):
		distance = clampf(distance + zoom_step, zoom_min, zoom_max)
		_update_camera_offset()


func _zoom_speed_factor() -> float:
	# Pan faster when zoomed out so long-distance navigation stays usable.
	return clampf(distance / 28.0, 0.5, 2.0)


func _update_camera_offset() -> void:
	# Camera3D is expected as a child named Camera3D.
	var cam := get_node_or_null("Camera3D") as Camera3D
	if cam:
		var pitch := deg_to_rad(pitch_degrees)
		cam.position = Vector3(0, sin(pitch), cos(pitch)) * distance
		cam.rotation = Vector3.ZERO
