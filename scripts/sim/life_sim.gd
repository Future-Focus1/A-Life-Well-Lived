class_name LifeSim
extends RefCounted

## One life, one seed, both time modes. Daily and Fast call these same methods.

static var shared_ticks: int = 0

var life: Dictionary = {}
var suppress_random_death: bool = false

const STAT_KEYS: Array = [
	"health", "happiness", "intelligence", "fitness", "charisma",
	"ambition", "creativity", "stress", "wealth", "luck",
]
const PERSONALITY_KEYS: Array = [
	"intelligence", "confidence", "ambition", "kindness", "sociability",
	"risk_tolerance", "athleticism", "creativity", "luck",
]


static func begin(mode: String, seed_value: int, today: String) -> LifeSim:
	var sim := LifeSim.new()
	sim.life = _build(mode, seed_value, today)
	return sim


func bind(data: Dictionary) -> void:
	life = data
	_normalize()


func export_life() -> Dictionary:
	return life


func is_dead() -> bool:
	return str(life.get("phase", "")) == "dead"


func age_now() -> int:
	return int(life.get("age", 0))


func death_cause() -> String:
	return str(life.get("death", {}).get("cause", ""))


func current_event_id() -> String:
	return str(life.get("current_event_id", ""))


func unlocked_count() -> int:
	if str(life.get("mode", "")) != "daily":
		return 99
	return 1 + int(life.get("clock", {}).get("granted_days", 0))


func can_advance() -> bool:
	if is_dead():
		return false
	var phase := str(life.get("phase", ""))
	if phase != "decade_break" and phase != "daily_wait":
		return false
	if str(life.get("mode", "")) == "fast":
		return phase == "decade_break"
	return int(life.get("decades_resolved", 0)) < unlocked_count()


func signature() -> String:
	return "%s|%s|%s|%s|%s|%s" % [
		str(life.get("phase", "")),
		str(life.get("current_event_id", "")),
		str(life.get("decade_pos", 0)),
		str(life.get("age", 0)),
		str(life.get("decades_resolved", 0)),
		str(life.get("clock", {}).get("granted_days", 0)),
	]


func acknowledge() -> void:
	if is_dead():
		return
	var phase := str(life.get("phase", ""))
	if phase == "birth":
		begin_decade(0)
	elif phase == "consequence":
		_after_consequence()
	elif phase == "decade_break" or phase == "daily_wait":
		if can_advance():
			begin_decade(int(life.get("decades_resolved", 0)))


func choose(visible_index: int) -> void:
	if str(life.get("phase", "")) != "event":
		return
	shared_ticks += 1
	var event := EventCatalog.get_event(current_event_id())
	if event.is_empty():
		life.phase = "consequence"
		return
	var visible := EventCatalog.visible_choices(event, life)
	if visible.is_empty():
		life.phase = "consequence"
		return
	var index := clampi(visible_index, 0, visible.size() - 1)
	var choice: Dictionary = visible[index]
	var rng := _rng()
	_apply(choice.get("effects", {}), rng)
	var outcome := _roll_outcome(choice, rng)
	_apply(outcome.get("effects", {}), rng)
	_queue_delayed(choice.get("delayed", []), age_now())
	_queue_delayed(outcome.get("delayed", []), age_now())
	_remember_followups(choice.get("followups", []))
	_insert_followup_ages(choice.get("followups", []))
	if bool(event.get("once", true)):
		_append_unique(life.completed_event_ids, str(event.get("id", "")))
	_erase_unresolved(str(event.get("id", "")))
	var storyline := str(event.get("storyline", ""))
	if storyline != "":
		life.storylines_used[storyline] = int(life.storylines_used.get(storyline, 0)) + 1
	_append_unique(life.choice_ids, str(choice.get("id", "")))
	var event_text := _fill(str(event.get("text", "")))
	var outcome_text := _fill(str(outcome.get("text", "")))
	var memorable := str(choice.get("effects", {}).get("memorable", "")) != "" or str(outcome.get("effects", {}).get("memorable", "")) != ""
	life.history.append({
		"age": age_now(),
		"year": int(life.birth_year) + age_now(),
		"event_id": str(event.get("id", "")),
		"choice_id": str(choice.get("id", "")),
		"text": event_text,
		"outcome": outcome_text,
		"memorable": memorable,
	})
	var animation := str(outcome.get("animation", ""))
	if animation == "":
		animation = str(choice.get("animation", ""))
	if animation == "":
		animation = str(event.get("animation", "idle"))
	var background := str(event.get("background", "auto"))
	life.pending = {
		"text": outcome_text,
		"event_text": event_text,
		"animation": animation,
		"background": background,
		"npc": str(event.get("npc", "")),
	}
	_keep(rng)
	var death := str(outcome.get("death", ""))
	if death != "":
		_die(death)
		return
	life.phase = "consequence"


func begin_decade(index: int) -> void:
	if is_dead():
		return
	life.decade_index = index
	life.decade_pos = 0
	life.shown_this_decade = []
	life.storylines_used = {}
	var lo := index * 10
	if lo >= 110:
		resolve_years_through(110)
		return
	var rng := _rng()
	var plan: Dictionary = EventCatalog.plan_ages(life, lo, lo + 9, rng)
	_keep(rng)
	life.decade_ages = plan.get("ages", [])
	life.reserved_ages = plan.get("reserved", [])
	_present_from_pos()


