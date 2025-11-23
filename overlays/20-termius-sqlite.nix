final: prev:
{
  # Ensure Termius bundles libsqlite3 for NSS (libsoftokn3.so)
  termius = prev.termius.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ prev.sqlite ];
  });
}

