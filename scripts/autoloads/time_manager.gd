extends Node

## Shared age rules. Daily and fast lives differ only in when a decade unlocks.


func stage_for_age(years: int) -> String:
	return LifeSim.stage_for_age(years)


func today() -> String:
	return TimeUtil.today()


func unlock_count(sim: LifeSim) -> int:
	if sim == null:
		return 0
	return sim.unlocked_count()


func can_advance(sim: LifeSim) -> bool:
	if sim == null:
		return false
	return sim.can_advance()