func resolve_years_through(target: int) -> bool:
	var year := int(life.last_resolved_age) + 1
	while year <= target:
		if _resolve_year(year):
			return true
		year += 1
	if not is_dead() and age_now() < target:
		life.age = target
		_update_stage()
	return is_dead()


func apply_today(system_date: String, uncap: bool) -> void:
	if str(life.get("mode", "")) != "daily":
		return
	var clock: Dictionary = life.clock
	var trusted := str(clock.get("last_trusted", system_date))
	if system_date < trusted:
		clock.notice = "The clock went backwards. Today stays put."
		clock.effective_today = trusted
		life.clock = clock
		return
	var delta := TimeUtil.days_between(trusted, system_date)
	var grant := delta
	if delta > 14 and not uncap:
		grant = 14
		clock.notice = "The calendar jumped ahead. Only 14 decades were unlocked."
	else:
		clock.notice = ""
	clock.granted_days = int(clock.get("granted_days", 0)) + grant
	clock.last_trusted = system_date
	clock.effective_today = system_date
	life.clock = clock
	if str(life.phase) == "daily_wait" and can_advance():
		life.phase = "decade_break"


func debug_grant_next_day() -> void:
	var clock: Dictionary = life.clock
	var next := TimeUtil.add_days(str(clock.get("last_trusted", "2026-01-01")), 1)
	clock.granted_days = int(clock.get("granted_days", 0)) + 1
	clock.last_trusted = next
	clock.effective_today = next
	clock.notice = ""
	life.clock = clock
	if str(life.phase) == "daily_wait":
		life.phase = "decade_break"


func debug_set_today(date_text: String) -> void:
	var clock: Dictionary = life.clock
	var trusted := str(clock.get("last_trusted", date_text))
	if date_text <= trusted:
		clock.notice = "Debug date stays on the trusted day."
		life.clock = clock
		return
	var delta := TimeUtil.days_between(trusted, date_text)
	clock.granted_days = int(clock.get("granted_days", 0)) + delta
	clock.last_trusted = date_text
	clock.effective_today = date_text
	clock.notice = "Debug calendar advanced."
	life.clock = clock
	if str(life.phase) == "daily_wait" and can_advance():
		life.phase = "decade_break"


func debug_add_consequence(item: Dictionary) -> void:
	life.scheduled.append(item)


func force_event(id: String) -> bool:
	var event := EventCatalog.get_event(id)
	if event.is_empty():
		return false
	_show_event(event)
	return true


func force_outcome(id: String) -> void:
	life.debug_outcome = id


func force_death(cause: String = "accident") -> void:
	_die(cause)


func debug_skip_decade() -> void:
	var guard := 0
	while not is_dead() and guard < 12:
		guard += 1
		var phase := str(life.phase)
		if phase == "birth":
			acknowledge()
		elif phase == "event":
			choose(0)
		elif phase == "consequence":
			acknowledge()
		else:
			break


func npc_by_id(id: String) -> Dictionary:
	return EventCatalog.find_npc(life, id)


func prompt() -> Dictionary:
	var stats: Dictionary = life.get("stats", {})
	var info := {
		"phase": str(life.get("phase", "")),
		"name": str(life.get("name", "")),
		"age": age_now(),
		"stage": str(life.get("life_stage", "baby")),
		"stage_label": stage_label(str(life.get("life_stage", "baby"))),
		"mode": str(life.get("mode", "")),
		"health": int(stats.get("health", 0)),
		"happiness": int(stats.get("happiness", 0)),
		"wealth": int(stats.get("wealth", 0)),
		"appearance": life.get("appearance", {}),
		"animation": "idle",
		"background": _room("auto"),
		"text": "",
		"sub": "",
		"choices": [],
		"npc": {},
		"notice": str(life.get("clock", {}).get("notice", "")),
		"can_advance": can_advance(),
		"tagline": _tagline(),
	}
	var phase := str(info.phase)
	if phase == "birth":
		info.text = "Welcome to the world, %s!" % str(life.get("name", ""))
		info.sub = str(life.get("facts", {}).get("family", ""))
		info.animation = "idle"
		info.background = _room("home")
	elif phase == "event":
		var event := EventCatalog.get_event(current_event_id())
		info.text = _fill(str(event.get("text", "")))
		info.animation = str(event.get("animation", "idle"))
		info.background = _room(str(event.get("background", "auto")))
		info.choices = _choice_buttons(event)
		info.npc = _npc_view(str(event.get("npc", "")))
	elif phase == "consequence":
		var pending: Dictionary = life.get("pending", {})
		info.text = str(pending.get("text", ""))
		info.animation = str(pending.get("animation", "idle"))
		info.background = _room(str(pending.get("background", "auto")))
		info.npc = _npc_view(str(pending.get("npc", "")))
	elif phase == "decade_break":
		info.text = "The next decade is open."
		info.sub = "Nothing is chosen until you continue."
		info.animation = "ageing"
		info.background = _room("auto")
	elif phase == "daily_wait":
		info.text = "Another decade awaits tomorrow..."
		info.sub = TimeUtil.countdown_text()
		info.animation = "idle"
		info.background = _room("auto")
	elif phase == "dead":
		info.text = "A life closes at age %d." % int(life.get("death", {}).get("age", age_now()))
		info.sub = str(life.get("death", {}).get("cause", ""))
		info.animation = "dying"
		info.background = _room("auto")
	return info


