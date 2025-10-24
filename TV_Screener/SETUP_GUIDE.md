# TradingView Screener Monitor - 設定指引

> Workflow 已成功上傳至 n8n 服務器！

## ✅ Workflow 資訊

- **Workflow ID**: `JJeM9dAGD8yFECD5`
- **Workflow 名稱**: TradingView_Screener_Monitor
- **狀態**: 未啟用（需完成配置後啟用）
- **N8N 服務器**: https://wingn8n.zeabur.app
- **創建時間**: 2025-10-24 09:16:08 UTC

## 📋 必要配置步驟

### Step 1: 準備 Google Sheets

#### 1.1 創建新的 Google Sheet

1. 前往 https://sheets.google.com
2. 創建新的 Spreadsheet，命名為：`TradingView_Forex_Screener`
3. 從 URL 提取 Sheet ID

**Sheet ID 提取範例**:
```
URL: https://docs.google.com/spreadsheets/d/1ABC123xyz/edit
Sheet ID: 1ABC123xyz
```

#### 1.2 創建三個 Sheets

在同一個 Spreadsheet 中創建以下三個 sheets：

**Sheet 1: "Latest"** (最新數據)
| A: Symbol | B: Technical Rating | C: Last Updated |
|-----------|---------------------|-----------------|
| EURUSD    | Strong Buy          | 2025-10-24 10:00:00 |

**Sheet 2: "History"** (歷史記錄)
| A: Timestamp | B: Symbol | C: Technical Rating | D: Changed | E: Previous Rating |
|--------------|-----------|---------------------|------------|-------------------|
| 2025-10-24 10:00:00 | EURUSD | Strong Buy | No | Strong Buy |

**Sheet 3: "Changes_Log"** (變化日誌)
| A: Timestamp | B: Symbol | C: From Rating | D: To Rating | E: Notified |
|--------------|-----------|----------------|--------------|-------------|
| 2025-10-24 10:00:00 | GBPUSD | Neutral | Buy | Yes |

#### 1.3 設定 Google Sheets API 權限

**選項 A: 使用 OAuth2（推薦）**
1. 在 n8n 中訪問 Credentials 設定
2. 添加新的 "Google Sheets OAuth2 API" credential
3. 授權 n8n 存取您的 Google Sheets

**選項 B: 使用 Service Account**
1. 前往 https://console.cloud.google.com/
2. 創建新專案或選擇現有專案
3. 啟用 Google Sheets API
4. 創建 Service Account 並下載 JSON 金鑰
5. 將 Sheet 分享給 Service Account Email（編輯權限）
6. 在 n8n 中上傳 Service Account JSON

### Step 2: 配置 N8N Workflow

#### 2.1 訪問 Workflow 編輯器

訪問: https://wingn8n.zeabur.app/workflow/JJeM9dAGD8yFECD5

#### 2.2 更新 "Read Latest Sheet" 節點

1. 點擊 "Read Latest Sheet" 節點
2. 將 `YOUR_SHEET_ID_HERE` 替換為您的 Google Sheet ID（從 Step 1.1）
3. 選擇或創建 Google Sheets Credential
4. 確認 Sheet Name 設定為 "Latest"
5. 保存節點

#### 2.3 替換 Placeholder 節點為實際的 Google Sheets 節點

**需要替換的節點**:
1. **"Update Latest Sheet"** (目前是 Code 節點)
2. **"Append to History Sheet"** (目前是 Code 節點)
3. **"Append to Changes Log"** (目前是 Code 節點)

**替換步驟**:

##### 節點 1: Update Latest Sheet
1. 刪除現有的 "Update Latest Sheet" Code 節點
2. 添加新的 "Google Sheets" 節點
3. 配置：
   - **Operation**: `clear` 然後 `append`（或使用 `Update` operation）
   - **Document**: 選擇您的 Google Sheet
   - **Sheet Name**: `Latest`
   - **Data**: 來自 "Compare Data and Detect Changes" 節點的 `all_results`
   - **Columns Mapping**:
     - Symbol → `{{ $json.symbol }}`
     - Technical Rating → `{{ $json.technical_rating }}`
     - Last Updated → `{{ $json.timestamp }}`

##### 節點 2: Append to History Sheet
1. 刪除現有的 "Append to History Sheet" Code 節點
2. 添加新的 "Google Sheets" 節點
3. 配置：
   - **Operation**: `append`
   - **Document**: 選擇您的 Google Sheet
   - **Sheet Name**: `History`
   - **Data Mode**: `Auto-Map Input Data` 或 `Map Each Column`
   - **Columns Mapping**:
     - Timestamp → `{{ $json.timestamp }}`
     - Symbol → `{{ $json.symbol }}`
     - Technical Rating → `{{ $json.technical_rating }}`
     - Changed → `{{ $json.changed }}`
     - Previous Rating → `{{ $json.previous_rating }}`

##### 節點 3: Append to Changes Log
1. 刪除現有的 "Append to Changes Log" Code 節點
2. 添加新的 "Google Sheets" 節點
3. 配置：
   - **Operation**: `append`
   - **Document**: 選擇您的 Google Sheet
   - **Sheet Name**: `Changes_Log`
   - **Data**: 來自 "Format Bark Notification" 節點的 `changes`
   - **Columns Mapping**:
     - Timestamp → `{{ $json.timestamp }}`
     - Symbol → `{{ $json.symbol }}`
     - From Rating → `{{ $json.from_rating }}`
     - To Rating → `{{ $json.to_rating }}`
     - Notified → `Yes`

**重新連接節點**:
- "Compare Data and Detect Changes" → "Update Latest Sheet"
- "Compare Data and Detect Changes" → "Append to History Sheet"
- "Format Bark Notification" → "Append to Changes Log"

