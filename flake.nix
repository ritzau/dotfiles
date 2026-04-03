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
              btop
              buildifier
              cloc
              delta
              direnv
              dust
              eza
              fastfetch
              fd
              fzf
              gh
              git-absorb
              go
              gpustat
              htop
              just
              ncdu
              neovim
              neovim-gtk
              parallel
              ripgrep
              tldr
              tig
              traceroute
              tree
              uv
              xsel
              yq
              zoxide
              zsh
              zsh-powerlevel10k
            ];
          };
        });
    };
}
