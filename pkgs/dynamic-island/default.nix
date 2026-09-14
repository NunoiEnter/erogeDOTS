{ lib
, python3
, wrapGAppsHook4
, gtk4
, gtk4-layer-shell
, playerctl
, glib
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    pygobject3
    pycairo
  ]);
in
python3.pkgs.buildPythonApplication {
  pname = "dynamic-island";
  version = "1.0.0";
  format = "other";

  src = ../../scripts;

  nativeBuildInputs = [
    wrapGAppsHook4
    glib
  ];

  propagatedBuildInputs = [
    pythonEnv
    gtk4
    gtk4-layer-shell
    playerctl
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/bin
    cp dynamic-island $out/bin/dynamic-island
    chmod +x $out/bin/dynamic-island
    patchShebangs $out/bin/dynamic-island
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [ playerctl ]}
      --set GI_TYPELIB_PATH "$GI_TYPELIB_PATH"
    )
  '';

  meta = with lib; {
    description = "Nothing OS-style floating pill widget for niri/Wayland";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "dynamic-island";
  };
}
