# Enemies and waves
How enemies are built and how to add new enemies and waves. Everything except a new enemy type is done in the editor, without code.

## How it fits together
- **`Enemy`** (`scripts/npc/enemy.gd`) is the shared enemy: chasing the player, drawing the rings and arrow, checking the thread's winding and the knot animation. Its scene is `scenes/enemy/enemy.tscn`.
- **`EnemyType`** (`scripts/npc/enemy_type.gd`) is a component, a child node of the `Enemy`, like a Unity component. It decides how the winding counts and which way to wind. Every enemy has exactly one. All types have *Color*, *Winds* (how many winds knot it, 1 by default) and *Clockwise* (which way to wind, on by default), set on the `Type` node in each enemy scene. On its own, `EnemyType` is the plain rule, and most enemies use it directly. Subclasses in `scripts/npc/enemy_types/` change the rule:

  | Type | Rule |
  | --- | --- |
  | `EnemyType` | Wind *Winds* times in the *Clockwise* direction. Set *Speed*, *Radius* and the `Attack` on the scene for the rest. |
  | `PairedType` | Linked to a partner. Loop around both *Winds* times, in either direction. |
  | `PurpleType` | Wind *Required Winds* times (3 by default), switching direction after each wind. The first direction is random. |
  | `RandomDirectionType` | Wind *Winds* times in a random direction, picked when it spawns. |
  | `YellowType` | Like `RandomDirectionType`. When knotted, it splits into two smaller, faster copies that don't split again. |

- **Enemy scenes** inherit `enemy.tscn` and add a type component, like a Unity prefab variant. They're in `scenes/enemy/enemy_types/`.
- **Group scenes** are a plain `Node2D` with enemy scenes as children, e.g. `scenes/enemy/enemy_types/enemy_pair.tscn`. They spawn together and keep their layout.
- **`WaveData`** (`scripts/resources/waves/wave_data.gd`) is a Resource with a list of enemy or group scenes and an optional HUD *Hint*. Waves are saved in `resources/waves/`.
- **`ArenaData`** (`scripts/resources/arena/arena_data.gd`) is a Resource with an arena's settings: the player scene, *Waves*, *Random Spawns* and *Max Random Enemies*. The current one is `resources/arena/test_arena.tres`, assigned to the `Arena` node's *Arena Data*.
- **The arena** (`scenes/arena/arena.tscn`) has a `WaveSpawner` child that plays the *Waves* in order. After that it makes random waves from *Random Spawns*, one more enemy each wave, up to *Max Random Enemies*. Each pick is weighted by the entry's `WaveWeight` for the current wave, see [Wave-based weights](#wave-based-weights).

The arena doesn't know about specific enemy types. It only instantiates scenes.

## Add a variant of an existing type
For example, a clockwise enemy that needs 3 winds:
1. In the FileSystem dock, right-click `scenes/enemy/enemy_types/clockwise_enemy.tscn` > *New Inherited Scene*.
2. Rename the root, e.g. `Clockwise3Enemy`.
3. Select the `Type` node and set *Winds* = 3. The root `Enemy` node has *Speed* and *Radius* too.
4. Save it as `scenes/enemy/enemy_types/clockwise_3_enemy.tscn`.
5. Add it to a wave, or as a `SpawnEntry` to *Random Spawns* in the arena's `ArenaData`.

## Add a new enemy type
When the rule itself is different, not just *Winds*, *Clockwise*, *Speed*, *Radius* or the `Attack`:
1. Create `scripts/npc/enemy_types/<name>_type.gd` (e.g. `spiral_type.gd`) that extends `EnemyType`:
   ```gdscript
   @tool
   class_name SpiralType
   extends EnemyType
   ## Short description of the rule.
   ```
   Keep the `@tool` line. It makes the enemy draw in the editor, which calls the type's methods. `@tool` isn't inherited, so every type script needs its own. Anything that shouldn't run in the editor goes behind `if Engine.is_editor_hint(): return`.

   *Color*, *Winds* and *Clockwise* come from `EnemyType`. Don't declare them again in the new type, set them in its scene instead.
