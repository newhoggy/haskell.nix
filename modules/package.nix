# package descriptions in hackage will look like:
# { system, compiler, flags, pkgs, hsPkgs, pkgconfPkgs }:
# { flags = { flag1 = false; flags2 = true; ... };
#   package = { specVersion = "X.Y"; identifier = { name = "..."; version = "a.b.c.d"; };
#               license = "..."; copyright = "..."; maintainer = "..."; author = "...";
#               homepage = "..."; url = "..."; synopsis = "..."; description = "...";
#               buildType = "Simple"; # or Custom, Autoconf, ...
#             };
#  components = {
#    "..." = { depends = [ (hsPkgs.base) ... ]; };
#    exes = { "..." = { depends = ... };
#             "..." = { depends = ... }; };
#    tests = { "..." = { depends = ... }; ... };
#  };

{ lib, config, pkgs, haskellLib, ... }:

with lib;
with types;

let
  # This is just like listOf, except that it filters out all null elements.
  listOfFilteringNulls = elemType: listOf elemType // {
    # Mostly copied from nixpkgs/lib/types.nix
    merge = loc: defs:
      map (x: x.value) (filter (x: x ? value && x.value != null) (concatLists (imap1 (n: def:
        if isList def.value then
          imap1 (m: def':
            (mergeDefinitions
              (loc ++ ["[definition ${toString n}-entry ${toString m}]"])
              elemType
              [{ inherit (def) file; value = def'; }]
            ).optionalValue
          ) def.value
        else
          throw "The option value `${showOption loc}` in `${def.file}` is not a list.") defs)));
  };
in {
  # This is how the Nix expressions generated by *-to-nix receive
  # their flags argument.
  config._module.args.flags = config.flags;

  options = {
    # TODO: Add descriptions to everything.
    flags = mkOption {
      type = attrsOf bool;
    };

    package = {
      specVersion = mkOption {
        type = str;
      };

      identifier.name = mkOption {
        type = str;
      };

      identifier.version = mkOption {
        type = str;
      };

      license = mkOption {
        type = str;
      };

      copyright = mkOption {
        type = str;
      };

      maintainer = mkOption {
        type = str;
      };

      author = mkOption {
        type = str;
      };

      homepage = mkOption {
        type = str;
      };

      url = mkOption {
        type = str;
      };

      synopsis = mkOption {
        type = str;
      };

      description = mkOption {
        type = str;
      };

      buildType = mkOption {
        type = str;
      };
    };

    components = let
      componentType = submodule {
        options = {
          depends = mkOption {
            type = listOfFilteringNulls unspecified;
            default = [];
          };
          libs = mkOption {
            type = listOfFilteringNulls (nullOr package);
            default = [];
          };
          frameworks = mkOption {
            type = listOfFilteringNulls package;
            default = [];
          };
          pkgconfig = mkOption {
            type = listOfFilteringNulls package;
            default = [];
          };
          build-tools = mkOption {
            type = listOfFilteringNulls unspecified;
            default = [];
          };
          configureFlags = mkOption {
            type = listOfFilteringNulls str;
            default = config.configureFlags;
          };
          setupBuildFlags = mkOption {
            type = listOfFilteringNulls str;
            default = config.setupBuildFlags;
          };
          setupTestFlags = mkOption {
            type = listOfFilteringNulls str;
            default = config.setupTestFlags;
          };
          setupInstallFlags = mkOption {
            type = listOfFilteringNulls str;
            default = config.setupInstallFlags;
          };
          setupHaddockFlags = mkOption {
            type = listOfFilteringNulls str;
            default = config.setupHaddockFlags;
          };
          doExactConfig = mkOption {
            type = bool;
            default = config.doExactConfig;
          };
          doCheck = mkOption {
            type = bool;
            default = config.doCheck;
          };
          doCrossCheck = mkOption {
            type = bool;
            default = config.doCrossCheck;
          };
          doHaddock = mkOption {
            description = "Enable building of the Haddock documentation from the annotated Haskell source code.";
            type = bool;
            default = config.doHaddock;
          };
        };
      };
    in {
      library = mkOption {
        type = nullOr componentType;
        default = null;
      };
      sublibs = mkOption {
        type = attrsOf componentType;
        default = {};
      };
      foreignlibs = mkOption {
        type = attrsOf componentType;
        default = {};
      };
      exes = mkOption {
        type = attrsOf componentType;
        default = {};
      };
      tests = mkOption {
        type = attrsOf componentType;
        default = {};
      };
      benchmarks = mkOption {
        type = attrsOf componentType;
        default = {};
      };
      all = mkOption {
        type = componentType;
        apply = all: all // {
          # TODO: Should this check for the entire component
          # definition to match, rather than just the identifier?
          depends = builtins.filter (p: p.identifier != config.package.identifier) all.depends;
        };
        description = "The merged dependencies of all other components";
      };
    };

    name = mkOption {
      type = str;
      default = "${config.package.identifier.name}-${config.package.identifier.version}";
      defaultText = "\${config.package.identifier.name}-\${config.package.identifier.version}";
    };
    sha256 = mkOption {
      type = nullOr str;
      default = null;
    };
    src = mkOption {
      type = either path package;
      default = pkgs.fetchurl { url = "mirror://hackage/${config.name}.tar.gz"; inherit (config) sha256; };
      defaultText = "pkgs.fetchurl { url = \"mirror://hackage/\${config.name}.tar.gz\"; inherit (config) sha256; };";
    };
    cabal-generator = mkOption {
      type = nullOr str;
      default = null;
    };
    revision = mkOption {
      type = nullOr int;
      default = null;
    };
    revisionSha256 = mkOption {
      type = nullOr str;
      default = null;
    };
    patches = mkOption {
      type = listOf (either unspecified path);
      default = [];
    };
    configureFlags = mkOption {
      type = listOfFilteringNulls str;
      default = [];
    };
    setupBuildFlags = mkOption {
      type = listOfFilteringNulls str;
      default = [];
    };
    setupTestFlags = mkOption {
      type = listOfFilteringNulls str;
      default = [];
    };
    setupInstallFlags = mkOption {
      type = listOfFilteringNulls str;
      default = [];
    };
    setupHaddockFlags = mkOption {
      type = listOfFilteringNulls str;
      default = [];
    };
    preUnpack = mkOption {
      type = nullOr lines;
      default = null;
    };
    postUnpack = mkOption {
      type = nullOr string;
      default = null;
    };
    preConfigure = mkOption {
      type = nullOr string;
      default = null;
    };
    postConfigure = mkOption {
      type = nullOr string;
      default = null;
    };
    preBuild = mkOption {
      type = nullOr string;
      default = null;
    };
    postBuild = mkOption {
      type = nullOr string;
      default = null;
    };
    preCheck = mkOption {
      type = nullOr string;
      default = null;
    };
    postCheck = mkOption {
      type = nullOr string;
      default = null;
    };
    preInstall = mkOption {
      type = nullOr string;
      default = null;
    };
    postInstall = mkOption {
      type = nullOr string;
      default = null;
    };
    preHaddock = mkOption {
      type = nullOr string;
      default = null;
    };
    postHaddock = mkOption {
      type = nullOr string;
      default = null;
    };
    shellHook = mkOption {
      type = nullOr string;
      default = null;
    };
    doExactConfig = mkOption {
      type = bool;
      default = false;
    };
    doCheck = mkOption {
      type = bool;
      default = false;
    };
    doCrossCheck = mkOption {
      description = "Run doCheck also in cross compilation settings. This can be tricky as the test logic must know how to run the tests on the target.";
      type = bool;
      default = false;
    };
    doHaddock = mkOption {
      description = "Enable building of the Haddock documentation from the annotated Haskell source code.";
      type = bool;
      default = true;
    };
  };

  # This has one quirk. Manually setting options on the all component
  # will be considered a conflict. This is almost always fine; most
  # settings should be modified in either the package options, or an
  # individual component's options. When this isn't sufficient,
  # mkForce is a reasonable workaround.
  #
  # An alternative solution to mkForce for many of the options where
  # this is relevant would be to switch from the bool type to
  # something like an anyBool type, which would merge definitions by
  # returning true if any is true.
  config.components.all = lib.mkMerge (haskellLib.getAllComponents config);
}