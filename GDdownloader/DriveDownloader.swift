//
//  DriveDownloader.swift
//  GDdownloader
//
//  Created by 千葉牧人 on 2025/8/4.
//

import Foundation
import SwiftUI

// This file is being rebuilt.

typealias ExtractedFileInfo = (name: String, size: String, downloadURL: String)

@MainActor
class DriveDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: [String: Double] = [:]
    @Published var downloadStatus: [String: String] = [:]

    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
    }()

    // Functions will be added here.

    /// Fetches file information, handling the virus scan warning page.
    func getFileInfo(fileId: String) async throws -> ExtractedFileInfo {
        let initialURL = URL(string: "https://drive.google.com/uc?export=download&id=\(fileId)")!
        print("=== 檔案信息獲取 (1/2) ===")
        print("檔案 ID: \(fileId)")
        print("請求 URL: \(initialURL.absoluteString)")

        var request = URLRequest(url: initialURL)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DownloadError.networkError("無效的 HTTP 回應")
        }

        print("HTTP 狀態碼: \(httpResponse.statusCode)")
        print("Content-Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "未知")")

        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           contentType.contains("text/html"),
           let html = String(data: data, encoding: .utf8),
           html.contains("id=\"download-form\"") {
            
            print("⚠️  檢測到病毒掃描頁面，正在解析...")
            return try extractInfoFromVirusScanPage(html: html, fileId: fileId)
        }

        print("✅ 直接獲取檔案資訊 (非病毒掃描頁面)")
        let fileName = extractFileName(from: httpResponse, html: String(data: data, encoding: .utf8)) ?? "未知檔案.file"
        let fileSize = formatFileSize(httpResponse.expectedContentLength)
        
        return (fileName, fileSize, initialURL.absoluteString)
    }

    private func extractInfoFromVirusScanPage(html: String, fileId: String) throws -> ExtractedFileInfo {
        let fileName = extractFileNameFromVirusScanPage(html) ?? "未知檔案.file"
        let fileSize = extractFileSizeFromVirusScanPage(html) ?? "未知大小"
        print("✅ 從 HTML 提取 - 名稱: \(fileName), 大小: \(fileSize)")

        guard let confirmToken = extractValue(from: html, for: "confirm") else {
            throw DownloadError.parsingError("無法從 HTML 中提取 'confirm' token")
        }
        guard let uuid = extractValue(from: html, for: "uuid") else {
            throw DownloadError.parsingError("無法從 HTML 中提取 'uuid' token")
        }
        print("✅ 從 HTML 提取 - Confirm: \(confirmToken), UUID: \(uuid)")

        let downloadURL = "https://drive.usercontent.google.com/download?id=\(fileId)&export=download&confirm=\(confirmToken)&uuid=\(uuid)"
        print("✅ 建構最終下載 URL: \(downloadURL)")

        return (fileName, fileSize, downloadURL)
    }
    
    private func extractValue(from html: String, for key: String) -> String? {
        let pattern = #"<input type="hidden" name="\#(key)" value="([^"]+)">"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        if let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        return nil
    }

    private func extractFileNameFromVirusScanPage(_ html: String) -> String? {
        let pattern = #"<span class="uc-name-size"><a[^>]*>([^<]+)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        if let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        return nil
    }

    private func extractFileSizeFromVirusScanPage(_ html: String) -> String? {
        let pattern = #"<span class="uc-name-size">[^>]*>\s*\(([^\]+)\)</span>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        if let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        return nil
    }

    private func extractFileName(from response: HTTPURLResponse, html: String?) -> String? {
        if let disposition = response.value(forHTTPHeaderField: "Content-Disposition"),
           let fileName = disposition.components(separatedBy: "filename=").last?.replacingOccurrences(of: "\"", with: "") {
            return fileName
        }
        if let html = html {
            let pattern = #"<title>([^<]+) - Google Drive</title>"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        return nil
    }

    private func formatFileSize(_ bytes: Int64?) -> String {
        guard let bytes = bytes, bytes > 0 else { return "未知大小" }
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: bytes)
    }

    func startBatchDownload(files: [DriveFile], savePath: String) async -> [DriveFile] {
        isDownloading = true
        var updatedFiles = files

        for i in 0..<files.count {
            let file = files[i]
            do {
                let fileInfo = try await getFileInfo(fileId: file.id)
                
                updatedFiles[i].name = fileInfo.name
                updatedFiles[i].size = fileInfo.size
                updatedFiles[i].status = .downloading

                print("=== 開始下載 (2/2) ===")
                print("檔案: \(fileInfo.name)")
                print("儲存路徑: \(savePath)")
                
                let localPath = try await downloadFile(
                    downloadURL: fileInfo.downloadURL,
                    fileName: fileInfo.name,
                    savePath: savePath,
                    fileId: file.id
                )
                
                print("✅ 下載成功: \(localPath)")
                updatedFiles[i].status = .completed
                
            } catch {
                print("❌ 下載失敗: \(files[i].name), 錯誤: \(error.localizedDescription)")
                updatedFiles[i].status = .failed
            }
        }

        isDownloading = false
        return updatedFiles
    }

    private func downloadFile(downloadURL: String, fileName: String, savePath: String, fileId: String) async throws -> String {
        guard let url = URL(string: downloadURL) else {
            throw DownloadError.invalidURL("無效的最終下載 URL")
        }

        // 使用 Apple 官方推薦的異步下載方法，它會將檔案下載到一個臨時位置。
        // 注意：這個簡潔的 API 不提供即時進度回報。
        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DownloadError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        // 再次檢查，以防萬一最終連結仍然是 HTML 頁面
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"), contentType.contains("text/html") {
            print("❌ 錯誤: 最終下載連結仍然回傳 HTML 頁面。")
            throw DownloadError.parsingError("下載連結無效，收到非預期的網頁。")
        }

        // 在下載完成後，手動將進度更新到 100%
        DispatchQueue.main.async {
            self.downloadProgress[fileId] = 1.0
        }

        // 將檔案從臨時位置移動到使用者指定的儲存路徑
        return try await saveFile(from: tempURL, fileName: fileName, savePath: savePath)
    }

    private func saveFile(from tempURL: URL, fileName: String, savePath: String) async throws -> String {
        let fileManager = FileManager.default
        let saveURL = URL(fileURLWithPath: savePath, isDirectory: true).appendingPathComponent(fileName)
        
        // 確保目標資料夾存在
        try? fileManager.createDirectory(at: saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        // 如果檔案已存在，先將其移除
        if fileManager.fileExists(atPath: saveURL.path) {
            try? fileManager.removeItem(at: saveURL)
        }
        
        // 將下載好的檔案移動到最終位置
        try fileManager.moveItem(at: tempURL, to: saveURL)
        print("✅ 檔案已儲存到: \(saveURL.path)")
        return saveURL.path
    }

    func cancelAllDownloads() {
        for task in downloadTasks.values {
            task.cancel()
        }
        downloadTasks.removeAll()
        isDownloading = false
    }
}

enum DownloadError: Error, LocalizedError {
    case networkError(String)
    case invalidURL(String)
    case httpError(Int)
    case parsingError(String)
    case fileSystemError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "網路錯誤: \(message)"
        case .invalidURL(let message): return "無效 URL: \(message)"
        case .httpError(let code): return "HTTP 錯誤，狀態碼: \(code)"
        case .parsingError(let message): return "解析錯誤: \(message)"
        case .fileSystemError(let message): return "檔案系統錯誤: \(message)"
        }
    }
}
