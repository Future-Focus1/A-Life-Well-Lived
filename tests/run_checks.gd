extends SceneTree

## Headless checks for both life modes. Exit 0 only when every check passes.

var _failed := 0
const ROOT := "user://qa_life_checks/"
const PREFER := {
	"grad_fork": "kathy_uni",
	"path_kathy": "ask",
	"kathy_proposal": "propose",
	"business_fork": "partner",
	"bridge_dare": "persuade",
	"smoke_offer": "take",
	"exercise_choice": "train",
	"child_choice": "try",
	"degree_day": "job",
}
const ANIMS := [
	"idle", "walk", "sleep", "sit", "jump", "laugh", "cry", "celebrate",
	"confused", "worried", "angry", "love", "embarrassed", "sick", "injured",
	"hug", "hold_baby", "earn_money", "lose_money", "ageing", "dying",
]


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_check("autoloads and content", _content_problem())
	var fast := LifeSim.begin("fast", 424242, "2026-06-01")
	var daily := LifeSim.begin("daily", 434343, "2026-06-01")
	var fast_problem := _drive(fast, false, {})
	var daily_problem := _drive(daily, true, {})
	_check("1 fast life reaches death", "" if fast.is_dead() and fast_problem == "" else "%s age %d %s" % [fast_problem, fast.age_now(), fast.death_cause()])
	_check("1 daily life reaches death", "" if daily.is_dead() and daily_problem == "" else "%s age %d %s" % [daily_problem, daily.age_now(), daily.death_cause()])
	_check("2 daily decade per calendar day", _daily_unlock_problem())
	_check("3 fast life needs no calendar wait", _fast_advance_problem())
	_check("4 both modes share event code", _same_code_problem())
	_check("5 fast play leaves daily save untouched", _isolation_problem())
	_check("6 save and reload restores both lives", _reload_problem())
	_check("7 life stage art changes", _stage_problem())
	_check("8 Kathy persists after a choice", _kathy_problem())
	_check("9 follow-up needs its flag", _followup_problem())
	_check("10 contradictory events are excluded", _contradiction_problem())
	_check("11 delayed consequence waits for its age", _delayed_problem())
	_check("12 young death and old-age cap", _mortality_problem())
	_check("13 archive keeps the mode", _archive_problem(fast, daily))
	_check("14 memorial uses recorded history", _memorial_problem(fast))
	_check("15 two seeds diverge", _seed_problem())
	_check("16 excluded decade still has a fallback", _fallback_problem())
	_print_sample()
	print("CHECKS failed %d" % _failed)
	if _failed == 0:
		print("QA_OK")
		quit(0)
	else:
		print("QA_FAIL")
		quit(1)


func _check(label: String, detail: String) -> void:
	if detail == "":
		print("PASS ", label)
	else:
		_failed += 1
		print("FAIL ", label, " — ", detail)


func _content_problem() -> String:
	var names := [
		"GameManager", "CharacterManager", "TimeManager", "EventManager",
		"ConsequenceManager", "RelationshipManager", "NarrativeManager",
		"AnimationController", "SaveManager", "LifeHistoryManager", "ArchiveManager",
	]
	var missing: PackedStringArray = []
	for autoload_name in names:
		if get_root().get_node_or_null(autoload_name) == null:
			missing.append(autoload_name)
	if not missing.is_empty():
		return "missing " + ", ".join(missing)
	var count := EventCatalog.all_events().size()
	if count < 40 or count > 60:
		return "event count %d" % count
	var grad := EventCatalog.get_event("grad_fork")
	if str(grad.get("text", "")) != "You've graduated. What next?":
		return "graduation fork text"
	if EventCatalog.visible_choices(grad, LifeSim.begin("fast", 1, "2026-01-01").life).size() != 4:
		return "graduation fork choices"
	for anim_id in ANIMS:
		if int(SpriteBank.anim(anim_id).get("frames", 0)) < 1:
			return "anim " + anim_id
	if int(SpriteBank.anim("missing_anim").get("frames", 0)) < 1:
		return "missing anim crashed"
	if not FileAccess.file_exists("res://assets/characters/baby.png"):
		return "missing baby sheet"
	return ""


