---
applyTo: "**"
excludeAgent: "cloud-agent"
---

# Code review: Unity 6.6 game jam project
Review for bugs that break the game or the project for teammates. Keep comments short and actionable, and suggest a fix when possible.

## Don't comment on
- Formatting and whitespace, `.editorconfig` and `dotnet format` handle it.
- Missing tests, the project has none on purpose.
- Abstractions or base classes being "too much", they are welcome if they stay understandable.
- `Assets/InputSystem_Actions.cs`, it is generated.

## Flag these
### Unity correctness
- `?.`, `??`, `??=` or `is null` on `UnityEngine.Object` types (MonoBehaviour, GameObject, components, assets). They skip Unity's null check, so require `!= null` / `== null`.
- Renamed `[SerializeField]` or public fields without `[FormerlySerializedAs("oldName")]`. The renamed field loses its value in every scene and prefab.
- MonoBehaviour class name not matching its file name.
- Event or input subscriptions (`+=`) without a matching `-=` in `OnDisable` / `OnDestroy`.
- Code that must run while paused using `Time.deltaTime` / `WaitForSeconds`. Pausing sets `Time.timeScale = 0`, so it needs `Time.unscaledDeltaTime` / `WaitForSecondsRealtime`.
- `StartCoroutine` on objects that may be inactive.
- `GetComponent`, `Find*`, `FindAnyObjectByType` or LINQ allocations inside `Update` / `FixedUpdate`. Cache them in `Awake`.

### C# version
Unity compiles C# 9. Flag file-scoped namespaces, collection expressions (`[]`), primary constructors, `required`, `file`, extended property patterns, UTF-8 literals, the `field` keyword and `System.Threading.Lock`.

### Project conventions
- Managers must derive from `SingletonBase<T>` / `PersistentSingletonBase<T>` and check `IsInstance` after `base.Awake()`.
- New persistent managers must also be spawned in `Assets/Scripts/Editor/EditorBootstrapper.cs`.
- UI screens should be `UILayer`s shown through `UIManager`, not toggled with `SetActive` from elsewhere.
- Input must go through `InputManager.Instance`, not `Keyboard.current` / `Mouse.current` directly.
- Scene loading must go through `MainManager`.
- No namespaces. Single-statement methods use `=>`. Every class has a short `/// <summary>`.

### Repository hygiene
- Added, moved or renamed assets without their `.meta` files, or `.meta` files without their asset.
- Committed `Library/`, `Temp/`, `Logs/`, `UserSettings/`, `.csproj` or `.sln` files.
- Large hand-written changes to `.unity` / `.prefab` YAML. Ask whether it was done in the editor.
- Changes to `ProjectSettings/` or `Packages/manifest.json` that the PR description doesn't mention.
