extends Node

## Active daily and fast lives. Playing one never writes the other file.

const ROOT := "user://"

var settings: Dictionary = {"music": true, "sfx": true}
var daily: LifeSim
var fast: LifeSim
var last_life: LifeSim


func _ready() -> void:
	var loaded: Variant = SaveStore.read_json(SaveStore.file(ROOT, "settings.json"))
	if typeof(loaded) == TYPE_DICTIONARY:
		settings.music = bool(loaded.get("music", true))
		settings.sfx = bool(loaded.get("sfx", true))
	apply_audio()
	daily = _load_slot("daily")
	fast = _load_slot("fast")
	if daily != null:
		daily.apply_today(TimeUtil.today(), false)
		persist("daily")


func sim_for(mode: String) -> LifeSim:
	return daily if mode == "daily" else fast


func has_active(mode: String) -> bool:
	var sim := sim_for(mode)
	return sim != null and not sim.is_dead()


func active_label(mode: String) -> String:
	var sim := sim_for(mode)
	if sim == null or sim.is_dead():
		return ""
	return "%s — Age %d" % [str(sim.life.get("name", "")), sim.age_now()]


func start_new(mode: String, seed_value: int = -1) -> LifeSim:
	var seed := seed_value
	if seed < 0:
		seed = int(Time.get_ticks_usec() % 2000000000) + 1
	var sim := LifeSim.begin(mode, seed, TimeUtil.today())
	_set_slot(mode, sim)
	persist(mode)
	return sim


func prepare(mode: String) -> LifeSim:
	var sim := sim_for(mode)
	if sim == null:
		return null
	if sim.is_dead():
		persist(mode)
		return null
	if mode == "daily":
		sim.apply_today(TimeUtil.today(), false)
		persist(mode)
	return sim


func persist(mode: String) -> void:
	var sim := sim_for(mode)
	if sim == null:
		return
	if sim.is_dead():
		if not bool(sim.life.get("archived", false)):
			ArchiveStore.add(ROOT, sim.archive_record())
			sim.life["archived"] = true
		last_life = sim
		_set_slot(mode, null)
		SaveStore.remove_file(_slot_path(mode))
		return
	SaveStore.write_json(_slot_path(mode), sim.life)


func set_music(enabled: bool) -> void:
	settings.music = enabled
	_save_settings()


func set_sfx(enabled: bool) -> void:
	settings.sfx = enabled
	_save_settings()


func apply_audio() -> void:
	var music := AudioServer.get_bus_index("Music")
	if music >= 0:
		AudioServer.set_bus_mute(music, not bool(settings.music))
	var sfx := AudioServer.get_bus_index("SFX")
	if sfx >= 0:
		AudioServer.set_bus_mute(sfx, not bool(settings.sfx))


func records() -> Array:
	return ArchiveStore.load_records(ROOT)


func stats() -> Dictionary:
	return ArchiveStore.compute(records())


func _load_slot(mode: String) -> LifeSim:
	var parsed: Variant = SaveStore.read_json(_slot_path(mode))
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("mode"):
		return null
	var sim := LifeSim.new()
	sim.bind(parsed)
	if sim.is_dead():
		if not bool(sim.life.get("archived", false)):
			ArchiveStore.add(ROOT, sim.archive_record())
		SaveStore.remove_file(_slot_path(mode))
		last_life = sim
		return null
	return sim


func _set_slot(mode: String, sim: LifeSim) -> void:
	if mode == "daily":
		daily = sim
	else:
		fast = sim


func _slot_path(mode: String) -> String:
	var name := "daily_life.json" if mode == "daily" else "fast_life.json"
	return SaveStore.file(ROOT, name)


func _save_settings() -> void:
	SaveStore.write_json(SaveStore.file(ROOT, "settings.json"), settings)
	apply_audio()
