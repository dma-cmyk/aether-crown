class_name TerritoryController
extends Node3D
## Owns all territory regions of a Phase 2B map (plain scene node, never an
## Autoload). Flow: City ownership_changed -> bind_city callback -> _recalc
## (region owners -> frontlines) -> territories_changed -> map applies
## Aether income. Recalculation happens only on ownership change, never
## per-frame.

signal territories_changed

var regions: Array = [] # TerritoryRegion, in setup() order


## Builds one child region per definition. Called once by the map.
func setup(defs: Array) -> void:
	var i := 0
	for d in defs:
		var def := d as TerritoryDefinition
		if def == null:
			continue
		var r := TerritoryRegion.new()
		r.setup(def, i)
		r.position = def.center
		add_child(r)
		regions.append(r)
		i += 1


## Manual recalc for city-less setups (showcases, tests). Map scenes with
## bound cities recalc automatically on ownership change.
func refresh() -> void:
	_recalc()


## Links a city so its ownership drives the matching region.
func bind_city(city: RTSCity) -> void:
	if city == null:
		return
	if not city.ownership_changed.is_connected(_on_city_owner_changed):
		city.ownership_changed.connect(_on_city_owner_changed.bind(city))
	_recalc()


func region_by_id(id: StringName) -> TerritoryRegion:
	for r in regions:
		var region := r as TerritoryRegion
		if region != null and region.region_id == id:
			return region
	return null


func region_by_city_id(city_id: StringName) -> TerritoryRegion:
	for r in regions:
		var region := r as TerritoryRegion
		if region != null and region.definition != null and region.definition.linked_city_id == city_id:
			return region
	return null


## Counts per owner side for HUD/tests: {"player": p, "neutral": n, "enemy": e}.
func counts() -> Dictionary:
	var c := {"player": 0, "neutral": 0, "enemy": 0}
	for r in regions:
		var region := r as TerritoryRegion
		if region == null:
			continue
		match region.owner_side:
			TerritoryRegion.Owner.PLAYER:
				c["player"] = int(c["player"]) + 1
			TerritoryRegion.Owner.ENEMY:
				c["enemy"] = int(c["enemy"]) + 1
			_:
				c["neutral"] = int(c["neutral"]) + 1
	return c


func status_lines() -> Array:
	var lines: Array = []
	for r in regions:
		var region := r as TerritoryRegion
		if region != null:
			lines.append(region.status_text())
	return lines


## Aether/sec granted to one side by its owned regions.
func aether_for(player_flag: bool) -> float:
	var total := 0.0
	var want := TerritoryRegion.Owner.PLAYER if player_flag else TerritoryRegion.Owner.ENEMY
	for r in regions:
		var region := r as TerritoryRegion
		if region != null and region.owner_side == want and region.definition != null:
			total += region.definition.aether_income_bonus
	return total


## Neighbor pairs with differing owners: each [id_a, id_b, hard].
## hard = player-vs-enemy border. Used by tests and future strategic AI.
func frontline_pairs() -> Array:
	var pairs: Array = []
	var seen := {}
	for r in regions:
		var region := r as TerritoryRegion
		if region == null or region.definition == null:
			continue
		for n in region.definition.neighbor_ids:
			var other := region_by_id(n)
			if other == null or other.owner_side == region.owner_side:
				continue
			var key := _pair_key(region.region_id, other.region_id)
			if seen.has(key):
				continue
			seen[key] = true
			var hard := (region.owner_side == TerritoryRegion.Owner.PLAYER and other.owner_side == TerritoryRegion.Owner.ENEMY) or (region.owner_side == TerritoryRegion.Owner.ENEMY and other.owner_side == TerritoryRegion.Owner.PLAYER)
			pairs.append([region.region_id, other.region_id, hard])
	return pairs


func _pair_key(a: StringName, b: StringName) -> String:
	return str(a) + "|" + str(b) if str(a) < str(b) else str(b) + "|" + str(a)


func _on_city_owner_changed(_new_owner: int, _city: RTSCity) -> void:
	_recalc()


func _recalc() -> void:
	var signature := ""
	for r in regions:
		var region := r as TerritoryRegion
		if region == null or region.definition == null:
			continue
		var owner := _resolve_owner(region)
		region.set_region_owner(owner)
		signature += "%s=%d;" % [str(region.region_id), owner]
	for r in regions:
		var region := r as TerritoryRegion
		if region == null:
			continue
		region.set_frontline(_frontline_level(region))
		signature += "%s~%d;" % [str(region.region_id), region.frontline]
	if signature != _last_signature:
		_last_signature = signature
		territories_changed.emit()


var _last_signature: String = ""


func _resolve_owner(region: TerritoryRegion) -> int:
	var def := region.definition
	if def.fixed_owner != TerritoryDefinition.FOLLOW_CITY:
		return def.fixed_owner
	var city := _find_city(def.linked_city_id)
	if city != null:
		return city.owner_side
	return TerritoryRegion.Owner.NEUTRAL


func _find_city(city_id: StringName) -> RTSCity:
	for o in get_tree().get_nodes_in_group("rts_cities"):
		var city := o as RTSCity
		if city != null and city.city_id == city_id:
			return city
	return null


func _frontline_level(region: TerritoryRegion) -> int:
	var level := TerritoryRegion.Frontline.NONE
	for n in region.definition.neighbor_ids:
		var other := region_by_id(n)
		if other == null or other.owner_side == region.owner_side:
			continue
		var hard := (region.owner_side == TerritoryRegion.Owner.PLAYER and other.owner_side == TerritoryRegion.Owner.ENEMY) or (region.owner_side == TerritoryRegion.Owner.ENEMY and other.owner_side == TerritoryRegion.Owner.PLAYER)
		if hard:
			return TerritoryRegion.Frontline.HARD
		level = TerritoryRegion.Frontline.SOFT
	return level
