@tool
class_name Enemy
extends Node2D
## Enemy that dies when the thread winds around it in the right pattern.
## Its EnemyType child component decides the pattern. Positive winds are clockwise.
## A tool script so it's drawn in the editor. Gameplay code is skipped there.

## Emitted when this enemy creates a new one, e.g. by splitting. Whoever owns the enemies adds it to the scene.
signal spawned(new_enemy: Enemy)
## Emitted when this enemy drops an item, not yet in the tree. Whoever owns the enemies adds it to the scene.
signal dropped(item: Node2D)

## How much of a wind can be missing and still count. Keeps sloppy loops forgiving.
const TOLERANCE: float = 0.15
const RING_SPACING: float = 5.0

@export var speed: float = 55.0
@export var radius: float = 16.0
## Used on the target once it's within the attack's range of the enemy's edge. None means harmless.
@export var attack: Attack = null
## What the enemy can drop when it's knotted. None means it drops nothing.
@export var drop_table: DropTable = null

var target: Node2D
## The wave the enemy spawned on, set by the WaveSpawner. Used for wave-based weights.
var wave: int = 0
var is_knotted: bool = false
var color: Color:
	get:
		return type.get_color() if is_instance_valid(type) else Color.WHITE

var _progress: float = 0.0
var _completed_winds: int = 0
var _thread_completed_winds: int = 0
var _winding_total: float = 0.0
var _previous_position: Vector2
var _previous_player_position: Vector2
var _winding_initialized: bool = false

@onready var type: EnemyType = EnemyType.find_in(self)


func _ready() -> void:
	if Engine.is_editor_hint():
		# Pick up a Type child added or removed while editing
		child_order_changed.connect(func() -> void: type = EnemyType.find_in(self))
		set_physics_process(false)
		return

	if not is_instance_valid(type):
		push_error("Enemy '%s' needs an EnemyType child component." % name)
		set_physics_process(false)
		return

	speed = type.get_speed()
	radius = type.get_radius()
	type.pick_movement_pattern(wave)


func _physics_process(delta: float) -> void:
	if is_knotted or not is_instance_valid(target):
		return
	
	# Move toward the target, then apply the movement pattern if any. The EnemyType steers the velocity first.
	position += type.apply_movement_pattern(
		type.steer(position.direction_to(target.position) * speed)) * delta
	
	_attack_in_range()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color.darkened(0.6))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 2.0)
	if not is_instance_valid(type):
		return

	# One ring per remaining wind, filling clockwise or counterclockwise from the top
	var winds: int = type.winds_needed()
	var remaining_winds: int = maxi(winds - _completed_winds, 0)
	var direction: float = type.direction()

	for i: int in remaining_winds:
		var ring_radius: float = radius + 6.0 + i * RING_SPACING
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(color, 0.25), 2.0)

		var fill: float = clampf(_progress - i, 0.0, 1.0)
		if fill > 0.0:
			draw_arc(
				Vector2.ZERO,
				ring_radius,
				-PI / 2.0,
				-PI / 2.0 + direction * fill * TAU,
				48,
				color,
				3.0
			)

	# Arrowhead at the top shows which way to go
	if remaining_winds > 0:
		var tip := Vector2(
			0.0,
			-(radius + 6.0 + remaining_winds * RING_SPACING + 3.0)
		)
		draw_colored_polygon(PackedVector2Array([
			tip + Vector2(direction * 7.0, 0.0),
			tip + Vector2(-direction * 3.0, -5.0),
			tip + Vector2(-direction * 3.0, 5.0),
		]), color)

	type.draw_extras()


## Returns the enemies in a freshly instantiated scene: the root if it's an Enemy, otherwise its Enemy children.
## Children are taken out of the group, keeping its position as an offset from it, and the group is freed.
static func take_from(node: Node) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	if node is Enemy:
		enemies.append(node)
		return enemies

	for child: Node in node.get_children():
		if child is Enemy:
			node.remove_child(child)
			enemies.append(child)
	node.free()
	return enemies


## Updates the progress rings and returns true when the thread knots this enemy.
## [param windings] holds the winding around every enemy in the arena.
func evaluate(windings: Dictionary[Enemy, float]) -> bool:
	if not is_instance_valid(type):
		return false

	var along: float = type.wound_amount(windings)
	var needed: int = type.winds_needed()

	if along < 0.0:
		_progress = 0.0
		return false

	# The current, unfinished wind can be reversed.
	if absf(along) <= TOLERANCE:
		_thread_completed_winds = 0
		_progress = 0.0
		return false

	# Count only newly completed winds.
	var completed_in_thread: int = floori(along + TOLERANCE)
	var newly_completed: int = completed_in_thread - _thread_completed_winds

	if newly_completed > 0:
		_completed_winds += newly_completed
		_thread_completed_winds = completed_in_thread

	# Progress only represents the currently unfinished wind.
	_progress = along - completed_in_thread

	return _completed_winds >= needed


func knot() -> void:
	is_knotted = true
	if is_instance_valid(type):
		type.on_knotted()
	_drop_item()

	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", type.direction() * TAU, 0.3)
	tween.chain().tween_callback(queue_free)


## Hands a new enemy, not yet in the tree, to whoever owns the enemies. It chases the same target.
func spawn(new_enemy: Enemy) -> void:
	new_enemy.target = target
	spawned.emit(new_enemy)


func _attack_in_range() -> void:
	if is_instance_valid(attack) and position.distance_to(target.position) <= radius + attack.attack_range:
		attack.try_attack(target)


func _drop_item() -> void:
	if not drop_table:
		return

	var scene: PackedScene = drop_table.roll(wave)
	if not scene:
		return

	var instance: Node = scene.instantiate()
	var item: Node2D = instance as Node2D
	if not item:
		instance.free()
		push_error("Enemy '%s' drop scene '%s' needs a Node2D root." % [name, scene.resource_path])
		return

	item.position = position
	dropped.emit(item)

func update_winding(player_position: Vector2) -> void:
	var current_position: Vector2 = global_position

	if not _winding_initialized:
		_previous_player_position = player_position
		_previous_position = current_position
		_winding_initialized = true
		return

	var previous_relative: Vector2 = _previous_player_position - _previous_position
	var current_relative: Vector2 = player_position - current_position

	if previous_relative.length_squared() > 0.001 and current_relative.length_squared() > 0.001:
		_winding_total += angle_difference(
			previous_relative.angle(),
			current_relative.angle()
		) / TAU

	_previous_player_position = player_position
	_previous_position = current_position


func get_winding_total() -> float:
	return _winding_total
