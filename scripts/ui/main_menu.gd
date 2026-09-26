@tool
class_name MainMenu
extends MenuBase
## Main menu for Winding Combat.
## Uses the same visual language as the game: a small yellow player, fading golden thread,
## enemy circles and the arena border. Every now and then the player winds around an enemy.

const ARENA_MARGIN: float = 24.0
const PLAYER_RADIUS: float = 10.0
const THREAD_COLOR: Color = Color(1.0, 0.85, 0.4)
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
@export var button_min_size: Vector2 = Vector2(240.0, 52.0)
@export var click_sound: AudioStream

var _visual: MenuVisual
var _start_button: Button
var _hover_tweens: Dictionary[Button, Tween] = {}


func _ready() -> void:
	_visual = MenuVisual.new()
	add_child(_visual)
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


# -------------------------------------------------------------------
# MENU GAMEPLAY VISUAL
# -------------------------------------------------------------------

## Wanders at a constant speed, turning slowly and bending away from walls before reaching them.
class Drifter:
	var position: Vector2
	var velocity: Vector2 = Vector2.from_angle(randf() * TAU)
	var speed: float
	var steer_strength: float
	var steer_frequency: Vector2
	var steer_phase: Vector2 = Vector2(randf_range(0.0, TAU), randf_range(0.0, TAU))
	var wall_margin: float
	var wall_push: float

	## [param wall_force] points away from nearby walls, see [method MenuVisual._wall_force].
	func drift(delta: float, time: float, wall_force: Vector2) -> void:
		var steering := Vector2(
			sin(time * steer_frequency.x + steer_phase.x),
			cos(time * steer_frequency.y + steer_phase.y)
		)
		velocity += steering * steer_strength * delta
		velocity += wall_force * wall_push * delta
		# Steering changes the direction only, never the speed
		velocity = velocity.normalized() * speed
		position += velocity * delta


## An enemy circle in the menu.
class MenuEnemy extends Drifter:
	var color: Color
	var radius: float
	## Time left on the knot pulse, set when the player winds around it.
	var pulse: float = 0.0

	func _init(enemy_color: Color, enemy_radius: float) -> void:
		color = enemy_color
		radius = enemy_radius


