class_name DistrictController
extends Node3D
## Owns 2 preset district slots per capturable city (Phase 2C scene node,
## never an Autoload). Handles build validation/payment, build timers,
## completion visuals, capture inheritance (slots stick to the city node so
## bonuses follow the new owner automatically), and a slow deterministic
## enemy-builder utility. Bonus math stays event-driven: districts_changed
## (plus city/territory ownership) triggers the map's economy recalc.

signal districts_changed

const SLOTS_PER_CITY: int = 2
const STATE_EMPTY: int = 0
const STATE_BUILDING: int = 1
const STATE_COMPLETE: int = 2
const PLOTS: Array = [Vector3(-8.5, 0, 7.5), Vector3(8.5, 0, 7.5)]

var slots: Array = [] # each: {city, index, district, def, state, progress, root}
var defs: Dictionary = {} # StringName -> DistrictDefinition
var cities: Array = []

var _icons: Dictionary = {} # RTSCity -> Label3D


## defs_list: Array[DistrictDefinition]. Called once by the map.
func setup(city_list: Array, defs_list: Array) -> void:
	cities = city_list.duplicate()
	for d in defs_list:
		var def := d as DistrictDefinition
		if def != null:
			defs[def.id] = def
	for c in cities:
		var city := c as RTSCity
		if city == null:
			continue
		for i in range(SLOTS_PER_CITY):
			var root := Node3D.new()
			root.position = city.position + (PLOTS[i] as Vector3)
			add_child(root)
			slots.append({"city": city, "index": i, "district": &"", "def": null, "state": STATE_EMPTY, "progress": 0.0, "root": root})
		var icon := Label3D.new()
		icon.position = Vector3(0, 8.6, 2.6)
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.font_size = 32
		icon.pixel_size = 0.012
		icon.modulate = Color(1, 1, 1, 1)
		icon.text = ""
		city.add_child(icon)
		_icons[city] = icon
		if not city.ownership_changed.is_connected(_on_city_owner_changed):
			city.ownership_changed.connect(_on_city_owner_changed.bind(city))


func slots_for(city: RTSCity) -> Array:
	var out: Array = []
	for s in slots:
		if (s as Dictionary)["city"] == city:
			out.append(s)
	return out


func _city_side(city: RTSCity) -> int:
	return city.owner_side if city != null else 0


## Builds into the first empty slot. Economy belongs to the builder's side.
## Returns "ok" or a reason: not_owner/no_slot/duplicate/busy/
## no_material/no_aether/unknown_district.
func try_build(city: RTSCity, district_id: StringName, eco: RTSEconomy, player_side: bool) -> String:
	if city == null or eco == null:
		return "not_owner"
	var want := 1 if player_side else 2
	if _city_side(city) != want:
		return "not_owner"
	if not defs.has(district_id):
		return "unknown_district"
	var def := defs[district_id] as DistrictDefinition
	var mine := slots_for(city)
	for s in mine:
		if str((s as Dictionary)["district"]) == str(district_id):
			return "duplicate"
	for s in mine:
		if int((s as Dictionary)["state"]) == STATE_BUILDING:
			return "busy"
	var target: Dictionary = {}
	for s in mine:
		if int((s as Dictionary)["state"]) == STATE_EMPTY:
			target = s
			break
	if target.is_empty():
		return "no_slot"
	if eco.material < float(def.material_cost):
		return "no_material"
	if eco.aether < float(def.aether_cost):
		return "no_aether"
	eco.material -= float(def.material_cost)
	eco.aether -= float(def.aether_cost)
	eco.changed.emit()
	target["district"] = district_id
	target["def"] = def
	target["state"] = STATE_BUILDING
	target["progress"] = 0.0
	DistrictVisual.build_foundation(target["root"] as Node3D)
	_refresh_icon(city)
	districts_changed.emit()
	return "ok"


func _process(delta: float) -> void:
	var done: Array = []
	for s in slots:
		var slot := s as Dictionary
		if int(slot["state"]) != STATE_BUILDING or slot["def"] == null:
			continue
		slot["progress"] = float(slot["progress"]) + delta
		var def := slot["def"] as DistrictDefinition
		if float(slot["progress"]) >= def.build_time_sec:
			done.append(slot)
	for slot in done:
		_complete(slot as Dictionary)


func _complete(slot: Dictionary) -> void:
	slot["state"] = STATE_COMPLETE
	var root := slot["root"] as Node3D
	for child in root.get_children():
		child.queue_free()
	var def := slot["def"] as DistrictDefinition
	var city := slot["city"] as RTSCity
	DistrictVisual.build_district(root, def.visual_type, city != null and city.owner_side == 1)
	_refresh_icon(city)
	districts_changed.emit()


## Sum of completed material bonuses for one side.
func material_for(player_side: bool) -> float:
	return _bonus_sum(player_side, "material_income_bonus")


## Sum of completed aether bonuses for one side.
func aether_for(player_side: bool) -> float:
	return _bonus_sum(player_side, "aether_income_bonus")


## Sum of completed population bonuses for one side.
func pop_for(player_side: bool) -> int:
	return int(_bonus_sum(player_side, "population_bonus"))


