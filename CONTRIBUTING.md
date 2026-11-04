<div align="center">

# 🤝 Contributing to NSR

### Thanks for wanting to help! NSR is one `.bat` file, so contributing is easy.

[🐛 Report a bug](https://github.com/M1HA1586/Network-Settings-Reset/issues/new/choose) ·
[✨ Suggest a feature](https://github.com/M1HA1586/Network-Settings-Reset/issues/new/choose) ·
[🛡️ Suggest a DNS](https://github.com/M1HA1586/Network-Settings-Reset/issues/new/choose) ·
[💖 Support](DONATE.md)

</div>

---

## 💡 Ways to help

| | What | How |
|:--:|------|-----|
| 🐛 | **Report a bug** | Open an issue and pick *Bug report* |
| ✨ | **Suggest a feature** | Open an issue and pick *Feature request* |
| 🛡️ | **Suggest a DNS provider** | Open an issue and pick *Suggest a DNS provider* |
| 🧪 | **Test on your PC** | Tell us how it runs on your Windows build, language and hardware |
| 🔧 | **Send code** | Open a pull request (steps below) |
| ⭐ | **Spread the word** | Star the repo and tell a friend |

---

## 📐 The 5 promises of NSR

Every change must respect these:

| | Promise | Meaning |
|:--:|---------|---------|
| 📦 | **One file** | No installer, no extra downloads, nothing else needed to run |
| 🔒 | **No data collection** | No telemetry and no hidden network calls |
| 👀 | **Readable** | Plain text that anyone can open in Notepad and understand |
| ↩️ | **Reversible** | If it changes system settings, the menu can undo it |
| 🛡️ | **Safe** | Back up values before changing them, and ask before anything big |

---

## 🎛️ How every screen works

NSR 1.3 follows one set of rules, so users never get lost. A new screen should too:

| | Rule |
|:--:|------|
| 0️⃣ | **`0` is always Back**, and Exit on the main screen. Number keys choose |
| 📍 | Every screen shows where you are, for example `Home / DNS Center / Recommended / Safe` |
| 🗂️ | Menus are grouped as **FIX, DNS, TEST and TOOLS**, with aligned columns, the same footer and the same prompt: `Choose [1-9, 0 = Back]:` |
| ✅ | Every step ends with `[ OK ]`, `[FAIL]` or `[ DONE ]`. A failed step must never look like a success |
| ❓ | Anything that **writes** asks first. Things that only read can run right away |
| 🎨 | Plain CMD look: white text on black, no special colors, no extra windows |

---

## 🔧 Sending a pull request

> 💡 For anything bigger than a small fix, **open an issue first**, so we agree on the idea before you spend time on it.

1. 🍴 **Fork** the repository
2. 🌿 Create a branch: `git checkout -b my-change`
3. ✏️ Edit `NSR.bat`
4. 🧪 Test it (see below)
5. 📖 Update the `README.md` and add a line to `CHANGELOG.md` if something visible changed
6. 🚀 Open a pull request and fill in the template

---

## 🧪 Testing your change

- 🖱️ Run it from a normal double-click, not only from an open CMD window
- 🔑 Test it **as administrator**, and see what message you get without it
- 🪟 If you can, test on **Windows 10** and **Windows 11**
- 🧭 Walk the changed menu path, then press `0` to go Back and Exit
- ↩️ Test the way back too (*Undo Last Change*, *Reset to Automatic*, *Restore Windows Defaults*)
- 💾 Use a virtual machine, or create a restore point first

---

## ✍️ Code style

- 📄 Keep Windows line endings (**CRLF**) in `NSR.bat`
- 🏷️ Use clear names for labels and variables
- 💬 Add a short comment above any block that is not obvious
- 🎨 Keep the look and layout of the existing screens

---

## 🌍 Adding a DNS provider

Open a *Suggest a DNS provider* issue first. A provider is added only when it has **official public addresses** and a **clear privacy policy**. Addresses must come from the provider's **official page** (IPv4, IPv6, backup server and the encrypted DNS address). NSR has 20 providers in 4 groups, so a new one must bring something the others do not.

---

## 🔐 Security problems

Please do **not** open a public issue. Read [SECURITY.md](SECURITY.md).

## 🕊️ Be kind

By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## 📄 License

By contributing, you agree that your work is released under the [MIT License](LICENSE).

<div align="center">

**Thank you! 💙**

</div>
