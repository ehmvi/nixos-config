# module: programs/ollama
# llm local, sur localhost seulement
{ pkgs, ... }:

{
  # glm-4.7-flash en local. ollama 0.40.2 gere glm4moelite
  # (llama.cpp b11351). le paquet cuda manque dans cache.nixos.org et
  # compilerait llama.cpp avec nvcc. vulkan est deja en cache et passe
  # par le pilote nvidia deja installe. ecoute seulement sur localhost.
  # le quant q4_k_m (~19 go) se telecharge a la main, hors du store.
  # la rtx 4070 a 12 go : le surplus part en ram.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "127.0.0.1";
    openFirewall = false;
    # le modele quitte la vram 2 min apres sa derniere reponse (defaut 5 min), pour les jeux
    environmentVariables.OLLAMA_KEEP_ALIVE = "2m";
  };
}
