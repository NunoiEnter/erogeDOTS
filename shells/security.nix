{ pkgs }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # Network scanning & enumeration
    nmap
    masscan
    rustscan
    netcat-gnu
    socat

    # Web application testing
    nikto
    gobuster
    ffuf
    dirb
    whatweb
    sqlmap
    # wpscan dropped: unfree license breaks `nix flake check`;
    # re-add with per-shell allowUnfreePredicate if needed

    # Exploitation
    metasploit
    exploitdb

    # Password attacks
    hydra
    john
    hashcat
    ncrack

    # Wireless
    aircrack-ng

    # Forensics
    binwalk
    foremost
    binutils
    file
    exiftool

    # Packet analysis
    wireshark
    tcpdump
    tshark

    # Vulnerability scanning
    nuclei
    nuclei-templates

    # OSINT
    theharvester
    sherlock

    # Cryptography
    openssl
    age

    # Reverse engineering
    ghidra
    radare2

    # Utilities
    curl
    wget
    jq
    python3
    python3Packages.requests
    git
    tmux
    ripgrep
  ];

  shellHook = ''
    echo ""
    echo "⚠  SECURITY TOOLS ENVIRONMENT"
    echo "   Only use on systems you own or have explicit authorization to test."
    echo "   Unauthorized access to computer systems is illegal."
    echo ""
    echo "   nmap | nikto | sqlmap | hydra | metasploit | nuclei | ghidra"
    echo ""
  '';
}
