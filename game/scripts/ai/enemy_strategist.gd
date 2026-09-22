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
# HQ assault threshold counts infantry-equivalents (walkers excluded via
# _infantry_count below), so walker mixing never self-triggers the attack.
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
var city_aether: Dictionary = {} # Phase 2B: city_id (String) -> linked territory aether value. Empty on older maps.
var city_districts: Dictionary = {} # Phase 2D: city_id (String) -> completed district count. Empty on older maps.
var district_saving: bool = false # Phase 2C: set by the 2C map while the enemy can start a district soon; pauses unit production (same wallet, just deferred). False on older maps.
var infantry_def: UnitDefinition
var marksman_def: UnitDefinition
var heavy_def: UnitDefinition
## Phase 2.7: Ironstride. Optional — maps that don't wire it simply skip
## walker production (null guard in _pick_production).
var walker_def: UnitDefinition

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
	# Phase 2.7: enemy walkers join the army (orders go through the same
	# duck-typed OrderManager path; composition counts stay infantry-based
	# so the AI never spams walkers).
	for w in get_tree().get_nodes_in_group("visual_walkers"):
		if bool((w as Node).call("is_alive")) and not bool((w as Node).get("is_player")):
			force.append(w)
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
	# Phase 2.7: walker-inclusive army weight. Walkers fight but the plan
	# thresholds keep meaning "infantry battalion", not "one heavy walker".
	var infantry_count := _infantry_count(force)
	if infantry_count >= ATTACK_ARMY:
		target_city = null
		return Plan.ATTACK_PLAYER_HQ
	var defend := _threatened_own_city()
	if defend != null and infantry_count < CAPTURE_ARMY:
		target_city = defend
		return Plan.DEFEND_CITY
	# Behind on cities with a weak army: consolidate at the nearest owned
	# city instead of feeding units into defended captures. Threshold uses
	# the infantry-sized force (walkers add weight but do not trigger the
	# turtle on their own).
	if infantry_count < 6 and _city_score() < 0:
		var home := _nearest_own_city()
		if home != null:
			target_city = home
			return Plan.DEFEND_CITY
	var target := _pick_city_target()
	if target != null and infantry_count >= CAPTURE_ARMY:
		target_city = target
		return Plan.CAPTURE_CITY
	if defend != null:
		target_city = defend
		return Plan.DEFEND_CITY
	target_city = null
	return Plan.BUILD_FORCE


## Infantry-equivalent army size: RTSUnits only. Walkers stay out of plan
## thresholds so 1-2 heavy walkers never fake a full battalion.
func _infantry_count(force: Array) -> int:
	var count := 0
	for u in force:
		if not (u is VisualWalker):
			count += 1
	return count


## Own (ENEMY) city with enemy presence inside: needs defenders.
func _threatened_own_city() -> RTSCity:
	for c in cities:
		var city := c as RTSCity
		if city != null and city.owner_side == RTSCity.Owner.ENEMY and city.contested:
			return city
	return null


## Public read for the Phase 2D map: suspend district saving while any own
## city is contested so threatened cities get units first.
func is_city_threatened() -> bool:
	return _threatened_own_city() != null


## City score from the enemy side: +1 per ENEMY city, -1 per PLAYER city.
## Used to turtle when behind instead of feeding captures.
func _city_score() -> int:
	var score := 0
	for c in cities:
		var city := c as RTSCity
		if city == null:
			continue
		if city.owner_side == RTSCity.Owner.ENEMY:
			score += 1
		elif city.owner_side == RTSCity.Owner.PLAYER:
			score -= 1
	return score


## Nearest ENEMY-owned city to the enemy HQ (consolidation point).
func _nearest_own_city() -> RTSCity:
	var best: RTSCity = null
	var best_d := 1e9
	var from := enemy_hq.global_position if enemy_hq != null else Vector3.ZERO
	for c in cities:
		var city := c as RTSCity
		if city == null or city.owner_side != RTSCity.Owner.ENEMY:
			continue
		var d: Vector3 = city.global_position - from
		d.y = 0.0
		if d.length() < best_d:
			best_d = d.length()
			best = city
	return best


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
		# Phase 2B: lightly value linked territory aether (Central weighs in).
		# Empty dict on older maps, so Phase 1.5/2A behavior is unchanged.
		score += float(city_aether.get(str(city.city_id), 0.0)) * 20.0
		# Phase 2D: grown enemy-player cities are worth retaking; grown
		# neutral cities are worth denying. Empty dict on older maps.
		score += float(city_districts.get(str(city.city_id), 0)) * 8.0
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
		# Walkers have no state enum; they are re-ordered when idle
		# (no active order). RTSUnits keep the state gate.
		if u is RTSUnit:
			var unit := u as RTSUnit
			if unit.state == RTSUnit.State.IDLE or unit.state == RTSUnit.State.MOVING:
				calm.append(unit)
		elif u is VisualWalker:
			var w := u as VisualWalker
			if not w.has_move_order and not w.attack_moving and w.forced_target == null:
				calm.append(w)
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
## district_saving defers (never skips) spending while a district is near.
func _produce(force: Array) -> void:
	if district_saving:
		return
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
	# Walkers are capped against the infantry-sized force (walkers stay out
	# of rts_units): at most 1 per 6, and they cost Aether, so the AI still
	# fields infantry/marksman/heavy around them. The AI only saves toward
	# a walker once it already owns a city (aether line + expansion done).
	if walker_def != null and force.size() >= 7 and _owns_city():
		var walkers := 0
		for w in get_tree().get_nodes_in_group("visual_walkers"):
			if not bool((w as Node).get("is_player")) and bool((w as Node).call("is_alive")):
				walkers += 1
		if walkers * 6 < force.size() - walkers:
			if _can_pay(walker_def):
				return walker_def
	if heavy_def != null and force.size() >= 4 and heavies * 3 < force.size():
		if _can_pay(heavy_def):
			return heavy_def
	if marksman_def != null and marksmen * 2 < force.size():
		if _can_pay(marksman_def):
			return marksman_def
	if infantry_def != null:
		if _can_pay(infantry_def):
			return infantry_def
	return null


## True once the enemy owns at least one city: gates walker saving so the
## AI expands and secures an aether line before heavy-unit tech.
func _owns_city() -> bool:
	for c in cities:
		var city := c as RTSCity
		if city != null and city.owner_side == RTSCity.Owner.ENEMY:
			return true
	return false


## Wallet + supply check shared by every production pick (Phase 2.7:
## aether was previously only enforced at try_enqueue, so the AI could
## pick an aether unit it could never afford and stall production).
func _can_pay(def: UnitDefinition) -> bool:
	if not economy.can_afford(float(def.cost_metal)):
		return false
	if economy.aether < float(def.cost_aether):
		return false
	return economy.can_house(def.supply_cost, queue.queued_pop())
