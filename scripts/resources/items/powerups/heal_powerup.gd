class_name HealPowerup
extends PowerupData
## Heals the player right away.

@export var amount: int = 1


func apply(player: Player) -> void:
	player.health.heal(amount)
