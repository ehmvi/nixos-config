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

# statix + deadnix + shellcheck de l'activation darwin (nix-darwin echoue sur
# un avertissement shellcheck). --inputs-from epingle local et CI au meme lock.
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    nix run --inputs-from {{flake}} nixpkgs#statix -- check .
    nix run --inputs-from {{flake}} nixpkgs#deadnix -- --fail .
    nix eval --raw {{flake}}#darwinConfigurations.sommei.config.system.activationScripts.postActivation.text \
        | nix run --inputs-from {{flake}} nixpkgs#shellcheck -- --shell=bash -

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

# controle rapide (lecture seule, sans build) de l'etat reel de cet hote :
# unites en echec, liens nix casses, mimeapps obsoletes, garde-fous materiels.
doctor:
    #!/usr/bin/env bash
    set -euo pipefail
    issues=0
    ok()   { printf 'ok    %s\n' "$1"; }
    warn() { printf 'warn  %s\n' "$1"; issues=$((issues + 1)); }

    if [ "$(uname)" = "Darwin" ]; then
        host=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
        if [ "$host" = "sommei" ]; then
            ok "LocalHostName = sommei"
        else
            warn "LocalHostName = $host (attendu : sommei)"
        fi
        if [ -d /Library/Audio/Plug-Ins/HAL/BlackHole2ch.driver ]; then
            ok "BlackHole2ch.driver present"
        else
            warn "BlackHole2ch.driver absent de /Library/Audio/Plug-Ins/HAL"
        fi
        if [ -f "$HOME/Library/Application Support/zen/profiles.ini" ]; then
            ok "zen profiles.ini present"
        else
            warn "zen profiles.ini absent"
        fi
    else
        host=$(hostname)
        sys_failed=$(systemctl --failed --no-legend --plain | awk '{print $1}')
        if [ -z "$sys_failed" ]; then
            ok "systemd systeme : 0 unite en echec"
        else
            warn "systemd systeme en echec : $(printf '%s' "$sys_failed" | tr '\n' ' ')"
        fi
        usr_failed=$(systemctl --user --failed --no-legend --plain 2>/dev/null | awk '{print $1}' || true)
        if [ -z "$usr_failed" ]; then
            ok "systemd utilisateur : 0 unite en echec"
        else
            warn "systemd utilisateur en echec : $(printf '%s' "$usr_failed" | tr '\n' ' ')"
        fi

        # seuls les liens casses vers /nix/store comptent (chrome/electron utilisent des liens Singleton* casses)
        broken=()
        while IFS= read -r -d '' link; do
            case "$(readlink "$link" 2>/dev/null || true)" in
                /nix/store/*) broken+=("$link") ;;
            esac
        done < <(find "$HOME/.config" -maxdepth 4 -xtype l -print0 2>/dev/null || true)
        if [ "${#broken[@]}" -eq 0 ]; then
            ok "liens hjem/nix dans ~/.config : tous valides"
        else
            warn "liens /nix/store casses : ${broken[*]}"
        fi

        # verifie que chaque .desktop de ~/.config/mimeapps.list existe encore
        if [ -f "$HOME/.config/mimeapps.list" ]; then
            dead=()
            while IFS= read -r desktop; do
                found=0
                IFS=: read -ra dirs <<< "${XDG_DATA_DIRS:-/usr/share}:/run/current-system/sw/share:${XDG_DATA_HOME:-$HOME/.local/share}"
                for dir in "${dirs[@]}"; do
                    if [ -f "$dir/applications/$desktop" ]; then found=1; break; fi
                done
                [ "$found" -eq 0 ] && dead+=("$desktop")
            done < <(awk -F= '/^[^[#]/ && NF>=2 { n=split($2,a,";"); for(i=1;i<=n;i++) if(a[i] ~ /\.desktop$/) print a[i] }' "$HOME/.config/mimeapps.list" | sort -u)
            if [ "${#dead[@]}" -eq 0 ]; then
                ok "mimeapps.list : toutes les cibles .desktop existent"
            else
                warn "mimeapps.list pointe vers des .desktop absents : ${dead[*]}"
            fi
        fi

        if [ "$host" = "games" ]; then
            if command -v nvidia-smi >/dev/null 2>&1; then
                pl=$(nvidia-smi --query-gpu=power.limit --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')
                case "$pl" in
                    170|170.0|170.00) ok "gpu power limit = ${pl} W" ;;
                    *) warn "gpu power limit = ${pl:-inconnu} W (attendu : 170 W)" ;;
                esac
            fi
        elif [ "$host" = "navi" ]; then
            for bat in /sys/class/power_supply/BAT*; do
                [ -r "$bat/charge_control_end_threshold" ] || continue
                start=$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "?")
                end=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "?")
                if [ "$start" = "75" ] && [ "$end" = "80" ]; then
                    ok "batterie $(basename "$bat") : seuils ${start}/${end} %"
                else
                    warn "batterie $(basename "$bat") : seuils ${start}/${end} % (attendu : 75/80 %)"
                fi
            done
        fi

        wayle_log=$(find "$HOME/.local/state/wayle" -maxdepth 1 -name 'wayle-shell.*.log' 2>/dev/null | sort | tail -n1 || true)
        if [ -n "$wayle_log" ]; then
            if grep -qE 'Read-only file system|deprecated config key' "$wayle_log"; then
                warn "wayle : avertissements config/schema dans $(basename "$wayle_log")"
            else
                ok "wayle : aucun avertissement config/schema dans $(basename "$wayle_log")"
            fi
        fi
    fi

    [ "$issues" -eq 0 ]

# cherche des secrets (cles, tokens, mots de passe) dans tout l historique git.
# repo public : un secret commite reste lisible dans l historique meme apres suppression.
scan:
    nix run --inputs-from {{flake}} nixpkgs#gitleaks -- git {{flake}} --redact --verbose

# met a jour un seul input, ex : `just bump nixpkgs`
bump input:
    nix flake update {{input}}

# le `-` devant chaque bump laisse continuer si un depot amont tombe (404,
# release cassee) : l erreur s affiche, le paquet garde sa version.
# met a jour tous les inputs et les paquets suivis sur les releases github
update:
    nix flake update
    -just bump-release pkgs/artcraft-launcher.nix
    -just bump-release pkgs/t3code-nightly.nix
    -just bump-release pkgs/timon.nix
    -just bump-release pkgs/timon-darwin.nix
    -just bump-release pkgs/horizon-launcher.nix
    -just bump-release pkgs/see.nix
    -just bump-release pkgs/see-darwin.nix
    -just bump-craft
    -just bump-ladybird

# passe pkgs/ladybird.nix et pkgs/ladybird-darwin.nix a la derniere release.
# version et sha256 mac viennent de download.ladybird.org/releases.json, le
# sha256 du .deb 24.04 de l'index apt : rien a telecharger.
bump-ladybird:
    #!/usr/bin/env bash
    set -euo pipefail
    linux_file="{{flake}}/pkgs/ladybird.nix"
    darwin_file="{{flake}}/pkgs/ladybird-darwin.nix"
    jq="$(nix build --no-link --print-out-paths --inputs-from {{flake}} nixpkgs#jq.bin)/bin/jq"
    rel=$(curl -sSfL "https://download.ladybird.org/releases.json")
    version=$("$jq" -r '.releases[0].version // empty' <<<"$rel")
    if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
        echo "ladybird : version inattendue : $version" >&2
        exit 1
    fi
    current_linux=$(sed -nE 's|^ *version = "(.*)";$|\1|p' "$linux_file")
    current_darwin=$(sed -nE 's|^ *version = "(.*)";$|\1|p' "$darwin_file")
    if [ "$version" = "$current_linux" ] && [ "$version" = "$current_darwin" ]; then
        echo "ladybird : deja en $version"
        exit 0
    fi
    darwin_hex=$("$jq" -r '.releases[0].downloads[] | select(.platform == "macOS" and .architecture == "arm64") | .sha256' <<<"$rel" | head -n1)
    linux_hex=$(curl -sSfL "https://apt.ladybird.org/dists/noble/main/binary-amd64/Packages" \
        | awk -v f="pool/main/l/ladybird/ladybird_${version}-1~ubuntu24.04_amd64.deb" '
            /^Filename: / { match_pkg = ($2 == f) }
            match_pkg && /^SHA256: / { print $2; exit }
        ')
    if [ -z "$linux_hex" ] || [ -z "$darwin_hex" ]; then
        echo "ladybird $version : sha256 linux ou darwin absent" >&2
        exit 1
    fi
    linux_hash=$(nix hash convert --hash-algo sha256 --to sri "$linux_hex")
    darwin_hash=$(nix hash convert --hash-algo sha256 --to sri "$darwin_hex")
    sed -E -i.bak \
        -e "s|^( *version = \").*(\";)$|\\1$version\\2|" \
        -e "s|^( *hash = \").*(\";)$|\\1$linux_hash\\2|" "$linux_file"
    rm "$linux_file.bak"
    sed -E -i.bak \
        -e "s|^( *version = \").*(\";)$|\\1$version\\2|" \
        -e "s|^( *hash = \").*(\";)$|\\1$darwin_hash\\2|" "$darwin_file"
    rm "$darwin_file.bak"
    echo "ladybird : $current_linux -> $version"

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