func _drive(sim: LifeSim, grant_daily: bool, prefer: Dictionary) -> String:
	var guard := 0
	var stuck := 0
	while not sim.is_dead() and guard < 900:
		guard += 1
		var before := sim.signature()
		var phase := str(sim.life.get("phase", ""))
		if phase == "birth" or phase == "consequence":
			sim.acknowledge()
		elif phase == "event":
			_choose(sim, prefer)
		elif phase == "decade_break":
			if not sim.can_advance():
				return "decade locked " + sim.signature()
			sim.acknowledge()
		elif phase == "daily_wait":
			if not grant_daily:
				return ""
			sim.debug_grant_next_day()
		else:
			return "phase " + phase
		if sim.signature() == before and not sim.is_dead():
			stuck += 1
			if stuck > 4:
				return "no progress " + sim.signature()
		else:
			stuck = 0
	if not sim.is_dead():
		return "still alive " + sim.signature()
	return ""


func _choose(sim: LifeSim, prefer: Dictionary) -> void:
	var visible := EventCatalog.visible_choices(EventCatalog.get_event(sim.current_event_id()), sim.life)
	var wanted := str(prefer.get(sim.current_event_id(), ""))
	var index := 0
	if wanted != "":
		for i in visible.size():
			if str(visible[i].get("id", "")) == wanted:
				index = i
				break
	sim.choose(index)


func _until(sim: LifeSim, stop_phase: String) -> String:
	var guard := 0
	while not sim.is_dead() and str(sim.life.get("phase", "")) != stop_phase and guard < 80:
		guard += 1
		var phase := str(sim.life.get("phase", ""))
		if phase == "birth" or phase == "consequence":
			sim.acknowledge()
		elif phase == "event":
			sim.choose(0)
		elif phase == "decade_break":
			return "unexpected break"
		else:
			return "phase " + phase
	if str(sim.life.get("phase", "")) != stop_phase:
		return sim.signature()
	return ""


func _daily_unlock_problem() -> String:
	var sim := LifeSim.begin("daily", 42, "2026-06-01")
	sim.suppress_random_death = true
	var stuck := _until(sim, "daily_wait")
	if stuck != "":
		return stuck
	if sim.can_advance():
		return "same day already open"
	var granted := int(sim.life.clock.granted_days)
	sim.apply_today("2026-06-01", false)
	if int(sim.life.clock.granted_days) != granted or sim.can_advance():
		return "same day unlocked another decade"
	sim.apply_today("2026-06-02", false)
	if int(sim.life.clock.granted_days) != granted + 1 or not sim.can_advance():
		return "next day did not unlock one decade"
	var clock := LifeSim.begin("daily", 7, "2026-01-01")
	clock.apply_today("2026-03-01", false)
	if int(clock.life.clock.granted_days) != 14:
		return "14-day cap gave %d" % int(clock.life.clock.granted_days)
	if str(clock.life.clock.notice).find("14") < 0:
		return "missing jump notice"
	clock.apply_today("2026-03-01", false)
	clock.apply_today("2025-12-01", false)
	if int(clock.life.clock.granted_days) != 14:
		return "clock moved after a repeat or a backward date"
	if str(clock.life.clock.notice).find("backwards") < 0:
		return "missing backward notice"
	clock.debug_set_today("2026-06-01")
	if int(clock.life.clock.granted_days) <= 28:
		return "debug date stayed capped"
	return ""


func _fast_advance_problem() -> String:
	var sim := LifeSim.begin("fast", 99, "2026-06-01")
	sim.suppress_random_death = true
	var stuck := _until(sim, "decade_break")
	if stuck != "":
		return stuck
	if not sim.can_advance():
		return "cannot advance"
	if int(sim.life.clock.granted_days) != 0:
		return "fast life waited on the calendar"
	var resolved := int(sim.life.decades_resolved)
	sim.acknowledge()
	if sim.is_dead():
		return ""
	if int(sim.life.decades_resolved) != resolved:
		return "decade counter changed early"
	if str(sim.life.phase) == "decade_break" or str(sim.life.phase) == "daily_wait":
		return "did not enter the next decade"
	if int(sim.life.decade_index) != resolved:
		return "next decade index"
	return ""


