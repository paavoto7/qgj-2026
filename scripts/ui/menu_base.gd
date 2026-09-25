class_name MenuBase
extends CanvasLayer
## Base class for menus and screens. Shows the mouse cursor while visible and restores the gameplay mouse mode when hidden.

## Mouse mode while the menu is hidden, e.g. Captured for a first-person game.
@export var gameplay_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
## Keep processing while the game is paused, needed for pause menus.
@export var works_while_paused: bool = true
## Node to focus when the menu opens, so controllers and keyboards can navigate it.
@export var initial_focus: Control


func _enter_tree() -> void:
	# _ready is too late for scenes that start hidden
	visibility_changed.connect(_on_visibility_changed)
	if works_while_paused:
		process_mode = Node.PROCESS_MODE_ALWAYS


func open() -> void:
	show()


func close() -> void:
	hide()


func _on_visibility_changed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else gameplay_mouse_mode
	if visible and initial_focus != null:
		initial_focus.grab_focus.call_deferred()
