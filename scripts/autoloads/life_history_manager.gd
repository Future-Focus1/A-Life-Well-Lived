extends Node

## Appends only what actually happened.


func append(sim: LifeSim, entry: Dictionary) -> void:
	if sim == null:
		return
	sim.life.history.append(entry)


func entries(sim: LifeSim) -> Array:
	if sim == null:
		return []
	return sim.life.get("history", [])
