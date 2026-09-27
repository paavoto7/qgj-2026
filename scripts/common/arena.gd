@tool
class_name Arena
extends Node2D
## Combat arena. Circle enemies with your thread to knot them. Spawns the player from its ArenaData,
## wires up the WaveSpawner, ScoreKeeper and HUD children, and knots enemies the player's thread winds around.
## A tool script so the border is drawn in the editor. Gameplay code is skipped there.
## Test keys, only when the game is run from the editor: Tab starts the next wave, 1-9 go to that wave and 0 to wave 10.

## Margin used in the editor when no Arena Data is assigned.
const DEFAULT_MARGIN: float = 24.0
const DEBUG_NEXT_WAVE: StringName = &"debug_next_wave"
const DEBUG_WAVE_PREFIX: String = "debug_wave_"
const DEBUG_WAVE_KEYS: int = 10

@export var arena_data: ArenaData:
	set(value):
		arena_data = value
		queue_redraw()

var _arena: Rect2
var _player: Player
var _debug_keys: bool = false
## Runs that used the test keys aren't recorded.
var _used_debug_keys: bool = false

@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _score_keeper: ScoreKeeper = $ScoreKeeper
@onready var _hud: HUD = $HUD


func _ready() -> void:
	if Engine.is_editor_hint():
		var window_size := Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		)
		var margin: float = arena_data.arena_margin if arena_data else DEFAULT_MARGIN
		_arena = Rect2(Vector2.ZERO, window_size).grow(-margin)
		set_physics_process(false)
		queue_redraw()
		return

	if not arena_data:
		push_error("Arena needs an Arena Data resource.")
		set_physics_process(false)
		return

	if not arena_data.player_scene or arena_data.random_spawns.is_empty():
		push_error("Arena needs a Player Scene and at least one entry in Random Spawns.")
		set_physics_process(false)
		return

	_arena = get_viewport_rect().grow(-arena_data.arena_margin)
	# The border never changes, so it's drawn once
	queue_redraw()

	_player = arena_data.player_scene.instantiate()
	_player.arena = _arena
	_player.position = _arena.get_center()
	add_child(_player)
	_player.health.damaged.connect(_on_player_damaged)
	_player.health.died.connect(_on_player_died)

	var label_position := Vector2(arena_data.arena_margin + 12.0, arena_data.arena_margin + 8.0)
	_hud.setup(label_position, _player)

	_score_keeper.combo_window = arena_data.combo_window
	_score_keeper.score_changed.connect(_hud.show_score)
	_score_keeper.combo_changed.connect(_hud.show_combo)

	_spawner.setup(arena_data, _arena, _player)
	_spawner.wave_started.connect(_hud.show_wave)
	_spawner.item_dropped.connect(_on_item_dropped)
	_spawner.next_wave()

	_debug_keys = OS.has_feature("editor")
	if _debug_keys:
		_add_debug_actions()


func _unhandled_input(event: InputEvent) -> void:
	if not _debug_keys:
		return

	if event.is_action_pressed(DEBUG_NEXT_WAVE):
		_debug_go_to_wave(_spawner.wave + 1)
		return

	for number: int in range(1, DEBUG_WAVE_KEYS + 1):
		if event.is_action_pressed(DEBUG_WAVE_PREFIX + str(number)):
			_debug_go_to_wave(number)
			return


func _physics_process(_delta: float) -> void:
	_check_knots()

	if _spawner.enemies.is_empty():
		_spawner.next_wave()


func _draw() -> void:
	if not arena_data:
		return

	draw_rect(_arena, arena_data.border_color, false, 2.0)


func _check_knots() -> void:
	var enemies: Array[Enemy] = _spawner.enemies
	var windings: Dictionary[Enemy, float] = {}
	for enemy: Enemy in enemies:
		enemy.update_winding(_player.global_position)
		windings[enemy] = enemy.get_winding_total()

	var knotted: Array[Enemy] = []
	for enemy: Enemy in enemies:
		if enemy.evaluate(windings):
			knotted.append(enemy)

	if knotted.is_empty():
		return

	# Everything knotted by the same thread counts as one combo, then the thread is used up
	for enemy: Enemy in knotted:
		enemies.erase(enemy)
		enemy.knot()
	_score_keeper.add_knots(knotted.size())
	_player.thread.clear()


func _on_item_dropped(item: Node2D) -> void:
	item.position = item.position.clamp(_arena.position, _arena.end)
	add_child(item)


func _on_player_damaged(_amount: int) -> void:
	# The player snaps its thread on a hit, which also breaks the combo
	_score_keeper.break_combo()


func _on_player_died() -> void:
	# The wave the player died on wasn't cleared
	var waves_cleared: int = maxi(_spawner.wave - 1, 0)
	var score: int = _score_keeper.score
	var is_new_high_score: bool = false
	if not _used_debug_keys:
		is_new_high_score = MainManager.game_data.record_run(score, _score_keeper.knots, waves_cleared)
		MainManager.save_game_data()

	_hud.show_game_over(score, is_new_high_score)
	MainManager.pause_game()


## Registers the test keys as input actions, so they don't need to be in the project's Input Map.
func _add_debug_actions() -> void:
	_add_debug_action(DEBUG_NEXT_WAVE, KEY_TAB)
	for number: int in range(1, DEBUG_WAVE_KEYS + 1):
		# 1-9 on the number row, 0 for wave 10
		_add_debug_action(DEBUG_WAVE_PREFIX + str(number), (KEY_0 + number % 10) as Key)


func _add_debug_action(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return

	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.add_action(action)
	InputMap.action_add_event(action, event)


func _debug_go_to_wave(number: int) -> void:
	get_viewport().set_input_as_handled()
	_used_debug_keys = true
	_player.thread.clear()
	_spawner.go_to_wave(number)
