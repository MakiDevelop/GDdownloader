# GDdownloader - Google Drive 批次下載器

一個專為 macOS 設計的 Google Drive 批次下載應用程式，讓您可以輕鬆下載多個 Google Drive 檔案。

## 功能特色

### 🎯 核心功能
- **批次處理**：一次貼入多個 Google Drive 連結
- **智能解析**：自動識別檔案和資料夾連結
- **拖拉支援**：直接拖拉文字檔到應用程式
- **進度顯示**：即時顯示解析和下載進度
- **路徑選擇**：自由選擇下載儲存位置

### 🔗 支援的連結格式
- 單一檔案連結：`https://drive.google.com/file/d/[FILE_ID]`
- 資料夾連結：`https://drive.google.com/drive/folders/[FOLDER_ID]`
- Google Docs：`https://docs.google.com/document/d/[DOC_ID]`
- Google Sheets：`https://docs.google.com/spreadsheets/d/[SHEET_ID]`
- 分享連結：包含 `?usp=sharing` 參數的連結
- 預覽/編輯連結：包含 `/preview` 或 `/edit` 的連結

## 使用方法

### 1. 輸入連結
- **直接貼入**：在文字框中貼入 Google Drive 連結，每行一個
- **載入檔案**：點擊「載入文字檔」按鈕選擇包含連結的文字檔
- **拖拉檔案**：直接拖拉文字檔到應用程式視窗

### 2. 解析連結
- 點擊「解析連結」按鈕
- 系統會自動識別有效的 Google Drive 連結
- 在檔案列表中查看解析結果

### 3. 選擇儲存路徑
- 點擊「選擇」按鈕
- 選擇要儲存下載檔案的資料夾

### 4. 開始下載
- 點擊「開始下載」按鈕
- 查看下載進度和狀態

## 系統需求

- macOS 13 Ventura 或更新版本
- 至少 100MB 可用磁碟空間

## 開發狀態

### ✅ 已完成
- [x] 基本 UI 介面
- [x] Google Drive 連結解析器
- [x] 拖拉檔案功能
- [x] 檔案列表顯示
- [x] 儲存路徑選擇

### 🚧 開發中
- [ ] Google Drive API 整合
- [ ] OAuth 2.0 授權
- [ ] 實際檔案下載功能
- [ ] 下載進度顯示
- [ ] 錯誤處理和重試機制

### 📋 計劃中
- [ ] 並行下載控制
- [ ] 檔案篩選功能
- [ ] 資料夾結構保留
- [ ] 自動解壓縮
- [ ] 設定頁面

## 技術架構

- **語言**：Swift
- **UI 框架**：SwiftUI
- **網路**：URLSession
- **檔案處理**：FileManager
- **並發處理**：GCD (Grand Central Dispatch)

## 測試

使用 `test_links.txt` 檔案來測試連結解析功能。該檔案包含各種 Google Drive 連結格式的範例。

## 注意事項

⚠️ **重要提醒**
- 目前版本僅支援連結解析，實際下載功能尚未實作
- 對於需要授權的私密檔案，需要實作 Google OAuth 流程
- 請遵守 Google Drive API 的使用限制和速率限制

## 授權

本專案採用 MIT 授權條款。

## 貢獻

歡迎提交 Issue 和 Pull Request 來改善這個專案！

---

**版本**：0.1.0  
**最後更新**：2025年8月 