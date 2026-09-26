@abstract
class_name Enemy
extends Node2D
## Base for enemies that die when the thread winds around them in the right pattern.
## Subclasses decide how the winding counts and what colour they are. Positive winds are clockwise.

## How much of a wind can be missing and still count. Keeps sloppy loops forgiving.
const TOLERANCE: float = 0.15
const RING_SPACING: float = 5.0

@export var speed: float = 55.0
@export var radius: float = 16.0

var target: Node2D
var is_knotted: bool = false
var color: Color:
	get:
		return _get_color()

var _progress: float = 0.0


func _physics_process(delta: float) -> void:
	if is_knotted or not is_instance_valid(target):
		return
	position += _get_velocity() * delta


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color.darkened(0.6))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 2.0)

	# One ring per wind needed, filling up clockwise or counterclockwise from the top
	var winds: int = _winds_needed()
	var direction: float = _direction()
	var filled: float = _progress * winds
	for i: int in winds:
		var ring_radius: float = radius + 6.0 + i * RING_SPACING
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(color, 0.25), 2.0)
		var fill: float = clampf(filled - i, 0.0, 1.0)
		if fill > 0.0:
			draw_arc(Vector2.ZERO, ring_radius, -PI / 2.0, -PI / 2.0 + direction * fill * TAU, 48, color, 3.0)

	# Arrowhead at the top shows which way to go
	var tip := Vector2(0.0, -(radius + 6.0 + winds * RING_SPACING + 3.0))
	draw_colored_polygon(PackedVector2Array([
		tip + Vector2(direction * 7.0, 0.0),
		tip + Vector2(-direction * 3.0, -5.0),
		tip + Vector2(-direction * 3.0, 5.0),
	]), color)


## Updates the progress rings and returns true when the thread knots this enemy.
## [param windings] holds the thread's winding around every enemy in the arena.
func evaluate(windings: Dictionary[Enemy, float]) -> bool:
	var along: float = _wound_amount(windings)
	var needed: float = _winds_needed()
	_progress = clampf(along / needed, 0.0, 1.0)
	return along >= needed - TOLERANCE


func knot() -> void:
	is_knotted = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", _direction() * TAU, 0.3)
	tween.chain().tween_callback(queue_free)


## How many winds the thread has made around this enemy in the direction it needs.
@abstract func _wound_amount(windings: Dictionary[Enemy, float]) -> float


@abstract func _get_color() -> Color


func _get_velocity() -> Vector2:
	return position.direction_to(target.position) * speed


func _winds_needed() -> int:
	return 1


## 1 for clockwise, -1 for counterclockwise.
func _direction() -> float:
	return 1.0
