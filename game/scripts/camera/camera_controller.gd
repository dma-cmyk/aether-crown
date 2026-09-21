extends Node3D
## Quarter-view RTS camera rig (fixed pitch, no rotation in Phase 1).
## - WASD / arrows: pan (Input actions camera_forward/backward/left/right)
## - Wheel / E,Q: zoom (camera_zoom_in/out)
## - Screen-edge scroll (toggleable), map bounds clamp, smoothed pan.
## Works with window resize (no fixed-resolution assumptions).

@export var pan_speed: float = 20.0
@export var zoom_min: float = 8.0
@export var zoom_max: float = 60.0
@export var zoom_step: float = 4.0
@export var pitch_degrees: float = 50.0
@export var edge_scroll_enabled: bool = true
@export var edge_margin_px: float = 24.0
@export var map_limit: float = 58.0
@export var smoothing: float = 10.0

var distance: float = 28.0
var _pan_velocity: Vector3 = Vector3.ZERO
var _mouse_active: bool = false


func _ready() -> void:
	add_to_group("rts_camera")
	rotation = Vector3(deg_to_rad(-pitch_degrees), 0.0, 0.0)
	_update_camera_offset()


## Edge scroll starts only after the first real mouse motion, so the camera
## never drifts on startup when the cursor rests at (0,0).
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_active = true


func _process(delta: float) -> void:
	var wish := Vector3.ZERO
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("camera_left", "camera_right")
	input_dir.y = Input.get_axis("camera_forward", "camera_backward")
	if input_dir.length() > 0.01:
		var fwd := Vector3(0.0, 0.0, -1.0)
		var right := Vector3(1.0, 0.0, 0.0)
		var move := (right * input_dir.x) + (fwd * -input_dir.y)
		if move.length() > 0.01:
			wish += move.normalized()
	wish += _edge_scroll_dir()
	if wish.length() > 0.01:
		wish = wish.normalized() * pan_speed * _zoom_speed_factor()
	_pan_velocity = _pan_velocity.lerp(wish, clampf(delta * smoothing, 0.0, 1.0))
	position += _pan_velocity * delta
	position.x = clampf(position.x, -map_limit, map_limit)
	position.z = clampf(position.z, -map_limit, map_limit)
	position.y = 0.0

	if Input.is_action_just_pressed("camera_zoom_in"):
		distance = clampf(distance - zoom_step, zoom_min, zoom_max)
		_update_camera_offset()
	if Input.is_action_just_pressed("camera_zoom_out"):
		distance = clampf(distance + zoom_step, zoom_min, zoom_max)
		_update_camera_offset()


func _edge_scroll_dir() -> Vector3:
	if not edge_scroll_enabled or not _mouse_active:
		return Vector3.ZERO
	var vp := get_viewport()
	if vp == null:
		return Vector3.ZERO
	var mp := vp.get_mouse_position()
	var size := vp.get_visible_rect().size
	var dir := Vector3.ZERO
	if mp.x <= edge_margin_px:
		dir.x -= 1.0
	elif mp.x >= size.x - edge_margin_px:
		dir.x += 1.0
	if mp.y <= edge_margin_px:
		dir.z -= 1.0
	elif mp.y >= size.y - edge_margin_px:
		dir.z += 1.0
	return dir


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
