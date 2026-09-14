{ lib
, stdenv
, python3
, wrapGAppsHook4
, gtk4
, gtk4-layer-shell
, playerctl
, glib
, dbus
, gobject-introspection
, pango
, gdk-pixbuf
, graphene
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    pygobject3
    pycairo
  ]);
  giTypelibs = lib.makeSearchPath "lib/girepository-1.0" [
    gtk4
    gtk4-layer-shell
    gobject-introspection
    pango
    gdk-pixbuf
    graphene
    glib
  ];
in
stdenv.mkDerivation {
  pname = "music-pill";
  version = "1.0.0";

  src = ../../scripts;

  nativeBuildInputs = [
    wrapGAppsHook4
    glib
  ];

  buildInputs = [
    pythonEnv
    gtk4
    gtk4-layer-shell
    playerctl
    dbus
    gobject-introspection
    pango
    gdk-pixbuf
    graphene
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src/music-pill $out/bin/music-pill
    chmod +x $out/bin/music-pill
    patchShebangs $out/bin/music-pill
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [ playerctl dbus pythonEnv ]}
      --prefix GI_TYPELIB_PATH : "${giTypelibs}:${pythonEnv}/lib/girepository-1.0"
      --set LD_PRELOAD "${lib.makeLibraryPath [ gtk4-layer-shell ]}/libgtk4-layer-shell.so"
    )
  '';

  meta = with lib; {
    description = "Floating music pill with lyrics for Wayland (niri/Hyprland)";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "music-pill";
  };
}
