class_name SpawnEntry
extends Resource
## An enemy or group scene that random waves can pick, and how likely it is on each wave.

@export var scene: PackedScene
## Empty means a weight of 1 on every wave.
@export var weight: WaveWeight = null
