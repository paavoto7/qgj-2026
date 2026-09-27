# Items, powerups and drops
How enemies drop items, how the player collects them and how to add new powerups. Everything except a new powerup or item kind is done in the editor, without code.

## How it fits together
- **`Item`** (`scripts/interaction/Item/item.gd`) is a pickup. It extends `Interactable`, so like any interactable it's a child node of an `Area2D`. It's collected on touch (*Interact On Touch* and *One Shot* are on by default), then frees its area. *Lifetime* (10 s by default, 0 or less = forever) makes it disappear if nobody collects it, fading out over the last *Fade Time* seconds.
- **`Powerup`** (`scripts/interaction/Item/powerup.gd`) is the `Item` that gives the player a powerup. It shows the powerup's sprite and colour on a sibling `Sprite2D`. Its scene is `scenes/item/powerup.tscn`.
- **`PowerupData`** (`scripts/resources/items/powerup_data.gd`) is a Resource that describes what a powerup does, with *Name*, *Sprite*, *Color* and *Duration* (0 = instant). It's abstract: every powerup is a script that extends it. The powerups are in `scripts/resources/items/powerups/`:

  | Powerup | Effect |
  | --- | --- |
  | `HealPowerup` | Instant. Heals *Amount* health. |
  | `SpeedPowerup` | Timed, 5 s by default. Multiplies the player's speed by *Multiplier* (1.5 by default). |
  | `ShieldPowerup` | Timed, 5 s by default. The player can't be damaged, so hits don't snap the thread. |

- **`Powerups`** (`scripts/components/powerups.gd`) is a component, a child node of the `Player`. It applies powerups and removes timed ones when they run out. Picking up a powerup that's already active restarts its timer instead of stacking it. It emits `powerup_added` and `powerup_expired`, e.g. for the HUD, and clears everything when the player dies.
- **The player** needs an `Interactor` under its `HitBox` to collect items, and a `Powerups` child for powerups. The item's `Area2D` goes on collision layer 4 (interactable), which the `HitBox` already masks.
- **`Droppable`** (`scripts/resources/items/droppable.gd`) is a Resource with an item scene, its *Rarity* and an optional *Wave Weight*.
- **`DropTable`** (`scripts/resources/items/drop_table.gd`) is a Resource with a *Drop Chance* and a list of *Drops*. Each enemy scene has its own, set on the root `Enemy` node's *Drop Table*, so different enemies can drop different things. No table means the enemy drops nothing.

When an enemy is knotted it rolls its table. A dropped item goes up through the `WaveSpawner` (`item_dropped`) to the `Arena`, which adds it where the enemy was, inside the arena border.

## How drop chances work
A roll has two steps:
1. **Does anything drop?** *Drop Chance* on the enemy's `DropTable` decides, e.g. 0.3 = 30% of knots.
2. **Which item?** One of the *Drops* is picked by rarity weight:

   | Rarity | Weight |
   | --- | --- |
   | Common | 55 |
   | Uncommon | 20 |
   | Rare | 15 |
   | Epic | 8 |
   | Legendary | 2 |

The weights are relative to the other entries in the same table, not fixed percentages. An entry's chance is its weight divided by the total weight of the table. They only read as percentages when a table has one entry of each rarity, since those add up to 100.

For example, a table with *Drop Chance* 0.3, a Common heal and a Rare shield has a total weight of 55 + 15 = 70:

| Item | Share of drops | Chance per knot |
| --- | --- | --- |
| Heal | 55 / 70 ≈ 79% | 0.3 × 79% ≈ 24% |
| Shield | 15 / 70 ≈ 21% | 0.3 × 21% ≈ 6% |

So adding more entries makes each existing one rarer, and a table with a single entry always drops that entry when something drops, whatever its rarity. The same item can be in a table more than once to raise its share.

To change the odds over the waves, give a `Droppable` a *Wave Weight*. Its value for the enemy's wave multiplies the rarity weight, e.g. a Legendary with *Weight* 1 and *Per Wave* 0.5 counts as 2 on wave 1 and 20 on wave 19, and *From Wave* 5 makes it never drop before wave 5. Empty means ×1. See [Wave-based weights](ENEMIES_AND_WAVES.md#wave-based-weights) for the settings.

## Make an enemy drop items
1. Right-click `resources/items/` > *Create New* > *Resource…* > `Droppable`. Set *Item Scene* to a powerup scene and pick a *Rarity*. Save it, e.g. `resources/items/heal_common.tres`. One `Droppable` can be reused in many tables.
2. Open the enemy scene, e.g. `scenes/enemy/enemy_types/clockwise_enemy.tscn`, and select the root `Enemy` node.
3. On *Drop Table*, pick *New DropTable*. Set *Drop Chance* and add `Droppable`s to *Drops*.

   To share a table between enemies, save it as a file instead (click it > *Save As…*, e.g. `resources/items/basic_drops.tres`) and load it on the other enemies. Setting the table on `scenes/enemy/enemy.tscn` gives it to every enemy that doesn't override it.

## Add a variant of an existing powerup
For example, a bigger heal:
1. Right-click `resources/powerups/` > *Create New* > *Resource…* > `HealPowerup`. Set *Name*, *Sprite*, *Color* and *Amount* = 3, and save it as `resources/powerups/big_heal.tres`. `PowerupData` isn't in the list because it's abstract.
2. Right-click `scenes/item/powerup.tscn` > *New Inherited Scene*. Select the `Powerup` node and set *Powerup Data* to the new resource. Save it as `scenes/item/big_heal_powerup.tscn`.
3. Make a `Droppable` for it and add it to a drop table.

## Add a new powerup
When no existing powerup does what you want:
1. Create `scripts/resources/items/powerups/<name>_powerup.gd` that extends `PowerupData`:
   ```gdscript
   class_name MagnetPowerup
   extends PowerupData
   ## Short description of the effect.

   @export var strength: float = 1.0


   func _init() -> void:
   	duration = 5.0


   func apply(player: Player) -> void:
   	pass # Start the effect


   func remove(player: Player) -> void:
   	pass # Undo apply()
   ```
   - `apply(player)` is required. Godot won't parse the script if it's missing.
   - `remove(player)` is only called for timed powerups (*Duration* over 0), when they run out, when the player dies and before a refresh. It must undo exactly what `apply` did, e.g. divide by the multiplier that `apply` multiplied with.
   - Set a default *Duration* in `_init`, like above. Leave it at 0 for an instant powerup.

   *Name*, *Sprite*, *Color* and *Duration* come from `PowerupData`. Don't declare them again.
2. Create a resource from it and a scene for it, like in [Add a variant of an existing powerup](#add-a-variant-of-an-existing-powerup).

## Add a new kind of item
For something that isn't a powerup, e.g. a coin that gives score:
1. Create a script under `scripts/interaction/Item/` that extends `Item` and implements `_on_collected(player)`:
   ```gdscript
   class_name Coin
   extends Item
   ## Gives score when collected.

   @export var value: int = 10


   func _on_collected(player: Player) -> void:
   	pass # Give the score
   ```
   The area is freed after `_on_collected`. If you override `_ready`, call `super()` so the lifetime still works.
2. Make a scene like `powerup.tscn`: an `Area2D` root on collision layer 4 with a `CollisionShape2D`, a `Sprite2D`, and a `Node` child with the new script. Save it under `scenes/item/`.
3. Make a `Droppable` for it and add it to a drop table.

For something the player should use with a button press instead, e.g. a shrine, turn *Interact On Touch* off. That needs an `interact` input action in Project Settings > Input Map and a HUD prompt connected to the `Interactor`'s `focus_changed`.
