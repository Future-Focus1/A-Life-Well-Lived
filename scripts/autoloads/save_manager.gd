extends Node

const ROOT := "user://"


func save_settings(data: Dictionary) -> void:
	SaveStore.write_json(SaveStore.file(ROOT, "settings.json"), data)


func save_life(mode: String, sim: LifeSim) -> void:
	if sim == null:
		return
	var name := "daily_life.json" if mode == "daily" else "fast_life.json"
	SaveStore.write_json(SaveStore.file(ROOT, name), sim.life)


func load_life(mode: String) -> Variant:
	var name := "daily_life.json" if mode == "daily" else "fast_life.json"
	return SaveStore.read_json(SaveStore.file(ROOT, name))
