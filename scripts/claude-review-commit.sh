#!/usr/bin/env bash
# seul chemin de commit pour la revue claude.
# verifie la branche, lance `just check`, commit en tant qu'ehmvi, pousse sans option.
# pas de merge, pas de force-push, pas de trailer co-authored-by.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: claude-review-commit.sh <message conventional>" >&2
  exit 1
fi

MESSAGE="$*"
AUTHOR_NAME="ehmvi"
AUTHOR_EMAIL="198573042+ehmvi@users.noreply.github.com"
EXPECTED_FILE="/tmp/pr-head-ref"

# le message est un sujet conventional, une seule ligne, sans trailer
if [[ "$MESSAGE" == *$'\n'* ]]; then
  echo "le message tient sur une ligne" >&2
  exit 1
fi
if printf '%s\n' "$MESSAGE" | grep -qi 'co-authored-by:'; then
  echo "co-authored-by interdit" >&2
  exit 1
fi
if ! printf '%s\n' "$MESSAGE" | grep -Eq '^(feat|fix|docs|style|refactor|perf|build|ops|chore)(\([a-z0-9._/-]+\))?!?: .+'; then
  echo "message conventional commits requis (feat, fix, docs, style, refactor, perf, build, ops, chore)" >&2
  exit 1
fi

if [[ ! -f "$EXPECTED_FILE" ]]; then
  echo "branche de la pr inconnue (${EXPECTED_FILE} absent)" >&2
  exit 1
fi
EXPECTED="$(tr -d '[:space:]' < "$EXPECTED_FILE")"
case "$EXPECTED" in
  "" | main | master)
    echo "refus: branche cible invalide" >&2
    exit 1
    ;;
esac

cd "$(git rev-parse --show-toplevel)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "$EXPECTED" ]]; then
  echo "refus: sur ${BRANCH}, la pr est ${EXPECTED}" >&2
  exit 1
fi

# le push avec GITHUB_TOKEN ne relance pas le workflow check, donc on verifie ici
nix fmt
nix shell --inputs-from . nixpkgs#just -c just check

git add -A
if ! git diff --cached --quiet; then
  # -c gagne sur la config du job ; l'env gagne sur -c, on fixe les deux
  export GIT_AUTHOR_NAME="$AUTHOR_NAME"
  export GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL"
  export GIT_COMMITTER_NAME="$AUTHOR_NAME"
  export GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL"
  git -c user.name="$AUTHOR_NAME" \
    -c user.email="$AUTHOR_EMAIL" \
    -c core.hooksPath=/dev/null \
    commit -m "$MESSAGE"
fi

if git rev-parse --verify --quiet "origin/${BRANCH}" >/dev/null; then
  if [[ "$(git rev-parse HEAD)" == "$(git rev-parse "origin/${BRANCH}")" ]]; then
    echo "rien a pousser"
    exit 0
  fi
fi

# sans option : pas de --force, pas de --receive-pack
git push origin HEAD
