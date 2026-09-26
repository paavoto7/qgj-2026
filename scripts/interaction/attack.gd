class_name Attack
extends Node
## Attack component. Add it as a child of the attacker and call try_attack() when a target is in reach.
## Melee attacks damage the target's Health right away, ranged ones spawn a projectile aimed at it.

## The amount of damage this attack deals.
@export var damage: int = 1
## The amount of knockback this attack applies (not used yet).
@export var knockback: Vector2 = Vector2.ZERO
## How far past the attacker's edge the attack reaches.
@export var attack_range: float = 100.0
## Seconds between attacks.
@export var cooldown: float = 0.5
## The projectile scene that ranged attacks spawn. Its root must be a Projectile.
@export var projectile: PackedScene
## Whether this attack is melee or ranged. If true, the attack is instant and does not spawn a projectile.
@export var is_melee: bool = false

var _ready_at: float = 0.0

@onready var parent: Node2D = get_parent() as Node2D


## Attacks the target unless the attack is still cooling down. Returns true if it attacked.
func try_attack(target: Node2D) -> bool:
	if _now() < _ready_at:
		return false
	
	_ready_at = _now() + cooldown
	_on_attack(target)
	return true


func _on_attack(target: Node2D) -> void:
	if is_melee:
		# Melee attacks are instant, so apply the effect immediately
		_apply_effect(target)
	elif projectile:
		# Ranged attacks spawn a projectile that applies the effect on hit
		var proj: Projectile = projectile.instantiate()
		proj.damage = damage
		proj.knockback = knockback
		proj.position = parent.global_position
		proj.rotation = parent.global_position.angle_to_point(target.global_position)
		get_tree().current_scene.add_child(proj)


## Applies the attack's effect to the target. Override to implement a different effect.
func _apply_effect(target: Node2D) -> void:
	var health: Health = Health.find_in(target)
	if health:
		health.take_damage(damage)

	if target.has_method("knockback"):
		target.knockback(knockback)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
