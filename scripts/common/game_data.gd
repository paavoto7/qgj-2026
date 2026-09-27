class_name GameData
extends Resource
## Persistent save data, saved and loaded by MainManager.
##
## Only @export variables are written to the save file. Add the game's own fields here.

@export var high_score: int = 0
@export var enemies_knotted: int = 0
@export var runs_played: int = 0
@export var waves_cleared: int = 0
@export var flags: Dictionary[StringName, bool] = {}


## Adds a finished run to the lifetime totals. Returns true if it set a new high score.
func record_run(score: int, knots: int, waves: int) -> bool:
	runs_played += 1
	enemies_knotted += knots
	waves_cleared += waves
	if score <= high_score:
		return false

	high_score = score
	return true


func set_flag(flag: StringName, value: bool = true) -> void:
	flags[flag] = value


func has_flag(flag: StringName) -> bool:
	return flags.get(flag, false)
