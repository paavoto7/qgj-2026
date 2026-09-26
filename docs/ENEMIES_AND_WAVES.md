# Enemies and waves
How enemies are built and how to add new enemies and waves. Everything except a new enemy type is done in the editor, without code.

## How it fits together
- **`Enemy`** (`scripts/npc/enemy.gd`) is the shared enemy: chasing the player, drawing the rings and arrow, checking the thread's winding and the knot animation. Its scene is `scenes/enemy/enemy.tscn`.
- **`EnemyType`** (`scripts/npc/enemy_type.gd`) is a component, a child node of the `Enemy`, like a Unity component. It decides how the winding counts and which way to wind. Every enemy has exactly one. All types have *Color*, *Winds* (how many winds knot it, 1 by default) and *Clockwise* (which way to wind, on by default), set on the `Type` node in each enemy scene. The types are in `scripts/npc/enemy_types/`:

  | Type | Rule |
  | --- | --- |
  | `ClockwiseType` | Wind clockwise *Winds* times. |
  | `CounterclockwiseType` | Wind counterclockwise *Winds* times. |
  | `PairedType` | Linked to a partner. Loop around both *Winds* times, in either direction. |

- **Enemy scenes** inherit `enemy.tscn` and add a type component, like a Unity prefab variant. They're in `scenes/enemy/enemy_types/`.
- **Group scenes** are a plain `Node2D` with enemy scenes as children, e.g. `scenes/enemy/enemy_types/enemy_pair.tscn`. They spawn together and keep their layout.
- **`WaveData`** (`scripts/waves/wave_data.gd`) is a Resource with a list of enemy or group scenes and an optional HUD *Hint*. Waves are saved in `resources/waves/`.
- **The arena** (`scenes/arena/arena.tscn`) plays its *Waves* in order. After that it makes random waves from *Random Enemies*, one more enemy each wave, up to *Max Random Enemies*.

The arena doesn't know about specific enemy types. It only instantiates scenes.

## Add a variant of an existing type
For example, a clockwise enemy that needs 3 winds:
1. In the FileSystem dock, right-click `scenes/enemy/enemy_types/clockwise_enemy.tscn` > *New Inherited Scene*.
2. Rename the root, e.g. `Clockwise3Enemy`.
3. Select the `Type` node and set *Winds* = 3. The root `Enemy` node has *Speed* and *Radius* too.
4. Save it as `scenes/enemy/enemy_types/clockwise_3_enemy.tscn`.
5. Add it to a wave or to the arena's *Random Enemies*.

## Add a new enemy type
When no existing type fits the rule you want:
1. Create `scripts/npc/enemy_types/<name>_type.gd` (e.g. `spiral_type.gd`) that extends `EnemyType`:
   ```gdscript
   @tool
   class_name SpiralType
   extends EnemyType
   ## Short description of the rule.


   func wound_amount(windings: Dictionary[Enemy, float]) -> float:
   	return windings.get(enemy, 0.0) * direction()
   ```
   Keep the `@tool` line. It makes the enemy draw in the editor, which calls the type's methods. `@tool` isn't inherited, so every type script needs its own. Anything that shouldn't run in the editor goes behind `if Engine.is_editor_hint(): return`.

   *Color*, *Winds* and *Clockwise* come from `EnemyType`. Don't declare them again in the new type, set them in its scene instead.
2. Implement the required method `wound_amount(windings)`: how many winds the thread has made in the direction this enemy needs. `windings` has the winding around every enemy in the arena, positive = clockwise. The enemy is knotted once this reaches `winds_needed()`. Godot won't parse the script if it's missing.
3. Override the optional ones if needed:

   | Method | Default | Use it for |
   | --- | --- | --- |
   | `get_color() -> Color` | *Color* | A colour that changes, e.g. with state. |
   | `winds_needed() -> int` | *Winds* | Number of rings, and winds needed to knot. |
   | `get_speed() -> float` | the enemy's *Speed* | A different chase speed, applied when the enemy is ready. |
   | `get_radius() -> float` | the enemy's *Radius* | A different size, applied when the enemy is ready. |
   | `direction() -> float` | *Clockwise* as `1.0` / `-1.0` | `1.0` clockwise, `-1.0` counterclockwise. Flips the rings and arrow. Multiply by it in `wound_amount` so the rule follows *Clockwise*. |
   | `steer(velocity) -> Vector2` | chase the player | Different movement. Return the new velocity. |
   | `on_spawned(group)` | nothing | Setup that needs the other enemies from the same scene, like `PairedType` linking up. |
   | `draw_extras()` | nothing | Extra drawing, like the pair's dashed line. Draw with `enemy.draw_*`, in the enemy's local space. |

   The type's enemy is available as `enemy`.
4. Make a scene for it: right-click `scenes/enemy/enemy.tscn` > *New Inherited Scene*. Rename the root (e.g. `SpiralEnemy`), add a `Node` child named `Type`, attach the new script, set its *Color* and *Winds*, and save it as `scenes/enemy/enemy_types/spiral_enemy.tscn`.
5. Add the scene to a wave or to *Random Enemies*.

## Add a group of enemies
1. Scene > *New Scene* > *Other Node* > `Node2D`, and name the root, e.g. `EnemyTrio`. Don't attach a script.
2. Drag enemy scenes in from the FileSystem dock as children. Their positions are offsets from the spawn point, e.g. (-55, 0) and (55, 0) for the pair.
3. Save it next to the enemy scenes, e.g. `scenes/enemy/enemy_types/enemy_trio.tscn`.
4. Add it to a wave or to *Random Enemies* like any enemy scene. The whole group spawns at one random point.

## Add or change a wave
1. Right-click `resources/waves/` > *Create New* > *Resource…* > `WaveData`, and save it as e.g. `wave_4.tres`.
2. In the inspector, add scenes to *Enemies*. The same scene can be added more than once. Optionally, write a *Hint*, which shows under the HUD during that wave.
3. Open `scenes/arena/arena.tscn`, select `Arena`, and add the wave to *Waves* in the position it should play.

To change an existing wave, open its `.tres` file and edit it. The arena picks the change up automatically.

## Current content
All scenes are in `scenes/enemy/enemy_types/`.

| Scene | Type |
| --- | --- |
| `clockwise_enemy.tscn` | `ClockwiseType`, 2 winds |
| `counterclockwise_enemy.tscn` | `CounterclockwiseType`, 1 wind |
| `paired_enemy.tscn` | `PairedType`. Only spawn it inside a group, alone it has no partner. |
| `enemy_pair.tscn` | Group of two `paired_enemy` |

| Wave | Enemies |
| --- | --- |
| `wave_1.tres` | `clockwise_enemy` |
| `wave_2.tres` | `counterclockwise_enemy` |
| `wave_3.tres` | `enemy_pair`, `clockwise_enemy` |

*Random Enemies*: `clockwise_enemy`, `counterclockwise_enemy`, `enemy_pair`.
