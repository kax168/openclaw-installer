# OpenClaw One-Click Installer

Deploy your personal AI assistant in 60 seconds. One command, any platform.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-green.svg)]()

## Quick Start

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/kax168/openclaw-installer/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/kax168/openclaw-installer/main/install.ps1 | iex
```

That's it. The installer handles everything.

## What It Does

1. Detects your OS and architecture
2. Installs Node.js 22 (via nvm)
3. Installs OpenClaw globally
4. Runs interactive config wizard
5. Registers as system service (optional)

## Supported Platforms

| Platform | Package Manager | Status |
|----------|----------------|--------|
| Ubuntu/Debian | apt | ✅ |
| CentOS/RHEL | yum | ✅ |
| Fedora | dnf | ✅ |
| Arch Linux | pacman | ✅ |
| macOS | brew | ✅ |
| Windows | PowerShell | ✅ |

## Supported Providers

- **Anthropic** (Claude Sonnet/Opus)
- **OpenAI** (GPT-4o)
- **Google** (Gemini 2.5 Pro)
- **Custom proxy** (any OpenAI-compatible endpoint)

## Health Check

```bash
./install.sh --doctor
```

Checks Node.js, OpenClaw, config, and service status.

## What is OpenClaw?

[OpenClaw](https://github.com/openclaw/openclaw) is a self-hosted AI assistant that connects to your favorite messaging apps (Telegram, Discord, WhatsApp) and runs 24/7 on your own server. Think of it as your personal AI that remembers everything and can automate tasks.

## Need Help?

- **Professional setup service**: ¥99 — we handle everything for you
- **AI Prompt Templates**: [200+ ready-to-use prompts](https://fromlaerkai.store)
- **Community**: 公众号「记录海对岸」

## License

MIT

## Support This Project

If this tool saved you time, consider buying me a coffee ☕

| Alipay | WeChat Pay |
|--------|------------|
| <img src="alipay.jpg" width="200"> | <img src="wechatpay.jpg" width="200"> |

---

Built with ❤️ by [LaerKai](https://fromlaerkai.store)
