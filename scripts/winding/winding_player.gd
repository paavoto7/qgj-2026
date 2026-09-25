class_name WindingPlayer
extends Node2D
## Player for winding combat. Moves freely inside the arena, which records its path as the thread.

@export var speed: float = 340.0
@export var acceleration: float = 2400.0
@export var radius: float = 10.0
@export var max_health: int = 3
@export var color: Color = Color(1.0, 0.85, 0.4)
@export var dead_color: Color = Color(0.4, 0.4, 0.4)

var arena: Rect2
var velocity: Vector2 = Vector2.ZERO
var health: Health

var _flash: FlashEffect


func _init() -> void:
	health = Health.new()
	health.invulnerability_time = 1.0
	add_child(health)

	# Blink for as long as the player is invulnerable
	_flash = FlashEffect.new()
	_flash.flash_count = ceili(health.invulnerability_time / _flash.flash_duration)
	add_child(_flash)


func _ready() -> void:
	health.max_health = max_health
	health.reset()
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if health.is_dead:
		return

	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = velocity.move_toward(input * speed, acceleration * delta)
	position += velocity * delta
	if arena.has_area():
		position = position.clamp(arena.position, arena.end)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, dead_color if health.is_dead else color)


func _on_damaged(_amount: int) -> void:
	_flash.flash()


func _on_died() -> void:
	_flash.stop()
	queue_redraw()
