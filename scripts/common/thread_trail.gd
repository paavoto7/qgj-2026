class_name ThreadTrail
extends Node2D
## The thread the player leaves behind.
## The visible trail is short, while winding detection keeps a longer movement history.

@export var max_points: int = 140
@export var winding_history_points: int = 1000
@export var sample_distance: float = 8.0
@export var width: float = 3.0
@export var color: Color = Color(1.0, 0.85, 0.4)

var points: PackedVector2Array = PackedVector2Array()
var winding_points: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	top_level = true
	global_transform = Transform2D.IDENTITY


func _draw() -> void:
	if points.size() < 2:
		return

	# Older thread fades out so the player can see what is about to expire.
	var colors := PackedColorArray()
	colors.resize(points.size())

	for i: int in points.size():
		colors[i] = Color(color, float(i) / points.size())

	draw_polyline_colors(points, colors, width, true)


func add_point(point: Vector2) -> void:
	if not points.is_empty() and points[-1].distance_to(point) < sample_distance:
		return

	# Visible trail.
	points.append(point)

	if points.size() > max_points:
		points.remove_at(0)

	# Longer history used only for winding detection.
	winding_points.append(point)

	if winding_points.size() > winding_history_points:
		winding_points.remove_at(0)

	queue_redraw()


func clear() -> void:
	points.clear()
	winding_points.clear()
	queue_redraw()


## Signed number of turns the player's movement makes around center.
## Positive is clockwise on screen.
## Uses the longer hidden history rather than the short visual trail.
func winding_around(center: Vector2) -> float:
	if winding_points.size() < 2:
		return 0.0

	var total: float = 0.0
	var previous: float = (winding_points[0] - center).angle()

	for i: int in range(1, winding_points.size()):
		var current: float = (winding_points[i] - center).angle()
		total += angle_difference(previous, current)
		previous = current

	return total / TAU


func get_latest_points() -> Array[Vector2]:
	if winding_points.size() < 2:
		return []

	return [winding_points[-2], winding_points[-1]]