func _same_code_problem() -> String:
	var seed_value := 5150
	var today := "2026-06-01"
	var fast := LifeSim.begin("fast", seed_value, today)
	var daily := LifeSim.begin("daily", seed_value, today)
	if str(fast.life.rng_state) != str(daily.life.rng_state) or str(fast.life.name) != str(daily.life.name):
		return "generation diverged"
	var ticks := LifeSim.shared_ticks
	var fast_problem := _drive(fast, false, {})
	var after_fast := LifeSim.shared_ticks
	if fast_problem != "":
		return "fast " + fast_problem
	if after_fast <= ticks:
		return "fast did not tick the shared simulation"
	var daily_problem := _drive(daily, true, {})
	if daily_problem != "":
		return "daily " + daily_problem
	if LifeSim.shared_ticks <= after_fast:
		return "daily did not tick the shared simulation"
	var diff := _first_diff(_ids(fast), _ids(daily))
	if diff != "":
		return diff
	if str(fast.life.rng_state) != str(daily.life.rng_state):
		return "rng diverged"
	return ""


func _isolation_problem() -> String:
	var daily := LifeSim.begin("daily", 1001, "2026-06-01")
	_until(daily, "daily_wait")
	var path := SaveStore.file(ROOT, "daily_life.json")
	if not SaveStore.write_json(path, daily.life):
		return "could not write daily"
	var before := SaveStore.read_text(path)
	var fast := LifeSim.begin("fast", 2002, "2026-06-01")
	var problem := _drive(fast, false, {})
	if problem != "":
		return problem
	SaveStore.write_json(SaveStore.file(ROOT, "fast_life.json"), fast.life)
	if SaveStore.read_text(path) != before:
		return "daily file changed"
	return ""


func _reload_problem() -> String:
	var daily := LifeSim.begin("daily", 3003, "2026-04-02")
	var fast := LifeSim.begin("fast", 3004, "2026-04-02")
	_until(daily, "daily_wait")
	_until(fast, "decade_break")
	var daily_path := SaveStore.file(ROOT, "slot_daily.json")
	var fast_path := SaveStore.file(ROOT, "slot_fast.json")
	SaveStore.write_json(daily_path, daily.life)
	SaveStore.write_json(fast_path, fast.life)
	var daily_back := _bind_file(daily_path)
	var fast_back := _bind_file(fast_path)
	if daily_back == null or fast_back == null:
		return "reload failed"
	if daily_back.signature() != daily.signature() or fast_back.signature() != fast.signature():
		return "signature mismatch"
	if str(daily_back.life.name) != str(daily.life.name) or int(daily_back.life.seed) != 3003:
		return "daily identity"
	if str(fast_back.life.name) != str(fast.life.name) or int(fast_back.life.seed) != 3004:
		return "fast identity"
	if str(daily_back.life.rng_state) != str(daily.life.rng_state):
		return "daily rng"
	if str(fast_back.life.rng_state) != str(fast.life.rng_state):
		return "fast rng"
	if str(daily_back.life.mode) != "daily" or str(fast_back.life.mode) != "fast":
		return "mode swapped"
	return ""


