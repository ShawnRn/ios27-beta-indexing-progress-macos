iOS Indexing Checker for Windows - 一键版

使用者只需要：

1. 解压 zip。
2. 双击 Start-iOS-Indexing-Checker.cmd。
3. 插上 iPhone，解锁，点“信任此电脑”。
4. 在 iPhone 上打开“设置”。
5. 回到窗口按 Enter。

这个版本不需要用户安装 Python，也不会创建 Python 环境。
解压后不需要联网下载任何工具或依赖。

仍然需要的前置条件：

- Windows 能识别 iPhone。
- 已安装 Apple Devices 或 iTunes，确保存在 Apple Mobile Device Service。

隐私：

这个工具只在本机读取 iPhone 实时日志，过滤 `spotlight indexing progress` / `PipelineCompleteness`，不会上传日志。

如果有问题，同目录会生成 `ios-indexing-checker.log`，方便排查。
