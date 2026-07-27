# mrustc -> rustc 1.90 -> ... -> the current Rust compiler.
# Bootstrap links use Rust-pinned LLVM; the final link uses Nixpkgs LLVM.
{
  lib,
  stdenv,
  newScope,
  callPackage,
  pkgsBuildBuild,
  pkgsBuildHost,
  pkgsBuildTarget,
  pkgsHostTarget,
  pkgsTargetTarget,
  makeRustPlatform,
  wrapRustcWith,
  llvmPackages_21,
  cargo-auditable,
  mrustcStage0,
  optimizeFinal ? false,
}@args:

let
  llvmPackages = llvmPackages_21;

  llvmSharedFor = pkgSet: pkgSet.llvmPackages_21.libllvm.override { enableSharedLibraries = true; };

  llvmSharedForBuild = llvmSharedFor pkgsBuildBuild;
  llvmSharedForHost = llvmSharedFor pkgsBuildHost;
  llvmSharedForTarget = llvmSharedFor pkgsBuildTarget;
  llvmShared = llvmSharedFor pkgsHostTarget;

  bootstrapLlvmSrc = callPackage ./bootstrap-llvm.nix { };
  distinctLlvmFroms = lib.unique (lib.filter (x: x != null) (map (e: e.llvmFrom or null) versions));
  bootstrapLlvm = lib.genAttrs distinctLlvmFroms (version: {
    shared = bootstrapLlvmSrc.libllvmFor pkgsHostTarget version;
    sharedForBuild = bootstrapLlvmSrc.libllvmFor pkgsBuildBuild version;
    sharedForHost = bootstrapLlvmSrc.libllvmFor pkgsBuildHost version;
    sharedForTarget = bootstrapLlvmSrc.libllvmFor pkgsBuildTarget version;
  });

  baseArgs = removeAttrs args [
    "llvmPackages_21"
    "cargo-auditable"
    "pkgsHostTarget"
    "mrustcStage0"
    "optimizeFinal"
  ];

  # Add wrapper attributes missing from mrustc-bootstrap.
  baseRustc = mrustcStage0.rustc // {
    unwrapped = mrustcStage0.rustc;
    inherit (pkgsBuildHost.rust_1_97.packages.prebuilt.rustc-unwrapped)
      targetPlatforms
      targetPlatformsWithHostTools
      badTargetPlatforms
      ;
  };

  # null `llvmFrom` selects the maintained LLVM.
  versions = [
    {
      version = "1.90.0";
      hash = "sha256-eZqfnLpO1TUeBxBIvPa1VgdV2QCWSN7zOkB91JYfm34=";
      llvmFrom = "1.90.0";
    }
    {
      version = "1.91.1";
      hash = "sha256-ONziBdOfYVcSYfBEQjehzp7+y5cOdg2OxNlXr1tEVyM=";
      llvmFrom = "1.90.0";
    }
    {
      version = "1.92.0";
      hash = "sha256-ng0sp1x+J1/cdYJVv0sDr7PWXRVDYCdGkHyTO2kBw7g=";
      llvmFrom = "1.90.0";
    }
    {
      version = "1.93.1";
      hash = "sha256-TCMKRLPZyfPO+VCUNxn4OABY0nyR/aXjapqUfvAT4B8=";
      llvmFrom = "1.90.0";
    }
    {
      version = "1.94.1";
      hash = "sha256-TBQqYl8S4833FsaK4Z9PYNmK0UgmJ7CFebFYOOla1RQ=";
      llvmFrom = "1.90.0";
    }
    {
      version = "1.95.0";
      hash = "sha256-6puCqD5GlnU3w1ac6db6FoEcBDqW5lE3bDSecCQcpRU=";
      llvmFrom = "1.90.0";
    }
    {
      version = "1.96.0";
      hash = "sha256-6QqesVOylIr6yEDb6dd7ZON2cG8oZDh+53F/dFAEO0Q=";
      llvmFrom = "1.90.0";
    }
    {
      version = "1.97.0";
      hash = "sha256-HAhV2JgqD7HQMhtgVLVbcy07HRfIRoQet/0Ks3vydvg=";
      llvmFrom = null;
    }
  ];

  attrName = version: "rust_" + lib.concatStringsSep "_" (lib.take 2 (lib.splitString "." version));

  nLinks = lib.length versions;

  mkLink =
    index: entry:
    let
      inherit (entry) version;
      isFinal = index == nLinks - 1;
      isBase = index == 0;
      optimize = isFinal && optimizeFinal;
      bootstrapLlvmLink =
        if (entry.llvmFrom or null) != null then bootstrapLlvm.${entry.llvmFrom} else null;
      prevAttr = attrName (lib.elemAt versions (index - 1)).version;
      override =
        if isBase then
          {
            rustc = baseRustc;
            inherit (mrustcStage0) cargo;
          }
        else
          {
            inherit (chain.${prevAttr}.packages.stable) rustc cargo;
          };
    in
    import ./default.nix {
      rustcVersion = version;
      rustcSha256 = entry.hash;

      minimal = !isFinal;
      enableRustcDev = isFinal;

      inherit optimize;

      cargoAuditable = false;

      llvmShared = if bootstrapLlvmLink != null then bootstrapLlvmLink.shared else llvmShared;
      llvmSharedForHost =
        if bootstrapLlvmLink != null then bootstrapLlvmLink.sharedForHost else llvmSharedForHost;
      llvmSharedForBuild =
        if bootstrapLlvmLink != null then bootstrapLlvmLink.sharedForBuild else llvmSharedForBuild;
      llvmSharedForTarget =
        if bootstrapLlvmLink != null then bootstrapLlvmLink.sharedForTarget else llvmSharedForTarget;
      inherit llvmPackages cargo-auditable;

      bootstrapPackagesOverride = override;

      selectRustPackage = pkgs: pkgs.rustcBootstrapChain.${attrName version};

      bootstrapVersion = version;
      bootstrapHashes = { };
    } baseArgs;

  chain = lib.listToAttrs (
    lib.imap0 (index: entry: lib.nameValuePair (attrName entry.version) (mkLink index entry)) versions
  );
in
chain
// {
  final = chain.${attrName (lib.last versions).version};
}
