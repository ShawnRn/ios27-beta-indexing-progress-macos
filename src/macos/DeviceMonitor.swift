import Foundation
import Observation

public struct ConnectedDevice: Identifiable, Hashable, Sendable {
    public var id: String { udid }
    public let udid: String
    public let name: String
    public let model: String
}

@MainActor
@Observable
public final class DeviceMonitor {
    public var devices: [ConnectedDevice] = []
    public var isScanning: Bool = false
    public var isMonitoring: Bool = false
    public var monitoringDevice: ConnectedDevice? = nil
    
    // 进度与状态
    public var progress: Double = 0.0
    public var lastSeenProgress: Double? = nil
    public var statusMessage: String = "空闲"
    public var logLines: [String] = []
    
    nonisolated(unsafe) private var scanTimer: Timer?
    nonisolated(unsafe) private var monitorProcess: Process?
    private var isStopping = false
    private var monitorTask: Task<Void, Never>?
    
    public init() {
        startScanning()
    }
    
    deinit {
        // 在析构时清理（由于 deinit 是 synchronous 且非 isolated，我们只能通过同步方法杀进程）
        scanTimer?.invalidate()
        monitorProcess?.terminate()
    }
    
    // MARK: - 扫描设备
    
    public func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        
        // 立即扫描一次，随后每 5 秒扫描一次
        scanDevices()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.scanDevices()
            }
        }
    }
    
    public func stopScanning() {
        scanTimer?.invalidate()
        scanTimer = nil
        isScanning = false
    }
    
    public func scanDevices() {
        let pythonPath = UserDefaults.standard.string(forKey: "customPythonPath") ?? "python3"
        
        // 首先尝试通过 pymobiledevice3 获取设备列表
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [pythonPath, "-m", "pymobiledevice3", "usbmux", "list"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // 丢弃错误
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let parsed = parsePymobiledeviceList(output)
                    self.devices = parsed
                    return
                }
            }
        } catch {
            // pymobiledevice3 运行失败，可能未安装，降级使用 system_profiler
        }
        
        // 降级方案：使用 system_profiler 检测 USB 是否连有 iPhone
        scanDevicesViaSystemProfiler()
    }
    
    private struct PymobiledeviceEntry: Codable {
        let Identifier: String?
        let UniqueDeviceID: String?
        let DeviceName: String?
        let ProductType: String?
        let BuildVersion: String?
        let ConnectionType: String?
    }

    private func parsePymobiledeviceList(_ output: String) -> [ConnectedDevice] {
        guard let data = output.data(using: .utf8) else { return [] }
        do {
            let entries = try JSONDecoder().decode([PymobiledeviceEntry].self, from: data)
            
            // 按照 UDID 进行去重，并优先保留 USB 连接
            var uniqueEntries: [String: PymobiledeviceEntry] = [:]
            for entry in entries {
                let udid = entry.Identifier ?? entry.UniqueDeviceID ?? ""
                guard !udid.isEmpty else { continue }
                
                if let existing = uniqueEntries[udid] {
                    // 如果新的 ConnectionType 是 USB，或者已有的不是 USB，进行覆盖
                    if entry.ConnectionType == "USB" || existing.ConnectionType != "USB" {
                        uniqueEntries[udid] = entry
                    }
                } else {
                    uniqueEntries[udid] = entry
                }
            }
            
            return uniqueEntries.values.map { entry in
                let udid = entry.Identifier ?? entry.UniqueDeviceID ?? ""
                let name = entry.DeviceName ?? "iOS 设备"
                let model = mapProductType(entry.ProductType ?? "iPhone")
                return ConnectedDevice(udid: udid, name: name, model: model)
            }
        } catch {
            return parseFallbackList(output)
        }
    }
    
    private func parseFallbackList(_ output: String) -> [ConnectedDevice] {
        var result: [ConnectedDevice] = []
        var seenUdids = Set<String>()
        let blocks = output.components(separatedBy: "- UDID:")
        for block in blocks {
            let lines = block.components(separatedBy: .newlines)
            var udid = ""
            var name = ""
            var model = ""
            
            for line in lines {
                let parts = line.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let val = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                let cleanVal = val.trimmingCharacters(in: CharacterSet(charactersIn: "[]\"'"))
                
                if key == "UDID" || key == "Identifier" || key == "UniqueDeviceID" {
                    udid = cleanVal
                } else if key == "DeviceName" {
                    name = cleanVal
                } else if key == "ProductType" || key == "HardwareModel" {
                    model = cleanVal
                }
            }
            
            if !udid.isEmpty && udid != "[" && !seenUdids.contains(udid) {
                seenUdids.insert(udid)
                let displayName = name.isEmpty ? "iOS 设备" : name
                let displayModel = model.isEmpty ? "iPhone" : mapProductType(model)
                result.append(ConnectedDevice(udid: udid, name: displayName, model: displayModel))
            }
        }
        return result
    }
    
    private func scanDevicesViaSystemProfiler() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["system_profiler", "SPUSBDataType"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if output.contains("iPhone") || output.contains("iPad") {
                    self.devices = [ConnectedDevice(
                        udid: "USB_DETECTED",
                        name: "USB 已连接的 iPhone/iPad",
                        model: "需要安装依赖以开始读取"
                    )]
                    return
                }
            }
        } catch {}
        
        self.devices = []
    }
    
    private func mapProductType(_ type: String) -> String {
        if type.starts(with: "iPhone") {
            return "iPhone"
        } else if type.starts(with: "iPad") {
            return "iPad"
        }
        return type
    }
    
    // MARK: - 监控进度
    
    private var scriptPath: String {
        if let path = Bundle.main.path(forResource: "IosIndexingProgress", ofType: "py") {
            return path
        }
        
        let fileManager = FileManager.default
        let possiblePaths = [
            fileManager.currentDirectoryPath + "/src/IosIndexingProgress.py",
            fileManager.currentDirectoryPath + "/IosIndexingProgress.py"
        ]
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return path
            }
        }
        
        return "IosIndexingProgress.py"
    }
    
    public func startMonitoring(device: ConnectedDevice) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitoringDevice = device
        progress = 0.0
        lastSeenProgress = nil
        statusMessage = "正在建立连接..."
        logLines = ["正在连接到设备 \(device.name)..."]
        isStopping = false
        
        let pythonPath = UserDefaults.standard.string(forKey: "customPythonPath") ?? "python3"
        let script = scriptPath
        
        var args = [script, "--duration", "0", "--raw"]
        if device.udid != "USB_DETECTED" {
            args.append(contentsOf: ["--udid", device.udid])
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [pythonPath] + args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        self.monitorProcess = process
        
        // 使用 Swift 现代并发管理日志读取任务
        monitorTask = Task {
            do {
                try process.run()
                
                // 异步多线程流式读取行
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanLine.isEmpty {
                        self.appendLog(cleanLine)
                        self.parseLine(cleanLine)
                    }
                }
                
                process.waitUntilExit()
                
                if !self.isStopping {
                    self.isMonitoring = false
                    self.statusMessage = "连接已断开"
                    self.appendLog("连接意外关闭，退出代码: \(process.terminationStatus)")
                }
            } catch {
                self.isMonitoring = false
                self.statusMessage = "连接失败"
                self.appendLog("无法启动 Python 监控进程: \(error.localizedDescription)")
            }
        }
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        isStopping = true
        isMonitoring = false
        
        monitorTask?.cancel()
        monitorTask = nil
        
        monitorProcess?.terminate()
        monitorProcess = nil
        
        statusMessage = "已停止"
        appendLog("用户中止了监控。")
    }
    
    private func appendLog(_ line: String) {
        logLines.append(line)
        if logLines.count > 500 {
            logLines.removeFirst()
        }
    }
    
    private func parseLine(_ line: String) {
        if line.contains("iOS indexing progress:") {
            let pattern = "indexing progress:\\s*([0-9.]+)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = line as NSString
                let results = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
                if let match = results.first {
                    let percentStr = nsString.substring(with: match.range(at: 1))
                    if let percent = Double(percentStr) {
                        self.progress = percent / 100.0
                        self.lastSeenProgress = percent
                        self.statusMessage = "正在读取索引进度: \(percent)%"
                    }
                }
            }
        } else if line.contains("Connected. Waiting for Spotlight indexing logs") {
            self.statusMessage = "等待 Spotlight 索引日志..."
        } else if line.contains("Still connected. Waiting") {
            self.statusMessage = "等待最新日志..."
        } else if line.contains("Could not connect to the iPhone") {
            self.statusMessage = "连接超时，请重试"
        }
    }
}
