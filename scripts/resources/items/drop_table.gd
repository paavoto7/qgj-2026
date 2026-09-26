class_name DropTable
extends Resource
## What an enemy can drop when it's knotted. Assign one per enemy scene so each type drops different things.

## Chance that anything drops at all.
@export_range(0.0, 1.0) var drop_chance: float = 0.3
## Picked from by rarity weight when something drops.
@export var drops: Array[Droppable] = []


## Returns the item scene to drop, or null if nothing drops this time.
func roll() -> PackedScene:
	if drops.is_empty() or randf() >= drop_chance:
		return null

	var total: int = 0
	for droppable: Droppable in drops:
		if droppable:
			total += droppable.weight
	if total <= 0:
		return null

	var pick: int = randi_range(1, total)
	for droppable: Droppable in drops:
		if not droppable:
			continue
		pick -= droppable.weight
		if pick <= 0:
			return droppable.item_scene

	return null
