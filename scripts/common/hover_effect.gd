class_name HoverEffect
extends Node
## Bobs the parent Node2D or Node3D up and down, e.g. for pickups.

## Distance from the rest position, in pixels for 2D and metres for 3D.
@export var amplitude: float = 4.0
## Full bobs per second.
@export var frequency: float = 0.5
## Start at a random point of the cycle so identical objects don't bob in sync.
@export var randomize_phase: bool = true

@onready var _target: Node = get_parent()

var _rest_position: Variant
var _time: float = 0.0


func _ready() -> void:
	if not (_target is Node2D or _target is Node3D):
		push_warning("HoverEffect: parent must be a Node2D or Node3D")
		set_process(false)
		return

	_rest_position = _target.position
	if randomize_phase:
		_time = randf() / max(frequency, 0.001)


func _process(delta: float) -> void:
	_time += delta
	var offset: float = sin(_time * frequency * TAU) * amplitude
	if _target is Node2D:
		# 2D y points down, so subtract to start by moving up
		_target.position = _rest_position - Vector2(0.0, offset)
	else:
		_target.position = _rest_position + Vector3(0.0, offset, 0.0)
