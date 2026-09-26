@tool
class_name MainMenu
extends MenuBase
## Main menu for Winding Combat.
## Uses the same visual language as the game:
## a small yellow player, fading golden thread, enemy circles,
## and the arena border.

@export var title: String = "WINDING COMBAT"
@export_multiline var subtitle: String = "Don't shoot. Wind your thread. Knot your enemies."
@export_file("*.tscn") var game_scene: String = "res://scenes/arena/arena.tscn"

@export var title_font_size: int = 64
@export var subtitle_font_size: int = 18
@export var button_min_size: Vector2 = Vector2(240.0, 52.0)
@export var click_sound: AudioStream

const ARENA_MARGIN: float = 24.0
const PLAYER_RADIUS: float = 10.0
const ENEMY_RADIUS: float = 16.0
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


# -------------------------------------------------------------------
# MENU GAMEPLAY VISUAL
# -------------------------------------------------------------------

class MenuVisual extends Node2D:
	var thread: ThreadTrail

	var player_position: Vector2 = Vector2.ZERO
	var player_velocity: Vector2 = Vector2(1.0, 0.0)

	var time: float = 0.0
	var arena: Rect2 = Rect2()

	var enemies := [
		{
			"position": Vector2.ZERO,
			"color": Color(0.9, 0.15, 0.15),
			"radius": 55.0 / 3.0,
			"phase": 0.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.2, 0.4, 1.0),
			"radius": 55.0 / 3.0,
			"phase": 1.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.65, 0.2, 0.85),
			"radius": 55.0 / 3.0,
			"phase": 2.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(1.0, 0.55, 0.1),
			"radius": 55.0 / 3.0,
			"phase": 3.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(1.0, 0.85, 0.4),
			"radius": 55.0 / 3.0,
			"phase": 4.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color.BLACK,
			"radius": 55.0 / 6.0,
			"phase": 5.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color.WHITE,
			"radius": 55.0 / 1.5,
			"phase": 6.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.6, 1.0, 0.5),
			"radius": 55.0 / 3.0,
			"phase": 7.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.6, 1.0, 0.5),
			"radius": 55.0 / 3.0,
			"phase": 7.0,
		},
	]


	func _ready() -> void:
		top_level = true
		global_transform = Transform2D.IDENTITY

		_initialize_all_enemy_state()

		thread = ThreadTrail.new()
		add_child(thread)

		queue_redraw()


	# ----------------------------------------------------------------
	# RUNTIME INITIALIZATION
	# ----------------------------------------------------------------

	func _initialize_all_enemy_state() -> void:
		for enemy in enemies:
			_initialize_enemy_state(enemy)

		if enemies.size() >= 9:
			enemies[7]["pair_center"] = Vector2.ZERO
			enemies[8]["pair_center"] = Vector2.ZERO

			enemies[7]["pair_velocity"] = Vector2.RIGHT * 35.0
			enemies[8]["pair_velocity"] = Vector2.RIGHT * 35.0

			enemies[7]["pair_phase_x"] = 0.0
			enemies[7]["pair_phase_y"] = 0.0

			enemies[8]["pair_phase_x"] = 0.0
			enemies[8]["pair_phase_y"] = 0.0


	func _initialize_enemy_state(enemy: Dictionary) -> void:
		# Movement state.
		enemy["move_velocity"] = Vector2.ZERO
		enemy["move_phase_x"] = 0.0
		enemy["move_phase_y"] = 0.0
		enemy["move_frequency_x"] = 0.35
		enemy["move_frequency_y"] = 0.35

		# Winding state.
		enemy["wind_angle"] = 0.0
		enemy["last_player_angle"] = 0.0
		enemy["tracking_loop"] = false

		# Kill state.
		# 0 = alive
		# 1 = knot animation
		# 2 = waiting to respawn
		# 3 = fading in
		enemy["kill_state"] = 0
		enemy["kill_progress"] = 0.0
		enemy["kill_rotation"] = 0.0
		enemy["fade_alpha"] = 1.0
		enemy["respawn_timer"] = 0.0


	func _process(delta: float) -> void:
		time += delta

		var viewport_size: Vector2 = get_viewport_rect().size

		arena = Rect2(
			Vector2(ARENA_MARGIN, ARENA_MARGIN),
			viewport_size - Vector2(
				ARENA_MARGIN * 2.0,
				ARENA_MARGIN * 2.0
			)
		)

		_update_player(delta)
		_update_enemies(delta)
		_update_enemy_loops(delta)

		queue_redraw()


	# ----------------------------------------------------------------
	# PLAYER
	# ----------------------------------------------------------------

	func _update_player(delta: float) -> void:
		if player_position == Vector2.ZERO:
			player_position = arena.get_center() + Vector2(-180.0, 90.0)

		const PLAYER_SPEED: float = 340.0
		const WALL_MARGIN: float = 120.0
		const TURN_SPEED: float = 1.8

		var desired_direction := Vector2(
			cos(time * 0.63),
			sin(time * 0.91)
		).normalized()

		# ------------------------------------------------------------
		# Enemy avoidance
		# ------------------------------------------------------------

		var avoidance := Vector2.ZERO

		for enemy in enemies:
			var kill_state: int = int(
				enemy.get("kill_state", 0)
			)

			if kill_state != 0:
				continue

			var offset: Vector2 = (
				player_position
				- enemy.get("position", Vector2.ZERO)
			)

			var distance: float = offset.length()

			var safe_distance: float = (
				float(enemy.get("radius", ENEMY_RADIUS))
				+ PLAYER_RADIUS
				+ 140.0
			)

			if distance < safe_distance and distance > 0.001:
				var strength: float = (
					1.0 - distance / safe_distance
				)

				avoidance += (
					offset.normalized()
					* strength
					* strength
				)

		if avoidance.length() > 0.001:
			desired_direction = (
				desired_direction * 0.35
				+ avoidance.normalized() * 1.25
			).normalized()

		# ------------------------------------------------------------
		# Smooth wall avoidance
		# ------------------------------------------------------------

		var wall_force := Vector2.ZERO

		var left_distance: float = (
			player_position.x - arena.position.x
		)

		var right_distance: float = (
			arena.end.x - player_position.x
		)

		var top_distance: float = (
			player_position.y - arena.position.y
		)

		var bottom_distance: float = (
			arena.end.y - player_position.y
		)

		if left_distance < WALL_MARGIN:
			var left_strength: float = (
				1.0 - left_distance / WALL_MARGIN
			)
			wall_force.x += left_strength * left_strength

		if right_distance < WALL_MARGIN:
			var right_strength: float = (
				1.0 - right_distance / WALL_MARGIN
			)
			wall_force.x -= right_strength * right_strength

		if top_distance < WALL_MARGIN:
			var top_strength: float = (
				1.0 - top_distance / WALL_MARGIN
			)
			wall_force.y += top_strength * top_strength

		if bottom_distance < WALL_MARGIN:
			var bottom_strength: float = (
				1.0 - bottom_distance / WALL_MARGIN
			)
			wall_force.y -= bottom_strength * bottom_strength

		if wall_force.length() > 0.001:
			desired_direction = (
				desired_direction * 0.55
				+ wall_force.normalized() * 0.9
			).normalized()

		# ------------------------------------------------------------
		# Smooth turning.
		# ------------------------------------------------------------

		var current_direction: Vector2 = (
			player_velocity.normalized()
		)

		if current_direction.length() < 0.001:
			current_direction = desired_direction

		current_direction = current_direction.slerp(
			desired_direction,
			clampf(TURN_SPEED * delta, 0.0, 1.0)
		).normalized()

		player_velocity = current_direction * PLAYER_SPEED
		player_position += player_velocity * delta

		# ------------------------------------------------------------
		# Hard safety boundary.
		# The player can never visually leave the arena.
		# ------------------------------------------------------------

		var safe_left: float = (
			arena.position.x
			+ PLAYER_RADIUS
			+ 4.0
		)

		var safe_right: float = (
			arena.end.x
			- PLAYER_RADIUS
			- 4.0
		)

		var safe_top: float = (
			arena.position.y
			+ PLAYER_RADIUS
			+ 4.0
		)

		var safe_bottom: float = (
			arena.end.y
			- PLAYER_RADIUS
			- 4.0
		)

		player_position.x = clampf(
			player_position.x,
			safe_left,
			safe_right
		)

		player_position.y = clampf(
			player_position.y,
			safe_top,
			safe_bottom
		)

		thread.add_point(player_position)


	# ----------------------------------------------------------------
	# ENEMY MOVEMENT
	# ----------------------------------------------------------------

	func _update_enemies(delta: float) -> void:
		# Initialize movement positions once.
		if not bool(enemies[0].get("movement_initialized", false)):
			var margin: float = 70.0

			for i in enemies.size():
				var enemy: Dictionary = enemies[i]

				var columns: int = 3
				var rows: int = 3

				var column: int = i % columns
				var row: int = int(i / columns)

				var cell_width: float = (
					arena.size.x - margin * 2.0
				) / float(columns)

				var cell_height: float = (
					arena.size.y - margin * 2.0
				) / float(rows)

				var base_position := Vector2(
					arena.position.x
					+ margin
					+ cell_width * (
						float(column) + 0.5
					),

					arena.position.y
					+ margin
					+ cell_height * (
						float(row) + 0.5
					)
				)

				base_position += Vector2(
					randf_range(-70.0, 70.0),
					randf_range(-70.0, 70.0)
				)

				enemy["position"] = base_position

				var initial_direction := Vector2(
					randf_range(-1.0, 1.0),
					randf_range(-1.0, 1.0)
				)

				if initial_direction.length() < 0.001:
					initial_direction = Vector2.RIGHT

				enemy["move_velocity"] = (
					initial_direction.normalized()
					* randf_range(28.0, 48.0)
				)

				enemy["move_phase_x"] = randf_range(0.0, TAU)
				enemy["move_phase_y"] = randf_range(0.0, TAU)

				enemy["move_frequency_x"] = randf_range(
					0.25,
					0.42
				)

				enemy["move_frequency_y"] = randf_range(
					0.28,
					0.46
				)

				enemy["movement_initialized"] = true

			# Green pair state.
			enemies[7]["pair_center"] = (
				enemies[7].get("position", arena.get_center())
			)

			enemies[8]["pair_center"] = (
				enemies[7].get("pair_center", arena.get_center())
			)

			var pair_direction := Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			)

			if pair_direction.length() < 0.001:
				pair_direction = Vector2.RIGHT

			enemies[7]["pair_velocity"] = (
				pair_direction.normalized() * 35.0
			)

			enemies[8]["pair_velocity"] = (
				pair_direction.normalized() * 35.0
			)

			enemies[7]["pair_phase_x"] = randf_range(
				0.0,
				TAU
			)

			enemies[7]["pair_phase_y"] = randf_range(
				0.0,
				TAU
			)

			enemies[8]["pair_phase_x"] = (
				enemies[7]["pair_phase_x"]
			)

			enemies[8]["pair_phase_y"] = (
				enemies[7]["pair_phase_y"]
			)

		# ------------------------------------------------------------
		# Normal enemies.
		# ------------------------------------------------------------

		for i in range(7):
			var enemy: Dictionary = enemies[i]

			if int(enemy.get("kill_state", 0)) != 0:
				continue

			var velocity: Vector2 = (
				enemy.get("move_velocity", Vector2.RIGHT * 40.0)
			)

			var steering := Vector2(
				sin(
					time * float(
						enemy.get("move_frequency_x", 0.35)
					)
					+ float(
						enemy.get("move_phase_x", 0.0)
					)
				),

				cos(
					time * float(
						enemy.get("move_frequency_y", 0.35)
					)
					+ float(
						enemy.get("move_phase_y", 0.0)
					)
				)
			)

			velocity += steering * 12.0 * delta

			var enemy_position: Vector2 = (
				enemy.get("position", arena.get_center())
			)

			var wall_force := Vector2.ZERO
			var wall_margin: float = 100.0

			if enemy_position.x < (
				arena.position.x + wall_margin
			):
				wall_force.x += 1.0

			elif enemy_position.x > (
				arena.end.x - wall_margin
			):
				wall_force.x -= 1.0

			if enemy_position.y < (
				arena.position.y + wall_margin
			):
				wall_force.y += 1.0

			elif enemy_position.y > (
				arena.end.y - wall_margin
			):
				wall_force.y -= 1.0

			velocity += wall_force * 80.0 * delta

			if velocity.length() < 0.001:
				velocity = Vector2.RIGHT * 40.0

			velocity = velocity.normalized() * 40.0

			enemy["move_velocity"] = velocity
			enemy["position"] = (
				enemy_position + velocity * delta
			)

		# ------------------------------------------------------------
		# Separate normal enemies.
		# ------------------------------------------------------------

		for i in range(7):
			if int(enemies[i].get("kill_state", 0)) != 0:
				continue

			for j in range(i + 1, 7):
				if int(enemies[j].get("kill_state", 0)) != 0:
					continue

				var first_enemy: Dictionary = enemies[i]
				var second_enemy: Dictionary = enemies[j]

				var first_position: Vector2 = (
					first_enemy.get("position", Vector2.ZERO)
				)

				var second_position: Vector2 = (
					second_enemy.get("position", Vector2.ZERO)
				)

				var offset: Vector2 = (
					second_position - first_position
				)

				var distance: float = offset.length()

				var minimum_distance: float = (
					float(
						first_enemy.get(
							"radius",
							ENEMY_RADIUS
						)
					)
					+
					float(
						second_enemy.get(
							"radius",
							ENEMY_RADIUS
						)
					)
					+ 20.0
				)

				if distance < minimum_distance:
					var direction := Vector2.RIGHT

					if distance > 0.001:
						direction = offset / distance

					var push_amount: float = (
						minimum_distance - distance
					) * 0.5

					first_enemy["position"] = (
						first_position
						- direction * push_amount
					)

					second_enemy["position"] = (
						second_position
						+ direction * push_amount
					)

		# ------------------------------------------------------------
		# Green pair.
		# ------------------------------------------------------------

		var green_a: Dictionary = enemies[7]
		var green_b: Dictionary = enemies[8]

		if int(green_a.get("kill_state", 0)) == 0:
			var pair_velocity: Vector2 = (
				green_a.get(
					"pair_velocity",
					Vector2.RIGHT * 35.0
				)
			)

			var pair_steering := Vector2(
				sin(
					time * 0.31
					+ float(
						green_a.get("pair_phase_x", 0.0)
					)
				),

				cos(
					time * 0.37
					+ float(
						green_a.get("pair_phase_y", 0.0)
					)
				)
			)

			pair_velocity += pair_steering * 14.0 * delta

			var pair_center: Vector2 = (
				green_a.get(
					"pair_center",
					arena.get_center()
				)
			)

			var pair_wall_force := Vector2.ZERO
			var pair_margin: float = 120.0

			if pair_center.x < (
				arena.position.x + pair_margin
			):
				pair_wall_force.x += 1.0

			elif pair_center.x > (
				arena.end.x - pair_margin
			):
				pair_wall_force.x -= 1.0

			if pair_center.y < (
				arena.position.y + pair_margin
			):
				pair_wall_force.y += 1.0

			elif pair_center.y > (
				arena.end.y - pair_margin
			):
				pair_wall_force.y -= 1.0

			pair_velocity += pair_wall_force * 90.0 * delta

			if pair_velocity.length() < 0.001:
				pair_velocity = Vector2.RIGHT * 36.0

			pair_velocity = (
				pair_velocity.normalized() * 36.0
			)

			pair_center += pair_velocity * delta

			green_a["pair_velocity"] = pair_velocity
			green_b["pair_velocity"] = pair_velocity

			green_a["pair_center"] = pair_center
			green_b["pair_center"] = pair_center

			var pair_angle: float = time * 0.45

			var pair_direction := Vector2.from_angle(
				pair_angle
			)

			var pair_spacing: float = (
				float(
					green_a.get("radius", ENEMY_RADIUS)
				)
				+
				float(
					green_b.get("radius", ENEMY_RADIUS)
				)
				+ 30.0
			)

			var pair_half_width: float = (
				pair_spacing * 0.5
				+
				float(
					green_a.get("radius", ENEMY_RADIUS)
				)
			)

			pair_center.x = clampf(
				pair_center.x,
				arena.position.x + pair_half_width,
				arena.end.x - pair_half_width
			)

			pair_center.y = clampf(
				pair_center.y,
				arena.position.y + pair_half_width,
				arena.end.y - pair_half_width
			)

			green_a["pair_center"] = pair_center
			green_b["pair_center"] = pair_center

			green_a["position"] = (
				pair_center
				- pair_direction
				* pair_spacing
				* 0.5
			)

			green_b["position"] = (
				pair_center
				+ pair_direction
				* pair_spacing
				* 0.5
			)


	# ----------------------------------------------------------------
	# LOOP / KILL SYSTEM
	# ----------------------------------------------------------------

	func _update_enemy_loops(delta: float) -> void:
		for enemy in enemies:
			var kill_state: int = int(
				enemy.get("kill_state", 0)
			)

			# --------------------------------------------------------
			# Knot animation.
			# --------------------------------------------------------

			if kill_state == 1:
				var progress: float = float(
					enemy.get("kill_progress", 0.0)
				)

				progress += delta / 0.65

				enemy["kill_progress"] = progress

				enemy["kill_rotation"] = (
					float(
						enemy.get("kill_rotation", 0.0)
					)
					+ delta * 10.0
				)

				if progress >= 1.0:
					enemy["kill_progress"] = 1.0
					enemy["kill_state"] = 2
					enemy["respawn_timer"] = 0.35

				continue

			# --------------------------------------------------------
			# Waiting before respawn.
			# --------------------------------------------------------

			if kill_state == 2:
				enemy["respawn_timer"] = (
					float(
						enemy.get("respawn_timer", 0.0)
					)
					- delta
				)

				if float(
					enemy.get("respawn_timer", 0.0)
				) <= 0.0:
					_respawn_enemy(enemy)

				continue

			# --------------------------------------------------------
			# Fade-in after respawn.
			# --------------------------------------------------------

			if kill_state == 3:
				var fade_alpha: float = (
					float(
						enemy.get("fade_alpha", 0.0)
					)
					+ delta / 0.8
				)

				enemy["fade_alpha"] = fade_alpha

				if fade_alpha >= 1.0:
					enemy["fade_alpha"] = 1.0
					enemy["kill_state"] = 0

				continue

			# --------------------------------------------------------
			# Normal winding tracking.
			# --------------------------------------------------------

			var offset: Vector2 = (
				player_position
				- enemy.get("position", Vector2.ZERO)
			)

			var distance: float = offset.length()

			var tracking_distance: float = (
				float(
					enemy.get("radius", ENEMY_RADIUS)
				)
				+ PLAYER_RADIUS
				+ 170.0
			)

			# Player has moved away from this enemy.
			if distance > tracking_distance:
				enemy["wind_angle"] = move_toward(
					float(
						enemy.get("wind_angle", 0.0)
					),
					0.0,
					delta * 1.5
				)

				enemy["tracking_loop"] = false
				enemy["last_player_angle"] = 0.0
				continue

			# Don't count the loop if the player is inside the enemy.
			if distance <= (
				float(
					enemy.get("radius", ENEMY_RADIUS)
				)
				+ PLAYER_RADIUS
				+ 8.0
			):
				continue

			var player_angle: float = offset.angle()

			if not bool(
				enemy.get("tracking_loop", false)
			):
				enemy["last_player_angle"] = player_angle
				enemy["tracking_loop"] = true
				continue

			var angle_change: float = angle_difference(
				float(
					enemy.get("last_player_angle", 0.0)
				),
				player_angle
			)

			enemy["wind_angle"] = (
				float(
					enemy.get("wind_angle", 0.0)
				)
				+ angle_change
			)

			enemy["last_player_angle"] = player_angle

			# One complete revolution in either direction.
			if absf(
				float(
					enemy.get("wind_angle", 0.0)
				)
			) >= TAU:
				_kill_enemy(enemy)


	func _kill_enemy(enemy: Dictionary) -> void:
		if int(enemy.get("kill_state", 0)) != 0:
			return

		# Green is a linked pair, so killing either kills both.
		if enemy == enemies[7] or enemy == enemies[8]:
			var green_a: Dictionary = enemies[7]
			var green_b: Dictionary = enemies[8]

			for green_enemy in [green_a, green_b]:
				green_enemy["kill_state"] = 1
				green_enemy["kill_progress"] = 0.0
				green_enemy["kill_rotation"] = 0.0
				green_enemy["wind_angle"] = 0.0
				green_enemy["tracking_loop"] = false

			return

		enemy["kill_state"] = 1
		enemy["kill_progress"] = 0.0
		enemy["kill_rotation"] = 0.0
		enemy["wind_angle"] = 0.0
		enemy["tracking_loop"] = false


	func _respawn_enemy(enemy: Dictionary) -> void:
		var new_position: Vector2 = (
			_find_respawn_position(enemy)
		)

		enemy["position"] = new_position

		enemy["fade_alpha"] = 0.0
		enemy["kill_progress"] = 0.0
		enemy["kill_rotation"] = 0.0
		enemy["wind_angle"] = 0.0
		enemy["last_player_angle"] = 0.0
		enemy["tracking_loop"] = false
		enemy["kill_state"] = 3

		var movement_direction := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)

		if movement_direction.length() < 0.001:
			movement_direction = Vector2.RIGHT

		enemy["move_velocity"] = (
			movement_direction.normalized()
			* randf_range(28.0, 48.0)
		)

		enemy["move_phase_x"] = randf_range(0.0, TAU)
		enemy["move_phase_y"] = randf_range(0.0, TAU)

		# Green pair respawns together.
		if enemy == enemies[7] or enemy == enemies[8]:
			var green_center: Vector2 = new_position

			var green_a: Dictionary = enemies[7]
			var green_b: Dictionary = enemies[8]

			green_a["pair_center"] = green_center
			green_b["pair_center"] = green_center

			var pair_direction := Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			)

			if pair_direction.length() < 0.001:
				pair_direction = Vector2.RIGHT

			green_a["pair_velocity"] = (
				pair_direction.normalized() * 35.0
			)

			green_b["pair_velocity"] = (
				pair_direction.normalized() * 35.0
			)

			green_a["kill_state"] = 3
			green_b["kill_state"] = 3

			green_a["fade_alpha"] = 0.0
			green_b["fade_alpha"] = 0.0

			green_a["kill_progress"] = 0.0
			green_b["kill_progress"] = 0.0

			green_a["kill_rotation"] = 0.0
			green_b["kill_rotation"] = 0.0

			green_a["wind_angle"] = 0.0
			green_b["wind_angle"] = 0.0

			green_a["tracking_loop"] = false
			green_b["tracking_loop"] = false


	func _find_respawn_position(enemy: Dictionary) -> Vector2:
		var margin: float = 90.0
		var minimum_player_distance: float = 320.0
		var minimum_enemy_distance: float = 100.0

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

			if candidate.distance_to(
				player_position
			) < minimum_player_distance:
				continue

			var valid: bool = true

			for other in enemies:
				if other == enemy:
					continue

				if int(
					other.get("kill_state", 0)
				) != 0:
					continue

				var other_position: Vector2 = (
					other.get("position", Vector2.ZERO)
				)

				if candidate.distance_to(
					other_position
				) < minimum_enemy_distance:
					valid = false
					break

			if valid:
				return candidate

		# Fallback: pick the point farthest from the player.
		var best_position: Vector2 = arena.get_center()
		var best_distance: float = -1.0

		for attempt in range(12):
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

			var candidate_distance: float = (
				candidate.distance_to(player_position)
			)

			if candidate_distance > best_distance:
				best_distance = candidate_distance
				best_position = candidate

		return best_position


	# ----------------------------------------------------------------
	# DRAWING
	# ----------------------------------------------------------------

	func _draw() -> void:
		# Arena border.
		draw_rect(
			arena,
			Color(1.0, 1.0, 1.0, 0.18),
			false,
			2.0
		)

		var center: Vector2 = arena.get_center()

		# Subtle arena cross-lines.
		draw_line(
			Vector2(
				arena.position.x,
				center.y
			),

			Vector2(
				arena.end.x,
				center.y
			),

			Color(1.0, 1.0, 1.0, 0.025),
			1.0
		)

		draw_line(
			Vector2(
				center.x,
				arena.position.y
			),

			Vector2(
				center.x,
				arena.end.y
			),

			Color(1.0, 1.0, 1.0, 0.025
			),
			1.0
		)

		# ------------------------------------------------------------
		# Green pair connection.
		# ------------------------------------------------------------

		var green_a: Dictionary = enemies[7]
		var green_b: Dictionary = enemies[8]

		var green_a_state: int = int(
			green_a.get("kill_state", 0)
		)

		var green_b_state: int = int(
			green_b.get("kill_state", 0)
		)

		if (
			green_a_state == 0
			or green_a_state == 3
		) and (
			green_b_state == 0
			or green_b_state == 3
		):
			var green_a_position: Vector2 = (
				green_a.get("position", Vector2.ZERO)
			)

			var green_b_position: Vector2 = (
				green_b.get("position", Vector2.ZERO)
			)

			var to_partner: Vector2 = (
				green_b_position
				- green_a_position
			)

			if to_partner.length() > 0.001:
				var heading: Vector2 = (
					to_partner.normalized()
				)

				var start: Vector2 = (
					green_a_position
					+ heading
					* float(
						green_a.get(
							"radius",
							ENEMY_RADIUS
						)
					)
				)

				var end: Vector2 = (
					green_b_position
					- heading
					* float(
						green_b.get(
							"radius",
							ENEMY_RADIUS
						)
					)
				)

				var connection_alpha: float = minf(
					float(
						green_a.get(
							"fade_alpha",
							1.0
						)
					),

					float(
						green_b.get(
							"fade_alpha",
							1.0
						)
					)
				)

				var green_color: Color = (
					green_a.get(
						"color",
						Color(0.6, 1.0, 0.5)
					)
				)

				draw_dashed_line(
					start,
					end,
					Color(
						green_color,
						0.5 * connection_alpha
					),
					2.0,
					8.0
				)

		# ------------------------------------------------------------
		# Enemies.
		# ------------------------------------------------------------

		for enemy in enemies:
			# IMPORTANT:
			# Always use get() here because _draw() can happen
			# before _process() has initialized runtime values.
			var kill_state: int = int(
				enemy.get("kill_state", 0)
			)

			if kill_state == 2:
				continue

			var enemy_position: Vector2 = (
				enemy.get(
					"position",
					Vector2.ZERO
				)
			)

			var enemy_radius: float = float(
				enemy.get(
					"radius",
					ENEMY_RADIUS
				)
			)

			var enemy_color: Color = (
				enemy.get(
					"color",
					Color.WHITE
				)
			)

			var fade_alpha: float = float(
				enemy.get(
					"fade_alpha",
					1.0
				)
			)

			# --------------------------------------------------------
			# Normal / fading enemy.
			# --------------------------------------------------------

			if kill_state == 0 or kill_state == 3:
				var body_color := Color(
					enemy_color.r,
					enemy_color.g,
					enemy_color.b,
					fade_alpha
				)

				var dark_color_base: Color = (
					enemy_color.darkened(0.6)
				)

				var dark_color := Color(
					dark_color_base.r,
					dark_color_base.g,
					dark_color_base.b,
					fade_alpha
				)

				draw_circle(
					enemy_position,
					enemy_radius,
					dark_color
				)

				draw_arc(
					enemy_position,
					enemy_radius,
					0.0,
					TAU,
					32,
					body_color,
					2.0
				)

				continue

			# --------------------------------------------------------
			# Knot / death animation.
			# --------------------------------------------------------

			if kill_state == 1:
				var progress: float = float(
					enemy.get(
						"kill_progress",
						0.0
					)
				)

				var spin_angle: float = float(
					enemy.get(
						"kill_rotation",
						0.0
					)
				)

				var animated_scale: float = (
					1.0
					+ sin(progress * PI) * 0.18
				)

				var animated_radius: float = (
					enemy_radius * animated_scale
				)

				var knot_alpha: float = (
					1.0 - progress * 0.75
				)

				var animated_color := Color(
					enemy_color.r,
					enemy_color.g,
					enemy_color.b,
					knot_alpha
				)

				var dark_color_base: Color = (
					enemy_color.darkened(0.6)
				)

				var animated_dark_color := Color(
					dark_color_base.r,
					dark_color_base.g,
					dark_color_base.b,
					knot_alpha
				)

				# Main body.
				draw_circle(
					enemy_position,
					animated_radius,
					animated_dark_color
				)

				# Rotating knot-like rings.
				for ring in range(3):
					var ring_progress: float = (
						float(ring) / 3.0
					)

					var ring_radius: float = (
						animated_radius
						* (
							0.45
							+ ring_progress * 0.45
						)
					)

					var start_angle: float = (
						spin_angle
						+ ring_progress
						* TAU
						/ 3.0
					)

					var sweep: float = (
						TAU
						* (
							0.72
							+ progress * 0.2
						)
					)

					draw_arc(
						enemy_position,
						ring_radius,
						start_angle,
						start_angle + sweep,
						24,
						animated_color,
						2.5
					)

				# Outer rotating outline.
				draw_arc(
					enemy_position,
					animated_radius,
					spin_angle,
					spin_angle + TAU,
					32,
					animated_color,
					2.0
				)

		# ------------------------------------------------------------
		# Player.
		# ------------------------------------------------------------

		draw_circle(
			player_position,
			PLAYER_RADIUS,
			THREAD_COLOR
		)
