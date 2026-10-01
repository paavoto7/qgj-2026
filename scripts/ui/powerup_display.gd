class_name PowerupDisplay
extends VBoxContainer
## Stack of icons for the active timed powerups, right-aligned in the top right corner.
## Icons are laid out by the container, so the rest moves up when one expires.
## Call bind() with the player's Powerups and place() with the distance from the corner.

const _PULSE_SCALE: Vector2 = Vector2(0.75, 0.75)

## Minimum width of the icons, in pixels. The height is scaled to keep the aspect ratio.
@export var width: float = 54.0

## Icons are the sprite size times this.
@export var icon_scale: float = 0.8

## One icon per active powerup.
var _icons: Dictionary[PowerupData, TextureRect] = {}
var _powerups: Powerups
var _margin: Vector2


func _exit_tree() -> void:
	if not is_instance_valid(_powerups):
		return

	_powerups.powerup_added.disconnect(_on_powerup_added)
	_powerups.powerup_expired.disconnect(_on_powerup_expired)


## Keeps the stack in sync with the powerups component.
func bind(powerups: Powerups) -> void:
	_powerups = powerups
	_powerups.powerup_added.connect(_on_powerup_added)
	_powerups.powerup_expired.connect(_on_powerup_expired)


## Keeps the stack's top right corner margin pixels away from the viewport's.
func place(margin: Vector2) -> void:
	_margin = margin
	if not resized.is_connected(_reposition):
		resized.connect(_reposition)
	_reposition()


func _reposition() -> void:
	position = Vector2(get_viewport_rect().size.x - _margin.x - size.x, _margin.y)


## Adds a new icon for the powerup, or pulses the existing one if it's already in the stack.
func _on_powerup_added(data: PowerupData) -> void:
	# Instant powerups never expire, so they would stay in the stack forever
	if not data.is_timed or not data.sprite:
		return

	# Picked up again, so the timer restarted
	if _icons.has(data):
		ItemFade.pulse_item(self, _icons[data])
		return

	var icon := TextureRect.new()
	icon.texture = data.sprite
	var icon_size: Vector2 = icon.texture.get_size()
	icon_size.x = width

	icon.custom_minimum_size = icon_size * icon_scale
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_END

	add_child(icon)
	_icons[data] = icon
	ItemFade.pulse_item(self, icon)


func _on_powerup_expired(data: PowerupData) -> void:
	var icon: TextureRect = _icons.get(data)
	if not icon:
		return

	# Erased right away so a pickup during the fade gets a fresh icon
	_icons.erase(data)

	var tween := create_tween()
	tween.tween_property(icon, "modulate:a", 0.0, 0.25)
	# Leaves the stack only once faded, then the others move up
	tween.tween_callback(icon.queue_free)
