class_name ThreadTrail
extends Node2D
## The thread the player leaves behind. Purely visual, enemies measure the winding themselves.

@export var max_points: int = 140
@export var sample_distance: float = 8.0
@export var width: float = 3.0
@export var color: Color = Color(1.0, 0.85, 0.4)

var points: PackedVector2Array = PackedVector2Array()


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

	points.append(point)

	if points.size() > max_points:
		points.remove_at(0)

	queue_redraw()


func clear() -> void:
	points.clear()
	queue_redraw()