func memorial() -> Dictionary:
	var death: Dictionary = life.get("death", {})
	var facts: Dictionary = life.get("facts", {})
	var jobs: Array = facts.get("jobs", [])
	var career := ""
	if not jobs.is_empty():
		career = str(jobs[jobs.size() - 1])
	var children: Array = []
	for child in life.get("children", []):
		children.append(str(child.get("name", "")))
	var relationships: Array = []
	for npc in life.get("npcs", []):
		var line := "%s — %s" % [str(npc.get("name", "")), str(npc.get("role", "someone"))]
		if not bool(npc.get("alive", true)):
			line += " (died)"
		relationships.append(line)
	var achievements: Array = []
	for item in facts.get("achievements", []):
		achievements.append(str(item))
	var memorable: Array = []
	for item in facts.get("memorable", []):
		memorable.append(str(item))
	return {
		"full_name": str(life.get("name", "")),
		"appearance": life.get("appearance", {}),
		"life_stage": str(life.get("life_stage", "")),
		"birth_year": int(life.get("birth_year", 0)),
		"death_year": int(death.get("year", 0)),
		"age": int(death.get("age", age_now())),
		"cause": str(death.get("cause", "")),
		"relationships": relationships,
		"children": children,
		"career": career,
		"money": int(life.get("stats", {}).get("wealth", 0)),
		"achievements": achievements,
		"memorable": memorable,
		"family": str(facts.get("family", "")),
		"epitaph": str(death.get("epitaph", "")),
		"marriages": int(facts.get("marriages", 0)),
	}


func archive_record() -> Dictionary:
	var card := memorial()
	var notable := str(card.get("epitaph", ""))
	if notable == "" and not card.memorable.is_empty():
		notable = str(card.memorable[0])
	return {
		"id": str(life.get("id", "")),
		"mode": str(life.get("mode", "")),
		"seed": int(life.get("seed", 0)),
		"name": card.full_name,
		"gender": str(life.get("gender", "")),
		"appearance": card.appearance,
		"life_stage": card.life_stage,
		"birth_year": card.birth_year,
		"death_year": card.death_year,
		"age": card.age,
		"cause": card.cause,
		"epitaph": card.epitaph,
		"notable": notable,
		"wealth": card.money,
		"children": life.get("children", []),
		"marriages": card.marriages,
		"career": card.career,
		"memorial": card,
		"history": life.get("history", []),
		"facts": life.get("facts", {}),
		"npcs": life.get("npcs", []),
		"flags": life.get("flags", {}),
	}


func debug_report() -> String:
	var lines: PackedStringArray = []
	lines.append("Seed %s  age %d  %s" % [str(life.get("seed", "")), age_now(), str(life.get("phase", ""))])
	var stats: Dictionary = life.get("stats", {})
	for key in STAT_KEYS:
		lines.append("%s %s" % [key, str(stats.get(key, 0))])
	var flag_names: Array = life.get("flags", {}).keys()
	flag_names.sort()
	lines.append("Flags: " + _csv(flag_names))
	var hidden: Dictionary = life.get("hidden", {})
	lines.append("Hidden talents: " + _csv(hidden.get("talents", [])))
	lines.append("Illness risk %s" % str(hidden.get("illness_risk", "")))
	lines.append("Weaknesses: " + _csv(hidden.get("weaknesses", [])))
	for npc in life.get("npcs", []):
		lines.append("%s role=%s aff=%s alive=%s" % [
			str(npc.get("name", "")),
			str(npc.get("role", "")),
			str(npc.get("affection", "")),
			str(npc.get("alive", true)),
		])
	lines.append("Unresolved: " + _csv(life.get("unresolved", [])))
	return "\n".join(lines)


static func stage_for_age(years: int) -> String:
	if years <= 2:
		return "baby"
	if years <= 12:
		return "child"
	if years <= 19:
		return "teen"
	if years <= 34:
		return "young_adult"
	if years <= 49:
		return "adult"
	if years <= 64:
		return "middle_aged"
	if years <= 79:
		return "elderly"
	return "very_elderly"


static func stage_label(stage: String) -> String:
	match stage:
		"baby":
			return "Baby"
		"child":
			return "Child"
		"teen":
			return "Teen"
		"young_adult":
			return "Young adult"
		"adult":
			return "Adult"
		"middle_aged":
			return "Middle-aged"
		"elderly":
			return "Elderly"
		"very_elderly":
			return "Very elderly"
		_:
			return "Living"


