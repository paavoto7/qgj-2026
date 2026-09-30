@tool
class_name RandomDirectionType
extends EnemyType
## Winds clockwise or counterclockwise, chosen when spawned.

var _direction: float = 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_direction = 1.0 if randf() < 0.5 else -1.0


func direction() -> float:
	return _direction
