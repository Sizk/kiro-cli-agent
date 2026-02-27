# Kiro CLI Agent

[Zed](https://zed.dev) Agent Server Extension that packages
[Kiro CLI](https://kiro.dev/cli) as a native agent via the
[Agent Client Protocol (ACP)](https://agentclientprotocol.com/).

Install from the Zed Extensions panel or the
[ACP Registry](https://agentclientprotocol.com/registry) and start
using Kiro directly in your editor.

## Prerequisites

Kiro CLI must be installed on your machine:

```sh
curl -fsSL https://cli.kiro.dev/install | bash
```

Verify the installation:

```sh
kiro-cli doctor
which kiro-cli
```

## Install in Zed

### From the Extensions panel

1. Open Zed and press `Cmd-Shift-X` (Extensions).
2. Filter by **Agent Servers** and search for **Kiro CLI Agent**.
3. Click **Install**.

### From the ACP Registry

1. Open the ACP Registry page in Zed.
2. Find **Kiro CLI Agent** and install it.

### Manual (custom agent)

Add the following to your Zed settings (`~/.config/zed/settings.json`):

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

## Usage

1. Open the Agent Panel (`Cmd-?` / `Ctrl-?`).
2. Click `+` and select **Kiro CLI Agent**.
3. Authenticate when prompted (opens your browser).
4. Start chatting.

## How it works

The extension ships a thin POSIX wrapper script per platform:

```sh
#!/bin/sh
exec kiro-cli acp "$@"
```

Zed downloads and extracts this wrapper, then spawns it as an ACP
agent server. All AI capabilities come from your locally installed
`kiro-cli` binary.

## Supported platforms

| Platform | Target |
|---|---|
| macOS ARM64 (Apple Silicon) | `darwin-aarch64` |
| Linux x86_64 | `linux-x86_64` |
| Linux ARM64 | `linux-aarch64` |

Windows is not supported by Kiro CLI.

## Troubleshooting

| Issue | Fix |
|---|---|
| `kiro-cli: command not found` | Install Kiro CLI or ensure it's on your PATH (`which kiro-cli`) |
| Authentication loop | Run `kiro-cli login` in a terminal first, then retry in Zed |
| Agent not responding | Check ACP logs: Command Palette -> `dev: open acp logs` |
| Connection drops | Run `kiro-cli doctor` and check Kiro logs at `$TMPDIR/kiro-log/kiro-chat.log` |

## License

[Apache-2.0](LICENSE)
