@tool
class_name MenuBackground
extends MenuBase
## Main menu for Winding Combat.
## Uses the same visual language as the game:
## a small yellow player, fading golden thread, enemy circles,
## winding indicators, and the arena border.

@export var title: String = ""
@export_multiline var subtitle: String = ""
@export_file("*.tscn") var game_scene: String = "res://scenes/arena/arena.tscn"

@export var title_font_size: int = 64
@export var subtitle_font_size: int = 18
@export var button_min_size: Vector2 = Vector2(240.0, 52.0)
@export var click_sound: AudioStream

const ARENA_MARGIN: float = 24.0
const PLAYER_RADIUS: float = 10.0
const THREAD_COLOR := Color(1.0, 0.85, 0.4)

var _visual: MenuVisual
var _start_button: Button


func _ready() -> void:
	_build_visual()
	_build_ui()


func _build_visual() -> void:
	_visual = MenuVisual.new()
	add_child(_visual)


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	# Title
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", title_font_size)
	column.add_child(title_label)

	# Subtitle
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", subtitle_font_size)
	subtitle_label.modulate = Color(1.0, 1.0, 1.0, 0.65)
	column.add_child(subtitle_label)

	# Space between subtitle and buttons.
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18.0
	column.add_child(spacer)

	_start_button = _add_button(column, "START", _on_start_pressed)

	if not OS.has_feature("web"):
		_add_button(column, "QUIT", _on_quit_pressed)

	initial_focus = _start_button
	_start_button.grab_focus.call_deferred()


func _add_button(parent: Control, text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = button_min_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pivot_offset = button_min_size * 0.5

	button.mouse_entered.connect(func() -> void:
		_button_hover(button, true)
	)

	button.mouse_exited.connect(func() -> void:
		if not button.has_focus():
			_button_hover(button, false)
	)

	button.focus_entered.connect(func() -> void:
		_button_hover(button, true)
	)

	button.focus_exited.connect(func() -> void:
		_button_hover(button, false)
	)

	button.pressed.connect(on_pressed)

	parent.add_child(button)
	return button


func _button_hover(button: Button, hovered: bool) -> void:
	var target := Vector2(1.06, 1.06) if hovered else Vector2.ONE

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, 0.12)


func _on_start_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.change_scene(game_scene)


func _on_quit_pressed() -> void:
	AudioManager.play_ui(click_sound)
	MainManager.quit_game()


