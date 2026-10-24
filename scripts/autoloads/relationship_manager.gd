extends Node

## Living people only. Dead NPCs stay in history and never return as alive.


func find(life: Dictionary, id: String) -> Dictionary:
	return EventCatalog.find_npc(life, id)


func is_alive(life: Dictionary, id: String) -> bool:
	return EventCatalog.npc_is_alive(life, id)


func friend_name(life: Dictionary) -> String:
	return EventCatalog.friend_name(life)
