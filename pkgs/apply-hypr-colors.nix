# apply-hypr-colors : applique en direct aux bordures hyprland les couleurs
# que matugen vient d ecrire dans ~/.config/hypr/matugen-colors.lua.
# hyprctl eval = execute du lua dans hyprland. stdout jete (wayle lit la
# sortie de matugen), stderr reste visible.
{
  writeShellApplication,
  hyprland,
}:

writeShellApplication {
  name = "apply-hypr-colors";
  runtimeInputs = [ hyprland ];
  text = ''
    hyprctl eval 'local t = dofile(os.getenv("HOME") .. "/.config/hypr/matugen-colors.lua"); hl.config({ general = { col = { active_border = { colors = { t.active_border }, angle = 45 }, inactive_border = t.inactive_border } } })' > /dev/null
  '';
}
