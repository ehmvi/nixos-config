# conventions

regles pour les changements de ce depot.

## pull requests

un sujet par pr, et un commit par changement logique.

la branche part toujours d'un `origin/main` a jour. on n'y merge jamais
`main`. l'integration se fait uniquement en rebase-and-merge, jamais en
squash.

un force-push reste limite a sa propre branche de pr, tant qu'elle n'est
pas mergee. la commande est `git push --force-with-lease`. jamais
`--force` seul.

## messages de commit

format conventional commits, voir
https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13.
le scope est le nom du module ou de l'hote : `core`, `games`, `desktop`,
`hypr`, `matugen`, etc.

- `feat` : changement visible sur un hote (paquet, service, bind, comportement)
- `fix` : repare un comportement casse
- `refactor` : rien de visible ne change
- `perf`, `style`, `docs`
- `build` : plomberie nix sans effet visible (sorties du flake, `pkgs/`, dependances). un bump d'input s'ecrit `build(flake): bump <input>`
- `ops` : ci et infrastructure du depot (`.github`, verifications du justfile)
- `chore` : menage divers, comme `.gitignore`

la config d'un hote (paquets, services) est un `feat` ou un `fix`, pas un `ops`.

mizu (compte github `ehmvi`) est le seul auteur et le seul committer,
sous l'identite `ehmvi <198573042+ehmvi@users.noreply.github.com>`.
aucun trailer `Co-authored-by`.

## commentaires

en minuscules, en francais, sans accents et sans emoji. les apostrophes
naturelles restent (`n'est`, `d'usage`). on reformule au lieu d'ecrire
`l architecture`.

les fichiers anciens restent tels quels. un nettoyage d'accents, s'il est
voulu, va dans son propre commit `style:`, separe de tout changement
fonctionnel.

## avant de pousser

lancer `just check`. pour un extrait d'activation darwin, le verifier
avec shellcheck, ou lancer `just build` sur sommei : nix-darwin echoue
sur un avertissement shellcheck.

## secrets et verrou

aucun secret dans le depot. mizu lance `just update` lui-meme. une pr
qui ne fait que bumper le lock n'a pas lieu d'etre, sauf si elle corrige
un vrai probleme (`build(flake): bump <input>`).