static func _build(mode: String, seed_value: int, today: String) -> Dictionary:
	var life := {
		"id": "%s-%d-%d" % [mode, seed_value, Time.get_ticks_usec() % 1000000],
		"mode": mode,
		"seed": seed_value,
		"rng_state": "",
		"first_name": "",
		"name": "",
		"gender": "",
		"birth_year": 2000,
		"age": 0,
		"last_resolved_age": 0,
		"life_stage": "baby",
		"appearance": {},
		"personality": {},
		"hidden": {},
		"stats": {},
		"education": "none",
		"qualifications": [],
		"career": "",
		"employment": "none",
		"income": 0,
		"debt": 0,
		"housing": "family_home",
		"relationship_status": "single",
		"children": [],
		"conditions": [],
		"npcs": [],
		"completed_event_ids": [],
		"choice_ids": [],
		"presented_ids": [],
		"shown_this_decade": [],
		"flags": {},
		"unresolved": [],
		"scheduled": [],
		"milestones": [],
		"history": [],
		"facts": {
			"family": "",
			"jobs": [],
			"achievements": [],
			"memorable": [],
			"marriages": 0,
			"relationships": [],
		},
		"phase": "birth",
		"decade_index": 0,
		"decades_resolved": 0,
		"decade_ages": [],
		"decade_pos": 0,
		"reserved_ages": [],
		"storylines_used": {},
		"current_event_id": "",
		"pending": {},
		"death": {},
		"archived": false,
		"debug_outcome": "",
		"family": {},
		"clock": {
			"start_date": today,
			"last_trusted": today,
			"effective_today": today,
			"granted_days": 0,
			"notice": "",
		},
	}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var names := _names()
	var gender_roll := rng.randi() % 10
	var gender := "female"
	if gender_roll > 6:
		gender = "male"
	elif gender_roll > 4:
		gender = "nonbinary"
	life.gender = gender
	var first_pool: Array = names.get(gender, names.neutral)
	if gender == "nonbinary":
		first_pool = names.neutral
	life.first_name = str(first_pool[rng.randi() % first_pool.size()])
	var surname := str(names.surnames[rng.randi() % names.surnames.size()])
	life.name = "%s %s" % [life.first_name, surname]
	var rolled_year := 1955 + (rng.randi() % 50)
	if mode == "daily":
		life.birth_year = int(today.substr(0, 4))
	else:
		life.birth_year = rolled_year
	var hair_styles := ["short", "bob", "curly", "long", "buzz", "braids"]
	var hair_colors := ["black", "brown", "blonde", "red", "auburn"]
	var skins := ["fair", "olive", "tan", "brown", "deep"]
	var eyes := ["brown", "blue", "green", "hazel", "amber"]
	life.appearance = {
		"hair": hair_styles[rng.randi() % hair_styles.size()],
		"hair_color": hair_colors[rng.randi() % hair_colors.size()],
		"skin": skins[rng.randi() % skins.size()],
		"eyes": eyes[rng.randi() % eyes.size()],
	}
	var personality := {}
	for key in PERSONALITY_KEYS:
		personality[key] = 1 + (rng.randi() % 10)
	life.personality = personality
	var talents := ["music", "maths", "sport", "art", "language", "machines", "people", "cooking"]
	var weaknesses := ["lungs", "heart", "joints", "anxiety", "allergies"]
	var talent_count := 1 + (rng.randi() % 2)
	var picked: Array = []
	while picked.size() < talent_count:
		var talent: String = talents[rng.randi() % talents.size()]
		if not picked.has(talent):
			picked.append(talent)
	var weak: Array = []
	var weak_count := rng.randi() % 3
	while weak.size() < weak_count:
		var item: String = weaknesses[rng.randi() % weaknesses.size()]
		if not weak.has(item):
			weak.append(item)
	life.hidden = {
		"talents": picked,
		"illness_risk": 1 + (rng.randi() % 10),
		"weaknesses": weak,
	}
	var circumstances: Array = ["struggling", "modest", "comfortable", "wealthy"]
	var circumstance: String = circumstances[rng.randi() % circumstances.size()]
	var parents: Array = ["both parents", "one parent", "guardians"]
	var parent: String = parents[rng.randi() % parents.size()]
	var siblings := rng.randi() % 4
	life.family = {"circumstances": circumstance, "parents": parent, "siblings": siblings}
	life.flags["family_%s" % circumstance] = true
	var starting_wealth := 30
	var happiness_mod := 0
	match circumstance:
		"struggling":
			starting_wealth = 10
			happiness_mod = -8
		"modest":
			starting_wealth = 30
			happiness_mod = 0
		"comfortable":
			starting_wealth = 80
			happiness_mod = 6
		"wealthy":
			starting_wealth = 220
			happiness_mod = 8
	life.stats = {
		"health": clampi(70 + (rng.randi() % 25), 0, 100),
		"happiness": clampi(55 + happiness_mod + (rng.randi() % 15), 0, 100),
		"intelligence": clampi(int(personality.intelligence) * 8 + (rng.randi() % 12), 0, 100),
		"fitness": clampi(int(personality.athleticism) * 8 + (rng.randi() % 10), 0, 100),
		"charisma": clampi(int(personality.sociability) * 6 + int(personality.confidence) * 2, 0, 100),
		"ambition": clampi(int(personality.ambition) * 9, 0, 100),
		"creativity": clampi(int(personality.creativity) * 8, 0, 100),
		"stress": clampi(18 + (10 - int(personality.confidence)) * 2, 0, 100),
		"wealth": starting_wealth,
		"luck": clampi(int(personality.luck) * 8 + (rng.randi() % 15), 0, 100),
	}
	var sibling_text := "no siblings"
	if siblings == 1:
		sibling_text = "1 sibling"
	elif siblings > 1:
		sibling_text = "%d siblings" % siblings
	var family_line := "Born into a %s household with %s and %s." % [circumstance, parent, sibling_text]
	life.facts.family = family_line
	life.history.append({
		"age": 0,
		"year": int(life.birth_year),
		"event_id": "birth",
		"choice_id": "",
		"text": family_line,
		"outcome": "Welcome to the world, %s!" % life.name,
		"memorable": true,
	})
	life.facts.memorable.append(family_line)
	life.rng_state = str(rng.state)
	return life


