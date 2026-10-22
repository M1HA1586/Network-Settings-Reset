<div align="center">

# 🌐 NSR
### Network Settings Reset

**A clean CMD menu to repair your Windows network, pick a safer DNS and find out what is wrong.**

![Version](https://img.shields.io/badge/version-1.1-blue) ![Platform](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6) ![License](https://img.shields.io/badge/license-MIT-green)

[✨ Features](#features) · [🚀 Quick Start](#quick-start) · [🛡️ DNS](#dns) · [🛠️ Maintenance](#maintenance) · [🎮 Bufferbloat](#bufferbloat) · [❓ FAQ](#faq) · [💖 Support](#support)

</div>

---

<a id="about"></a>
## 📖 About

**NSR** is a single `.bat` file for Windows. Run it, press a number key, done.

- 📦 **One file.** No installer, no extra downloads
- 🔒 **No data collection.** NSR has no telemetry and sends nothing about you anywhere
- 👀 **Fully open.** Plain text, you can read every line before running it
- ↩️ **Reversible.** DNS and Bufferbloat changes can be undone from the menu

---

<a id="preview"></a>
## 👀 Preview

```
  ============================================================================
   N S R   -   Network Settings Reset                                 v1.1
  ============================================================================

   MAIN MENU
  ----------------------------------------------------------------------------

   Administrator: YES     PowerShell: 5.1.22621.4391     Windows build: 22631

   [1]  Network Maintenance      Fix connection problems (recommended)
   [2]  Change DNS               Faster, safer or family-friendly DNS
   [3]  DNS Speed Test           Find the fastest DNS for your line
   [4]  Network Diagnostics      Find out where the problem is
   [5]  PC Information           CPU, RAM, GPU, disks, network
   [6]  Bufferbloat Optimizer    Advanced: less lag when the line is busy
   [7]  About NSR                Version, what's new, links

   [8]  Exit
```

---

<a id="whats-new"></a>
## 🆕 What's new in v1.1

- 🌐 DNS is shown on **IPv4 and IPv6**, with a `[manual]` / `[auto]` tag
- 🛡️ **9 DNS providers**, including safe and family-friendly ones
- 🔒 **Encrypted DNS (DoH)** on Windows 11
- ⚡ **DNS Speed Test** now measures real DNS answers and can apply the fastest one
- 🩺 New **Network Diagnostics**: router, ISP or DNS?
- 📝 Log file in `%USERPROFILE%\NSR_Backup`

Full list: see the [Releases](https://github.com/M1HA1586/Network-Settings-Reset/releases) page.

---

<a id="features"></a>
## ✨ Features

| | Option | What it does |
|:-:|---|---|
| 🛠️ | **Network Maintenance** | Quick Fix or Full Reset for connection problems |
| 🔀 | **Change DNS** | Pick a recommended provider or enter your own (IPv4 and IPv6). Go back to automatic DNS anytime |
| 📡 | **DNS Speed Test** | Sends real DNS requests to each provider, compares them with your current DNS and shows the **fastest one for you** |
| 🩺 | **Network Diagnostics** | Checks router, Internet (IPv4 and IPv6), DNS and web access, then tells you where the problem is |
| 💻 | **PC Information** | CPU, RAM, GPU, mainboard, disks, uptime, IPv4 and IPv6 address |
| 🎮 | **Bufferbloat Optimizer** | Advanced network tweaks with backup and restore |
| ℹ️ | **About NSR** | Version, what's new, project link and the backup / log folder |

---

<a id="dns"></a>
## 🛡️ DNS

### 🔀 Built-in DNS providers

Every provider is set on **IPv4 and IPv6 together**, with a secondary (backup) server.

| # | Provider | IPv4 | IPv6 | DoH | Good to know |
|:-:|---|---|---|:-:|---|
| 1 | **Cloudflare** | `1.1.1.1` | `2606:4700:4700::1111` | ✅ | Fast, privacy focused |
| 2 | **Google** | `8.8.8.8` | `2001:4860:4860::8888` | ✅ | Very popular and reliable |
| 3 | **Cisco OpenDNS** | `208.67.222.222` | `2620:119:35::35` | ✅ | Stable, has filtering options |
| 4 | **GCore** | `95.85.95.85` | `2a03:90c0:999d::1` | ➖ | Alternative provider |
| 5 | **Quad9** | `9.9.9.9` | `2620:fe::fe` | ✅ | Non-profit, blocks malicious sites |
| 6 | **Cloudflare Security** | `1.1.1.2` | `2606:4700:4700::1112` | ✅ | Fast, blocks malware |
| 7 | **DNS4EU** | `86.54.11.1` | `2a13:1001::86:54:11:1` | ✅ | European, GDPR, blocks threats |
| 8 | **AdGuard DNS** | `94.140.14.14` | `2a10:50c0::ad1:ff` | ✅ | Blocks ads, trackers and malware |
| 9 | **AdGuard Family** | `94.140.14.15` | `2a10:50c0::bad1:ff` | ✅ | Also blocks adult sites |

> [!NOTE]
> The best DNS depends on your location. Use **DNS Speed Test** to see what works best for you. Providers 5 to 9 filter content on purpose. If a site you trust is blocked, switch to Cloudflare or Google.

### 👁️ DNS on IPv4 and IPv6

The DNS screen lists every active adapter with both address families:

```
   Ethernet
      IPv4 : 1.1.1.1, 1.0.0.1  [manual]
      IPv6 : 2606:4700:4700::1111, 2606:4700:4700::1001  [manual]
```

`[manual]` means you set it. `[auto]` means it comes from your router or ISP.

### 🔒 Encrypted DNS (DoH)

On **Windows 11**, after you apply a provider that supports it, NSR asks if you want to turn on encrypted DNS. Your DNS requests are then hidden from your ISP and from public Wi-Fi. If DoH is blocked on a network, Windows falls back to normal DNS, so you never lose Internet.

### ⚡ DNS Speed Test

```
   Cloudflare           avg    9.4 ms   best   7.9   worst   14.2   failed 0/16
   Your current DNS     avg   18.1 ms   best  12.0   worst   40.7   failed 0/16
   Fastest: Cloudflare
```

Lower is faster. After the test you can apply the fastest provider with one key press.

---

<a id="quick-start"></a>
## 🚀 Quick Start

1. Open **[`NSR.bat`](https://github.com/M1HA1586/Network-Settings-Reset/blob/main/NSR.bat)** and click the **download** button
2. Double-click the file. Windows will ask for administrator permission, click **Yes**
3. Use the number keys to move through the menu

### 📋 Requirements

- 🪟 Windows 10 or Windows 11
- ⚙️ PowerShell 5.1 or newer (included in Windows)
- 🔑 Administrator rights (NSR asks for them automatically)
- 🔒 Encrypted DNS (DoH) needs Windows 11

---

<a id="maintenance"></a>
## 🛠️ Quick Fix vs Full Reset

| | ⚡ Quick Fix | 🔧 Full Reset |
|---|:-:|:-:|
| Flush DNS cache | ✅ | ✅ |
| Clear ARP cache | ✅ | ✅ |
| Release and renew IP address | ✅ | ✅ |
| Connection test at the end (IPv4, IPv6, DNS) | ✅ | ✅ |
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

No. NSR has no telemetry and no account. It only runs Windows commands on your PC. Some features talk to public servers, because they need to:
- **DNS Speed Test** sends DNS requests to the providers in the list
- **Connection test and Network Diagnostics** ping `1.1.1.1` and, for the diagnostics, open one Cloudflare page to show your public IP
- A browser opens only if you choose to open the GitHub page
</details>

<details>
<summary><b>How do I undo a DNS change?</b></summary>

Open **Change DNS** and choose **Reset to automatic**. This resets IPv4 and IPv6 DNS.
</details>

<details>
<summary><b>How do I undo the Bufferbloat Optimizer?</b></summary>

Open **Bufferbloat Optimizer** and choose **Restore Windows defaults**, then restart your PC.
</details>

<details>
<summary><b>Which DNS should I choose?</b></summary>

- **Fastest and simple:** Cloudflare or Google
- **Safer (blocks malware):** Quad9, Cloudflare Security or DNS4EU
- **Less ads and trackers:** AdGuard DNS
- **Kids' PC:** AdGuard Family

Run **DNS Speed Test** to see which one is fastest on your line.
</details>

<details>
<summary><b>Why is a website blocked after I changed DNS?</b></summary>

Safe and family providers block sites on purpose (malware, ads, adult content). Switch to Cloudflare or Google, or use **Reset to automatic**.
</details>

<details>
<summary><b>The encrypted DNS (DoH) question did not appear.</b></summary>

DoH needs Windows 11, and not every provider supports it (GCore does not). On Windows 10 NSR sets normal DNS and tells you.
</details>

<details>
<summary><b>Where are the log and the backups?</b></summary>

In `%USERPROFILE%\NSR_Backup`. You can open the folder from **About NSR**.
</details>

---

<a id="support"></a>
## 💖 Support the Project

If NSR saved you time, you can support its development. Thank you! 🙏

| Method | Address |
|---|---|
| 💳 **PayPal** | [paypal.me/mihaiserif](https://paypal.me/mihaiserif) |
| 🔵 **Revolut** | [revolut.me/mihaiserif5](https://revolut.me/mihaiserif5) |
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

Released under the **MIT License**. See the [LICENSE](https://github.com/M1HA1586/Network-Settings-Reset/blob/main/LICENSE) file.

<div align="center">

Made with ❤️ by [**M1HA1586**](https://github.com/M1HA1586)

</div>
