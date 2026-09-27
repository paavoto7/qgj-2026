class_name OverlayMenu
extends MenuBase
## A menu shown over the dimmed game, e.g. the pause menu or game over screen.
## The scene needs a full-screen %Dim and a %Center holding the content. open() fades them in.

## How far the content slides up while fading in.
const INTRO_OFFSET: float = 12.0

@export var fade_time: float = 0.4

@onready var _dim: Control = %Dim
@onready var _center: Control = %Center


func open() -> void:
	super()
	AudioManager.set_music_playing(false)
	_play_intro()


## Fades the dim in, then slides the content up while fading it in.
func _play_intro() -> void:
	# Set up front, a delayed tweener only reads its start value once its delay ends
	_dim.modulate.a = 0.0
	_center.modulate.a = 0.0
	_center.position.y = INTRO_OFFSET

	var tween := create_tween()
	# The game is usually paused while an overlay is open
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_dim, "modulate:a", 1.0, fade_time)
	tween.tween_property(_center, "modulate:a", 1.0, fade_time).set_delay(fade_time * 0.5)
	tween.tween_property(_center, "position:y", 0.0, fade_time).set_delay(fade_time * 0.5)
