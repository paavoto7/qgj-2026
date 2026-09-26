@tool
extends Node2D
## Combat arena. Circle enemies with your thread to knot them. Builds the thread and HUD from code,
## spawns the exported player scene, and plays the exported waves, then random waves once they run out.
## A tool script so the border is drawn in the editor. Gameplay code is skipped there.

const ARENA_MARGIN: float = 24.0
const SPAWN_MARGIN: float = 40.0
const SPAWN_MIN_DISTANCE: float = 260.0
## Seconds after a knot during which the next knot raises the combo.
const COMBO_WINDOW: float = 3.0

@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var player_scene: PackedScene
## Scripted opening waves, played in order.
@export var waves: Array[WaveData] = []
## Enemy or group scenes that random waves pick from after the scripted waves.
@export var random_enemies: Array[PackedScene] = []
@export var max_random_enemies: int = 6

var _arena: Rect2
var _wave: int = 0
var _score: int = 0
var _combo: int = 0
var _combo_timer: float = 0.0
var _enemies: Array[Enemy] = []
var _player: Player
var _thread: ThreadTrail
var _hud: Label
var _game_over: GameOverScreen


func _ready() -> void:
	if Engine.is_editor_hint():
		var window_size := Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		)
		_arena = Rect2(Vector2.ZERO, window_size).grow(-ARENA_MARGIN)
		set_physics_process(false)
		return

	if not player_scene or random_enemies.is_empty():
		push_error("Arena needs a Player Scene and at least one scene in Random Enemies.")
		set_physics_process(false)
		return

	_arena = get_viewport_rect().grow(-ARENA_MARGIN)

	_thread = ThreadTrail.new()
	add_child(_thread)

	_player = player_scene.instantiate()
	_player.arena = _arena
	_player.position = _arena.get_center()
	add_child(_player)
	_player.health.damaged.connect(_on_player_damaged)

	var hud_layer := CanvasLayer.new()
	add_child(hud_layer)
	_hud = Label.new()
	_hud.position = Vector2(ARENA_MARGIN + 12.0, ARENA_MARGIN + 8.0)
	hud_layer.add_child(_hud)

	_game_over = GameOverScreen.new()
	_game_over.hide()
	add_child(_game_over)
	_player.health.died.connect(_game_over.open)

	_next_wave()


func _physics_process(delta: float) -> void:
	if _player.health.is_dead:
		_update_hud()
		return

	_thread.add_point(_player.position)
	_check_knots()
	_hurt_player_on_contact()

	_combo_timer -= delta
	if _combo_timer <= 0.0:
		_combo = 0

	if _enemies.is_empty():
		_next_wave()
	_update_hud()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(_arena, border_color, false, 2.0)


func _check_knots() -> void:
	var windings: Dictionary[Enemy, float] = {}
	for enemy: Enemy in _enemies:
		windings[enemy] = _thread.winding_around(enemy.position)

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
	_combo_timer = COMBO_WINDOW
	_thread.clear()


func _hurt_player_on_contact() -> void:
	for enemy: Enemy in _enemies:
		if enemy.position.distance_to(_player.position) < enemy.radius + _player.radius:
			_player.health.take_damage(1)
			return


func _next_wave() -> void:
	_wave += 1
	for scene: PackedScene in _wave_scenes():
		_spawn(scene)


## The scripted waves in order, then random picks that grow with the wave number.
func _wave_scenes() -> Array[PackedScene]:
	var wave_data: WaveData = _current_wave_data()
	if wave_data:
		return wave_data.enemies

	var scenes: Array[PackedScene] = []
	for i: int in mini(_wave - 1, max_random_enemies):
		scenes.append(random_enemies.pick_random())
	return scenes


func _current_wave_data() -> WaveData:
	return waves[_wave - 1] if _wave <= waves.size() else null


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
	var area: Rect2 = _arena.grow(-SPAWN_MARGIN)
	var point := Vector2.ZERO
	for attempt: int in 20:
		point = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		if point.distance_to(_player.position) >= SPAWN_MIN_DISTANCE:
			break
	return point


func _update_hud() -> void:
	var text: String = "Wave %d    Score %d    HP %d" % [_wave, _score, _player.health.current_health]
	if _combo > 1:
		text += "    x%d combo!" % _combo
	var wave_data: WaveData = _current_wave_data()
	if wave_data and not wave_data.hint.is_empty():
		text += "\n" + wave_data.hint
	_hud.text = text


func _on_player_damaged(_amount: int) -> void:
	# A hit snaps the thread and breaks the combo
	_thread.clear()
	_combo = 0
