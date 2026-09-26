@tool
class_name ClockwiseType
extends EnemyType
## The enemy needs the thread wound clockwise around it a set number of times.

@export var winds: int = 2
@export var color: Color = Color(1.0, 0.4, 0.4)


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0)


func get_color() -> Color:
	return color


func winds_needed() -> int:
	return maxi(winds, 1)
