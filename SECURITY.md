<div align="center">

# 🔒 Security Policy

### NSR is plain text, has no telemetry, and you can read every line before you run it.

</div>

---

## 🛡️ What NSR does (and does not do)

| | |
|:--:|---|
| 👀 | A plain-text `.bat` file. Open it in Notepad and read it |
| 🚫 | **No telemetry.** It sends nothing about you anywhere |
| 🌐 | The only network traffic is what a feature needs: DNS requests, ping tests, the speed test, and one Cloudflare page to show your public IP in *Network Diagnostics*. The full list is on [getnsr.xyz/safety](https://getnsr.xyz/safety/) |
| 🔑 | It changes system and network settings, so it asks for administrator rights |

---

## ✅ Supported versions

| Version | Supported |
|:-------:|:---------:|
| **1.3** (latest) | ✅ |
| older | ❌ please update |

---

## 🐞 Reporting a vulnerability

Found a security problem, for example a way to make NSR run something unexpected?
Please **do not open a public issue**. Report it privately:

1. 🔐 **GitHub private reporting:** open the [Security tab](https://github.com/M1HA1586/Network-Settings-Reset/security) and click **Report a vulnerability**
2. 💬 **Or Discord:** message **`mihaifbd`**

Please include:

- 📍 What the problem is and where it is in `NSR.bat`
- 🔁 Steps to reproduce it
- 🪟 Your Windows version

You will get an answer as soon as possible (NSR is a one-person project, so please be patient), and you can be credited if you want. 🙏

---

## ✅ What counts

| | |
|:--:|---|
| ⚠️ | A command that runs **without the confirmation** NSR promises |
| ↩️ | A change that **cannot be undone**, or whose backup is missing or wrong |
| 📂 | Files written outside `%USERPROFILE%\NSR_Backup` or the Desktop report |
| 📡 | Network traffic that is **not listed** on the [safety page](https://getnsr.xyz/safety/) |
| 💉 | A way to make NSR run unexpected code, for example through a typed host name |
| 🎭 | A fake or changed copy of NSR shared under the project name |

**Not a vulnerability:** the SmartScreen warning (NSR is not digitally signed, see the [FAQ](https://getnsr.xyz/faq/)), problems that need an attacker who already has administrator rights, and DNS providers that block sites on purpose.

---

## 🔎 Verify your download

There are only **two official places**: this repository and [getnsr.xyz](https://getnsr.xyz). NSR has no paid version, no installer and no `.exe`. A page that sells NSR or offers an "NSR.exe" is **not** from this project.

Copies from other sites can be changed by someone else. To be sure, compare the SHA-256 hash of your file with the one in the release notes:

```powershell
Get-FileHash .\NSR.bat
```

or, in Command Prompt:

```
certutil -hashfile NSR.bat SHA256
```

Machine-readable contact: [`security.txt`](https://getnsr.xyz/.well-known/security.txt)
