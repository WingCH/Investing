# TradingView Forex Screener 自動導出系統 N8N 設計計劃書

本文件設計一個 N8N 自動化工作流程，解決 TradingView Forex Screener 免費用戶無法導出數據的問題。

---

## 專案概覽 Project Overview

**專案名稱**: TradingView Forex Screener Auto Export System  
**目標**: 自動抓取 TradingView Forex Screener 數據，儲存至 Google Sheets，並監控技術評級變化  
**平台**: N8N Workflow Automation  
**執行週期**: 每小時一次（可調整）或手動觸發

**核心功能**:
- 使用 Firecrawl API 抓取 TradingView Forex Screener 頁面數據
- 解析並提取外匯貨幣對的 symbol_name 和 technical_rating
- 將數據以橫向格式儲存至 Google Sheets 並保留歷史記錄
- 與上一次數據對比，檢測 technical_rating 變化
- 🎯 **個性化訂閱**: 每個用戶可選擇只接收特定貨幣對的變化通知
- 透過 Bark 推送通知重要變化到多個裝置

**解決痛點**:
- TradingView 免費用戶無法導出 Screener 數據
- 無需手動記錄和追蹤技術評級變化
- 自動化監控多個貨幣對的評級轉變

---

## 工作流程架構 Workflow Architecture

### 主要工作流程 Main Workflow

**Workflow 名稱**: `TradingView_Screener_Monitor`

```
┌─────────────────┐
│  Schedule       │ 每 2 小時執行一次
│  Trigger        │ (可調整)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  HTTP Request   │ 呼叫 Firecrawl API
│  (Firecrawl)    │ 抓取 TradingView 數據
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Parse & Format │ 解析回傳的 JSON
│  Data (Code)    │ 轉換為橫向格式
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Google Sheets   │ 追加新數據到 Sheet
│ (Append)        │ 橫向格式：Timestamp + Symbols
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Google Sheets   │ 讀取所有歷史數據
│ (Read All)      │ 用於比對
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  比對最近兩行   │ JavaScript Code
│  找變化 (Code)  │ 比對最後兩次評級
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  IF Node        │ 檢查是否有變化？
│  Has Changes?   │
└────────┬────────┘
         │ Yes
         ▼
┌─────────────────┐
│  準備多裝置     │ 🎯 根據用戶訂閱
│  推送 (Code)    │ 過濾相關變化
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  格式化個人     │ 為每個用戶生成
│  通知 (Code)    │ 專屬通知內容
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  發送 Bark      │ 自動循環發送到
│  推送 (HTTP)    │ 每個訂閱裝置
└─────────────────┘
```

---

## Step 1: 環境準備與設定 Environment Setup

### 1.1 N8N 安裝與配置

**必要條件**:
- N8N 平台（自架或雲端版本）
- Node.js 18+ 環境
- 網絡連接供 API 呼叫

**安裝指令**:
```bash
# 使用 npm 安裝
npm install -g n8n

# 或使用 Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

**啟動 N8N**:
```bash
n8n start
```

訪問 http://localhost:5678 進入 N8N 介面。

### 1.2 API Keys 與服務設定

需要取得以下服務：

#### 1. Firecrawl API
- **取得方式**: 前往 https://firecrawl.dev/ 註冊
- **API Key**: `fc-752d2d2535c9478b83b5aebc3c802781` （已提供）
- **用途**: 抓取 TradingView Forex Screener 頁面並解析數據
- **API 端點**: `https://api.firecrawl.dev/v2/scrape`
- **文檔**: https://docs.firecrawl.dev/

**費用考量**:
- 免費方案：每月 500 次請求
- 每小時執行一次：每月約 720 次請求（建議升級或調整頻率）
- 建議：每 2-4 小時執行一次，或僅在交易時段執行

#### 2. Google Sheets API
- **取得方式**: Google Cloud Console 啟用 Sheets API
- **步驟**:
  1. 前往 https://console.cloud.google.com/
  2. 創建新專案或選擇現有專案
  3. 啟用 Google Sheets API
  4. 創建服務帳號（Service Account）
  5. 下載 JSON 金鑰檔案
- **用途**: 讀寫 Google Sheets 數據

#### 3. Bark 推送通知
- **取得方式**: iOS App Store 下載 Bark App
- **設定步驟**:
  1. 安裝 Bark App
  2. 打開 App，取得 Device Key（如 `https://api.day.app/yourkey/`）
  3. 測試推送：訪問 `https://api.day.app/yourkey/測試標題/測試內容`
- **用途**: 接收技術評級變化通知
- **優點**: 完全免費，支援豐富的推送格式

### 1.3 N8N Credentials 設定

在 N8N 介面中設定以下 Credentials：

#### Firecrawl API Credential
1. 進入 N8N → Settings → Credentials
2. 新增 "Header Auth" credential
3. 名稱: `Firecrawl_API`
4. 設定:
   - Name: `Authorization`
   - Value: `Bearer fc-752d2d2535c9478b83b5aebc3c802781`

#### Google Sheets Credential
1. 新增 "Google Sheets OAuth2 API" credential
2. 名稱: `Google_Sheets_TV_Screener`
3. 上傳 Service Account JSON 或使用 OAuth2
4. 授予 Sheets 讀寫權限

#### Bark Credential（選用）
1. 新增 "Generic Credential" 或直接在 workflow 中設定
2. 儲存 Device Key: 如 `yourkey` (從 URL `https://api.day.app/yourkey/` 提取)

---

## Step 2: Google Sheets 結構設計

### 2.1 建立 Google Sheet

**Sheet 名稱**: `TradingView_Forex_Screener`

**Sheet 結構**:

#### Sheet 1: "工作表1" 或 "Latest"（記錄數據）
採用**橫向格式**存儲，每個貨幣對是一個欄位。每次執行追加一行新記錄。

| A: Timestamp | B: EURUSD | C: GBPUSD | D: USDJPY | E: AUDCAD | F: ... |
|--------------|-----------|-----------|-----------|-----------|--------|
| 2025-10-27T15:00:00.000Z | Strong Buy | Buy | Neutral | Sell | ... |
| 2025-10-27T13:00:00.000Z | Strong Buy | Neutral | Neutral | Sell | ... |
| 2025-10-27T11:00:00.000Z | Buy | Neutral | Buy | Neutral | ... |
| ...          | ...       | ...       | ...       | ...       | ...    |

**格式特點**:
- ✅ **橫向布局**: 時間戳在第一列，每個貨幣對佔一列
- ✅ **固定 Symbols**: 因為貨幣對數量固定，這種格式更直觀
- ✅ **簡潔高效**: 每次執行只追加一行，包含所有貨幣對的當前評級
- ✅ **易於比對**: 直接讀取最後兩行即可進行變化檢測
- ✅ **時間序列**: 自然形成時間序列數據，適合趨勢分析

### 2.2 預先設定 Google Sheet

**步驟**:
1. 建立新的 Google Sheet
2. 重命名為 `TradingView_Forex_Screener`
3. 保留默認的 "工作表1" (或命名為 "Latest")
4. 在第一行添加標題行:
   - A1: `Timestamp`
   - B1, C1, D1... 等: 將由第一次執行自動填入各貨幣對名稱 (如 `EURUSD`, `GBPUSD` 等)
   - ℹ️ **注意**: 使用 Google Sheets 的 "Auto-Map Input Data" 功能，首次追加時會自動建立標題
5. 將 Sheet 分享給 N8N 的 Service Account Email（如 `xxx@xxx.iam.gserviceaccount.com`）並給予編輯權限
6. 記錄 Google Sheet ID（從 URL 提取）

