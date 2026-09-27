class_name Droppable
extends Resource
## One entry of a DropTable: an item scene and how likely it is compared to the other entries.

## The values are weights. With every rarity in a table, they add up to 100, so they read as percentages.
enum Rarity
{
	COMMON = 55,
	UNCOMMON = 20,
	RARE = 15,
	EPIC = 8,
	LEGENDARY = 2
}

@export var rarity: Rarity = Rarity.COMMON
## The scene to drop. Its root is usually an Area2D with an Item child.
@export var item_scene: PackedScene
## Optional. Multiplies the rarity weight per wave, e.g. to make an item likelier in later waves.
@export var wave_weight: WaveWeight = null


## The rarity weight on the given wave, times Wave Weight if set.
func get_weight(wave: int) -> float:
	return int(rarity) * WeightedRandom.weight_of(wave_weight, wave)
