extends Control

const INK := Color("1c1a33")
const CREAM := Color("fff6e4")
const MUTED := Color("d7c8ae")
const CORAL := Color("ff6b5a")
const TEAL := Color("2a9d8f")
const GOLD := Color("f2c14e")
const PANEL := Color("3c3666")
const NIGHT := Color("2a2548")

var _mode := ""
var _sim: LifeSim
var _record: Dictionary = {}
var _animating := false
var _anim_left := 0.0
var _host: MarginContainer
var _countdown: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = INK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	_host = MarginContainer.new()
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	_apply_margins()
	if not get_viewport().size_changed.is_connected(_apply_margins):
		get_viewport().size_changed.connect(_apply_margins)
	_show_menu()


func _process(delta: float) -> void:
	if _animating:
		_anim_left -= delta
		if _anim_left <= 0.0:
			_animating = false
			_show_play()
		return
	if _countdown != null and is_instance_valid(_countdown) and _sim != null and str(_sim.life.get("phase", "")) == "daily_wait":
		_countdown.text = TimeUtil.countdown_text()


func _apply_margins() -> void:
	if _host == null:
		return
	var edge := _safe_margins()
	_host.add_theme_constant_override("margin_left", edge[0])
	_host.add_theme_constant_override("margin_top", edge[1])
	_host.add_theme_constant_override("margin_right", edge[2])
	_host.add_theme_constant_override("margin_bottom", edge[3])


func _safe_margins() -> Array:
	var margins: Array = [12, 16, 12, 14]
	var screen := DisplayServer.screen_get_size()
	if screen.x < 8 or screen.y < 8:
		return margins
	var safe := DisplayServer.get_display_safe_area()
	var viewport_size := get_viewport_rect().size
	if viewport_size.x < 2.0 or viewport_size.y < 2.0:
		return margins
	var left := maxi(0, int(safe.position.x))
	var top := maxi(0, int(safe.position.y))
	var right := maxi(0, int(screen.x - (safe.position.x + safe.size.x)))
	var bottom := maxi(0, int(screen.y - (safe.position.y + safe.size.y)))
	margins[0] = maxi(12, int(left * viewport_size.x / float(screen.x)))
	margins[1] = maxi(16, int(top * viewport_size.y / float(screen.y)))
	margins[2] = maxi(12, int(right * viewport_size.x / float(screen.x)))
	margins[3] = maxi(14, int(bottom * viewport_size.y / float(screen.y)))
	return margins


func _clear() -> void:
	_countdown = null
	for child in _host.get_children():
		child.queue_free()


func _column() -> VBoxContainer:
	_clear()
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	_host.add_child(box)
	return box


func _label(text: String, size: int, color: Color, center: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if center:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button(text: String, color: Color, tall: int = 52) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, tall)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.set_border_width_all(2)
	style.border_color = Color("1c1a33")
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	return button


func _show_menu() -> void:
	_animating = false
	var box := _column()
	box.add_child(_label("A Life Well Played", 28, GOLD, true))
	var person := CharacterView.new()
	person.custom_minimum_size = Vector2(96, 144)
	person.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(person)
	person.show_person("young_adult", {"skin": "olive", "hair_color": "auburn", "eyes": "green", "hair": "bob"}, "idle")
	box.add_child(_label("A tiny life, from the first cry onward.", 14, MUTED, true))
	box.add_child(_mode_block("daily", "Daily Life", TEAL))
	box.add_child(_mode_block("fast", "Fast Life", CORAL))
	var past := _button("Past Lives", GOLD)
	past.pressed.connect(_show_archive)
	box.add_child(past)
	var settings := _button("Settings", Color("c9b6f2"))
	settings.pressed.connect(_show_settings)
	box.add_child(settings)


func _mode_block(mode: String, title: String, color: Color) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 2)
	var button := _button(title, color)
	button.pressed.connect(_open_mode.bind(mode))
	block.add_child(button)
	var caption := str(_games().call("active_label", mode))
	if caption == "":
		caption = "One day. Ten years. One extraordinary life." if mode == "daily" else "One lifetime. One sitting. Infinite possibilities."
	block.add_child(_label(caption, 13, CREAM, true))
	return block


func _open_mode(mode: String) -> void:
	_mode = mode
	var existing: LifeSim = _games().prepare(mode)
	if existing == null:
		_sim = _games().start_new(mode)
	else:
		_sim = existing
	_show_play()


func _show_play() -> void:
	if _sim == null:
		_show_menu()
		return
	if _sim.is_dead() and not _animating:
		_show_memorial(_sim.memorial(), _sim.archive_record())
		return
	var info: Dictionary = _sim.prompt()
	var box := _column()
	box.add_child(_hud(info))
	var stage := _stage(info)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(stage)
	box.add_child(_event_card(info))
	var menu := _button("Menu", Color("d9d0ea"), 40)
	menu.pressed.connect(_show_menu)
	box.add_child(menu)
	var debug := _button("Debug", Color("f0d48a"), 40)
	debug.pressed.connect(_show_debug)
	box.add_child(debug)


