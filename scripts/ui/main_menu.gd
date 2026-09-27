@tool
class_name MainMenu
extends MenuBase
## Main menu for Winding Combat: title, subtitle and buttons over a [MenuBackground].

const SUBTITLE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.65)
const HOVER_SCALE: Vector2 = Vector2(1.06, 1.06)
const HOVER_TIME: float = 0.12
const INTRO_TIME: float = 0.6
## How far the menu slides up while fading in.
const INTRO_OFFSET: float = 12.0
## Delay between the title, subtitle and each button fading in.
const INTRO_STAGGER: float = 0.12

@export var title: String = "WINDING COMBAT"
@export_multiline var subtitle: String = "Don't shoot. Wind your thread. Knot your enemies."
@export_file("*.tscn") var game_scene: String = "res://scenes/arena/arena.tscn"

@export var title_font_size: int = 64
@export var subtitle_font_size: int = 18
@export var stats_font_size: int = 16
@export var button_min_size: Vector2 = Vector2(240.0, 52.0)
@export var click_sound: AudioStream

var _background: MenuBackground
var _start_button: Button
var _hover_tweens: Dictionary[Button, Tween] = {}


func _ready() -> void:
	_background = MenuBackground.new()
	add_child(_background)
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not visible:
		return

	if event.is_action_pressed("ui_cancel") and _can_quit():
		get_viewport().set_input_as_handled()
		_on_quit_pressed()


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	var title_label := _add_label(column, title, title_font_size)
	var subtitle_label := _add_label(column, subtitle, subtitle_font_size)
	# A colour instead of modulate, so the intro can fade modulate
	subtitle_label.add_theme_color_override("font_color", SUBTITLE_COLOR)

	# Space between subtitle and buttons
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18.0
	column.add_child(spacer)

	_start_button = _add_button(column, "START", _on_start_pressed)
	var intro_items: Array[Control] = [title_label, subtitle_label, _start_button]
	if _can_quit():
		intro_items.append(_add_button(column, "QUIT", _on_quit_pressed))

	# Autoloads don't run in the editor preview
	if not Engine.is_editor_hint() and MainManager.game_data.runs_played > 0:
		var stats_label := _add_label(column, _stats_text(MainManager.game_data), stats_font_size)
		stats_label.add_theme_color_override("font_color", SUBTITLE_COLOR)
		intro_items.append(stats_label)

	initial_focus = _start_button
	# The script runs in the editor for the preview, where it shouldn't steal focus
	if not Engine.is_editor_hint():
		_start_button.grab_focus.call_deferred()
		_play_intro(center, intro_items)


func _add_label(parent: Control, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _stats_text(data: GameData) -> String:
	return "Best %d · %d knotted · %d runs · %d waves" % [
		data.high_score, data.enemies_knotted, data.runs_played, data.waves_cleared
	]


func _add_button(parent: Control, text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = button_min_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Scale from the center, whatever size the button ends up
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)

	# Stays big while the mouse is over it or it has focus
	button.mouse_entered.connect(_set_hovered.bind(button, true))
	button.mouse_exited.connect(func() -> void: _set_hovered(button, button.has_focus()))
	button.focus_entered.connect(_set_hovered.bind(button, true))
	button.focus_exited.connect(func() -> void: _set_hovered(button, button.is_hovered()))

	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button


func _set_hovered(button: Button, hovered: bool) -> void:
	# Stop the previous tween, or both fight over the scale
	var previous: Tween = _hover_tweens.get(button)
	if previous != null:
		previous.kill()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", HOVER_SCALE if hovered else Vector2.ONE, HOVER_TIME)
	_hover_tweens[button] = tween


## Slides the menu up and fades its items in one after another.
func _play_intro(container: Control, items: Array[Control]) -> void:
	var tween := create_tween()
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "position:y", 0.0, INTRO_TIME).from(INTRO_OFFSET)

	for i: int in items.size():
		items[i].modulate.a = 0.0
		tween.tween_property(items[i], "modulate:a", 1.0, INTRO_TIME).set_delay(i * INTRO_STAGGER)


## There's nothing to quit to on web.
func _can_quit() -> bool:
	return not OS.has_feature("web")


func _on_start_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.change_scene(game_scene)


func _on_quit_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.quit_game()
