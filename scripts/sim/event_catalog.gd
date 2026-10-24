class_name EventCatalog
extends RefCounted

## Loads res://data/events/*.json and decides which templates can fire.

static var _events: Array = []
static var _by_id: Dictionary = {}
static var _loaded: bool = false

const FRIEND_ROLES: Array = ["friend", "classmate", "crush", "partner", "spouse"]


static func ensure_loaded() -> void:
	if _loaded:
		return
	_events = []
	_by_id = {}
	var folder := "res://data/events"
	var names: PackedStringArray = DirAccess.get_files_at(folder)
	var files: Array = []
	for name in names:
		if str(name).ends_with(".json"):
			files.append(str(name))
	files.sort()
	for name in files:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(folder + "/" + str(name)))
		var rows: Array = []
		if typeof(parsed) == TYPE_ARRAY:
			rows = parsed
		elif typeof(parsed) == TYPE_DICTIONARY and parsed.has("events"):
			rows = parsed.events
		for row in rows:
			if typeof(row) != TYPE_DICTIONARY or not row.has("id"):
				continue
			_events.append(row)
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	for row in _events:
		_by_id[str(row.get("id", ""))] = row
	_loaded = true


static func all_events() -> Array:
	ensure_loaded()
	return _events


static func get_event(id: String) -> Dictionary:
	ensure_loaded()
	if _by_id.has(id):
		return _by_id[id]
	return {}


static func is_eligible(event: Dictionary, life: Dictionary, age: int) -> bool:
	if event.is_empty():
		return false
	if age < int(event.get("min_age", 0)) or age > int(event.get("max_age", 120)):
		return false
	return passes_rules(event, life, true)


static func passes_rules(event: Dictionary, life: Dictionary, honour_shown: bool) -> bool:
	if event.is_empty():
		return false
	var id := str(event.get("id", ""))
	if bool(event.get("once", true)) and _list(life, "completed_event_ids").has(id):
		return false
	if honour_shown and _list(life, "shown_this_decade").has(id) and not bool(event.get("fallback", false)):
		return false
	if not _placeholder_ok(event, life):
		return false
	if not _requirements_ok(event.get("requires", {}), life):
		return false
	if _excluded(event.get("excludes", {}), life):
		return false
	var visible := visible_choices(event, life)
	return visible.size() >= 2


static func visible_choices(event: Dictionary, life: Dictionary) -> Array:
	var out: Array = []
	var raw := 0
	for choice in event.get("choices", []):
		if typeof(choice) == TYPE_DICTIONARY and choice_ok(choice, life):
			var copy: Dictionary = choice.duplicate(true)
			copy["raw_index"] = raw
			out.append(copy)
		raw += 1
	return out


static func choice_ok(choice: Dictionary, life: Dictionary) -> bool:
	return _requirements_ok(choice.get("requires", {}), life)


static func plan_ages(life: Dictionary, lo: int, hi: int, rng: RandomNumberGenerator) -> Dictionary:
	ensure_loaded()
	var primary: Array = []
	var extra: Array = []
	for event in _events:
		if bool(event.get("fallback", false)):
			continue
		if bool(event.get("once", true)) and _list(life, "completed_event_ids").has(str(event.get("id", ""))):
			continue
		if not passes_rules(event, life, false):
			continue
		var slot := _reserve_slot(event, lo, hi)
		if slot < 0:
			continue
		if bool(event.get("priority", false)):
			if not primary.has(slot):
				primary.append(slot)
		elif bool(event.get("catch_up", false)):
			if not extra.has(slot):
				extra.append(slot)
	primary.sort()
	if primary.size() > 4:
		primary = primary.slice(0, 4)
	var ages: Array = primary.duplicate()
	extra.sort()
	for slot in extra:
		if ages.size() >= 4:
			break
		if not ages.has(slot):
			ages.append(slot)
	var count: int = 2 + (rng.randi() % 3)
	var guard := 0
	while ages.size() < count and ages.size() < 4 and guard < 40:
		guard += 1
		var rolled: int = lo + (rng.randi() % 10)
		if not ages.has(rolled):
			ages.append(rolled)
	ages.sort()
	return {"ages": ages, "reserved": primary}


static func pick_for_age(life: Dictionary, age: int, rng: RandomNumberGenerator) -> Dictionary:
	ensure_loaded()
	var follow: Array = []
	var priorities: Array = []
	var pool: Array = []
	for event in _events:
		if bool(event.get("fallback", false)):
			continue
		if not is_eligible(event, life, age):
			continue
		pool.append(event)
		if _list(life, "unresolved").has(str(event.get("id", ""))):
			follow.append(event)
		if bool(event.get("priority", false)) and int(event.get("at_age", -999)) == age:
			priorities.append(event)
	var chosen_pool: Array = pool
	if not follow.is_empty():
		chosen_pool = follow
	elif not priorities.is_empty():
		chosen_pool = priorities
	else:
		chosen_pool = _cap_storylines(pool, life)
	if chosen_pool.is_empty():
		return fallback_for(life, age)
	return _weighted(chosen_pool, life, rng)


static func fallback_for(life: Dictionary, age: int) -> Dictionary:
	ensure_loaded()
	var fresh: Array = []
	var any: Array = []
	for event in _events:
		if not bool(event.get("fallback", false)):
			continue
		if age < int(event.get("min_age", 0)) or age > int(event.get("max_age", 120)):
			continue
		any.append(event)
		if not _list(life, "shown_this_decade").has(str(event.get("id", ""))):
			fresh.append(event)
	var pool: Array = fresh if not fresh.is_empty() else any
	if pool.is_empty():
		for event in _events:
			if bool(event.get("fallback", false)):
				return event
		return {}
	return pool[0]


