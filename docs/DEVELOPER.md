# 开发者说明

## 项目结构

```text
src/IosIndexingProgress.py                 核心读取程序
scripts/Start-iOS-Indexing-Checker.cmd     用户双击入口
scripts/Start-iOS-Indexing-Checker.ps1     一键启动器
scripts/Build-NoPython-Package.ps1         维护者打包脚本
packaging/README_OneClick_Distribution.txt 离线包内说明
dist/*.zip                                 面向用户的离线包
tests/sample-indexing-syslog.txt           解析测试样例
```

## 技术路线

核心程序使用 `pymobiledevice3` 连接 iPhone 的 Apple Mobile Device / usbmux 通道，并读取 iOS 日志流。工具过滤 Spotlight / Settings 相关日志，提取 `PipelineCompleteness`。

Windows 用户拿到的是 PyInstaller 打包后的自包含 exe，不需要安装 Python。

## 构建

维护者机器需要 Python 3.10+。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Build-NoPython-Package.ps1
```

默认构建目录：

```text
D:\Codex Program\ios-indexing-checker-build
```

如果没有这个目录，会回退到项目目录下的 `.build-nopython`。

## 本地测试

解析样例日志：

```powershell
python src\IosIndexingProgress.py --input tests\sample-indexing-syslog.txt
```

构建后解压 `dist\iOS_Indexing_Checker_Windows_NoPython.zip`，再做真机短测：

```powershell
.\IosIndexingProgress.exe --duration 20 --connect-timeout 10 --raw
```

启动器链路测试：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Start-iOS-Indexing-Checker.ps1 -DurationSeconds 20 -Raw -NoPrompt
```

## 发布前检查

- 真机能读到 `iOS indexing progress: XX%`。
- 启动器能显示阶段和心跳。
- zip 内只包含启动器、exe 和说明文件。
- 不把 `ios-indexing-checker.log`、`runtime-tmp`、构建缓存上传。
