<p align="right">
  <a href="README.md">English</a> |
  <strong>中文</strong>
</p>

# iOS Spotlight 索引进度查询工具

当 iPhone 升级 iOS 后显示“正在索引 / Indexing in Progress”，但系统设置界面没有告诉你百分比进度时，可以用这个小工具看一下当前的详细进度。

本项目现已提供 **macOS 原生图形化客户端**（完美适配 macOS 14+）和 **Windows 命令行版本**。

---

## 🚀 macOS 原生图形化 App

使用最新的 **SwiftUI 6** 与 **Swift 结构化并发** 编写，专为 macOS 设计的原生桌面客户端。

### 功能特性：
- **莫兰迪高级灰设计**：采用低饱和度的莫兰迪色系（灰蓝与烟粉）进度环，配合平滑的进度递增动画。
- **智能连接检测**：接入 iPhone 后自动侦测，支持多重通道（USB/Wi-Fi）去重并**自动优先使用更稳定的 USB 物理连接**。
- **实时日志流过滤**：实时滚动展示设备 syslog 并提取 Spotlight 日志，支持关键字搜索与一键导出。
- **一键依赖配置**：应用内含一键配置引导，后台自动静默安装 `pymobiledevice3` 所需运行环境。
- **离线日志分析**：支持将拖拽导入已有的日志文本文件（.txt 或 .log），瞬间匹配出进度百分比。

### 下载与安装：
- **[下载最新版 macOS DMG 镜像](https://github.com/ShawnRn/Spotlight-Progress/releases/latest/download/SpotlightProgress_1.0.0_arm64.dmg)**。
- 双击打开 DMG，将 `SpotlightProgress.app` 拖入 `Applications` 文件夹中即可运行。

### 使用方法：
1. 用 USB 线连接 iPhone 到 Mac。
2. 解锁 iPhone 并信任此电脑。
3. 在 iPhone 上打开“设置”App。
4. 在侧边栏选中您的 iPhone，点击“**开始读取进度**”按钮。

---

## 🪟 Windows 命令行版本

适合 Windows 用户使用的轻量级打包脚本。

### 下载：
- **[下载 Windows ZIP 包（GitHub）](https://github.com/CZJ0219/ios27-beta-indexing-progress-windows/releases/latest/download/iOS_Indexing_Checker_Windows_NoPython.zip)**
- **[下载 Windows ZIP 包（腾讯微云）](https://share.weiyun.com/H5B7bCUz)**

### 使用方法：
1. 下载并解压 `iOS_Indexing_Checker_Windows_NoPython.zip`。
2. 用 USB 线连接 iPhone 到电脑并解锁。
3. 如果 iPhone 弹出提示，点击“信任此电脑”。
4. 在 iPhone 上打开“设置”App。
5. 双击运行解压得到的 `Start-iOS-Indexing-Checker.cmd`。
6. 根据窗口提示按 Enter，正常情况下会看到如 `iOS indexing progress: 85%` 的输出。

---

## ⚠️ 常见排查与故障解决

- 保持 iPhone 始终处于解锁状态，并在 iPhone 上打开“设置”App。
- 确认已经信任此电脑。
- 如果没有马上出现百分比，请保持连接并稍微等待。iPhone 不会每秒都上报索引日志。
- 拔掉 USB 数据线重新插一次，换一个 USB 接口或更换数据线。
- 更多排查方法见：[故障排查](docs/TROUBLESHOOTING.md)

## 🔒 隐私声明

此工具完全在您的电脑本机运行。它不会上传任何日志，不会收集 telemetry 数据，也不会连接外部的项目服务器，100% 保护您的设备隐私。

---

## 许可证

基于 MIT 许可证开源。详见 [LICENSE](LICENSE)。
