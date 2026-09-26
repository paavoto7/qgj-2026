@tool
class_name Arena
extends Node2D
## Combat arena. Circle enemies with your thread to knot them. Builds the thread and HUD from code,
## spawns the exported player scene, and plays the exported waves, then random waves once they run out.
## A tool script so the border is drawn in the editor. Gameplay code is skipped there.

signal setup_hud(bounds: Vector2, player_health: int)
signal wave_changed(wave_data: WaveData, wave_number: int)
signal score_changed(score: int)

@export var arena_data: ArenaData

var _arena: Rect2
var _wave: int = 0
var _score: int = 0
var _combo: int = 0
var _combo_timer: float = 0.0
var _enemies: Array[Enemy] = []
var _player: Player


func _ready() -> void:
	if Engine.is_editor_hint():
		var window_size := Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		)
		_arena = Rect2(Vector2.ZERO, window_size).grow(-arena_data.ARENA_MARGIN)
		set_physics_process(false)
		return

	if not arena_data:
		push_error("Arena needs an Arena Data resource.")
		set_physics_process(false)
		return

	if not arena_data.player_scene or arena_data.random_enemies.is_empty():
		push_error("Arena needs a Player Scene and at least one scene in Random Enemies.")
		set_physics_process(false)
		return

	_arena = get_viewport_rect().grow(-arena_data.ARENA_MARGIN)

	_player = arena_data.player_scene.instantiate()
	_player.arena = _arena
	_player.position = _arena.get_center()
	add_child(_player)
	_player.health.damaged.connect(_on_player_damaged)
	_player.health.died.connect(_on_player_died)

	setup_hud.emit(
		Vector2(arena_data.ARENA_MARGIN + 12.0, arena_data.ARENA_MARGIN + 8.0), _player.health.max_health)

	_next_wave()


func _physics_process(delta: float) -> void:
	_check_knots()

	_combo_timer -= delta
	if _combo_timer <= 0.0:
		_combo = 0

	if _enemies.is_empty():
		_next_wave()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(_arena, arena_data.border_color, false, 2.0)


func _check_knots() -> void:
	var windings: Dictionary[Enemy, float] = {}
	for enemy: Enemy in _enemies:
		windings[enemy] = _player._thread.winding_around(enemy.position)

	var knotted: Array[Enemy] = []
	for enemy: Enemy in _enemies:
		if enemy.evaluate(windings):
			knotted.append(enemy)

	if knotted.is_empty():
		return

	# Everything knotted by the same thread counts as one combo, then the thread is used up
	for enemy: Enemy in knotted:
		_enemies.erase(enemy)
		enemy.knot()
		_combo += 1
		_score += 100 * _combo
		score_changed.emit(_score)
	_combo_timer = arena_data.COMBO_WINDOW
	_player._thread.clear()


func _next_wave() -> void:
	_wave += 1
	for scene: PackedScene in _wave_scenes():
		_spawn(scene)
	wave_changed.emit(_current_wave_data(), _wave)


## The scripted waves in order, then random picks that grow with the wave number.
func _wave_scenes() -> Array[PackedScene]:
	var wave_data: WaveData = _current_wave_data()
	if wave_data:
		return wave_data.enemies

	var scenes: Array[PackedScene] = []
	for i: int in mini(_wave - 1, arena_data.max_random_enemies):
		scenes.append(arena_data.random_enemies.pick_random())
	return scenes


func _current_wave_data() -> WaveData:
	return arena_data.waves[_wave - 1] if _wave <= arena_data.waves.size() else null


## Spawns every enemy in the scene around one random point, keeping a group's layout.
func _spawn(scene: PackedScene) -> void:
	var spawn_point: Vector2 = _random_spawn_point()
	var group: Array[Enemy] = Enemy.take_from(scene.instantiate())
	for enemy: Enemy in group:
		enemy.position = (spawn_point + enemy.position).clamp(_arena.position, _arena.end)
		enemy.target = _player
		add_child(enemy)
		_enemies.append(enemy)

	for enemy: Enemy in group:
		if is_instance_valid(enemy.type):
			enemy.type.on_spawned(group)


func _random_spawn_point() -> Vector2:
	var area: Rect2 = _arena.grow(-arena_data.SPAWN_MARGIN)
	var point := Vector2.ZERO
	for attempt: int in 20:
		point = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		if point.distance_to(_player.position) >= arena_data.SPAWN_MIN_DISTANCE:
			break
	return point


func _on_player_damaged(_amount: int) -> void:
	_combo = 0


func _on_player_died() -> void:
	get_tree().paused = true
	_combo = 0
