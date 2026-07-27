# LLVM sources pinned by Rust bootstrap releases.
{
  lib,
  fetchFromGitHub,
}:
rec {
  llvmSources = {
    "1.90.0" = {
      rev = "e8a2ffcf322f45b8dce82c65ab27a3e2430a6b51";
      hash = "sha256-KswK7h6kakY3Eb2XLx2j1lpsafu8XHE13Q6DTpdRhrM=";
      major = "20";
    };
  };

  srcFor =
    version:
    let
      s =
        llvmSources.${version}
          or (throw "bootstrap-llvm: no llvm-project pin for rust ${version}; add one to llvmSources");
    in
    fetchFromGitHub {
      owner = "rust-lang";
      repo = "llvm-project";
      inherit (s) rev hash;
      passthru = {
        owner = "rust-lang";
        repo = "llvm-project";
        inherit (s) rev;
      };
    };

  majorFor =
    version:
    (llvmSources.${version}
      or (throw "bootstrap-llvm: no llvm-project pin for rust ${version}; add one to llvmSources")
    ).major;

  mkLibllvm =
    libllvm: version:
    (libllvm.override {
      enableSharedLibraries = true;
      enablePolly = false;
      monorepoSrc = srcFor version;
    }).overrideAttrs
      (_: {
        doCheck = false;
      });

  libllvmFor = pkgSet: version: mkLibllvm pkgSet."llvmPackages_${majorFor version}".libllvm version;
}
