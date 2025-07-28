# Icon Font Overlay - Using reliable alternatives to Feather Font
self: super: with super; {
  # This overlay can be used to add custom icon fonts if needed
  # For now, we'll use existing nixpkgs icon fonts instead
  
  # Example: If you want to add a custom icon font later, add it here
  # custom-icon-font = stdenv.mkDerivation {
  #   name = "custom-icon-font-1.0";
  #   src = fetchFromGitHub { ... };
  #   ...
  # };
}
