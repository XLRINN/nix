self: super: let
  origBuildRustPackage = super.rustPlatform.buildRustPackage;
in {
  rustPlatform = super.rustPlatform // {
    # Strip deprecated arg that triggers noisy evaluation warnings on 25.05+
    buildRustPackage = args: origBuildRustPackage (builtins.removeAttrs args ["useFetchCargoVendor"]);
  };
}

