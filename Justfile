set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

docker_platform := "linux/amd64"
docker_platform_arm64 := "linux/arm64"
fixture_catalog := "fixtures/templates"

default:
    just --list

fmt:
    cargo fmt --all

fmt-check:
    cargo fmt --all -- --check

check:
    cargo check --workspace

build:
    cargo build --workspace

build-release:
    cargo build --release --workspace

build-gametainer:
    cargo build -p gametainer

build-gametainer-release:
    cargo build --release -p gametainer

build-gamer:
    cargo build -p gamer

build-gamer-release:
    cargo build --release -p gamer

package-current target="local" version="dev":
    cargo build --release -p gametainer -p gamer
    GAMETAINER_VERSION={{version}} ./scripts/package-release.sh {{target}}

package-target target version="dev":
    cargo build --release -p gametainer -p gamer --target {{target}}
    GAMETAINER_VERSION={{version}} ./scripts/package-release.sh {{target}}

test:
    cargo test --workspace

games:
    cargo run -q -p gametainer -- games list

games-fixtures:
    cargo run -q -p gametainer -- games list --templates {{fixture_catalog}}

catalog-validate:
    cargo run -q -p gametainer -- catalog validate

catalog-validate-fixtures:
    cargo run -q -p gametainer -- catalog validate --templates {{fixture_catalog}}

init:
    cargo run -q -p gametainer -- init

servers:
    cargo run -q -p gametainer -- servers list

server-create-skip name="my-factorio":
    cargo run -q -p gametainer -- servers create factorio {{name}} --skip-container

server-create name="my-factorio":
    cargo run -q -p gametainer -- servers create factorio {{name}}

server-start name="my-factorio":
    cargo run -q -p gametainer -- servers start {{name}}

server-stop name="my-factorio":
    cargo run -q -p gametainer -- servers stop {{name}}

server-logs name="my-factorio":
    cargo run -q -p gametainer -- servers logs {{name}}

server-destroy-skip name="my-factorio":
    cargo run -q -p gametainer -- servers destroy {{name}} --skip-container

gamer-config:
    GAMER_CONFIG_FILE={{fixture_catalog}}/games/factorio/settings.template.yaml cargo run -q -p gamer -- print-effective-config

docker-check-base:
    docker build --check --platform {{docker_platform}} -f images/base/Dockerfile .

docker-check-steamcmd:
    docker build --check --platform {{docker_platform}} --build-arg BASE_IMAGE=debian:trixie-slim -f images/steamcmd/Dockerfile .

docker-check-wine:
    docker build --check --platform {{docker_platform}} --build-arg BASE_IMAGE=debian:trixie-slim -f images/wine/Dockerfile .

docker-check-steamcmd-wine:
    docker build --check --platform {{docker_platform}} --build-arg WINE_IMAGE=debian:trixie-slim -f images/steamcmd-wine/Dockerfile .

docker-check-base-fex:
    docker build --check --platform {{docker_platform_arm64}} -f images/base-fex/Dockerfile .

docker-check-steamcmd-fex:
    docker build --check --platform {{docker_platform_arm64}} --build-arg BASE_FEX_IMAGE=ubuntu:24.04 -f images/steamcmd-fex/Dockerfile .

docker-check-wine-fex:
    docker build --check --platform {{docker_platform_arm64}} --build-arg BASE_FEX_IMAGE=ubuntu:24.04 -f images/wine-fex/Dockerfile .

docker-check-steamcmd-wine-fex:
    docker build --check --platform {{docker_platform_arm64}} --build-arg WINE_FEX_IMAGE=ubuntu:24.04 -f images/steamcmd-wine-fex/Dockerfile .

docker-check-fex: docker-check-base-fex docker-check-steamcmd-fex docker-check-wine-fex docker-check-steamcmd-wine-fex

docker-check: docker-check-base docker-check-steamcmd docker-check-wine docker-check-steamcmd-wine docker-check-fex

verify: fmt-check check catalog-validate-fixtures games-fixtures gamer-config docker-check

build-base:
    docker build --platform {{docker_platform}} -t ghcr.io/gametainer/base:local -f images/base/Dockerfile .

build-steamcmd:
    docker build --platform {{docker_platform}} -t ghcr.io/gametainer/steamcmd:local -f images/steamcmd/Dockerfile .

build-wine:
    docker build --platform {{docker_platform}} -t ghcr.io/gametainer/wine:local -f images/wine/Dockerfile .

build-steamcmd-wine:
    docker build --platform {{docker_platform}} -t ghcr.io/gametainer/steamcmd-wine:local -f images/steamcmd-wine/Dockerfile .

build-base-fex:
    docker build --platform {{docker_platform_arm64}} -t ghcr.io/gametainer/base-fex:local -f images/base-fex/Dockerfile .

build-steamcmd-fex:
    docker build --platform {{docker_platform_arm64}} --build-arg BASE_FEX_IMAGE=ghcr.io/gametainer/base-fex:local -t ghcr.io/gametainer/steamcmd-fex:local -f images/steamcmd-fex/Dockerfile .

build-wine-fex:
    docker build --platform {{docker_platform_arm64}} --build-arg BASE_FEX_IMAGE=ghcr.io/gametainer/base-fex:local -t ghcr.io/gametainer/wine-fex:local -f images/wine-fex/Dockerfile .

build-steamcmd-wine-fex:
    docker build --platform {{docker_platform_arm64}} --build-arg WINE_FEX_IMAGE=ghcr.io/gametainer/wine-fex:local -t ghcr.io/gametainer/steamcmd-wine-fex:local -f images/steamcmd-wine-fex/Dockerfile .

build-fex-images: build-base-fex build-steamcmd-fex build-wine-fex build-steamcmd-wine-fex

build-images: build-base build-steamcmd build-wine build-steamcmd-wine

sync-dev host="nixos@10.0.0.215" path="/home/nixos/dev/gametainer":
    ssh {{host}} 'mkdir -p {{path}}'
    rsync -az --delete \
        --exclude .git \
        --exclude target \
        --exclude .gametainer \
        --exclude archive \
        ./ {{host}}:{{path}}/

sync-dev-build host="nixos@10.0.0.215" path="/home/nixos/dev/gametainer":
    just sync-dev {{host}} {{path}}
    ssh {{host}} 'cd {{path}} && just build-images'
