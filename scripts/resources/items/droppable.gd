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

var weight: int:
	get:
		return int(rarity)
