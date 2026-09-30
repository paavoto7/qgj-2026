@abstract
class_name PowerupData
extends Resource
## What a powerup does to the player. Extend it, implement apply() and, for timed powerups, remove().
## The player's Powerups component calls them, so a powerup only has to describe its effect.

@export var name: String
@export var sprite: Texture2D
## Seconds the effect lasts. 0 makes it instant, so remove() is never called.
@export var duration: float = 0.0

var is_timed: bool:
	get:
		return duration > 0.0


## Starts the effect.
@abstract func apply(player: Player) -> void


## Undoes apply() when a timed powerup runs out.
func remove(_player: Player) -> void:
	pass
