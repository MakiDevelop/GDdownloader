//
//  DriveLinkParser.swift
//  GDdownloader
//
//  Created by 千葉牧人 on 2025/8/4.
//

import Foundation

class DriveLinkParser {
    
    // Google Drive 連結模式
    private static let patterns: [(pattern: String, type: DriveFileType)] = [
        // === 基本檔案連結格式 ===
        // 標準檔案連結
        (#"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://drive\.google\.com/open\?id=([a-zA-Z0-9_-]+)"#, .file),
        
        // === UC 下載連結（各種參數順序） ===
        // id 在第一個參數
        (#"https://drive\.google\.com/uc\?id=([a-zA-Z0-9_-]+)(?:&[^&\s]*)*"#, .file),
        // id 在其他位置
        (#"https://drive\.google\.com/uc\?([^&\s]*&)*id=([a-zA-Z0-9_-]+)(?:&[^&\s]*)*"#, .file),
        // 包含 export 參數的各種組合
        (#"https://drive\.google\.com/uc\?export=[^&\s]*&id=([a-zA-Z0-9_-]+)(?:&[^&\s]*)*"#, .file),
        (#"https://drive\.google\.com/uc\?id=([a-zA-Z0-9_-]+)&export=[^&\s]*(?:&[^&\s]*)*"#, .file),
        
        // === 各種檔案操作連結 ===
        // 檔案檢視和預覽
        (#"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/view"#, .file),
        (#"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/preview"#, .file),
        (#"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/edit"#, .file),
        (#"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/copy"#, .file),
        
        // 帶用戶帳號的連結
        (#"https://drive\.google\.com/drive/u/\d+/file/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://drive\.google\.com/a/[^/]+/file/d/([a-zA-Z0-9_-]+)"#, .file),
        
        // === Google Workspace 文件 ===
        // Google Docs
        (#"https://docs\.google\.com/document/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://docs\.google\.com/document/u/\d+/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://docs\.google\.com/a/[^/]+/document/d/([a-zA-Z0-9_-]+)"#, .file),
        
        // Google Sheets
        (#"https://docs\.google\.com/spreadsheets/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://docs\.google\.com/spreadsheets/u/\d+/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://docs\.google\.com/a/[^/]+/spreadsheets/d/([a-zA-Z0-9_-]+)"#, .file),
        
        // Google Slides
        (#"https://docs\.google\.com/presentation/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://docs\.google\.com/presentation/u/\d+/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://docs\.google\.com/a/[^/]+/presentation/d/([a-zA-Z0-9_-]+)"#, .file),
        
        // Google Forms
        (#"https://docs\.google\.com/forms/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://forms\.gle/([a-zA-Z0-9_-]+)"#, .file),
        
        // Google Drawings
        (#"https://docs\.google\.com/drawings/d/([a-zA-Z0-9_-]+)"#, .file),
        
        // === 資料夾連結 ===
        // 標準資料夾
        (#"https://drive\.google\.com/drive/folders/([a-zA-Z0-9_-]+)"#, .folder),
        (#"https://drive\.google\.com/drive/u/\d+/folders/([a-zA-Z0-9_-]+)"#, .folder),
        (#"https://drive\.google\.com/a/[^/]+/folders/([a-zA-Z0-9_-]+)"#, .folder),
        
        // 開啟資料夾
        (#"https://drive\.google\.com/open\?id=([a-zA-Z0-9_-]+)(?:&[^&\s]*)*"#, .folder),
        
        // === 分享和嵌入連結 ===
        // 分享連結帶參數
        (#"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/view\?usp=sharing"#, .file),
        (#"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/view\?usp=drive_link"#, .file),
        (#"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/view\?usp=drivesdk"#, .file),
        
        // === 行動裝置和應用程式連結 ===
        // 行動版連結
        (#"https://drive\.google\.com/viewerng/viewer\?id=([a-zA-Z0-9_-]+)"#, .file),
        (#"https://drive\.google\.com/thumbnail\?id=([a-zA-Z0-9_-]+)"#, .file),
        
        // === 舊版和替代格式 ===
        // 舊版 googledrive 域名
        (#"https://googledrive\.com/file/d/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://www\.googledrive\.com/file/d/([a-zA-Z0-9_-]+)"#, .file),
        
        // === 短連結和重定向 ===
        // Google 短連結
        (#"https://goo\.gl/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://bit\.ly/([a-zA-Z0-9_-]+)"#, .file),
        (#"https://tinyurl\.com/([a-zA-Z0-9_-]+)"#, .file),
        
        // === 通用模式（最後備用） ===
        // 任何包含檔案 ID 的 Google Drive URL
        (#"https://[^/]*\.google\.com/[^?]*id=([a-zA-Z0-9_-]+)"#, .file)
    ]
    
    /// 解析 Google Drive 連結
    /// - Parameter link: 原始連結字串
    /// - Returns: 解析後的 DriveFile 物件，如果無法解析則返回 nil
    static func parseLink(_ link: String) -> DriveFile? {
        let cleanedLink = cleanLink(link)
        
        // 嘗試解析各種連結模式
        for (pattern, type) in patterns {
            if let fileId = extractFileId(from: cleanedLink, pattern: pattern) {
                return createDriveFile(id: fileId, type: type, originalLink: link)
            }
        }
        
        return nil
    }
    
    /// 批次解析多個連結
    /// - Parameter links: 連結陣列
    /// - Returns: 解析結果陣列
    static func parseLinks(_ links: [String]) -> [DriveFile] {
        return links.compactMap { parseLink($0) }
    }
    
    /// 清理連結字串
    private static func cleanLink(_ link: String) -> String {
        var cleaned = link.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 對於 UC 連結，保留參數因為 ID 在參數中
        // 其他連結類型可以移除多餘參數
        if !cleaned.contains("/uc?") {
            if let questionMarkIndex = cleaned.firstIndex(of: "?") {
                cleaned = String(cleaned[..<questionMarkIndex])
            }
        }
        
        // 移除結尾的斜線
        if cleaned.hasSuffix("/") {
            cleaned = String(cleaned.dropLast())
        }
        
        return cleaned
    }
    
    /// 從連結中提取檔案 ID
    private static func extractFileId(from link: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: link, range: NSRange(link.startIndex..., in: link)),
              match.numberOfRanges > 1 else {
            return nil
        }
        
        // 檢查所有捕獲組，找到第一個有效的檔案 ID
        for i in 1..<match.numberOfRanges {
            let range = match.range(at: i)
            if range.location != NSNotFound,
               let swiftRange = Range(range, in: link) {
                let capturedString = String(link[swiftRange])
                
                // 驗證是否為有效的檔案 ID 格式（只包含字母、數字、連字號、底線）
                if capturedString.range(of: "^[a-zA-Z0-9_-]+$", options: .regularExpression) != nil {
                    return capturedString
                }
            }
        }
        
        return nil
    }
    
    /// 建立 DriveFile 物件
    private static func createDriveFile(id: String, type: DriveFileType, originalLink: String) -> DriveFile {
        return DriveFile(
            id: id,
            name: generateFileName(for: id, type: type),
            type: type,
            size: "未知",
            link: originalLink,
            status: .pending
        )
    }
    
    /// 根據檔案 ID 和類型生成檔案名稱
    private static func generateFileName(for id: String, type: DriveFileType) -> String {
        let prefix = type == .file ? "檔案" : "資料夾"
        return "\(prefix)_\(id.prefix(8))"
    }
    
    /// 驗證連結是否為有效的 Google Drive 連結
    static func isValidGoogleDriveLink(_ link: String) -> Bool {
        let cleanedLink = cleanLink(link)
        
        for (pattern, _) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: cleanedLink, range: NSRange(cleanedLink.startIndex..., in: cleanedLink)) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// 取得連結類型描述
    static func getLinkTypeDescription(_ link: String) -> String {
        if let file = parseLink(link) {
            switch file.type {
            case .file:
                return "單一檔案"
            case .folder:
                return "資料夾"
            }
        }
        return "未知類型"
    }
}

// 擴展 DriveFile 以支援更多功能
extension DriveFile {
    /// 取得下載 URL（需要實作 Google Drive API）
    var downloadURL: String {
        // 基本的下載 URL 格式
        return "https://drive.google.com/uc?export=download&id=\(id)"
    }
    
    /// 取得預覽 URL
    var previewURL: String {
        return "https://drive.google.com/file/d/\(id)/preview"
    }
    
    /// 檢查是否為公開檔案
    var isPublic: Bool {
        // 這裡需要實作 Google Drive API 檢查
        // 暫時返回 true
        return true
    }
} 