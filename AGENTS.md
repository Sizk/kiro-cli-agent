# AGENTS.md

Zed Agent Server Extension and ACP Registry entry that packages
[Kiro CLI](https://kiro.dev/cli) as a native agent in Zed (and other
ACP-compatible editors). The extension ships thin wrapper scripts that
invoke the user's pre-installed `kiro-cli` binary over the
[Agent Client Protocol](https://agentclientprotocol.com/).

## Repository structure

```
kiro-cli-agent/
  extension.toml          # Zed extension manifest (agent server definition)
  agent.json              # ACP Registry entry
  icon/
    kiro-cli-agent.svg    # 16x16 monochrome SVG icon
  scripts/
    kiro-cli-wrapper.sh   # POSIX wrapper shipped in darwin/linux archives
  LICENSE                 # Apache-2.0
  .github/
    workflows/
      release.yml         # CI: build wrapper archives, create GitHub Release
```

## Prerequisites

- **Kiro CLI** must be installed: `curl -fsSL https://cli.kiro.dev/install | bash`
- Verify installation: `kiro-cli doctor` and `which kiro-cli`
- **Zed** v0.221 or later (for ACP Registry support) or v0.202+ (for Agent Server Extensions)

## Build and validation commands

### Build wrapper archives (from repo root)

```sh
# Create release archives containing the wrapper script
mkdir -p dist
# macOS ARM64
tar -czf dist/kiro-cli-agent-darwin-arm64.tar.gz -C scripts kiro-cli-wrapper.sh
# Linux x86_64
tar -czf dist/kiro-cli-agent-linux-x64.tar.gz -C scripts kiro-cli-wrapper.sh
# Linux ARM64
tar -czf dist/kiro-cli-agent-linux-arm64.tar.gz -C scripts kiro-cli-wrapper.sh
```

### Generate SHA-256 hashes

```sh
shasum -a 256 dist/*.tar.gz
```

### Validate extension.toml

```sh
# Basic TOML syntax check (requires taplo or similar)
taplo check extension.toml
```

### Validate agent.json (ACP Registry)

```sh
# Full schema + URL validation
uv run --with jsonschema .github/workflows/build_registry.py

# Skip URL checks during development
SKIP_URL_VALIDATION=1 uv run --with jsonschema .github/workflows/build_registry.py
```

### Validate icon

The icon must be exactly 16x16, square, monochrome (`currentColor` only).
No hardcoded colors (`#hex`, `red`, `rgb(...)`) -- only `fill="currentColor"`,
`fill="none"`, or `fill="inherit"` are permitted. Process through
[SVGOMG](https://jakearchibald.github.io/svgomg/) before committing.

## Local development and testing

### Stage 1 -- Test ACP communication (no extension needed)

Add Kiro as a custom agent in Zed settings (`~/.config/zed/settings.json`):

```json
{
  "agent_servers": {
    "Kiro CLI Agent": {
      "type": "custom",
      "command": "kiro-cli",
      "args": ["acp"],
      "env": {}
    }
  }
}
```

Open the Agent Panel (`Cmd-?` / `Ctrl-?`), select "Kiro CLI Agent", and
authenticate. This validates that `kiro-cli acp` works over ACP before
involving the extension packaging at all.

### Stage 2 -- Test as a dev extension

Agent Server extensions always download archives from the URLs in
`extension.toml`, even when installed as dev extensions. You must first
create a GitHub Release with the archives (see Release workflow), then:

1. Run `zed: install dev extension` and select this repo directory.
2. Open the Agent Panel, click `+`, select "Kiro CLI Agent".
3. Verify download, extraction, authentication, and a test prompt.

### Debugging

- **ACP logs**: Command Palette -> `dev: open acp logs`
- **Kiro logs (macOS)**: `$TMPDIR/kiro-log/kiro-chat.log`
- **Kiro logs (Linux)**: `$XDG_RUNTIME_DIR/kiro-log/kiro-chat.log`
- **Verbose mode**: `KIRO_LOG_LEVEL=debug kiro-cli acp`
- **Zed logs**: `zed: open log` (or launch `zed --foreground` for INFO-level output)

## extension.toml conventions

The manifest defines the Zed Agent Server Extension. Key rules:

- `id`: Must be lowercase, hyphens allowed, must NOT contain "zed". Use `kiro-cli-agent`.
- `schema_version`: Always `1`.
- `version`: Semver (`major.minor.patch`). Must match `extensions.toml` entry exactly.
- Each `[agent_servers.<id>.targets.<platform>]` needs `archive`, `cmd`, and optionally `args`, `env`, `sha256`.
- `cmd` is relative to extracted archive root (e.g., `./kiro-cli-wrapper.sh`).
- Supported platforms: `darwin-aarch64`, `linux-x86_64`, `linux-aarch64`.
  Kiro CLI does not support Windows.
- Optional `icon` field points to SVG relative to extension root.
- Optional `env` block sets environment variables for the spawned process.

## agent.json conventions (ACP Registry)

The ACP Registry entry follows the [agent.schema.json](https://cdn.agentclientprotocol.com/registry/v1/latest/agent.schema.json).

- `id`: `^[a-z][a-z0-9-]*$` -- use `kiro-cli-agent`.
- Required fields: `id`, `name`, `version`, `description`, `distribution`.
- `distribution.binary` maps platform targets to `{ archive, cmd, args }`.
- Archive URLs must not contain `/latest/` -- use pinned version tags.
- Versions auto-update hourly from GitHub Releases; no PR needed for bumps.
- Authentication: Kiro uses Agent Auth (browser-based OAuth). The `initialize`
  response must include `authMethods` with `type: "agent"`.

## Release workflow

When cutting a new release:

1. **Bump version** in both `extension.toml` and `agent.json` (must match).
2. **Build wrapper archives**: run the archive commands above.
3. **Compute SHA-256 hashes** and update `sha256` fields in `extension.toml`.
4. **Update archive URLs** in both files to point to the new release tag.
5. **Tag and push**: `git tag v<version> && git push origin v<version>`.
6. **Create GitHub Release** with the tag, upload the `.tar.gz` archives.
7. **ACP Registry**: versions auto-update from GitHub Releases within ~1 hour.
8. **Zed Extension Registry**: open a PR to `zed-industries/extensions` updating
   the submodule ref and `version` in `extensions.toml`.

## Publishing

### Zed Extension Registry (legacy, will be deprecated)

1. Fork `zed-industries/extensions`.
2. Add this repo as a submodule: `git submodule add https://github.com/Sizk/kiro-cli-agent.git extensions/kiro-cli-agent`
3. Add entry to `extensions.toml`: `[kiro-cli-agent]\nsubmodule = "extensions/kiro-cli-agent"\nversion = "0.1.0"`
4. Run `pnpm sort-extensions`, open PR.
5. Note: the ID `kiro` is already taken by a theme extension.

### ACP Registry (preferred)

1. Fork `agentclientprotocol/registry`.
2. Create `kiro-cli-agent/` directory with `agent.json` and `icon.svg`.
3. Open PR -- CI validates schema, URLs, icon, and auth support.
4. Once merged, available in all ACP clients immediately.

## Code style guidelines

### TOML (extension.toml)
- Use double quotes for all string values.
- Group related keys: metadata block, then `[agent_servers]` blocks.
- One blank line between sections. No trailing whitespace.

### JSON (agent.json)
- 2-space indentation. No trailing commas.
- Keys in order: `id`, `name`, `version`, `description`, `repository`, `authors`, `license`, `icon`, `distribution`.

### Shell scripts (scripts/)
- POSIX-compliant (`#!/bin/sh`), no bashisms.
- Use `exec` to replace the shell process: `exec kiro-cli acp "$@"`.
- Keep wrapper scripts minimal -- no logic beyond delegation.

### SVG icons
- Viewport: `width="16" height="16" viewBox="0 0 16 16"`.
- Only `fill="currentColor"`, `fill="none"`, or `stroke="currentColor"`.
- No gradients, no embedded raster images. Clean with SVGOMG.

### Versioning
- Strict semver: `MAJOR.MINOR.PATCH` (e.g., `0.1.0`).
- Tag format: `v0.1.0`.
- `extension.toml` version, `agent.json` version, and git tag must all match.

### CI / GitHub Actions
- YAML: 2-space indentation. Quote shell commands in `run:` blocks.
- Pin action versions to full SHA, not tags.
- Secrets: never commit API keys, tokens, or credentials.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Agent not found in Zed | Ensure dev extension is installed; check `zed: open log` |
| `kiro-cli: command not found` | Wrapper can't find the binary. Ensure `kiro-cli` is on PATH or set full path in `env` |
| Authentication loop | Run `kiro-cli login` in terminal first, then retry in Zed |
| Archive download fails (404) | Verify archive URLs match the GitHub Release tag exactly |
| Icon not rendering | Must be 16x16 SVG with `currentColor` fills; check for hardcoded colors |
| ACP connection drops | Check `dev: open acp logs` in Zed; check `kiro-cli doctor` |
