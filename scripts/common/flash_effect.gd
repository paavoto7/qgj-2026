class_name FlashEffect
extends Node
## Flashes the parent CanvasItem (sprite, label...) or GeometryInstance3D, e.g. when taking damage.
##
## 2D modulates the colour, 3D fades the instance transparency.

@export var flash_color: Color = Color(1, 1, 1, 0.5)
## Duration of one flash, half fading in and half fading out.
@export var flash_duration: float = 0.2
@export var flash_count: int = 1
## Transparency used at the peak of a 3D flash.
@export_range(0.0, 1.0) var flash_transparency_3d: float = 0.5

var is_flashing: bool:
	get:
		return _tween != null and _tween.is_running()

@onready var _target: Node = get_parent()

var _original_modulate: Color
var _original_transparency: float
var _tween: Tween


func _ready() -> void:
	if _target is CanvasItem:
		_original_modulate = _target.modulate
	elif _target is GeometryInstance3D:
		_original_transparency = _target.transparency
	else:
		push_warning("FlashEffect: parent must be a CanvasItem or GeometryInstance3D")


func flash() -> void:
	stop()
	_tween = create_tween().set_loops(max(flash_count, 1))
	var half: float = flash_duration * 0.5
	if _target is CanvasItem:
		_tween.tween_property(_target, "modulate", flash_color, half)
		_tween.tween_property(_target, "modulate", _original_modulate, half)
	elif _target is GeometryInstance3D:
		_tween.tween_property(_target, "transparency", flash_transparency_3d, half)
		_tween.tween_property(_target, "transparency", _original_transparency, half)


func stop() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	if _target is CanvasItem:
		_target.modulate = _original_modulate
	elif _target is GeometryInstance3D:
		_target.transparency = _original_transparency
