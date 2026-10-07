# Git protocol

`$BASE` is the branch the plan lands on, recorded in the Execution log. It is often
`main`, but a resumed plan usually sits on a topic branch.

## Rules for both commit modes

- Linear history on `$BASE`. Every commit is green.
- Land cards in dependency order. A commit's staged files must not reference
  uncommitted work, because hooks that stash unstaged changes test the staged tree
  alone.
- Never put 2 cards' files in 1 commit.
- Commit a card whole: code, specs, and new files together. A split leaves the card's
  untracked files on disk under a hook that stashes, and the first commit goes red.
- Never write a tracked file in the main checkout while a hook runs. The hook rolls it
  back. Write to scratch and copy between landings.
- If a hook fails, the files stay staged. Run `git reset` before the next `git add`.
- Rebase and fast-forward merge run no hooks. Run the full suite after either.
- Message hooks run after the hooks that run the suite. Check the message against the
  repo's message rules before `git commit`. A message failure after a green suite costs
  a full rerun, and `--no-verify` is denied in auto mode.
- Keep every hook's output in a log named by card and attempt. A passing hook prints
  nothing, so the suite's example count comes from the log.
- Record `git status --porcelain` before and after each commit attempt. A hook that
  reports modified files does not name them.
- Retry a landing only when `$BASE` moved under it. Never on a red hook.
- Commit messages follow `~/.claude/reference/coding.md`. That covers commits that
  update the plan document too.

## Worktrees

Never use `isolation: worktree`. It forks from `origin/main`, so the agent opens a tree
without the cards that have already landed, and nothing tells it so.

Cut each worktree by hand, from HEAD, just before the spawn:

```bash
git check-ignore -v tmp/                                # must print a rule
git worktree add tmp/worktrees/<card> -b card/<card> HEAD
git -C tmp/worktrees/<card> log -1 --format=%h          # must equal HEAD
```

- Put worktrees in a directory the repo already ignores. If `tmp/` is not ignored, use
  one that is.
- HEAD moves each time a card lands. Cut from the current HEAD, never from a ref
  resolved earlier.
- Spawn the agent without `isolation`. The first line of its brief names the absolute
  worktree path as the only directory it may touch.
- Worktrees share the stash stack and, by default, `TMPDIR`. Agents never stash. Give
  each worktree its own `TMPDIR` if tests write there.

If an agent reports that a file the plan cites is missing, or that line numbers are
wrong throughout, suspect a stale base before plan drift. To correct it:

```bash
git -C <worktree> status --porcelain        # must be empty, else stop
git -C <worktree> merge --ff-only <head>
```

Then tell the agent with SendMessage that its base was wrong and it must re-read.

## orchestrator-commits (default)

Agents never run git. They hand back changed files and wiring diffs. The main session
applies the wiring to the shared files in the card's worktree before review. After
approval it copies the card's files into the main checkout, applies the same wiring
there, runs the full suite, and commits on `$BASE`. If a shared file changed on `$BASE`
since the review, check the wiring still applies as reviewed.

Before copying a file, check whether it changed on `$BASE` since the worktree was cut.
If it did, a whole-file copy reverts that change. Apply the card's diff as a patch
instead:

```bash
git diff <cut sha> card/<card> -- <file> | git apply -3
```

## branch-queue

Agents commit on their own branch. The main session merges 1 branch at a time.

```bash
# the agent's last act
git rebase "$BASE" && <full suite>

# the main session
if git merge-base --is-ancestor "$BASE" card/<card>; then
  <full suite in the card's worktree>
  git merge --ff-only card/<card>
else
  # $BASE moved. SendMessage the agent: rebase and verify again
fi
```

Merge branches that touch the same shared file 1 after another. Integration fixes land
with the later branch.

## Cleanup

Remove each card's worktree and branch when the card has landed and no agent will be
continued in it.

```bash
cp tmp/worktrees/<card>/.handback-*.md <scratch dir>/   # only if worth keeping
git worktree remove --force tmp/worktrees/<card>
git branch -d card/<card>
git worktree prune
```

- Use `-d`, never `-D`. If `-d` refuses, something did not land.
  Find out what.
- Hand-backs and probe scripts are untracked and die with the worktree.
- Under disk pressure, delete build output (`target/`, `node_modules/`) from worktrees
  with no running agent.

At close-out, `git worktree list` and `git branch --list` must match the start of the
run.