func _normalize() -> void:
	life.seed = int(life.get("seed", 1))
	life.age = int(life.get("age", 0))
	life.last_resolved_age = int(life.get("last_resolved_age", 0))
	life.birth_year = int(life.get("birth_year", 2000))
	life.income = int(round(float(life.get("income", 0))))
	life.debt = int(round(float(life.get("debt", 0))))
	life.decade_index = int(life.get("decade_index", 0))
	life.decades_resolved = int(life.get("decades_resolved", 0))
	life.decade_pos = int(life.get("decade_pos", 0))
	var facts: Dictionary = life.get("facts", {})
	facts.marriages = int(facts.get("marriages", 0))
	life.facts = facts
	var ages: Array = []
	for value in life.get("decade_ages", []):
		ages.append(int(value))
	life.decade_ages = ages
	var reserved: Array = []
	for value in life.get("reserved_ages", []):
		reserved.append(int(value))
	life.reserved_ages = reserved
	var stats: Dictionary = life.get("stats", {})
	for key in stats.keys():
		stats[key] = int(round(float(stats[key])))
	life.stats = stats
	var clock: Dictionary = life.get("clock", {})
	clock.granted_days = int(clock.get("granted_days", 0))
	life.clock = clock
	if not life.has("storylines_used") or typeof(life.storylines_used) != TYPE_DICTIONARY:
		life.storylines_used = {}
	if typeof(life.get("death", {})) != TYPE_DICTIONARY:
		life.death = {}


func _present_from_pos() -> void:
	if is_dead():
		return
	var ages: Array = life.decade_ages
	var pos := int(life.decade_pos)
	if pos >= ages.size():
		var end_age: int = int(life.decade_index) * 10 + 9
		if age_now() < end_age:
			if resolve_years_through(end_age):
				return
		_end_decade()
		return
	var slot := int(ages[pos])
	if slot < age_now():
		life.decade_pos = pos + 1
		_present_from_pos()
		return
	if resolve_years_through(slot):
		return
	var rng := _rng()
	var event: Dictionary = EventCatalog.pick_for_age(life, slot, rng)
	_keep(rng)
	if event.is_empty():
		life.decade_pos = pos + 1
		_present_from_pos()
		return
	_show_event(event)


func _show_event(event: Dictionary) -> void:
	var id := str(event.get("id", ""))
	if not life.presented_ids.has(id):
		var rng := _rng()
		_apply(event.get("on_present", {}), rng)
		_keep(rng)
		life.presented_ids.append(id)
	if not life.shown_this_decade.has(id):
		life.shown_this_decade.append(id)
	life.current_event_id = id
	life.phase = "event"
	life.pending = {}


func _after_consequence() -> void:
	if is_dead():
		return
	var current := age_now()
	for index in life.decade_ages.size():
		if int(life.decade_ages[index]) == current:
			life.decade_pos = index
			break
	life.decade_pos = int(life.decade_pos) + 1
	_present_from_pos()


func _end_decade() -> void:
	if is_dead():
		return
	var index := int(life.decade_index)
	life.decades_resolved = index + 1
	if index >= 10:
		resolve_years_through(110)
		return
	if str(life.mode) == "fast":
		life.phase = "decade_break"
	elif int(life.decades_resolved) < unlocked_count():
		life.phase = "decade_break"
	else:
		life.phase = "daily_wait"


func _resolve_year(year: int) -> bool:
	shared_ticks += 1
	var rng := _rng()
	life.age = year
	_update_stage()
	for npc in life.npcs:
		if bool(npc.get("alive", true)):
			npc.age = int(npc.get("age", year)) + 1
	_fire_due(year, rng)
	_upkeep()
	var died := false
	if year >= 110:
		_keep(rng)
		_die("old age")
		died = true
	else:
		var roll := rng.randf()
		var chance := _death_chance()
		if roll < chance and not suppress_random_death:
			var cause := _pick_cause(rng)
			_keep(rng)
			_die(cause)
			died = true
		else:
			_keep(rng)
	life.last_resolved_age = year
	return died


func _fire_due(year: int, rng: RandomNumberGenerator) -> void:
	var keep: Array = []
	for item in life.scheduled:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var due := int(item.get("due_age", 999))
		if due > year:
			keep.append(item)
			continue
		var chance := float(item.get("chance", 1.0))
		var roll := rng.randf()
		if roll <= chance:
			_apply(item.get("effects", {}), rng)
			var text := str(item.get("text", ""))
			life.history.append({
				"age": year,
				"year": int(life.birth_year) + year,
				"event_id": str(item.get("id", "delayed")),
				"choice_id": "",
				"text": text,
				"outcome": "",
				"memorable": text != "",
			})
			if text != "":
				_append_unique(life.facts.memorable, text)
	life.scheduled = keep


