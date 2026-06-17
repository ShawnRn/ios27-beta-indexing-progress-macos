import SwiftUI
import UniformTypeIdentifiers

struct LogAnalyzerView: View {
    @State private var importedLogContent: String = ""
    @State private var fileName: String = ""
    @State private var parsedPercent: Double? = nil
    @State private var isDraggingOver = false
    @State private var matchingLines: [String] = []
    @State private var showingFileImporter = false
    
    // 正则表达式匹配
    private let pipelinePatterns = [
        try? NSRegularExpression(pattern: "PipelineCompleteness\\s*[:=]\\s*([0-9.]+)\\s*%", options: .caseInsensitive),
        try? NSRegularExpression(pattern: "Pipeline\\s+Completeness\\s*[:=]\\s*([0-9.]+)\\s*%", options: .caseInsensitive),
        try? NSRegularExpression(pattern: "PipelineCompleteness\\s*[:=]\\s*([0-9.]+)", options: .caseInsensitive)
    ].compactMap { $0 }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部说明
            VStack(alignment: .leading, spacing: 6) {
                Text("离线日志分析器")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                Text("拖入或导入已有的 iPhone 导出日志，瞬间提取出 Spotlight 索引进度。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .horizontal], 24)
            .padding(.bottom, 16)
            
            // 拖拽与导入区域
            VStack(spacing: 16) {
                if importedLogContent.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(isDraggingOver ? .accentColor : .secondary)
                            .symbolEffect(.bounce, value: isDraggingOver)
                        
                        Text("拖拽日志文件到此处，或")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("选择日志文件") {
                            showingFileImporter = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isDraggingOver ? Color.accentColor : Color.secondary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [8])
                            )
                            .background(isDraggingOver ? Color.accentColor.opacity(0.05) : Color.clear)
                    )
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
                        handleDrop(providers: providers)
                    }
                } else {
                    // 已导入后的展示视图
                    HStack(spacing: 24) {
                        // 环形进度显示
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 14)
                                    .frame(width: 140, height: 140)
                                
                                if let percent = parsedPercent {
                                    Circle()
                                        .trim(from: 0.0, to: CGFloat(percent / 100.0))
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color(red: 0.52, green: 0.58, blue: 0.63), Color(red: 0.70, green: 0.62, blue: 0.63)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                        )
                                        .frame(width: 140, height: 140)
                                        .rotationEffect(Angle(degrees: -90))
                                        .shadow(color: Color(red: 0.52, green: 0.58, blue: 0.63).opacity(0.3), radius: 6, x: 0, y: 3)
                                }
                                
                                VStack(spacing: 2) {
                                    if let percent = parsedPercent {
                                        Text("\(percent, format: .number.precision(.fractionLength(0...2)))%")
                                            .font(.system(size: 26, weight: .bold, design: .rounded))
                                        Text("索引进度")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("无")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Text("未解析出进度")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Text(fileName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: 160)
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                        
                        // 匹配日志汇总
                        VStack(alignment: .leading, spacing: 10) {
                            Text("解析结果")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                if let percent = parsedPercent {
                                    Label("成功提取到进度：\(percent)%", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Label("未能在日志中解析出 PipelineCompleteness 数据", systemImage: "info.circle.fill")
                                        .foregroundColor(.orange)
                                }
                                
                                Label("匹配到 Spotlight 日志行数：\(matchingLines.count) 行", systemImage: "doc.text.fill")
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Button("清除并重新导入") {
                                    clearData()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("选择新文件") {
                                    showingFileImporter = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .frame(height: 180)
                    
                    // 日志查看器
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("匹配到的过滤日志行 (\(matchingLines.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                        
                        Divider()
                        
                        if matchingLines.isEmpty {
                            VStack {
                                Text("没有找到 Spotlight 相关的索引日志")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 6) {
                                    ForEach(matchingLines.indices, id: \.self) { idx in
                                        let line = matchingLines[idx]
                                        let isProgressLine = line.contains("PipelineCompleteness") || line.contains("Pipeline Completeness")
                                        Text(line)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(isProgressLine ? Color(red: 0.45, green: 0.53, blue: 0.47) : .primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 2)
                                            .background(isProgressLine ? Color(red: 0.45, green: 0.53, blue: 0.47).opacity(0.12) : Color.clear)
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.text, .plainText, .data]) { result in
            switch result {
            case .success(let url):
                importFile(url: url)
            case .failure(let error):
                print("导入失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func clearData() {
        importedLogContent = ""
        fileName = ""
        parsedPercent = nil
        matchingLines = []
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            DispatchQueue.main.async {
                self.importFile(url: url)
            }
        }
        return true
    }
    
    private func importFile(url: URL) {
        // 请求安全访问权限（特别是沙盒外拖放时）
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            self.fileName = url.lastPathComponent
            self.importedLogContent = content
            self.analyzeLogs(content)
        } catch {
            // 尝试以 Windows-1252 或其他编码读取
            do {
                let content = try String(contentsOf: url, encoding: .ascii)
                self.fileName = url.lastPathComponent
                self.importedLogContent = content
                self.analyzeLogs(content)
            } catch {
                clearData()
                self.fileName = "读取失败: \(url.lastPathComponent)"
            }
        }
    }
    
    private func analyzeLogs(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
        var matchLines: [String] = []
        var lastPercent: Double? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            // 是否是“有趣”行
            let lower = trimmed.lowercased()
            let isInteresting = lower.contains("pipelinecompleteness") ||
                                lower.contains("spotlight indexing progress") ||
                                (lower.contains("spotlight") && lower.contains("indexing") && lower.contains("progress"))
            
            if isInteresting {
                matchLines.append(trimmed)
                
                // 解析百分比
                for pattern in pipelinePatterns {
                    let nsString = trimmed as NSString
                    let results = pattern.matches(in: trimmed, range: NSRange(location: 0, length: nsString.length))
                    if let match = results.first {
                        let percentStr = nsString.substring(with: match.range(at: 1))
                        if let percent = Double(percentStr) {
                            lastPercent = percent
                        }
                    }
                }
            }
        }
        
        self.matchingLines = matchLines
        self.parsedPercent = lastPercent
    }
}
