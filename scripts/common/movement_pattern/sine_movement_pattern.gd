class_name SineMovementPattern
extends MovementPattern
	
## The amplitude of the sine wave.
@export var amplitude: float = 50.0

## The frequency of the sine wave.
@export var frequency: float = 1.0
## The phase offset of the sine wave.
@export var phase: float = 0.0

var _time: float = 0.0


func apply(velocity: Vector2) -> Vector2:
	_time += get_process_delta_time()
	var sine_offset: float = amplitude * sin(frequency * _time + phase)
	var perpendicular: Vector2 = velocity.normalized().rotated(PI / 2)
	return velocity + perpendicular * sine_offset
