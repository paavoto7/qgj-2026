@abstract
class_name MovementPattern
extends Node2D
## A movement pattern that can be applied to an Enemy's velocity.
## Add exactly one as a child of an EnemyType.

@export var probability: float = 0.5


## Applies the movement pattern to the given velocity.
func apply(velocity: Vector2) -> Vector2:
	return velocity
