{ lib
, stdenv
, fetchFromGitHub
, cmake
, magic-enum
, spdlog
, qt6
, range-v3
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
    qt6.qtbase
    qt6.qtconnectivity
    qt6.qttools
    qt6.qtlanguageserver
    libXScrnSaver
    magic-enum
    spdlog
    range-v3
  ];

  cmakeFlags = [ "-D FETCH_CONTENT=OFF" ];
  patches = [
    ./0001-add-desktop-file-and-fix-install.patch
    ./0002-allow-cmake-to-use-system-packages.patch
  ];

  nativeBuildInputs = [ cmake qt6.wrapQtAppsHook ];

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Kimai desktop client written in QT6";
    homepage = "https://github.com/AlexandrePTJ/kemai";
    license = licenses.mit;
    maintainers = with maintainers; [ poelzi ];
    platforms   = platforms.unix;
  };
}
