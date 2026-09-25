class_name KnotEnemy
extends Node2D
## Enemy that dies when the thread winds around it in the right pattern.
## Positive winds are clockwise, negative counterclockwise. With a partner, one loop around both knots them.

## How far apart linked partners try to stay.
const PAIR_DISTANCE: float = 110.0
## How much of a wind can be missing and still count. Keeps sloppy loops forgiving.
const TOLERANCE: float = 0.15
const RING_SPACING: float = 5.0

@export var required_winds: int = 2
@export var speed: float = 55.0
@export var radius: float = 16.0
@export var clockwise_color: Color = Color(1.0, 0.4, 0.4)
@export var counterclockwise_color: Color = Color(0.4, 0.7, 1.0)
@export var pair_color: Color = Color(0.6, 1.0, 0.5)

var partner: KnotEnemy
var target: Node2D
var is_knotted: bool = false
var color: Color:
	get:
		if has_partner():
			return pair_color
		return clockwise_color if required_winds > 0 else counterclockwise_color

var _progress: float = 0.0


func _physics_process(delta: float) -> void:
	if is_knotted or not is_instance_valid(target):
		return

	var velocity: Vector2 = position.direction_to(target.position) * speed
	if has_partner():
		# Spring towards the partner so the pair stays loopable as one
		var offset: Vector2 = partner.position - position
		velocity += offset.normalized() * (offset.length() - PAIR_DISTANCE) * 2.0
	position += velocity * delta


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


## Partners always knot together, so a valid partner means this enemy is part of a pair.
func has_partner() -> bool:
	return is_instance_valid(partner)


## Updates the progress rings and returns true when the thread knots this enemy.
func evaluate(winding: float, partner_winding: float) -> bool:
	var along: float
	if has_partner():
		# Both must be wound the same way, so a loop around the pair counts but a figure eight doesn't
		along = minf(absf(winding), absf(partner_winding)) if signf(winding) == signf(partner_winding) else 0.0
	else:
		along = winding * signf(required_winds)

	var needed: float = _winds_needed()
	_progress = clampf(along / needed, 0.0, 1.0)
	return along >= needed - TOLERANCE


func knot() -> void:
	is_knotted = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", _direction() * TAU, 0.3)
	tween.chain().tween_callback(queue_free)


func _winds_needed() -> int:
	return 1 if has_partner() else maxi(absi(required_winds), 1)


func _direction() -> float:
	return -1.0 if required_winds < 0 and not has_partner() else 1.0
