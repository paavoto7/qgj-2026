class_name ScoreKeeper
extends Node
## Keeps the score and combo. Each knot within the combo window raises the combo and scores 100 × combo.

signal score_changed(score: int)
## Emitted when the combo rises or breaks. [param time_left] is the seconds until it breaks, 0 when broken.
signal combo_changed(combo: int, time_left: float)

## Seconds after a knot during which the next knot raises the combo.
var combo_window: float = 3.0
var score: int = 0
var combo: int = 0

var _combo_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if combo == 0:
		return

	_combo_timer -= delta
	if _combo_timer <= 0.0:
		break_combo()


## Scores enemies knotted by the same thread. They all count towards one combo.
func add_knots(count: int) -> void:
	if count <= 0:
		return

	for i: int in count:
		combo += 1
		score += 100 * combo
	_combo_timer = combo_window
	score_changed.emit(score)
	combo_changed.emit(combo, _combo_timer)


func break_combo() -> void:
	if combo == 0:
		return

	combo = 0
	_combo_timer = 0.0
	combo_changed.emit(combo, 0.0)
