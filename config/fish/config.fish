# PATH : tout est ajoute EN FIN, nix garde la priorite en cas de conflit.
# fish_add_path ignore les dossiers deja presents (pas de doublons en sous-shell),
# --path modifie PATH directement sans toucher a fish_user_paths (qui passe devant PATH).
fish_add_path --path --append /opt/homebrew/bin /opt/homebrew/sbin # homebrew (bash, handbrake, mole)
fish_add_path --path --append $HOME/.local/bin # outils locaux (claude, uv)
fish_add_path --path --append $HOME/.npm-global/bin # npm global
fish_add_path --path --append $HOME/scripts # scripts perso
fish_add_path --path --append $HOME/.opencode/bin # opencode

if status is-interactive
    starship init fish | source
end
