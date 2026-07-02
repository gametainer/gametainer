# gametainer

Gametainer is an early Rust 2024 workspace for managing containerized self-hosted game servers.

Current local flow:

```bash
just build-base
just build-steamcmd
just init
just build-gametainer
cargo run -q -p gametainer -- catalog sync official
just catalog-validate
cargo run -q -p gametainer -- servers create factorio my-factorio
cargo run -q -p gametainer -- servers start my-factorio
cargo run -q -p gametainer -- servers logs my-factorio
cargo run -q -p gametainer -- servers wait-ready my-factorio
```

By default, `gametainer` resolves catalogs in this order: `--templates <path>`,
`GAMETAINER_CATALOG_ROOT`, the active synced source under the state directory,
then the sibling development checkout at `../gametainer-catalog`. The committed
`fixtures/templates` catalog is for tests and offline repo verification, not
normal runtime use.

Catalog sources can be synced into the local state directory:

```bash
gametainer catalog sources list
gametainer catalog sync official
gametainer catalog path
```

Runtime state is stored in the OS app data directory by default:

- macOS: `~/Library/Application Support/gametainer`
- Linux: `$XDG_DATA_HOME/gametainer` or `~/.local/share/gametainer`
- Windows: `%APPDATA%\gametainer`

Use `GAMETAINER_STATE_DIR=/path/to/state` for dev, portable, or isolated state.
Use `GAMETAINER_DB_PATH=/path/to/gametainer.db` only when the SQLite DB needs a
specific location.

The controller talks to the Docker Engine API through `/var/run/docker.sock` by default. Set `GAMETAINER_DOCKER_SOCKET` to use another Docker-compatible Unix socket.

Runtime images build as `linux/amd64` by default, including on Apple Silicon:

```bash
just build-base
just build-steamcmd
```

For development without Docker:

```bash
cargo run -q -p gametainer -- servers create factorio my-factorio --skip-container
cargo run -q -p gametainer -- servers destroy my-factorio --skip-container
```

Release packaging is documented in [docs/release-packaging.md](docs/release-packaging.md).
Global update-channel metadata lives in [versions.json](versions.json) and is
intended to be read from GitHub while the project uses static metadata files.
