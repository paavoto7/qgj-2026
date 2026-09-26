@tool
class_name PurpleType
extends EnemyType
## A special enemy that requires alternating winding directions.
## Each completed wind switches the required direction.


@export var required_winds: int = 3

var _starting_direction: float = 1.0
var _winding_origin: float = 0.0
var _origin_wind_count: int = 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_starting_direction = 1.0 if randf() < 0.5 else -1.0


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	var raw_winding: float = windings.get(enemy, 0.0)

	# When Purple completes a wind, use the current thread winding
	# as the starting point for the next direction.
	if enemy._completed_winds != _origin_wind_count:
		_winding_origin = raw_winding
		_origin_wind_count = enemy._completed_winds

	var winding: float = (raw_winding - _winding_origin) * direction()
	return maxf(winding, 0.0)


func direction() -> float:
	if not is_instance_valid(enemy):
		return _starting_direction

	# Flip direction after every completed wind.
	return _starting_direction * (-1.0 if enemy._completed_winds % 2 == 1 else 1.0)


func winds_needed() -> int:
	return maxi(required_winds, 1)
