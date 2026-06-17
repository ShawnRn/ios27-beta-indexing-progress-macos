<p align="right">
  <strong>English</strong> |
  <a href="README.zh-CN.md">中文</a>
</p>

# iOS Spotlight Indexing Progress Checker

A simple tool for people whose iPhone says "Indexing in Progress" after an iOS upgrade but does not show a percentage.

This project now provides a **Native macOS Graphical App** (optimized for macOS 14+) alongside the original **Windows Command-Line scripts**.

---

## 🚀 Native macOS Graphical App

A premium native desktop client written with the latest **SwiftUI 6** and **Swift Structured Concurrency**.

### Features:
- **Muted Morandi Design**: Featuring a beautiful circular progress bar with a soft Morandi palette (blue-gray & rose) and smooth numbers animation.
- **Smart USB Detection**: Instant USB connect detection with automatic duplication filter and **USB physical connection priority** for maximum stability.
- **Real-time Log Filtering**: Stream device syslog directly and filter out Spotlight indexing status, with search and export capabilities.
- **One-click Dependency Setup**: In-app step-by-step guidance to automatically install `pymobiledevice3` environment in the background.
- **Offline Log Analyzer**: Simply drag and drop any syslog text file (.txt or .log) to instantly parse and extract Spotlight completeness.

### Download & Installation:
- **[Download the latest macOS DMG Package](https://github.com/ShawnRn/Spotlight-Progress/releases/latest/download/SpotlightProgress_1.0.0_arm64.dmg)**.
- Double-click to open the DMG, drag `SpotlightProgress.app` to your `Applications` folder and run it.

### How to Use:
1. Connect your iPhone to your Mac via USB.
2. Unlock your iPhone and tap "Trust This Computer".
3. Open the "Settings" App on your iPhone.
4. Select your iPhone from the sidebar list, then click "**Start Monitoring**".

---

## 🪟 Windows Command-Line Version

A lightweight script package tailored for Windows users.

### Download:
- **[Download the Windows ZIP Package (GitHub)](https://github.com/CZJ0219/ios27-beta-indexing-progress-windows/releases/latest/download/iOS_Indexing_Checker_Windows_NoPython.zip)**
- **[Download the Windows ZIP Package (Tencent Weiyun)](https://share.weiyun.com/H5B7bCUz)**

### How to Use:
1. Download and unzip `iOS_Indexing_Checker_Windows_NoPython.zip`.
2. Connect your iPhone via USB and unlock it.
3. Tap "Trust This Computer" when prompted.
4. Open the "Settings" App on your iPhone.
5. Double-click `Start-iOS-Indexing-Checker.cmd`.
6. Press Enter when prompted. You will see outputs like `iOS indexing progress: 85%`.

---

## ⚠️ Troubleshooting

- Keep the iPhone unlocked and leave the Settings app open on the phone.
- Confirm that you tapped "Trust This Computer".
- If a percentage does not appear immediately, leave it connected and wait. The phone does not report indexing progress every second.
- Unplug and reconnect the USB cable, or try another USB port or cable.
- More help: [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🔒 Privacy

The tool runs 100% locally on your computer. It does not upload logs, collect telemetry, or connect to any remote server, protecting your device privacy.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
