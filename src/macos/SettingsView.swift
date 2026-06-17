import SwiftUI

struct SettingsView: View {
    @Environment(DependencyInstaller.self) private var installer
    @Environment(DeviceMonitor.self) private var monitor
    
    @State private var customPythonPath: String = ""
    @State private var showingSaveAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                VStack(alignment: .leading, spacing: 4) {
                    Text("系统设置")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    Text("管理应用的运行环境和 Python 依赖")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // 环境状态卡片
                VStack(alignment: .leading, spacing: 14) {
                    Text("依赖环境状态")
                        .font(.headline)
                    
                    Divider()
                    
                    HStack {
                        Label("Python 3 环境", systemImage: installer.isPythonAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(installer.isPythonAvailable ? .green : .red)
                        Spacer()
                        Text(installer.isPythonAvailable ? "已就绪" : "未检测到")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("pymobiledevice3 依赖", systemImage: installer.isPymobiledeviceAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(installer.isPymobiledeviceAvailable ? .green : .orange)
                        Spacer()
                        Text(installer.isPymobiledeviceAvailable ? "已就绪" : "未安装")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                
                // 依赖一键安装面板
                if !installer.isPymobiledeviceAvailable {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                                .symbolEffect(.bounce, value: installer.isInstalling)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("一键配置所需环境")
                                    .font(.headline)
                                Text("iOS 17+ 设备的实时进度查询需使用 pymobiledevice3。点击下方按钮，我们将为您自动配置该工具。")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        if installer.isInstalling {
                            VStack(alignment: .leading, spacing: 6) {
                                ProgressView()
                                    .progressViewStyle(.linear)
                                Text(installer.installProgress)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        } else {
                            Button(action: {
                                installer.installDependency()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down.to.line.circle")
                                    Text("开始一键安装")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        }
                        
                        if let error = installer.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // 配置设置卡片
                VStack(alignment: .leading, spacing: 14) {
                    Text("路径配置")
                        .font(.headline)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("自定义 Python 3 执行路径")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("例如 /usr/local/bin/python3 或 python3", text: $customPythonPath)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)
                            
                            Button("保存并检测") {
                                UserDefaults.standard.set(customPythonPath.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "customPythonPath")
                                showingSaveAlert = true
                                installer.checkEnvironment()
                                monitor.scanDevices()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Text("如若使用 homebrew 或虚拟环境，可以填入对应的 python3 路径。默认为 'python3'。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                
                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            customPythonPath = UserDefaults.standard.string(forKey: "customPythonPath") ?? "python3"
        }
        .alert("设置已保存", isPresented: $showingSaveAlert) {
            Button("好", role: .cancel) { }
        } message: {
            Text("Python 路径已成功更新，已自动为您重新检测依赖环境。")
        }
    }
}