func _bind_file(path: String) -> LifeSim:
	var parsed: Variant = SaveStore.read_json(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var sim := LifeSim.new()
	sim.bind(parsed)
	return sim


func _stage_problem() -> String:
	if LifeSim.stage_for_age(1) != "baby" or LifeSim.stage_for_age(70) != "elderly":
		return "stage keys"
	if SpriteBank.stage_key(0) == SpriteBank.stage_key(70):
		return "sprite key"
	if SpriteBank.sheet_path("baby") == SpriteBank.sheet_path("elderly"):
		return "sheet path"
	var look := {"skin": "fair", "hair_color": "brown", "eyes": "blue", "hair": "short"}
	var baby := SpriteBank.bake("baby", look)
	var elder := SpriteBank.bake("elderly", look)
	if baby == null or elder == null or baby.get_width() < 8 or elder.get_width() < 8:
		return "bake"
	return ""


func _kathy_problem() -> String:
	var sim := LifeSim.begin("fast", 5, "2026-01-01")
	var before := -1
	if not sim.npc_by_id("kathy").is_empty():
		before = int(sim.npc_by_id("kathy").get("affection", 0))
	if not sim.force_event("grad_fork"):
		return "missing fork"
	sim.choose(0)
	var kathy := sim.npc_by_id("kathy")
	if kathy.is_empty() or str(kathy.get("name", "")) != "Kathy":
		return "Kathy was not recorded"
	if int(kathy.get("affection", 0)) <= before:
		return "affection did not rise"
	var text := JSON.stringify(sim.life)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return "json"
	var copy := LifeSim.new()
	copy.bind(parsed)
	var again := copy.npc_by_id("kathy")
	if str(again.get("name", "")) != "Kathy" or int(again.get("affection", 0)) != int(kathy.get("affection", 0)):
		return "reload lost Kathy"
	return ""


func _followup_problem() -> String:
	var sim := LifeSim.begin("fast", 6, "2026-01-01")
	for event in EventCatalog.all_events():
		var id := str(event.get("id", ""))
		if id != "path_kathy" and not bool(event.get("fallback", false)):
			sim.life.completed_event_ids.append(id)
	sim.life.unresolved.append("path_kathy")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var blocked := EventCatalog.pick_for_age(sim.life, 20, rng)
	if str(blocked.get("id", "")) == "path_kathy" or not bool(blocked.get("fallback", false)):
		return "shown without flag: " + str(blocked.get("id", ""))
	sim.life.flags["kathy_university"] = true
	rng.seed = 1
	var open := EventCatalog.pick_for_age(sim.life, 20, rng)
	if str(open.get("id", "")) != "path_kathy":
		return "hidden with flag: " + str(open.get("id", ""))
	return ""


func _contradiction_problem() -> String:
	var sim := LifeSim.begin("fast", 8, "2026-01-01")
	for id in ["divorce_papers", "parenting_night", "business_lawsuit", "derek_embezzle"]:
		var event := EventCatalog.get_event(id)
		if event.is_empty():
			return "missing " + id
		var age := int(event.get("at_age", event.get("min_age", 0)))
		if EventCatalog.is_eligible(event, sim.life, age):
			return id + " was eligible"
	sim.life.relationship_status = "married"
	sim.life.flags["kathy_married"] = true
	var papers := EventCatalog.get_event("divorce_papers")
	if not EventCatalog.is_eligible(papers, sim.life, int(papers.get("at_age", 42))):
		return "divorce stayed hidden after marriage"
	return ""


func _delayed_problem() -> String:
	var sim := LifeSim.begin("fast", 3, "2026-01-01")
	sim.suppress_random_death = true
	sim.debug_add_consequence({
		"id": "later_hit",
		"due_age": 45,
		"chance": 1.0,
		"text": "The old habit catches up.",
		"effects": {"flags_set": ["delayed_fired"]},
	})
	sim.resolve_years_through(44)
	if bool(sim.life.flags.get("delayed_fired", false)) or sim.age_now() != 44:
		return "fired before 45"
	sim.resolve_years_through(45)
	if not bool(sim.life.flags.get("delayed_fired", false)):
		return "missing at 45"
	return ""


func _mortality_problem() -> String:
	var young := LifeSim.begin("fast", 8, "2026-01-01")
	young.force_death("accident")
	if not young.is_dead() or young.age_now() != 0 or young.death_cause() != "accident":
		return "young force"
	var old := LifeSim.begin("fast", 8, "2026-01-01")
	old.suppress_random_death = true
	if not old.resolve_years_through(110):
		return "did not end"
	if not old.is_dead() or old.age_now() != 110 or old.death_cause() != "old age":
		return "cap %d %s" % [old.age_now(), old.death_cause()]
	return ""


func _archive_problem(fast: LifeSim, daily: LifeSim) -> String:
	if not fast.is_dead() or not daily.is_dead():
		return "lives were not finished"
	SaveStore.write_json(ArchiveStore.path(ROOT), [])
	ArchiveStore.add(ROOT, fast.archive_record())
	ArchiveStore.add(ROOT, daily.archive_record())
	var records := ArchiveStore.load_records(ROOT)
	if records.size() < 2:
		return "records %d" % records.size()
	if str(records[0].get("mode", "")) != "fast" or str(records[1].get("mode", "")) != "daily":
		return "modes"
	var stats := ArchiveStore.compute(records)
	if int(stats.get("total_lives", 0)) != 2:
		return "stats"
	return ""


func _memorial_problem(sim: LifeSim) -> String:
	if sim == null or not sim.is_dead():
		return "no finished life"
	var card := sim.memorial()
	var facts: Dictionary = sim.life.get("facts", {})
	if str(card.get("full_name", "")) != str(sim.life.get("name", "")):
		return "name"
	if str(card.get("cause", "")) != sim.death_cause():
		return "cause"
	if int(card.get("age", -1)) != int(sim.life.get("death", {}).get("age", -2)):
		return "age"
	if int(card.get("birth_year", 0)) != int(sim.life.get("birth_year", -1)):
		return "birth year"
	if int(card.get("death_year", 0)) != int(sim.life.get("birth_year", 0)) + int(card.get("age", 0)):
		return "death year"
	var jobs: Array = facts.get("jobs", [])
	if jobs.is_empty():
		if str(card.get("career", "")) != "":
			return "invented career"
	elif str(card.get("career", "")) != str(jobs[jobs.size() - 1]):
		return "career"
	var achievements: Array = facts.get("achievements", [])
	for item in card.get("achievements", []):
		if not achievements.has(str(item)):
			return "invented achievement"
	var child_names: Array = []
	for child in sim.life.get("children", []):
		child_names.append(str(child.get("name", "")))
	for item in card.get("children", []):
		if not child_names.has(str(item)):
			return "invented child"
	var npc_names: Array = []
	for npc in sim.life.get("npcs", []):
		npc_names.append(str(npc.get("name", "")))
	for line in card.get("relationships", []):
		var npc_name := str(line).split(" — ")[0]
		if not npc_names.has(npc_name):
			return "invented relationship"
	var recorded: Array = facts.get("memorable", [])
	for row in sim.life.get("history", []):
		recorded.append(str(row.get("text", "")))
		recorded.append(str(row.get("outcome", "")))
	for item in card.get("memorable", []):
		if not recorded.has(str(item)):
			return "invented memory"
	var epitaph := str(card.get("epitaph", ""))
	if epitaph == "" or epitaph != str(sim.life.get("death", {}).get("epitaph", "")):
		return "epitaph"
	for token in ["Kathy", "Derek"]:
		if epitaph.find(token) >= 0 and not npc_names.has(token) and str(sim.life.get("name", "")).find(token) < 0:
			return "epitaph names " + token
	return ""


func _seed_problem() -> String:
	var pairs := [[11, 29], [3, 9], [101, 808], [12, 90]]
	for pair in pairs:
		var left := LifeSim.begin("fast", int(pair[0]), "2026-01-01")
		var right := LifeSim.begin("fast", int(pair[1]), "2026-01-01")
		var left_problem := _drive(left, false, {})
		var right_problem := _drive(right, false, {})
		if left_problem != "" or right_problem != "":
			return left_problem + " " + right_problem
		if _first_diff(_ids(left), _ids(right)) != "":
			return ""
	return "sequences matched"


func _fallback_problem() -> String:
	var sim := LifeSim.begin("fast", 1, "2026-01-01")
	for event in EventCatalog.all_events():
		if not bool(event.get("fallback", false)):
			sim.life.completed_event_ids.append(str(event.get("id", "")))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var saw := false
	for age in [4, 14, 25, 33, 48, 66, 81, 95]:
		var picked := EventCatalog.pick_for_age(sim.life, age, rng)
		saw = true
		if not bool(picked.get("fallback", false)):
			return "age %d returned %s" % [age, str(picked.get("id", ""))]
	if not saw:
		return "no ages"
	return ""


func _ids(sim: LifeSim) -> PackedStringArray:
	var ids: PackedStringArray = []
	for row in sim.life.get("history", []):
		ids.append(str(row.get("event_id", "")))
	return ids


func _first_diff(left: PackedStringArray, right: PackedStringArray) -> String:
	var count := mini(left.size(), right.size())
	for index in count:
		if left[index] != right[index]:
			return "event %d %s vs %s" % [index, left[index], right[index]]
	if left.size() != right.size():
		return "length %d vs %d" % [left.size(), right.size()]
	return ""


func _print_sample() -> void:
	var sim := LifeSim.begin("fast", 20261024, "2026-10-24")
	var problem := _drive(sim, false, PREFER)
	print("FAST_LIFE seed=20261024 name=%s born=%s died=%s age=%s cause=%s" % [
		str(sim.life.get("name", "")),
		str(sim.life.get("birth_year", "")),
		str(sim.life.get("death", {}).get("year", "")),
		str(sim.life.get("death", {}).get("age", sim.age_now())),
		str(sim.death_cause()),
	])
	if problem != "":
		print("FAST_LIFE problem=", problem)
	for row in sim.life.get("history", []):
		var event_id := str(row.get("event_id", ""))
		if event_id in ["grad_fork", "path_kathy", "kathy_proposal", "business_fork", "bridge_dare", "derek_embezzle", "smoke_offer", "child_choice", "degree_day", "death"]:
			print("FAST_LIFE age %s %s -> %s | %s" % [
				str(row.get("age", "")),
				event_id,
				str(row.get("choice_id", "")),
				str(row.get("outcome", row.get("text", ""))),
			])
	print("FAST_LIFE epitaph=", str(sim.life.get("death", {}).get("epitaph", "")))