## Draws a decorative round of the game behind the menu.
class MenuVisual extends Node2D:
	const ENEMY_RADIUS: float = 55.0 / 3.0
	## Colour and radius multiplier of each lone enemy.
	const ENEMY_SPECS: Array = [
		[Color(0.9, 0.15, 0.15), 1.0],
		[Color(0.2, 0.4, 1.0), 1.0],
		[Color(0.65, 0.2, 0.85), 1.0],
		[Color(1.0, 0.55, 0.1), 1.0],
		[Color(1.0, 0.85, 0.4), 1.0],
		[Color.BLACK, 0.5],
		[Color.WHITE, 2.0],
	]
	const ENEMY_SPEED: float = 40.0
	const ENEMY_STEER: float = 12.0
	const ENEMY_WALL_MARGIN: float = 100.0
	const ENEMY_WALL_PUSH: float = 80.0
	## Minimum gap between two lone enemies.
	const ENEMY_SPACING: float = 20.0

	const PAIR_COLOR: Color = Color(0.6, 1.0, 0.5)
	const PAIR_SPEED: float = 36.0
	const PAIR_STEER: float = 14.0
	const PAIR_STEER_FREQUENCY: Vector2 = Vector2(0.31, 0.37)
	const PAIR_WALL_MARGIN: float = 120.0
	const PAIR_WALL_PUSH: float = 90.0
	const PAIR_GAP: float = 30.0
	## Radians per second the pair spins around its center.
	const PAIR_SPIN: float = 0.45

	## The player always moves at this speed and only turns, so it never slows down in curves.
	const PLAYER_SPEED: float = 250.0
	## Fastest the player turns while wandering, in radians per second. Lower gives wider, calmer curves.
	const PLAYER_TURN_SPEED: float = 4.0
	## Fastest turn while winding. PLAYER_SPEED divided by this is the tightest loop radius.
	const PLAYER_WIND_TURN_SPEED: float = 5.0
	## Fastest turn right at a wall, so it bounces off quickly.
	const PLAYER_WALL_TURN_SPEED: float = 6.0
	## How hard the turn follows the direction the player wants to go.
	const PLAYER_TURN_GAIN: float = 4.0
	## How fast the turn itself can change. Easing it in and out is what keeps the path smooth.
	const PLAYER_TURN_SMOOTHING: float = 6.0
	## Distance from a wall where the player starts turning away from it.
	## Small on purpose, so the player can bump into walls and bounce off.
	const PLAYER_WALL_MARGIN: float = 60.0
	## Wall push at the wall itself, relative to the wander pull. Above 1 so it doesn't slide along the wall.
	const PLAYER_WALL_PUSH_SCALE: float = 1.5
	## Seconds ahead the player checks for walls. Raise it to avoid walls more.
	const WALL_LOOKAHEAD: float = 0.15
	const WANDER_FREQUENCY: Vector2 = Vector2(0.63, 0.91)
	## Extra distance the player keeps from enemy edges.
	const AVOID_DISTANCE: float = 95.0
	const WANDER_WEIGHT: float = 0.65
	const AVOID_WEIGHT: float = 2.0

	## The enemies are spread over a grid of this many columns and rows at the start.
	const SPAWN_GRID: int = 3
	const SPAWN_MARGIN: float = 70.0
	## Random offset from the grid cell's center, so it doesn't look like a grid.
	const SPAWN_JITTER: float = 70.0

	const WIND_INTERVAL_MIN: float = 6.0
	const WIND_INTERVAL_MAX: float = 9.0
	## Distance from the enemy's edge the player circles at.
	const WIND_DISTANCE: float = 55.0
	## Extra room the orbit needs from the walls. Negative lets loops brush the wall.
	const WIND_WALL_GAP: float = 0.0
	## Give up winding if a full loop takes longer than this.
	const WIND_TIMEOUT: float = 6.0
	const KNOT_PULSE_TIME: float = 0.4
	const KNOT_PULSE_GROWTH: float = 18.0

	var _thread: ThreadTrail
	var _arena: Rect2
	var _time: float = 0.0
	var _is_set_up: bool = false

	var _player_position: Vector2
	var _player_velocity: Vector2 = Vector2.RIGHT
	## Angle the player is heading in, in radians.
	var _player_heading: float = 0.0
	## Radians per second the heading is currently turning.
	var _player_turn: float = 0.0

	var _enemies: Array[MenuEnemy] = []
	var _pair_center: Drifter
	var _pair_a: MenuEnemy
	var _pair_b: MenuEnemy
	## Lone enemies and the pair.
	var _all_enemies: Array[MenuEnemy] = []

	## Enemy the player is winding around, null while wandering.
	var _wind_target: MenuEnemy
	## 1 to wind one way, -1 for the other.
	var _wind_sign: float = 1.0
	var _wind_angle: float = 0.0
	## Radians wound around the target so far.
	var _wound: float = 0.0
	var _wind_time: float = 0.0
	var _wind_cooldown: float = 0.0


	func _ready() -> void:
		top_level = true
		global_transform = Transform2D.IDENTITY

		_thread = ThreadTrail.new()
		add_child(_thread)


	func _process(delta: float) -> void:
		_time += delta
		_arena = Rect2(
			Vector2.ONE * ARENA_MARGIN,
			get_viewport_rect().size - Vector2.ONE * ARENA_MARGIN * 2.0
		)

		# Waits for the first frame, when the arena size is known
		if not _is_set_up:
			_setup()

		_update_winding(delta)
		_update_player(delta)
		_update_enemies(delta)
		_update_pair(delta)
		queue_redraw()


	func _draw() -> void:
		draw_rect(_arena, Color(1.0, 1.0, 1.0, 0.18), false, 2.0)

		# Subtle arena cross-lines
		var center := _arena.get_center()
		var line_color := Color(1.0, 1.0, 1.0, 0.025)
		draw_line(Vector2(_arena.position.x, center.y), Vector2(_arena.end.x, center.y), line_color, 1.0)
		draw_line(Vector2(center.x, _arena.position.y), Vector2(center.x, _arena.end.y), line_color, 1.0)

		if not _is_set_up:
			return

		# Pair connection, matching PairedType's visual language
		var heading := (_pair_b.position - _pair_a.position).normalized()
		draw_dashed_line(
			_pair_a.position + heading * _pair_a.radius,
			_pair_b.position - heading * _pair_b.radius,
			Color(_pair_a.color, 0.5),
			2.0,
			8.0
		)

		for enemy: MenuEnemy in _all_enemies:
			draw_circle(enemy.position, enemy.radius, enemy.color.darkened(0.6))
			draw_arc(enemy.position, enemy.radius, 0.0, TAU, 32, enemy.color, 2.0)

			if enemy.pulse > 0.0:
				var progress: float = 1.0 - enemy.pulse / KNOT_PULSE_TIME
				draw_arc(
					enemy.position,
					enemy.radius + progress * KNOT_PULSE_GROWTH,
					0.0,
					TAU,
					32,
					Color(THREAD_COLOR, 1.0 - progress),
					2.0
				)

		draw_circle(_player_position, PLAYER_RADIUS, THREAD_COLOR)


	func _setup() -> void:
		_is_set_up = true
		_player_position = _arena.get_center() + Vector2(-180.0, 90.0)
		_wind_cooldown = randf_range(WIND_INTERVAL_MIN, WIND_INTERVAL_MAX)

		for i: int in ENEMY_SPECS.size():
			var spec: Array = ENEMY_SPECS[i]
			var enemy := MenuEnemy.new(spec[0], ENEMY_RADIUS * spec[1])
			enemy.position = _spawn_point(i)
			enemy.speed = ENEMY_SPEED
			enemy.steer_strength = ENEMY_STEER
			enemy.steer_frequency = Vector2(randf_range(0.25, 0.42), randf_range(0.28, 0.46))
			enemy.wall_margin = ENEMY_WALL_MARGIN
			enemy.wall_push = ENEMY_WALL_PUSH
			_enemies.append(enemy)

		# The pair drifts as one and spins around its own center
		_pair_center = Drifter.new()
		_pair_center.position = _spawn_point(_enemies.size())
		_pair_center.speed = PAIR_SPEED
		_pair_center.steer_strength = PAIR_STEER
		_pair_center.steer_frequency = PAIR_STEER_FREQUENCY
		_pair_center.wall_margin = PAIR_WALL_MARGIN
		_pair_center.wall_push = PAIR_WALL_PUSH
		_pair_a = MenuEnemy.new(PAIR_COLOR, ENEMY_RADIUS)
		_pair_b = MenuEnemy.new(PAIR_COLOR, ENEMY_RADIUS)

		_all_enemies.assign(_enemies)
		_all_enemies.append(_pair_a)
		_all_enemies.append(_pair_b)


	## A random point in grid cell [param index], so the enemies start spread over the arena.
	func _spawn_point(index: int) -> Vector2:
		var cell := (_arena.size - Vector2.ONE * SPAWN_MARGIN * 2.0) / float(SPAWN_GRID)
		var grid := Vector2(index % SPAWN_GRID, floorf(float(index) / SPAWN_GRID))
		var jitter := Vector2(
			randf_range(-SPAWN_JITTER, SPAWN_JITTER),
			randf_range(-SPAWN_JITTER, SPAWN_JITTER)
		)
		return _arena.position + Vector2.ONE * SPAWN_MARGIN + cell * (grid + Vector2(0.5, 0.5)) + jitter


	func _update_winding(delta: float) -> void:
		if _wind_target == null:
			_wind_cooldown -= delta
			if _wind_cooldown <= 0.0:
				_start_winding()
			return

		_wind_time += delta
		# The target drifted towards a wall, so circling it would hit the wall
		if not _orbit_fits(_wind_target):
			_stop_winding()
			return

		var angle: float = (_player_position - _wind_target.position).angle()
		_wound += angle_difference(_wind_angle, angle)
		_wind_angle = angle

		if absf(_wound) >= TAU:
			_wind_target.pulse = KNOT_PULSE_TIME
			_stop_winding()
		elif _wind_time > WIND_TIMEOUT:
			_stop_winding()


	func _start_winding() -> void:
		_wind_target = _pick_wind_target()
		if _wind_target == null:
			_stop_winding()
			return

		var offset := _player_position - _wind_target.position
		# Keep turning the way the player is already going
		_wind_sign = 1.0 if offset.orthogonal().dot(_player_velocity) >= 0.0 else -1.0
		_wind_angle = offset.angle()
		_wound = 0.0
		_wind_time = 0.0


	func _stop_winding() -> void:
		_wind_target = null
		_wind_cooldown = randf_range(WIND_INTERVAL_MIN, WIND_INTERVAL_MAX)


	## Nearest lone enemy the player can circle without hitting a wall, or null if there is none.
	func _pick_wind_target() -> MenuEnemy:
		var nearest: MenuEnemy = null
		var nearest_distance: float = INF
		for enemy: MenuEnemy in _enemies:
			var distance: float = enemy.position.distance_squared_to(_player_position)
			if distance < nearest_distance and _orbit_fits(enemy):
				nearest = enemy
				nearest_distance = distance
		return nearest


	func _orbit_fits(target: MenuEnemy) -> bool:
		var reach: float = target.radius + WIND_DISTANCE + PLAYER_RADIUS + WIND_WALL_GAP
		return _arena.grow(-reach).has_point(target.position)


	func _update_player(delta: float) -> void:
		var direction: Vector2 = _orbit_direction(_wind_target) if _wind_target != null else _wander_direction()

		# Not normalized, so avoidance fades in as enemies get closer instead of snapping on
		direction = direction * WANDER_WEIGHT + _enemy_avoidance() * AVOID_WEIGHT

		# Check where the player is and where it's about to be, so it turns before reaching the wall
		var ahead := _wall_force(_player_position + _player_velocity * WALL_LOOKAHEAD, PLAYER_WALL_MARGIN, true)
		var here := _wall_force(_player_position, PLAYER_WALL_MARGIN, true)
		var wall_force := Vector2(_stronger(ahead.x, here.x), _stronger(ahead.y, here.y))
		direction = _steer_off_walls(direction, wall_force) + wall_force * PLAYER_WALL_PUSH_SCALE

		var max_turn: float = PLAYER_WIND_TURN_SPEED if _wind_target != null else PLAYER_TURN_SPEED
		max_turn = lerpf(max_turn, PLAYER_WALL_TURN_SPEED, clampf(wall_force.length(), 0.0, 1.0))
		_turn_towards(direction, max_turn, delta)

		_player_velocity = Vector2.from_angle(_player_heading) * PLAYER_SPEED
		_player_position = _clamp_to_arena(_player_position + _player_velocity * delta, PLAYER_RADIUS)
		_thread.add_point(_player_position)


	## Turns the heading towards [param direction], at most [param max_turn] radians per second.
	## The turn eases towards its target instead of jumping, so the path curves smoothly.
	func _turn_towards(direction: Vector2, max_turn: float, delta: float) -> void:
		var target_turn: float = 0.0
		if direction.length_squared() > 0.000001:
			var error: float = angle_difference(_player_heading, direction.angle())
			# Target almost straight behind: keep turning the same way instead of flipping between sides
			if absf(error) > PI * 0.8 and error * _player_turn < 0.0:
				error += TAU * signf(_player_turn)
			target_turn = clampf(error * PLAYER_TURN_GAIN, -max_turn, max_turn)

		_player_turn = lerpf(_player_turn, target_turn, minf(PLAYER_TURN_SMOOTHING * delta, 1.0))
		_player_heading = wrapf(_player_heading + _player_turn * delta, -PI, PI)


	## Removes the part of [param direction] that heads into a wall, more the closer the wall is.
	func _steer_off_walls(direction: Vector2, wall_force: Vector2) -> Vector2:
		for axis: int in 2:
			if direction[axis] * wall_force[axis] < 0.0:
				direction[axis] *= 1.0 - absf(wall_force[axis])
		return direction


	## Whichever of [param a] and [param b] is further from zero.
	func _stronger(a: float, b: float) -> float:
		return a if absf(a) > absf(b) else b


	func _wander_direction() -> Vector2:
		return Vector2(cos(_time * WANDER_FREQUENCY.x), sin(_time * WANDER_FREQUENCY.y)).normalized()


	## Circles [param target] at WIND_DISTANCE from its edge, spiralling in or out to get there.
	func _orbit_direction(target: MenuEnemy) -> Vector2:
		var offset := _player_position - target.position
		var distance: float = maxf(offset.length(), 0.001)
		var outward := offset / distance
		var orbit_distance: float = target.radius + WIND_DISTANCE
		var correction: float = clampf((orbit_distance - distance) / orbit_distance, -1.0, 1.0)
		return (outward.orthogonal() * _wind_sign + outward * correction).normalized()


	## Points away from nearby enemies, stronger the closer they are. Ignores the wind target.
	func _enemy_avoidance() -> Vector2:
		var avoidance := Vector2.ZERO
		for enemy: MenuEnemy in _all_enemies:
			if enemy == _wind_target:
				continue

			var offset := _player_position - enemy.position
			var distance: float = offset.length()
			var safe_distance: float = enemy.radius + PLAYER_RADIUS + AVOID_DISTANCE
			if distance < safe_distance and distance > 0.001:
				var strength: float = 1.0 - distance / safe_distance
				avoidance += offset / distance * strength * strength
		return avoidance


	func _update_enemies(delta: float) -> void:
		for enemy: MenuEnemy in _all_enemies:
			enemy.pulse = maxf(enemy.pulse - delta, 0.0)

		for enemy: MenuEnemy in _enemies:
			enemy.drift(delta, _time, _wall_force(enemy.position, enemy.wall_margin, false))

		_separate_enemies()

		# Steering keeps them inside, this catches window resizes and separation pushes
		for enemy: MenuEnemy in _enemies:
			enemy.position = _clamp_to_arena(enemy.position, enemy.radius)


	## Pushes overlapping lone enemies apart.
	func _separate_enemies() -> void:
		for i: int in _enemies.size():
			for j: int in range(i + 1, _enemies.size()):
				var a := _enemies[i]
				var b := _enemies[j]
				var offset := b.position - a.position
				var distance: float = offset.length()
				var minimum_distance: float = a.radius + b.radius + ENEMY_SPACING
				if distance >= minimum_distance:
					continue

				var direction: Vector2 = offset / distance if distance > 0.001 else Vector2.RIGHT
				var push: float = (minimum_distance - distance) * 0.5
				a.position -= direction * push
				b.position += direction * push


	func _update_pair(delta: float) -> void:
		_pair_center.drift(delta, _time, _wall_force(_pair_center.position, _pair_center.wall_margin, false))

		# Keep the whole pair inside the arena
		var spacing: float = _pair_a.radius + _pair_b.radius + PAIR_GAP
		var half_width: float = spacing * 0.5 + _pair_a.radius
		_pair_center.position = _clamp_to_arena(_pair_center.position, half_width)

		# Spins around its own center, not around the arena
		var offset := Vector2.from_angle(_time * PAIR_SPIN) * spacing * 0.5
		_pair_a.position = _pair_center.position - offset
		_pair_b.position = _pair_center.position + offset


	## Points back into the arena on each axis where [param point] is within [param margin] of a wall.
	## Hard force is 1 per axis. Soft force grows from 0 at the margin to 1 at the wall.
	func _wall_force(point: Vector2, margin: float, soft: bool) -> Vector2:
		var force := Vector2.ZERO
		for axis: int in 2:
			var from_start: float = point[axis] - _arena.position[axis]
			var from_end: float = _arena.end[axis] - point[axis]
			# Capped at 1, since a look-ahead point can be past the wall
			if from_start < margin:
				force[axis] = minf(1.0 - from_start / margin, 1.0) if soft else 1.0
			elif from_end < margin:
				force[axis] = -minf(1.0 - from_end / margin, 1.0) if soft else -1.0
		return force


	## [param point] moved inside the arena, at least [param inset] away from every wall.
	func _clamp_to_arena(point: Vector2, inset: float) -> Vector2:
		return point.clamp(_arena.position + Vector2.ONE * inset, _arena.end - Vector2.ONE * inset)