func _bonus_sum(player_side: bool, field: String) -> float:
	var want := 1 if player_side else 2
	var total := 0.0
	for s in slots:
		var slot := s as Dictionary
		if int(slot["state"]) != STATE_COMPLETE or slot["def"] == null:
			continue
		var city := slot["city"] as RTSCity
		if city == null or city.owner_side != want:
			continue
		total += float((slot["def"] as DistrictDefinition).get(field))
	return total


## True when the enemy could start a district soon: an owned city with an
## empty slot, nothing under construction, and enough Aether banked. The
## map uses this to pause enemy unit production so the AI can actually save
## the Material cost (same wallet, deferred spending, no free units).
func enemy_wants_saving(eco: RTSEconomy) -> bool:
	if eco == null or eco.aether < 25.0:
		return false
	for c in cities:
		var city := c as RTSCity
		if city == null or city.owner_side != 2:
			continue
		if _city_busy(city) or _city_full(city):
			continue
		return true
	return false


## Slow deterministic enemy builder (called by the map every ~7s, max one
## build per tick). Same costs and rules as the player. No randomness.
func enemy_ai_tick(eco: RTSEconomy) -> void:
	if eco == null:
		return
	for c in cities:
		var city := c as RTSCity
		if city == null or city.owner_side != 2:
			continue
		if _city_busy(city) or _city_full(city):
			continue
		for pick in _ranked_picks(city, eco):
			if try_build(city, pick, eco, false) == "ok":
				return


func _city_busy(city: RTSCity) -> bool:
	for s in slots_for(city):
		if int((s as Dictionary)["state"]) == STATE_BUILDING:
			return true
	return false


func _city_full(city: RTSCity) -> bool:
	for s in slots_for(city):
		if int((s as Dictionary)["state"]) == STATE_EMPTY:
			return false
	return true


func _ranked_picks(city: RTSCity, eco: RTSEconomy) -> Array:
	var owned := {}
	for s in slots_for(city):
		var d := str((s as Dictionary)["district"])
		if d != "":
			owned[d] = true
	var scored: Array = []
	var industry_score := 30.0 if eco.income_per_sec() < 6.0 else 10.0
	var pop_frac: float = float(eco.pop_used) / float(maxi(1, eco.pop_max))
	var military_score := 30.0 if pop_frac > 0.75 else 5.0
	var central_owned := false
	for c in cities:
		var other := c as RTSCity
		if other != null and str(other.city_id) == "central_city" and other.owner_side == 2:
			central_owned = true
	var aether_score := (25.0 if central_owned else 10.0) + (10.0 if eco.aether < 30.0 else 0.0)
	var order: Array = [
		[&"industry", industry_score],
		[&"military", military_score],
		[&"aether_works", aether_score],
	]
	for e in order:
		var id := (e as Array)[0] as StringName
		if not owned.has(str(id)):
			scored.append([(e as Array)[1] as float, id])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var out: Array = []
	for e in scored:
		out.append((e as Array)[1])
	return out


func _on_city_owner_changed(_new_owner: int, city: RTSCity) -> void:
	# Slots stick to the city: rebuild visuals in the new owner's colors so
	# the grown city visibly changes hands with its districts.
	for s in slots_for(city):
		var slot := s as Dictionary
		if int(slot["state"]) == STATE_EMPTY or slot["def"] == null:
			continue
		var root := slot["root"] as Node3D
		for child in root.get_children():
			child.queue_free()
		var def := slot["def"] as DistrictDefinition
		if int(slot["state"]) == STATE_BUILDING:
			DistrictVisual.build_foundation(root)
		else:
			DistrictVisual.build_district(root, def.visual_type, city.owner_side == 1)
	_refresh_icon(city)
	districts_changed.emit()


func _refresh_icon(city: RTSCity) -> void:
	if not _icons.has(city):
		return
	var parts: Array = []
	for s in slots_for(city):
		var slot := s as Dictionary
		var st := int(slot["state"])
		if st == STATE_COMPLETE:
			parts.append(_short_name(str(slot["district"])))
		elif st == STATE_BUILDING:
			parts.append("...")
	(_icons[city] as Label3D).text = " | ".join(parts)


func _short_name(district_id: String) -> String:
	match district_id:
		"industry":
			return "I"
		"military":
			return "M"
		"aether_works":
			return "A"
	return "?"


## HUD helper: textual slot states for one city.
func slot_texts(city: RTSCity) -> Array:
	var out: Array = []
	for s in slots_for(city):
		var slot := s as Dictionary
		var st := int(slot["state"])
		if st == STATE_EMPTY:
			out.append("[Empty]")
		elif st == STATE_BUILDING:
			var def := slot["def"] as DistrictDefinition
			var frac := 0.0
			if def != null and def.build_time_sec > 0.0:
				frac = clampf(float(slot["progress"]) / def.build_time_sec, 0.0, 1.0)
			out.append("[%s %.0f%%]" % [def.display_name if def != null else "?", frac * 100.0])
		else:
			var def := slot["def"] as DistrictDefinition
			out.append("[%s]" % (def.display_name if def != null else "?"))
	return out