2. Override the methods your rule needs. The type's enemy is available as `enemy`.

   | Method | Default | Use it for |
   | --- | --- | --- |
   | `wound_amount(windings) -> float` | winding in the `direction()` direction | How many winds the thread has made in the direction this enemy needs. `windings` has the winding around every enemy in the arena, positive = clockwise. The enemy is knotted once this reaches `winds_needed()`. |
   | `get_color() -> Color` | *Color* | A colour that changes, e.g. with state. |
   | `winds_needed() -> int` | *Winds* | Number of rings, and winds needed to knot. |
   | `get_speed() -> float` | the enemy's *Speed* | A different chase speed, applied when the enemy is ready. |
   | `get_radius() -> float` | the enemy's *Radius* | A different size, applied when the enemy is ready. |
   | `direction() -> float` | *Clockwise* as `1.0` / `-1.0` | `1.0` clockwise, `-1.0` counterclockwise. Flips the rings and arrow. Multiply by it in your own `wound_amount` so the rule follows *Clockwise*. |
   | `steer(velocity) -> Vector2` | chase the player | Different movement. Return the new velocity. |
   | `on_spawned(group)` | nothing | Setup that needs the other enemies from the same scene, like `PairedType` linking up. |
   | `on_wind_completed()` | nothing | Something that happens after each full wind, like `PurpleType` switching direction. |
   | `on_knotted()` | nothing | Something that happens when the enemy is knotted, like `YellowType` splitting. Create new enemies with `scene.instantiate()` and hand them over with `enemy.spawn(new_enemy)`, the spawner adds them to the arena. |
   | `draw_extras()` | nothing | Extra drawing, like the pair's dashed line. Draw with `enemy.draw_*`, in the enemy's local space. |
3. Make a scene for it: right-click `scenes/enemy/enemy.tscn` > *New Inherited Scene*. Rename the root (e.g. `SpiralEnemy`), add a `Node` child named `Type`, attach the new script, set its *Color* and *Winds*, and save it as `scenes/enemy/enemy_types/spiral_enemy.tscn`.
4. Add the scene to a wave or to *Random Spawns*.

## Add a group of enemies
1. Scene > *New Scene* > *Other Node* > `Node2D`, and name the root, e.g. `EnemyTrio`. Don't attach a script.
2. Drag enemy scenes in from the FileSystem dock as children. Their positions are offsets from the spawn point, e.g. (-55, 0) and (55, 0) for the pair.
3. Save it next to the enemy scenes, e.g. `scenes/enemy/enemy_types/enemy_trio.tscn`.
4. Add it to a wave or to *Random Spawns* like any enemy scene. The whole group spawns at one random point.

## Add or change a wave
1. Right-click `resources/waves/` > *Create New* > *Resource…* > `WaveData`, and save it as e.g. `wave_4.tres`.
2. In the inspector, add scenes to *Enemies*. The same scene can be added more than once. Optionally, write a *Hint*, which shows under the HUD during that wave.
3. Open the arena's `ArenaData` (`resources/arena/test_arena.tres`) and add the wave to *Waves* in the position it should play.

To change an existing wave, open its `.tres` file and edit it. The arena picks the change up automatically.

**Test keys:** when the game is run from the editor, *Tab* starts the next wave and the number keys go to that wave (*1*-*9*, *0* for wave 10). The current enemies are removed first. Runs that used them don't record a high score. They're off in exported builds.

## Wave-based weights
A **`WaveWeight`** (`scripts/resources/weights/wave_weight.gd`) is a Resource that says how likely something is on a given wave, compared to the other options it's picked from. It's used for random spawns, movement patterns and drops (see [ITEMS_AND_POWERUPS.md](ITEMS_AND_POWERUPS.md)). An empty weight slot counts as 1 on every wave, so leaving them all empty gives an even pick.

