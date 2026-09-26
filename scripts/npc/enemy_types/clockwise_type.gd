@tool
class_name ClockwiseType
extends EnemyType
## The enemy needs the thread wound clockwise around it a set number of times.


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0) * direction()
