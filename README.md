<div align="center">

# 🌐 NSR
### Network Settings Reset

**A clean CMD menu to repair your Windows network, switch DNS and test its speed.**

[✨ Features](#features) · [🚀 Quick Start](#quick-start) · [🛠️ Maintenance](#maintenance) · [🎮 Bufferbloat](#bufferbloat) · [❓ FAQ](#faq) · [💖 Support](#support)

</div>

---

<a id="about"></a>
## 📖 About

**NSR** is a single `.bat` file for Windows. Run it, press a number key, done.

- 📦 **One file.** No installer, no extra downloads
- 🔒 **No data collection.** Nothing is sent anywhere
- 👀 **Fully open.** Plain text, you can read every line before running it
- ↩️ **Reversible.** DNS and Bufferbloat changes can be undone from the menu

---

<a id="preview"></a>
## 👀 Preview

```
  ============================================================================
   N S R   -   Network Settings Reset                                 v1.0
  ============================================================================

   MAIN MENU
  ----------------------------------------------------------------------------

   [1]  Network Maintenance      Fix connection problems (recommended)
   [2]  Change DNS               Use a faster or safer DNS provider
   [3]  DNS Speed Test           See which DNS answers the fastest
   [4]  PC Information           CPU, RAM, GPU, disks, network
   [5]  About NSR                Version, links and credits
   [6]  Bufferbloat Optimizer    Advanced: less lag when the line is busy

   [7]  Exit
```

---

<a id="features"></a>
## ✨ Features

| | Option | What it does |
|:-:|---|---|
| 🛠️ | **Network Maintenance** | Quick Fix or Full Reset for connection problems |
| 🔀 | **Change DNS** | Pick a recommended provider or enter your own. Go back to automatic DNS anytime |
| 📡 | **DNS Speed Test** | Sends 10 test packets to each provider and shows the **fastest one for you** |
| 💻 | **PC Information** | CPU, RAM, GPU, mainboard, disks, uptime and IP address |
| 🎮 | **Bufferbloat Optimizer** | Advanced network tweaks with backup and restore |
| ℹ️ | **About NSR** | Version and project link |

### 🔀 Built-in DNS providers

| Provider | IPv4 | Good to know |
|---|---|---|
| **Cloudflare** | `1.1.1.1` | Fast, privacy focused |
| **Cisco OpenDNS** | `208.67.222.222` | Stable, has filtering options |
| **GCore** | `95.85.95.85` | Alternative provider |
| **Quad9** | `9.9.9.9` | Blocks known malicious sites |
| **Google** | `8.8.8.8` | Very popular and reliable |

> The best DNS depends on your location. Use **DNS Speed Test** to see what works best for you.

---

<a id="quick-start"></a>
## 🚀 Quick Start

1. Open **`NSR.bat`** in this repository and click the **download** button
2. Double-click the file. Windows will ask for administrator permission, click **Yes**
3. Use the number keys to move through the menu

### 📋 Requirements

- 🪟 Windows 10 or Windows 11
- ⚙️ PowerShell (included in Windows)
- 🔑 Administrator rights (NSR asks for them automatically)

---

<a id="maintenance"></a>
## 🛠️ Quick Fix vs Full Reset

| | ⚡ Quick Fix | 🔧 Full Reset |
|---|:-:|:-:|
| Flush DNS cache | ✅ | ✅ |
| Release and renew IP address | ✅ | ✅ |
| Connection test at the end | ✅ | ✅ |
| Reset Winsock | ➖ | ✅ |
| Reset TCP/IP stack | ➖ | ✅ |
| Restart needed | ➖ | ✅ |
| **Use it for** | Everyday problems | Serious problems |

> [!NOTE]
> Your internet drops for a few seconds while NSR works. Save your work and close downloads or remote sessions first.

---

<a id="bufferbloat"></a>
## 🎮 Bufferbloat Optimizer

**Bufferbloat** is the lag you feel in games and calls when your connection is busy, for example when someone downloads, streams or uploads.

| Step | What happens |
|:-:|---|
| 1️⃣ | NSR **saves a backup** of the current values in `%USERPROFILE%\NSR_Backup` |
| 2️⃣ | It applies registry, TCP and network card tweaks |
| 3️⃣ | You restart your PC |
| ↩️ | **Restore Windows defaults** sets the usual Windows 10/11 values again |

> [!WARNING]
> These tweaks can **lower your download and upload speed** and raise CPU usage. Try it, and restore the defaults if you do not like the result.
> `[SKIP]` in the list means your Windows version does not allow that setting. This is normal.

> [!TIP]
> The best fix for bufferbloat is **Smart Queue / SQM** on your router, if it supports it.

---

<a id="faq"></a>
## ❓ FAQ

<details>
<summary><b>Windows says "Windows protected your PC". What do I do?</b></summary>

The script is not digitally signed, so Windows shows this warning for downloaded files. Click **More info**, then **Run anyway**. You can open `NSR.bat` in Notepad first and read everything it does.
</details>

<details>
<summary><b>Does NSR collect or send my data?</b></summary>

No. It only runs Windows commands on your PC. The speed test and connection check use pings to public DNS servers, and a browser opens only if you choose to open the GitHub page.
</details>

<details>
<summary><b>How do I undo a DNS change?</b></summary>

Open **Change DNS** and choose **Reset to automatic**.
</details>

<details>
<summary><b>How do I undo the Bufferbloat Optimizer?</b></summary>

Open **Bufferbloat Optimizer** and choose **Restore Windows defaults**, then restart your PC.
</details>

---

<a id="support"></a>
## 💖 Support the Project

If NSR saved you time, you can support its development. Thank you! 🙏

| Method | Address |
|---|---|
| 💳 **PayPal** | [paypal.me/mihaiserif](https://paypal.me/mihaiserif) |
| 🪙 **Litecoin (LTC)** | `LUoHjsi2dDC9tRDyuuBVHF3Lo7fFwgVNYs` |
| ₿ **Bitcoin (BTC)** | `bc1qmajqt2nrg9twys8tq0uwddnuwcgtsemt98j99l` |

---

## 💬 Contact

**Discord:** `mihaifbd`

Found a bug or have an idea? Open an **issue** on GitHub or message me on Discord.

---

## ⚠️ Disclaimer

NSR changes system and network settings. Use it **at your own risk**. If you are not sure, create a Windows restore point first.

## 📄 License

Released under the **MIT License**. See the `LICENSE` file.

<div align="center">

Made with ❤️ by **M1HA15**

</div>
