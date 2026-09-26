class_name WaveSpawner
extends Node2D
## Plays the scripted waves from ArenaData in order, then random waves that grow with the wave number.
## Spawned enemies become children of this node. Call setup() before next_wave().

signal wave_started(wave_data: WaveData, number: int)

var enemies: Array[Enemy] = []

var _data: ArenaData
var _bounds: Rect2
var _target: Player
var _wave: int = 0


func setup(data: ArenaData, bounds: Rect2, target: Player) -> void:
	_data = data
	_bounds = bounds
	_target = target


func next_wave() -> void:
	_wave += 1
	for scene: PackedScene in _wave_scenes():
		_spawn(scene)
	wave_started.emit(_current_wave_data(), _wave)


## The scripted waves in order, then random picks that grow with the wave number.
func _wave_scenes() -> Array[PackedScene]:
	var wave_data: WaveData = _current_wave_data()
	if wave_data:
		return wave_data.enemies

	var scenes: Array[PackedScene] = []
	for i: int in mini(_wave - 1, _data.max_random_enemies):
		scenes.append(_data.random_enemies.pick_random())
	return scenes


func _current_wave_data() -> WaveData:
	return _data.waves[_wave - 1] if _wave <= _data.waves.size() else null


## Spawns every enemy in the scene around one random point, keeping a group's layout.
func _spawn(scene: PackedScene) -> void:
	var spawn_point: Vector2 = _random_spawn_point()
	var group: Array[Enemy] = Enemy.take_from(scene.instantiate())
	for enemy: Enemy in group:
		enemy.position = (spawn_point + enemy.position).clamp(_bounds.position, _bounds.end)
		enemy.target = _target
		add_child(enemy)
		enemies.append(enemy)

	for enemy: Enemy in group:
		if is_instance_valid(enemy.type):
			enemy.type.on_spawned(group)


func _random_spawn_point() -> Vector2:
	var area: Rect2 = _bounds.grow(-_data.spawn_margin)
	var point := Vector2.ZERO
	for attempt: int in 20:
		point = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		if point.distance_to(_target.position) >= _data.spawn_min_distance:
			break
	return point
