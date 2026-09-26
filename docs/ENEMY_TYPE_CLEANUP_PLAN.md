# Enemy type cleanup plan
A planned cleanup, not done yet. It replaces four copy-pasted enemy type scripts with one, so new enemy variants don't need new scripts.

## Problem
`ClockwiseType`, `CounterclockwiseType`, `RangedEnemyType` and `FastSmallType` (in `scripts/npc/enemy_types/`) all implement the same rule:

```gdscript
func wound_amount(windings: Dictionary[Enemy, float]) -> float:
	return windings.get(enemy, 0.0) * direction()
```

- Clockwise and counterclockwise only differ in the *Clockwise* export, which `EnemyType` already has.
- What makes the ranged enemy ranged is its `Attack` node, not its type.
- `FastSmallType` only multiplies speed (3×) and radius (0.5×), which the `Enemy` root already exports as *Speed* and *Radius*.

So every new variant tempts people into writing another script, while [ENEMIES_AND_WAVES.md](ENEMIES_AND_WAVES.md) says variants should be editor-only.

## Plan
1. In `scripts/npc/enemy_type.gd`, drop `@abstract` from `wound_amount` and give it the shared body above as the default. Keep the class itself `@abstract`, so it can't be added to an enemy directly.
2. Add `scripts/npc/enemy_types/winding_type.gd`:
   ```gdscript
   @tool
   class_name WindingType
   extends EnemyType
   ## Wind the thread Winds times around the enemy, in the direction set by Clockwise.
   ```
3. `PairedType` stays, it has a rule of its own.

## Editor steps
For each scene in `scenes/enemy/enemy_types/`, select the `Type` node and change its script to `winding_type.gd`. Afterwards check that *Color*, *Winds* and *Clockwise* kept their values (same property names, so they should):
- `clockwise_enemy.tscn` (2 winds, clockwise)
- `counterclockwise_enemy.tscn` (1 wind, *Clockwise* off)
- `ranged_enemy.tscn`
- `fast_small_enemy.tscn`: also set the root *Speed* to 165 and *Radius* to 8, which is what the multipliers gave, and give it a visible *Color* (it's black now)

## Afterwards
- Delete `clockwise_type.gd`, `counterclockwise_type.gd`, `ranged_enemytype.gd` and `fastsmall_type.gd` with their `.uid` files, in the FileSystem dock.
- Update [ENEMIES_AND_WAVES.md](ENEMIES_AND_WAVES.md): the types table (`WindingType`, `PairedType`), "Add a variant", "Add a new enemy type" (`wound_amount` becomes optional, the default winds in the *Clockwise* direction) and "Current content".
- Delete this file.

## Verification
1. Headless import (see AGENTS.md) reports no `SCRIPT ERROR`, `Parse Error` or `ERROR:`.
2. No hits for `ClockwiseType`, `CounterclockwiseType`, `RangedEnemyType` or `FastSmallType` in `scripts/`, `scenes/` and `docs/`.
3. In game, every enemy shows the right ring direction and knots correctly, the fast small enemy is still fast and small, and the ranged enemy still shoots.
