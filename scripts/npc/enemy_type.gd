@tool
class_name EnemyType
extends Node
## Component that decides an Enemy's type. Add exactly one as a child of an Enemy.
## It decides how the thread's winding counts, which way to wind and what colour the enemy is.
## On its own, the enemy is wound Winds times in the Clockwise direction. Subclasses change the rule.
## Subclasses must be tool scripts too, so the enemy is drawn in the editor.

## Set per type in the enemy's scene, on its Type node.
@export var color: Color = Color.WHITE
## How many winds knot the enemy. Also the number of rings drawn around it.
@export var winds: int = 1
## Which way to wind. Flips the rings and arrow too.
@export var clockwise: bool = true
## How likely the enemy is to just chase, compared to the weights of its MovementPattern children.
## Empty means a weight of 1 on every wave.
@export var no_pattern_weight: WaveWeight = null

## How the enemy moves, picked from the MovementPattern children when it spawns. Null means it just chases.
var movement_pattern: MovementPattern = null
var enemy: Enemy:
	get:
		return get_parent() as Enemy


## Returns the first EnemyType child of node, or null.
static func find_in(node: Node) -> EnemyType:
	for child: Node in node.get_children():
		if child is EnemyType:
			return child

	return null


## Picks one MovementPattern child, or none, by their weights on the given wave and frees the rest.
## Called by the Enemy when it's ready, so it works even if a subclass overrides _ready.
func pick_movement_pattern(wave: int) -> void:
	var patterns: Array[MovementPattern] = []
	var weights := PackedFloat32Array()
	for child: Node in get_children():
		var pattern: MovementPattern = child as MovementPattern
		if pattern:
			patterns.append(pattern)
			weights.append(WeightedRandom.weight_of(pattern.weight, wave))
	if patterns.is_empty():
		return

	# The last slot is plain chasing
	weights.append(WeightedRandom.weight_of(no_pattern_weight, wave))
	var index: int = WeightedRandom.pick_index(weights)
	movement_pattern = patterns[index] if index >= 0 and index < patterns.size() else null

	for pattern: MovementPattern in patterns:
		if pattern != movement_pattern:
			pattern.queue_free()


## How many winds the thread has made around the enemy in the direction it needs.
## [param windings] holds the thread's winding around every enemy in the arena.
func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0) * direction()


func get_color() -> Color:
	return color


func get_speed() -> float:
	return enemy.speed


func get_radius() -> float:
	return enemy.radius


func winds_needed() -> int:
	return maxi(winds, 1)


## 1 for clockwise, -1 for counterclockwise.
func direction() -> float:
	return 1.0 if clockwise else -1.0


## Adjusts the enemy's velocity, which chases the target by default.
func steer(velocity: Vector2) -> Vector2:
	return velocity

func apply_movement_pattern(velocity: Vector2) -> Vector2:
	if movement_pattern:
		return movement_pattern.apply(velocity)
	return velocity


## Called once every enemy spawned from the same scene is in the tree, e.g. to link them up.
func on_spawned(_group: Array[Enemy]) -> void:
	pass


## Called each time the thread completes a wind around the enemy, before the knot check.
func on_wind_completed() -> void:
	pass


## Called when the enemy is knotted, before it disappears. Spawn extra enemies with [method Enemy.spawn].
func on_knotted() -> void:
	pass


## Called at the end of Enemy._draw. Draw on [member enemy], in its local space.
func draw_extras() -> void:
	pass