**Sheet ID 提取範例**:
```
URL: https://docs.google.com/spreadsheets/d/1ABC123xyz/edit
Sheet ID: 1ABC123xyz
```

---

## Step 3: N8N Workflow 詳細設計

### Workflow 名稱: `TradingView_Screener_Monitor`

### 節點配置詳解

#### Node 1: Schedule Trigger（定時觸發器）
**節點類型**: `Schedule Trigger`  
**名稱**: `Every Hour Trigger`

**配置**:
```json
{
  "rule": {
    "interval": [
      {
        "field": "hours",
        "hoursInterval": 1
      }
    ]
  }
}
```

**說明**:
- 每小時執行一次
- 可調整為每 2/4/6 小時
- 或設定為僅在交易時段執行（週一至週五 UTC 00:00-22:00）

**進階配置（僅交易時段）**:
```json
{
  "rule": {
    "interval": [
      {
        "field": "cronExpression",
        "cronExpression": "0 * * * 1-5"
      }
    ]
  }
}
```
（每週一至週五，每小時整點執行）

---

#### Node 2: HTTP Request - Firecrawl Scrape（抓取數據）
**節點類型**: `HTTP Request`  
**名稱**: `Scrape TradingView Forex Screener`

**配置**:
- **Method**: `POST`
- **URL**: `https://api.firecrawl.dev/v2/scrape`
- **Authentication**: Header Auth（使用 Firecrawl_API credential）
- **Send Headers**: 
  - `Content-Type`: `application/json`
  - `Authorization`: `Bearer fc-752d2d2535c9478b83b5aebc3c802781`
- **Send Body**: Yes (JSON)

**Body 內容**:
```json
{
  "url": "https://www.tradingview.com/forex-screener/",
  "onlyMainContent": false,
  "maxAge": 172800000,
  "parsers": ["pdf"],
  "formats": [
    {
      "type": "json",
      "schema": {
        "type": "object",
        "required": [],
        "properties": {
          "data": {
            "type": "array",
            "items": {
              "type": "object",
              "required": [],
              "properties": {
                "symbol_name": {
                  "type": "string"
                },
                "technical_rating": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    }
  ]
}
```

**說明**:
- `maxAge: 172800000` (48小時) 表示可使用 48 小時內的快取數據，減少 API 用量
- JSON schema 定義了要提取的數據結構
- 回傳格式應包含 `data` 陣列，每個項目有 `symbol_name` 和 `technical_rating`

**預期回應範例**:
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "symbol_name": "EURUSD",
        "technical_rating": "Strong Buy"
      },
      {
        "symbol_name": "GBPUSD",
        "technical_rating": "Buy"
      },
      {
        "symbol_name": "USDJPY",
        "technical_rating": "Neutral"
      }
    ]
  }
}
```

**錯誤處理**:
- 設定 "Continue On Fail": true
- 添加 Error Trigger 分支處理失敗情況

---

#### Node 3: Code - Parse and Format Data（解析並轉換為橫向格式）
**節點類型**: `Code`  
**名稱**: `Parse and Format Data`

**JavaScript Code**:
```javascript
const response = $input.first().json;

if (!response.success || !response.data || !response.data.json.data) {
  throw new Error('Firecrawl API 回應格式錯誤或抓取失敗');
}

const scrapedData = response.data.json.data;
const timestamp = new Date().toISOString();

// 轉換成橫向格式：一個物件包含所有 symbol 的評級
const rowData = {
  'Timestamp': timestamp
};

scrapedData.forEach(item => {
  rowData[item.symbol_name] = item.technical_rating;
});

console.log(`抓取完成: ${scrapedData.length} 個貨幣對`);
console.log('資料格式:', Object.keys(rowData).join(', '));

return [{ json: rowData }];
```

**說明**:
- 解析 Firecrawl 回傳的巢狀 JSON 結構
- **轉換為橫向格式**: 將所有貨幣對的評級放在同一個物件中
- 每個 symbol_name 成為物件的一個 key，對應的 technical_rating 是值
- 添加 Timestamp 欄位
- 輸出單一物件（一行數據），包含所有貨幣對

**輸出範例**:
```json
[
  {
    "json": {
      "Timestamp": "2025-10-27T15:00:00.000Z",
      "EURUSD": "Strong Buy",
      "GBPUSD": "Buy",
      "USDJPY": "Neutral",
      "AUDCAD": "Sell",
      "NZDUSD": "Buy"
    }
  }
]
```

---

#### Node 4: Google Sheets - Append Latest Data（追加最新數據）
**節點類型**: `Google Sheets`  
**名稱**: `追加到 Google Sheet`

**配置**:
- **Credential**: `Google_Sheets_TV_Screener`
- **Operation**: `Append`
- **Document**: `TradingView_Forex_Screener` (輸入 Sheet ID: `1xY-x6Ck1bHRTylODJJLSsfaI2x8JKjjvJBVoxKO3fkQ`)
- **Sheet Name**: `工作表1` (gid=0)
- **Columns Mapping**: `Auto-Map Input Data` ✅
- **Options**: 保持默認

**說明**:
- **先儲存再比對**: 首先將新抓取的數據追加到 Google Sheet
- 使用橫向格式，一行包含所有貨幣對的評級
- Auto-Map 會自動將物件的 keys 對應到欄位名稱
- 第一次執行時會自動建立標題行

---

#### Node 5: Google Sheets - Read All Historical Data（讀取所有歷史數據）
**節點類型**: `Google Sheets`  
**名稱**: `讀取所有歷史數據`

**配置**:
- **Credential**: `Google_Sheets_TV_Screener`
- **Operation**: `Read`
- **Document**: `TradingView_Forex_Screener` (輸入 Sheet ID)
- **Sheet Name**: `工作表1` (gid=0)
- **Options**: 
  - Range Definition: `detectAutomatically` (讀取所有數據)

**說明**:
- 在追加新數據後，讀取 Sheet 中的所有歷史記錄
- 用於比對最近兩行數據以檢測變化
- 如果是第一次執行，只有一行數據，無法比對

---

#### Node 6: Code - Compare Recent Rows and Detect Changes（比對最近兩行找變化）
**節點類型**: `Code`  
**名稱**: `比對最近兩行找變化`

**JavaScript Code**:
```javascript
const allData = $input.all();

if (!allData || allData.length < 2) {
  console.log(`數據不足，只有 ${allData?.length || 0} 行`);
  return [{ json: { has_changes: false, changes: [], is_first_run: true } }];
}

// 按時間戳排序，取最後兩行
const sortedData = allData.sort((a, b) => {
  const timeA = new Date(a.json['Timestamp']).getTime();
  const timeB = new Date(b.json['Timestamp']).getTime();
  return timeB - timeA; // 降序
});

const latestRow = sortedData[0].json;
const previousRow = sortedData[1].json;

const latestTimestamp = latestRow['Timestamp'];
const previousTimestamp = previousRow['Timestamp'];

console.log(`比對時間: ${previousTimestamp} -> ${latestTimestamp}`);

// 找出所有 Symbol 欄位（排除 Timestamp 和 Google Sheets 的元數據字段）
const metadataFields = ['Timestamp', 'row_number', 'row_index', '_id'];
const symbols = Object.keys(latestRow).filter(key => !metadataFields.includes(key));
console.log(`共有 ${symbols.length} 個貨幣對`);

