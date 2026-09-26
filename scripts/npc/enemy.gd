@tool
class_name Enemy
extends Node2D
## Enemy that dies when the thread winds around it in the right pattern.
## Its EnemyType child component decides the pattern. Positive winds are clockwise.
## A tool script so it's drawn in the editor. Gameplay code is skipped there.

## How much of a wind can be missing and still count. Keeps sloppy loops forgiving.
const TOLERANCE: float = 0.15
const RING_SPACING: float = 5.0

@export var speed: float = 55.0
@export var radius: float = 16.0

var target: Node2D
var is_knotted: bool = false
var color: Color:
	get:
		return type.get_color() if is_instance_valid(type) else Color.WHITE

var _progress: float = 0.0
var _completed_winds: int = 0
var _thread_completed_winds: int = 0

@onready var type: EnemyType = EnemyType.find_in(self)


func _ready() -> void:
	if Engine.is_editor_hint():
		# Pick up a Type child added or removed while editing
		child_order_changed.connect(func() -> void: type = EnemyType.find_in(self))
		set_physics_process(false)
		return

	if not is_instance_valid(type):
		push_error("Enemy '%s' needs an EnemyType child component." % name)
		set_physics_process(false)
		return

	speed = type.get_speed()
	radius = type.get_radius()


func _physics_process(delta: float) -> void:
	if is_knotted or not is_instance_valid(target):
		return
	position += type.steer(position.direction_to(target.position) * speed) * delta


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color.darkened(0.6))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 2.0)
	if not is_instance_valid(type):
		return

	# One ring per remaining wind, filling clockwise or counterclockwise from the top
	var winds: int = type.winds_needed()
	var remaining_winds: int = maxi(winds - _completed_winds, 0)
	var direction: float = type.direction()

	for i: int in remaining_winds:
		var ring_radius: float = radius + 6.0 + i * RING_SPACING
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(color, 0.25), 2.0)

		var fill: float = clampf(_progress - i, 0.0, 1.0)
		if fill > 0.0:
			draw_arc(
				Vector2.ZERO,
				ring_radius,
				-PI / 2.0,
				-PI / 2.0 + direction * fill * TAU,
				48,
				color,
				3.0
			)

	# Arrowhead at the top shows which way to go
	if remaining_winds > 0:
		var tip := Vector2(
			0.0,
			-(radius + 6.0 + remaining_winds * RING_SPACING + 3.0)
		)
		draw_colored_polygon(PackedVector2Array([
			tip + Vector2(direction * 7.0, 0.0),
			tip + Vector2(-direction * 3.0, -5.0),
			tip + Vector2(-direction * 3.0, 5.0),
		]), color)

	type.draw_extras()


## Returns the enemies in a freshly instantiated scene: the root if it's an Enemy, otherwise its Enemy children.
## Children are taken out of the group, keeping its position as an offset from it, and the group is freed.
static func take_from(node: Node) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	if node is Enemy:
		enemies.append(node)
		return enemies

	for child: Node in node.get_children():
		if child is Enemy:
			node.remove_child(child)
			enemies.append(child)
	node.free()
	return enemies


## Updates the progress rings and returns true when the thread knots this enemy.
## [param windings] holds the winding around every enemy in the arena.
func evaluate(windings: Dictionary[Enemy, float]) -> bool:
	if not is_instance_valid(type):
		return false

	var along: float = type.wound_amount(windings)
	var needed: int = type.winds_needed()

	# The thread has been cleared/reset.
	if absf(along) <= TOLERANCE:
		_thread_completed_winds = 0
		_progress = 0.0
		return false

	# Only count complete winds in the required direction.
	var completed_in_thread: int = floori(along + TOLERANCE)

	# Only count winds that have not already been counted.
	var newly_completed: int = completed_in_thread - _thread_completed_winds
	if newly_completed > 0:
		_completed_winds += newly_completed
		_thread_completed_winds = completed_in_thread

	# Show partial progress toward the next wind.
	_progress = along - completed_in_thread

	return _completed_winds >= needed


func knot() -> void:
	is_knotted = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", type.direction() * TAU, 0.3)
	tween.chain().tween_callback(queue_free)
