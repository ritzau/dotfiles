{
  description = "Dotfiles packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    in {
      packages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.buildEnv {
            name = "dotfiles-packages";
            paths = with pkgs; [
              bat
              bottom
              buildifier
              cloc
              delta
              direnv
              eza
              fastfetch
              fd
              fzf
              git-absorb
              go
              gpustat
              htop
              just
              ncdu
              neovim
              neovim-gtk
              ripgrep
              tig
              traceroute
              tree
              uv
              xsel
              yq
              zsh
              zsh-powerlevel10k
            ];
          };
        });
    };
}