// 比對每個 Symbol 的變化
const changes = [];
symbols.forEach(symbol => {
  const newRating = latestRow[symbol];
  const oldRating = previousRow[symbol];
  
  if (oldRating && newRating && oldRating !== newRating) {
    changes.push({
      timestamp: latestTimestamp,
      symbol: symbol,
      from_rating: oldRating,
      to_rating: newRating
    });
  }
});

console.log(`發現 ${changes.length} 個變化`);

return [{
  json: {
    has_changes: changes.length > 0,
    changes: changes,
    total_changes: changes.length,
    total_symbols: symbols.length,
    latest_timestamp: latestTimestamp,
    previous_timestamp: previousTimestamp,
    is_first_run: false
  }
}];
```

**說明**:
- 讀取所有歷史數據後，按時間戳排序
- 取最後兩行（最新和前一次）進行比對
- 過濾出實際的 Symbol 欄位（排除 Timestamp 和 Google Sheets 元數據）
- 逐個比對每個貨幣對的評級變化
- 僅當評級確實改變時才記錄到 `changes` 陣列
- 處理首次執行情況（數據不足 2 行時）

**輸出範例**:
```json
{
  "json": {
    "has_changes": true,
    "changes": [
      {
        "timestamp": "2025-10-27T15:00:00.000Z",
        "symbol": "GBPUSD",
        "from_rating": "Neutral",
        "to_rating": "Buy"
      },
      {
        "timestamp": "2025-10-27T15:00:00.000Z",
        "symbol": "NZDUSD",
        "from_rating": "Sell",
        "to_rating": "Neutral"
      }
    ],
    "total_changes": 2,
    "total_symbols": 70,
    "is_first_run": false
  }
}
```

---

#### Node 7: IF - Check if Changes Exist（檢查是否有變化）
**節點類型**: `IF`  
**名稱**: `Has Changes?`

**配置**:
- **Conditions**:
  - `{{ $json.has_changes }}` equals `true`

**說明**:
- 檢查 `has_changes` 標記
- 如果有變化（true），則執行通知和變化日誌分支
- 如果沒有變化（false），則跳過通知，workflow 結束

---

#### Node 8: Code - Prepare Multi-Device Push（準備多裝置推送）
**節點類型**: `Code`  
**名稱**: `準備多裝置推送`

**執行條件**: 僅在 IF 節點條件為 true 時執行

**JavaScript Code**:
```javascript
// 🎯 在這裡管理所有用戶的訂閱設定
// 每個用戶可以選擇只接收特定貨幣對的變化通知

const userSubscriptions = [
  {
    device_key: 'iXrrdsXHDFBrin5KaqzUmc',
    name: '你自己',
    symbols: ['EURNZD', 'GBPSGD', 'NZDUSD', 'USDCHF', 'ETHUSD', 'AUDUSA']
  },
  // {
  //   device_key: 'FRIEND_DEVICE_KEY_1',
  //   name: '朋友 1',
  //   symbols: ['EURUSD', 'GBPUSD', 'USDJPY']  // 朋友 1 只想看這幾個
  // },
  // {
  //   device_key: 'FRIEND_DEVICE_KEY_2',
  //   name: '朋友 2',
  //   symbols: []  // 空陣列 = 接收所有變化
  // },
];

const allChanges = $input.first().json.changes;

if (!allChanges || allChanges.length === 0) {
  console.log('沒有任何變化');
  return [];
}

const results = [];

userSubscriptions.forEach(user => {
  // 如果用戶的 symbols 是空陣列，代表接收所有變化
  let userChanges = allChanges;
  
  if (user.symbols && user.symbols.length > 0) {
    // 過濾出用戶訂閱的貨幣對
    userChanges = allChanges.filter(change => 
      user.symbols.includes(change.symbol)
    );
  }
  
  // 只有當有相關變化時才推送
  if (userChanges.length > 0) {
    results.push({
      json: {
        device_key: user.device_key,
        user_name: user.name,
        changes: userChanges,
        total_changes: userChanges.length,
        subscribed_symbols: user.symbols
      }
    });
    
    console.log(`✅ ${user.name}: ${userChanges.length} 個相關變化`);
  } else {
    console.log(`⏭️  ${user.name}: 沒有訂閱的貨幣對變化，跳過推送`);
  }
});

console.log(`準備發送通知到 ${results.length} 個裝置`);

return results;
```

**說明**:
- 🎯 **個性化訂閱中心**: 管理所有用戶的訂閱設定
- 每個用戶可指定只接收特定貨幣對的變化通知
- `symbols: []` 空陣列表示接收所有變化
- 智能過濾：只推送用戶關心的貨幣對變化
- 支持多用戶：輕鬆添加新朋友，只需添加一行配置
- 自動跳過沒有相關變化的用戶

**配置範例**:
```javascript
// 添加新朋友只需要：
{
  device_key: 'ABC123DEF456',  // 從 Bark App 獲取
  name: '朋友的名字',
  symbols: ['EURUSD', 'GBPUSD']  // 他關心的貨幣對
}
```

**輸出範例**:
```json
[
  {
    "json": {
      "device_key": "iXrrdsXHDFBrin5KaqzUmc",
      "user_name": "你自己",
      "changes": [
        {
          "timestamp": "2025-10-27T15:00:00.000Z",
          "symbol": "EURNZD",
          "from_rating": "Buy",
          "to_rating": "Strong Buy"
        }
      ],
      "total_changes": 1,
      "subscribed_symbols": ["EURNZD", "GBPSGD", "NZDUSD", "USDCHF", "ETHUSD", "AUDUSA"]
    }
  }
]
```

---

#### Node 9: Code - Format Individual Notification（格式化個人通知）
**節點類型**: `Code`  
**名稱**: `格式化個人通知`

**執行條件**: 僅在 IF 節點條件為 true 時執行

**JavaScript Code**:
```javascript
const changes = $json.changes;

if (!changes || changes.length === 0) {
  return [];
}

// 簡短有力的標題
const count = changes.length;
const title = count === 1 ? `📊 Forex Screener • 1 changed` : `📊 Forex Screener • ${count} changed`;

function isMoreBullish(from, to) {
  const ratings = ['Strong Sell', 'Sell', 'Neutral', 'Buy', 'Strong Buy'];
  return ratings.indexOf(to) > ratings.indexOf(from);
}

function isMoreBearish(from, to) {
  const ratings = ['Strong Sell', 'Sell', 'Neutral', 'Buy', 'Strong Buy'];
  return ratings.indexOf(to) < ratings.indexOf(from);
}

function getArrow(from, to) {
  if (isMoreBullish(from, to)) return '📈→';
  if (isMoreBearish(from, to)) return '📉→';
  return '→';
}

const messageLines = changes.map(change => {
  const arrow = getArrow(change.from_rating, change.to_rating);
  return `${change.symbol}: ${change.from_rating} ${arrow} ${change.to_rating}`;
});

const message = messageLines.join('\n');

