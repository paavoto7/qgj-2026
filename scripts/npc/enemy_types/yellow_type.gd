@tool
class_name YellowType
extends EnemyType
## A normal enemy that splits into two smaller, faster enemies when knotted.
## Its winding direction is randomly chosen when spawned.

const CHILD_RADIUS_SCALE: float = 0.6
const CHILD_SPEED_MULTIPLIER: float = 3.0
const CHILD_BURST_TIME: float = 0.35
const CHILD_BURST_STRENGTH: float = 2.5

var _direction: float = 1.0
var _can_split: bool = true
var _burst_direction: Vector2 = Vector2.ZERO
var _burst_timer: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_direction = 1.0 if randf() < 0.5 else -1.0


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0) * _direction


func direction() -> float:
	return _direction


func steer(velocity: Vector2) -> Vector2:
	if _burst_timer > 0.0:
		_burst_timer -= get_physics_process_delta_time()
		return _burst_direction * velocity.length() * CHILD_BURST_STRENGTH

	return velocity


func on_knotted() -> void:
	for child: Enemy in _split():
		enemy.spawn(child)


func _split() -> Array[Enemy]:
	if not _can_split:
		return []

	var scene := load(enemy.scene_file_path) as PackedScene
	if not scene:
		return []

	var children: Array[Enemy] = []

	# Burst sideways relative to the player.
	var to_player := enemy.target.position - enemy.position
	var sideways := to_player.normalized().orthogonal()

	for side: float in [-1.0, 1.0]:
		var child := scene.instantiate() as Enemy
		child.position = enemy.position
		child.radius = enemy.radius * CHILD_RADIUS_SCALE
		child.speed = enemy.speed * CHILD_SPEED_MULTIPLIER

		var child_type := EnemyType.find_in(child) as YellowType
		child_type._can_split = false
		child_type._burst_direction = sideways * side
		child_type._burst_timer = CHILD_BURST_TIME

		children.append(child)

	return children
