import SwiftUI

struct DeviceProgressView: View {
    let device: ConnectedDevice
    
    @Environment(DeviceMonitor.self) private var monitor
    @Environment(DependencyInstaller.self) private var installer
    
    @State private var searchText = ""
    @State private var autoScroll = true
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部设备状态面板
            HStack(spacing: 16) {
                // 设备头像/图标
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "iphone")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                        .symbolEffect(.bounce, value: monitor.isMonitoring)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.headline)
                    Text("UDID: \(device.udid)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 控制按钮
                if monitor.isMonitoring && monitor.monitoringDevice?.udid == device.udid {
                    Button(action: {
                        monitor.stopMonitoring()
                    }) {
                        Label("停止监控", systemImage: "stop.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button(action: {
                        monitor.startMonitoring(device: device)
                    }) {
                        Label("开始读取进度", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!installer.isPymobiledeviceAvailable || (monitor.isMonitoring && monitor.monitoringDevice?.udid != device.udid))
                }
            }
            .padding(20)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
            
            Divider()
            
            // 主体区域：进度圈 + 日志
            HStack(spacing: 0) {
                // 左侧进度圈 (Wow Factor)
                VStack(spacing: 24) {
                    Spacer()
                    
                    ZStack {
                        // 背景底色圈
                        Circle()
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 16)
                            .frame(width: 220, height: 220)
                        
                        // 发光晕染背景圈 (Glow)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(monitor.progress))
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.52, green: 0.58, blue: 0.63).opacity(0.3), Color(red: 0.70, green: 0.62, blue: 0.63).opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 24, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(Angle(degrees: -90))
                            .blur(radius: 12)
                            .opacity(monitor.isMonitoring ? 0.4 : 0.1)
                            .animation(.easeInOut(duration: 0.8), value: monitor.progress)
                        
                        // 渐变进度圈
                        Circle()
                            .trim(from: 0.0, to: CGFloat(monitor.progress))
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.52, green: 0.58, blue: 0.63), Color(red: 0.70, green: 0.62, blue: 0.63)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(Angle(degrees: -90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: monitor.progress)
                        
                        // 中间百分比文字
                        VStack(spacing: 4) {
                            if let lastPercent = monitor.lastSeenProgress {
                                Text("\(lastPercent, format: .number.precision(.fractionLength(0...2)))%")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .transition(.opacity)
                            } else {
                                Text("Waiting")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(monitor.isMonitoring ? "正在读取日志..." : "监控已停止")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 10)
                    
                    // 状态说明文字
                    VStack(spacing: 6) {
                        Text(monitor.statusMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .foregroundColor(.primary.opacity(0.9))
                        
                        if device.udid == "USB_DETECTED" {
                            Text("⚠️ 请在系统设置中配置依赖以解锁完整功能。")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("说明: 保持 iPhone 处于解锁状态，并在 iPhone 上打开设置。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: 320)
                .frame(maxHeight: .infinity)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                
                // 竖直分割线
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 1)
                
                // 右侧日志面板 (Terminal 风格)
                VStack(spacing: 0) {
                    // 日志控制栏
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("过滤日志...", text: $searchText)
                            .textFieldStyle(.plain)
                            .frame(maxWidth: 160)
                        
                        Spacer()
                        
                        Toggle(isOn: $autoScroll) {
                            Text("自动滚动")
                                .font(.caption)
                        }
                        .toggleStyle(.checkbox)
                        
                        Button(action: {
                            exportLogs()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                        .help("导出过滤后的日志")
                        .disabled(monitor.logLines.isEmpty)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 24)
                    .padding(.vertical, 10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                    
                    Divider()
                    
                    // 日志滚动视图
                    ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                let filteredLogs = filteredLogLines()
                                ForEach(filteredLogs.indices, id: \.self) { idx in
                                    let line = filteredLogs[idx]
                                    let isProgressLine = line.contains("iOS indexing progress:")
                                    
                                    Text(line)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(isProgressLine ? Color(red: 0.45, green: 0.53, blue: 0.47) : .primary.opacity(0.85))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 1)
                                        .background(isProgressLine ? Color(red: 0.45, green: 0.53, blue: 0.47).opacity(0.12) : Color.clear)
                                        .cornerRadius(4)
                                        .id(idx)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
                        .onChange(of: monitor.logLines.count) { _, _ in
                            if autoScroll {
                                let filteredCount = filteredLogLines().count
                                if filteredCount > 0 {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        scrollViewProxy.scrollTo(filteredCount - 1, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.trailing, 10)
        }
        .onDisappear {
            // 当离开设备视图时，如果正在监控，则停止它，防止泄漏
            monitor.stopMonitoring()
        }
    }
    
    private func filteredLogLines() -> [String] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return monitor.logLines
        }
        return monitor.logLines.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func exportLogs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "Spotlight_Progress_\(device.name)_Log.txt"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                let text = filteredLogLines().joined(separator: "\n")
                try? text.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}