return [{
  json: {
    device_key: $json.device_key,
    title: title,
    message: message,
    changes: changes
  }
}];
```

**說明**:
- 為每個用戶生成專屬通知內容
- **簡潔標題**: `📊 Forex Screener • X changed`
- 根據變化方向添加箭頭 emoji（📈 偏多 / 📉 偏空）
- 僅包含該用戶訂閱的貨幣對變化
- **移除趨勢摘要**: 專注於具體變化，不再顯示整體趨勢

**輸出範例**:
```json
{
  "json": {
    "device_key": "iXrrdsXHDFBrin5KaqzUmc",
    "title": "📊 Forex Screener • 2 changed",
    "message": "EURNZD: Buy 📈→ Strong Buy\nNZDUSD: Neutral 📉→ Sell",
    "changes": [...]
  }
}
```

---

#### Node 10: HTTP Request - Send Bark Notification（發送 Bark 通知）
**節點類型**: `HTTP Request`  
**名稱**: `發送 Bark 推送`

**執行條件**: 僅在 IF 節點條件為 true 時執行

**配置**:
- **Method**: `POST`
- **URL**: `https://api.day.app/push`
- **Send Body**: Yes (JSON)
- **Body** (JSON):
```json
{
  "device_key": "={{ $json.device_key }}",
  "title": "={{ $json.title }}",
  "body": "={{ $json.message }}",
  "sound": "bell",
  "icon": "https://www.tradingview.com/favicon.ico",
  "group": "TradingView",
  "url": "https://www.tradingview.com/forex-screener/"
}
```

**說明**:
- 使用 POST 方法發送推送通知到 iOS 裝置
- **自動循環發送**: N8N 會自動為每個輸入項目執行一次（多裝置推送）
- `device_key` 從前一個節點獲取（每個用戶有不同的 key）
- 支援自訂圖示、分組、點擊跳轉等功能
- 每個用戶只收到他們訂閱的貨幣對變化

**Bark 進階功能**:
- `sound`: 通知音效（`bell`, `alarm`, `silence`）
- `icon`: 自訂圖示 URL
- `group`: 通知分組（所有通知歸類到 "TradingView"）
- `url`: 點擊通知後跳轉的連結
- `isArchive`: 是否自動存檔（1=是，0=否）

**通知示例**:
```
📊 Forex Screener • 2 changed

EURNZD: Buy 📈→ Strong Buy
NZDUSD: Neutral 📉→ Sell
```

---

## Step 4: Workflow 完整配置 JSON

以下是完整的 N8N workflow JSON 配置，可直接匯入 N8N：

<details>
<summary>點擊展開完整 Workflow JSON</summary>

```json
{
  "name": "TradingView_Screener_Monitor",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": "hours",
              "hoursInterval": 1
            }
          ]
        }
      },
      "name": "Every Hour Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://api.firecrawl.dev/v2/scrape",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ]
        },
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "url",
              "value": "https://www.tradingview.com/forex-screener/"
            },
            {
              "name": "onlyMainContent",
              "value": false
            },
            {
              "name": "maxAge",
              "value": 172800000
            },
            {
              "name": "parsers",
              "value": ["pdf"]
            },
            {
              "name": "formats",
              "value": [
                {
                  "type": "json",
                  "schema": {
                    "type": "object",
                    "properties": {
                      "data": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "properties": {
                            "symbol_name": {"type": "string"},
                            "technical_rating": {"type": "string"}
                          }
                        }
                      }
                    }
                  }
                }
              ]
            }
          ]
        },
        "options": {}
      },
      "name": "Scrape TradingView Forex Screener",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "position": [450, 300],
      "credentials": {
        "httpHeaderAuth": {
          "id": "1",
          "name": "Firecrawl_API"
        }
      }
    },
    {
      "parameters": {
        "jsCode": "const response = $input.item.json;\n\nif (!response.success || !response.data || !response.data.data) {\n  throw new Error('Firecrawl API response error');\n}\n\nconst scrapedData = response.data.data;\nconst timestamp = new Date().toISOString();\n\nconst formattedData = scrapedData.map(item => ({\n  symbol: item.symbol_name,\n  technical_rating: item.technical_rating,\n  timestamp: timestamp\n}));\n\nreturn formattedData.map(item => ({ json: item }));"
      },
      "name": "Parse and Format Data",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [650, 300]
    },
    {
      "parameters": {
        "operation": "read",
        "documentId": {
          "__rl": true,
          "value": "YOUR_SHEET_ID_HERE",
          "mode": "id"
        },
        "sheetName": {
          "__rl": true,
          "value": "Latest",
          "mode": "list"
        },
        "range": "A:C",
        "options": {}
      },
      "name": "Read Latest Sheet",
      "type": "n8n-nodes-base.googleSheets",
      "typeVersion": 4,
      "position": [850, 300],
      "credentials": {
        "googleSheetsOAuth2Api": {
          "id": "2",
          "name": "Google_Sheets_TV_Screener"
        }
      }
    },
    {
      "parameters": {
        "jsCode": "const newData = $('Parse and Format Data').all();\nconst previousDataRaw = $('Read Latest Sheet').all();\n\nconst previousDataMap = new Map();\npreviousDataRaw.forEach(item => {\n  const symbol = item.json['Symbol'];\n  const rating = item.json['Technical Rating'];\n  if (symbol && rating) {\n    previousDataMap.set(symbol, rating);\n  }\n});\n\nconst results = [];\nconst changes = [];\n\nnewData.forEach(item => {\n  const symbol = item.json.symbol;\n  const newRating = item.json.technical_rating;\n  const timestamp = item.json.timestamp;\n  \n  const previousRating = previousDataMap.get(symbol) || null;\n  const hasChanged = previousRating && previousRating !== newRating;\n  \n  const result = {\n    timestamp: timestamp,\n    symbol: symbol,\n    technical_rating: newRating,\n    changed: hasChanged ? 'Yes' : 'No',\n    previous_rating: previousRating || 'N/A'\n  };\n  \n  results.push(result);\n  \n  if (hasChanged) {\n    changes.push({\n      timestamp: timestamp,\n      symbol: symbol,\n      from_rating: previousRating,\n      to_rating: newRating,\n      notified: 'Pending'\n    });\n  }\n});\n\nreturn [{\n  json: {\n    all_results: results,\n    changes: changes,\n    has_changes: changes.length > 0,\n    total_symbols: results.length,\n    total_changes: changes.length\n  }\n}];"
      },
      "name": "Compare Data and Detect Changes",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [1050, 300]
    },
    {
      "parameters": {
        "operation": "update",
        "documentId": {
          "__rl": true,
          "value": "YOUR_SHEET_ID_HERE",
          "mode": "id"
        },
        "sheetName": {
          "__rl": true,
          "value": "Latest",
          "mode": "list"
        },
        "range": "A2:C",
        "options": {
          "valueInputMode": "USER_ENTERED"
        },
        "dataMode": "autoMapInputData",
        "data": "={{ $json.all_results.map(item => ({ 'Symbol': item.symbol, 'Technical Rating': item.technical_rating, 'Last Updated': item.timestamp })) }}"
      },
      "name": "Update Latest Sheet",
      "type": "n8n-nodes-base.googleSheets",
      "typeVersion": 4,
      "position": [1250, 200],
      "credentials": {
        "googleSheetsOAuth2Api": {
          "id": "2",
          "name": "Google_Sheets_TV_Screener"
        }
      }
    },
    {
      "parameters": {
        "operation": "append",
        "documentId": {
          "__rl": true,
          "value": "YOUR_SHEET_ID_HERE",
          "mode": "id"
        },
        "sheetName": {
          "__rl": true,
          "value": "History",
          "mode": "list"
        },
        "options": {},
        "dataMode": "autoMapInputData",
        "data": "={{ $json.all_results.map(item => ({ 'Timestamp': item.timestamp, 'Symbol': item.symbol, 'Technical Rating': item.technical_rating, 'Changed': item.changed, 'Previous Rating': item.previous_rating })) }}"
      },
      "name": "Append to History Sheet",
      "type": "n8n-nodes-base.googleSheets",
      "typeVersion": 4,
      "position": [1250, 300],
      "credentials": {
        "googleSheetsOAuth2Api": {
          "id": "2",
          "name": "Google_Sheets_TV_Screener"
        }
      }
    },
    {
      "parameters": {
        "conditions": {
          "boolean": [
            {
              "value1": "={{ $json.has_changes }}",
              "value2": true
            }
          ]
        }
      },
      "name": "Has Changes?",
      "type": "n8n-nodes-base.if",
      "typeVersion": 1,
      "position": [1250, 400]
    },
    {
      "parameters": {
        "jsCode": "const changes = $json.changes;\n\nif (!changes || changes.length === 0) {\n  return [];\n}\n\nconst title = `📊 TradingView 技術評級變化 (${changes.length})`;\n\nfunction isMoreBullish(from, to) {\n  const ratings = ['Strong Sell', 'Sell', 'Neutral', 'Buy', 'Strong Buy'];\n  return ratings.indexOf(to) > ratings.indexOf(from);\n}\n\nfunction isMoreBearish(from, to) {\n  const ratings = ['Strong Sell', 'Sell', 'Neutral', 'Buy', 'Strong Buy'];\n  return ratings.indexOf(to) < ratings.indexOf(from);\n}\n\nfunction getArrow(from, to) {\n  if (isMoreBullish(from, to)) return '📈→';\n  if (isMoreBearish(from, to)) return '📉→';\n  return '→';\n}\n\nconst messageLines = changes.map(change => {\n  const arrow = getArrow(change.from_rating, change.to_rating);\n  return `${change.symbol}: ${change.from_rating} ${arrow} ${change.to_rating}`;\n});\n\nconst message = messageLines.join('\\n');\n\nconst bullishCount = changes.filter(c => isMoreBullish(c.from_rating, c.to_rating)).length;\nconst bearishCount = changes.filter(c => isMoreBearish(c.from_rating, c.to_rating)).length;\n\nlet trend = '';\nif (bullishCount > bearishCount) {\n  trend = '📈 偏多信號增加';\n} else if (bearishCount > bullishCount) {\n  trend = '📉 偏空信號增加';\n} else {\n  trend = '⚖️ 評級分散變化';\n}\n\nconst fullMessage = `${message}\\n\\n${trend}`;\n\nreturn [{\n  json: {\n    title: title,\n    message: fullMessage,\n    changes: changes\n  }\n}];"
      },
      "name": "Format Bark Notification",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [1450, 400]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://api.day.app/push",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "device_key",
              "value": "={{ $env.BARK_KEY }}"
            },
            {
              "name": "title",
              "value": "={{ $json.title }}"
            },
            {
              "name": "body",
              "value": "={{ $json.message }}"
            },
            {
              "name": "sound",
              "value": "bell"
            },
            {
              "name": "icon",
              "value": "https://www.tradingview.com/favicon.ico"
            },
            {
              "name": "group",
              "value": "TradingView"
            },
            {
              "name": "url",
              "value": "https://www.tradingview.com/forex-screener/"
            }
          ]
        },
        "options": {}
      },
      "name": "Send Bark Push",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "position": [1650, 400]
    },
    {
      "parameters": {
        "operation": "append",
        "documentId": {
          "__rl": true,
          "value": "YOUR_SHEET_ID_HERE",
          "mode": "id"
        },
        "sheetName": {
          "__rl": true,
          "value": "Changes_Log",
          "mode": "list"
        },
        "options": {},
        "dataMode": "autoMapInputData",
        "data": "={{ $json.changes.map(item => ({ 'Timestamp': item.timestamp, 'Symbol': item.symbol, 'From Rating': item.from_rating, 'To Rating': item.to_rating, 'Notified': 'Yes' })) }}"
      },
      "name": "Append to Changes Log",
      "type": "n8n-nodes-base.googleSheets",
      "typeVersion": 4,
      "position": [1650, 500],
      "credentials": {
        "googleSheetsOAuth2Api": {
          "id": "2",
          "name": "Google_Sheets_TV_Screener"
        }
      }
    }
  ],
  "connections": {
    "Every Hour Trigger": {
      "main": [
        [
          {
            "node": "Scrape TradingView Forex Screener",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Scrape TradingView Forex Screener": {
      "main": [
        [
          {
            "node": "Parse and Format Data",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Parse and Format Data": {
      "main": [
        [
          {
            "node": "Read Latest Sheet",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Read Latest Sheet": {
      "main": [
        [
          {
            "node": "Compare Data and Detect Changes",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Compare Data and Detect Changes": {
      "main": [
        [
          {
            "node": "準備工作表數據",
            "type": "main",
            "index": 0
          },
          {
            "node": "Has Changes?",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "準備工作表數據": {
      "main": [
        [
          {
            "node": "記錄最新數據",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Has Changes?": {
      "main": [
        [
          {
            "node": "Format Bark Notification",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Format Bark Notification": {
      "main": [
        [
          {
            "node": "Send Bark Push",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "settings": {
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "all",
    "saveManualExecutions": true
  }
}
```

