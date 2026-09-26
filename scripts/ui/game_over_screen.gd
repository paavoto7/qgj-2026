class_name GameOverScreen
extends MenuBase
## Game over screen for winding combat. Builds its own label, restarts on accept and returns to the menu on cancel.

@export var message: String = "The thread snapped.\nEnter to try again, Esc for the main menu."
@export var font_size: int = 32
@export_file("*.tscn") var menu_scene: String = "res://scenes/ui/main_menu.tscn"


func _ready() -> void:
	var label := Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept"):
		MainManager.reload_scene()
	elif event.is_action_pressed("ui_cancel"):
		MainManager.change_scene(menu_scene)
