# qgj-2026
Our game for Quantum Game Jam 2026.

- Engine: Godot **4.7.2**, .NET build (GDScript and C#).
- Getting started and commit workflow: [CONTRIBUTING.md](CONTRIBUTING.md).
- Setting up the project at jam start: [docs/JAM_START.md](docs/JAM_START.md).
- Adding enemies and waves: [docs/ENEMIES_AND_WAVES.md](docs/ENEMIES_AND_WAVES.md).

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
| `interaction/interactable.gd` | Child of an `Area2D`/`Area3D`. Emits `interacted` or can be extended by overriding `interact()`. |
| `interaction/interactor.gd` | Child of the player's `Area2D`/`Area3D`. Focuses the closest `Interactable` and interacts on the `interact` action. Connect `focus_changed` to the HUD. |
| `common/flash_effect.gd` | Flashes the parent sprite or mesh, e.g. on damage. |
| `common/hover_effect.gd` | Bobs the parent up and down, e.g. for pickups. |
