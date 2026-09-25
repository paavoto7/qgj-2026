# Jam start checklist
Only one person does this, the rest wait until the PR is merged and then pull.

## 1. Create the Unity project
1. Unity Hub > New project > Unity **6000.6.2f1** > *Universal 2D* or *Universal 3D*.
2. Create it in a **temporary folder** outside the repo (Hub refuses non-empty folders).
3. Close the editor.

## 2. Move it into the repo
1. Copy `Packages/` and `ProjectSettings/` from the temp project to the repo root.
2. Copy the contents of the temp project's `Assets/` into the repo's `Assets/`, e.g. `Settings/`, `Scenes/`.
    - If the template has its own `InputSystem_Actions.inputactions`, **keep ours** (don't overwrite it, including the `.meta`).
3. Don't copy `Library/`, `Temp/`, `Logs/`, `UserSettings/` or any `.csproj`/`.sln` files.
4. Open the repo root in Unity Hub (Add > Add project from disk) and open it. Check the console for errors.

## 3. Project settings
- Player > Other Settings > Active Input Handling = *Input System Package (New)*.
- Input System Package > Project-wide Actions = `Assets/InputSystem_Actions`.
- Editor > Asset Serialization = *Force Text* (default).
- Window > TextMeshPro > Import TMP Essential Resources.

## 4. Scenes and prefabs
1. Create `Assets/Scenes/MainMenu.unity` and `Assets/Scenes/Game.unity`.
2. Build Profiles / Build Settings order: `MainMenu` (0), `Game` (1).
3. Create `Assets/Prefabs/MainManager.prefab` with a `MainManager` component.
    - Optionally assign a loading screen prefab (a Canvas with `LoadingScreen` and `LoadingBar`).
4. In `MainMenu`:
    - Add the `MainManager` prefab.
    - Add a GameObject with `InputManager` and one with `SoundManager` (adds an `AudioSource`).
    - Add a Canvas with `UIManager` and a child panel with `MainMenu`. Set it as the UIManager's *Start Layer* and add it to *UI Layers*.
    - Hook the Play button to `MainMenu.PlayGame` and Quit to `MainMenu.QuitGame`.
    - Check that the EventSystem uses `InputSystemUIInputModule`.
5. In `Game`:
    - Add a Canvas with `UIManager`, a child `PauseMenu` panel (Resume and Quit buttons) and `PauseMenuController` referencing it.
    - Add the `PauseMenu` to the UIManager's *UI Layers*. Tick *Is Overlay* on it to keep the HUD visible under it.
    - Untick *Lock Cursor On Resume* on `PauseMenuController` if the game uses the mouse cursor.
6. Pressing Play in `Game` directly should work too, `EditorBootstrapper` spawns the missing managers.

## 5. Commit
1. `git checkout -b project-setup`
2. `git status`, check that no `Library/` etc. is included.
3. Commit, push and open a PR. Once merged, tell everyone to pull.
