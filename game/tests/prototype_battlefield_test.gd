extends SceneTree
## Prototype battlefield test: scene loads, both bases + midfield + units
## + airships present, walker GLB grounded, no errors.
## Usage: godot --headless --path game --script res://tests/prototype_battlefield_test.gd

var _frame := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/maps/prototype_battlefield.tscn")


func _fail(message: String) -> bool:
	print("PROTOTYPE_TEST NG ", message)
	quit(1)
	return true


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 20:
		return false
	var proto := get_first_node_in_group("prototype_battlefield")
	if proto == null:
		return _fail("scene missing")
	var blue := proto.get_node_or_null("BlueBase")
	var red := proto.get_node_or_null("RedBase")
	var mid := proto.get_node_or_null("Midfield")
	var units := proto.get_node_or_null("UnitsRoot")
	if blue == null or blue.get_child_count() < 5:
		return _fail("blue base incomplete")
	for role_prop in ["SupportMast", "FactoryCargo00", "AetherPylon"]:
		if blue.get_node_or_null(role_prop) == null:
			return _fail("blue role prop missing: %s" % role_prop)
	if red == null or red.get_child_count() < 4:
		return _fail("red base incomplete")
	if mid == null or mid.get_child_count() < 6:
		return _fail("midfield incomplete (want 5 walkers + titan)")
	if units == null or units.get_child_count() < 16:
		return _fail("units incomplete (want 2 airships + 16 infantry)")
	var walkers := 0
	for c in mid.get_children():
		if (c.name as String).begins_with("Walker"):
			walkers += 1
			if (c as Node3D).position.y < -0.01:
				return _fail("walker below ground")
	if walkers != 5:
		return _fail("want 5 walkers, got %d" % walkers)
	var ships := 0
	for c in units.get_children():
		if (c.name as String).begins_with("Airship"):
			ships += 1
			if (c as Node3D).scale.x > 0.5:
				return _fail("prototype airship dominates frame: %s" % c.name)
			if bool(c.get("bombard_enabled")):
				return _fail("showcase airship bombardment must stay disabled")
	if ships != 2:
		return _fail("want 2 airships, got %d" % ships)
	print("PROTOTYPE_TEST OK blue=%d red=%d walkers=5 airships=2 units=%d" % [
		blue.get_child_count(), red.get_child_count(), units.get_child_count()])
	quit(0)
	return true
