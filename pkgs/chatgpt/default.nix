{
  lib,
  stdenvNoCC,
  fetchurl,
  rpmextract,
  buildFHSEnv,
  makeDesktopItem,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libusb1,
  libxkbcommon,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  nspr,
  nss,
  pango,
  systemd,
  xdg-utils,
}:

let
  version = "26.903.61454";

  source = stdenvNoCC.mkDerivation {
    pname = "chatgpt-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm";
      hash = "sha256-QvWilN+o4C0QJmEzl4qCy8aGJpeutgnCqJCXT5YW7LI=";
    };

    nativeBuildInputs = [ rpmextract ];
    unpackPhase = "rpmextract $src";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/share
      cp -r usr/lib/chatgpt $out/lib/
      cp -r usr/share/pixmaps $out/share/
      runHook postInstall
    '';
  };

  desktopItem = makeDesktopItem {
    name = "chatgpt";
    desktopName = "ChatGPT";
    comment = "ChatGPT by OpenAI";
    exec = "chatgpt %U";
    icon = "chatgpt";
    categories = [ "Network" "Chat" ];
    startupNotify = true;
  };
in
buildFHSEnv {
  name = "chatgpt";
  inherit version;

  targetPkgs = pkgs: [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libnotify
    libusb1
    libxkbcommon
    nspr
    nss
    pango
    systemd
    xdg-utils
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
  ];

  runScript = "${source}/lib/chatgpt/ChatGPT";

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps
    cp ${desktopItem}/share/applications/chatgpt.desktop $out/share/applications/
    cp ${source}/share/pixmaps/chatgpt.png $out/share/pixmaps/
  '';

  meta = {
    description = "Official ChatGPT desktop app for Linux";
    homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = lib.licenses.unfree;
    mainProgram = "chatgpt";
    platforms = [ "x86_64-linux" ];
  };
}
