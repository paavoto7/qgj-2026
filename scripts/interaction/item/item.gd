@abstract
class_name Item
extends Interactable
## A pickup. Add it as a child of an Area2D, like any Interactable, and extend it with _on_collected().
## Collected on touch by default, so the player needs an Interactor on its HitBox. Frees the area once collected.

## Seconds before the item disappears if nobody collects it. 0 or less keeps it forever.
@export var lifetime: float = 10.0
## Seconds at the end of the lifetime during which the item fades out.
@export var fade_time: float = 2.0

var _time_left: float

@onready var _canvas_item: CanvasItem = area as CanvasItem


func _init() -> void:
	interact_on_touch = true
	one_shot = true


func _ready() -> void:
	_time_left = lifetime
	set_process(lifetime > 0.0)


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		area.queue_free()
		return

	if is_instance_valid(_canvas_item) and fade_time > 0.0:
		_canvas_item.modulate.a = clampf(_time_left / fade_time, 0.0, 1.0)


func interact(interactor: Node) -> void:
	var player: Player = interactor as Player
	if not enabled or not is_instance_valid(player) or player.health.is_dead:
		return

	super(interactor)
	_on_collected(player)
	area.queue_free()


## What collecting the item does.
@abstract func _on_collected(player: Player) -> void
