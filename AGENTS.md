# AGENTS.md
Guidance for AI coding agents working in this repository. For people, see [README.md](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

`.github/copilot-instructions.md` is an exact copy of this file for Visual Studio Copilot, which doesn't read `AGENTS.md`. Whenever you edit this file, copy it over there too: `cp AGENTS.md .github/copilot-instructions.md`.

## Project
- Godot game for Quantum Game Jam 2026, Godot **4.7.2** (.NET build, so both GDScript and C# work).
- The repo root is the Godot project root (`res://`). `project.godot` gets added at jam start, see [docs/JAM_START.md](docs/JAM_START.md).
- No starter scripts exist yet. When adding shared systems, follow the architecture section below.

## Languages
**GDScript is the default.** Use C# only where it clearly helps (heavy computation, existing C# code, a teammate's preference for their own feature).
- Keep a feature in one language. Cross-language calls work (`get_node("/root/X")` / `GetNode("/root/X")`, `call`, signals) but lose type checking.
- Shared building blocks (autoloads, base classes, Resources) should be GDScript so both sides can use them.
- C# requires everyone to use the **.NET build** of Godot and the .NET SDK. Godot generates `<project>.csproj` and `<project>.sln` when the first C# script is created, commit them.

## GDScript constraints
- Use static typing everywhere: `var speed: float = 1.0`, `func move(delta: float) -> void:`. Prefer `:=` only when the type is obvious from the right side.
- Give reusable scripts a `class_name`. Don't use `class_name` on autoload scripts, it clashes with the autoload name.
- Use `@export` for inspector values and `@onready var x: Type = $Path` (or `%UniqueName`) for node references. Don't call `get_node` in `_process`.
- Check freed nodes with `is_instance_valid(node)`, not just `node != null`. A freed node isn't `null`.
- Connect signals with callables: `button.pressed.connect(_on_button_pressed)`. Disconnect in `_exit_tree` if the emitter outlives the listener (autoloads, other persistent nodes).

## C# constraints
Godot .NET compiles against the `TargetFramework` in the generated `.csproj` (.NET 8 or newer), so modern C# is fine. Godot-specific:
- Every script class that extends a Godot type must be `partial`, and its class name must match its file name.
- Use `[Export]` for inspector values and `[Signal] public delegate void SomethingEventHandler(...)` for signals (the `EventHandler` suffix is required).
- Don't use `?.`, `??` or `is null` to check if a `GodotObject` is still alive. Use `GodotObject.IsInstanceValid(obj)`.
- Unsubscribe from C# events (`-=`) in `_ExitTree` when the emitter outlives the listener.
- Build with `dotnet build` or the editor's Build button before running, otherwise the editor runs stale assemblies.

## Godot-specific rules (both languages)
- A script's class name and file are linked. Rename or move scripts, scenes and resources **inside the Godot FileSystem dock**, so references and `.uid` files are updated. Outside the editor, always move the `.uid` / `.import` file together with its file.
- Always commit `.uid` files (next to scripts and shaders) and `.import` files (next to imported assets like images and sounds). Never commit `.godot/`.
- Renaming an exported property silently clears its value in every scene and resource that set it. Avoid renames after the value has been set in scenes, or tell the user to reassign the values.
- Pausing sets `get_tree().paused = true`. Anything that runs while paused (pause menu, UI, fades) needs `process_mode = PROCESS_MODE_ALWAYS` (or `WHEN_PAUSED`). Tweens need `set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)` and timers `get_tree().create_timer(t, true)`.
- Use `_physics_process` for movement and physics, `_process` for visuals. Multiply by `delta`.

## Scenes, resources and project settings
- Don't hand-edit `.tscn`, `.tres` or `project.godot` beyond trivial fixes. Write the code, then give the user editor steps (e.g. "add a `Timer` child to `Player`, set *One Shot* on it"), like [docs/JAM_START.md](docs/JAM_START.md) does.
- New input actions go in Project Settings > Input Map. Give the user steps for adding them, then read them with `Input.is_action_pressed("action")` / `Input.IsActionPressed("action")`. Don't read keys or buttons directly.
- Folder and file names in `snake_case` (`scenes/player/player.tscn`, `scripts/player.gd`), except C# files which must match their PascalCase class.

## Architecture
Prefer Godot's built-in patterns over building parallel ones:
- **Autoloads** (Project Settings > Globals) for global managers, e.g. game state, scene loading, sound. They exist in every scene, including when running a single scene with F6.
- **Scenes** as reusable building blocks, instanced instead of copy-pasted.
- **Signals** for communication upwards and between siblings, direct calls downwards ("call down, signal up").
- **Resources** (`extends Resource` with `class_name`) for data such as item or enemy stats, instead of hard-coded values.
- One scene per screen or menu under a `CanvasLayer`. Show and hide them through a single UI manager once one exists.
- A node-based state machine (a `StateMachine` node with `State` children) for player, enemy and game flow logic.
- Scene changes through one place (an autoload), not `get_tree().change_scene_to_file` scattered around.

Abstractions are welcome. Prefer reusable, generic building blocks, such as base classes, Resources, scenes and signals, over one-off code, as long as they stay understandable. No tests or test frameworks for now, and ask before adding addons, NuGet packages or other dependencies.

## Code style
Follow `.editorconfig`.

GDScript follows the [official style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):
- Tabs for indentation, LF line endings, final newline.
- `snake_case` for variables, functions and files, `PascalCase` for `class_name` and nodes, `CONSTANT_CASE` for constants and enum values.
- Prefix private members with `_`: `var _velocity: Vector2`, `func _update_hud() -> void:`.
- A short `##` doc comment at the top of each script.
- Order: `class_name`, `extends`, doc comment, signals, enums, constants, `@export`, public vars, private vars, `@onready` vars, built-in callbacks (`_ready`, `_process`...), public methods, private methods.

C#:
- Allman braces, 4 spaces, LF, final newline.
- No namespaces.
- Private fields in camelCase, PascalCase for properties, methods and types. `[Export] private float speed = 1f;` is fine.
- A short `/// <summary>` for each class.
- Single-statement methods use arrow notation: `public void Stop() => audioPlayer.Stop();`. Multi-statement methods and constructors use block bodies.
- `var` when the type isn't a built-in, explicit `int`, `float`, `bool` etc.
- Short single-line `if (x) return;` statements are fine. Use braces if the statement spans lines.

## Verifying changes
1. C# formatting, if there is any C#:
   ```sh
   dotnet format whitespace --folder . --verify-no-changes
   ```
   Drop `--verify-no-changes` to fix.
2. Check that everything parses and compiles. Ask the user for the Godot executable path if you don't know it (the .NET build is usually named `Godot_v4.7.2-stable_mono_win64.exe`).
   - C#: `dotnet build` in the repo root. Grep for `error CS` and `warning CS`.
   - GDScript and scenes: `<godot> --headless --path . --import --quit` imports the project and reports broken scripts and resources. Grep the output for `SCRIPT ERROR`, `Parse Error` and `ERROR:`.
   - Before `project.godot` exists, use a throwaway project in the scratchpad: an empty `project.godot` plus copies of the files to check.

   Having the project open in the editor at the same time is fine, but the editor may reimport afterwards.

## Safety
- Never run destructive operations, e.g.:
  - deleting or overwriting files or folders the user hasn't asked about (`rm -rf`, `Remove-Item -Recurse`)
  - `git reset --hard`, `git clean`, `git checkout -- .` / `git restore .`, `git stash drop`
  - deleting branches or tags, rewriting pushed history (rebasing or amending commits that are already pushed)
  - deleting `.godot/`, `.uid` or `.import` files, or assets
- If one seems necessary, stop, explain why and let the user run it or confirm it explicitly.
- Never force anything: no `git push --force` / `--force-with-lease`, no `-f` flags to bypass checks, no `--no-verify`.

## Git
- `main` is protected. Work on a branch, push it and open a pull request, see [CONTRIBUTING.md](CONTRIBUTING.md).
- Confirm every state-changing git operation with the user first: commit, push, pull, merge, rebase of unpushed work, branch switch, stash, opening a pull request. Skip the confirmation only if the user explicitly asked for that exact operation. Approval for one operation doesn't carry over to the next.
- Read-only commands (`status`, `diff`, `log`, `show`) are always fine.
- Check `git status` for `.godot/`, `bin/`, `obj/`, `.vs/`, export builds etc. before committing. Afterwards, verify the result with `git status` / `git log`.
- Commit messages are short and in past tense, with no trailing period:
  - `Added FPS ticker to HUD`
  - `Fixed controller input in pause menu`
  - `UI manager improvements`

  If needed, add a body of a few plain sentences after a blank line.

## Pull request descriptions
Fill in every section of `.github/pull_request_template.md`, in plain and short sentences:
- **Summary:** what and why in one or two sentences.
- **Changes:** bullets of notable changes, not a file list.
- **Editor setup needed:** everything a teammate must do in the editor after pulling (assign exports, add input actions, groups or physics layers, scene edits you gave as steps). Write "None" if nothing.
- **Screenshots / video:** leave the placeholder for the author if there is a visual change.
- **Checklist:** only tick items you actually verified, e.g. the compile check.

Mention changes to `project.godot`, autoloads, input actions, `export_presets.cfg` or scenes explicitly. The PR title follows the commit message style.

Copilot code review has its own rules in `.github/instructions/code-review.instructions.md`. Keep them consistent with this file when conventions change.
