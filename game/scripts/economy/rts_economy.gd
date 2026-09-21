class_name RTSEconomy
extends Node
## Single-resource (Material) economy for one faction (Phase 1.5).
## Player and enemy each own an instance with identical rules.
## Low-frequency: income ticks once per second, never per-frame scans.
## Future resources (Aether) can add sibling fields here.

signal changed

var is_player: bool = true
var material: float = 150.0
var base_income: float = 4.0 # Material per second from HQ
var bonus_income: float = 0.0 # Material per second from outposts
var pop_used: int = 0
var pop_max: int = 40

var _accum: float = 0.0


func setup(player_flag: bool, start_material: float, income_per_sec: float, max_pop: int) -> void:
	is_player = player_flag
	material = start_material
	base_income = income_per_sec
	bonus_income = 0.0
	pop_used = 0
	pop_max = max_pop
	_accum = 0.0


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 1.0:
		_accum -= 1.0
		material += income_per_sec()
		changed.emit()


func income_per_sec() -> float:
	return base_income + bonus_income


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
