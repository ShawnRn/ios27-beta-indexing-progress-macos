# 贡献说明

欢迎提交问题和改进建议。

## 提交 Issue

请尽量提供：

- Windows 版本。
- iPhone 型号。
- iOS 版本。
- 是否安装 Apple Devices 或 iTunes。
- 是否能在 Windows 中看到 iPhone。
- `ios-indexing-checker.log` 中的相关片段。

请先遮盖设备名、UDID、Apple ID、邮箱、手机号等个人信息。

## 提交代码

建议改动范围保持清晰：

- 核心日志读取逻辑放在 `src/`。
- 用户启动体验放在 `scripts/Start-iOS-Indexing-Checker.ps1`。
- 构建相关改动放在 `scripts/Build-NoPython-Package.ps1`。

提交前请至少验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Start-iOS-Indexing-Checker.ps1 -DurationSeconds 20 -NoPrompt
```
