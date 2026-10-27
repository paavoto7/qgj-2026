@tool
class_name Player
extends Node2D
## Player that moves inside the arena and leaves its path behind as the thread. Drag anywhere to steer on touch screens.
## Needs Health and FlashEffect children, plus an Interactor under its HitBox and a Powerups child for items.

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
## How far a touch has to be dragged, in pixels, for full speed.
@export var touch_drag_distance: float = 60.0

@export var powerup_sound: AudioStream = null

var arena: Rect2
var velocity: Vector2 = Vector2.ZERO
var thread: ThreadTrail

## The finger steering the player, -1 when nothing is touching.
var _touch_index: int = -1
var _touch_start: Vector2
var _touch_input: Vector2 = Vector2.ZERO

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


func _notification(what: int) -> void:
	# The finger is usually lifted while paused, and that release never reaches the player
	if what == NOTIFICATION_PAUSED:
		_release_touch()


func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch:
		if touch.pressed and _touch_index == -1:
			_touch_index = touch.index
			_touch_start = touch.position
			_touch_input = Vector2.ZERO
		elif not touch.pressed and touch.index == _touch_index:
			_release_touch()
		return

	var drag := event as InputEventScreenDrag
	if drag and drag.index == _touch_index:
		# The start point trails the finger, so turning back responds right away
		var offset: Vector2 = (drag.position - _touch_start).limit_length(touch_drag_distance)
		_touch_start = drag.position - offset
		_touch_input = offset / touch_drag_distance


func _physics_process(delta: float) -> void:
	if health.is_dead:
		return

	var input: Vector2
	if _touch_index != -1:
		input = _touch_input
	else:
		input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = velocity.move_toward(input * speed, acceleration * delta)
	position += velocity * delta

	if arena.has_area():
		position = position.clamp(arena.position, arena.end)

	thread.add_point(position)


func _draw() -> void:
	var is_dead: bool = not Engine.is_editor_hint() and health.is_dead
	draw_circle(Vector2.ZERO, radius, dead_color if is_dead else color)


func _release_touch() -> void:
	_touch_index = -1
	_touch_input = Vector2.ZERO


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
