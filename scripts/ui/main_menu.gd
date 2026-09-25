class_name MainMenu
extends MenuBase
## Main menu with a title and Start / Quit buttons. Builds its own UI, so the scene only needs this script on a CanvasLayer.

@export var title: String = "Winding Combat"
@export_multiline var subtitle: String = "Don't shoot. Wind your thread around enemies to knot them."
@export_file("*.tscn") var game_scene: String = "res://scenes/winding/winding_arena.tscn"
@export var title_font_size: int = 64
@export var button_min_size: Vector2 = Vector2(240.0, 48.0)
@export var click_sound: AudioStream


func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)

	var title_label := _add_label(column, title)
	title_label.add_theme_font_size_override("font_size", title_font_size)
	_add_label(column, subtitle)

	var start_button := _add_button(column, "Start", _on_start_pressed)
	# Web builds can't quit, so the button would do nothing there
	if not OS.has_feature("web"):
		_add_button(column, "Quit", _on_quit_pressed)

	# MenuBase only focuses on visibility changes, and this menu starts visible
	initial_focus = start_button
	start_button.grab_focus.call_deferred()


func _add_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _add_button(parent: Control, text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = button_min_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button


func _on_start_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.change_scene(game_scene)


func _on_quit_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.quit_game()
