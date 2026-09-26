@tool
class_name Projectile extends Node2D
## A projectile that moves in a straight line and damages the first target it hits.

@export var speed: float = 400.0
@export var damage: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var colour: Color = Color(1.0, 0.5, 0.0)
## The projectile's lifetime in seconds. If negative, it lives until it hits something.
@export var lifetime: float = -1.0




func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta
	if lifetime >= 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, colour)
