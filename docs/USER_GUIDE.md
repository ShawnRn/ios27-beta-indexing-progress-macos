# 使用说明

## 适合谁用

当 iPhone 显示“正在索引”“Indexing in Progress”，但界面不告诉你具体进度时，可以用这个工具在 Windows 上查看实际百分比。

## 下载

从仓库下载：

```text
dist/iOS_Indexing_Checker_Windows_NoPython.zip
```

下载后请先解压，不要直接在 zip 预览窗口里运行。

## 一键使用

1. 解压 zip。
2. 用 USB 连接 iPhone。
3. 解锁 iPhone。
4. 如果 iPhone 弹出“信任此电脑”，点信任。
5. 在 iPhone 上打开“设置”。
6. 双击 `Start-iOS-Indexing-Checker.cmd`。
7. 回到窗口，按 Enter 开始。

## 输出是什么意思

```text
iOS indexing progress: 85%
```

表示系统日志里最新一次出现的索引进度是 85%。

如果多次出现同一个百分比，说明 iPhone 仍在报告同一阶段；这不是工具卡住。

## 需要等多久

首次启动 exe 时，Windows 可能需要 10-30 秒解压运行时或被安全软件扫描。窗口会显示心跳：

```text
核心程序仍在运行：已等待 10 秒，距上次输出 10 秒。
```

这表示工具仍在工作。

## 日志文件

同目录会生成：

```text
ios-indexing-checker.log
```

如果你要反馈问题，可以提供这份日志，但建议先遮盖设备名和 UDID。
