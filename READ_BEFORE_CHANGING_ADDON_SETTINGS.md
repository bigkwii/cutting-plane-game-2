# READ THIS IF YOU'RE MESSING WITH ADDON SETTINGS AND SPECIALLY WITH THE LEADERBOARDS

Talo Leaderboards require you to add a token to `addons/talo/settings.cfg`. DO NOT PUSH THIS TOKEN TO GITHUB!

Make sure your local repo ignores `addons/talo/settings.cfg` by running:

```bash
git update-index --skip-worktree addons/talo/settings.cfg
```

And if you make changes to `addons/talo/settings.cfg` that you want to keep, you can run:

```bash
git update-index --no-skip-worktree addons/talo/settings.cfg
```

...before committing your changes.

If you screw up, [get some help](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
