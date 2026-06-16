# iOS 27 Beta Indexing Progress Checker for Windows

A small Windows utility for checking the actual iPhone "Indexing in Progress" percentage.

It follows the same idea as the macOS Console method: stream live iPhone logs, look for Spotlight / Settings indexing messages, and extract `PipelineCompleteness`.

## Download

Download the offline package from this repository:

[dist/iOS_Indexing_Checker_Windows_NoPython.zip](dist/iOS_Indexing_Checker_Windows_NoPython.zip)

End users do not need to install Python or download dependencies.

## Quick Start

1. Extract `iOS_Indexing_Checker_Windows_NoPython.zip`.
2. Connect the iPhone over USB.
3. Unlock the iPhone and tap "Trust This Computer" if prompted.
4. Open Settings on the iPhone.
5. Double-click `Start-iOS-Indexing-Checker.cmd`.
6. Follow the window prompts.

Expected output:

```text
Connected. Waiting for Spotlight indexing logs...
[19:48:27] iOS indexing progress: 85%
Latest iOS indexing progress seen: 85%
```

## Requirements

- Windows 10 or Windows 11.
- iPhone connected over USB.
- Apple Devices or iTunes installed, so Windows has Apple Mobile Device Service.

Apple's USB/mobile-device driver is not bundled with this project.

## Privacy

The tool reads live logs locally and filters for indexing progress. It does not upload logs anywhere.

## License

MIT License. See [LICENSE](LICENSE).
