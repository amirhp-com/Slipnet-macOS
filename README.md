# BlackSwan — SlipNet macOS Client

A native macOS GUI client for [SlipNet](https://github.com/anonvector/SlipNet) — a VPN tool with DNS tunneling (DNSTT, NoizDNS & Slipstream), NaiveProxy, SSH, Tor, and DoH support, featuring a built-in DNS scanner.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## Features

- **Profile Management** — Create, edit, duplicate, import, and manage multiple SlipNet connection profiles
- **Custom Command Runner** — Run any slipnet command directly from the terminal panel
- **Quick Connect** — Paste a `slipnet://` or `slipnet-enc://` URI from clipboard and connect instantly
- **Built-in DNS Scanner** — Scan DNS resolvers with multiple modes:
  - Basic DNS Scan
  - DNS + End-to-End (E2E) testing
  - Quick Scan (single IP)
  - Prism (server-verified)
  - E2E Test Only
- **DNS Test (nslookup)** — Test a DNS resolver IP with `nslookup` before using it, with one-click copy or apply to profile
- **System-wide SOCKS Proxy** — Enable/disable macOS system-wide SOCKS proxy with one click (uses `networksetup` under the hood)
- **Live Terminal Output** — Real-time process output with auto-scroll, copy, and clear
- **Advanced Run** — Build custom command-line arguments for the SlipNet binary
- **Auto-Update** — Download the latest SlipNet binary directly from GitHub releases
- **Connection Settings** — Configure DNS resolver, direct mode, local host/port, uTLS fingerprint, and query size per profile

## Screenshots

> _Coming soon_

## Requirements

- macOS 13.0+ (Ventura or later)
- [SlipNet binary](https://github.com/anonvector/SlipNet/releases) (auto-detected or manually configured)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/amirhp-com/BlackSwan.git
   ```
2. Open `BlackSwan.xcodeproj` in Xcode
3. Build and run (Cmd+R)
4. Place the `slipnet` binary next to the app or set its path in Settings

## Usage

### Quick Start

1. Launch BlackSwan
2. Create a new profile (click **Add** or Cmd+N)
3. Paste your `slipnet://` URI into the URI field
4. Click **Save & Connect**

### System SOCKS Proxy

After connecting, click the **System Proxy** button in the toolbar to route all macOS traffic through the SOCKS5 proxy. The proxy is automatically disabled when you disconnect.

You can configure the network interface (default: Wi-Fi) in **Settings > Connection**.

```bash
# What it does under the hood:
networksetup -setsocksfirewallproxy Wi-Fi 127.0.0.1 1080   # Enable
networksetup -setsocksfirewallproxystate Wi-Fi off           # Disable
```

### DNS Scanner

1. Click **DNS Scanner** in the toolbar
2. Paste a config URI or enter a domain manually
3. Provide a file with resolver IPs or a single IP for quick scan
4. Use the **Test** button to verify a DNS IP with `nslookup` before scanning
5. Click **Start Scan**

## Project Structure

```
BlackSwan/
├── BlackSwanApp.swift          # App entry point & window config
├── Models/
│   ├── AppState.swift          # Central state management & process execution
│   ├── SlipnetConfig.swift     # Connection profile data model
│   └── ScanConfig.swift        # DNS scanner configuration model
└── Views/
    ├── ContentView.swift       # Main layout (NavigationSplitView)
    ├── SidebarView.swift       # Profile list & quick actions
    ├── DetailView.swift        # Toolbar & split editor/terminal
    ├── ProfileEditorView.swift # Profile settings form
    ├── TerminalView.swift      # Live output display
    ├── ScanView.swift          # DNS scanner interface
    ├── AdvancedRunView.swift   # Custom command builder
    └── SettingsView.swift      # App settings (General, Connection, Scanner, Update, About)
```

## Tech Stack

- **SwiftUI** — Declarative UI framework
- **MVVM** — Architecture pattern with `@Published` state
- **Foundation Process** — Native process spawning for SlipNet binary
- **UserDefaults** — Profile persistence with JSON encoding

## License

MIT License — see [LICENSE](LICENSE) for details.

## Credits

- Developed by [amirhp.com](https://amirhp.com)
- SlipNet Core by [anonvector/SlipNet](https://github.com/anonvector/SlipNet)
