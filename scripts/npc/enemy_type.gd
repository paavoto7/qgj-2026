@tool
@abstract
class_name EnemyType
extends Node
## Component that decides an Enemy's type. Add exactly one as a child of an Enemy.
## It decides how the thread's winding counts, which way to wind and what colour the enemy is.
## Subclasses must be tool scripts too, so the enemy is drawn in the editor.

## Set per type in the enemy's scene, on its Type node.
@export var color: Color = Color.WHITE
## How many winds knot the enemy. Also the number of rings drawn around it.
@export var winds: int = 1
## Which way to wind. Flips the rings and arrow too.
@export var clockwise: bool = true

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


func get_color() -> Color:
	return color


func get_speed() -> float:
	return enemy.speed


func get_radius() -> float:
	return enemy.radius


func winds_needed() -> int:
	return maxi(winds, 1)


## 1 for clockwise, -1 for counterclockwise.
func direction() -> float:
	return 1.0 if clockwise else -1.0


## Adjusts the enemy's velocity, which chases the target by default.
func steer(velocity: Vector2) -> Vector2:
	return velocity


## Called once every enemy spawned from the same scene is in the tree, e.g. to link them up.
func on_spawned(_group: Array[Enemy]) -> void:
	pass


## Called when the enemy is knotted, before it disappears. Spawn extra enemies with [method Enemy.spawn].
func on_knotted() -> void:
	pass


## Called at the end of Enemy._draw. Draw on [member enemy], in its local space.
func draw_extras() -> void:
	pass
