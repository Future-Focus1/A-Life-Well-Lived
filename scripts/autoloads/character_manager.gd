extends Node

## Builds a character from a seed. The player never customises one.


func create(mode: String, seed_value: int, today: String) -> LifeSim:
	return LifeSim.begin(mode, seed_value, today)
