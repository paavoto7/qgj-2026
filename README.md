# Knot today (QGJ-2026)
Game made for the [Quantum Game Jam 2026](https://itch.io/jam/quantum-game-jam-2026). Game can be found at [itch.io](https://borje1.itch.io/knot-today)

- Engine: Godot **4.7.2**
- Getting started and commit workflow: [CONTRIBUTING.md](CONTRIBUTING.md).

## Theme
The theme of the year is *quantum braiding*.

## Starter scripts
Reusable scripts under `scripts/`, taken from our GGJ 2026 project and cleaned up. Components work in both 2D and 3D.

| Script | What it does |
| --- | --- |
| `autoloads/main_manager.gd` | `MainManager` autoload. Scene changes, pause/resume (`pause_changed` signal), quitting, saving and loading `GameData`. |
| `autoloads/audio_manager.gd` | `AudioManager` autoload. Music with cross-fades, UI sounds and pooled one-shot SFX (`play_sfx`, `play_sfx_2d`, `play_sfx_3d`). Uses the Music, SFX and UI buses if they exist. |
| `game_data.gd` | `GameData` resource saved to `user://`. Add the game's save fields as `@export` variables. |
| `state_machine/state_machine.gd`, `state_base.gd` | Code-driven state machine. Extend `StateBase` with a `class_name` and switch with `change_state(&"ClassName")`. |
| `ui/menu_base.gd` | Base for menus. Shows the cursor while open, works while paused and focuses a control for controller navigation. |
| `components/health.gd` | `Health` child node with damage, healing, invulnerability frames, sounds and signals. |
| `components/damage_zone.gd` | Child of an `Area2D`/`Area3D`. Damages bodies with a `Health`, once or repeatedly. |
| `interaction/interactable.gd` | Child of an `Area2D`/`Area3D`. Emits `interacted` or can be extended by overriding `interact()`. `interact_on_touch` makes it trigger on overlap, e.g. for pickups. |
| `interaction/interactor.gd` | Child of the player's `Area2D`/`Area3D`. Focuses the closest `Interactable` and interacts on the `interact` action, or right away for touch interactables. Connect `focus_changed` to the HUD. |
| `interaction/Item/item.gd`, `powerup.gd` | `Item` is an `Interactable` pickup collected on touch, with an optional lifetime. Extend it and override `_on_collected()`. `Powerup` gives the player a `PowerupData`. |
| `components/powerups.gd` | `Powerups` child of the player. Applies powerups, times out timed ones and refreshes a powerup picked up again. |
| `resources/items/drop_table.gd`, `droppable.gd` | Per-enemy `DropTable` (drop chance + `Droppable` item scenes weighted by rarity), assigned to an Enemy's *Drop Table*. |
| `resources/weights/wave_weight.gd`, `common/weighted_random.gd` | `WaveWeight` resource for weights that change with the wave number, and `WeightedRandom.pick_index()` for weighted picks. Used by random spawns, movement patterns and drops. |
| `resources/items/powerup_data.gd` | Base for powerups. Extend it and implement `apply()` and, if timed, `remove()`. Examples in `resources/items/powerups/`. |
| `common/flash_effect.gd` | Flashes the parent sprite or mesh, e.g. on damage. |
| `common/hover_effect.gd` | Bobs the parent up and down, e.g. for pickups. |
