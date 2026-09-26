class_name CounterclockwiseType
extends EnemyType
## The enemy needs the thread wound counterclockwise around it a set number of times.

@export var winds: int = 1
@export var color: Color = Color(0.4, 0.7, 1.0)


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return -windings.get(enemy, 0.0)


func get_color() -> Color:
	return color


func winds_needed() -> int:
	return maxi(winds, 1)


func direction() -> float:
	return -1.0
