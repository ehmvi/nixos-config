# PATH : tout est ajoute EN FIN, nix garde la priorite en cas de conflit.
# fish_add_path ignore les dossiers deja presents (pas de doublons en sous-shell),
# --global evite d ecrire dans la variable universelle fish_user_paths.
fish_add_path --global --append /opt/homebrew/bin /opt/homebrew/sbin # homebrew (bash, handbrake, mole)
fish_add_path --global --append $HOME/.npm-global/bin # npm global
fish_add_path --global --append $HOME/scripts # scripts perso
fish_add_path --global --append $HOME/.opencode/bin # opencode

if status is-interactive
    starship init fish | source
end
