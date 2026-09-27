@tool
class_name PurpleType
extends EnemyType
## A special enemy that requires alternating winding directions.
## Each completed wind switches the required direction.


@export var required_winds: int = 3

var _starting_direction: float = 1.0
## Progress of the current wind in the required direction. Never below 0.
var _progress: float = 0.0
var _last_winding: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_starting_direction = 1.0 if randf() < 0.5 else -1.0


func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	# Add how far the player wound this frame. The wrong way counts as negative,
	# but progress never drops below 0, so turning around counts straight away.
	var winding: float = windings.get(enemy, 0.0)
	_progress = maxf(_progress + (winding - _last_winding) * direction(), 0.0)
	_last_winding = winding
	return _progress


func on_wind_completed() -> void:
	# The direction flips, so the next wind starts from scratch
	_progress = 0.0


func direction() -> float:
	# Flip direction after every completed wind.
	if enemy._completed_winds % 2 == 0:
		return _starting_direction
	else:
		return _starting_direction * -1.0


func winds_needed() -> int:
	return maxi(required_winds, 1)