func _hud(info: Dictionary) -> PanelContainer:
	var panel := _panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 2)
	panel.add_child(inner)
	var mode_name := "Daily Life" if str(info.get("mode", "")) == "daily" else "Fast Life"
	inner.add_child(_label(str(info.get("name", "")), 18, CREAM))
	inner.add_child(_label("Age %d · %s · %s" % [int(info.get("age", 0)), str(info.get("stage_label", "")), mode_name], 13, MUTED))
	inner.add_child(_stat_line("Health", int(info.get("health", 0)), 100, Color("ef6f6c")))
	inner.add_child(_stat_line("Happiness", int(info.get("happiness", 0)), 100, Color("f2c14e")))
	inner.add_child(_stat_line("Wealth", int(info.get("wealth", 0)), 500, Color("7bd389")))
	return panel


func _stat_line(title: String, value: int, scale: int, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name := _label("%s %d" % [title, value], 12, CREAM)
	name.custom_minimum_size = Vector2(118, 0)
	row.add_child(name)
	var width := int(140.0 * clampf(float(value) / float(maxi(1, scale)), 0.0, 1.0))
	var fill := ColorRect.new()
	fill.color = color
	fill.custom_minimum_size = Vector2(maxi(6, width), 10)
	fill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(fill)
	return row


func _stage(info: Dictionary) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(0, 210)
	var room := TextureRect.new()
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	room.texture = SpriteBank.background(str(info.get("background", "home")))
	room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(room)
	var person := CharacterView.new()
	person.set_anchors_preset(Control.PRESET_CENTER)
	person.offset_left = -48
	person.offset_top = -72
	person.offset_right = 48
	person.offset_bottom = 72
	frame.add_child(person)
	var anim := str(info.get("animation", "idle"))
	if _animating:
		anim = str(_sim.life.get("pending", {}).get("animation", anim))
	person.show_person(str(info.get("stage", "baby")), info.get("appearance", {}), anim)
	var npc: Dictionary = info.get("npc", {})
	if not npc.is_empty() and not _animating:
		var portrait := CharacterView.new()
		portrait.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		portrait.offset_left = 8
		portrait.offset_top = -78
		portrait.offset_right = 56
		portrait.offset_bottom = -8
		frame.add_child(portrait)
		portrait.show_person("adult", npc.get("appearance", {}), "idle", true)
		var tag := _label(str(npc.get("name", "")), 12, CREAM)
		tag.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		tag.offset_left = 60
		tag.offset_top = -28
		tag.offset_right = 180
		tag.offset_bottom = -8
		frame.add_child(tag)
	return frame


func _event_card(info: Dictionary) -> PanelContainer:
	var panel := _panel()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	var phase := str(info.get("phase", ""))
	if _animating:
		inner.add_child(_label(str(_sim.life.get("pending", {}).get("event_text", info.get("text", ""))), 15, CREAM))
		return panel
	inner.add_child(_label(str(info.get("text", "")), 15, CREAM))
	if str(info.get("sub", "")) != "":
		var sub := _label(str(info.sub), 13, MUTED)
		inner.add_child(sub)
		if phase == "daily_wait" and not bool(info.get("can_advance", false)):
			_countdown = sub
	if str(info.get("notice", "")) != "":
		inner.add_child(_label(str(info.notice), 13, GOLD))
	if phase == "birth":
		var begin := _button("Begin.", TEAL)
		begin.pressed.connect(_acknowledge)
		inner.add_child(begin)
	elif phase == "event":
		var index := 0
		for choice in info.get("choices", []):
			var button := _button(str(choice.get("label", "Choose.")), CORAL if index % 2 == 0 else TEAL, 58)
			button.pressed.connect(_choose.bind(index))
			inner.add_child(button)
			index += 1
	elif phase == "consequence" or phase == "dead":
		var next := _button("Continue.", GOLD)
		next.pressed.connect(_acknowledge if phase == "consequence" else _open_memorial_from_sim)
		inner.add_child(next)
	elif phase == "decade_break" or bool(info.get("can_advance", false)):
		var next := _button("Open the next decade.", TEAL)
		next.pressed.connect(_acknowledge)
		inner.add_child(next)
	return panel


func _choose(index: int) -> void:
	if _sim == null or _animating:
		return
	_sim.choose(index)
	_games().persist(_mode)
	var anim := str(_sim.life.get("pending", {}).get("animation", "idle"))
	if _sim.is_dead():
		anim = "dying"
	_anim_left = SpriteBank.hold_of(anim)
	_animating = true
	_show_play()


func _acknowledge() -> void:
	if _sim == null or _animating:
		return
	_sim.acknowledge()
	_games().persist(_mode)
	if _sim.is_dead():
		_show_memorial(_sim.memorial(), _sim.archive_record())
		return
	_show_play()


func _open_memorial_from_sim() -> void:
	if _sim == null:
		_show_menu()
		return
	_show_memorial(_sim.memorial(), _sim.archive_record())


func _show_memorial(card: Dictionary, record: Dictionary) -> void:
	_animating = false
	_record = record
	var box := _column()
	box.add_child(_label("In memory", 14, GOLD, true))
	var person := CharacterView.new()
	person.custom_minimum_size = Vector2(96, 144)
	person.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(person)
	person.show_person(str(card.get("life_stage", "elderly")), card.get("appearance", {}), "idle")
	box.add_child(_label(str(card.get("full_name", "")), 22, CREAM, true))
	box.add_child(_label("%d–%d · age %d" % [int(card.get("birth_year", 0)), int(card.get("death_year", 0)), int(card.get("age", 0))], 14, MUTED, true))
	box.add_child(_label(str(card.get("cause", "")), 16, GOLD, true))
	box.add_child(_label(_line("Relationships", card.get("relationships", [])), 13, CREAM))
	box.add_child(_label(_line("Children", card.get("children", [])), 13, CREAM))
	var career := str(card.get("career", ""))
	box.add_child(_label("Career: %s" % (career if career != "" else "none recorded"), 13, CREAM))
	box.add_child(_label("Money: %d" % int(card.get("money", 0)), 13, CREAM))
	box.add_child(_label(_line("Achievements", card.get("achievements", [])), 13, CREAM))
	box.add_child(_label(_line("Remembered", card.get("memorable", [])), 13, CREAM))
	if str(card.get("family", "")) != "":
		box.add_child(_label(str(card.family), 13, MUTED))
	box.add_child(_label(str(card.get("epitaph", "")), 15, GOLD, true))
	var again := _button("Start Another Life", TEAL)
	again.pressed.connect(_again)
	box.add_child(again)
	var timeline := _button("View Life Timeline", GOLD)
	var timeline_record: Dictionary = record if not record.is_empty() else {"history": [], "name": card.get("full_name", "")}
	timeline.pressed.connect(_show_timeline.bind(timeline_record, "memorial"))
	box.add_child(timeline)
	var back := _button("Return to Main Menu", Color("d9d0ea"))
	back.pressed.connect(_show_menu)
	box.add_child(back)


func _again() -> void:
	var mode := _mode if _mode != "" else str(_record.get("mode", "fast"))
	_mode = mode
	_sim = _games().start_new(mode)
	_show_play()


func _show_archive() -> void:
	var box := _column()
	box.add_child(_label("Past Lives", 26, GOLD, true))
	var stats: Dictionary = _games().stats()
	box.add_child(_label("Lives %d" % int(stats.get("total_lives", 0)), 14, CREAM, true))
	box.add_child(_label(_stat_caption("Longest", stats.get("longest", {})), 12, MUTED, true))
	box.add_child(_label(_stat_caption("Shortest", stats.get("shortest", {})), 12, MUTED, true))
	box.add_child(_label(_stat_caption("Wealthiest", stats.get("wealthiest", {})), 12, MUTED, true))
	box.add_child(_label(_stat_caption("Most children", stats.get("most_children", {})), 12, MUTED, true))
	box.add_child(_label(_stat_caption("Most marriages", stats.get("most_marriages", {})), 12, MUTED, true))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var rows: Array = _games().records()
	if rows.is_empty():
		list.add_child(_label("No past lives yet.", 14, MUTED, true))
	for record in rows:
		list.add_child(_life_card(record))
	var back := _button("Return to Main Menu", Color("d9d0ea"))
	back.pressed.connect(_show_menu)
	box.add_child(back)


func _life_card(record: Dictionary) -> Button:
	var notable := str(record.get("notable", ""))
	var text := "%s\nAge %d · %s · %s\n%s" % [
		str(record.get("name", "")),
		int(record.get("age", 0)),
		str(record.get("mode", "")),
		str(record.get("cause", "")),
		notable,
	]
	var button := _button(text, PANEL, 96)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", CREAM)
	button.pressed.connect(_show_timeline.bind(record))
	return button


func _show_timeline(record: Dictionary, back_to: String = "archive") -> void:
	var box := _column()
	box.add_child(_label(str(record.get("name", "A life")), 22, GOLD, true))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var history: Array = record.get("history", [])
	if history.is_empty() and record.has("memorial"):
		history = []
	if history.is_empty():
		list.add_child(_label("Nothing recorded.", 14, MUTED))
	for entry in history:
		var line := "Age %s — %s" % [str(entry.get("age", "")), str(entry.get("text", ""))]
		if str(entry.get("outcome", "")) != "":
			line += " " + str(entry.get("outcome", ""))
		list.add_child(_label(line, 13, CREAM))
	var back := _button("Back", Color("d9d0ea"))
	if back_to == "memorial":
		back.pressed.connect(_open_memorial_from_sim)
	else:
		back.pressed.connect(_show_archive)
	box.add_child(back)


func _show_settings() -> void:
	var box := _column()
	box.add_child(_label("Settings", 26, GOLD, true))
	var games = _games()
	var music := _button("Music: %s" % ("On" if games.settings.music else "Off"), TEAL)
	music.pressed.connect(_toggle_music)
	box.add_child(music)
	var sfx := _button("Sound: %s" % ("On" if games.settings.sfx else "Off"), CORAL)
	sfx.pressed.connect(_toggle_sfx)
	box.add_child(sfx)
	box.add_child(_label("Audio files are optional. The toggles are saved either way.", 13, MUTED))
	var debug := _button("Debug", GOLD)
	debug.pressed.connect(_show_debug)
	box.add_child(debug)
	var back := _button("Return to Main Menu", Color("d9d0ea"))
	back.pressed.connect(_show_menu)
	box.add_child(back)


func _toggle_music() -> void:
	var games = _games()
	games.set_music(not bool(games.settings.music))
	_show_settings()


func _toggle_sfx() -> void:
	var games = _games()
	games.set_sfx(not bool(games.settings.sfx))
	_show_settings()


func _show_debug() -> void:
	var box := _column()
	box.add_child(_label("Debug", 24, GOLD, true))
	if _sim == null:
		box.add_child(_label("Open Daily Life or Fast Life to inspect a person.", 14, CREAM))
	else:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 180)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(scroll)
		var report := _label(_sim.debug_report(), 12, CREAM)
		scroll.add_child(report)
		var skip := _button("Skip this decade", CORAL, 44)
		skip.pressed.connect(_debug_skip)
		box.add_child(skip)
		var die := _button("Force death", Color("ef6f6c"), 44)
		die.pressed.connect(_debug_die)
		box.add_child(die)
		box.add_child(_debug_row("Force event id", _debug_event))
		box.add_child(_debug_row("Force outcome id", _debug_outcome))
		box.add_child(_debug_row("Restart seed", _debug_seed))
		if str(_sim.life.get("mode", "")) == "daily":
			box.add_child(_debug_row("Set simulated today", _debug_date))
	var back := _button("Back", Color("d9d0ea"))
	back.pressed.connect(_show_play if _sim != null else _show_menu)
	box.add_child(back)