</details>

**使用說明**:
1. 複製上述 JSON
2. 在 N8N 介面中選擇 "Import from JSON"
3. 貼上 JSON 內容
4. 替換所有 `YOUR_SHEET_ID_HERE` 為實際的 Google Sheet ID
5. 設定環境變數 `BARK_KEY`
6. 配置 Credentials（Firecrawl_API, Google_Sheets_TV_Screener）
7. 測試執行

---

## Step 5: 測試與驗證

### 5.1 單元測試

**測試步驟**:

1. **測試 Firecrawl API 呼叫**
   - 手動執行 "Scrape TradingView Forex Screener" 節點
   - 確認回應包含 `success: true` 和 `data.data` 陣列
   - 檢查數據格式是否正確（包含 symbol_name 和 technical_rating）

2. **測試數據解析**
   - 執行 "Parse and Format Data" 節點
   - 確認輸出格式正確（symbol, technical_rating, timestamp）
   - 檢查是否有遺漏或格式錯誤的數據

3. **測試 Google Sheets 讀取**
   - 預先在 Latest sheet 中填入一些測試數據
   - 執行 "Read Latest Sheet" 節點
   - 確認能正確讀取數據

4. **測試變化檢測**
   - 準備測試數據：部分評級變化，部分保持不變
   - 執行 "Compare Data and Detect Changes" 節點
   - 確認 `changes` 陣列僅包含有變化的項目
   - 確認 `has_changes` 標記正確

5. **測試 Google Sheets 寫入**
   - 執行 "準備工作表數據" 和 "記錄最新數據" 節點
   - 檢查 Latest sheet 是否成功追加數據
   - 確認數據格式包含所有欄位（Timestamp, Symbol, Technical Rating, Changed, Previous Rating）

6. **測試通知**
   - 準備有變化的測試數據（設定 `has_changes: true`）
   - 執行通知相關節點
   - 確認 Bark 推送通知成功送達
   - 檢查通知內容格式是否清晰易讀

### 5.2 整合測試

**完整流程測試**:

1. **初次執行測試**（Latest sheet 為空）
   - 手動觸發 workflow
   - 確認能成功抓取數據
   - 確認 Latest sheet 被正確追加數據
   - 確認因為沒有歷史數據，所有 `Changed` 欄位為 "No" 或 "N/A"
   - 確認不會觸發通知

2. **無變化執行測試**
   - 再次觸發 workflow（數據未變化）
   - 確認 Latest sheet 追加新記錄（時間戳更新）
   - 確認所有 `Changed` 欄位為 "No"
   - 確認沒有觸發通知（`has_changes: false`）

