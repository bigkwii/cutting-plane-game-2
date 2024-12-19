# READ THIS IF YOU'RE MESSING WITH THE LEADERBOARDS

Quiver Leaderboards require you to add a token to your project.godot file. DO NOT PUSH THIS TOKEN TO GITHUB!

Make sure your local repo ignores project.godot by running:

```bash
git update-index --skip-worktree project.godot
```

And if you make changes to project.godot that you want to keep, you can run:

```bash
git update-index --no-skip-worktree project.godot
```

...before committing your changes.
