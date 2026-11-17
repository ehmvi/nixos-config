$env.config.show_banner = false

# historique en sqlite : horodatage, dossier et code de sortie de chaque commande
$env.config.history.file_format = "sqlite"
# 100k entrees, la valeur par defaut, posee ici pour qu'elle reste visible
$env.config.history.max_size = 100_000
# historique partage entre les shells ouverts (seulement en sqlite)
$env.config.history.isolation = false

# completions floues et sans casse : `dcm` trouve `Documents`
$env.config.completions.algorithm = "fuzzy"
$env.config.completions.case_sensitive = false

# ctrl+o ouvre la ligne courante dans zed. --wait : nu attend la fermeture de l'onglet
$env.config.buffer_editor = ["zeditor", "--wait"]

# curseur en barre fine, comme dans wezterm
$env.config.cursor_shape.emacs = "line"

# pied de tableau (noms des colonnes) seulement quand l'en-tete sort de l'ecran
$env.config.footer_mode = "auto"
