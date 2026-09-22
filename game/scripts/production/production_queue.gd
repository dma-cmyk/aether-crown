class_name ProductionQueue
extends Node
## Single production queue per HQ (Phase 1.5). Material AND Aether are
## consumed at enqueue time; population is reserved against used + queued.
## Old unit defs carry cost_aether = 0, so Phase 1.5/2A/2B/2C behavior is
## unchanged. Only the front item progresses. No per-frame searches.

signal queue_changed
signal unit_ready(def: UnitDefinition)

const MAX_QUEUED: int = 5

var queue: Array[UnitDefinition] = []
var progress_sec: float = 0.0


func is_empty() -> bool:
	return queue.is_empty()


func front() -> UnitDefinition:
	if queue.is_empty():
		return null
	return queue[0]


func front_fraction() -> float:
	var def := front()
	if def == null or def.build_time_sec <= 0.0:
		return 0.0
	return clampf(progress_sec / def.build_time_sec, 0.0, 1.0)


func front_remaining() -> float:
	var def := front()
	if def == null:
		return 0.0
	return maxf(0.0, def.build_time_sec - progress_sec)


func queued_pop() -> int:
	var total := 0
	for def in queue:
		total += def.supply_cost
	return total


## Returns "ok" or a reason code: queue_full / no_material / no_aether / no_pop.
func try_enqueue(def: UnitDefinition, economy: RTSEconomy) -> String:
	if def == null or economy == null:
		return "invalid"
	if queue.size() >= MAX_QUEUED:
		return "queue_full"
	if not economy.can_afford(float(def.cost_metal)):
		return "no_material"
	if economy.aether < float(def.cost_aether):
		return "no_aether"
	if not economy.can_house(def.supply_cost, queued_pop()):
		return "no_pop"
	economy.spend(float(def.cost_metal))
	economy.aether = maxf(0.0, economy.aether - float(def.cost_aether))
	economy.changed.emit()
	queue.append(def)
	queue_changed.emit()
	return "ok"


func _process(delta: float) -> void:
	if queue.is_empty():
		return
	progress_sec += delta
	var def := queue[0]
	if progress_sec >= def.build_time_sec:
		queue.pop_front()
		progress_sec = 0.0
		queue_changed.emit()
		unit_ready.emit(def)