3. **有變化執行測試**
   - 等待 TradingView 評級實際變化，或手動修改測試數據
   - 觸發 workflow
   - 確認檢測到變化
   - 確認收到 Bark 通知
   - 確認 Latest sheet 中變化項目的 `Changed` 欄位為 "Yes"
   - 確認通知內容準確反映變化

4. **多次執行穩定性測試**
   - 連續執行 workflow 3-5 次
   - 確認沒有數據重複或遺漏
   - 確認 Latest sheet 正常累積記錄（形成時間序列）
   - 確認通知不會重複發送（僅在有新變化時發送）

### 5.3 錯誤處理測試

**測試場景**:

1. **Firecrawl API 失敗**
   - 暫時使用錯誤的 API Key
   - 確認 workflow 能捕獲錯誤
   - 確認錯誤訊息記錄到 N8N 日誌

2. **TradingView 頁面結構變化**
   - 模擬回傳空數據或格式錯誤的數據
   - 確認 Parse 節點能正確處理並報錯

3. **Google Sheets 權限問題**
   - 暫時移除 Sheet 的編輯權限
   - 確認 workflow 能捕獲錯誤
   - 恢復權限後能正常運作

4. **Bark 推送失敗**
   - 使用錯誤的 Device Key
   - 確認 workflow 能繼續執行其他步驟
   - 錯誤被記錄但不影響數據儲存

---

## Step 6: 部署與排程

### 6.1 環境變數設定

**N8N 環境變數**:

如果使用 Docker 部署：
```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e BARK_KEY=yourkey \
  -e TIMEZONE=Asia/Hong_Kong \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

如果使用 npm 安裝，在 `~/.n8n/.env` 中設定：
```env
BARK_KEY=yourkey
TIMEZONE=Asia/Hong_Kong
```

### 6.2 執行排程配置

**建議排程**:

考慮到 Firecrawl API 免費方案限制（每月 500 次請求），建議調整執行頻率：

| 執行頻率 | 每月請求次數 | 說明 |
|---------|-------------|------|
| 每小時 | ~720 | 超出免費額度，需付費方案 |
| 每 2 小時 | ~360 | 符合免費額度 ✅ |
| 每 4 小時 | ~180 | 節省配額 ✅ |
| 僅交易時段（24x5） | ~120 | 最節省 ✅ |

**推薦配置：每 2 小時（交易時段）**

Cron Expression: `0 */2 * * 1-5`
- 每週一至週五（1-5）
- 每 2 小時執行一次（*/2）
- 在整點執行（0）

**進階配置（僅關鍵時段）**:

```
# 每天 08:00, 12:00, 16:00, 20:00 執行（香港時間）
0 0,4,8,12 * * 1-5
```

**Cron 轉換為 UTC**:
- 香港時間 = UTC+8
- 香港 08:00 = UTC 00:00
- 香港 12:00 = UTC 04:00
- 香港 16:00 = UTC 08:00
- 香港 20:00 = UTC 12:00

**N8N Schedule Trigger 配置（交易時段，每 2 小時）**:
```json
{
  "rule": {
    "interval": [
      {
        "field": "cronExpression",
        "cronExpression": "0 */2 * * 1-5"
      }
    ]
  }
}
```

### 6.3 監控與維護

**日常監控**:

1. **檢查 N8N Workflow 執行狀態**
   - 每日查看 N8N 介面中 Execution 列表
   - 確認沒有失敗執行
   - 檢查執行時間是否正常

2. **定期檢查 Google Sheets**
   - 每週查看 Latest sheet，確認數據追加正常
   - 定期清理舊數據（如保留最近 3 個月的記錄）
   - 可使用 Google Sheets 的篩選功能查看特定貨幣對的歷史記錄

3. **監控 API 用量**
   - 追蹤 Firecrawl API 月使用量
   - 如接近配額，調整執行頻率
   - 考慮升級付費方案

**維護任務**:

1. **每月任務**
   - 清理 Latest sheet 舊數據（保留最近 3 個月）
   - 檢查 Firecrawl API 用量
   - 使用 Google Sheets 篩選功能分析評級變化趨勢（篩選 `Changed` = "Yes"）

2. **每季任務**
   - 檢查 TradingView Screener 頁面是否有結構變化
   - 測試 Firecrawl schema 是否仍能正確解析數據
   - 更新 N8N 版本（如有新版本）

3. **例外處理**
   - 如果連續多次執行失敗，檢查 TradingView 頁面是否有變化
   - 如果 Bark 通知異常，檢查 Device Key 是否過期
   - 如果數據異常，手動驗證 Firecrawl 回傳內容

---

## Step 7: 進階功能與擴展

### 7.1 數據分析與視覺化

**Google Sheets 圖表建議**:

1. **評級分布圓餅圖**
   - 顯示最新時間點所有貨幣對的評級分布
   - 數據來源：Latest sheet（篩選最新的 Timestamp）

2. **評級變化趨勢圖**
   - 顯示特定貨幣對評級隨時間的變化
   - 數據來源：Latest sheet
   - 使用 FILTER 或 QUERY 函數篩選特定貨幣對
   - 建議追蹤：EURUSD, GBPUSD, USDJPY 等主要貨幣對

3. **變化頻率統計**
   - 統計每個貨幣對評級變化的頻率
   - 數據來源：Latest sheet（篩選 `Changed` = "Yes"）
   - 使用 COUNTIF 函數計算每個貨幣對的變化次數
   - 用於識別波動性較高的貨幣對

**Google Data Studio 整合**（選用）:
- 連接 Google Sheets 數據源
- 建立儀表板展示即時評級狀態
- 設定自動更新（每小時）

### 7.2 智能過濾與自訂通知

**擴展 Workflow：選擇性通知**

在 "Compare Data and Detect Changes" 節點後添加過濾邏輯：

```javascript
// 僅通知關注的貨幣對
const watchlist = ['EURUSD', 'GBPUSD', 'USDJPY', 'GBPJPY'];

const filteredChanges = changes.filter(change => 
  watchlist.includes(change.symbol)
);

// 僅通知重大變化（跨越 Neutral）
const significantChanges = changes.filter(change => {
  const from = change.from_rating;
  const to = change.to_rating;
  
  // 從看空轉看多，或從看多轉看空
  const bullish = ['Buy', 'Strong Buy'];
  const bearish = ['Sell', 'Strong Sell'];
  
  const wasBearish = bearish.includes(from);
  const nowBullish = bullish.includes(to);
  const wasBullish = bullish.includes(from);
  const nowBearish = bearish.includes(to);
  
  return (wasBearish && nowBullish) || (wasBullish && nowBearish);
});
```

**多級通知策略**:
- 所有變化：記錄到 Changes_Log
- 關注清單變化：發送一般通知
- 重大變化：發送緊急通知（不同的 Bark 音效，如 `alarm`）

### 7.3 多來源數據整合

**整合其他 Screener 數據**:

可複製此 workflow 並調整為抓取其他來源：
- TradingView Crypto Screener
- Investing.com Forex Screener
- ForexFactory Calendar

**數據比對分析**:
- 比對多個來源的技術評級
- 當多個來源同時給出相同信號時，提高通知優先級
- 識別數據源之間的差異

### 7.4 歷史回測與信號分析

**利用 Latest 數據進行回測**:

1. **下載 Latest sheet 數據**（從 Google Sheets 導出為 CSV）
2. **分析評級變化與實際價格走勢的相關性**
3. **計算信號準確率**
   - 篩選 `Changed` = "Yes" 的記錄
   - 比對 Strong Buy → 實際上漲的比例
   - 比對 Strong Sell → 實際下跌的比例
4. **調整信號過濾邏輯**（基於回測結果）

**Python 分析腳本範例**（選用）:
```python
import pandas as pd
from datetime import datetime, timedelta

