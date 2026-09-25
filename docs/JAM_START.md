# Jam start checklist
Only one person does this, the rest wait until the PR is merged and then pull.

## 1. Create the Godot project
1. Everyone uses the **.NET build** of Godot **4.7.2** (`Godot_v4.7.2-stable_mono_*`), so C# scripts work for everyone.
2. Project Manager > Create:
    - *Project Path*: the repo root. Godot warns that the folder isn't empty, that's fine.
    - *Renderer*: *Forward+* for 3D, *Compatibility* for 2D or if we might want a web build.
    - *Version Control Metadata*: **None**. The repo already has `.gitignore` and `.gitattributes`.
3. Create & Edit. Check that `project.godot` and `icon.svg` appear in the repo root.

## 2. Folders
Create these in the FileSystem dock:
- `scenes/` with `scenes/sandbox/` for personal test scenes.
- `scripts/`, `assets/` (`sprites/`, `audio/`, `fonts/`...), `resources/`.

## 3. Project settings
- Application > Config > *Name*: the game's name.
- Display > Window: set the *Viewport Width/Height* and *Stretch Mode* (`canvas_items` for most 2D games, `viewport` for pixel art).
- Rendering > Textures > *Default Texture Filter* = *Nearest* for pixel art.
- Input Map: add the basic actions, e.g. `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `interact`, `pause`, with keyboard and controller bindings.

## 4. C# setup
1. Project > Tools > C# > Create C# solution. This creates `<project>.csproj` and `<project>.sln`.
2. Press Build (hammer icon, top right) and check the output for errors.

## 5. Scenes
1. Create `scenes/main_menu.tscn` and `scenes/game.tscn`.
2. Project Settings > Application > Run > *Main Scene* = `scenes/main_menu.tscn`.
3. Add global managers as autoloads in Project Settings > Globals once they exist.

## 6. Commit
1. `git checkout -b project-setup`
2. `git status`, check that `.godot/` isn't included, and that `project.godot`, `icon.svg`, `*.import`, `*.uid`, `.csproj` and `.sln` are.
3. Commit, push and open a PR. Once merged, tell everyone to pull and open the project with Import in the Project Manager.
