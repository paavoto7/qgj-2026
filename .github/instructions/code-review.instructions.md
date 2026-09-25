---
applyTo: "**"
excludeAgent: "cloud-agent"
---

# Code review: Godot 4.7 game jam project
Review for bugs that break the game or the project for teammates. Keep comments short and actionable, and suggest a fix when possible.

## Don't comment on
- Formatting and whitespace, `.editorconfig` and `dotnet format` handle it.
- Missing tests, the project has none on purpose.
- Abstractions or base classes being "too much", they are welcome if they stay understandable.
- Generated files: `.uid`, `.import`, `.csproj`, `.sln`.

## Flag these
### Godot correctness
- Checking freed nodes with `!= null` (GDScript) or `?.` / `??` / `is null` (C#) instead of `is_instance_valid` / `GodotObject.IsInstanceValid`.
- Renamed `@export` / `[Export]` properties. The renamed property loses its value in every scene and resource, so ask whether the values were reassigned.
- C# script classes that aren't `partial`, or whose class name doesn't match the file name.
- C# signals whose delegate name doesn't end in `EventHandler`.
- Signal connections or C# event subscriptions to longer-lived emitters (autoloads) without a matching disconnect in `_exit_tree` / `_ExitTree`.
- Code that must run while paused without `process_mode = PROCESS_MODE_ALWAYS` / `WHEN_PAUSED`, tweens without `TWEEN_PAUSE_PROCESS`, or `create_timer` without `process_always`.
- `get_node`, `$Path`, `find_child`, `get_nodes_in_group` or allocations inside `_process` / `_physics_process`. Cache node references with `@onready`.
- Movement or physics in `_process` instead of `_physics_process`, or missing `delta`.
- Hard-coded node paths into other scenes (`get_node("../../Player")`). Suggest an export, a signal, a group or `%UniqueName`.

### GDScript
- Missing static types on variables, parameters and return values.
- `class_name` on an autoload script.

### Project conventions
- Global managers must be autoloads, not nodes found with `get_tree().root.find_child`.
- Scene changes must go through the scene loading autoload once one exists, not `change_scene_to_file` scattered around.
- Input must use Input Map actions (`Input.is_action_pressed`), not `Input.is_key_pressed` or raw keycodes.
- A feature should stay in one language. Shared building blocks should be GDScript.
- GDScript: `snake_case` files and members, `_` prefix for private members, a `##` doc comment per script.
- C#: no namespaces, single-statement methods use `=>`, every class has a short `/// <summary>`.

### Repository hygiene
- Added, moved or renamed scripts or assets without their `.uid` / `.import` file, or orphaned `.uid` / `.import` files.
- Committed `.godot/`, `bin/`, `obj/`, `.vs/` or export builds.
- Large hand-written changes to `.tscn` / `.tres` files. Ask whether it was done in the editor.
- Changes to `project.godot`, autoloads, input actions or `export_presets.cfg` that the PR description doesn't mention.
