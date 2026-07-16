{ pkgs }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # Container runtimes
    docker
    docker-compose
    podman
    podman-compose

    # Image tools
    dive
    skopeo
    buildah
    crane

    # Security scanning
    trivy
    grype

    # Linting
    hadolint

    # Registry
    regctl

    # Debugging
    ctop
    lazydocker

    # Utilities
    jq
    yq-go
    curl
    wget
    git
  ];

  DOCKER_HOST = "unix:///var/run/podman/podman.sock";

  shellHook = ''
    echo "🐳 Docker/Podman Shell loaded"
    echo "   docker | podman | compose | dive | trivy | hadolint"
  '';
}