#### 2.4 設定 Bark 通知

**獲取 Bark Device Key**:
1. 從 iOS App Store 下載並安裝 Bark App
2. 打開 Bark App
3. 複製 Device Key（如 URL `https://api.day.app/yourkey/` 中的 `yourkey`）

**在 N8N 中設定環境變數**:

**方法 A: 透過 N8N 介面**（如支援）
1. 前往 Settings → Environment Variables
2. 添加新變數：`BARK_KEY`
3. 值：您的 Bark Device Key（如 `yourkey`）

**方法 B: 透過 Docker/部署配置**
```bash
# 在 docker-compose.yml 或環境變數中添加
BARK_KEY=yourkey
```

**方法 C: 直接在節點中設定（不推薦）**
1. 編輯 "Send Bark Push" 節點
2. 將 `$env.BARK_KEY` 替換為實際的 Device Key

#### 2.5 測試 Workflow

**手動測試步驟**:

1. **測試 Firecrawl API**
   - 點擊 "Scrape TradingView Forex Screener" 節點
   - 點擊 "Execute Node"
   - 確認回應包含 `success: true` 和數據

2. **測試數據解析**
   - 點擊 "Parse and Format Data" 節點
   - 點擊 "Execute Node"
   - 確認輸出格式正確

3. **測試完整流程**（首次執行）
   - 點擊右上角 "Execute Workflow"
   - 觀察每個節點的執行結果
   - 檢查 Google Sheets 是否正確更新

4. **測試變化檢測**
   - 手動修改 "Latest" sheet 中某個評級
   - 再次執行 Workflow
   - 確認收到 Bark 通知
   - 檢查 "Changes_Log" sheet 是否記錄變化

### Step 3: 啟用 Workflow

完成所有配置並測試成功後：

1. 在 Workflow 編輯器右上角
2. 將 Workflow 狀態切換為 **Active** (啟用)
3. Workflow 將按照 Schedule Trigger 設定自動執行（每 2 小時一次）

## 🔧 進階配置

### 調整執行頻率

編輯 "Every 2 Hours Trigger" 節點：

```
每小時執行：
- field: hours
- hoursInterval: 1

每 4 小時執行：
- field: hours
- hoursInterval: 4

使用 Cron Expression（僅交易時段）：
- field: cronExpression
- expression: "0 */2 * * 1-5"  # 每週一至週五，每 2 小時
```

### 添加錯誤通知

1. 為關鍵節點添加 Error Output
2. 連接到 "Send Bark Push" 節點
3. 發送錯誤通知

### 過濾特定貨幣對

在 "Compare Data and Detect Changes" 節點的程式碼中添加過濾邏輯：

```javascript
// 僅監控特定貨幣對
const watchlist = ['EURUSD', 'GBPUSD', 'USDJPY', 'GBPJPY'];

newData.forEach(item => {
  const symbol = item.json.symbol;
  
  // 跳過不在 watchlist 中的貨幣對
  if (!watchlist.includes(symbol)) {
    return;
  }
  
  // ... 其餘邏輯
});
```

## 📊 監控與維護

### 查看執行歷史

1. 在 n8n 介面中點擊 "Executions"
2. 查看 "TradingView_Screener_Monitor" 的執行記錄
3. 檢查成功/失敗狀態

### 定期維護任務

- **每日**: 檢查 Bark 通知，關注評級變化
- **每週**: 查看 "Latest" sheet，確認數據更新正常
- **每月**: 
  - 檢查 Firecrawl API 用量（免費額度：500 請求/月）
  - 清理 "History" sheet 舊數據（保留 3 個月）
  - 下載 CSV 備份

### 故障排除

**問題 1: Firecrawl API 回傳錯誤**
- 檢查 API Key 是否正確
- 確認 TradingView 網站可正常訪問
- 查看 API 配額是否用完

**問題 2: Google Sheets 無法寫入**
- 確認 Credential 授權正確
- 檢查 Sheet 名稱拼寫
- 驗證 Sheet ID 正確

**問題 3: 未收到 Bark 通知**
- 驗證 Device Key 是否正確
- 測試直接訪問 Bark API URL
- 檢查 iPhone Bark App 是否在背景執行

**問題 4: Workflow 執行失敗**
- 查看 Execution 日誌中的錯誤訊息
- 逐個節點手動測試
- 檢查節點之間的數據傳遞

## 📝 重要注意事項

1. **首次執行**: 由於 "Latest" sheet 為空，不會觸發變化通知，這是正常的
2. **API 限制**: Firecrawl 免費方案每月 500 次請求，每 2 小時執行約 360 次/月
3. **數據延遲**: Firecrawl 使用 48 小時快取（`maxAge: 172800000`），減少實際請求次數
4. **時區設定**: 時間戳使用 UTC，如需香港時間請調整程式碼
5. **安全性**: 不要在公開場合分享 Sheet ID、Bark Key 或 Firecrawl API Key

## 🚀 下一步

完成設定後，您的 TradingView Forex Screener 自動監控系統已準備就緒！

系統將：
- ✅ 每 2 小時自動抓取 TradingView Forex Screener 數據
- ✅ 儲存至 Google Sheets（Latest / History / Changes_Log）
- ✅ 檢測技術評級變化
- ✅ 透過 Bark 推送通知到您的 iPhone

如有任何問題，請參考：
- [`N8N_DESIGN_PLAN.md`](./N8N_DESIGN_PLAN.md) - 完整設計文檔
- [`PRINCIPLES.md`](./PRINCIPLES.md) - 策略原理說明
- [`README.md`](./README.md) - 快速開始指南

---

**文件版本**: v1.0  
**最後更新**: 2025-10-24  
**Workflow ID**: JJeM9dAGD8yFECD5