func _upkeep() -> void:
	if age_now() <= 16:
		return
	var income := int(life.income)
	if bool(life.flags.get("in_prison", false)):
		income = 0
	var cost := 3 + int(life.children.size()) * 2
	var housing := str(life.housing)
	if housing == "mansion":
		cost += 10
	elif housing == "house":
		cost += 4
	_add_stat("wealth", income - cost)
	if int(life.debt) > 0:
		var pay := mini(int(life.debt), 3)
		life.debt = int(life.debt) - pay
		_add_stat("wealth", -pay)
		if int(life.debt) <= 0:
			life.flags.erase("has_debt")


func _death_chance() -> float:
	var years := age_now()
	if years >= 110:
		return 1.0
	var chance := 0.0
	if years < 40:
		chance = 0.0
		if bool(life.flags.get("serious_injury", false)):
			chance += 0.012
		if bool(life.flags.get("smoker", false)):
			chance += 0.001
	elif years < 55:
		chance = 0.004
	elif years < 70:
		chance = 0.02 + float(years - 55) * 0.003
	elif years < 85:
		chance = 0.06 + float(years - 70) * 0.012
	elif years < 100:
		chance = 0.2 + float(years - 85) * 0.03
	else:
		chance = 0.5
	var health := float(life.stats.get("health", 50))
	chance *= lerpf(1.7, 0.55, clampf(health / 100.0, 0.0, 1.0))
	chance += float(int(life.hidden.get("illness_risk", 1))) * 0.0015
	if bool(life.flags.get("smoker", false)) and years >= 45:
		chance += 0.02
	if bool(life.flags.get("heavy_drinker", false)) and years >= 45:
		chance += 0.015
	if bool(life.flags.get("ill", false)):
		chance += 0.03
	if bool(life.flags.get("fit", false)):
		chance *= 0.7
	if bool(life.flags.get("sedentary", false)):
		chance += 0.006
	var luck := float(life.stats.get("luck", 50))
	chance *= lerpf(1.25, 0.75, clampf(luck / 100.0, 0.0, 1.0))
	if int(life.stats.get("health", 50)) <= 8 and years >= 30:
		chance += 0.08
	return clampf(chance, 0.0, 0.95)


func _pick_cause(rng: RandomNumberGenerator) -> String:
	var years := age_now()
	var weights := {
		"old age": 0,
		"illness": 2 + int(int(life.hidden.get("illness_risk", 1)) / 3),
		"accident": 1,
		"lifestyle": 0,
		"rare": 1 if years < 60 else 0,
	}
	if years >= 75:
		weights["old age"] = 4 + int((years - 75) / 5)
	if bool(life.flags.get("serious_injury", false)):
		weights["accident"] = int(weights["accident"]) + 4
	if (bool(life.flags.get("smoker", false)) or bool(life.flags.get("heavy_drinker", false))) and years >= 40:
		weights["lifestyle"] = 4
	if bool(life.flags.get("ill", false)) or int(life.stats.get("health", 50)) < 35:
		weights["illness"] = int(weights["illness"]) + 3
	var bag: Array = []
	for key in weights.keys():
		for _i in int(weights[key]):
			bag.append(str(key))
	if bag.is_empty():
		return "illness" if years < 80 else "old age"
	return str(bag[rng.randi() % bag.size()])


func _die(cause: String) -> void:
	if not life.get("death", {}).is_empty() and str(life.death.get("cause", "")) != "":
		life.phase = "dead"
		return
	var years := age_now()
	life.death = {
		"age": years,
		"year": int(life.birth_year) + years,
		"cause": cause,
		"epitaph": "",
	}
	life.death.epitaph = _epitaph()
	life.phase = "dead"
	life.history.append({
		"age": years,
		"year": int(life.death.year),
		"event_id": "death",
		"choice_id": "",
		"text": "Died of %s at age %d." % [cause, years],
		"outcome": str(life.death.epitaph),
		"memorable": true,
	})


func _epitaph() -> String:
	var who := str(life.first_name)
	var years := int(life.death.get("age", age_now()))
	var cause := str(life.death.get("cause", ""))
	var marriages := int(life.facts.get("marriages", 0))
	var kids := int(life.children.size())
	var wealth := int(life.stats.get("wealth", 0))
	if bool(life.flags.get("in_prison", false)):
		return "%s left the story with the door locked." % who
	if cause == "accident" and years < 40:
		return "%s was gone before the punchline." % who
	if kids >= 4:
		return "%s collected %d children and a very full table." % [who, kids]
	if marriages >= 2:
		return "%s married %d times and called it the scenic route." % [who, marriages]
	if wealth >= 400:
		return "%s left enough money to start an argument." % who
	if wealth < 15 and years >= 70:
		return "%s was never rich, and rarely bothered." % who
	if bool(life.flags.get("smoker", false)) and cause == "lifestyle":
		return "The habit kept its promise, and %s paid it." % who
	if marriages == 1:
		var spouse := _spouse_name()
		if spouse != "":
			return "%s and %s made a life that mostly fit." % [who, spouse]
	if cause == "old age":
		return "%s stayed long enough to see the joke." % who
	return "A whole life, folded small enough to hold."


func _spouse_name() -> String:
	for npc in life.npcs:
		if str(npc.get("role", "")) == "spouse":
			return str(npc.get("name", ""))
	return ""


