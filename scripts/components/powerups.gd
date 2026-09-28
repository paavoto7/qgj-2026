class_name Powerups
extends Node
## Powerup component. Add it as a child of the Player. Applies powerups and removes timed ones when they run out.
## Picking up a powerup that is already active restarts its timer instead of stacking it.

signal powerup_added(data: PowerupData)
signal powerup_expired(data: PowerupData)

## Seconds left for every active timed powerup.
var _remaining: Dictionary[PowerupData, float] = {}

@onready var _player: Player = get_parent() as Player


func _physics_process(delta: float) -> void:
	for data: PowerupData in _remaining.keys():
		_remaining[data] -= delta
		if _remaining[data] <= 0.0:
			_expire(data)


## Returns the Powerups child of node, or null.
static func find_in(node: Node) -> Powerups:
	if node is Powerups:
		return node

	for child: Node in node.get_children():
		if child is Powerups:
			return child

	return null


func add(data: PowerupData) -> void:
	if not data or not is_instance_valid(_player):
		return

	# Reapply so effects that depend on the duration, like the shield, are refreshed too
	if _remaining.has(data):
		data.remove(_player)
	data.apply(_player)
	if data.is_timed:
		_remaining[data] = data.duration
	powerup_added.emit(data)


func is_active(data: PowerupData) -> bool:
	return _remaining.has(data)


## Seconds left for a timed powerup, or 0 if it isn't active.
func time_left(data: PowerupData) -> float:
	return _remaining.get(data, 0.0)


## Removes every active powerup, e.g. when the player dies.
func clear() -> void:
	for data: PowerupData in _remaining.keys():
		_expire(data)


func _expire(data: PowerupData) -> void:
	_remaining.erase(data)
	data.remove(_player)
	powerup_expired.emit(data)


func collect(data: PowerupData) -> void:
	if not data or not is_instance_valid(_player):
		return

	add(data)
	if _player.powerup_sound:
		AudioManager.play_sfx_2d(_player.powerup_sound, _player.position, -6.0)
