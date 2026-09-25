extends Node
## Autoload for game flow: scene changes, pausing, quitting and save data.

signal pause_changed(is_paused: bool)
signal scene_changing(path: String)

const SAVE_PATH: String = "user://game_data.tres"

var game_data: GameData

var is_paused: bool:
	get:
		return get_tree().paused


func _enter_tree() -> void:
	# Pause and quit handling must work while the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_data()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game_data()


func change_scene(path: String) -> void:
	scene_changing.emit(path)
	set_paused(false)
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("MainManager: couldn't load scene '%s' (%s)" % [path, error_string(error)])


func change_scene_to_packed(scene: PackedScene) -> void:
	scene_changing.emit(scene.resource_path)
	set_paused(false)
	get_tree().change_scene_to_packed(scene)


func reload_scene() -> void:
	set_paused(false)
	get_tree().reload_current_scene()


func set_paused(paused: bool) -> void:
	if get_tree().paused == paused:
		return

	get_tree().paused = paused
	pause_changed.emit(paused)


func pause_game() -> void:
	set_paused(true)


func resume_game() -> void:
	set_paused(false)


func toggle_pause() -> void:
	set_paused(not get_tree().paused)


func quit_game() -> void:
	save_game_data()
	get_tree().quit()


func save_game_data() -> void:
	var error: Error = ResourceSaver.save(game_data, SAVE_PATH)
	if error != OK:
		push_error("MainManager: couldn't save game data (%s)" % error_string(error))


func load_game_data() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		game_data = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GameData

	if game_data == null:
		reset_game_data()


func reset_game_data() -> void:
	game_data = GameData.new()
