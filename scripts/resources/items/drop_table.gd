class_name DropTable
extends Resource
## What an enemy can drop when it's knotted. Assign one per enemy scene so each type drops different things.

## Chance that anything drops at all.
@export_range(0.0, 1.0) var drop_chance: float = 0.3
## Picked from by weight when something drops.
@export var drops: Array[Droppable] = []


## Returns the item scene to drop on the given wave, or null if nothing drops this time.
func roll(wave: int) -> PackedScene:
	if drops.is_empty() or randf() >= drop_chance:
		return null

	var weights := PackedFloat32Array()
	for droppable: Droppable in drops:
		weights.append(droppable.get_weight(wave) if droppable else 0.0)

	var index: int = WeightedRandom.pick_index(weights)
	return drops[index].item_scene if index >= 0 else null
