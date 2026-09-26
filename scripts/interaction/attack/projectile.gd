@tool
class_name Projectile extends Node2D
## A projectile that moves in a straight line and damages the first target it hits.

@export var speed: float = 400.0
@export var damage: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var colour: Color = Color(1.0, 0.5, 0.0)
## The projectile's lifetime in seconds. If negative, it lives until it hits something.
@export var lifetime: float = -1.0
## How many physics frames of positions the trail keeps. If -1, the trail is unlimited.
@export var trail_length: int = -1
## How sharply the trail fades towards its tail. 1 is linear, higher values fade faster.
@export var trail_falloff: float = 4.0

@export var trail_gradient_steps: int = 8

@onready var hitbox: Area2D = $HitBox
@onready var trail: Line2D = $Trail


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
	else:
		# Keep the trail's points in world space instead of moving with the projectile.
		trail.top_level = true
		trail.global_transform = Transform2D.IDENTITY

	trail.gradient = _make_trail_gradient()

	hitbox.area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var target: Node2D = area.get_parent() as Node2D
	if not target:
		return

	var health: Health = Health.find_in(target)
	if health:
		health.take_damage(damage)

	if target.has_method("knockback"):
		target.knockback(knockback)

	queue_free()


func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta
	trail.add_point(global_position)
	while trail.get_point_count() > trail_length and trail_length != -1:
		trail.remove_point(0)
	if lifetime >= 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, colour)


## Line2D gradients run from the first (oldest) point to the last (newest) one,
## so alpha rises from 0 at the tail to full at the head along a power curve.
func _make_trail_gradient() -> Gradient:
	var offsets: PackedFloat32Array = PackedFloat32Array()
	var colors: PackedColorArray = PackedColorArray()
	for i: int in trail_gradient_steps + 1:
		var t: float = float(i) / trail_gradient_steps
		offsets.append(t)
		colors.append(Color(colour, colour.a * pow(t, trail_falloff)))

	var gradient: Gradient = Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	return gradient
