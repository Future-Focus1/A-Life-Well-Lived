extends Node

## Memorial text is assembled from the life record, then stored on it.


func memorial_for(sim: LifeSim) -> Dictionary:
	if sim == null:
		return {}
	return sim.memorial()


func epitaph(sim: LifeSim) -> String:
	if sim == null or not sim.is_dead():
		return ""
	return str(sim.life.get("death", {}).get("epitaph", ""))
