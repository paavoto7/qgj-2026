class_name WindingPlayer
extends Node2D
## Player for winding combat. Moves freely inside the arena, which records its path as the thread.

@export var speed: float = 340.0
@export var acceleration: float = 2400.0
@export var radius: float = 10.0
@export var max_health: int = 3
@export var color: Color = Color(1.0, 0.85, 0.4)
@export var hurt_color: Color = Color(1.0, 1.0, 1.0)

var arena: Rect2
var velocity: Vector2 = Vector2.ZERO
var health: Health

var _hurt_flash: float = 0.0


func _init() -> void:
	health = Health.new()
	health.invulnerability_time = 1.0
	add_child(health)


func _ready() -> void:
	health.max_health = max_health
	health.reset()
	health.damaged.connect(_on_damaged)


func _physics_process(delta: float) -> void:
	if health.is_dead:
		return

	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = velocity.move_toward(input * speed, acceleration * delta)
	position += velocity * delta
	if arena.has_area():
		position = position.clamp(arena.position, arena.end)


func _process(delta: float) -> void:
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var draw_color: Color = color
	if health.is_dead:
		draw_color = Color(0.4, 0.4, 0.4)
	elif _hurt_flash > 0.0 and int(_hurt_flash * 12.0) % 2 == 0:
		draw_color = hurt_color
	draw_circle(Vector2.ZERO, radius, draw_color)


func _on_damaged(_amount: int) -> void:
	_hurt_flash = health.invulnerability_time
