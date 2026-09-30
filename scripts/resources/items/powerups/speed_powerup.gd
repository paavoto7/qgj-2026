class_name SpeedPowerup
extends PowerupData
## Makes the player faster for the duration.

@export var multiplier: float = 1.5


func apply(player: Player) -> void:
	player.speed *= multiplier


func remove(player: Player) -> void:
	player.speed /= multiplier
