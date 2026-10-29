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
| 🌐 | The only network traffic is what a feature needs: DNS requests, ping tests, and one Cloudflare page to show your public IP in *Network Diagnostics* |
| 🔑 | It changes system and network settings, so it asks for administrator rights |

---

## ✅ Supported versions

| Version | Supported |
|:-------:|:---------:|
| **1.1** (latest) | ✅ |
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

You will get an answer as soon as possible, and you can be credited if you want. 🙏

---

## 🔎 Verify your download

Download NSR **only** from this repository:
<https://github.com/M1HA1586/Network-Settings-Reset>

Copies from other sites can be changed by someone else. To be sure, compare the SHA-256 hash of your file with the one in the release notes:

```
certutil -hashfile NSR.bat SHA256
```
