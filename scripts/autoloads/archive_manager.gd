extends Node

const ROOT := "user://"


func add(record: Dictionary) -> void:
	ArchiveStore.add(ROOT, record)


func records() -> Array:
	return ArchiveStore.load_records(ROOT)


func stats() -> Dictionary:
	return ArchiveStore.compute(records())
