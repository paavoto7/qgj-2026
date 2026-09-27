class_name Powerup
extends Item
## Item that gives the player a powerup. Shows the powerup's sprite and colour on a sibling Sprite2D.

@export var powerup_data: PowerupData

@onready var _sprite: Sprite2D = get_node_or_null("../Sprite2D")


func _ready() -> void:
	super()
	if not powerup_data:
		push_error("Powerup '%s' has no Powerup Data." % area.name)
		return

	if is_instance_valid(_sprite):
		if powerup_data.sprite:
			_sprite.texture = powerup_data.sprite
		_sprite.modulate = powerup_data.color


func _on_collected(player: Player) -> void:
	if not powerup_data:
		return

	var powerups: Powerups = player.powerups
	if not powerups:
		push_error("Player has no Powerups component, so '%s' does nothing." % powerup_data.name)
		return

	powerups.collect(powerup_data)