class MenuVisual extends Node2D:
	const PLAYER_SPEED: float = 340.0
	const PLAYER_TURN_SPEED: float = 3.2

	const PLAYER_WALL_MARGIN: float = 110.0
	const PLAYER_ENEMY_MARGIN: float = 115.0
	const PLAYER_SAFE_GAP: float = 8.0

	const ENEMY_SPEED: float = 40.0
	const ENEMY_WALL_MARGIN: float = 100.0
	const ENEMY_SEPARATION: float = 20.0

	const KNOT_TIME: float = 0.3
	const RESPAWN_DELAY: float = 0.35
	const FADE_TIME: float = 0.8

	var thread: ThreadTrail

	var player_position := Vector2.ZERO
	var player_velocity := Vector2.RIGHT * PLAYER_SPEED

	var time: float = 0.0
	var arena := Rect2()

	var enemies := [
		{
			"position": Vector2.ZERO,
			"color": Color(0.9, 0.15, 0.15),
			"radius": 55.0 / 3.0,
			"winds": 2,
			"direction": 1.0,
			"phase": 0.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.2, 0.4, 1.0),
			"radius": 55.0 / 3.0,
			"winds": 1,
			"direction": -1.0,
			"phase": 1.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.65, 0.2, 0.85),
			"radius": 55.0 / 3.0,
			"winds": 1,
			"direction": 1.0,
			"phase": 2.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(1.0, 0.55, 0.1, 1.0),
			"radius": 55.0 / 3.0,
			"winds": 1,
			"direction": 1.0,
			"phase": 3.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(1.0, 0.85, 0.4),
			"radius": 55.0 / 3.0,
			"winds": 1,
			"direction": 1.0,
			"phase": 4.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color.BLACK,
			"radius": 55.0 / 6.0,
			"winds": 1,
			"direction": 1.0,
			"speed": 120.0,
			"phase": 5.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color.WHITE,
			"radius": 55.0 / 1.5,
			"winds": 4,
			"direction": -1.0,
			"speed": 40.0,
			"phase": 6.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.6, 1.0, 0.5),
			"radius": 55.0 / 3.0,
			"winds": 1,
			"direction": 1.0,
			"phase": 7.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.6, 1.0, 0.5),
			"radius": 55.0 / 3.0,
			"winds": 1,
			"direction": 1.0,
			"phase": 7.0,
		},
	]


	func _ready() -> void:
		top_level = true
		global_transform = Transform2D.IDENTITY

		_initialize_enemies()

		thread = ThreadTrail.new()
		add_child(thread)

		queue_redraw()


	func _initialize_enemies() -> void:
		for i in enemies.size():
			var enemy: Dictionary = enemies[i]

			enemy["move_velocity"] = Vector2.ZERO
			enemy["move_phase_x"] = randf_range(0.0, TAU)
			enemy["move_phase_y"] = randf_range(0.0, TAU)
			enemy["move_frequency_x"] = randf_range(0.25, 0.42)
			enemy["move_frequency_y"] = randf_range(0.28, 0.46)

			enemy["completed_winds"] = 0
			enemy["thread_completed_winds"] = 0
			enemy["progress"] = 0.0

			enemy["kill_state"] = 0
			enemy["kill_progress"] = 0.0
			enemy["kill_rotation"] = 0.0
			enemy["fade_alpha"] = 1.0
			enemy["respawn_timer"] = 0.0

			enemy["movement_initialized"] = false

		# Green pair shares one movement center.
		enemies[7]["pair_center"] = Vector2.ZERO
		enemies[8]["pair_center"] = Vector2.ZERO
		enemies[7]["pair_velocity"] = Vector2.RIGHT * 35.0
		enemies[8]["pair_velocity"] = Vector2.RIGHT * 35.0
		enemies[7]["pair_phase"] = randf_range(0.0, TAU)
		enemies[8]["pair_phase"] = enemies[7]["pair_phase"]


	func _process(delta: float) -> void:
		time += delta

		var viewport_size := get_viewport_rect().size

		arena = Rect2(
			Vector2(ARENA_MARGIN, ARENA_MARGIN),
			viewport_size - Vector2(ARENA_MARGIN * 2.0, ARENA_MARGIN * 2.0)
		)

		if player_position == Vector2.ZERO:
			player_position = arena.get_center() + Vector2(-180.0, 90.0)

		_initialize_enemy_positions()

		_update_player(delta)
		_update_enemies(delta)
		_update_enemy_loops(delta)

		queue_redraw()


	func _initialize_enemy_positions() -> void:
		if bool(enemies[0].get("movement_initialized", false)):
			return

		var margin := 70.0
		var columns := 3
		var rows := 3

		for i in enemies.size():
			var enemy: Dictionary = enemies[i]

			var column := i % columns
			var row := int(i / columns)

			var cell_width := (
				arena.size.x - margin * 2.0
			) / float(columns)

			var cell_height := (
				arena.size.y - margin * 2.0
			) / float(rows)

			var position := Vector2(
				arena.position.x + margin + cell_width * (float(column) + 0.5),
				arena.position.y + margin + cell_height * (float(row) + 0.5)
			)

			position += Vector2(
				randf_range(-60.0, 60.0),
				randf_range(-60.0, 60.0)
			)

			enemy["position"] = position

			var direction := Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			).normalized()

			if direction.length() < 0.001:
				direction = Vector2.RIGHT

			var speed: float = float(enemy.get("speed", ENEMY_SPEED))

			enemy["move_velocity"] = direction * speed
			enemy["movement_initialized"] = true

		var pair_center: Vector2 = enemies[7]["position"]
		enemies[7]["pair_center"] = pair_center
		enemies[8]["pair_center"] = pair_center

		var pair_direction := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		if pair_direction.length() < 0.001:
			pair_direction = Vector2.RIGHT

		enemies[7]["pair_velocity"] = pair_direction * 35.0
		enemies[8]["pair_velocity"] = pair_direction * 35.0


	func _update_player(delta: float) -> void:
		var desired := Vector2(
			cos(time * 0.63),
			sin(time * 0.91)
		)

		if desired.length() < 0.001:
			desired = Vector2.RIGHT

		# Keep the player away from enemies without making it orbit them.
		var avoidance := Vector2.ZERO

		for enemy in enemies:
			if int(enemy.get("kill_state", 0)) != 0:
				continue

			var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
			var offset := player_position - enemy_position
			var distance := offset.length()

			var safe_distance := (
				float(enemy.get("radius", 16.0))
				+ PLAYER_RADIUS
				+ PLAYER_ENEMY_MARGIN
			)

			if distance < safe_distance and distance > 0.001:
				var strength := 1.0 - distance / safe_distance
				avoidance += offset.normalized() * strength * strength

		if avoidance.length() > 0.001:
			desired = (
				desired * 0.7
				+ avoidance.normalized() * 1.1
			).normalized()

		# Smooth wall steering.
		var wall_force := Vector2.ZERO

		var left := player_position.x - arena.position.x
		var right := arena.end.x - player_position.x
		var top := player_position.y - arena.position.y
		var bottom := arena.end.y - player_position.y

		if left < PLAYER_WALL_MARGIN:
			var strength := 1.0 - left / PLAYER_WALL_MARGIN
			wall_force.x += strength * strength

		if right < PLAYER_WALL_MARGIN:
			var strength := 1.0 - right / PLAYER_WALL_MARGIN
			wall_force.x -= strength * strength

		if top < PLAYER_WALL_MARGIN:
			var strength := 1.0 - top / PLAYER_WALL_MARGIN
			wall_force.y += strength * strength

		if bottom < PLAYER_WALL_MARGIN:
			var strength := 1.0 - bottom / PLAYER_WALL_MARGIN
			wall_force.y -= strength * strength

		if wall_force.length() > 0.001:
			desired = (
				desired * 0.65
				+ wall_force.normalized() * 0.9
			).normalized()

		var current_direction := player_velocity.normalized()

		if current_direction.length() < 0.001:
			current_direction = desired

		current_direction = current_direction.slerp(
			desired,
			clampf(PLAYER_TURN_SPEED * delta, 0.0, 1.0)
		).normalized()

		player_velocity = current_direction * PLAYER_SPEED

		var proposed := player_position + player_velocity * delta

		# Hard collision prevention.
		for enemy in enemies:
			if int(enemy.get("kill_state", 0)) != 0:
				continue

			var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
			var enemy_radius: float = enemy.get("radius", 16.0)

			var minimum_distance := (
				PLAYER_RADIUS
				+ enemy_radius
				+ PLAYER_SAFE_GAP
			)

			var offset := proposed - enemy_position
			var distance := offset.length()

			if distance < minimum_distance:
				var normal := Vector2.RIGHT

				if distance > 0.001:
					normal = offset / distance

				proposed = enemy_position + normal * minimum_distance

				var inward := player_velocity.dot(normal)

				if inward < 0.0:
					player_velocity -= normal * inward

		player_position = proposed

		# Hard arena boundary.
		player_position.x = clampf(
			player_position.x,
			arena.position.x + PLAYER_RADIUS + 4.0,
			arena.end.x - PLAYER_RADIUS - 4.0
		)

		player_position.y = clampf(
			player_position.y,
			arena.position.y + PLAYER_RADIUS + 4.0,
			arena.end.y - PLAYER_RADIUS - 4.0
		)

		thread.add_point(player_position)


	func _update_enemies(delta: float) -> void:
		# Normal enemies.
		for i in range(7):
			var enemy: Dictionary = enemies[i]

			if int(enemy.get("kill_state", 0)) != 0:
				continue

			var position: Vector2 = enemy.get("position", arena.get_center())
			var velocity: Vector2 = enemy.get(
				"move_velocity",
				Vector2.RIGHT * ENEMY_SPEED
			)

			var phase_x: float = enemy.get("move_phase_x", 0.0)
			var phase_y: float = enemy.get("move_phase_y", 0.0)

			# Slow organic steering instead of a fixed path.
			var wander := Vector2(
				sin(time * enemy.get("move_frequency_x", 0.35) + phase_x),
				cos(time * enemy.get("move_frequency_y", 0.35) + phase_y)
			)

			velocity += wander * 18.0 * delta

			# Steer away from the player before getting too close.
			var player_offset := position - player_position
			var player_distance := player_offset.length()
			var player_safe_distance := (
				float(enemy.get("radius", 16.0))
				+ PLAYER_RADIUS
				+ 45.0
			)

			if player_distance < player_safe_distance and player_distance > 0.001:
				var strength := 1.0 - player_distance / player_safe_distance
				velocity += player_offset.normalized() * strength * 100.0 * delta

			# Wall steering.
			var wall_force := Vector2.ZERO

			if position.x < arena.position.x + ENEMY_WALL_MARGIN:
				var strength := 1.0 - (
					position.x - arena.position.x
				) / ENEMY_WALL_MARGIN
				wall_force.x += strength

			if position.x > arena.end.x - ENEMY_WALL_MARGIN:
				var strength := 1.0 - (
					arena.end.x - position.x
				) / ENEMY_WALL_MARGIN
				wall_force.x -= strength

			if position.y < arena.position.y + ENEMY_WALL_MARGIN:
				var strength := 1.0 - (
					position.y - arena.position.y
				) / ENEMY_WALL_MARGIN
				wall_force.y += strength

			if position.y > arena.end.y - ENEMY_WALL_MARGIN:
				var strength := 1.0 - (
					arena.end.y - position.y
				) / ENEMY_WALL_MARGIN
				wall_force.y -= strength

			velocity += wall_force * 100.0 * delta

			var speed: float = enemy.get("speed", ENEMY_SPEED)

			if velocity.length() < 0.001:
				velocity = Vector2.RIGHT * speed

			velocity = velocity.normalized() * speed

			enemy["move_velocity"] = velocity
			enemy["position"] = position + velocity * delta

		_separate_enemies()
		_update_green_pair(delta)


	func _separate_enemies() -> void:
		for i in range(7):
			if int(enemies[i].get("kill_state", 0)) != 0:
				continue

			for j in range(i + 1, 7):
				if int(enemies[j].get("kill_state", 0)) != 0:
					continue

				var first: Dictionary = enemies[i]
				var second: Dictionary = enemies[j]

				var first_position: Vector2 = first.get("position", Vector2.ZERO)
				var second_position: Vector2 = second.get("position", Vector2.ZERO)

				var offset := second_position - first_position
				var distance := offset.length()

				var minimum_distance := (
					float(first.get("radius", 16.0))
					+ float(second.get("radius", 16.0))
					+ ENEMY_SEPARATION
				)

				if distance >= minimum_distance:
					continue

				var direction := Vector2.RIGHT

				if distance > 0.001:
					direction = offset / distance

				var push := (minimum_distance - distance) * 0.5

				first["position"] = first_position - direction * push
				second["position"] = second_position + direction * push


	func _update_green_pair(delta: float) -> void:
		var green_a: Dictionary = enemies[7]
		var green_b: Dictionary = enemies[8]

		if int(green_a.get("kill_state", 0)) != 0:
			return

		var center: Vector2 = green_a.get(
			"pair_center",
			arena.get_center()
		)

		var velocity: Vector2 = green_a.get(
			"pair_velocity",
			Vector2.RIGHT * 35.0
		)

		var phase: float = green_a.get("pair_phase", 0.0)

		var wander := Vector2(
			sin(time * 0.31 + phase),
			cos(time * 0.37 + phase)
		)

		velocity += wander * 14.0 * delta

		var wall_force := Vector2.ZERO
		var margin := 120.0

		if center.x < arena.position.x + margin:
			wall_force.x += 1.0

		if center.x > arena.end.x - margin:
			wall_force.x -= 1.0

		if center.y < arena.position.y + margin:
			wall_force.y += 1.0

		if center.y > arena.end.y - margin:
			wall_force.y -= 1.0

		velocity += wall_force * 90.0 * delta

		if velocity.length() < 0.001:
			velocity = Vector2.RIGHT * 35.0

		velocity = velocity.normalized() * 35.0
		center += velocity * delta

		var spacing := (
			float(green_a.get("radius", 16.0))
			+ float(green_b.get("radius", 16.0))
			+ 30.0
		)

		var half_spacing := spacing * 0.5

		center.x = clampf(
			center.x,
			arena.position.x + half_spacing + 10.0,
			arena.end.x - half_spacing - 10.0
		)

		center.y = clampf(
			center.y,
			arena.position.y + half_spacing + 10.0,
			arena.end.y - half_spacing - 10.0
		)

		var pair_angle := time * 0.45
		var pair_direction := Vector2.from_angle(pair_angle)

		green_a["pair_center"] = center
		green_b["pair_center"] = center
		green_a["pair_velocity"] = velocity
		green_b["pair_velocity"] = velocity

		green_a["position"] = center - pair_direction * half_spacing
		green_b["position"] = center + pair_direction * half_spacing


	func _update_enemy_loops(delta: float) -> void:
		for enemy in enemies:
			var state: int = int(enemy.get("kill_state", 0))

			if state == 1:
				enemy["kill_progress"] = (
					float(enemy.get("kill_progress", 0.0))
					+ delta / KNOT_TIME
				)

				enemy["kill_rotation"] = (
					float(enemy.get("kill_rotation", 0.0))
					+ enemy.get("direction", 1.0) * TAU * delta / KNOT_TIME
				)

				if float(enemy["kill_progress"]) >= 1.0:
					enemy["kill_progress"] = 1.0
					enemy["kill_state"] = 2
					enemy["respawn_timer"] = RESPAWN_DELAY

				continue

			if state == 2:
				enemy["respawn_timer"] = (
					float(enemy.get("respawn_timer", 0.0))
					- delta
				)

				if float(enemy["respawn_timer"]) <= 0.0:
					_respawn_enemy(enemy)

				continue

			if state == 3:
				enemy["fade_alpha"] = (
					float(enemy.get("fade_alpha", 0.0))
					+ delta / FADE_TIME
				)

				if float(enemy["fade_alpha"]) >= 1.0:
					enemy["fade_alpha"] = 1.0
					enemy["kill_state"] = 0

				continue

			_update_enemy_winding(enemy)


	func _update_enemy_winding(enemy: Dictionary) -> void:
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)

		var winding := thread.winding_around(enemy_position)

		var direction: float = enemy.get("direction", 1.0)

		# Convert the player's signed winding into this enemy's
		# required direction, just like EnemyType.wound_amount().
		var along := winding * direction

		const TOLERANCE: float = 0.15

		if absf(along) <= TOLERANCE:
			enemy["thread_completed_winds"] = 0
			enemy["progress"] = 0.0
			return

		var completed_in_thread := floori(along + TOLERANCE)

		var old_completed: int = enemy.get(
			"thread_completed_winds",
			0
		)

		var newly_completed := completed_in_thread - old_completed

		if newly_completed > 0:
			enemy["completed_winds"] = (
				int(enemy.get("completed_winds", 0))
				+ newly_completed
			)

			enemy["thread_completed_winds"] = completed_in_thread

		enemy["progress"] = along - completed_in_thread

		if int(enemy.get("completed_winds", 0)) >= int(enemy.get("winds", 1)):
			_kill_enemy(enemy)


	func _kill_enemy(enemy: Dictionary) -> void:
		if int(enemy.get("kill_state", 0)) != 0:
			return

		# Green is a linked pair.
		if enemy == enemies[7] or enemy == enemies[8]:
			for green in [enemies[7], enemies[8]]:
				_start_knot(green)

			thread.clear()
			return

		_start_knot(enemy)
		thread.clear()


	func _start_knot(enemy: Dictionary) -> void:
		enemy["kill_state"] = 1
		enemy["kill_progress"] = 0.0
		enemy["kill_rotation"] = 0.0
		enemy["completed_winds"] = 0
		enemy["thread_completed_winds"] = 0
		enemy["progress"] = 0.0


	func _respawn_enemy(enemy: Dictionary) -> void:
		enemy["position"] = _find_respawn_position(enemy)

		enemy["fade_alpha"] = 0.0
		enemy["kill_progress"] = 0.0
		enemy["kill_rotation"] = 0.0
		enemy["completed_winds"] = 0
		enemy["thread_completed_winds"] = 0
		enemy["progress"] = 0.0
		enemy["kill_state"] = 3

		var direction := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		if direction.length() < 0.001:
			direction = Vector2.RIGHT

		var speed: float = enemy.get("speed", ENEMY_SPEED)

		enemy["move_velocity"] = direction * speed
		enemy["move_phase_x"] = randf_range(0.0, TAU)
		enemy["move_phase_y"] = randf_range(0.0, TAU)

		# Yellow's direction is chosen again when it respawns.
		if enemy["color"] == Color(1.0, 0.85, 0.4):
			enemy["direction"] = 1.0 if randf() < 0.5 else -1.0

		# Green pair respawns together.
		if enemy == enemies[7] or enemy == enemies[8]:
			var center: Vector2 = enemy["position"]

			var green_a: Dictionary = enemies[7]
			var green_b: Dictionary = enemies[8]

			green_a["pair_center"] = center
			green_b["pair_center"] = center

			green_a["kill_state"] = 3
			green_b["kill_state"] = 3
			green_a["fade_alpha"] = 0.0
			green_b["fade_alpha"] = 0.0

			green_a["completed_winds"] = 0
			green_b["completed_winds"] = 0
			green_a["thread_completed_winds"] = 0
			green_b["thread_completed_winds"] = 0

			var pair_direction := Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			).normalized()

			if pair_direction.length() < 0.001:
				pair_direction = Vector2.RIGHT

			green_a["pair_velocity"] = pair_direction * 35.0
			green_b["pair_velocity"] = pair_direction * 35.0


	func _find_respawn_position(enemy: Dictionary) -> Vector2:
		var margin := 90.0

		for attempt in range(40):
			var candidate := Vector2(
				randf_range(
					arena.position.x + margin,
					arena.end.x - margin
				),
				randf_range(
					arena.position.y + margin,
					arena.end.y - margin
				)
			)

			if candidate.distance_to(player_position) < 320.0:
				continue

			var valid := true

			for other in enemies:
				if other == enemy:
					continue

				if int(other.get("kill_state", 0)) != 0:
					continue

				if candidate.distance_to(
					other.get("position", Vector2.ZERO)
				) < 100.0:
					valid = false
					break

			if valid:
				return candidate

		return arena.get_center()


	func _draw() -> void:
		# Arena border.
		draw_rect(
			arena,
			Color(1.0, 1.0, 1.0, 0.18),
			false,
			2.0
		)

		var center := arena.get_center()

		# Subtle arena cross-lines.
		draw_line(
			Vector2(arena.position.x, center.y),
			Vector2(arena.end.x, center.y),
			Color(1.0, 1.0, 1.0, 0.025),
			1.0
		)

		draw_line(
			Vector2(center.x, arena.position.y),
			Vector2(center.x, arena.end.y),
			Color(1.0, 1.0, 1.0, 0.025),
			1.0
		)

		_draw_green_connection()

		for enemy in enemies:
			_draw_enemy(enemy)

		# Player has no winding rings or arrow.
		draw_circle(
			player_position,
			PLAYER_RADIUS,
			THREAD_COLOR
		)


	func _draw_green_connection() -> void:
		var green_a: Dictionary = enemies[7]
		var green_b: Dictionary = enemies[8]

		if int(green_a.get("kill_state", 0)) == 2:
			return

		if int(green_b.get("kill_state", 0)) == 2:
			return

		var a: Vector2 = green_a.get("position", Vector2.ZERO)
		var b: Vector2 = green_b.get("position", Vector2.ZERO)

		var offset := b - a

		if offset.length() < 0.001:
			return

		var heading := offset.normalized()

		var start := a + heading * float(green_a.get("radius", 16.0))
		var end := b - heading * float(green_b.get("radius", 16.0))

		var alpha := minf(
			float(green_a.get("fade_alpha", 1.0)),
			float(green_b.get("fade_alpha", 1.0))
		)

		draw_dashed_line(
			start,
			end,
			Color(0.6, 1.0, 0.5, 0.5 * alpha),
			2.0,
			8.0
		)


	func _draw_enemy(enemy: Dictionary) -> void:
		var state: int = enemy.get("kill_state", 0)

		if state == 2:
			return

		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		var radius: float = enemy.get("radius", 16.0)
		var color: Color = enemy.get("color", Color.WHITE)

		if state == 1:
			_draw_knotting_enemy(enemy, position, radius, color)
			return

		var alpha: float = enemy.get("fade_alpha", 1.0)

		var body_color := Color(
			color.r,
			color.g,
			color.b,
			alpha
		)

		var dark_base := color.darkened(0.6)

		var dark_color := Color(
			dark_base.r,
			dark_base.g,
			dark_base.b,
			alpha
		)

		draw_circle(position, radius, dark_color)
		draw_arc(
			position,
			radius,
			0.0,
			TAU,
			32,
			body_color,
			2.0
		)

		_draw_winding_indicator(enemy, position, radius, alpha)


	func _draw_winding_indicator(
		enemy: Dictionary,
		position: Vector2,
		radius: float,
		alpha: float
	) -> void:
		var winds: int = enemy.get("winds", 1)
		var completed: int = enemy.get("completed_winds", 0)
		var remaining := maxi(winds - completed, 0)

		if remaining <= 0:
			return

		var direction: float = enemy.get("direction", 1.0)
		var progress: float = enemy.get("progress", 0.0)
		var color: Color = enemy.get("color", Color.WHITE)

		for i in remaining:
			var ring_radius := radius + 6.0 + i * 5.0

			draw_arc(
				position,
				ring_radius,
				0.0,
				TAU,
				32,
				Color(color, 0.25 * alpha),
				2.0
			)

			var fill := clampf(
				progress - i,
				0.0,
				1.0
			)

			if fill > 0.0:
				draw_arc(
					position,
					ring_radius,
					-PI / 2.0,
					-PI / 2.0 + direction * fill * TAU,
					48,
					Color(color, alpha),
					3.0
				)

		var tip := Vector2(
			0.0,
			-(radius + 6.0 + remaining * 5.0 + 3.0)
		)

		draw_colored_polygon(
			PackedVector2Array([
				position + tip + Vector2(direction * 7.0, 0.0),
				position + tip + Vector2(-direction * 3.0, -5.0),
				position + tip + Vector2(-direction * 3.0, 5.0),
			]),
			Color(color, alpha)
		)


	func _draw_knotting_enemy(
		enemy: Dictionary,
		position: Vector2,
		radius: float,
		color: Color
	) -> void:
		var progress: float = enemy.get("kill_progress", 0.0)
		var rotation: float = enemy.get("kill_rotation", 0.0)

		var t := clampf(progress, 0.0, 1.0)

		# Matches the game's shrink-and-spin feel.
		var scale := 1.0 - t
		var animated_radius := radius * scale

		if animated_radius <= 0.1:
			return

		var alpha := 1.0 - t

		var body_color := Color(
			color.r,
			color.g,
			color.b,
			alpha
		)

		var dark_base := color.darkened(0.6)

		var dark_color := Color(
			dark_base.r,
			dark_base.g,
			dark_base.b,
			alpha
		)

		draw_circle(
			position,
			animated_radius,
			dark_color
		)

		# Rotating knot-like rings.
		for ring in range(3):
			var ring_fraction := float(ring) / 3.0

			var ring_radius := animated_radius * (
				0.45 + ring_fraction * 0.45
			)

			var start_angle := (
				rotation
				+ ring_fraction * TAU / 3.0
			)

			draw_arc(
				position,
				ring_radius,
				start_angle,
				start_angle + TAU * (0.72 + t * 0.2),
				24,
				body_color,
				2.5
			)

		draw_arc(
			position,
			animated_radius,
			rotation,
			rotation + TAU,
			32,
			body_color,
			2.0
		)
