extends Node
## Editor-only test helper (autoload). Each Caps Lock press gives the player the next powerup,
## so the HUD display can be tested. Removes itself in exported builds.

const _POWERUPS_DIR: String = "res://resources/powerups"
const _POWERUPS_KEY: Key = KEY_ALT

var _powerups: Array[PowerupData] = []
var _index: int = 0


func _ready() -> void:
	if not OS.has_feature("editor"):
		queue_free()
		return

	for file: String in DirAccess.get_files_at(_POWERUPS_DIR):
		var data := load(_POWERUPS_DIR.path_join(file)) as PowerupData
		if data:
			_powerups.append(data)


# Reads the key directly instead of an input action, since this is a throwaway debug tool
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo or key.keycode != _POWERUPS_KEY:
		return

	var powerups := _find_powerups()
	if not powerups or _powerups.is_empty():
		return

	powerups.add(_powerups[_index])
	_index = (_index + 1) % _powerups.size()


## Looks the player up on every press, since the arena can be reloaded.
func _find_powerups() -> Powerups:
	var scene := get_tree().current_scene
	if not scene:
		return null

	var players := scene.find_children("*", "Player", true, false)
	if players.is_empty():
		return null

	return (players[0] as Player).powerups
