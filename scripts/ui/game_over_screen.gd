class_name GameOverScreen
extends OverlayMenu
## Game over screen with the run's score and lifetime stats, plus restart and main menu buttons.
## Esc also returns to the menu. The layout and styling live in game_over_screen.tscn.

@export var high_score_color: Color = Color(1.0, 0.82, 0.3)
@export_file("*.tscn") var menu_scene: String = "res://scenes/ui/main_menu.tscn"
@export var click_sound: AudioStream

## The best label's colour from the scene, used when it isn't a new high score.
var _best_color: Color

@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_best_color = _best_label.get_theme_color("font_color")
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	# Accept is handled by the focused button
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_menu_pressed()


## Opens the screen with the run's score. Call it after the run is recorded, so the totals include it.
func show_results(score: int, is_new_high_score: bool) -> void:
	var data: GameData = MainManager.game_data
	_score_label.text = "Score %d" % score
	_best_label.text = "New high score!" if is_new_high_score else "Best %d" % data.high_score
	_best_label.add_theme_color_override("font_color", high_score_color if is_new_high_score else _best_color)
	_stats_label.text = "%d knotted · %d runs · %d waves" % [data.enemies_knotted, data.runs_played, data.waves_cleared]
	open()


func _on_restart_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.reload_scene()


func _on_menu_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.change_scene(menu_scene)
