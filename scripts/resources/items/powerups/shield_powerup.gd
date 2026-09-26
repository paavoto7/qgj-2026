class_name ShieldPowerup
extends PowerupData
## Makes the player invulnerable for the duration, so hits don't snap the thread.


func _init() -> void:
	duration = 5.0


func apply(player: Player) -> void:
	player.health.make_invulnerable(duration)
