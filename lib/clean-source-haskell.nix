# This is a source filter function which cleans common build products
# and files not needed to do a haskell build from a source directory.
#
# This can avoid unnecessary builds when these files change.
#
# It should be used with "pkgs.lib.cleanSourceWith". Alternatively,
# use the convenience function "cleanSourceHaskell".
#
{ lib }:

rec {
  haskellSourceFilter = name: type:
    let baseName = baseNameOf (toString name);
    in ! (
      # Filter out cabal build products.
      baseName == "dist" || baseName == "dist-newstyle" ||
      baseName == "cabal.project.local" ||
      lib.hasPrefix ".ghc.environment" baseName ||
      # Filter out stack build products.
      lib.hasPrefix ".stack-work" baseName ||
      # Filter out files left by ghci
      lib.hasSuffix ".hi" baseName ||
      # Filter out files generated by "hasktags"
      baseName == "TAGS" || baseName == "tags" ||
      # Filter out files which are commonly edited but don't
      # affect the cabal build.
      lib.hasSuffix ".nix" baseName
    );

  # Like pkgs.lib.cleanSource, but adds Haskell files to the filter.
  cleanSourceHaskell = { src, name ? null }:
    let
      clean = lib.cleanSourceWith {
        filter = haskellSourceFilter;
        src = lib.cleanSource src;
        inherit name;
      };
      # Copy function from 19.09 for compatibility with 19.03.
      # Does require at least Nix 2.0.
      compat = let
        isFiltered = src ? _isLibCleanSourceWith;
        origSrc = if isFiltered then src.origSrc else src;
        filter' = name: type: haskellSourceFilter name type && lib.cleanSourceFilter name type;
        name' = if name != null then name else if isFiltered then src.name else baseNameOf src;
      in {
        inherit origSrc;
        filter = filter';
        outPath = builtins.path { filter = filter'; path = origSrc; name = name'; };
        _isLibCleanSourceWith = true;
        name = name';
      };
    in
      if (builtins.typeOf src) == "path"
      then (if lib.versionAtLeast lib.version "19.09" then clean else compat) else src;
}