func _apply(effects: Variant, rng: RandomNumberGenerator) -> void:
	if typeof(effects) != TYPE_DICTIONARY or effects.is_empty():
		return
	for flag in effects.get("flags_set", []):
		life.flags[str(flag)] = true
	for flag in effects.get("flags_clear", []):
		life.flags.erase(str(flag))
	var deltas: Dictionary = effects.get("stats", {})
	for key in deltas.keys():
		_add_stat(str(key), int(round(float(deltas[key]))))
	if effects.has("relationship_status"):
		life.relationship_status = str(effects.relationship_status)
	if effects.has("education"):
		life.education = str(effects.education)
	if effects.has("qualification"):
		_append_unique(life.qualifications, str(effects.qualification))
	if effects.has("career"):
		var career := str(effects.career)
		life.career = career
		if career != "":
			_append_unique(life.facts.jobs, career)
	if effects.has("employment"):
		life.employment = str(effects.employment)
		if life.employment == "none":
			life.flags.erase("employed")
			life.income = 0
		else:
			life.flags["employed"] = true
	if effects.has("income"):
		life.income = int(round(float(effects.income)))
	if effects.has("income_delta"):
		life.income = int(life.income) + int(round(float(effects.income_delta)))
	if effects.has("debt"):
		life.debt = maxi(0, int(life.debt) + int(round(float(effects.debt))))
		if int(life.debt) > 0:
			life.flags["has_debt"] = true
		else:
			life.flags.erase("has_debt")
	if effects.has("housing"):
		life.housing = str(effects.housing)
	if effects.has("condition"):
		_append_unique(life.conditions, str(effects.condition))
	if effects.has("achievement"):
		var achievement := str(effects.achievement)
		_append_unique(life.facts.achievements, achievement)
		_append_unique(life.milestones, achievement)
	if effects.has("memorable"):
		_append_unique(life.facts.memorable, str(effects.memorable))
	if effects.has("relationship_note"):
		_append_unique(life.facts.relationships, str(effects.relationship_note))
	if effects.has("ensure_npc"):
		_ensure_npc(effects.ensure_npc)
	if effects.has("npc_patch"):
		_patch_npc(effects.npc_patch)
	if bool(effects.get("add_child", false)):
		_add_child(rng)


