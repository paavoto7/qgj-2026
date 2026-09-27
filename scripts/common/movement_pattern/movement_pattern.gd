@abstract
class_name MovementPattern
extends Node2D
## A movement pattern that can be applied to an Enemy's velocity.
## Add one or more as children of an EnemyType. One of them, or none, is picked by weight when the enemy spawns.

## How likely this pattern is compared to the others and the type's No Pattern Weight. Empty means 1.
@export var weight: WaveWeight = null


## Applies the movement pattern to the given velocity.
func apply(velocity: Vector2) -> Vector2:
	return velocity
