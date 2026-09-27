class_name HUD
extends Control
## In-game HUD with the wave, score, combo countdown and player HP, plus the pause menu and game over screen.
## The arena calls setup() and the show_* methods; the HUD doesn't look anything up itself.

var _wave: WaveData
var _wave_number: int = 0
var _score: int = 0
var _combo: int = 0
## Display-only countdown, reset by every show_combo() call.
var _combo_time_left: float = 0.0
var _player_health: int = 0

@onready var _score_label: Label = $ScoreLabel
@onready var _game_over_screen: GameOverScreen = $GameOverScreen
@onready var _pause_menu: PauseMenu = $PauseMenu


func _process(delta: float) -> void:
	if _combo == 0:
		return

	_combo_time_left = maxf(_combo_time_left - delta, 0.0)
	_update_hud()


func setup(label_position: Vector2, player: Player) -> void:
	_game_over_screen.hide()
	_pause_menu.hide()
	_score_label.position = label_position
	_player_health = player.health.current_health
	player.health.health_changed.connect(_on_player_health_changed)
	_update_hud()


func show_wave(wave_data: WaveData, number: int) -> void:
	_wave = wave_data
	_wave_number = number
	_update_hud()


func show_score(score: int) -> void:
	_score = score
	_update_hud()


func show_combo(combo: int, time_left: float) -> void:
	_combo = combo
	_combo_time_left = time_left
	_update_hud()


func show_game_over(score: int, is_new_high_score: bool) -> void:
	# No pausing over the game over screen
	_pause_menu.can_pause = false
	_game_over_screen.show_results(score, is_new_high_score)


func _on_player_health_changed(current: int, _maximum: int) -> void:
	_player_health = current
	_update_hud()


func _update_hud() -> void:
	var text: String = "Wave %d    Score %d    HP %d" % [_wave_number, _score, _player_health]
	if _combo > 0:
		text += "    x%d combo  %.1fs" % [_combo, _combo_time_left]
	if _wave and not _wave.hint.is_empty():
		text += "\n" + _wave.hint
	_score_label.text = text
	_pause_menu.show_run(_score, _wave_number)
