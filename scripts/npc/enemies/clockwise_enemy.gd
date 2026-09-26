class_name ClockwiseEnemy
extends Enemy
## Enemy that needs the thread wound clockwise around it a set number of times.

@export var winds: int = 2
@export var enemy_color: Color = Color(1.0, 0.4, 0.4)


func _wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(self, 0.0)


func _get_color() -> Color:
	return enemy_color


func _winds_needed() -> int:
	return maxi(winds, 1)
