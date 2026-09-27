@tool
class_name MenuBackground
extends MenuBase
## Animated background drawn behind [MainMenu].
## Uses the same visual language as the game: a small yellow player,
## fading golden thread, enemy circles, winding indicators and the arena border.

const ARENA_MARGIN: float = 24.0
const PLAYER_RADIUS: float = 10.0
const THREAD_COLOR := Color(1.431, 1.221, 0.586)

var _visual: MenuVisual

func _ready() -> void:
	_visual = MenuVisual.new()
	add_child(_visual)


## Draws and simulates the arena: the player wanders, avoids enemies and
## winds its thread around them, which knots them and respawns them elsewhere.
class MenuVisual extends Node2D:
	enum State { ALIVE, KNOTTING, DEAD, FADING_IN }

	const PLAYER_SPEED: float = 340.0
	const PLAYER_TURN_SPEED: float = 3.2
	const PLAYER_WALL_MARGIN: float = 110.0
	const PLAYER_WALL_GAP: float = 4.0
	const PLAYER_ENEMY_MARGIN: float = 115.0
	const PLAYER_SAFE_GAP: float = 8.0
	const PLAYER_START_OFFSET := Vector2(-180.0, 90.0)

	const ENEMY_BASE_RADIUS: float = 55.0
	const ENEMY_SPEED: float = 40.0
	const ENEMY_WANDER_STRENGTH: float = 18.0
	const ENEMY_PLAYER_AVOID_GAP: float = 45.0
	const ENEMY_PLAYER_AVOID_STRENGTH: float = 100.0
	const ENEMY_WALL_MARGIN: float = 100.0
	const ENEMY_WALL_STRENGTH: float = 100.0
	const ENEMY_SEPARATION: float = 20.0
	# The fast enemy reacts earlier and more strongly to the walls.
	# It is still completely free-moving; there is no hard boundary.
	const FAST_ENEMY_WALL_MARGIN: float = 350.0
	const FAST_ENEMY_WALL_STRENGTH: float = 260.0

	const PAIR_SPEED: float = 35.0
	const PAIR_GAP: float = 30.0
	const PAIR_WANDER_STRENGTH: float = 14.0
	const PAIR_WALL_MARGIN: float = 120.0
	const PAIR_WALL_STRENGTH: float = 90.0
	const PAIR_ARENA_GAP: float = 10.0
	const PAIR_SPIN_SPEED: float = 0.45

	const SPAWN_GRID_MARGIN: float = 70.0
	const SPAWN_GRID_SIZE: int = 3
	const SPAWN_JITTER: float = 60.0

	const RESPAWN_MARGIN: float = 90.0
	const RESPAWN_ATTEMPTS: int = 40
	const RESPAWN_PLAYER_DISTANCE: float = 320.0
	const RESPAWN_ENEMY_DISTANCE: float = 100.0

	const WIND_TOLERANCE: float = 0.15
	const KNOT_TIME: float = 0.3
	const RESPAWN_DELAY: float = 0.35
	const FADE_TIME: float = 0.8

	const RING_OFFSET: float = 6.0
	const RING_SPACING: float = 5.0
	const ARENA_BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.18)
	const ARENA_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.025)
	const GREEN := Color(0.6, 1.0, 0.5)

	var _thread: ThreadTrail
	var _time: float = 0.0
	var _arena := Rect2()

	var _player_position := Vector2.ZERO
	var _player_velocity := Vector2.RIGHT * PLAYER_SPEED

	var _enemies: Array[MenuEnemy] = []
	## Enemies that move on their own, i.e. everything except the green pair.
	var _solo_enemies: Array[MenuEnemy] = []
	var _enemies_placed: bool = false

	# The green pair shares one movement center and moves as a unit.
	var _green_a: MenuEnemy
	var _green_b: MenuEnemy
	var _pair_center := Vector2.ZERO
	var _pair_velocity := Vector2.RIGHT * PAIR_SPEED
	var _pair_phase: float = 0.0


	func _ready() -> void:
		top_level = true
		global_transform = Transform2D.IDENTITY

		_create_enemies()

		_thread = ThreadTrail.new()
		add_child(_thread)

		queue_redraw()


	func _process(delta: float) -> void:
		_time += delta

		var viewport_size := get_viewport_rect().size
		_arena = Rect2(
			Vector2(ARENA_MARGIN, ARENA_MARGIN),
			viewport_size - Vector2(ARENA_MARGIN * 2.0, ARENA_MARGIN * 2.0)
		)

		if _player_position == Vector2.ZERO:
			_player_position = _arena.get_center() + PLAYER_START_OFFSET

		# Placement needs the arena size, so it happens on the first frame.
		if not _enemies_placed:
			_place_enemies()

		_update_player(delta)
		_update_solo_enemies(delta)
		_separate_solo_enemies()
		_update_green_pair(delta)
		_update_enemy_states(delta)

		queue_redraw()


	func _draw() -> void:
		draw_rect(_arena, ARENA_BORDER_COLOR, false, 2.0)

		# Subtle arena cross-lines.
		var center := _arena.get_center()
		draw_line(Vector2(_arena.position.x, center.y), Vector2(_arena.end.x, center.y), ARENA_LINE_COLOR, 1.0)
		draw_line(Vector2(center.x, _arena.position.y), Vector2(center.x, _arena.end.y), ARENA_LINE_COLOR, 1.0)

		_draw_green_connection()

		for enemy in _enemies:
			_draw_enemy(enemy)

		# Player has no winding rings or arrow.
		draw_circle(_player_position, PLAYER_RADIUS, THREAD_COLOR)


	# --- Setup ---

	func _create_enemies() -> void:
		var third := ENEMY_BASE_RADIUS / 3.0

		var yellow := MenuEnemy.new(THREAD_COLOR, third, 1, 1.0)
		yellow.rerolls_direction = true

		var black := MenuEnemy.new(Color.BLACK, ENEMY_BASE_RADIUS / 6.0, 1, 1.0, 120.0)
		black.is_fast = true

		_solo_enemies = [
			MenuEnemy.new(Color(0.9, 0.15, 0.15), third, 2, 1.0),
			MenuEnemy.new(Color(0.2, 0.4, 1.0), third, 1, -1.0),
			MenuEnemy.new(Color(0.65, 0.2, 0.85), third, 1, 1.0),
			MenuEnemy.new(Color(1.0, 0.55, 0.1), third, 1, 1.0),
			yellow,
			black,
			MenuEnemy.new(Color.WHITE, ENEMY_BASE_RADIUS / 1.5, 4, -1.0),
		]

		_green_a = MenuEnemy.new(GREEN, third, 1, 1.0)
		_green_b = MenuEnemy.new(GREEN, third, 1, 1.0)
		_pair_phase = randf_range(0.0, TAU)

		_enemies.assign(_solo_enemies + [_green_a, _green_b])


	## Spreads the enemies over a grid with some jitter.
	func _place_enemies() -> void:
		var cell_size := (_arena.size - Vector2.ONE * SPAWN_GRID_MARGIN * 2.0) / float(SPAWN_GRID_SIZE)

		for i in _enemies.size():
			var enemy := _enemies[i]
			var cell := Vector2(i % SPAWN_GRID_SIZE, floori(i / float(SPAWN_GRID_SIZE)))

			enemy.position = _arena.position + Vector2.ONE * SPAWN_GRID_MARGIN + cell_size * (cell + Vector2(0.5, 0.5))
			enemy.position += Vector2(
				randf_range(-SPAWN_JITTER, SPAWN_JITTER),
				randf_range(-SPAWN_JITTER, SPAWN_JITTER)
			)
			enemy.velocity = _random_direction() * enemy.speed

		_pair_center = _green_a.position
		_pair_velocity = _random_direction() * PAIR_SPEED
		_enemies_placed = true


	# --- Player ---

	func _update_player(delta: float) -> void:
		var desired := Vector2(cos(_time * 0.63), sin(_time * 0.91))
		if desired.length() < 0.001:
			desired = Vector2.RIGHT

		# Keep the player away from enemies without making it orbit them.
		var avoidance := Vector2.ZERO
		for enemy in _enemies:
			if enemy.state != State.ALIVE:
				continue

			var offset := _player_position - enemy.position
			var distance := offset.length()
			var safe_distance := enemy.radius + PLAYER_RADIUS + PLAYER_ENEMY_MARGIN

			if distance < safe_distance and distance > 0.001:
				var strength := 1.0 - distance / safe_distance
				avoidance += offset.normalized() * strength * strength

		if avoidance.length() > 0.001:
			desired = (desired * 0.7 + avoidance.normalized() * 1.1).normalized()

		var wall_force := _wall_force(_player_position, PLAYER_WALL_MARGIN)
		if wall_force.length() > 0.001:
			desired = (desired * 0.65 + wall_force.normalized() * 0.9).normalized()

		var current_direction := _player_velocity.normalized()
		if current_direction.length() < 0.001:
			current_direction = desired

		current_direction = current_direction.slerp(
			desired,
			clampf(PLAYER_TURN_SPEED * delta, 0.0, 1.0)
		).normalized()
		_player_velocity = current_direction * PLAYER_SPEED

		_player_position = _push_out_of_enemies(_player_position + _player_velocity * delta)

		var inset := PLAYER_RADIUS + PLAYER_WALL_GAP
		_player_position = _player_position.clamp(
			_arena.position + Vector2.ONE * inset,
			_arena.end - Vector2.ONE * inset
		)

		_thread.add_point(_player_position)


	## Hard collision: moves [param proposed] out of every live enemy and
	## removes the player's velocity towards them.
	func _push_out_of_enemies(proposed: Vector2) -> Vector2:
		for enemy in _enemies:
			if enemy.state != State.ALIVE:
				continue

			var minimum_distance := PLAYER_RADIUS + enemy.radius + PLAYER_SAFE_GAP
			var offset := proposed - enemy.position
			var distance := offset.length()

			if distance >= minimum_distance:
				continue

			var normal := offset / distance if distance > 0.001 else Vector2.RIGHT
			proposed = enemy.position + normal * minimum_distance

			var inward := _player_velocity.dot(normal)
			if inward < 0.0:
				_player_velocity -= normal * inward

		return proposed


	# --- Enemy movement ---

	func _update_solo_enemies(delta: float) -> void:
		for enemy in _solo_enemies:
			if enemy.state != State.ALIVE:
				continue

			var velocity := enemy.velocity

			# Slow organic steering instead of a fixed path.
			var wander := Vector2(
				sin(_time * enemy.wander_frequency.x + enemy.wander_phase.x),
				cos(_time * enemy.wander_frequency.y + enemy.wander_phase.y)
			)
			velocity += wander * ENEMY_WANDER_STRENGTH * delta

			# Steer away from the player before getting too close.
			var player_offset := enemy.position - _player_position
			var player_distance := player_offset.length()
			var player_safe_distance := enemy.radius + PLAYER_RADIUS + ENEMY_PLAYER_AVOID_GAP

			if player_distance < player_safe_distance and player_distance > 0.001:
				var strength := 1.0 - player_distance / player_safe_distance
				velocity += player_offset.normalized() * strength * ENEMY_PLAYER_AVOID_STRENGTH * delta

			var wall_margin := FAST_ENEMY_WALL_MARGIN if enemy.is_fast else ENEMY_WALL_MARGIN
			var wall_strength := FAST_ENEMY_WALL_STRENGTH if enemy.is_fast else ENEMY_WALL_STRENGTH
			velocity += _wall_force(enemy.position, wall_margin) * wall_strength * delta

			if velocity.length() < 0.001:
				velocity = Vector2.RIGHT * enemy.speed

			enemy.velocity = velocity.normalized() * enemy.speed
			enemy.position += enemy.velocity * delta


	## Pushes overlapping live enemies apart, half the overlap each.
	func _separate_solo_enemies() -> void:
		for i in _solo_enemies.size():
			var first := _solo_enemies[i]
			if first.state != State.ALIVE:
				continue

			for j in range(i + 1, _solo_enemies.size()):
				var second := _solo_enemies[j]
				if second.state != State.ALIVE:
					continue

				var offset := second.position - first.position
				var distance := offset.length()
				var minimum_distance := first.radius + second.radius + ENEMY_SEPARATION

				if distance >= minimum_distance:
					continue

				var direction := offset / distance if distance > 0.001 else Vector2.RIGHT
				var push := (minimum_distance - distance) * 0.5

				first.position -= direction * push
				second.position += direction * push


	func _update_green_pair(delta: float) -> void:
		if _green_a.state != State.ALIVE:
			return

		var wander := Vector2(
			sin(_time * 0.31 + _pair_phase),
			cos(_time * 0.37 + _pair_phase)
		)
		_pair_velocity += wander * PAIR_WANDER_STRENGTH * delta

		# Constant push back from the walls, no falloff.
		var wall_force := Vector2.ZERO
		if _pair_center.x < _arena.position.x + PAIR_WALL_MARGIN:
			wall_force.x += 1.0
		if _pair_center.x > _arena.end.x - PAIR_WALL_MARGIN:
			wall_force.x -= 1.0
		if _pair_center.y < _arena.position.y + PAIR_WALL_MARGIN:
			wall_force.y += 1.0
		if _pair_center.y > _arena.end.y - PAIR_WALL_MARGIN:
			wall_force.y -= 1.0
		_pair_velocity += wall_force * PAIR_WALL_STRENGTH * delta

		if _pair_velocity.length() < 0.001:
			_pair_velocity = Vector2.RIGHT * PAIR_SPEED

		_pair_velocity = _pair_velocity.normalized() * PAIR_SPEED
		_pair_center = _clamp_pair_center(_pair_center + _pair_velocity * delta)

		_place_green_pair(Vector2.from_angle(_time * PAIR_SPIN_SPEED))


	# --- Winding, knotting and respawning ---

	func _update_enemy_states(delta: float) -> void:
		for enemy in _enemies:
			match enemy.state:
				State.ALIVE:
					if _is_green(enemy):
						continue
					_update_enemy_winding(enemy)

				State.KNOTTING:
					enemy.knot_progress += delta / KNOT_TIME
					enemy.knot_rotation += enemy.direction * TAU * delta / KNOT_TIME

					if enemy.knot_progress >= 1.0:
						enemy.knot_progress = 1.0
						enemy.state = State.DEAD
						enemy.respawn_timer = RESPAWN_DELAY

				State.DEAD:
					enemy.respawn_timer -= delta
					if enemy.respawn_timer <= 0.0:
						_respawn_enemy(enemy)

				State.FADING_IN:
					enemy.fade_alpha += delta / FADE_TIME
					if enemy.fade_alpha >= 1.0:
						enemy.fade_alpha = 1.0
						enemy.state = State.ALIVE

		_update_green_winding()


	func _update_enemy_winding(enemy: MenuEnemy) -> void:
		var current_position: Vector2 = enemy.position

		if not enemy.winding_initialized:
			enemy.previous_player_position = _player_position
			enemy.previous_position = current_position
			enemy.winding_initialized = true
			return

		var previous_relative: Vector2 = enemy.previous_player_position - enemy.previous_position
		var current_relative: Vector2 = _player_position - current_position

		if previous_relative.length_squared() > 0.001 and current_relative.length_squared() > 0.001:
			enemy.winding_total += angle_difference(
				previous_relative.angle(),
				current_relative.angle()
			) / TAU

		enemy.previous_player_position = _player_position
		enemy.previous_position = current_position

		var along: float = enemy.winding_total * enemy.direction

		if along < 0.0:
			enemy.progress = 0.0
			return

		var completed_in_thread := floori(along + WIND_TOLERANCE)
		var newly_completed := completed_in_thread - enemy.thread_completed_winds

		if newly_completed > 0:
			enemy.completed_winds += newly_completed
			enemy.thread_completed_winds = completed_in_thread

		enemy.progress = along - completed_in_thread

		if enemy.completed_winds >= enemy.winds:
			_kill_enemy(enemy)


	func _update_green_winding() -> void:
		if _green_a.state != State.ALIVE or _green_b.state != State.ALIVE:
			return

		_update_enemy_winding(_green_a)
		_update_enemy_winding(_green_b)

		var along_a: float = _green_a.winding_total * _green_a.direction
		var along_b: float = _green_b.winding_total * _green_b.direction

		var along: float = minf(along_a, along_b)

		if along < 0.0:
			_green_a.progress = 0.0
			_green_b.progress = 0.0
			return

		var completed_in_thread := floori(along + WIND_TOLERANCE)

		_green_a.progress = along - completed_in_thread
		_green_b.progress = along - completed_in_thread

		if completed_in_thread > _green_a.thread_completed_winds:
			_green_a.completed_winds += completed_in_thread - _green_a.thread_completed_winds
			_green_b.completed_winds += completed_in_thread - _green_b.thread_completed_winds
			_green_a.thread_completed_winds = completed_in_thread
			_green_b.thread_completed_winds = completed_in_thread

		if _green_a.completed_winds >= _green_a.winds:
			_kill_enemy(_green_a)


	func _kill_enemy(enemy: MenuEnemy) -> void:
		if enemy.state != State.ALIVE:
			return

		# Green is a linked pair.
		if _is_green(enemy):
			_start_knot(_green_a)
			_start_knot(_green_b)
		else:
			_start_knot(enemy)


	func _start_knot(enemy: MenuEnemy) -> void:
		enemy.state = State.KNOTTING
		enemy.knot_progress = 0.0
		enemy.knot_rotation = 0.0
		enemy.reset_winding()


	func _respawn_enemy(enemy: MenuEnemy) -> void:
		enemy.position = _find_respawn_position(enemy)
		enemy.state = State.FADING_IN
		enemy.fade_alpha = 0.0
		enemy.knot_progress = 0.0
		enemy.knot_rotation = 0.0
		enemy.reset_winding()

		enemy.velocity = _random_direction() * enemy.speed
		enemy.wander_phase = Vector2(randf_range(0.0, TAU), randf_range(0.0, TAU))

		if enemy.rerolls_direction:
			enemy.direction = 1.0 if randf() < 0.5 else -1.0

		if _is_green(enemy):
			_respawn_green_pair(enemy)


	## Respawns both green enemies together, already next to each other.
	func _respawn_green_pair(respawned: MenuEnemy) -> void:
		_pair_center = _clamp_pair_center(_find_respawn_position(respawned))

		var pair_direction := _random_direction()
		_place_green_pair(pair_direction)
		_pair_velocity = pair_direction * PAIR_SPEED

		for green: MenuEnemy in [_green_a, _green_b]:
			green.state = State.FADING_IN
			green.fade_alpha = 0.0
			green.reset_winding()


	## Picks a random spot away from the player and the other live enemies,
	## or the arena center if none is found.
	func _find_respawn_position(enemy: MenuEnemy) -> Vector2:
		for _attempt in RESPAWN_ATTEMPTS:
			var candidate := Vector2(
				randf_range(_arena.position.x + RESPAWN_MARGIN, _arena.end.x - RESPAWN_MARGIN),
				randf_range(_arena.position.y + RESPAWN_MARGIN, _arena.end.y - RESPAWN_MARGIN)
			)

			if candidate.distance_to(_player_position) < RESPAWN_PLAYER_DISTANCE:
				continue

			var valid := true
			for other in _enemies:
				if other == enemy or other.state != State.ALIVE:
					continue

				if candidate.distance_to(other.position) < RESPAWN_ENEMY_DISTANCE:
					valid = false
					break

			if valid:
				return candidate

		return _arena.get_center()


	# --- Drawing ---

	func _draw_green_connection() -> void:
		if _green_a.state == State.DEAD or _green_b.state == State.DEAD:
			return

		var offset := _green_b.position - _green_a.position
		if offset.length() < 0.001:
			return

		var heading := offset.normalized()
		var start := _green_a.position + heading * _green_a.radius
		var end := _green_b.position - heading * _green_b.radius
		var alpha := minf(_green_a.fade_alpha, _green_b.fade_alpha)

		draw_dashed_line(start, end, Color(GREEN, 0.5 * alpha), 2.0, 8.0)


	func _draw_enemy(enemy: MenuEnemy) -> void:
		match enemy.state:
			State.DEAD:
				return

			State.KNOTTING:
				_draw_knotting_enemy(enemy)

			_:
				var alpha := enemy.fade_alpha
				draw_circle(enemy.position, enemy.radius, Color(enemy.color.darkened(0.6), alpha))
				draw_arc(enemy.position, enemy.radius, 0.0, TAU, 32, Color(enemy.color, alpha), 2.0)
				_draw_winding_indicator(enemy, alpha)


	## Rings for the winds still needed, filled by the current progress,
	## with an arrow on top showing the winding direction.
	func _draw_winding_indicator(enemy: MenuEnemy, alpha: float) -> void:
		var remaining := maxi(enemy.winds - enemy.completed_winds, 0)
		if remaining <= 0:
			return

		for i in remaining:
			var ring_radius := enemy.radius + RING_OFFSET + i * RING_SPACING
			draw_arc(enemy.position, ring_radius, 0.0, TAU, 32, Color(enemy.color, 0.25 * alpha), 2.0)

			var fill := clampf(enemy.progress - i, 0.0, 1.0)
			if fill > 0.0:
				draw_arc(
					enemy.position,
					ring_radius,
					-PI / 2.0,
					-PI / 2.0 + enemy.direction * fill * TAU,
					48,
					Color(enemy.color, alpha),
					3.0
				)

		var tip := enemy.position + Vector2(0.0, -(enemy.radius + RING_OFFSET + remaining * RING_SPACING + 3.0))
		var direction := enemy.direction
		draw_colored_polygon(
			PackedVector2Array([
				tip + Vector2(direction * 7.0, 0.0),
				tip + Vector2(-direction * 3.0, -5.0),
				tip + Vector2(-direction * 3.0, 5.0),
			]),
			Color(enemy.color, alpha)
		)


	## Matches the game's shrink-and-spin feel.
	func _draw_knotting_enemy(enemy: MenuEnemy) -> void:
		var t := clampf(enemy.knot_progress, 0.0, 1.0)
		var animated_radius := enemy.radius * (1.0 - t)
		if animated_radius <= 0.1:
			return

		var alpha := 1.0 - t
		var body_color := Color(enemy.color, alpha)
		var rotation_angle := enemy.knot_rotation

		draw_circle(enemy.position, animated_radius, Color(enemy.color.darkened(0.6), alpha))

		# Rotating knot-like rings.
		for ring in 3:
			var ring_fraction := float(ring) / 3.0
			var ring_radius := animated_radius * (0.45 + ring_fraction * 0.45)
			var start_angle := rotation_angle + ring_fraction * TAU / 3.0

			draw_arc(
				enemy.position,
				ring_radius,
				start_angle,
				start_angle + TAU * (0.72 + t * 0.2),
				24,
				body_color,
				2.5
			)

		draw_arc(enemy.position, animated_radius, rotation_angle, rotation_angle + TAU, 32, body_color, 2.0)


	# --- Helpers ---

	func _is_green(enemy: MenuEnemy) -> bool:
		return enemy == _green_a or enemy == _green_b


	func _pair_half_spacing() -> float:
		return (_green_a.radius + _green_b.radius + PAIR_GAP) * 0.5


	## Keeps both green enemies inside the arena around [param center].
	func _clamp_pair_center(center: Vector2) -> Vector2:
		var inset := _pair_half_spacing() + PAIR_ARENA_GAP
		return center.clamp(_arena.position + Vector2.ONE * inset, _arena.end - Vector2.ONE * inset)


	## Puts the green enemies on both sides of [member _pair_center] along [param direction].
	func _place_green_pair(direction: Vector2) -> void:
		var half_spacing := _pair_half_spacing()
		_green_a.position = _pair_center - direction * half_spacing
		_green_b.position = _pair_center + direction * half_spacing


	## Steering away from the arena walls, growing quadratically within [param margin].
	func _wall_force(point: Vector2, margin: float) -> Vector2:
		var force := Vector2.ZERO
		force.x += _wall_push(point.x - _arena.position.x, margin)
		force.x -= _wall_push(_arena.end.x - point.x, margin)
		force.y += _wall_push(point.y - _arena.position.y, margin)
		force.y -= _wall_push(_arena.end.y - point.y, margin)
		return force


	func _wall_push(distance: float, margin: float) -> float:
		if distance >= margin:
			return 0.0

		var strength := 1.0 - distance / margin
		return strength * strength


	func _random_direction() -> Vector2:
		var direction := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		return direction if direction.length() >= 0.001 else Vector2.RIGHT


	## One enemy circle in the menu arena.
	class MenuEnemy:
		var color: Color
		var radius: float
		## Winds needed to knot this enemy.
		var winds: int
		## 1.0 or -1.0, the winding direction this enemy needs.
		var direction: float
		var speed: float
		## Reacts to walls earlier and more strongly.
		var is_fast: bool = false
		## Picks a new winding direction on every respawn.
		var rerolls_direction: bool = false

		var state: State = State.ALIVE
		var position := Vector2.ZERO
		var velocity := Vector2.ZERO
		var wander_phase: Vector2
		var wander_frequency: Vector2

		var completed_winds: int = 0
		var thread_completed_winds: int = 0
		## Fraction of the current wind, shown on the indicator ring.
		var progress: float = 0.0

		# Winding state.
		var winding_total: float = 0.0
		var previous_position: Vector2 = Vector2.ZERO
		var previous_player_position: Vector2 = Vector2.ZERO
		var winding_initialized: bool = false

		var knot_progress: float = 0.0
		var knot_rotation: float = 0.0
		var fade_alpha: float = 1.0
		var respawn_timer: float = 0.0


		func _init(
			p_color: Color,
			p_radius: float,
			p_winds: int,
			p_direction: float,
			p_speed: float = ENEMY_SPEED
		) -> void:
			color = p_color
			radius = p_radius
			winds = p_winds
			direction = p_direction
			speed = p_speed
			wander_phase = Vector2(randf_range(0.0, TAU), randf_range(0.0, TAU))
			wander_frequency = Vector2(randf_range(0.25, 0.42), randf_range(0.28, 0.46))


		func reset_winding() -> void:
			completed_winds = 0
			thread_completed_winds = 0
			progress = 0.0
			winding_total = 0.0
			previous_position = position
			previous_player_position = Vector2.ZERO
			winding_initialized = false
