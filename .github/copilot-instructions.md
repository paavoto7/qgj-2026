# AGENTS.md
Guidance for AI coding agents working in this repository. For people, see [README.md](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

`.github/copilot-instructions.md` is an exact copy of this file for Visual Studio Copilot, which doesn't read `AGENTS.md`. Whenever you edit this file, copy it over there too: `cp AGENTS.md .github/copilot-instructions.md`.

## Project
- Unity game for Quantum Game Jam 2026, Unity **6000.6.2f1** (URP, Input System, uGUI/TextMeshPro).
- Until jam start only `Assets/` is tracked. `ProjectSettings/` and `Packages/` get added then, see [docs/JAM_START.md](docs/JAM_START.md).
- Starter scripts are under `Assets/Scripts/`, the README has a table of what each does.

## C# constraints
Unity 6.6 compiles with **C# 9** (`-langversion:9.0`) against .NET Standard 2.1. Don't use newer features even if `.editorconfig` prefers them:
- No file-scoped namespaces, collection expressions (`[]`), primary constructors, `required`/`file`, extended property patterns, UTF-8 literals, `field` keyword or `System.Threading.Lock`.
- Target-typed `new()`, `is not`, switch expressions and static lambdas are fine.

Unity-specific:
- Don't use `?.`, `??` or `is null` on `UnityEngine.Object` types, they skip Unity's overloaded null check. Use `!= null` / `== null`.
- Don't make `[SerializeField]` fields `readonly` or serialized structs `readonly struct`.
- `Assets/InputSystem_Actions.cs` is generated from `InputSystem_Actions.inputactions`. Don't edit or reformat it.
- Always keep `.meta` files with their assets. Don't create, rename or move assets without their `.meta`.
- A MonoBehaviour's class name must match its file name. Rename both together and keep the `.meta` with the file, otherwise every scene and prefab reference to the script breaks.
- Renaming a serialized field (`[SerializeField]` or public) silently clears its value in every scene and prefab. Keep the old values with `[FormerlySerializedAs("oldName")]`.
- Pausing sets `Time.timeScale = 0`. Anything that runs while paused (UI, fades, menus) must use `Time.unscaledDeltaTime` / `WaitForSecondsRealtime`, as `ScreenFade` and `UILayer` do.

## Scenes, prefabs and assets
- Don't hand-edit `.unity`, `.prefab` or `.asset` YAML. Write the code, then give the user editor steps (e.g. "add X to the Canvas, assign Y in the inspector"), like [docs/JAM_START.md](docs/JAM_START.md) does.
- New input actions go in `Assets/InputSystem_Actions.inputactions`. Unity regenerates `InputSystem_Actions.cs` on import. Then expose the action as a property on `InputManager`.

## Architecture
Use the existing systems instead of building parallel ones:
- `SingletonBase<T>` / `PersistentSingletonBase<T>` for managers. Check `IsInstance` after `base.Awake()` in overrides.
- `UIManager` + `UILayer` for every screen, menu or HUD element. Override `Show(object data)`, `CanShow` or `OnClosing` as needed.
- `InputManager.Instance.<Action>` for input, not reading devices directly.
- `SoundManager` for music and non-world SFX, `AudioController` for per-object sounds.
- `MainManager` for scene loading.
- `StateMachine` + `IState` for state-based behaviour (player, enemies, game flow).

New persistent managers must also be spawned in `Editor/EditorBootstrapper.cs`, so pressing Play in any scene still works.

Abstractions are welcome. Prefer reusable, generic building blocks, such as base classes, interfaces, ScriptableObject data and events, over one-off code, as long as they stay understandable. No tests or test frameworks for now, and ask before adding packages.

## Code style
Follow `.editorconfig` (only `[*.cs]` is configured). In short:
- Allman braces, 4 spaces, CRLF, final newline.
- No namespaces.
- `[SerializeField] private` fields in camelCase, PascalCase for properties, methods and types.
- A short `/// <summary>` for each class.
- Single-statement methods use arrow notation: `public void Stop() => audioSource.Stop();`. Multi-statement methods and constructors use block bodies.
- `var` when the type isn't a built-in, explicit `int`, `float`, `bool` etc.
- Short single-line `if (x) return;` statements are fine. Use braces if the statement spans lines.

## Verifying changes
1. Formatting:
   ```sh
   dotnet format whitespace --folder Assets/Scripts --verify-no-changes
   ```
   Drop `--verify-no-changes` to fix. Code inside `#if UNITY_EDITOR` (e.g. `Editor/EditorBootstrapper.cs`) is skipped by `--folder`, check it by hand.
2. Compile with Unity, since there is no csproj or sln in the repo. Once the project exists, run batch mode on the repo root. Before that, use a throwaway project outside the repo:
   - Copy `Assets/Scripts` and `Assets/InputSystem_Actions.*` into `<tmp>/Assets/`.
   - Add `<tmp>/Packages/manifest.json` listing `com.unity.inputsystem`, `com.unity.ugui` and `com.unity.modules.audio`. Exact versions don't matter, Unity resolves compatible ones.
   - Run `"C:/Program Files/Unity/Hub/Editor/6000.6.2f1/Editor/Unity.exe" -batchmode -nographics -quit -projectPath <tmp> -logFile <tmp>/unity.log`. Pass Windows-style paths (`cygpath -w` in Git Bash).
   - Check that `<tmp>/Library/ScriptAssemblies/Assembly-CSharp.dll` was rebuilt.
   - Grep the log for `error CS` and `warning CS`.

   Batch mode fails if the project is open in the editor. In that case ask the user to close it, or to check the editor console instead.

## Safety
- Never run destructive operations, e.g.:
  - deleting or overwriting files or folders the user hasn't asked about (`rm -rf`, `Remove-Item -Recurse`)
  - `git reset --hard`, `git clean`, `git checkout -- .` / `git restore .`, `git stash drop`
  - deleting branches or tags, rewriting pushed history (rebasing or amending commits that are already pushed)
  - deleting `Library/`, `.meta` files or assets
- If one seems necessary, stop, explain why and let the user run it or confirm it explicitly.
- Never force anything: no `git push --force` / `--force-with-lease`, no `-f` flags to bypass checks, no `--no-verify`.

## Git
- `main` is protected. Work on a branch, push it and open a pull request, see [CONTRIBUTING.md](CONTRIBUTING.md).
- Confirm every state-changing git operation with the user first: commit, push, pull, merge, rebase of unpushed work, branch switch, stash, opening a pull request. Skip the confirmation only if the user explicitly asked for that exact operation. Approval for one operation doesn't carry over to the next.
- Read-only commands (`status`, `diff`, `log`, `show`) are always fine.
- Check `git status` for `Library/`, `Temp/`, `.csproj`, `.sln` etc. before committing. Afterwards, verify the result with `git status` / `git log`.
- Commit messages are short and in past tense, with no trailing period:
  - `Added FPS ticker to HUD`
  - `Fixed controller input in pause menu`
  - `UIManager improvements`

  If needed, add a body of a few plain sentences after a blank line.

## Pull request descriptions
Fill in every section of `.github/pull_request_template.md`, in plain and short sentences:
- **Summary:** what and why in one or two sentences.
- **Changes:** bullets of notable changes, not a file list.
- **Editor setup needed:** everything a teammate must do in the editor after pulling (assign references, add tags or layers, scene or prefab edits you gave as steps). Write "None" if nothing.
- **Screenshots / video:** leave the placeholder for the author if there is a visual change.
- **Checklist:** only tick items you actually verified, e.g. the Unity compile check.

Mention changes to `ProjectSettings/`, `Packages/manifest.json` or scenes explicitly. The PR title follows the commit message style.

Copilot code review has its own rules in `.github/instructions/code-review.instructions.md`. Keep them consistent with this file when conventions change.