static func weight_of(event: Dictionary, life: Dictionary) -> float:
	var weight := float(event.get("weight", 1.0))
	if _list(life, "unresolved").has(str(event.get("id", ""))):
		weight *= 4.0
	var bias: Dictionary = event.get("bias", {})
	for key in bias.keys():
		var value := 5.0
		var personality: Dictionary = life.get("personality", {})
		var stats: Dictionary = life.get("stats", {})
		if personality.has(key):
			value = float(personality[key])
		elif stats.has(key):
			value = float(stats[key]) / 10.0
		var tilt := (value - 5.0) / 5.0
		weight *= maxf(0.25, 1.0 + tilt * float(bias[key]) * 0.35)
	return maxf(weight, 0.01)


static func friend_name(life: Dictionary) -> String:
	for npc in life.get("npcs", []):
		if typeof(npc) != TYPE_DICTIONARY:
			continue
		if not bool(npc.get("alive", true)):
			continue
		if FRIEND_ROLES.has(str(npc.get("role", ""))):
			return str(npc.get("name", ""))
	return ""


static func find_npc(life: Dictionary, id: String) -> Dictionary:
	for npc in life.get("npcs", []):
		if typeof(npc) == TYPE_DICTIONARY and str(npc.get("id", "")) == id:
			return npc
	return {}


static func npc_is_alive(life: Dictionary, id: String) -> bool:
	var npc := find_npc(life, id)
	return not npc.is_empty() and bool(npc.get("alive", true))


static func _reserve_slot(event: Dictionary, lo: int, hi: int) -> int:
	var at := int(event.get("at_age", -999))
	if bool(event.get("priority", false)) and at >= lo and at <= hi:
		return at
	if bool(event.get("catch_up", false)):
		if at >= lo and at <= hi:
			return at
		var catch_at := int(event.get("catch_at", -999))
		if catch_at >= lo and catch_at <= hi:
			return catch_at
	return -1


static func _cap_storylines(pool: Array, life: Dictionary) -> Array:
	var used: Dictionary = life.get("storylines_used", {})
	var filtered: Array = []
	for event in pool:
		var storyline := str(event.get("storyline", ""))
		if storyline != "" and int(used.get(storyline, 0)) >= 1:
			continue
		filtered.append(event)
	if filtered.is_empty():
		return pool
	return filtered


static func _weighted(pool: Array, life: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if pool.is_empty():
		return {}
	var total := 0.0
	var weights: Array = []
	for event in pool:
		var weight := weight_of(event, life)
		weights.append(weight)
		total += weight
	var roll := rng.randf() * total
	var cursor := 0.0
	for index in pool.size():
		cursor += float(weights[index])
		if roll <= cursor:
			return pool[index]
	return pool[pool.size() - 1]


static func _requirements_ok(rules: Variant, life: Dictionary) -> bool:
	if typeof(rules) != TYPE_DICTIONARY or rules.is_empty():
		return true
	var flags: Dictionary = life.get("flags", {})
	for flag in rules.get("flags", []):
		if not bool(flags.get(str(flag), false)):
			return false
	for flag in rules.get("missing_flags", []):
		if bool(flags.get(str(flag), false)):
			return false
	var any_of: Array = rules.get("any_flags", [])
	if not any_of.is_empty():
		var hit := false
		for flag in any_of:
			if bool(flags.get(str(flag), false)):
				hit = true
				break
		if not hit:
			return false
	var relationship: Array = rules.get("relationship", [])
	if not relationship.is_empty() and not relationship.has(str(life.get("relationship_status", ""))):
		return false
	var not_relationship: Array = rules.get("not_relationship", [])
	if not_relationship.has(str(life.get("relationship_status", ""))):
		return false
	if bool(rules.get("has_children", false)) and _list(life, "children").is_empty():
		return false
	if bool(rules.get("no_children", false)) and not _list(life, "children").is_empty():
		return false
	if rules.has("min_wealth") and int(round(float(life.get("stats", {}).get("wealth", 0)))) < int(rules.min_wealth):
		return false
	if rules.has("max_wealth") and int(round(float(life.get("stats", {}).get("wealth", 0)))) > int(rules.max_wealth):
		return false
	var education: Array = rules.get("education_in", [])
	if not education.is_empty() and not education.has(str(life.get("education", ""))):
		return false
	if str(rules.get("npc_id", "")) != "":
		var npc := find_npc(life, str(rules.npc_id))
		var must_live := bool(rules.get("npc_alive", true))
		if must_live:
			if npc.is_empty() or not bool(npc.get("alive", true)):
				return false
		elif not npc.is_empty() and bool(npc.get("alive", true)):
			return false
	return true


static func _excluded(rules: Variant, life: Dictionary) -> bool:
	if typeof(rules) != TYPE_DICTIONARY or rules.is_empty():
		return false
	var flags: Dictionary = life.get("flags", {})
	for flag in rules.get("flags", []):
		if bool(flags.get(str(flag), false)):
			return true
	var relationship: Array = rules.get("relationship", [])
	if relationship.has(str(life.get("relationship_status", ""))):
		return true
	return false


static func _placeholder_ok(event: Dictionary, life: Dictionary) -> bool:
	for token in event.get("placeholders", []):
		var name := str(token)
		if name == "friend_name" and friend_name(life) == "":
			return false
		if name == "child_name" and _list(life, "children").is_empty():
			return false
	return true


static func _list(life: Dictionary, key: String) -> Array:
	var value: Variant = life.get(key, [])
	if typeof(value) == TYPE_ARRAY:
		return value
	return []
