class_name ArchiveStore
extends RefCounted

## Completed lives. The list can grow; stats are derived from it.


static func path(root: String) -> String:
	return SaveStore.file(root, "archive.json")


static func stats_path(root: String) -> String:
	return SaveStore.file(root, "stats.json")


static func load_records(root: String) -> Array:
	var parsed: Variant = SaveStore.read_json(path(root))
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed


static func add(root: String, record: Dictionary) -> void:
	var records := load_records(root)
	records.append(record)
	SaveStore.write_json(path(root), records)
	SaveStore.write_json(stats_path(root), compute(records))


static func compute(records: Array) -> Dictionary:
	var stats := {
		"total_lives": records.size(),
		"longest": {},
		"shortest": {},
		"wealthiest": {},
		"most_children": {},
		"most_marriages": {},
	}
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var age := int(record.get("age", 0))
		var wealth := int(record.get("wealth", 0))
		var children: int = _count_children(record)
		var marriages := int(record.get("marriages", 0))
		_keep_best(stats, "longest", record, age, true)
		_keep_best(stats, "shortest", record, age, false)
		_keep_best(stats, "wealthiest", record, wealth, true)
		_keep_best(stats, "most_children", record, children, true)
		_keep_best(stats, "most_marriages", record, marriages, true)
	return stats


static func _count_children(record: Dictionary) -> int:
	var children: Variant = record.get("children", [])
	if typeof(children) == TYPE_ARRAY:
		return children.size()
	return 0


static func _keep_best(stats: Dictionary, key: String, record: Dictionary, value: int, higher: bool) -> void:
	var current: Dictionary = stats[key]
	if current.is_empty():
		stats[key] = _entry(record, value)
		return
	var old := int(current.get("value", 0))
	if higher and value > old:
		stats[key] = _entry(record, value)
	elif not higher and value < old:
		stats[key] = _entry(record, value)


static func _entry(record: Dictionary, value: int) -> Dictionary:
	return {
		"id": str(record.get("id", "")),
		"name": str(record.get("name", "")),
		"value": value,
		"mode": str(record.get("mode", "")),
	}
