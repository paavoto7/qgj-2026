extends Node
## Autoload for music, UI sounds and one-shot SFX. Per-object looping sounds should use their own AudioStreamPlayer.
##
## Uses the Music, SFX and UI buses if they exist in the audio bus layout, otherwise Master.

const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const UI_BUS: StringName = &"UI"

## How many one-shot sounds of each kind can play at the same time before the oldest is cut off.
const POOL_SIZE: int = 8

var _music_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_2d_pool: Array[AudioStreamPlayer2D] = []
var _sfx_3d_pool: Array[AudioStreamPlayer3D] = []
var _music_tween: Tween

var loaded: bool = false

func _ready() -> void:
	# UI sounds and music keep playing while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _get_bus(MUSIC_BUS)
	add_child(_music_player)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = _get_bus(UI_BUS)
	add_child(_ui_player)

	for i in POOL_SIZE:
		_sfx_pool.append(_add_pooled_player(AudioStreamPlayer.new()))
		_sfx_2d_pool.append(_add_pooled_player(AudioStreamPlayer2D.new()))
		_sfx_3d_pool.append(_add_pooled_player(AudioStreamPlayer3D.new()))
	
	loaded = true


func _exit_tree() -> void:
	loaded = false


## Plays music, cross-fading from the current track if fade_time > 0. Does nothing if the stream is already playing.
func play_music(stream: AudioStream, fade_time: float = 0.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if _music_player.stream == stream and _music_player.playing:
		return

	_kill_music_tween()
	if fade_time <= 0.0 or not _music_player.playing:
		_music_player.stream = stream
		_music_player.volume_db = volume_db if fade_time <= 0.0 else -80.0
		_music_player.play()
		if fade_time > 0.0:
			_music_tween = _create_music_tween()
			_music_tween.tween_property(_music_player, "volume_db", volume_db, fade_time)
		return

	_music_tween = _create_music_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_time * 0.5)
	_music_tween.tween_callback(func() -> void:
		_music_player.stream = stream
		_music_player.play()
	)
	_music_tween.tween_property(_music_player, "volume_db", volume_db, fade_time * 0.5)


func stop_music(fade_time: float = 0.0) -> void:
	_kill_music_tween()
	if fade_time <= 0.0:
		_music_player.stop()
		return

	_music_tween = _create_music_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
	_music_tween.tween_callback(_music_player.stop)


## Toggles music playback, e.g. when pausing or resuming the game.
func set_music_playing(playing: bool) -> void:
	if playing == _music_player.playing:
		return
	if playing:
		_music_player.stream_paused = false
	else:
		_music_player.stream_paused = true


func play_ui(stream: AudioStream) -> void:
	if stream == null:
		return

	_ui_player.stream = stream
	_ui_player.play()


## Plays a non-positional one-shot sound.
## Set ignore_pause for sounds that trigger a pause right away (e.g. a death sound before the game over screen),
## otherwise they freeze until the game resumes.
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0, ignore_pause: bool = false) -> void:
	if stream == null:
		return

	var player: AudioStreamPlayer = _next_free(_sfx_pool)
	_start(player, stream, volume_db, pitch_scale, ignore_pause)


func play_sfx_2d(stream: AudioStream, position: Vector2, volume_db: float = 0.0, pitch_scale: float = 1.0, ignore_pause: bool = false) -> void:
	if stream == null:
		return

	var player: AudioStreamPlayer2D = _next_free(_sfx_2d_pool)
	player.global_position = position
	_start(player, stream, volume_db, pitch_scale, ignore_pause)


func play_sfx_3d(stream: AudioStream, position: Vector3, volume_db: float = 0.0, pitch_scale: float = 1.0, ignore_pause: bool = false) -> void:
	if stream == null:
		return

	var player: AudioStreamPlayer3D = _next_free(_sfx_3d_pool)
	player.global_position = position
	_start(player, stream, volume_db, pitch_scale, ignore_pause)


func _add_pooled_player(player: Node) -> Node:
	player.bus = _get_bus(SFX_BUS)
	# One-shot SFX pause with the game, unlike music and UI
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	return player


## Returns a player that isn't playing, or the one that was started first if all are busy.
func _next_free(pool: Array) -> Node:
	for player: Node in pool:
		if not player.playing:
			return player

	var oldest: Node = pool.pop_front()
	pool.push_back(oldest)
	return oldest


func _start(player: Node, stream: AudioStream, volume_db: float, pitch_scale: float, ignore_pause: bool) -> void:
	player.process_mode = Node.PROCESS_MODE_ALWAYS if ignore_pause else Node.PROCESS_MODE_PAUSABLE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _get_bus(bus: StringName) -> StringName:
	return bus if AudioServer.get_bus_index(bus) != -1 else &"Master"


func _create_music_tween() -> Tween:
	return create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)


func _kill_music_tween() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
