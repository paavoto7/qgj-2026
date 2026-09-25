# How to commit?

The repository has branch protection rules activated for *main*.
To add changes, create a new branch, add your changes to it and push that to the remote repository.
Then create a pull request for it and merge, if no conflicts arise.

## On branches
Before creating a new branch from `main`, always `pull` or alternatively `fetch`.

This helps to avoid merge conflicts and creating features for old APIs etc.

If problems arise, merge or rebase main to your branch. Ask for help if needed.

## Step by step

### Getting the repo
1. Clone: `git clone https://github.com/paavoto7/qgj-2026.git` or `git clone git@github.com:paavoto7/qgj-2026.git`

### Creating a branch
1. Pull: `git pull origin main`
2. Create a branch: `git branch [branch]`
    - Or alternatively to create and checkout `git checkout -b [branch]`
3. Change branch: `git checkout [branch]`

### After adding code/assets
1. Check that no cache/config etc. files are being committed with e.g. `git status`
2. Stage: `git add [files to add or .]`
3. Commit: `git commit -m [message]`
4. Push: `git push origin [branch]`

### Adding changes to main
1. Create a pull request for your branch
2. Merge the branch, no reviewers mandated

# Godot
- Use the editor version in [README.md](README.md), the **.NET build**. Others might break the project for everyone.
- Always commit the `.uid` and `.import` files together with their scripts and assets. Never commit `.godot/`.
- Rename and move files in the Godot FileSystem dock, not in Explorer, so references get updated.
- Never work on the same scene at the same time as someone else, scenes merge badly.
    - Split things into their own scenes and edit those instead.
    - For testing, make your own scene in `scenes/sandbox/[name]/`.
- Mention changes to Project Settings (input actions, autoloads, layers) in your PR, they all end up in `project.godot`.

## Languages
GDScript is the default. C# is fine for your own features, but keep a feature in one language and write shared code (autoloads, base classes, Resources) in GDScript.

## Code style
Follow `.editorconfig`.

### GDScript
Follow the [official style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):
- Tabs for indentation.
- Static typing everywhere.
- `snake_case` for files, variables and functions, `PascalCase` for `class_name`. Private members start with `_`.
- A short `##` doc comment for each script.

```gdscript
class_name Example
extends Node3D
## Is responsible for something.

@export var speed: float = 1.0

var is_moving: bool = false


func stop() -> void:
	is_moving = false


func _physics_process(delta: float) -> void:
	if is_moving:
		translate(Vector3.FORWARD * speed * delta)
	else:
		pass # ...
```

### C#
- Braces on their own line.
- No namespaces.
- Script classes are `partial` and named like their file.
- `[Export] private` fields in camelCase.
- A short summary for each class.
- Single-statement methods use arrow notation (`=>`).

```csharp
using Godot;

/// <summary>
/// Is responsible for something.
/// </summary>
public partial class Example : Node3D
{
    [Export] private float speed = 1f;

    public bool IsMoving { get; private set; }

    public void Stop() => IsMoving = false;

    public override void _PhysicsProcess(double delta)
    {
        if (IsMoving)
        {
            Translate(Vector3.Forward * speed * (float)delta);
        }
        else
        {
            // ...
        }
    }
}
```
