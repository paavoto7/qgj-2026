class_name HUD
extends Control


@onready var _score_label: Label = get_node("ScoreLabel") as Label
#@onready var _combo_label: Label = get_node("ComboLabel") as Label
@onready var _game_over_screen: GameOverScreen = get_node("GameOverScreen") as GameOverScreen
@onready var _arena: Arena = get_parent() as Arena


var _wave: WaveData
var _wave_number: int = 0
var _score: int = 0
var _combo: int = 0
var _player_health: int


func _ready() -> void:
	_arena.setup_hud.connect(setup_hud)


# Called when the node enters the scene tree for the first time.
func setup_hud(bounds: Vector2, player_health: int) -> void:
	_game_over_screen.hide()
	_player_health = player_health

	set_scorelabel_position(bounds)

	_arena._player.health.died.connect(_game_over_screen.open)
	_arena.wave_changed.connect(_on_wave_changed)
	_arena.score_changed.connect(_on_score_changed)
	_arena._player.health.health_changed.connect(_on_player_health_changed)


func set_scorelabel_position(label_pos: Vector2) -> void:
	_score_label.position = label_pos


func _on_wave_changed(wave_data: WaveData, wave_number: int) -> void:
	_wave = wave_data
	_wave_number = wave_number
	_update_hud()


func _on_score_changed(score: int) -> void:
	_score = score
	_update_hud()


func _on_player_health_changed(current: int, _maximum: int) -> void:
	_player_health = current
	_update_hud()


func _update_hud() -> void:
	var text: String = "Wave %d    Score %d    HP %d" % [_wave_number, _score, _player_health]
	if _combo > 1:
		text += "    x%d combo!" % _combo
	if _wave and not _wave.hint.is_empty():
		text += "\n" + _wave.hint
	_score_label.text = text
