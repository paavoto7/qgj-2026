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

# Unity
- Use the editor version in [README.md](README.md), others might break the project for everyone.
- Always commit the `.meta` files together with their assets. Missing meta files break references.
- Never work on the same scene at the same time as someone else, scenes merge badly.
    - Make things into prefabs and edit those instead.
    - For testing, make your own scene in `Assets/Scenes/Sandbox/[name]`.
- Keep Asset Serialization as *Force Text* (Project Settings > Editor).

## Code style
Follow the existing scripts and `.editorconfig`:
- Braces on their own line.
- No namespaces.
- `[SerializeField] private` fields in camelCase.
- A short summary for each class.
- Single-statement methods use arrow notation (`=>`).
- Unity compiles C# 9, so don't use newer syntax such as file-scoped namespaces or collection expressions (`[]`).

```csharp
/// <summary>
/// Is responsible for something.
/// </summary>
public class Example : MonoBehaviour
{
    [SerializeField] private float speed = 1f;

    public bool IsMoving { get; private set; }

    public void Stop() => IsMoving = false;

    private void Update()
    {
        if (IsMoving)
        {
            transform.Translate(speed * Time.deltaTime * Vector3.forward);
        }
        else
        {
            // ...
        }
    }
}
```
