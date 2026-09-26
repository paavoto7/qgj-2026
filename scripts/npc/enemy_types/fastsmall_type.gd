@tool
class_name FastSmallType
extends EnemyType
## The enemy needs the thread wound clockwise around it a set number of times.

@export var speed_multiplier: float = 3
@export var radius_multiplier: float = 0.5


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0) * direction()


func get_speed() -> float:
	return enemy.speed * speed_multiplier


func get_radius() -> float:
	return enemy.radius * radius_multiplier
