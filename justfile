# nixos-config. `just` pour lister.
flake := justfile_directory()

# liste les recettes
default:
    @just --list

# rebuild + switch ce host
switch:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo darwin-rebuild switch --flake {{flake}}#$(scutil --get LocalHostName); \
    else \
        sudo nixos-rebuild switch --flake {{flake}}#$(hostname); \
    fi

# build seul, pas d'activation
build:
    @if [ "$(uname)" = "Darwin" ]; then \
        darwin-rebuild build --flake {{flake}}#$(scutil --get LocalHostName); \
    else \
        nixos-rebuild build --flake {{flake}}#$(hostname); \
    fi

# formate tous les fichiers nix
fmt:
    nix fmt

# statix + deadnix, épinglés au nixpkgs du lock (--inputs-from garantit que
# local et CI lancent la même version des linters)
lint:
    nix run --inputs-from {{flake}} nixpkgs#statix -- check .
    nix run --inputs-from {{flake}} nixpkgs#deadnix -- --fail .

# gate local : format + lint. miroir exact de ce que fait la CI.
check:
    nix build --no-link {{flake}}#checks.$(nix eval --impure --raw --expr 'builtins.currentSystem').formatting
    just lint
    just eval

# évalue les 3 hosts sans rien construire : attrape options inexistantes et fautes de frappe
eval:
    nix eval {{flake}}#nixosConfigurations.navi.config.system.build.toplevel.drvPath
    nix eval {{flake}}#nixosConfigurations.games.config.system.build.toplevel.drvPath
    nix eval {{flake}}#darwinConfigurations.sommei.config.system.build.toplevel.drvPath

# cherche des secrets (cles, tokens, mots de passe) dans tout l historique git.
# repo public : un secret commite reste lisible dans l historique meme apres suppression.
scan:
    nix run --inputs-from {{flake}} nixpkgs#gitleaks -- git {{flake}} --redact --verbose

# met a jour un seul input, ex : `just bump nixpkgs`
bump input:
    nix flake update {{input}}

# met a jour tous les inputs et les paquets suivis sur les releases github
update:
    nix flake update
    just bump-release pkgs/artcraft-launcher.nix

# passe un paquet de pkgs/ a la derniere release github : reecrit version et hash.
# releases/latest ignore les pre-releases. rien n'est ecrit si le telechargement echoue.
bump-release file:
    #!/usr/bin/env bash
    set -euo pipefail
    file="{{file}}"
    template=$(sed -nE 's|^ *url = "(https://github\.com/.*)";$|\1|p' "$file")
    if [ -z "$template" ] || [ "$(printf '%s\n' "$template" | wc -l)" -ne 1 ]; then
        echo "$file : il faut une seule url github" >&2
        exit 1
    fi
    repo=$(printf '%s\n' "$template" | cut -d/ -f4-5)
    latest=$(curl -sSfL -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")
    version=${latest##*/v}
    if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
        echo "$repo : tag inattendu : $latest" >&2
        exit 1
    fi
    current=$(sed -nE 's|^ *version = "(.*)";$|\1|p' "$file")
    if [ "$version" = "$current" ]; then
        echo "$file : deja en $version"
        exit 0
    fi
    url=${template//'${finalAttrs.version}'/$version}
    hash=$(nix hash convert --hash-algo sha256 --to sri "$(nix-prefetch-url --type sha256 "$url")")
    sed -E -i.bak -e "s|^( *version = \").*(\";)$|\\1$version\\2|" -e "s|^( *hash = \").*(\";)$|\\1$hash\\2|" "$file"
    rm "$file.bak"
    echo "$file : $current -> $version"
