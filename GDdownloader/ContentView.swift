//
//  ContentView.swift
//  GDdownloader
//
//  Created by 千葉牧人 on 2025/8/4.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputLinks: String = ""
    @State private var parsedFiles: [DriveFile] = []
    @State private var isParsing: Bool = false
    @State private var selectedSavePath: String = ""
    @State private var dragOver: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @StateObject private var downloader = DriveDownloader()
    
    // 計算屬性
    private var selectedFilesCount: Int {
        parsedFiles.filter { $0.isSelected }.count
    }
    
    private var allSelected: Bool {
        !parsedFiles.isEmpty && parsedFiles.allSatisfy { $0.isSelected }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    inputSection
                    buttonSection
                    pathSection
                    fileListSection
                    downloadSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(minWidth: geometry.size.width - 64)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .background(backgroundGradient)
        .alert("訊息", isPresented: $showAlert) {
            Button("確定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadLastUsedPath()
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "icloud.and.arrow.down.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.linearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("GD Downloader")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Google Drive 批次下載工具")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
                .opacity(0.6)
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "link.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("Google Drive 連結")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 8) {
                TextEditor(text: $inputLinks)
                    .frame(height: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(dragOver ? .blue : .gray.opacity(0.3), lineWidth: dragOver ? 2 : 1)
                            )
                    )
                    .onDrop(of: [UTType.text, UTType.plainText, UTType.fileURL], isTargeted: $dragOver) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                
                if dragOver {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                        Text("放開以載入檔案")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var buttonSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: parseLinks) {
                    HStack(spacing: 8) {
                        if isParsing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 16))
                        }
                        Text(isParsing ? "解析中..." : "解析連結")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.linearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    )
                    .foregroundColor(.white)
                }
                .disabled(inputLinks.isEmpty || isParsing)
                .buttonStyle(.plain)
                
                Spacer() 
                
                Button("清除") {
                    inputLinks = ""
                    parsedFiles = []
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            HStack(spacing: 12) {
                Button("載入文字檔") {
                    loadTextFile()
                }
                .buttonStyle(.bordered)
                
                Button("測試連結") {
                    testSpecificLink()
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
    }
    
    private var pathSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "folder.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.linearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("儲存路徑")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    TextField("", text: $selectedSavePath)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .disabled(true)
                    
                    Button(action: selectSavePath) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.badge.plus")
                            Text("選擇")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.orange, lineWidth: 1)
                                )
                        )
                        .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: setDownloadsAsPath) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle")
                            Text("下載項目")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.green, lineWidth: 1)
                                )
                        )
                        .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .help("快速設定下載項目為儲存路徑")
                }
                
                HStack {
                    if selectedSavePath.isEmpty {
                        Label("請選擇儲存路徑", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                    } else {
                        Label("路徑已設定", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var fileListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.linearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("解析結果")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                if !parsedFiles.isEmpty {
                    HStack(spacing: 8) {
                        Text("\(parsedFiles.count) 個檔案 (\(selectedFilesCount) 個已選)")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.green.opacity(0.1))
                            )
                            .foregroundColor(.green)
                        
                        // 全選/取消全選按鈕
                        Button(allSelected ? "取消全選" : "全選") {
                            toggleSelectAll()
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.blue.opacity(0.1))
                        )
                        .foregroundColor(.blue)
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            
            if parsedFiles.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.linearGradient(colors: [.gray, .secondary], startPoint: .top, endPoint: .bottom))
                    
                    VStack(spacing: 8) {
                        Text("尚未解析任何檔案")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("請貼入 Google Drive 連結並點擊「解析連結」")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(parsedFiles.indices, id: \.self) {
                            index in
                            ModernFileRowView(
                                file: $parsedFiles[index], 
                                downloadProgress: downloader.downloadProgress[parsedFiles[index].id] ?? 0.0
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 220)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
        }
    }
    
    private var downloadSection: some View {
        Group {
            if !parsedFiles.isEmpty {
                VStack(spacing: 16) {
                    if downloader.isDownloading {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("正在下載檔案...")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("請等待下載完成")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            
                            Button("取消下載") {
                                cancelDownload()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    } else {
                        Button(action: startDownload) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 18))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("開始下載")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("\(selectedFilesCount) 個檔案")
                                        .font(.system(size: 13, weight: .medium))
                                        .opacity(0.8)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((selectedSavePath.isEmpty || selectedFilesCount == 0) ? 
                                          AnyShapeStyle(Color.gray.opacity(0.3)) : 
                                          AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                                    )
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(selectedSavePath.isEmpty || selectedFilesCount == 0)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(NSColor.windowBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Methods (原有的所有方法保持不變)
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                    if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.inputLinks = text
                            self.showAlert(message: "已載入文字內容")
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            self.loadFileFromURL(url)
                        }
                    }
                }
            }
        }
    }
    
    private func loadTextFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.text, UTType.plainText]
        panel.allowsMultipleSelection = false
        panel.message = "選擇包含 Google Drive 連結的文字檔"
        
        if panel.runModal() == .OK, let url = panel.url {
            loadFileFromURL(url)
        }
    }
    
    private func loadFileFromURL(_ url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            inputLinks = content
            showAlert(message: "已載入檔案：\(url.lastPathComponent)")
        } catch {
            showAlert(message: "無法讀取檔案：\(error.localizedDescription)")
        }
    }
    
    private func parseLinks() {
        isParsing = true
        
        Task {
            let links = inputLinks.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            var files: [DriveFile] = []
            
            // 解析連結並獲取檔案信息
            for link in links {
                if var file = parseGoogleDriveLink(link) {
                    do {
                        // 調用更新後的 getFileInfo 並處理回傳
                        let fileInfo = try await downloader.getFileInfo(fileId: file.id)
                        file.name = fileInfo.name
                        file.size = fileInfo.size
                        file.status = .pending // 成功獲取信息，設為待處理
                    } catch {
                        print("無法獲取檔案 \(file.id) 的詳細信息: \(error.localizedDescription)")
                        // 即使獲取資訊失敗，也將其加入列表，但標記為失敗
                        file.status = .failed
                    }
                    files.append(file)
                }
            }
            
            await MainActor.run {
                self.parsedFiles = files
                self.isParsing = false
                
                if files.isEmpty {
                    self.showAlert(message: "未找到有效的 Google Drive 連結")
                } else {
                    self.showAlert(message: "成功解析 \(files.count) 個檔案")
                }
            }
        }
    }
    
    private func parseGoogleDriveLink(_ link: String) -> DriveFile? {
        return DriveLinkParser.parseLink(link)
    }
    
    private func selectSavePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "選擇下載儲存路徑"
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedSavePath = url.path
                saveLastUsedPath(selectedSavePath)
                showAlert(message: "已選擇儲存路徑：\(selectedSavePath)")
            }
        }
    }
    
    private func setDownloadsAsPath() {
        let downloadsPath = NSHomeDirectory() + "/Downloads"
        selectedSavePath = downloadsPath
        
        if !selectedSavePath.isEmpty {
            saveLastUsedPath(selectedSavePath)
            showAlert(message: "已設定下載項目為儲存路徑")
        }
    }
    
    private func startDownload() {
        // 只下載選中的檔案
        let selectedFiles = parsedFiles.filter { $0.isSelected }
        
        if selectedFiles.isEmpty {
            showAlert(message: "請選擇要下載的檔案")
            return
        }
        
        Task {
            let updatedFiles = await downloader.startBatchDownload(
                files: selectedFiles,
                savePath: selectedSavePath
            )
            
            await MainActor.run {
                // 更新已下載檔案的狀態
                for updatedFile in updatedFiles {
                    if let index = self.parsedFiles.firstIndex(where: { $0.id == updatedFile.id }) {
                        self.parsedFiles[index].status = updatedFile.status
                        self.parsedFiles[index].name = updatedFile.name // 更新檔案名
                        self.parsedFiles[index].size = updatedFile.size // 更新檔案大小
                    }
                }
                
                let completedCount = updatedFiles.filter { $0.status == .completed }.count
                let failedCount = updatedFiles.filter { $0.status == .failed }.count
                
                if failedCount == 0 {
                    showAlert(message: "成功下載 \(completedCount) 個檔案")
                } else {
                    showAlert(message: "下載完成：\(completedCount) 個成功，\(failedCount) 個失敗")
                }
            }
        }
    }
    
    private func cancelDownload() {
        downloader.cancelAllDownloads()
        showAlert(message: "已取消下載")
    }
    
    private func testSpecificLink() {
        let testLinks = [
            // 用戶提供的連結 - 修復後應該要能正常解析
            "https://drive.google.com/uc?id=12ZUDXM2BSF1zI6Nxh7slt9ntyJiu93Oe&export=download",
            "https://drive.google.com/uc?id=1cSsry8hXkbodXqFk8C28Cd9SUrLhGu55&export=download",
            
            // 其他常見格式測試
            "https://drive.google.com/file/d/1n4zVBUTmjEm3RwWMIZmW6EMch-ru6fop/view?usp=drive_link",
            "https://drive.google.com/uc?export=download&id=12ZUDXM2BSF1zI6Nxh7slt9ntyJiu93Oe",
            "https://docs.google.com/document/d/1n4zVBUTmjEm3RwWMIZmW6EMch-ru6fop/edit",
            "https://drive.google.com/open?id=12ZUDXM2BSF1zI6Nxh7slt9ntyJiu93Oe"
        ]
        
        Task {
            print("=== 測試多種 Google Drive 連結格式 ===")
            
            for (index, testLink) in testLinks.enumerated() {
                print("\n[\(index + 1)] 測試連結: \(testLink)")
                
                if let file = DriveLinkParser.parseLink(testLink) {
                    print("✅ 解析成功:")
                    print("   檔案 ID: \(file.id)")
                    print("   檔案名稱: \(file.name)")
                    print("   檔案類型: \(file.type == .file ? "檔案" : "資料夾")")
                    print("   原始連結: \(file.link)")
                    
                    // 只對前兩個連結（用戶提供的）進行詳細測試
                    if index < 2 {
                        do {
                            let fileInfo = try await downloader.getFileInfo(fileId: file.id)
                            print("   實際檔案名稱: \(fileInfo.name)")
                            print("   檔案大小: \(fileInfo.size)")
                            print("   下載 URL: \(fileInfo.downloadURL)")
                        } catch {
                            print("   ⚠️ 無法獲取檔案詳細信息: \(error)")
                        }
                    }
                } else {
                    print("❌ 解析失敗 - 連結格式不支援")
                }
                
                print("   " + String(repeating: "-", count: 50))
            }
            
            await MainActor.run {
                showAlert(message: "連結格式測試完成！請查看控制台輸出查看詳細結果")
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - 路徑記憶功能
    private func saveLastUsedPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: "LastUsedDownloadPath")
    }
    
    private func loadLastUsedPath() {
        if let savedPath = UserDefaults.standard.string(forKey: "LastUsedDownloadPath"),
           !savedPath.isEmpty,
           FileManager.default.fileExists(atPath: savedPath) {
            selectedSavePath = savedPath
        } else {
            selectedSavePath = NSHomeDirectory() + "/Downloads"
        }
    }
    
    // MARK: - 檔案大小相關函數
    private func getFileSize(fileId: String) async throws -> Int64 {
        // 對於大型檔案，Google Drive 會返回病毒掃描頁面，無法直接獲取檔案大小
        // 我們可以嘗試從不同的 API 端點獲取檔案信息
        
        // 方法 1: 嘗試從檔案檢視頁面獲取檔案大小信息
        let viewURL = URL(string: "https://drive.google.com/file/d/\(fileId)/view")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: viewURL)
            if let html = String(data: data, encoding: .utf8) {
                
                // 嘗試從 HTML 中提取檔案大小
                if let fileSize = extractFileSizeFromHTML(html) {
                    return fileSize
                }
            }
        } catch {
            print("無法從檢視頁面獲取檔案大小: \(error)")
        }
        
        // 方法 2: 嘗試 HEAD 請求（對小檔案有效）
        let downloadURL = URL(string: "https://drive.google.com/uc?export=download&id=\(fileId)")!
        
        var request = URLRequest(url: downloadURL)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               let contentType = httpResponse.allHeaderFields["Content-Type"] as? String,
               !contentType.contains("text/html"), // 確保不是 HTML 頁面
               let contentLength = httpResponse.allHeaderFields["Content-Length"] as? String,
               let fileSize = Int64(contentLength) {
                return fileSize
            }
        } catch {
            print("HEAD 請求失敗: \(error)")
        }
        
        // 如果都無法獲取，回傳預設值
        throw NSError(domain: "FileSizeError", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法獲取檔案大小"])
    }
    
    private func extractFileSizeFromHTML(_ html: String) -> Int64? {
        // 嘗試多種模式來提取檔案大小
        let patterns = [
            #"sizeBytes":"(\d+)"#,
            #"fileSize":"(\d+)"#,
            #"文件大小[：:]\s*([0-9,.]+)\s*(B|KB|MB|GB|TB)"#,
            #"Size[：:]\s*([0-9,.]+)\s*(B|KB|MB|GB|TB)"#,
            #"大小[：:]\s*([0-9,.]+)\s*(B|KB|MB|GB|TB)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) {
                
                let range = match.range(at: 1)
                if range.location != NSNotFound,
                   let swiftRange = Range(range, in: html) {
                    let sizeString = String(html[swiftRange])
                    
                    // 如果是純數字（位元組）
                    if let bytes = Int64(sizeString) {
                        return bytes
                    }
                    
                    // 如果有單位，需要解析單位
                    if match.numberOfRanges > 2 {
                        let unitRange = match.range(at: 2)
                        if unitRange.location != NSNotFound,
                           let unitSwiftRange = Range(unitRange, in: html) {
                            let unit = String(html[unitSwiftRange]).uppercased()
                            let numberString = sizeString.replacingOccurrences(of: ",", with: "")
                            
                            if let number = Double(numberString) {
                                switch unit {
                                case "B":
                                    return Int64(number)
                                case "KB":
                                    return Int64(number * 1024)
                                case "MB":
                                    return Int64(number * 1024 * 1024)
                                case "GB":
                                    return Int64(number * 1024 * 1024 * 1024)
                                case "TB":
                                    return Int64(number * 1024 * 1024 * 1024 * 1024)
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
        } else {
            return String(format: "%.1f GB", Double(bytes) / (1024.0 * 1024.0 * 1024.0))
        }
    }
    
    // MARK: - 選擇功能
    private func toggleSelectAll() {
        let newSelectionState = !allSelected
        for index in parsedFiles.indices {
            parsedFiles[index].isSelected = newSelectionState
        }
    }
}

// MARK: - Supporting Views

struct ModernFileRowView: View {
    @Binding var file: DriveFile
    let downloadProgress: Double
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 勾選框
                Button(action: {
                    file.isSelected.toggle()
                }) {
                    Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(file.isSelected ? .blue : .gray)
                }
                .buttonStyle(.plain)
                
                Image(systemName: file.type == .file ? "doc.circle" : "folder.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        file.type == .file ? 
                        .linearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        .linearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.fullFileName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    HStack(spacing: 8) {
                        Text(file.size)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .frame(height: 12)
                        
                        Text(file.type == .file ? "檔案" : "資料夾")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer() 
                
                ModernStatusBadge(status: file.status)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if file.status == .downloading {
                VStack(spacing: 6) {
                    HStack {
                        Text("下載進度")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 6)
                        .scaleEffect(y: 1.5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            file.status == .downloading ? .blue.opacity(0.3) : .gray.opacity(0.2),
                            lineWidth: file.status == .downloading ? 2 : 1
                        )
                )
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

struct ModernStatusBadge: View {
    let status: DriveFileStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10, weight: .semibold))
            
            Text(statusText)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(statusBackgroundColor)
        )
        .foregroundColor(statusForegroundColor)
    }
    
    private var statusText: String {
        switch status {
        case .pending: return "待處理"
        case .downloading: return "下載中"
        case .completed: return "完成"
        case .failed: return "失敗"
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .pending: return "clock.circle.fill"
        case .downloading: return "arrow.down.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    private var statusBackgroundColor: Color {
        switch status {
        case .pending: return .gray.opacity(0.15)
        case .downloading: return .blue.opacity(0.15)
        case .completed: return .green.opacity(0.15)
        case .failed: return .red.opacity(0.15)
        }
    }
    
    private var statusForegroundColor: Color {
        switch status {
        case .pending: return .gray
        case .downloading: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// 資料模型
struct DriveFile {
    let id: String
    var name: String
    let type: DriveFileType
    var size: String
    let link: String
    var status: DriveFileStatus
    var isSelected: Bool = true  // 預設為選中狀態
    
    // 計算屬性：完整的檔案名稱（包含副檔名）
    var fullFileName: String {
        if name.contains(".") {
            return name
        } else {
            // 根據檔案類型添加預設副檔名
            switch type {
            case .file:
                return "\(name).file"
            case .folder:
                return name
            }
        }
    }
}

enum DriveFileType {
    case file
    case folder
}

enum DriveFileStatus {
    case pending
    case downloading
    case completed
    case failed
}

#Preview {
    ContentView()
}
