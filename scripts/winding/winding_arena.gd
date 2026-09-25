extends Node2D
## Winding combat arena. Circle enemies with your thread to knot them. Builds the player, thread, HUD and waves from code.

const ARENA_MARGIN: float = 24.0
const SPAWN_MARGIN: float = 40.0
const SPAWN_MIN_DISTANCE: float = 260.0
## Seconds after a knot during which the next knot raises the combo.
const COMBO_WINDOW: float = 3.0
const MAX_RANDOM_ENEMIES: int = 6
## Winds per enemy type in random waves. 0 means a linked pair.
const RANDOM_TYPES: Array[int] = [2, -1, 1, -2, 0]

@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.25)

var _arena: Rect2
var _wave: int = 0
var _score: int = 0
var _combo: int = 0
var _combo_timer: float = 0.0
var _enemies: Array[KnotEnemy] = []
var _player: WindingPlayer
var _thread: ThreadTrail
var _hud: Label
var _game_over: GameOverScreen


func _ready() -> void:
	_arena = get_viewport_rect().grow(-ARENA_MARGIN)

	_thread = ThreadTrail.new()
	add_child(_thread)

	_player = WindingPlayer.new()
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
	for enemy: KnotEnemy in _enemies:
		# Draw each pair link once
		if enemy.has_partner() and enemy.get_instance_id() < enemy.partner.get_instance_id():
			draw_dashed_line(enemy.position, enemy.partner.position, Color(enemy.color, 0.5), 2.0, 8.0)


func _check_knots() -> void:
	var windings: Dictionary[KnotEnemy, float] = {}
	for enemy: KnotEnemy in _enemies:
		windings[enemy] = _thread.winding_around(enemy.position)

	var knotted: Array[KnotEnemy] = []
	for enemy: KnotEnemy in _enemies:
		var partner_winding: float = windings.get(enemy.partner, 0.0) if enemy.has_partner() else 0.0
		if enemy.evaluate(windings[enemy], partner_winding):
			knotted.append(enemy)

	if knotted.is_empty():
		return

	# Everything knotted by the same thread counts as one combo, then the thread is used up
	for enemy: KnotEnemy in knotted:
		_enemies.erase(enemy)
		enemy.knot()
		_combo += 1
		_score += 100 * _combo
	_combo_timer = COMBO_WINDOW
	_thread.clear()


func _hurt_player_on_contact() -> void:
	for enemy: KnotEnemy in _enemies:
		if enemy.position.distance_to(_player.position) < enemy.radius + _player.radius:
			_player.health.take_damage(1)
			return


func _next_wave() -> void:
	_wave += 1
	for winds: int in _wave_types(_wave):
		if winds == 0:
			_spawn_pair()
		else:
			_spawn_enemy(winds, _random_spawn_point())


## The first waves teach one enemy type each, later ones mix them randomly.
func _wave_types(wave: int) -> Array[int]:
	match wave:
		1:
			return [2]
		2:
			return [2, -1]
		3:
			return [0]

	var types: Array[int] = []
	for i: int in mini(wave - 1, MAX_RANDOM_ENEMIES):
		types.append(RANDOM_TYPES.pick_random())
	return types


func _spawn_enemy(winds: int, spawn_position: Vector2) -> KnotEnemy:
	var enemy := KnotEnemy.new()
	enemy.required_winds = winds
	enemy.position = spawn_position
	enemy.target = _player
	add_child(enemy)
	_enemies.append(enemy)
	return enemy


func _spawn_pair() -> void:
	var first_position: Vector2 = _random_spawn_point()
	var offset: Vector2 = Vector2.from_angle(randf() * TAU) * KnotEnemy.PAIR_DISTANCE
	var second_position: Vector2 = (first_position + offset).clamp(_arena.position, _arena.end)
	var first: KnotEnemy = _spawn_enemy(1, first_position)
	var second: KnotEnemy = _spawn_enemy(1, second_position)
	first.partner = second
	second.partner = first


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
	if _wave == 1:
		text += "\nMove with WASD, the arrow keys or a stick. Wind your thread around enemies: the rings show how many loops, the arrow which way."
	_hud.text = text


func _on_player_damaged(_amount: int) -> void:
	# A hit snaps the thread and breaks the combo
	_thread.clear()
	_combo = 0
