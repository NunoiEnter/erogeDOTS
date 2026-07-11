{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    cargo
    rustc
    rustfmt
    clippy
  ];

  shellHook = ''
    echo "🦀 ยินดีต้อนรับสู่ Rust Development Environment!"
    echo "ระบบโหลด Compiler มาให้ใช้ชั่วคราวแล้วครับ"
  '';
}
