{ lib
, rustPlatform
#, nodejs
, rustc-wasm32
, clippy
, tailwindcss
, cargo-tauri
, trunk
, rustc
, gnumake
, cmake
, gcc
, clang
, rustfmt
, fetchFromGitHub
, pkg-config
, wrapGAppsHook
, symlinkJoin
, atk
, bzip2
, jq
, cairo
, dbus
, gdk-pixbuf
, glib
, gtk3
, libayatana-appindicator
, libsoup
, openssl
, pango
, sqlite
, webkitgtk
, zstd
, stdenv
, darwin
}:let
 rust-lld = symlinkJoin {
    name = "rust-lld";
    paths = [ rustc-wasm32.llvmPackages.lld ];
    postBuild = ''
      ln -s $out/bin/lld $out/bin/rust-lld
    '';
  };
in

rustPlatform.buildRustPackage rec {
  pname = "spyglass";
  version = "2023.5.1";

  src = fetchFromGitHub {
    owner = "spyglass-search";
    repo = "spyglass";
    rev = "v${version}";
    hash = "sha256-+NEuWhEQEtATn2bIcTtBgBrJ1JjJtkTzZUlaZ7dxhw0=";
  };

  model_src = builtins.fetchurl {
    url = "https://ggml.ggerganov.com/ggml-model-whisper-base.en.bin";
    sha256 = "sha256:00nhqqvgwyl9zgyy7vk9i3n017q2wlncp5p7ymsk0cpkdp47jdx0";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "auth_core-0.1.0" = "sha256-6f/mAAt4zhMgEASrZZO8cAvNLG4DvwIte9eBI1VOa+8=";
      "docx-1.1.2" = "sha256-H5KjtrbWlr2+js9JX6EsEX0/leIGBRXSVeToON77GL4=";
      "fix-path-env-0.0.0" = "sha256-+CI11TM+dGQZL40790N6WQJrm41z/3kDej2RwfzOZDs=";
      "hard-xml-0.0.0" = "sha256-hCGa8pswxo8KdFDv5kzqPmgGM6yYyUngMJ6K3uVNUpA=";
      "tauri-plugin-deep-link-0.1.0" = "sha256-ShfTOK3QR1oLHMqpDfILjWXS7A0z8TB4knS3VirlOUA=";
      "whisper-rs-0.6.0" = "sha256-VRL+Khs8nCknDPPhC4tSCdQ8wWnzH8D9yR9FS6HOiRQ=";
    };
  };

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
    wrapGAppsHook
    rustfmt
    gnumake
    cmake
    clang
    tailwindcss
    cargo-tauri
    clippy
    trunk
    rustc-wasm32
    rustPlatform.bindgenHook
    rustc.llvmPackages.lld
    rust-lld
    #rustcWithWasm
  ];

  buildPhase = ''
  make build-release
  '';


  # TODO:
  # it would be nice to set '| .tauri.updater.active = false ' in jq as well but this
  # will require some #[ifcfg(feature = updater)] patches
  postPatchPhase = ''
  substituteInPlace Makefile --replace "npx tailwindcss" "tailwindcss"
  cp .env.template .env
  mkdir -p assets/models
  cp ${model_src} assets/models/whisper.base.en.bin
  # cat crates/tauri/tauri.conf.json | ${jq}/bin/jq '.tauri.bundle.active = false | ' > crates/tauri/tauri.conf.json.new
  #mv crates/tauri/tauri.conf.json.new crates/tauri/tauri.conf.json
  '' + lib.optionalString stdenv.isLinux ''
        substituteInPlace $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
          --replace "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
  '';





  buildInputs = [
    atk
    bzip2
    cairo
    dbus
    libsoup
    openssl
    pango
    sqlite
    webkitgtk
    zstd
  ] ++ lib.optionals stdenv.isLinux [
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
  ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    AppKit
    CoreFoundation
    CoreGraphics
    CoreServices
    Foundation
    Security
    SystemConfiguration
  ]);

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = with lib; {
    description = "A personal search engine:  Create a searchable library from your personal documents, interests, and more";
    homepage = "https://github.com/spyglass-search/spyglass";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ poelzi ];
    mainProgram = "spyglass";
  };
}
