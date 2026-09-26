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
const ENEMY_COLORS := [
	Color(0.85, 0.18, 0.18),
	Color(0.25, 0.45, 0.95),
	Color(0.65, 0.25, 0.8),
	Color(0.95, 0.55, 0.15),
]

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

	# Make the button scale from its center.
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
	var player_position := Vector2.ZERO
	var player_velocity := Vector2(1.0, 0.0)

	var time := 0.0
	var arena := Rect2()

	var enemies := [
		{
			"position": Vector2.ZERO,
			"color": Color(0.9, 0.15, 0.15),
			"radius": 55.0 / 3,
			"phase": 0.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.2, 0.4, 1.0),
			"radius": 55.0 / 3,
			"phase": 1.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.65, 0.2, 0.85),
			"radius": 55.0 / 3,
			"phase": 2.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(1.0, 0.55, 0.1),
			"radius": 55.0 / 3,
			"phase": 3.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(1.0, 0.85, 0.4),
			"radius": 55.0 / 3,
			"phase": 4.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color.BLACK,
			"radius": 55 / 6,
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
			"radius": 55.0 / 3,
			"phase": 7.0,
		},
		{
			"position": Vector2.ZERO,
			"color": Color(0.6, 1.0, 0.5),
			"radius": 55.0 / 3,
			"phase": 7.0,
		},
	]


	func _ready() -> void:
		top_level = true
		global_transform = Transform2D.IDENTITY

		thread = ThreadTrail.new()
		add_child(thread)

		queue_redraw()


	func _process(delta: float) -> void:
		time += delta

		var size := get_viewport_rect().size
		arena = Rect2(
			Vector2(ARENA_MARGIN, ARENA_MARGIN),
			size - Vector2(ARENA_MARGIN * 2.0, ARENA_MARGIN * 2.0)
		)

		# Keep the decorative gameplay area behind the UI.
		_update_player(delta)
		_update_enemies()

		queue_redraw()


	func _update_player(delta: float) -> void:
		if player_position == Vector2.ZERO:
			player_position = arena.get_center() + Vector2(-180.0, 90.0)

		var desired_direction := Vector2(
			cos(time * 0.63),
			sin(time * 0.91)
		).normalized()

		# ---------------------------------------------------------------
		# Enemy avoidance
		# ---------------------------------------------------------------

		var avoidance := Vector2.ZERO

		for enemy in enemies:
			var offset: Vector2 = player_position - enemy.position
			var distance: float = offset.length()

			var safe_distance: float = enemy.radius + PLAYER_RADIUS + 85.0

			if distance < safe_distance and distance > 0.001:
				var strength: float = 1.0 - (distance / safe_distance)

				avoidance += offset.normalized() * strength * strength

		# Smooth the avoidance direction instead of allowing it to
		# instantly flip when enemies move around the player.
		if avoidance.length() > 0.001:
			desired_direction = (
				desired_direction * 0.65
				+ avoidance.normalized() * 0.75
			).normalized()

		# ---------------------------------------------------------------
		# Smooth player movement
		# ---------------------------------------------------------------

		var desired_velocity := desired_direction * 150.0

		player_velocity = player_velocity.lerp(
			desired_velocity,
			1.5 * delta
		)

		player_position += player_velocity * delta

		# ---------------------------------------------------------------
		# Soft wall avoidance
		# ---------------------------------------------------------------

		var wall_margin: float = 70.0
		var wall_avoidance := Vector2.ZERO

		if player_position.x < arena.position.x + wall_margin:
			var strength: float = 1.0 - (
				(player_position.x - arena.position.x) / wall_margin
			)
			wall_avoidance.x += strength

		elif player_position.x > arena.end.x - wall_margin:
			var strength: float = 1.0 - (
				(arena.end.x - player_position.x) / wall_margin
			)
			wall_avoidance.x -= strength

		if player_position.y < arena.position.y + wall_margin:
			var strength: float = 1.0 - (
				(player_position.y - arena.position.y) / wall_margin
			)
			wall_avoidance.y += strength

		elif player_position.y > arena.end.y - wall_margin:
			var strength: float = 1.0 - (
				(arena.end.y - player_position.y) / wall_margin
			)
			wall_avoidance.y -= strength

		if wall_avoidance.length() > 0.001:
			desired_velocity += wall_avoidance.normalized() * 100.0

			player_velocity = player_velocity.lerp(
				desired_velocity,
				1.5 * delta
			)

		player_position += player_velocity * delta

		# ---------------------------------------------------------------
		# Keep player inside arena
		# ---------------------------------------------------------------

		player_position.x = clampf(
			player_position.x,
			arena.position.x + PLAYER_RADIUS,
			arena.end.x - PLAYER_RADIUS
		)

		player_position.y = clampf(
			player_position.y,
			arena.position.y + PLAYER_RADIUS,
			arena.end.y - PLAYER_RADIUS
		)

		thread.add_point(player_position)


	func _update_enemies() -> void:
		var delta := get_process_delta_time()

		# ---------------------------------------------------------------
		# Initialize movement state once.
		# ---------------------------------------------------------------

		if not enemies[0].has("move_velocity"):
			var margin := 70.0

			for i in enemies.size():
				var enemy = enemies[i]

				# Give every enemy a deliberately different starting position.
				# This spreads them across the whole rectangular arena.
				var columns := 3
				var rows := 3

				var column := i % columns
				var row := i / columns

				var cell_width := (arena.size.x - margin * 2.0) / float(columns)
				var cell_height := (arena.size.y - margin * 2.0) / float(rows)

				var base_position := Vector2(
					arena.position.x + margin + cell_width * (float(column) + 0.5),
					arena.position.y + margin + cell_height * (float(row) + 0.5)
				)

				# Small random offset so it doesn't look like a grid.
				base_position += Vector2(
					randf_range(-70.0, 70.0),
					randf_range(-70.0, 70.0)
				)

				enemy.position = base_position

				# Each enemy gets a stable velocity.
				enemy["move_velocity"] = Vector2(
					randf_range(-1.0, 1.0),
					randf_range(-1.0, 1.0)
				).normalized() * randf_range(28.0, 48.0)

				# Different slow steering phases/frequencies.
				enemy["move_phase_x"] = randf_range(0.0, TAU)
				enemy["move_phase_y"] = randf_range(0.0, TAU)
				enemy["move_frequency_x"] = randf_range(0.25, 0.42)
				enemy["move_frequency_y"] = randf_range(0.28, 0.46)

			# Green pair gets its own independent smooth movement.
			enemies[7]["pair_center"] = enemies[7].position
			enemies[8]["pair_center"] = enemies[7].position

			enemies[7]["pair_velocity"] = Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			).normalized() * 35.0

			enemies[7]["pair_phase_x"] = randf_range(0.0, TAU)
			enemies[7]["pair_phase_y"] = randf_range(0.0, TAU)

		# ---------------------------------------------------------------
		# Normal enemies
		# ---------------------------------------------------------------

		for i in range(7):
			var enemy = enemies[i]

			var velocity: Vector2 = enemy["move_velocity"]

			# Very slow continuous steering.
			# This changes direction without changing speed abruptly.
			var steering := Vector2(
				sin(time * enemy["move_frequency_x"] + enemy["move_phase_x"]),
				cos(time * enemy["move_frequency_y"] + enemy["move_phase_y"])
			)

			velocity += steering * 12.0 * delta

			# Wall steering.
			# This bends their path before they hit the edge instead of
			# clamping them and causing ugly direction changes.
			var position: Vector2 = enemy.position
			var wall_force := Vector2.ZERO
			var wall_margin := 100.0

			if position.x < arena.position.x + wall_margin:
				wall_force.x += 1.0
			elif position.x > arena.end.x - wall_margin:
				wall_force.x -= 1.0

			if position.y < arena.position.y + wall_margin:
				wall_force.y += 1.0
			elif position.y > arena.end.y - wall_margin:
				wall_force.y -= 1.0

			velocity += wall_force * 80.0 * delta

			# Keep speed stable.
			velocity = velocity.normalized() * 40.0

			enemy["move_velocity"] = velocity
			enemy.position += velocity * delta

		# ---------------------------------------------------------------
		# Separate enemies so they don't overlap.
		# ---------------------------------------------------------------

		for i in range(7):
			for j in range(i + 1, 7):
				var a = enemies[i]
				var b = enemies[j]

				var offset: Vector2 = b.position - a.position
				var distance := offset.length()
				var minimum_distance: float = a.radius + b.radius + 20.0

				if distance < minimum_distance:
					var direction := Vector2.RIGHT

					if distance > 0.001:
						direction = offset / distance

					var push_amount := (minimum_distance - distance) * 0.5

					a.position -= direction * push_amount
					b.position += direction * push_amount

		# ---------------------------------------------------------------
		# Green pair
		# ---------------------------------------------------------------

		var green_a = enemies[7]
		var green_b = enemies[8]

		var pair_velocity: Vector2 = green_a["pair_velocity"]

		var pair_steering := Vector2(
			sin(time * 0.31 + green_a["pair_phase_x"]),
			cos(time * 0.37 + green_a["pair_phase_y"])
		)

		pair_velocity += pair_steering * 14.0 * delta

		# Smooth wall avoidance for the entire pair.
		var pair_center: Vector2 = green_a["pair_center"]
		var pair_wall_force := Vector2.ZERO
		var pair_margin := 120.0

		if pair_center.x < arena.position.x + pair_margin:
			pair_wall_force.x += 1.0
		elif pair_center.x > arena.end.x - pair_margin:
			pair_wall_force.x -= 1.0

		if pair_center.y < arena.position.y + pair_margin:
			pair_wall_force.y += 1.0
		elif pair_center.y > arena.end.y - pair_margin:
			pair_wall_force.y -= 1.0

		pair_velocity += pair_wall_force * 90.0 * delta
		pair_velocity = pair_velocity.normalized() * 36.0

		pair_center += pair_velocity * delta

		green_a["pair_velocity"] = pair_velocity
		green_a["pair_center"] = pair_center
		green_b["pair_center"] = pair_center

		# Rotate the pair around its own center.
		# This is rotation, NOT orbital movement around the arena.
		var pair_angle := time * 0.45
		var pair_direction := Vector2.from_angle(pair_angle)

		var pair_spacing: float = green_a.radius + green_b.radius + 30.0

		green_a.position = pair_center - pair_direction * pair_spacing * 0.5
		green_b.position = pair_center + pair_direction * pair_spacing * 0.5

		# Keep the pair itself inside the arena.
		var pair_half_width: float = pair_spacing * 0.5 + green_a.radius

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

		green_a.position = pair_center - pair_direction * pair_spacing * 0.5
		green_b.position = pair_center + pair_direction * pair_spacing * 0.5


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

		# Green pair connection, matching PairedType's visual language.
		var green_a = enemies[7]
		var green_b = enemies[8]

		var to_partner: Vector2 = green_b.position - green_a.position
		var heading: Vector2 = to_partner.normalized()

		var start: Vector2 = green_a.position + heading * green_a.radius
		var end: Vector2 = green_b.position - heading * green_b.radius

		draw_dashed_line(
			start,
			end,
			Color(green_a.color, 0.5),
			2.0,
			8.0
		)

		# Enemies.
		for enemy in enemies:
			var position: Vector2 = enemy.position
			var radius: float = enemy.radius
			var color: Color = enemy.color

			draw_circle(
				position,
				radius,
				color.darkened(0.6)
			)

			draw_arc(
				position,
				radius,
				0.0,
				TAU,
				32,
				color,
				2.0
			)

		# Player.
		draw_circle(
			player_position,
			PLAYER_RADIUS,
			THREAD_COLOR
		)
