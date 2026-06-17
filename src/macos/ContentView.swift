import SwiftUI

enum SidebarSelection: Hashable {
    case device(ConnectedDevice)
    case logAnalyzer
    case settings
}

struct ContentView: View {
    @Environment(DeviceMonitor.self) private var monitor
    @Environment(DependencyInstaller.self) private var installer
    
    @State private var selection: SidebarSelection? = nil
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            VStack(alignment: .leading, spacing: 0) {
                // App 标识
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [Color(red: 0.48, green: 0.54, blue: 0.60), Color(red: 0.64, green: 0.58, blue: 0.60)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Spotlight 进度")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("iOS 27 Indexing Checker")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .padding(.horizontal, 12)
                
                // 设备列表 / 导航项
                List(selection: $selection) {
                    Section(header: Text("已连接设备")) {
                        if monitor.devices.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("等待 iPhone 接入 USB...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        } else {
                            ForEach(monitor.devices) { device in
                                NavigationLink(value: SidebarSelection.device(device)) {
                                    HStack(spacing: 10) {
                                        Image(systemName: device.udid == "USB_DETECTED" ? "exclamationmark.triangle.fill" : "iphone")
                                            .foregroundColor(device.udid == "USB_DETECTED" ? .orange : Color(red: 0.48, green: 0.54, blue: 0.60))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(device.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Text(device.model)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("工具箱")) {
                        NavigationLink(value: SidebarSelection.logAnalyzer) {
                            Label("离线日志分析器", systemImage: "doc.text.magnifyingglass")
                        }
                        
                        NavigationLink(value: SidebarSelection.settings) {
                            Label("系统设置", systemImage: "gearshape")
                        }
                    }
                }
                .listStyle(.sidebar)
                
                Spacer()
                
                // 底部环境预警
                if !installer.isPymobiledeviceAvailable {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("缺少 Python 依赖")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        Text("iOS 实时监控功能需要配置。")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(8)
                    .padding(12)
                    .onTapGesture {
                        selection = .settings
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 290, max: 350)
        } detail: {
            // 右侧详情视图
            switch selection {
            case .device(let device):
                DeviceProgressView(device: device)
            case .logAnalyzer:
                LogAnalyzerView()
            case .settings:
                SettingsView()
            case nil:
                WelcomeView()
            }
        }
        .onAppear {
            // 默认选中
            if let firstDevice = monitor.devices.first {
                selection = .device(firstDevice)
            }
        }
        .onChange(of: monitor.devices) { _, newDevices in
            // 当扫描到新设备时，若当前无选中，则自动选中
            if selection == nil, let first = newDevices.first {
                selection = .device(first)
            }
        }
    }
}

// 缺省欢迎页面
struct WelcomeView: View {
    @Environment(DependencyInstaller.self) private var installer
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 炫酷的 Welcome 图标
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.48, green: 0.54, blue: 0.60).opacity(0.12), Color(red: 0.64, green: 0.58, blue: 0.60).opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.48, green: 0.54, blue: 0.60), Color(red: 0.64, green: 0.58, blue: 0.60)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            VStack(spacing: 8) {
                Text("开始检查 Spotlight 索引进度")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                
                Text("请使用 USB 数据线将 iPhone 连接到此 Mac。\n连接后在 iPhone 上点击“信任此电脑”，并保持设置应用处于打开状态。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            
            if !installer.isPymobiledeviceAvailable {
                VStack(spacing: 12) {
                    Text("检测到当前环境尚未配置依赖")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("实时读取 iOS 日志需要 python 模块 pymobiledevice3。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if installer.isInstalling {
                        ProgressView(installer.installProgress)
                            .controlSize(.small)
                            .padding(.top, 4)
                    } else {
                        Button("一键配置所需依赖") {
                            installer.installDependency()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 60)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.2))
    }
}
