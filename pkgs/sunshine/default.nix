{ lib, stdenvNoCC, fetchurl, rpmextract, buildFHSEnv, pkgs }:

let
  version = "2026.906.222525";
  source = stdenvNoCC.mkDerivation {
    pname = "sunshine-release";
    inherit version;
    src = fetchurl {
      url = "https://github.com/LizardByte/Sunshine/releases/download/v${version}/Sunshine-${version}-1.fc43.x86_64.rpm";
      hash = "sha256-eQc+RjlxIlQ49FXfaEHMCqDqcqjTb03TuTw4B5JjbZI=";
    };
    nativeBuildInputs = [ rpmextract ];
    unpackPhase = "rpmextract $src";
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r usr/bin usr/lib usr/share "$out/"
      runHook postInstall
    '';
  };
in
# The official binary embeds /usr/share/sunshine paths. Give it an FHS
# environment with NixOS libraries and the release's matching assets.
buildFHSEnv {
  name = "sunshine";
  inherit version;
  targetPkgs = p: with p; [
    curl miniupnpc libopus numactl libva libx11 openssl libdrm libcap
    libevdev vulkan-loader wayland libgbm glib pipewire libpulseaudio libxtst
    libglvnd avahi qt6.qtbase qt6.qtsvg qt6.qtwayland
  ];
  runScript = "${source}/bin/sunshine";
  extraBuildCommands = ''
    mkdir -p "$out/usr/share"
    ln -s ${source}/share/sunshine "$out/usr/share/sunshine"
  '';
  profile = ''
    export QT_PLUGIN_PATH="${pkgs.qt6.qtbase}/lib/qt-6/plugins:${pkgs.qt6.qtsvg}/lib/qt-6/plugins:${pkgs.qt6.qtwayland}/lib/qt-6/plugins"
  '';
  extraInstallCommands = ''
    mkdir -p "$out/lib/udev/rules.d" "$out/share/applications" "$out/share/icons"
    cp ${source}/lib/udev/rules.d/60-sunshine.rules "$out/lib/udev/rules.d/"
    cp ${source}/share/applications/dev.lizardbyte.app.Sunshine.desktop "$out/share/applications/"
    substituteInPlace "$out/share/applications/dev.lizardbyte.app.Sunshine.desktop" \
      --replace-fail '/usr/bin/env systemctl start --u app-dev.lizardbyte.app.Sunshine' "$out/bin/sunshine"
    cp -r ${source}/share/icons/hicolor "$out/share/icons/"
  '';
  meta = {
    description = "Official Sunshine stable release for Moonlight desktop streaming";
    homepage = "https://github.com/LizardByte/Sunshine";
    license = lib.licenses.gpl3Only;
    mainProgram = "sunshine";
    platforms = [ "x86_64-linux" ];
  };
}
