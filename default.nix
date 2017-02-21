{ pkgs ? import ./pkgs.nix }:

let
  blog-env = pkgs.bundlerEnv rec {
    name = "blog-env-setup";

    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };

in

pkgs.stdenv.mkDerivation {
  name = "blog-env";
  src = ./.;
  buildInputs = [ pkgs.ruby blog-env ];
}