class_name ArenaData
extends Resource
## Settings for one arena: the player, the waves and the spacing rules. Assign it to the Arena node.

@export var arena_margin: float = 24.0
@export var spawn_margin: float = 40.0
@export var spawn_min_distance: float = 260.0
## Seconds after a knot during which the next knot raises the combo.
@export var combo_window: float = 3.0

@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var player_scene: PackedScene
## Scripted opening waves, played in order.
@export var waves: Array[WaveData] = []
## Enemy or group scenes that random waves pick from after the scripted waves.
@export var random_enemies: Array[PackedScene] = []
@export var max_random_enemies: int = 6
