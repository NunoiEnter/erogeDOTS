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
    wpscan

    # Exploitation
    metasploit
    searchsploit

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
    strings
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
    theHarvester
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
