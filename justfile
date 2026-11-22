# nixos-config. `just` pour lister.
flake := justfile_directory()

# liste les recettes
default:
    @just --list

# NIX_REMOTE : en root, nix construit sans passer par le demon, donc sans sa priorite cpu idle.
# rebuild + switch ce host
switch:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo darwin-rebuild switch --flake {{flake}}#$(scutil --get LocalHostName); \
    else \
        sudo env NIX_REMOTE=daemon nixos-rebuild switch --flake {{flake}}#$(hostname); \
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
    just bump-release pkgs/t3code-nightly.nix
    just bump-release pkgs/timon.nix
    just bump-release pkgs/timon-darwin.nix
    just bump-release pkgs/horizon-launcher.nix
    just bump-craft

# passe les apps craft de pkgs/craft-apps.json a leur derniere release github.
# les hashes du tarball linux et du dmg mac viennent du SHA256SUMS.txt de la
# release : rien a telecharger. releases/latest ignore les pre-releases. le
# fichier n'est reecrit qu'a la fin : une app en echec n'ecrit rien.
bump-craft:
    #!/usr/bin/env bash
    set -euo pipefail
    file="{{flake}}/pkgs/craft-apps.json"
    jq="$(nix build --no-link --print-out-paths --inputs-from {{flake}} nixpkgs#jq.bin)/bin/jq"
    json=$(cat "$file")
    for id in $("$jq" -r 'keys[]' <<<"$json"); do
        repo=$("$jq" -r --arg id "$id" '.[$id].repo' <<<"$json")
        current=$("$jq" -r --arg id "$id" '.[$id].version' <<<"$json")
        latest=$(curl -sSfL -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")
        version=${latest##*/v}
        if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
            echo "$repo : tag inattendu : $latest" >&2
            exit 1
        fi
        if [ "$version" = "$current" ]; then
            echo "$id : deja en $version"
            continue
        fi
        sums=$(curl -sSfL "https://github.com/$repo/releases/download/v$version/SHA256SUMS.txt")
        sum() { awk -v f="$1" '$2 == f || $2 == "*" f { print $1 }' <<<"$sums"; }
        linux=$(sum "$id-$version-linux-x86_64.tar.gz")
        darwin=$(sum "$id-$version-macos-universal.dmg")
        if [ -z "$linux" ] || [ -z "$darwin" ]; then
            echo "$repo $version : tarball linux ou dmg absent de SHA256SUMS.txt" >&2
            exit 1
        fi
        json=$("$jq" --arg id "$id" --arg v "$version" \
            --arg l "$(nix hash convert --hash-algo sha256 --to sri "$linux")" \
            --arg d "$(nix hash convert --hash-algo sha256 --to sri "$darwin")" \
            '.[$id] += { version: $v, linux: $l, darwin: $d }' <<<"$json")
        echo "$id : $current -> $version"
    done
    printf '%s\n' "$json" > "$file"

# passe un paquet de pkgs/ a la derniere release github : reecrit version et hash.
# releases/latest ignore les pre-releases : un paquet en version -nightly. prend
# la derniere nightly de la liste. un tag sans `v` (`launcher@0.2.69`) vient d'un
# monorepo : releases/latest peut y etre un autre produit, donc on prend le
# dernier tag a ce prefixe. seul le hash qui suit l'url github change. rien
# n'est ecrit si le telechargement echoue.
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
    current=$(sed -nE 's|^ *version = "(.*)";$|\1|p' "$file")
    prefix=$(printf '%s\n' "$template" | sed -nE 's|.*/releases/download/(.*)\$\{finalAttrs\.version\}/.*|\1|p')
    if [[ "$current" == *-nightly.* ]]; then
        latest=$(curl -sSfL "https://api.github.com/repos/$repo/releases?per_page=30" | grep -oE '"tag_name": *"v[^"]*-nightly\.[^"]*"' | sed -n 1p | cut -d'"' -f4 || true)
        pattern='^[0-9]+(\.[0-9]+)+-nightly\.[0-9]+\.[0-9]+$'
    elif [ "$prefix" != v ]; then
        latest=$(curl -sSfL "https://api.github.com/repos/$repo/releases?per_page=100" | grep -oE "\"tag_name\": *\"${prefix}[0-9][^\"]*\"" | sed -n 1p | cut -d'"' -f4 || true)
        pattern='^[0-9]+(\.[0-9]+)+$'
    else
        latest=$(curl -sSfL -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")
        pattern='^[0-9]+(\.[0-9]+)+$'
    fi
    version=${latest##*/v}
    version=${version#v}
    version=${version#"$prefix"}
    if ! [[ "$version" =~ $pattern ]]; then
        echo "$repo : tag inattendu : $latest" >&2
        exit 1
    fi
    if [ "$version" = "$current" ]; then
        echo "$file : deja en $version"
        exit 0
    fi
    url=${template//'${finalAttrs.version}'/$version}
    hash=$(nix hash convert --hash-algo sha256 --to sri "$(nix-prefetch-url --type sha256 "$url")")
    sed -E -i.bak -e "s|^( *version = \").*(\";)$|\\1$version\\2|" -e "\\|^ *url = \"https://github\\.com/|,\\|^ *hash = |s|^( *hash = \").*(\";)$|\\1$hash\\2|" "$file"
    rm "$file.bak"
    echo "$file : $current -> $version"
