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
@onready var _combo_label: RichTextLabel = $ComboLabel
@onready var _game_over_screen: GameOverScreen = $GameOverScreen
@onready var _pause_menu: PauseMenu = $PauseMenu


func _process(delta: float) -> void:
	if _combo == 0:
		return

	_combo_time_left = maxf(_combo_time_left - delta, 0.0)

	if _combo_time_left <= 0.0:
		_combo = 0
		_fade_combo_out()
		return

	_update_hud()


func setup(label_position: Vector2, player: Player) -> void:
	_game_over_screen.hide()
	_pause_menu.hide()
	_score_label.position = label_position
	_combo_label.position = label_position + Vector2(250.0, 7.0)
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
	var increased := combo > _combo

	_combo = combo
	_combo_time_left = time_left
	_update_hud()

	if increased:
		_pulse_combo()
	

func _pulse_combo() -> void:
	_combo_label.pivot_offset = _combo_label.size * 0.5
	_combo_label.scale = Vector2(0.75, 0.75)
	_combo_label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.28)
	tween.tween_property(_combo_label, "modulate:a", 1.0, 0.20)
	

func show_game_over(score: int, is_new_high_score: bool) -> void:
	# No pausing over the game over screen
	_pause_menu.can_pause = false
	_game_over_screen.show_results(score, is_new_high_score)


func _on_player_health_changed(current: int, _maximum: int) -> void:
	_player_health = current
	_update_hud()


func _update_hud() -> void:
	var hp := ""
	for i: int in 3:
		hp += "◼ " if i < _player_health else "◻ "
	hp = hp.strip_edges()

	_score_label.text = "%-13s%-12s%-16s" % [
		"HP " + hp,
		"WAVE %02d" % _wave_number,
		"SCORE %d" % _score,
	]

	if _combo > 0:
		_combo_label.text = "[center][b]COMBO ×%d[/b][/center]" % _combo
	else:
		_combo_label.text = ""

	_pause_menu.show_run(_score, _wave_number)
	
	
func _fade_combo_out() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(_combo_label, "modulate:a", 0.0, 0.25)
	tween.tween_property(_combo_label, "scale", Vector2(0.92, 0.92), 0.25)
