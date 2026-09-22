extends SceneTree
## Phase 1.75 visual slice test (headless). Loads the independent
## visual_slice scene and checks: city present, 10-20 units, 1 titan,
## 1 airship, selection/orders/HUD wired, combat FX fires, no crash.
## Usage: godot --headless --path game --script res://tests/visual_slice_test.gd

var _frame: int = 0
var _phase: int = 0
var _map: Node = null
var _fx_seen: bool = false
var _bloodied_seen: bool = false


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/visual_slice.tscn")


func _fail(message: String) -> bool:
	print("VISUAL_SLICE_TEST NG ", message)
	quit(1)
	return true


func _ok(message: String) -> void:
	print("VISUAL_SLICE_TEST ok: ", message)


func _process(_delta: float) -> bool:
	_frame += 1
	if VisualFX.live_count() > 0:
		_fx_seen = true
	match _phase:
		0:
			if _frame < 30:
				return false
			_map = get_first_node_in_group("visual_slice")
			if _map == null:
				return _fail("no visual_slice node")
			var units := get_nodes_in_group("rts_units")
			if units.size() < 10 or units.size() > 20:
				return _fail("units want 10-20, got %d" % units.size())
			_ok("units=%d in 10-20" % units.size())
			if get_nodes_in_group("visual_titans").size() != 1:
				return _fail("want exactly 1 titan")
			_ok("titan x1")
			if get_nodes_in_group("visual_airships").size() != 1:
				return _fail("want exactly 1 airship")
			_ok("airship x1")
			var city := _map.get_node_or_null("CityRoot") as Node3D
			if city == null or city.get_child_count() < 5:
				return _fail("city too sparse")
			_ok("city children=%d" % city.get_child_count())
			if _map.get_node_or_null("SelectionManager") == null:
				return _fail("no SelectionManager")
			if _map.get_node_or_null("OrderManager") == null:
				return _fail("no OrderManager")
			if _map.get_node_or_null("HUD") == null:
				return _fail("no HUD")
			_ok("selection/orders/HUD wired")
			var titan := get_nodes_in_group("visual_titans")[0] as Node
			if float(titan.get("hp")) < 1000.0:
				return _fail("titan hp too low")
			var ship := get_nodes_in_group("visual_airships")[0] as Node3D
			if ship.global_position.y < 10.0:
				return _fail("airship too low y=%f" % ship.global_position.y)
			_ok("titan hp + airship altitude OK")
			_phase = 1
		1:
			for o in get_nodes_in_group("rts_units"):
				var u := o as RTSUnit
				if u != null and u.bloodied:
					_bloodied_seen = true
			if _frame >= 900:
				if not _fx_seen and not _bloodied_seen:
					return _fail("no combat FX or damage in 900 frames")
				_ok("combat reads (fx=%s bloodied=%s)" % [str(_fx_seen), str(_bloodied_seen)])
				var p := 0
				var e := 0
				for o in get_nodes_in_group("rts_units"):
					var u := o as RTSUnit
					if u != null and u.is_alive():
						if u.is_player:
							p += 1
						else:
							e += 1
				print("VISUAL_SLICE_TEST alive p=%d e=%d fx_live=%d emitters=%d" % [p, e, VisualFX.live_count(), VisualFX.emitter_count()])
				# Cleanup looping vents before quit so exit has no leaked RIDs.
				var fx := _map.get_node_or_null("FxRoot") as Node3D
				if fx != null:
					for c in fx.get_children():
						c.queue_free()
				_phase = 2
				_frame = 0
		2:
			if _frame >= 15:
				print("VISUAL_SLICE_TEST OK")
				quit(0)
				return true
	return false
