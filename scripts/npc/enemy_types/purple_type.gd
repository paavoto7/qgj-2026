@tool
class_name PurpleType
extends EnemyType
## A special enemy that requires alternating winding directions.
## Each completed wind switches the required direction. Wind Direction is the first one.


func direction() -> float:
	# Flip direction after every completed wind. The enemy starts the next wind from 0.
	return super.direction() * (1.0 if enemy.completed_winds % 2 == 0 else -1.0)
