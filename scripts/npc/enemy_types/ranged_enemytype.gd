@tool
class_name RangedEnemyType
extends EnemyType


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0) * direction()
