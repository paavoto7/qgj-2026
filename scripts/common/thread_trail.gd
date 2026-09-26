class_name ThreadTrail
extends Node2D
## The thread the player leaves behind. Measures how many times it winds around a point.

@export var max_points: int = 320
@export var sample_distance: float = 8.0
@export var width: float = 3.0
@export var color: Color = Color(1.0, 0.85, 0.4)

var points: PackedVector2Array = PackedVector2Array()


func _draw() -> void:
	if points.size() < 2:
		return

	# Older thread fades out so the player can see what is about to expire
	var colors := PackedColorArray()
	colors.resize(points.size())
	for i: int in points.size():
		colors[i] = Color(color, float(i) / points.size())
	draw_polyline_colors(points, colors, width, true)


func add_point(point: Vector2) -> void:
	if not points.is_empty() and points[-1].distance_to(point) < sample_distance:
		return

	points.append(point)
	# This is not optimal, but the line is short and time available even shorter.
	if points.size() > max_points:
		points.remove_at(0)
	queue_redraw()


func clear() -> void:
	points.clear()
	queue_redraw()


## Signed number of turns the thread makes around center. Positive is clockwise on screen.
## Only the total angle counts, so wobbly loops work as well as clean circles.
func winding_around(center: Vector2) -> float:
	if points.size() < 2:
		return 0.0

	var total: float = 0.0
	var previous: float = (points[0] - center).angle()
	for i: int in range(1, points.size()):
		var current: float = (points[i] - center).angle()
		total += angle_difference(previous, current)
		previous = current
	return total / TAU
