@tool
class_name Player
extends Node2D
## Player. Moves freely inside the arena, which records its path as the thread.
## Needs Health and FlashEffect children. Set max health and invulnerability time on the Health node.
## A tool script so it's drawn in the editor. Gameplay code is skipped there.

@export var speed: float = 340.0
@export var acceleration: float = 2400.0
@export var radius: float = 10.0:
	set(value):
		radius = value
		queue_redraw()
@export var color: Color = Color(1.0, 0.85, 0.4):
	set(value):
		color = value
		queue_redraw()
@export var dead_color: Color = Color(0.4, 0.4, 0.4)

var arena: Rect2
var velocity: Vector2 = Vector2.ZERO

@onready var health: Health = $Health
@onready var _flash: FlashEffect = $FlashEffect


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	# Blink for as long as the player is invulnerable
	_flash.flash_count = maxi(ceili(health.invulnerability_time / _flash.flash_duration), 1)
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
	var is_dead: bool = not Engine.is_editor_hint() and health.is_dead
	draw_circle(Vector2.ZERO, radius, dead_color if is_dead else color)


func _on_damaged(_amount: int) -> void:
	_flash.flash()


func _on_died() -> void:
	_flash.stop()
	queue_redraw()