func _roll_outcome(choice: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var outcomes: Array = choice.get("outcomes", [])
	if outcomes.is_empty():
		return {"id": "none", "text": "Life goes on.", "effects": {}}
	var forced := str(life.get("debug_outcome", ""))
	if forced != "":
		life.debug_outcome = ""
		for outcome in outcomes:
			if str(outcome.get("id", "")) == forced:
				return outcome
	var total := 0.0
	for outcome in outcomes:
		total += float(outcome.get("weight", 1))
	var roll := rng.randf() * total
	var cursor := 0.0
	for outcome in outcomes:
		cursor += float(outcome.get("weight", 1))
		if roll <= cursor:
			return outcome
	return outcomes[outcomes.size() - 1]


func _queue_delayed(rows: Variant, current_age: int) -> void:
	if typeof(rows) != TYPE_ARRAY:
		return
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var due := int(row.get("due_age", current_age + int(row.get("years", 1))))
		if due <= current_age:
			due = current_age + 1
		life.scheduled.append({
			"id": str(row.get("id", "delayed")),
			"due_age": due,
			"chance": float(row.get("chance", 1.0)),
			"text": str(row.get("text", "")),
			"effects": row.get("effects", {}),
		})


func _remember_followups(ids: Variant) -> void:
	if typeof(ids) != TYPE_ARRAY:
		return
	for id in ids:
		var text := str(id)
		if text != "" and not life.unresolved.has(text):
			life.unresolved.append(text)


func _insert_followup_ages(ids: Variant) -> void:
	if typeof(ids) != TYPE_ARRAY:
		return
	var end_age: int = int(life.decade_index) * 10 + 9
	for id in ids:
		var event := EventCatalog.get_event(str(id))
		if event.is_empty():
			continue
		var slot := int(event.get("at_age", int(event.get("min_age", age_now() + 1))))
		if slot <= age_now() or slot > end_age:
			continue
		if _array_has_int(life.decade_ages, slot):
			continue
		if life.decade_ages.size() < 4:
			life.decade_ages.append(slot)
		else:
			for index in range(life.decade_ages.size() - 1, -1, -1):
				var existing := int(life.decade_ages[index])
				if existing > age_now() and not _array_has_int(life.reserved_ages, existing):
					life.decade_ages[index] = slot
					break
		life.decade_ages.sort()


func _ensure_npc(spec: Dictionary) -> void:
	var id := str(spec.get("id", ""))
	if id == "":
		return
	var npc := EventCatalog.find_npc(life, id)
	if npc.is_empty():
		npc = _blank_npc(id, str(spec.get("name", id.capitalize())))
		npc.affection = int(spec.get("affection", 20))
		life.npcs.append(npc)
	if spec.has("role") and str(npc.get("role", "")) == "":
		npc.role = str(spec.role)
	elif spec.has("role") and int(npc.get("affection", 0)) == int(spec.get("affection", npc.get("affection", 0))):
		npc.role = str(spec.role)
	if spec.has("role"):
		npc.role = str(spec.role)
	if spec.has("circumstances"):
		npc.circumstances = str(spec.circumstances)
	if spec.has("history"):
		npc.history.append(str(spec.history))
	if spec.has("appearance"):
		npc.appearance = spec.appearance
	npc.age = age_now()


func _patch_npc(spec: Dictionary) -> void:
	var id := str(spec.get("id", ""))
	if id == "":
		return
	var npc := EventCatalog.find_npc(life, id)
	if npc.is_empty():
		var starter := 20
		if spec.has("affection_delta"):
			starter = 20 + int(spec.affection_delta)
		npc = _blank_npc(id, str(spec.get("name", id.capitalize())))
		npc.affection = starter
		life.npcs.append(npc)
	elif spec.has("affection_delta"):
		npc.affection = int(npc.get("affection", 0)) + int(spec.affection_delta)
	if spec.has("affection"):
		npc.affection = int(spec.affection)
	if spec.has("role"):
		npc.role = str(spec.role)
	if spec.has("alive"):
		npc.alive = bool(spec.alive)
	if spec.has("circumstances"):
		npc.circumstances = str(spec.circumstances)
	if spec.has("history"):
		npc.history.append(str(spec.history))
	if spec.has("appearance") and (npc.get("appearance", {}) as Dictionary).is_empty():
		npc.appearance = spec.appearance
	if spec.has("name"):
		npc.name = str(spec.name)
	npc.affection = clampi(int(npc.get("affection", 0)), 0, 100)


func _blank_npc(id: String, npc_name: String) -> Dictionary:
	return {
		"id": id,
		"name": npc_name,
		"age": age_now(),
		"role": "",
		"affection": 20,
		"alive": true,
		"circumstances": "",
		"history": [],
		"flags": [],
		"appearance": {},
	}


func _add_child(rng: RandomNumberGenerator) -> void:
	var names := _names()
	var pool: Array = []
	pool.append_array(names.female)
	pool.append_array(names.male)
	var child_name := str(pool[rng.randi() % pool.size()])
	life.children.append({"name": child_name, "born_at_parent_age": age_now()})
	var line := "Had a child, %s, at age %d." % [child_name, age_now()]
	_append_unique(life.facts.memorable, line)
	_append_unique(life.facts.relationships, line)


func _add_stat(key: String, delta: int) -> void:
	var current := int(life.stats.get(key, 0))
	if key == "wealth":
		life.stats[key] = clampi(current + delta, 0, 999999)
	else:
		life.stats[key] = clampi(current + delta, 0, 100)


func _update_stage() -> void:
	life.life_stage = stage_for_age(age_now())


func _fill(text: String) -> String:
	var filled := text.replace("{name}", str(life.get("name", "")))
	filled = filled.replace("{first}", str(life.get("first_name", "")))
	filled = filled.replace("{friend_name}", EventCatalog.friend_name(life))
	if not life.children.is_empty():
		filled = filled.replace("{child_name}", str(life.children[0].get("name", "your child")))
	else:
		filled = filled.replace("{child_name}", "your child")
	return filled


func _choice_buttons(event: Dictionary) -> Array:
	var buttons: Array = []
	for choice in EventCatalog.visible_choices(event, life):
		buttons.append({
			"id": str(choice.get("id", "")),
			"label": _fill(str(choice.get("label", "Continue."))),
		})
	return buttons


func _npc_view(id: String) -> Dictionary:
	if id == "":
		return {}
	var npc := EventCatalog.find_npc(life, id)
	if npc.is_empty() or not bool(npc.get("alive", true)):
		return {}
	return {
		"id": str(npc.get("id", "")),
		"name": str(npc.get("name", "")),
		"role": str(npc.get("role", "")),
		"appearance": npc.get("appearance", {}),
	}


func _room(requested: String) -> String:
	if requested != "" and requested != "auto" and requested != "home":
		return requested
	var housing := str(life.get("housing", ""))
	var wealth := int(life.stats.get("wealth", 0))
	if housing == "mansion" or wealth >= 500:
		return "mansion"
	if housing == "house" or wealth >= 140:
		return "home"
	if housing == "family_home" and wealth >= 80:
		return "home"
	return "apartment"


func _tagline() -> String:
	if str(life.get("mode", "")) == "daily":
		return "One day. Ten years. One extraordinary life."
	return "One lifetime. One sitting. Infinite possibilities."


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(life.seed)
	var state := str(life.get("rng_state", ""))
	if state != "":
		rng.state = int(state)
	return rng


func _keep(rng: RandomNumberGenerator) -> void:
	life.rng_state = str(rng.state)


func _erase_unresolved(id: String) -> void:
	var kept: Array = []
	for item in life.unresolved:
		if str(item) != id:
			kept.append(item)
	life.unresolved = kept


func _array_has_int(values: Array, wanted: int) -> bool:
	for value in values:
		if int(value) == wanted:
			return true
	return false


static func _csv(values: Array) -> String:
	var parts: PackedStringArray = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)


static func _append_unique(target: Array, value: String) -> void:
	if value == "":
		return
	if not target.has(value):
		target.append(value)


static var _name_cache: Dictionary = {}


static func _names() -> Dictionary:
	if not _name_cache.is_empty():
		return _name_cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/names.json"))
	if typeof(parsed) == TYPE_DICTIONARY:
		_name_cache = parsed
	else:
		_name_cache = {
			"female": ["Ada"],
			"male": ["Arthur"],
			"neutral": ["Alex"],
			"surnames": ["Wells"],
		}
	return _name_cache
