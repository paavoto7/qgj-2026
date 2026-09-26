@tool
class_name Player
extends Node2D
## Player. Moves freely inside the arena and leaves its path behind as the thread.
## Needs Health and FlashEffect children. Set max health and invulnerability time on the Health node.
## To collect items it needs an Interactor under its HitBox, and a Powerups child for powerups.
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
var thread: ThreadTrail

@onready var health: Health = $Health
@onready var powerups: Powerups = Powerups.find_in(self)
@onready var _flash: FlashEffect = $FlashEffect


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	# Blink for as long as the player is invulnerable
	_flash.set_flash_count_by_health(health)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health.invulnerable_hit.connect(_on_invulnerable_hit)

	thread = ThreadTrail.new()
	add_child(thread)


func _physics_process(delta: float) -> void:
	if health.is_dead:
		return

	thread.add_point(position)
	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = velocity.move_toward(input * speed, acceleration * delta)
	position += velocity * delta
	if arena.has_area():
		position = position.clamp(arena.position, arena.end)


func _draw() -> void:
	var is_dead: bool = not Engine.is_editor_hint() and health.is_dead
	draw_circle(Vector2.ZERO, radius, dead_color if is_dead else color)


func _on_damaged(_amount: int) -> void:
	# A hit snaps the thread
	thread.clear()
	_flash.flash()


func _on_died() -> void:
	_flash.stop()
	if is_instance_valid(powerups):
		powerups.clear()
	queue_redraw()


func _on_invulnerable_hit() -> void:
	_flash.flash()
