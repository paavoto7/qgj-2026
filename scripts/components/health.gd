class_name Health
extends Node
## Health component. Add it as a child of anything that can take damage and connect to its signals.

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died
signal invulnerable_hit

@export var max_health: int = 100
## Seconds of invulnerability after taking damage. 0 disables it.
@export var invulnerability_time: float = 0.0
@export var hurt_sound: AudioStream
@export var death_sound: AudioStream


var current_health: int
var is_dead: bool:
	get:
		return current_health <= 0

var _invulnerable_until: float = 0.0


func _ready() -> void:
	current_health = max_health


## Returns the first Health child of node, or null. Use it to find the Health of a body that entered an area.
static func find_in(node: Node) -> Health:
	if node is Health:
		return node

	for child: Node in node.get_children():
		if child is Health:
			return child

	return null


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead:
		return
	
	if _is_invulnerable():
		invulnerable_hit.emit()
		# invulnerability_flash.set_flash_count_by_health(self)
		# invulnerability_flash.flash()
		return

	current_health = max(current_health - amount, 0)
	if invulnerability_time > 0.0:
		_invulnerable_until = _now() + invulnerability_time

	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if is_dead:
		AudioManager.play_sfx(death_sound)
		died.emit()
	else:
		AudioManager.play_sfx(hurt_sound)


func heal(amount: int) -> void:
	if amount <= 0 or is_dead:
		return

	var healed_amount: int = min(amount, max_health - current_health)
	current_health += healed_amount
	healed.emit(healed_amount)
	health_changed.emit(current_health, max_health)


func kill() -> void:
	_invulnerable_until = 0.0
	take_damage(current_health)


## Brings a dead or damaged character back to full health.
func reset() -> void:
	current_health = max_health
	_invulnerable_until = 0.0
	health_changed.emit(current_health, max_health)


func _is_invulnerable() -> bool:
	return _now() < _invulnerable_until


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