# 讀取 Google Sheet 數據
df = pd.read_csv('latest_export.csv')

# 篩選有變化的記錄
changes_df = df[df['Changed'] == 'Yes']

# 分析評級變化效果
def analyze_signal_accuracy(df, symbol, days_forward=7):
    """
    分析某個貨幣對評級變化後 N 天的價格走勢
    """
    symbol_df = df[df['Symbol'] == symbol]
    # 實現邏輯...
    pass

# 執行分析
symbols = ['EURUSD', 'GBPUSD', 'USDJPY']
for symbol in symbols:
    accuracy = analyze_signal_accuracy(changes_df, symbol)
    print(f'{symbol} Signal Accuracy: {accuracy:.2%}')
```

### 7.5 Webhook 觸發與 API 端點

**添加 Webhook 觸發器**:

在 workflow 開頭添加 Webhook Trigger 節點，允許外部系統觸發執行：

```
Webhook URL: https://your-n8n-instance.com/webhook/tv-screener-trigger
Method: GET or POST
Authentication: Header Auth (設定 secret key)
```

**使用場景**:
- 從其他系統觸發即時抓取
- 整合到交易系統中，根據評級變化自動調整策略
- 通過 Siri Shortcuts 或自動化工具手動觸發

**Webhook 安全性**:
- 設定 Authentication Header
- 限制 IP 白名單（如果 N8N 支援）
- 使用 HTTPS

---

## Step 8: 成本分析與優化

### 8.1 成本估算

**免費方案**:

| 服務 | 免費額度 | 當前用量 | 狀態 |
|------|---------|---------|------|
| Firecrawl | 500 請求/月 | ~360 請求/月（每2小時） | ✅ 符合 |
| Google Sheets | 無限（一般使用） | ~360 次寫入/月 | ✅ 免費 |
| Bark | 完全免費 | 不限 | ✅ 免費 |
| N8N（自架） | 完全免費 | 不限 | ✅ 免費 |

**總成本：$0/月**（使用免費方案）

**付費方案考量**:

如果需要更高頻率執行（如每小時），需考慮升級：

| 服務 | 付費方案 | 成本 | 優勢 |
|------|---------|------|------|
| Firecrawl | Starter: 10,000 請求/月 | $49/月 | 支援每小時執行 |
| N8N Cloud | Starter: 無限 workflows | $20/月 | 無需自架，穩定性高 |

### 8.2 優化策略

**減少 API 用量**:

1. **使用 Firecrawl Cache**
   - 設定 `maxAge: 172800000`（48小時）
   - 如果頁面未變化，使用快取回應
   - 減少實際請求次數

2. **智能執行判斷**
   - 僅在交易時段執行
   - 跳過週末和假期
   - 根據市場波動性動態調整頻率

3. **批次處理**
   - 一次抓取，多次使用
   - 暫存數據到 N8N 內部儲存
   - 減少重複請求

**提高 Workflow 效率**:

1. **並行執行**
   - 將 Google Sheets 寫入操作並行化
   - Update Latest, Append History, 和 Check Changes 可同時進行

2. **條件執行**
   - 僅在有變化時執行通知和 Changes_Log 寫入
   - 減少不必要的節點執行

3. **錯誤重試**
   - 為關鍵節點設定 Retry 邏輯
   - 減少因暫時性錯誤導致的失敗

---

## Step 9: 故障排除與常見問題

### 9.1 Firecrawl API 問題

**問題 1: API 回傳 `success: false`**

**可能原因**:
- API Key 錯誤或過期
- TradingView 頁面結構變化
- Firecrawl 服務異常

**解決方法**:
1. 檢查 API Key 是否正確
2. 手動訪問 TradingView Forex Screener，確認頁面正常
3. 查看 Firecrawl 回傳的 error 訊息
4. 調整 JSON schema 以匹配新的頁面結構

**問題 2: Schema 無法解析數據**

**可能原因**:
- TradingView 頁面 DOM 結構變化
- 數據為動態載入（JavaScript 渲染）

**解決方法**:
1. 測試 Firecrawl 的 `waitFor` 選項，等待頁面完全載入
2. 調整 `onlyMainContent` 為 `true`，簡化解析
3. 修改 JSON schema 以匹配新結構
4. 考慮使用 Firecrawl 的 `extract` 功能而非 `schema`

### 9.2 Google Sheets 問題

**問題 1: 無法寫入數據**

**可能原因**:
- Service Account 沒有編輯權限
- Sheet 名稱或 ID 錯誤
- 數據格式不符

**解決方法**:
1. 確認 Sheet 已分享給 Service Account Email
2. 檢查 Sheet 名稱拼寫（區分大小寫）
3. 驗證 Sheet ID 正確
4. 測試 Credential 連接

**問題 2: 數據重複或遺漏**

**可能原因**:
- Workflow 被多次觸發
- 比對邏輯錯誤
- Sheet 結構被手動修改

**解決方法**:
1. 檢查 Trigger 設定，避免重複觸發
2. 在 Compare 節點添加 log，驗證比對邏輯
3. 恢復 Sheet 標題行到標準格式
4. 清空測試數據，重新執行一次乾淨的 workflow

### 9.3 Bark 通知問題

**問題 1: 未收到通知**

**可能原因**:
- Device Key 錯誤
- Bark App 未在背景執行
- 網絡問題

**解決方法**:
1. 驗證 Device Key: 手動訪問 `https://api.day.app/yourkey/測試/內容`
2. 確認 iPhone 的 Bark App 正在執行
3. 檢查 N8N 的 HTTP Request 節點回應狀態
4. 測試使用 GET 請求而非 POST

**問題 2: 通知內容顯示異常**

**可能原因**:
- URL 編碼問題
- 特殊字符未正確處理
- Message 過長

**解決方法**:
1. 在 HTTP Request 節點啟用 "URL Encode"
2. 移除或轉義特殊字符（如 emoji, newline）
3. 限制 message 長度（Bark 支援最多 ~1000 字符）
4. 使用 POST 方法，將內容放在 Body 中

### 9.4 N8N Workflow 問題

**問題 1: Workflow 執行失敗**

**可能原因**:
- 節點配置錯誤
- 數據傳遞格式不符
- Credential 過期

**解決方法**:
1. 查看 Execution 詳細日誌
2. 逐個節點手動執行，定位問題節點
3. 檢查節點之間的數據流
4. 更新或重新授權 Credentials

**問題 2: 執行時間過長**

**可能原因**:
- Firecrawl 抓取時間長
- Google Sheets 寫入慢
- 數據量過大

**解決方法**:
1. 調整 Firecrawl 的 `maxAge`，使用快取
2. 減少 History sheet 的記錄數量（定期清理）
3. 優化 Code 節點邏輯
4. 考慮分拆為多個 sub-workflow

---

## Step 10: 文檔與知識管理

### 10.1 操作手冊

**日常操作清單**:

- [ ] 每日檢查 Bark 通知，注意評級變化
- [ ] 每週查看 Google Sheets Latest sheet（可使用篩選查看最新記錄）
- [ ] 每月檢查 Firecrawl API 用量
- [ ] 每月清理 Latest sheet 舊數據（保留最近 3 個月）
- [ ] 每季測試 Workflow 完整性

**緊急情況處理**:

