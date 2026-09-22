class_name EnemyStrategist
extends Node3D
## Phase 1.5 enemy strategy layer on top of the Phase 1 combat AI.
## Simple state machine, 2s think ticks (never per-frame). The AI obeys the
## same economy rules as the player: no free units, same costs/times/pop.

signal plan_changed(new_plan: int)

enum Plan { BUILD_FORCE, CAPTURE_OUTPOST, DEFEND_OUTPOST, ATTACK_PLAYER_HQ, CAPTURE_CITY, DEFEND_CITY }

const THINK_INTERVAL: float = 2.0
const REISSUE_INTERVAL: float = 12.0
const CAPTURE_ARMY: int = 4
const ATTACK_ARMY: int = 12

var ai_enabled: bool = true
var plan: int = Plan.BUILD_FORCE

# Wired by the match map before play starts.
var economy: RTSEconomy
var queue: ProductionQueue
var orders: OrderManager
var map_nav: MapNav
var match_mgr: MatchManager
var enemy_hq: RTSBuilding
var player_hq: RTSBuilding
var outpost: RTSOutpost
var cities: Array = [] # Phase 2A: RTSCity list. Empty on the Phase 1.5 map.
var target_city: RTSCity = null # Phase 2A: city chosen by _decide_city.
var infantry_def: UnitDefinition
var marksman_def: UnitDefinition
var heavy_def: UnitDefinition

var _think_left: float = 2.0
var _reissue_left: float = REISSUE_INTERVAL


func plan_name() -> String:
	match plan:
		Plan.BUILD_FORCE:
			return "BUILD_FORCE"
		Plan.CAPTURE_OUTPOST:
			return "CAPTURE_OUTPOST"
		Plan.DEFEND_OUTPOST:
			return "DEFEND_OUTPOST"
		Plan.ATTACK_PLAYER_HQ:
			return "ATTACK_PLAYER_HQ"
		Plan.CAPTURE_CITY:
			return "CAPTURE_CITY"
		Plan.DEFEND_CITY:
			return "DEFEND_CITY"
	return "?"


func _process(delta: float) -> void:
	if not ai_enabled:
		return
	if match_mgr != null and not match_mgr.is_playing():
		return
	if economy == null or queue == null or orders == null:
		return
	_think_left -= delta
	_reissue_left -= delta
	if _think_left <= 0.0:
		_think_left = THINK_INTERVAL
		_think()
	elif _reissue_left <= 0.0:
		_reissue_left = REISSUE_INTERVAL
		_execute_plan(army())


func army() -> Array:
	var force: Array = []
	for o in get_tree().get_nodes_in_group("rts_units"):
		var u := o as RTSUnit
		if u != null and u.is_alive() and not u.is_player:
			force.append(u)
	return force


func _think() -> void:
	var force := army()
	_produce(force)
	var new_plan := _decide(force)
	if new_plan != plan:
		plan = new_plan
		_reissue_left = REISSUE_INTERVAL
		_execute_plan(force)
		plan_changed.emit(plan)


func _decide(force: Array) -> int:
	if not cities.is_empty():
		return _decide_city(force)
	if player_hq != null and not player_hq.is_alive():
		return Plan.ATTACK_PLAYER_HQ
	var n := force.size()
	if n >= ATTACK_ARMY:
		return Plan.ATTACK_PLAYER_HQ
	var outpost_owned := outpost != null and outpost.owner_side == RTSOutpost.Owner.ENEMY
	if not outpost_owned and n >= CAPTURE_ARMY:
		return Plan.CAPTURE_OUTPOST
	if outpost_owned and n < ATTACK_ARMY:
		return Plan.DEFEND_OUTPOST
	return Plan.BUILD_FORCE


## Phase 2A city logic. Picks among neutral / player-owned cities by
## ownership priority minus distance, so the AI spreads across the map
## instead of rushing Central forever. Own contested cities pull the army
## back to defend.
func _decide_city(force: Array) -> int:
	if player_hq != null and not player_hq.is_alive():
		return Plan.ATTACK_PLAYER_HQ
	var n := force.size()
	if n >= ATTACK_ARMY:
		target_city = null
		return Plan.ATTACK_PLAYER_HQ
	var defend := _threatened_own_city()
	if defend != null and n < CAPTURE_ARMY:
		target_city = defend
		return Plan.DEFEND_CITY
	var target := _pick_city_target()
	if target != null and n >= CAPTURE_ARMY:
		target_city = target
		return Plan.CAPTURE_CITY
	if defend != null:
		target_city = defend
		return Plan.DEFEND_CITY
	target_city = null
	return Plan.BUILD_FORCE