| Setting | Meaning |
| --- | --- |
| *Weight* | Weight on *From Wave*. |
| *Per Wave* | Added every wave after *From Wave*. Negative makes it rarer over time. |
| *From Wave* | 0 before this wave. |
| *Until Wave* | 0 after this wave. 0 means no end. |
| *Max Weight* | Cap on the weight. 0 means no cap. |
| *Curve* | Optional. Replaces *Weight* and *Per Wave*: x is the wave, y the weight. Set the curve's *Min/Max Domain* to the waves it covers, e.g. 1 to 20. |

Weights are relative, like drop rarities: an option's chance is its weight divided by the total of all options on that wave. For example, a clockwise enemy with no weight (1) and a ranged enemy with *Weight* 0.5, *Per Wave* 0.25 and *From Wave* 6 are never ranged before wave 6, 1/3 ranged on wave 6 and 3/5 ranged on wave 10. The wave number counts the scripted waves too.

**Random spawns:** each entry in *Random Spawns* is a `SpawnEntry` with a *Scene* and a *Weight*. If every weight is 0 on some wave, the spawner picks evenly so the wave isn't empty.

**Movement patterns:** add one or more `MovementPattern` nodes (e.g. `SineMovementPattern`) as children of an enemy's `Type` node, each with its own *Weight*. When the enemy spawns, one of them or none is picked. *No Pattern Weight* on the `Type` node is the weight of just chasing. With one pattern and no weights set, it's 50/50.

Add a `WaveWeight` in the inspector with *New WaveWeight* on any weight slot, or save one as a file in `resources/weights/` to reuse it.

## Current content
All scenes are in `scenes/enemy/enemy_types/`.

| Scene | Type |
| --- | --- |
| `clockwise_enemy.tscn` | `EnemyType`, 2 winds clockwise |
| `counterclockwise_enemy.tscn` | `EnemyType`, 1 wind counterclockwise |
| `paired_enemy.tscn` | `PairedType`. Only spawn it inside a group, alone it has no partner. |
| `enemy_pair.tscn` | Group of two `paired_enemy` |
| `fast_small_enemy.tscn` | `EnemyType`, 1 wind clockwise. *Speed* 165 and *Radius* 8, 3× the default speed and half the size. |
| `yellow_enemy.tscn` | `YellowType`, splits into two when knotted |
| `ranged_enemy.tscn` | `EnemyType`, 1 wind clockwise. Its `Attack` is ranged: shoots `scenes/projectiles/orb.tscn` from 400 px away. |
| `purple_enemy.tscn` | `PurpleType`, 3 winds, switching direction after each |
| `white_enemy.tscn` | `RandomDirectionType`, 4 winds. Big and slow: *Speed* 25, *Radius* 35. |

Every enemy inherits a melee `Attack` from `enemy.tscn` (1 damage, 10 px reach, 0.5 s cooldown), which `ranged_enemy.tscn` overrides.

`resources/arena/test_arena.tres` plays these waves in order:

| Wave | Enemies |
| --- | --- |
| `testwave.tres` | `fast_small_enemy`, `ranged_enemy` |
| `wave_1.tres` | `clockwise_enemy` |
| `wave_2.tres` | `counterclockwise_enemy` |
| `wave_3.tres` | `enemy_pair`, `clockwise_enemy` |

*Random Spawns* use three shared weights in `resources/weights/`, so the mix gets harder over the waves. Random waves start at wave 5, after the scripted ones.

| Weight | Enemies | Setting |
| --- | --- | --- |
| `easy_spawn_weight.tres` | `clockwise_enemy`, `counterclockwise_enemy` | 3 on every wave, so they get relatively rarer as others join. |
| `medium_spawn_weight.tres` | `enemy_pair`, `fast_small_enemy` | From wave 6: 1, +0.3 per wave, up to 4. |
| `hard_spawn_weight.tres` | `ranged_enemy`, `yellow_enemy`, `purple_enemy`, `white_enemy` | From wave 9: 0.5, +0.25 per wave, up to 6. |

That's only easy enemies on wave 5, about half easy on wave 9, and about two thirds hard by wave 30. `clockwise_enemy`'s sine movement also gets likelier: 67% on wave 1, 85% on wave 20.
