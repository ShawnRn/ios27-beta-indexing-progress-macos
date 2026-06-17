import Foundation
import Observation

@MainActor
@Observable
public final class DependencyInstaller {
    public var isPythonAvailable: Bool = false
    public var isPymobiledeviceAvailable: Bool = false
    public var isInstalling: Bool = false
    public var installProgress: String = ""
    public var errorMessage: String? = nil
    
    public init() {
        checkEnvironment()
    }
    
    /// 检查当前系统环境中的 Python3 和 pymobiledevice3 是否可用
    public func checkEnvironment() {
        let pythonPath = UserDefaults.standard.string(forKey: "customPythonPath") ?? "python3"
        
        // 1. 检查 python3 是否存在
        let pythonCheck = Process()
        pythonCheck.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        pythonCheck.arguments = [pythonPath, "--version"]
        
        let pipe = Pipe()
        pythonCheck.standardOutput = pipe
        pythonCheck.standardError = pipe
        
        do {
            try pythonCheck.run()
            pythonCheck.waitUntilExit()
            self.isPythonAvailable = (pythonCheck.terminationStatus == 0)
        } catch {
            self.isPythonAvailable = false
        }
        
        guard self.isPythonAvailable else {
            self.isPymobiledeviceAvailable = false
            return
        }
        
        // 2. 检查 pymobiledevice3 是否已安装
        let pyModuleCheck = Process()
        pyModuleCheck.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        pyModuleCheck.arguments = [pythonPath, "-c", "import pymobiledevice3; print(pymobiledevice3.__file__)"]
        
        let modulePipe = Pipe()
        pyModuleCheck.standardOutput = modulePipe
        pyModuleCheck.standardError = modulePipe
        
        do {
            try pyModuleCheck.run()
            pyModuleCheck.waitUntilExit()
            self.isPymobiledeviceAvailable = (pyModuleCheck.terminationStatus == 0)
        } catch {
            self.isPymobiledeviceAvailable = false
        }
    }
    
    /// 异步一键安装 pymobiledevice3
    public func installDependency() {
        guard !isInstalling else { return }
        
        isInstalling = true
        installProgress = "正在准备安装环境..."
        errorMessage = nil
        
        let pythonPath = UserDefaults.standard.string(forKey: "customPythonPath") ?? "python3"
        
        // 使用 Swift 现代并发 Task 在主线程上下文启动，非阻塞等待
        Task {
            let args = [
                pythonPath, "-m", "pip", "install", 
                "--user", 
                "--break-system-packages", 
                "pymobiledevice3"
            ]
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = args
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                
                // 使用 AsyncBytes 异步且线程安全地读取管道流中的每一行
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    let cleanProgress = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanProgress.isEmpty {
                        self.installProgress = cleanProgress
                    }
                }
                
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    self.installProgress = "安装成功！"
                    self.isPymobiledeviceAvailable = true
                    self.isInstalling = false
                } else {
                    // 如果失败，尝试不带 --break-system-packages 的备用方案
                    await retryInstallWithoutBreakSystemPackages(pythonPath: pythonPath)
                }
            } catch {
                self.isInstalling = false
                self.errorMessage = "启动安装进程失败: \(error.localizedDescription)"
            }
        }
    }
    
    private func retryInstallWithoutBreakSystemPackages(pythonPath: String) async {
        self.installProgress = "正在尝试备用安装方式..."
        
        let args = [
            pythonPath, "-m", "pip", "install", 
            "--user", 
            "pymobiledevice3"
        ]
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            
            for try await line in pipe.fileHandleForReading.bytes.lines {
                let cleanProgress = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanProgress.isEmpty {
                    self.installProgress = cleanProgress
                }
            }
            
            process.waitUntilExit()
            
            self.isInstalling = false
            if process.terminationStatus == 0 {
                self.installProgress = "安装成功！"
                self.isPymobiledeviceAvailable = true
            } else {
                self.errorMessage = "依赖安装失败。您可以尝试手动在终端中运行：\npip3 install pymobiledevice3"
            }
        } catch {
            self.isInstalling = false
            self.errorMessage = "备用安装尝试失败: \(error.localizedDescription)"
        }
    }
}