## Own (ENEMY) city with enemy presence inside: needs defenders.
func _threatened_own_city() -> RTSCity:
	for c in cities:
		var city := c as RTSCity
		if city != null and city.owner_side == RTSCity.Owner.ENEMY and city.contested:
			return city
	return null


## Best uncaptured city: recapture (PLAYER-owned) scores above neutral,
## closer cities score above distant ones.
func _pick_city_target() -> RTSCity:
	var best: RTSCity = null
	var best_score := -1e9
	var from := enemy_hq.global_position if enemy_hq != null else Vector3.ZERO
	for c in cities:
		var city := c as RTSCity
		if city == null or city.owner_side == RTSCity.Owner.ENEMY:
			continue
		var score := 0.0
		if city.owner_side == RTSCity.Owner.PLAYER:
			score += 120.0 # recapture priority
		else:
			score += 100.0 # neutral expansion
		var d: Vector3 = city.global_position - from
		d.y = 0.0
		score -= d.length() * 1.5
		if city.contested:
			score += 15.0 # join the ongoing fight
		if score > best_score:
			best_score = score
			best = city
	return best


## Idle/MOVING units only: fighters (CHASING/ATTACKING) are never yanked.
func _execute_plan(force: Array) -> void:
	var dest := _plan_destination()
	if dest == Vector3.INF:
		return
	var calm: Array = []
	for u in force:
		var unit := u as RTSUnit
		if unit != null and (unit.state == RTSUnit.State.IDLE or unit.state == RTSUnit.State.MOVING):
			calm.append(unit)
	if calm.is_empty():
		return
	orders.issue_attack_move(calm, dest)


func _reissue() -> void:
	_execute_plan(army())


func _plan_destination() -> Vector3:
	match plan:
		Plan.BUILD_FORCE:
			if enemy_hq != null and enemy_hq.is_alive():
				return enemy_hq.global_position + Vector3(0, 0, 8.0)
		Plan.CAPTURE_OUTPOST, Plan.DEFEND_OUTPOST:
			if outpost != null:
				if plan == Plan.DEFEND_OUTPOST and enemy_hq != null:
					var dir: Vector3 = (enemy_hq.global_position - outpost.global_position)
					dir.y = 0.0
					if dir.length() > 0.01:
						return outpost.global_position + dir.normalized() * 5.0
				return outpost.global_position
		Plan.ATTACK_PLAYER_HQ:
			if player_hq != null and player_hq.is_alive():
				return player_hq.global_position
		Plan.CAPTURE_CITY, Plan.DEFEND_CITY:
			if target_city != null and is_instance_valid(target_city):
				return target_city.global_position
	return Vector3.INF


## Same wallet as the player: only enqueue what the economy can afford.
func _produce(force: Array) -> void:
	if queue.queue.size() >= 2:
		return
	var def := _pick_production(force)
	if def == null:
		return
	queue.try_enqueue(def, economy)


func _pick_production(force: Array) -> UnitDefinition:
	var heavies := 0
	var marksmen := 0
	for u in force:
		var unit := u as RTSUnit
		if unit != null and unit.definition != null:
			if unit.definition.id == &"gf_heavy_guard":
				heavies += 1
			elif unit.definition.id == &"gf_marksman":
				marksmen += 1
	if heavy_def != null and force.size() >= 4 and heavies * 3 < force.size():
		if economy.can_afford(float(heavy_def.cost_metal)) and economy.can_house(heavy_def.supply_cost, queue.queued_pop()):
			return heavy_def
	if marksman_def != null and marksmen * 2 < force.size():
		if economy.can_afford(float(marksman_def.cost_metal)) and economy.can_house(marksman_def.supply_cost, queue.queued_pop()):
			return marksman_def
	if infantry_def != null:
		if economy.can_afford(float(infantry_def.cost_metal)) and economy.can_house(infantry_def.supply_cost, queue.queued_pop()):
			return infantry_def
	return null
