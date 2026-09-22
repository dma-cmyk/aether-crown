class_name RTSEconomy
extends Node
## Dual-resource (Material + Aether) economy for one faction.
## Player and enemy each own an instance with identical rules.
## Material behaves exactly as in Phase 1.5/2A. Aether starts at 0 and is
## only granted by territory ownership (Phase 2B); nothing spends it yet.
## Low-frequency: income ticks once per second, never per-frame scans.

signal changed

var is_player: bool = true
var material: float = 150.0
var base_income: float = 4.0 # Material per second from HQ
var bonus_income: float = 0.0 # Material per second from outposts/cities
var aether: float = 0.0
var base_aether: float = 0.0 # Aether per second (base territories grant none)
var bonus_aether: float = 0.0 # Aether per second from owned territories
var pop_used: int = 0
var pop_max: int = 40

var _accum: float = 0.0


## Extra args default to zero so Phase 1.5/2A call sites keep working
## untouched and their Aether stays exactly 0.
func setup(player_flag: bool, start_material: float, income_per_sec: float, max_pop: int, start_aether: float = 0.0, base_aether_per_sec: float = 0.0) -> void:
	is_player = player_flag
	material = start_material
	base_income = income_per_sec
	bonus_income = 0.0
	aether = start_aether
	base_aether = base_aether_per_sec
	bonus_aether = 0.0
	pop_used = 0
	pop_max = max_pop
	_accum = 0.0


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 1.0:
		_accum -= 1.0
		material += income_per_sec()
		aether += aether_per_sec()
		changed.emit()


func income_per_sec() -> float:
	return base_income + bonus_income


func aether_per_sec() -> float:
	return base_aether + bonus_aether


func can_afford(cost: float) -> bool:
	return material >= cost


## Deducts cost if affordable. Returns success.
func spend(cost: float) -> bool:
	if material < cost:
		return false
	material -= cost
	changed.emit()
	return true


func can_house(pop_cost: int, queued_pop: int = 0) -> bool:
	return pop_used + queued_pop + pop_cost <= pop_max


func on_unit_completed(pop_cost: int) -> void:
	pop_used += pop_cost
	changed.emit()


func on_unit_died(pop_cost: int) -> void:
	pop_used = maxi(0, pop_used - pop_cost)
	changed.emit()
