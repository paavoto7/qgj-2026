class_name GameData
extends Resource
## Persistent save data, saved and loaded by MainManager.
##
## Only @export variables are written to the save file. Add the game's own fields here.

@export var high_score: int = 0
@export var flags: Dictionary[StringName, bool] = {}


func set_flag(flag: StringName, value: bool = true) -> void:
	flags[flag] = value


func has_flag(flag: StringName) -> bool:
	return flags.get(flag, false)
