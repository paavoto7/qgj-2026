@tool
class_name Enemy
extends Node2D
## Enemy that dies when the thread winds around it in the right pattern.
## Its EnemyType child component decides the pattern. Positive winds are clockwise.
## Only movement within Wind Range counts, and an unfinished wind slides back if it makes no progress for a while.
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
## How close to the enemy's centre the player must be for its movement to wind the enemy.
## Stops laps around the whole arena from winding every enemy inside them.
@export var wind_range: float = 180.0
## Seconds without winding progress before the unfinished wind starts sliding back.
@export var unwind_delay: float = 1.0
## Winds per second the unfinished wind slides back. Completed winds stay done.
@export var unwind_speed: float = 0.5

var target: Node2D
## The wave the enemy spawned on, set by the WaveSpawner. Used for wave-based weights.
var wave: int = 0
var is_knotted: bool = false
var color: Color:
	get:
		return type.get_color() if is_instance_valid(type) else Color.WHITE
## How many winds the thread has completed around the enemy.
var completed_winds: int:
	get:
		return _completed_winds
## Total winding done in the needed direction: completed winds plus the current one, e.g. 2.4.
var total_wound: float:
	get:
		return _completed_winds + _wind_progress

## Progress of the current, unfinished wind in the needed direction, from 0 to 1.
var _wind_progress: float = 0.0
## Finished winds. The enemy is knotted when this reaches the type's winds_needed().
var _completed_winds: int = 0
## Seconds since the wind last made progress.
var _idle_time: float = 0.0
## The player's position relative to the winding centre on the previous frame. Zero until the first frame.
var _previous_offset: Vector2 = Vector2.ZERO

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

	# While a wind is in progress, show the range it counts in and dim the fill as it's about to slide back
	var fill_color: Color = color
	if _wind_progress > 0.0:
		draw_arc(to_local(type.winding_center()), wind_range, 0.0, TAU, 64, Color(color, 0.12), 1.0)
		var countdown: float = clampf(_idle_time / maxf(unwind_delay, 0.001), 0.0, 1.0)
		fill_color = Color(color, lerpf(1.0, 0.35, countdown))

	for i: int in remaining_winds:
		var ring_radius: float = radius + 6.0 + i * RING_SPACING
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(color, 0.25), 2.0)

		var fill: float = clampf(_wind_progress - i, 0.0, 1.0)
		if fill > 0.0:
			draw_arc(
				Vector2.ZERO,
				ring_radius,
				-PI / 2.0,
				-PI / 2.0 + direction * fill * TAU,
				48,
				fill_color,
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


## Advances the winding from the player's movement this frame. Returns true when the enemy is knotted.
func update_winding(player_position: Vector2, delta: float) -> bool:
	if not is_instance_valid(type):
		return false

	var offset: Vector2 = player_position - type.winding_center()
	var distance: float = offset.length()
	var step: float = 0.0
	# Only movement within range counts, so laps around the arena don't wind every enemy inside them
	var in_range: bool = distance <= wind_range and distance >= type.min_wind_distance()
	if in_range and offset.length_squared() > 0.001 and _previous_offset.length_squared() > 0.001:
		step = angle_difference(
				_previous_offset.angle(),
				offset.angle()
			) / TAU * type.direction()
	_previous_offset = offset

	# Winding the wrong way never goes below 0, so turning around counts straight away
	_wind_progress = maxf(_wind_progress + step, 0.0)
	_idle_time = 0.0 if step > 0.0 else _idle_time + delta

	# No progress for a while, so the unfinished wind slides back. Completed winds stay done.
	if _idle_time > unwind_delay:
		_wind_progress = maxf(_wind_progress - unwind_speed * delta, 0.0)

	if _wind_progress >= 1.0 - TOLERANCE:
		_wind_progress = 0.0
		_completed_winds += 1
		type.on_wind_completed()

	return _completed_winds >= type.winds_needed()


## Drops the current, unfinished wind. Completed winds stay done.
func reset_winding() -> void:
	_wind_progress = 0.0
	_idle_time = 0.0


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
