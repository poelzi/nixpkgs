{ lib
, stdenv
, fetchFromGitHub
, cmake
, magic-enum
, range-v3
, spdlog
, qtbase
, qtconnectivity
, qttools
, qtlanguageserver
, qtwayland
, wrapQtAppsHook
, libXScrnSaver
, nix-update-script
}:

stdenv.mkDerivation rec {
  pname = "kemai";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "AlexandrePTJ";
    repo = "kemai";
    rev = version;
    hash = "sha256-wclBAgeDyAIw/nGF6lzIwbwdoZMBTu+tjxsnIxIkODM=";
  };

  buildInputs = [
    qtbase
    qtconnectivity
    qttools
    qtlanguageserver
    libXScrnSaver
    magic-enum
    range-v3
    spdlog
  ] ++ lib.optional stdenv.hostPlatform.isLinux qtwayland;
  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DFETCHCONTENT_QUIET=OFF"
    "-DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=ALWAYS"
  ];

  nativeBuildInputs = [ cmake wrapQtAppsHook ];

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Kimai desktop client written in QT6";
    homepage = "https://github.com/AlexandrePTJ/kemai";
    license = licenses.mit;
    maintainers = with maintainers; [ poelzi ];
    platforms   = platforms.unix;
    mainProgram = "Kemai";
  };
}
