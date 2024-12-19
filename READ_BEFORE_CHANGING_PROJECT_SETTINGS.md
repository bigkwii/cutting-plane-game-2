# READ THIS IF YOU'RE MESSING WITH THE PROJECT SETTINGS AND SPECIALLY WITH THE LEADERBOARDS

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

If you screw up, [get some help](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
