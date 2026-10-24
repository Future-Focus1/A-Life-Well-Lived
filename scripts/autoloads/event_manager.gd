extends Node

## In-game door to the shared event catalog.


func _ready() -> void:
	EventCatalog.ensure_loaded()


func event_count() -> int:
	return EventCatalog.all_events().size()


func get_event(id: String) -> Dictionary:
	return EventCatalog.get_event(id)


func pick_for_age(life: Dictionary, age: int, rng: RandomNumberGenerator) -> Dictionary:
	return EventCatalog.pick_for_age(life, age, rng)
