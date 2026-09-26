@tool
class_name Arena
extends Node2D
## Combat arena. Circle enemies with your thread to knot them. Spawns the player from its ArenaData,
## wires up the WaveSpawner, ScoreKeeper and HUD children, and knots enemies the player's thread winds around.
## A tool script so the border is drawn in the editor. Gameplay code is skipped there.

## Margin used in the editor when no Arena Data is assigned.
const DEFAULT_MARGIN: float = 24.0

@export var arena_data: ArenaData:
	set(value):
		arena_data = value
		queue_redraw()

var _arena: Rect2
var _player: Player

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

	if not arena_data.player_scene or arena_data.random_enemies.is_empty():
		push_error("Arena needs a Player Scene and at least one scene in Random Enemies.")
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
	_spawner.next_wave()


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
		windings[enemy] = _player.thread.winding_around(enemy.position)

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


func _on_player_damaged(_amount: int) -> void:
	# The player snaps its thread on a hit, which also breaks the combo
	_score_keeper.break_combo()


func _on_player_died() -> void:
	MainManager.pause_game()
