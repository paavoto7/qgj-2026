class_name PauseMenu
extends OverlayMenu
## Pause menu over the dimmed arena. Toggled with the "pause" action. The layout and styling live in pause_menu.tscn.

@export_file("*.tscn") var menu_scene: String = "res://scenes/ui/main_menu.tscn"
@export var click_sound: AudioStream

## Whether the pause action opens the menu. Turned off on game over.
var can_pause: bool = true

@onready var _run_label: Label = %RunLabel
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	# Esc matches both actions, so they're checked together
	if event.is_action_pressed("pause"):
		if visible:
			resume()
		elif can_pause:
			pause()
		else:
			return
	elif visible and event.is_action_pressed("ui_cancel"):
		resume()
	else:
		return
	get_viewport().set_input_as_handled()


func pause() -> void:
	MainManager.pause_game()
	open()


func resume() -> void:
	close()
	MainManager.resume_game()


## Sets the current run's numbers shown in the menu.
func show_run(score: int, wave: int) -> void:
	_run_label.text = "Score %d · Wave %d" % [score, wave]


func _on_resume_pressed() -> void:
	AudioManager.play_ui(click_sound)
	resume()


func _on_restart_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.reload_scene()


func _on_menu_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.change_scene(menu_scene)
