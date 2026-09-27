class_name WaveData
extends Resource
## One wave of enemies. Each entry is an enemy scene or a group scene whose children are enemies.

@export var enemies: Array[PackedScene] = []
## Optional text shown on the HUD during this wave, e.g. a tutorial hint.
@export_multiline var hint: String = ""
@export var is_test_wave: bool = false
