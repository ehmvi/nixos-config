# claude

rules for the pull request review. also read `docs/conventions.md`.
the workflow prompt repeats the hard rules, because this file is only
restored from the base branch once it is merged.

## review

- write the pull request comment in english.
- review the diff against `docs/conventions.md`.
- post one summary with `gh pr comment`.
- use an inline comment only on a line that is part of the diff.
- if code needs a fix, commit it on this pull request branch by running
  `/tmp/claude-review-commit.sh "<conventional commit subject>"`.
  that script is the only commit path. it runs `just check` before the push.
- code comments you add are lowercase french, without accents, with natural
  apostrophes (`n'est`, `qu'il`).

## never

- do not merge, approve, close, or turn on auto-merge.
- do not run `gh pr merge`, `gh pr review`, `gh api`, or `git push`.
- do not push to `main` and do not force-push.
- do not add a `Co-authored-by` trailer.
- the only author and committer is
  `ehmvi <198573042+ehmvi@users.noreply.github.com>`.
- do not print secrets, tokens, or the environment.
- do not edit `/tmp/claude-review-commit.sh`.