func _debug_row(placeholder: String, handler: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size = Vector2(0, 40)
	row.add_child(field)
	var go := _button("Set", GOLD, 40)
	go.pressed.connect(func() -> void: handler.call(field.text))
	row.add_child(go)
	return row


func _debug_skip() -> void:
	if _sim == null:
		return
	_sim.debug_skip_decade()
	_games().persist(_mode)
	_show_play()


func _debug_die() -> void:
	if _sim == null:
		return
	_sim.force_death("accident")
	_games().persist(_mode)
	_show_memorial(_sim.memorial(), _sim.archive_record())


func _debug_event(id: String) -> void:
	if _sim == null:
		return
	if _sim.force_event(id.strip_edges()):
		_games().persist(_mode)
		_show_play()


func _debug_outcome(id: String) -> void:
	if _sim == null:
		return
	_sim.force_outcome(id.strip_edges())
	_show_play()


func _debug_seed(text: String) -> void:
	var seed_value := int(text.strip_edges()) if text.strip_edges().is_valid_int() else 1
	var mode := _mode if _mode != "" else "fast"
	_mode = mode
	_sim = _games().start_new(mode, seed_value)
	_show_play()


func _debug_date(text: String) -> void:
	if _sim == null:
		return
	_sim.debug_set_today(text.strip_edges())
	_games().persist(_mode)
	_show_play()


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color("f2c14e")
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _line(title: String, values: Array) -> String:
	if values.is_empty():
		return "%s: none recorded" % title
	var parts: PackedStringArray = []
	for value in values:
		parts.append(str(value))
	return "%s: %s" % [title, ", ".join(parts)]


func _stat_caption(title: String, entry: Dictionary) -> String:
	if entry.is_empty():
		return "%s: —" % title
	return "%s: %s (%s)" % [title, str(entry.get("name", "")), str(entry.get("value", ""))]


func _games() -> Node:
	return get_node("/root/GameManager")
