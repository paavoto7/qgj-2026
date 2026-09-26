@abstract
class_name EnemyType
extends Node
## Component that decides an Enemy's type. Add exactly one as a child of an Enemy.
## It decides how the thread's winding counts, which way to wind and what colour the enemy is.

var enemy: Enemy:
	get:
		return get_parent() as Enemy


## Returns the first EnemyType child of node, or null.
static func find_in(node: Node) -> EnemyType:
	for child: Node in node.get_children():
		if child is EnemyType:
			return child

	return null


## How many winds the thread has made around the enemy in the direction it needs.
## [param windings] holds the thread's winding around every enemy in the arena.
@abstract func wound_amount(windings: Dictionary[Enemy, float]) -> float


@abstract func get_color() -> Color


func winds_needed() -> int:
	return 1


## 1 for clockwise, -1 for counterclockwise.
func direction() -> float:
	return 1.0


## Adjusts the enemy's velocity, which chases the target by default.
func steer(velocity: Vector2) -> Vector2:
	return velocity
