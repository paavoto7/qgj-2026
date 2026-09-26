@tool
class_name CounterclockwiseType
extends EnemyType
## The enemy needs the thread wound counterclockwise around it a set number of times.


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0) * direction()
