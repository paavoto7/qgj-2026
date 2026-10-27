class_name HUD
extends Control
## In-game HUD with the wave, score, combo countdown and player HP, plus the pause menu and game over screen.
## The arena calls setup() and the show_* methods; the HUD doesn't look anything up itself.
## On mobile it adds a pause button, since there's no pause key.

const PAUSE_BUTTON_SIZE: Vector2 = Vector2(64.0, 64.0)

var _wave: WaveData
var _wave_number: int = 0
var _score: int = 0
var _combo: int = 0
## Display-only countdown, reset by every show_combo() call.
var _combo_time_left: float = 0.0
var _player_health: int = 0

var _arena_size: Vector2

@onready var _score_label: Label = $ScoreLabel
@onready var _combo_label: RichTextLabel = $ComboLabel
@onready var _powerup_display: PowerupDisplay = $PowerupDisplay
@onready var _game_over_screen: GameOverScreen = $GameOverScreen
@onready var _pause_menu: PauseMenu = $PauseMenu

@onready var _viewport: Viewport = get_viewport()


func _ready() -> void:
	# Touches on the HUD have to pass through to the player, which steers with them
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Phones have no pause key
	if MainManager.is_mobile:
		_add_pause_button()


func _process(delta: float) -> void:
	if _combo == 0:
		return

	_combo_time_left = maxf(_combo_time_left - delta, 0.0)

	if _combo_time_left <= 0.0:
		_combo = 0
		ItemFade.fade_item_out(self, _combo_label)
		return

	_update_hud()


func setup(label_position: Vector2, player: Player) -> void:
	_game_over_screen.hide()
	_pause_menu.hide()
	_arena_size = _viewport.get_visible_rect().size - label_position * 2.0

	_score_label.position = label_position
	_combo_label.position = label_position + Vector2(_arena_size.x / 4, 7.0)
	_player_health = player.health.current_health

	player.health.health_changed.connect(_on_player_health_changed)
	_powerup_display.place(label_position)
	_powerup_display.bind(player.powerups)
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
		ItemFade.pulse_item(self, _combo_label)


func show_game_over(score: int, is_new_high_score: bool) -> void:
	# No pausing over the game over screen
	_pause_menu.can_pause = false
	_game_over_screen.show_results(score, is_new_high_score)


func _add_pause_button() -> void:
	var button := Button.new()
	button.text = "II"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = PAUSE_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", 32)
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	button.pressed.connect(_on_pause_pressed)
	add_child(button)


func _on_pause_pressed() -> void:
	if _pause_menu.can_pause:
		_pause_menu.pause()


func _on_player_health_changed(current: int, _maximum: int) -> void:
	_player_health = current
	_update_hud()


func _update_hud() -> void:
	var hp := "HP %d" % _player_health

	_score_label.text = "%-6s%-9s%-12s" % [
		hp,
		"WAVE %02d" % _wave_number,
		"SCORE %d" % _score,
	]

	if _combo > 0:
		_combo_label.text = "[center][b]COMBO x%d[/b][/center]" % _combo
	else:
		_combo_label.text = ""

	_pause_menu.show_run(_score, _wave_number)