| 情況 | 處理步驟 |
|------|---------|
| Workflow 連續失敗 | 1. 查看 Execution 日誌<br>2. 手動測試 Firecrawl API<br>3. 檢查 TradingView 頁面<br>4. 聯絡 Firecrawl 支援 |
| 收不到通知 | 1. 測試 Bark Device Key<br>2. 檢查 N8N 環境變數<br>3. 手動執行通知節點 |
| 數據異常 | 1. 比對 TradingView 網站實際數據<br>2. 檢查 Parse 節點邏輯<br>3. 查看 Firecrawl 回傳原始數據 |

### 10.2 變更記錄

**Workflow 版本管理**:

建議使用 N8N 的 Workflow 版本控制功能，或手動記錄變更：

| 日期 | 版本 | 變更內容 | 原因 |
|------|------|---------|------|
| 2025-10-24 | v1.0 | 初始版本 | 新建 workflow |
| TBD | v1.1 | 調整執行頻率為每 2 小時 | 避免超出 API 配額 |
| TBD | v1.2 | 添加選擇性通知過濾 | 減少非關鍵通知 |

**TradingView 頁面變更追蹤**:

如果 TradingView 頁面結構變化，需更新 Firecrawl schema：

```json
// 當前 schema (v1.0)
{
  "type": "object",
  "properties": {
    "data": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "symbol_name": {"type": "string"},
          "technical_rating": {"type": "string"}
        }
      }
    }
  }
}

// 如有變更，記錄新 schema 於此
```

---

## 附錄 Appendix

### A. API 文檔參考

**Firecrawl API**:
- 官方文檔: https://docs.firecrawl.dev/
- Schema 指南: https://docs.firecrawl.dev/features/extract
- Rate Limits: https://docs.firecrawl.dev/rate-limits

**Google Sheets API**:
- 官方文檔: https://developers.google.com/sheets/api
- N8N 整合: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.googlesheets/

**Bark Push API**:
- GitHub: https://github.com/Finb/Bark
- API 說明: https://bark.day.app/#/tutorial

### B. N8N 節點類型速查

| 節點類型 | 用途 | 常用配置 |
|---------|------|---------|
| Schedule Trigger | 定時執行 | Cron Expression |
| HTTP Request | API 呼叫 | Method, URL, Headers, Body |
| Code | 自訂邏輯 | JavaScript Code |
| Google Sheets | Sheet 操作 | Read, Update, Append |
| IF | 條件分支 | Boolean Conditions |
| Set | 設定變數 | Data Transformation |

### C. 常用 JavaScript 程式碼片段

**1. 取得當前香港時間**:
```javascript
const now = new Date();
const hkTime = new Date(now.toLocaleString('en-US', {timeZone: 'Asia/Hong_Kong'}));
const timestamp = hkTime.toISOString();
```

**2. 格式化評級變化訊息**:
```javascript
const formatChange = (symbol, from, to) => {
  const emoji = to.includes('Buy') ? '📈' : to.includes('Sell') ? '📉' : '➡️';
  return `${emoji} ${symbol}: ${from} → ${to}`;
};
```

**3. 比對兩組數據**:
```javascript
const compareData = (newData, oldData) => {
  const changes = [];
  newData.forEach(newItem => {
    const oldItem = oldData.find(o => o.symbol === newItem.symbol);
    if (oldItem && oldItem.rating !== newItem.rating) {
      changes.push({
        symbol: newItem.symbol,
        from: oldItem.rating,
        to: newItem.rating
      });
    }
  });
  return changes;
};
```

### D. Cron Expression 參考

| 表達式 | 說明 | 執行頻率 |
|--------|------|---------|
| `0 * * * *` | 每小時整點 | 每月 ~720 次 |
| `0 */2 * * *` | 每 2 小時 | 每月 ~360 次 |
| `0 */4 * * *` | 每 4 小時 | 每月 ~180 次 |
| `0 */2 * * 1-5` | 每 2 小時（週一至週五） | 每月 ~240 次 |
| `0 0,4,8,12,16,20 * * 1-5` | 指定時段（週一至週五） | 每月 ~120 次 |

**Cron 格式說明**:
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (0 = Sunday)
│ │ │ │ │
│ │ │ │ │
* * * * *
```

### E. 疑難排解檢查清單

**Workflow 無法執行**:
- [ ] N8N 服務是否正常運行？
- [ ] Trigger 是否已啟用？
- [ ] Credentials 是否已配置且有效？
- [ ] 環境變數是否已設定？

**數據抓取失敗**:
- [ ] Firecrawl API Key 是否正確？
- [ ] TradingView 網站是否可正常訪問？
- [ ] API 配額是否已用完？
- [ ] JSON Schema 是否與頁面結構匹配？

**數據儲存失敗**:
- [ ] Google Sheet 是否已分享給 Service Account？
- [ ] Sheet 名稱是否正確？
- [ ] 數據格式是否符合 Sheet 結構？
- [ ] Credential 是否有寫入權限？

**通知未送達**:
- [ ] Bark Device Key 是否正確？
- [ ] 環境變數 BARK_KEY 是否已設定？
- [ ] iPhone 的 Bark App 是否在背景執行？
- [ ] 通知內容是否有格式錯誤？

---

## 總結 Summary

本設計計劃書詳細說明了如何使用 N8N 建立一個自動化系統，解決 TradingView Forex Screener 免費用戶無法導出數據的問題。

**核心優勢**:
1. ✅ **完全自動化**: 無需手動操作，定時自動抓取和分析
2. ✅ **零成本運行**: 使用免費服務，每月成本 $0
3. ✅ **即時通知**: 評級變化時立即推送到手機
4. ✅ **數據永久保存**: Google Sheets 保留完整歷史記錄（橫向格式）
5. ✅ **易於擴展**: 可輕鬆調整為監控其他市場或指標
6. ✅ **簡化架構**: 單一工作表設計，維護更輕鬆
7. 🎯 **個性化訂閱**: 每個用戶只接收他們關心的貨幣對變化
8. 🎯 **多裝置支持**: 輕鬆添加新朋友，共享有價值的信號

**技術亮點**:
- 使用 Firecrawl AI-powered web scraping 技術
- 智能比對邏輯，精準識別評級變化
- **橫向數據格式**: 直觀高效的時間序列存儲
- **訂閱過濾系統**: 根據用戶興趣智能過濾通知
- **簡潔通知格式**: `📊 Forex Screener • X changed`
- 優雅的 Bark 推送，支援多裝置自動循環發送

**後續改進方向**:
- 整合多個 Screener 來源交叉驗證
- 添加歷史回測和信號分析
- 建立 Data Studio 儀表板
- 擴展至 Crypto 和 Stock Screeners
- 添加更多智能過濾規則（如重大變化、連續變化等）
- 支持自定義通知頻率和時段

本系統為投資者提供了一個強大且靈活的市場監控工具，幫助及時捕捉技術評級的重要變化。通過個性化訂閱功能，每個用戶都能專注於自己關心的市場，減少信息噪音，提高決策效率。

---

**文件版本**: v2.0  
**建立日期**: 2025-10-24  
**最後更新**: 2025-10-27  
**作者**: Wing Chan  
**專案狀態**: 生產運行

**版本更新歷史**:
- v1.0 (2025-10-24): 初始版本，基礎工作流設計
- v2.0 (2025-10-27): 
  - 🎯 添加個性化訂閱功能（每個用戶可選擇特定貨幣對）
  - 📊 更改通知標題為 "Forex Screener"
  - 🔄 採用橫向數據格式，簡化數據結構
  - ✨ 支持多裝置推送，輕鬆添加新用戶
  - 🗑️ 移除趨勢摘要，專注於具體變化


