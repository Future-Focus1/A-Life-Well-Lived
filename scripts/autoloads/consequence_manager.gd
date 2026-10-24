extends Node

## Delayed consequences are stored on the life and resolved by LifeSim.


func schedule(sim: LifeSim, item: Dictionary) -> void:
	if sim == null:
		return
	sim.debug_add_consequence(item)


func due_count(sim: LifeSim) -> int:
	if sim == null:
		return 0
	return sim.life.get("scheduled", []).size()
