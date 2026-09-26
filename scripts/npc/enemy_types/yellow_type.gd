@tool
class_name YellowType
extends EnemyType
## A normal enemy that splits into two smaller, faster enemies when knotted.
## Its winding direction is randomly chosen when spawned.


const CHILD_RADIUS_SCALE: float = 0.6
const CHILD_SPEED_MULTIPLIER: float = 1.25
const CHILD_OFFSET: float = 14.0

var _direction: float = 1.0
@export var can_split: bool = true


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_direction = 1.0 if randf() < 0.5 else -1.0


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0) * _direction


func direction() -> float:
	return _direction


func split() -> Array[Enemy]:
	if not can_split:
		return []

	if enemy.scene_file_path.is_empty():
		push_error("Yellow enemy needs a scene file so it can split.")
		return []

	var scene := load(enemy.scene_file_path) as PackedScene
	if not scene:
		return []

	var children: Array[Enemy] = []

	for offset: float in [-CHILD_OFFSET, CHILD_OFFSET]:
		var child := scene.instantiate() as Enemy
		child.position = enemy.position + Vector2(offset, 0.0)
		child.radius = enemy.radius * CHILD_RADIUS_SCALE
		child.speed = enemy.speed * CHILD_SPEED_MULTIPLIER

		var child_type := EnemyType.find_in(child) as YellowType
		child_type.can_split = false

		children.append(child)

	return children
