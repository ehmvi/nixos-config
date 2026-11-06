# module: hardware/coolercontrol
# courbes de ventilo, demon coolercontrold
{ ... }:

{
  programs.coolercontrol.enable = true;
  # le pilote nct6775 garde ses valeurs environ 1,6 s, et les relire prend 80 ms de noyau.
  # a 1 s comme a 2 s il relit donc toutes les 2 s : 4 a 5 % d'un coeur (mesure). a 3 s,
  # 2,7 % attendus. les courbes de ventilo n'ont pas besoin de plus.
  # le demon garde son config.toml dans /etc, modifiable depuis son interface : on ne
  # touche qu'a cette cle, a chaque demarrage. le commentaire et la vraie cle peuvent
  # coexister, et une cle en double l'empecherait de demarrer : on efface les deux, puis
  # on la remet une fois. si sed echoue, le demon demarre quand meme avec sa valeur.
  systemd.services.coolercontrold.preStart = ''
    if [ -f /etc/coolercontrol/config.toml ]; then
      sed -i -E -e '/^#? *poll_rate *=/d' -e '/^\[settings\]/a poll_rate = 3.0' /etc/coolercontrol/config.toml || true
    fi
  '';
}
