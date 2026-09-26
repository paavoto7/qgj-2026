class_name ArenaData
extends Resource

@export var ARENA_MARGIN: float = 24.0
@export var SPAWN_MARGIN: float = 40.0
@export var SPAWN_MIN_DISTANCE: float = 260.0
## Seconds after a knot during which the next knot raises the combo.
@export var COMBO_WINDOW: float = 3.0

@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var player_scene: PackedScene
## Scripted opening waves, played in order.
@export var waves: Array[WaveData] = []
## Enemy or group scenes that random waves pick from after the scripted waves.
@export var random_enemies: Array[PackedScene] = []
@export var max_random_enemies: int = 6
