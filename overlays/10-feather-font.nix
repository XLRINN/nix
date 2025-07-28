# Icon Font Overlay - Using reliable alternatives to Feather Font
self: super: with super; {
  # Lucide Icons - Direct successor to Feather Icons
  lucide-icons = stdenv.mkDerivation {
    name = "lucide-icons-0.263.1";
    
    src = fetchFromGitHub {
      owner = "lucide-icons";
      repo = "lucide";
      rev = "v0.263.1";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will need to update this
    };

    buildInputs = [ ];
    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      # Copy any font files if they exist
      find . -name "*.ttf" -o -name "*.otf" | xargs -I {} cp {} $out/share/fonts/truetype/ || true
    '';

    meta = with lib; {
      description = "Lucide Icons - Beautiful & consistent icon toolkit (Feather successor)";
      homepage = "https://lucide.dev";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
}
