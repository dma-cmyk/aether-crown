extends Control
## Drag-selection rectangle overlay. Mouse-ignorant; drawn under HUD text.

var _rect := Rect2()
var _active := false


func _ready() -> void:
	add_to_group("selection_box")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func set_box(a: Vector2, b: Vector2) -> void:
	_rect = Rect2(a, b - a).abs()
	_active = true
	queue_redraw()


func hide_box() -> void:
	_active = false
	queue_redraw()


func _draw() -> void:
	if not _active or _rect.size.length() < 4.0:
		return
	draw_rect(_rect, Color(0.4, 0.8, 1.0, 0.15), true)
	draw_rect(_rect, Color(0.4, 0.8, 1.0, 0.9), false, 1.5)
