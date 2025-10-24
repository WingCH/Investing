# JT_EA N8N 自動化工作流程設計計劃書

本文件將 JT_EA AI Agents 策略轉換為 N8N 自動化工作流程實現方案。

---

## 專案概覽 Project Overview

**專案名稱**: JT_EA Daily Bias Monitor 自動化系統  
**目標**: 建立全自動的每日交易方向監控系統，自動收集市場數據、分析情境、生成決策建議並發送通知  
**平台**: N8N Workflow Automation  
**執行週期**: 每日一次（香港時間凌晨 12:00-1:00）

**監控標的**:
- EURNZD（歐元/紐西蘭元）— 當前方向：買入
- GBPSGD（英鎊/新加坡元）— 當前方向：買入
- NZDUSD（紐西蘭元/美元）— 當前方向：買入
- USDCHF（美元/瑞士法郎）— 當前方向：買入
- ETHUSD（以太坊/美元）— 當前方向：買入

---

## 工作流程架構 Workflow Architecture

### 主要工作流程 Main Workflows

1. **Daily Monitor Workflow** (主工作流程)
   - 定時觸發
   - 數據收集
   - 分析處理
   - 報告生成
   - 通知發送

2. **Emergency Alert Workflow** (緊急警報工作流程)
   - 實時監控
   - 異常檢測
   - 即時通知

---

## Step 1: 環境準備與設定 Environment Setup

### 1.1 N8N 安裝與配置

**必要條件**:
- N8N 平台（自架或雲端版本）
- Node.js 18+ 環境
- 儲存空間供報告輸出

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

### 1.2 API Keys 取得

需要取得以下 API Keys：

1. **Polygon.io API Key**
   - 前往 https://polygon.io/ 註冊
   - 取得 API Key（**目前使用免費帳號**）
   - 用途：Forex 和 Crypto 市場數據
   - **免費帳號限制**：
     * 延遲數據（15 分鐘延遲）
     * API 請求限制：每分鐘 5 次請求
     * 無法使用 WebSocket 即時數據
     * 無法使用付費技術指標 API（需自行計算）
     * 可用端點：Aggregates, Previous Close, Ticker Details, Reference Data

2. **財經新聞 API** (選擇一個)
   - NewsAPI (https://newsapi.org/) - 免費方案：每月 100 次請求
   - Alpha Vantage (https://www.alphavantage.co/) - 免費方案：每分鐘 5 次請求
   - Finnhub (https://finnhub.io/) - 免費方案：每分鐘 60 次請求（推薦）

3. **通知服務**
   - Bark App（iOS 推送通知，完全免費，推薦）
     * App Store 下載 Bark
     * 取得 Device Key
     * 無需額外 API 申請

### 1.3 N8N Credentials 設定

在 N8N 中設定以下 Credentials：
- `Polygon.io API` (HTTP Request Header Auth)
- `NewsAPI` 或 `Finnhub API` (API Key)
- `Bark Device Key` (儲存為 Generic Credential 或環境變數)

---

## Step 2: 主工作流程設計 Main Workflow Design

### Workflow 名稱: `JT_EA_Daily_Monitor`

### 節點架構 Node Structure

```
[Schedule Trigger] 
    ↓
[Initialize Variables] 
    ↓
[Loop Symbols] ───┐
    ↓             │
[Get Market Data] │
    ↓             │
[Get News Data]   │
    ↓             │
[Calculate ATR]   │
    ↓             │
[Analyze Context] │
    ↓             │
[Generate Recommendation] 
    ↓             │
←───────────────┘
    ↓
[Aggregate Results]
    ↓
[Generate Report]
    ↓
[Save to File]
    ↓
[Send Bark Notification]
```

---

## Step 3: 節點詳細配置 Detailed Node Configuration

### 3.1 Schedule Trigger Node

**節點類型**: `Schedule Trigger` (nodes-base.scheduleTrigger)

**配置**:
```json
{
  "mode": "everyDay",
  "hour": 0,
  "minute": 30,
  "timezone": "Asia/Hong_Kong"
}
```

**說明**: 每日香港時間 00:30 觸發（倫敦收市後）

---

### 3.2 Initialize Variables Node

**節點類型**: `Code` (nodes-base.code)

**用途**: 初始化交易標的清單和配置

**JavaScript 代碼**:
```javascript
// 定義監控標的
const symbols = [
  {
    ticker: "C:EURNZD",
    name: "EURNZD",
    currentBias: "Buy",
    market: "forex"
  },
  {
    ticker: "C:GBPSGD",
    name: "GBPSGD",
    currentBias: "Buy",
    market: "forex"
  },
  {
    ticker: "C:NZDUSD",
    name: "NZDUSD",
    currentBias: "Buy",
    market: "forex"
  },
  {
    ticker: "C:USDCHF",
    name: "USDCHF",
    currentBias: "Buy",
    market: "forex"
  },
  {
    ticker: "X:ETHUSD",
    name: "ETHUSD",
    currentBias: "Buy",
    market: "crypto"
  }
];

// 配置參數
const config = {
  polygonApiKey: $credentials.polygonApi.key,
  lookbackDays: 30,
  atrPeriod: 14,
  alertThreshold: 2.0, // ATR 倍數
  reportPath: "/Users/wingchan/Project/Investing/JT_EA/daily_reports/",
  today: new Date().toISOString().split('T')[0]
};

return symbols.map(symbol => ({
  json: { symbol, config }
}));
```

---

### 3.3 Loop Symbols Node

**節點類型**: `Loop Over Items` (nodes-base.splitInBatches)

**配置**:
```json
{
  "batchSize": 1,
  "options": {}
}
```

**說明**: 逐個處理每個交易標的

---

### 3.4 Get Market Data Node

**節點類型**: `HTTP Request` (nodes-base.httpRequest)

**用途**: 從 Polygon.io 取得市場數據（**免費帳號：延遲 15 分鐘**）

**API 端點**: `/v2/aggs/ticker/{ticker}/range/{multiplier}/{timespan}/{from}/{to}`

**配置**:
```json
{
  "method": "GET",
  "url": "=https://api.polygon.io/v2/aggs/ticker/{{ $json.symbol.ticker }}/range/1/day/{{ $now.minus({days: 30}).toISODate() }}/{{ $now.toISODate() }}",
  "authentication": "genericCredentialType",
  "genericAuthType": "queryAuth",
  "sendQuery": true,
  "queryParameters": {
    "parameters": [
      {
        "name": "apiKey",
        "value": "={{ $json.config.polygonApiKey }}"
      },
      {
        "name": "adjusted",
        "value": "true"
      },
      {
        "name": "sort",
        "value": "desc"
      },
      {
        "name": "limit",
        "value": "50"
      }
    ]
  },
  "options": {
    "response": {
      "response": {
        "responseFormat": "json"
      }
    },
    "timeout": 10000,
    "retry": {
      "maxTries": 3,
      "waitBetweenTries": 2000
    }
  }
}
```

**API Response 範例**:
```json
{
  "results": [
    {
      "v": 100000,
      "vw": 1.0234,
      "o": 1.0230,
      "c": 1.0240,
      "h": 1.0245,
      "l": 1.0225,
      "t": 1611082800000,
      "n": 1234
    }
  ],
  "status": "OK",
  "resultsCount": 30,
  "adjusted": true
}
```

**輸出**: OHLCV 日線數據（最近 30 天）
- `v`: 成交量 (Volume)
- `vw`: 加權平均價 (Volume Weighted Average Price)
- `o`: 開盤價 (Open)
- `c`: 收盤價 (Close)
- `h`: 最高價 (High)
- `l`: 最低價 (Low)
- `t`: 時間戳記 (Timestamp in milliseconds)
- `n`: 交易筆數 (Number of transactions)

---

### 3.5 Get Previous Close Node

**節點類型**: `HTTP Request` (nodes-base.httpRequest)

**用途**: 取得前一日收盤價

**API 端點**: `/v2/aggs/ticker/{ticker}/prev`

**配置**:
```json
{
  "method": "GET",
  "url": "=https://api.polygon.io/v2/aggs/ticker/{{ $json.symbol.ticker }}/prev",
  "authentication": "genericCredentialType",
  "genericAuthType": "queryAuth",
  "sendQuery": true,
  "queryParameters": {
    "parameters": [
      {
        "name": "apiKey",
        "value": "={{ $json.config.polygonApiKey }}"
      },
      {
        "name": "adjusted",
        "value": "true"
      }
    ]
  },
  "options": {
    "response": {
      "response": {
        "responseFormat": "json"
      }
    },
    "timeout": 10000
  }
}
```

**API Response 範例**:
```json
{
  "results": [
    {
      "T": "C:NZDUSD",
      "v": 150000,
      "vw": 0.6234,
      "o": 0.6230,
      "c": 0.6240,
      "h": 0.6245,
      "l": 0.6225,
      "t": 1611014400000,
      "n": 2345
    }
  ],
  "status": "OK",
  "adjusted": true
}
```

---

### 3.6 Calculate ATR Node

**節點類型**: `Code` (nodes-base.code)

**用途**: 計算 Average True Range (ATR) 技術指標

**重要說明**: ⚠️ **免費帳號無法使用 Polygon.io 的技術指標 API，必須自行計算 ATR**

**ATR 計算公式**:
```
True Range (TR) = max(High - Low, |High - PrevClose|, |Low - PrevClose|)
ATR = Simple Moving Average of TR over N periods (通常 N=14)
```

**JavaScript 代碼**:
```javascript
const marketData = $input.first().json.results;
const symbol = $input.first().json.symbol;
const config = $input.first().json.config;

// 計算 True Range
function calculateTR(current, previous) {
  const high = current.h;
  const low = current.l;
  const prevClose = previous ? previous.c : current.o;
  
  return Math.max(
    high - low,
    Math.abs(high - prevClose),
    Math.abs(low - prevClose)
  );
}

// 計算 ATR
const period = config.atrPeriod;
let trValues = [];

for (let i = 0; i < marketData.length - 1; i++) {
  const tr = calculateTR(marketData[i], marketData[i + 1]);
  trValues.push(tr);
}

const atr = trValues.slice(0, period).reduce((a, b) => a + b, 0) / period;

// 計算當前價格變動
const latestClose = marketData[0].c;
const previousClose = marketData[1].c;
const priceChange = latestClose - previousClose;
const priceChangePercent = (priceChange / previousClose) * 100;

// 計算波動性評估
const volatilityRatio = Math.abs(priceChange) / atr;

return [{
  json: {
    symbol: symbol,
    config: config,
    marketData: {
      latestClose: latestClose,
      previousClose: previousClose,
      priceChange: priceChange,
      priceChangePercent: priceChangePercent.toFixed(2),
      atr: atr.toFixed(5),
      volatilityRatio: volatilityRatio.toFixed(2),
      highAlert: volatilityRatio > config.alertThreshold
    },
    rawData: marketData.slice(0, 5) // 保留最近 5 天數據
  }
}];
```

---

### 3.7 Get News Data Node

**節點類型**: `HTTP Request` (nodes-base.httpRequest)

**用途**: 取得相關財經新聞（過去 24 小時）

**推薦使用**: Finnhub API（免費額度：每分鐘 60 次請求）

**API 端點**: `/v1/company-news`

**配置** (使用 Finnhub):
```json
{
  "method": "GET",
  "url": "https://finnhub.io/api/v1/company-news",
  "authentication": "genericCredentialType",
  "genericAuthType": "queryAuth",
  "sendQuery": true,
  "queryParameters": {
    "parameters": [
      {
        "name": "token",
        "value": "={{ $credentials.finnhub.apiKey }}"
      },
      {
        "name": "symbol",
        "value": "={{ $json.symbol.name }}"
      },
      {
        "name": "from",
        "value": "={{ $now.minus({days: 1}).toISODate() }}"
      },
      {
        "name": "to",
        "value": "={{ $now.toISODate() }}"
      }
    ]
  },
  "options": {
    "response": {
      "response": {
        "responseFormat": "json"
      }
    },
    "timeout": 10000
  }
}
```

**替代方案 - Polygon.io News API** (免費帳號也可用):
```json
{
  "method": "GET",
  "url": "https://api.polygon.io/v2/reference/news",
  "authentication": "genericCredentialType",
  "genericAuthType": "queryAuth",
  "sendQuery": true,
  "queryParameters": {
    "parameters": [
      {
        "name": "apiKey",
        "value": "={{ $json.config.polygonApiKey }}"
      },
      {
        "name": "ticker",
        "value": "={{ $json.symbol.name }}"
      },
      {
        "name": "order",
        "value": "desc"
      },
      {
        "name": "limit",
        "value": "10"
      },
      {
        "name": "sort",
        "value": "published_utc"
      }
    ]
  }
}
```

**備註**: 
- 對於 Forex pairs (如 EURNZD)，可搜尋個別貨幣 (EUR, NZD)
- 對於 ETHUSD，使用 "ETH" 或 "Ethereum" 作為關鍵字
- Polygon News API 免費帳號可用，無需額外申請

---

### 3.8 Analyze Context Node

**節點類型**: `Code` (nodes-base.code)

**用途**: 情境分析，識別重大風險因素

**JavaScript 代碼**:
```javascript
const symbol = $input.first().json.symbol;
const marketData = $input.first().json.marketData;
const newsArticles = $input.first().json.news?.articles || [];

// 風險因素關鍵字
const riskKeywords = {
  centralBank: ['central bank', 'fed', 'ecb', 'boe', 'rbnz', 'snb', 'interest rate', 'monetary policy'],
  geopolitical: ['war', 'conflict', 'sanction', 'trade war', 'tension', 'crisis'],
  economic: ['inflation', 'gdp', 'recession', 'unemployment', 'cpi', 'ppi'],
  technical: ['breakout', 'support', 'resistance', 'trend', 'reversal']
};

// 分析新聞情緒
function analyzeNews(articles) {
  let riskFactors = [];
  let sentimentScore = 0;
  
  articles.forEach(article => {
    const content = (article.title + ' ' + article.description).toLowerCase();
    
    // 檢測風險關鍵字
    Object.keys(riskKeywords).forEach(category => {
      riskKeywords[category].forEach(keyword => {
        if (content.includes(keyword)) {
          riskFactors.push({
            category: category,
            keyword: keyword,
            source: article.source.name,
            title: article.title,
            url: article.url
          });
        }
      });
    });
    
    // 簡單情緒評分（負面關鍵字）
    const negativeWords = ['fall', 'drop', 'decline', 'weak', 'concern', 'risk', 'threat'];
    negativeWords.forEach(word => {
      if (content.includes(word)) sentimentScore -= 1;
    });
    
    const positiveWords = ['rise', 'gain', 'strong', 'optimistic', 'growth'];
    positiveWords.forEach(word => {
      if (content.includes(word)) sentimentScore += 1;
    });
  });
  
  return { riskFactors, sentimentScore };
}

const newsAnalysis = analyzeNews(newsArticles);

// 計算風險等級
let riskLevel = 'LOW';
let riskScore = 0;

// 技術面風險
if (marketData.highAlert) {
  riskScore += 3;
}

// 新聞面風險
if (newsAnalysis.riskFactors.length > 5) {
  riskScore += 2;
}

if (newsAnalysis.sentimentScore < -5) {
  riskScore += 2;
}

// 判定風險等級
if (riskScore >= 5) {
  riskLevel = 'HIGH';
} else if (riskScore >= 3) {
  riskLevel = 'MEDIUM';
}

return [{
  json: {
    symbol: symbol,
    marketData: marketData,
    newsAnalysis: newsAnalysis,
    riskAssessment: {
      riskLevel: riskLevel,
      riskScore: riskScore,
      factors: newsAnalysis.riskFactors
    }
  }
}];
```

---

### 3.9 Generate Recommendation Node

**節點類型**: `Code` (nodes-base.code)

**用途**: 根據分析結果生成決策建議

**JavaScript 代碼**:
```javascript
const symbol = $input.first().json.symbol;
const marketData = $input.first().json.marketData;
const riskAssessment = $input.first().json.riskAssessment;

let recommendation = 'HOLD';
let action = '繼續執行當前 bias';
let reasoning = [];

// 決策邏輯
if (riskAssessment.riskLevel === 'HIGH') {
  if (marketData.highAlert) {
    recommendation = 'REVERSE';
    action = '建議平倉並考慮反向部位';
    reasoning.push(`價格波動超過 ${marketData.volatilityRatio} ATR`);
  } else {
    recommendation = 'ADJUST';
    action = '建議減倉或收緊止損';
  }
  
  reasoning.push(`檢測到 ${riskAssessment.riskScore} 個高風險因素`);
  
  // 列出主要風險
  riskAssessment.factors.slice(0, 3).forEach(factor => {
    reasoning.push(`${factor.category}: ${factor.keyword}`);
  });
  
} else if (riskAssessment.riskLevel === 'MEDIUM') {
  recommendation = 'ADJUST';
  action = '建議暫停新倉，密切觀察';
  reasoning.push('市場出現中度風險訊號');
  
} else {
  recommendation = 'HOLD';
  action = '繼續執行當前 bias';
  reasoning.push('無重大風險訊號');
}

// 技術面總結
const technicalSummary = `價格: ${marketData.latestClose.toFixed(5)} (${marketData.priceChangePercent > 0 ? '+' : ''}${marketData.priceChangePercent}%)`;

return [{
  json: {
    symbol: symbol.name,
    currentBias: symbol.currentBias,
    recommendation: recommendation,
    action: action,
    riskLevel: riskAssessment.riskLevel,
    reasoning: reasoning,
    technical: {
      summary: technicalSummary,
      atr: marketData.atr,
      volatilityRatio: marketData.volatilityRatio,
      highAlert: marketData.highAlert
    },
    timestamp: new Date().toISOString()
  }
}];
```

---

### 3.10 Aggregate Results Node

**節點類型**: `Code` (nodes-base.code)

**用途**: 彙整所有標的的分析結果

**JavaScript 代碼**:
```javascript
// 收集所有標的的結果
const allResults = $input.all().map(item => item.json);

// 統計摘要
const summary = {
  totalSymbols: allResults.length,
  hold: allResults.filter(r => r.recommendation === 'HOLD').length,
  adjust: allResults.filter(r => r.recommendation === 'ADJUST').length,
  reverse: allResults.filter(r => r.recommendation === 'REVERSE').length,
  highRisk: allResults.filter(r => r.riskLevel === 'HIGH').length,
  mediumRisk: allResults.filter(r => r.riskLevel === 'MEDIUM').length,
  lowRisk: allResults.filter(r => r.riskLevel === 'LOW').length
};

// 需要立即關注的標的
const urgentSymbols = allResults
  .filter(r => r.riskLevel === 'HIGH' || r.recommendation === 'REVERSE')
  .map(r => r.symbol);

return [{
  json: {
    date: new Date().toISOString().split('T')[0],
    summary: summary,
    urgentSymbols: urgentSymbols,
    results: allResults
  }
}];
```

---

### 3.11 Generate Report Node

**節點類型**: `Code` (nodes-base.code)

**用途**: 生成 Markdown 格式的日報

**JavaScript 代碼**:
```javascript
const data = $input.first().json;
const date = data.date;
const summary = data.summary;
const results = data.results;

// 生成 Markdown 報告
let report = `# Daily Bias Review - ${date}\n\n`;

// Executive Summary
report += `## Executive Summary\n\n`;
report += `今日監控 ${summary.totalSymbols} 個交易標的，`;
report += `其中 ${summary.highRisk} 個高風險、${summary.mediumRisk} 個中風險、${summary.lowRisk} 個低風險。`;
report += `建議動作：${summary.hold} 個維持、${summary.adjust} 個調整、${summary.reverse} 個反轉。\n\n`;

if (data.urgentSymbols.length > 0) {
  report += `⚠️ **需要立即關注**: ${data.urgentSymbols.join(', ')}\n\n`;
}

report += `---\n\n`;

// Symbol Analysis
report += `## Symbol Analysis\n\n`;

results.forEach(result => {
  report += `### ${result.symbol}\n\n`;
  report += `- **當前方向**: ${result.currentBias} Bias\n`;
  report += `- **建議動作**: **${result.recommendation}** - ${result.action}\n`;
  report += `- **風險等級**: ${result.riskLevel}\n`;
  report += `- **關鍵因素**:\n`;
  
  result.reasoning.forEach(reason => {
    report += `  - ${reason}\n`;
  });
  
  report += `- **技術面**:\n`;
  report += `  - ${result.technical.summary}\n`;
  report += `  - ATR: ${result.technical.atr}\n`;
  report += `  - 波動性比率: ${result.technical.volatilityRatio}x ATR\n`;
  
  if (result.technical.highAlert) {
    report += `  - ⚠️ **高波動警報**\n`;
  }
  
  report += `\n`;
});

report += `---\n\n`;

// Action Items
report += `## Action Items\n\n`;

results.forEach(result => {
  if (result.recommendation !== 'HOLD') {
    report += `- [ ] ${result.symbol}: ${result.action}\n`;
  }
});

if (results.every(r => r.recommendation === 'HOLD')) {
  report += `- [ ] 無需特別動作，繼續監控\n`;
}

report += `\n---\n\n`;

// Risk Dashboard
report += `## Risk Dashboard\n\n`;
report += `- 高風險 symbol 數量: ${summary.highRisk}/${summary.totalSymbols}\n`;
report += `- 需要立即關注: ${data.urgentSymbols.length > 0 ? data.urgentSymbols.join(', ') : '無'}\n`;
report += `- 報告生成時間: ${new Date().toLocaleString('zh-HK', { timeZone: 'Asia/Hong_Kong' })}\n`;

return [{
  json: {
    date: date,
    filename: `${date}.md`,
    content: report,
    summary: summary,
    urgentSymbols: data.urgentSymbols
  }
}];
```

---

### 3.12 Save to File Node

**節點類型**: `Write Binary File` (nodes-base.writeBinaryFile) 或使用 HTTP Request 寫入檔案系統

**配置**:
```json
{
  "fileName": "={{ $json.filename }}",
  "dataPropertyName": "content",
  "options": {
    "encoding": "utf8"
  }
}
```

**說明**: 將報告儲存到 `JT_EA/daily_reports/YYYY-MM-DD.md`

---

### 3.13 Send Bark Notification Node

**節點類型**: `HTTP Request` (nodes-base.httpRequest)

**用途**: 使用 Bark 發送 iOS 推送通知

**Bark 簡介**: Bark 是一個開源的 iOS 推送通知應用，可透過簡單的 HTTP API 發送通知到您的 iPhone

**配置**:
```json
{
  "method": "POST",
  "url": "=https://api.day.app/{{ $credentials.bark.deviceKey }}/{{ encodeURIComponent('📊 JT_EA Daily Report') }}",
  "authentication": "none",
  "sendBody": true,
  "bodyParameters": {
    "parameters": [
      {
        "name": "body",
        "value": "={{ $json.summary.highRisk > 0 ? '⚠️ 高風險：' + $json.urgentSymbols.join(', ') : '✅ 市場正常' }}\n維持: {{ $json.summary.hold }} | 調整: {{ $json.summary.adjust }} | 反轉: {{ $json.summary.reverse }}"
      },
      {
        "name": "level",
        "value": "={{ $json.summary.highRisk > 0 ? 'timeSensitive' : 'active' }}"
      },
      {
        "name": "badge",
        "value": "={{ $json.summary.highRisk }}"
      },
      {
        "name": "sound",
        "value": "{{ $json.summary.highRisk > 0 ? 'alarm' : 'bell' }}"
      },
      {
        "name": "group",
        "value": "JT_EA"
      }
    ]
  },
  "options": {
    "response": {
      "response": {
        "responseFormat": "json"
      }
    }
  }
}
```

**替代方案 - 使用 GET 請求（更簡單）**:
```json
{
  "method": "GET",
  "url": "=https://api.day.app/{{ $credentials.bark.deviceKey }}/📊 JT_EA Daily Report/{{ $json.summary.highRisk > 0 ? '⚠️ 高風險：' + $json.urgentSymbols.join(', ') : '✅ 市場正常' }}?level={{ $json.summary.highRisk > 0 ? 'timeSensitive' : 'active' }}&group=JT_EA",
  "authentication": "none"
}
```

**Bark 設定步驟**:
1. 在 iPhone 上安裝 Bark App（App Store 免費下載）
2. 打開 App，複製您的 Device Key（格式如：`xxxxxxxxxxxxxx`）
3. 在 N8N Credentials 中儲存 Device Key
4. 測試 URL：`https://api.day.app/YOUR_DEVICE_KEY/Test/Hello`

**Bark 參數說明**:
- `level`: 通知級別
  - `active`: 正常通知（預設）
  - `timeSensitive`: 時效性通知（會突破專注模式）
  - `passive`: 被動通知
- `badge`: 應用圖標上的數字角標
- `sound`: 通知音效（alarm, bell, chime 等）
- `group`: 通知分組

---

## Step 4: 測試與部署 Testing & Deployment

### 4.1 測試階段

**測試清單**:
- [ ] Schedule Trigger 是否正確觸發
- [ ] Polygon API 連線測試
- [ ] 數據處理邏輯驗證
- [ ] ATR 計算準確性
- [ ] 報告生成格式檢查
- [ ] 檔案儲存路徑正確
- [ ] Bark 通知發送成功

**測試指令**:
```bash
# 手動觸發測試
curl -X POST http://localhost:5678/webhook-test/jt-ea-daily-monitor

# 檢查日誌
docker logs n8n

# 檢查報告輸出
ls -la ~/Project/Investing/JT_EA/daily_reports/
```

---

### 4.2 部署步驟

1. **匯出工作流程**
   - 在 N8N UI 中匯出 JSON
   - 版本控制（Git）

2. **環境變數設定**
   ```bash
   export POLYGON_API_KEY="your_key_here"
   export TELEGRAM_BOT_TOKEN="your_token_here"
   export NEWS_API_KEY="your_key_here"
   ```

3. **啟動 N8N**
   ```bash
   n8n start
   ```

4. **監控運作**
   - 檢查執行歷史
   - 查看錯誤日誌
   - 驗證報告產出

---

## Step 5: 維護與優化 Maintenance & Optimization

### 5.1 定期檢查項目

**每週檢查**:
- [ ] API 額度使用情況
- [ ] 工作流程執行成功率
- [ ] 報告品質評估

**每月檢查**:
- [ ] 決策建議準確度回顧
- [ ] 風險評估模型優化
- [ ] 新增數據源評估

---

### 5.2 優化建議

1. **效能優化**
   - 使用 N8N 的 Cache 功能減少重複 API 呼叫
   - 平行處理多個標的（使用 Split In Batches）
   - 減少不必要的數據傳輸

2. **準確度提升**
   - 整合更多財經新聞來源
   - 加入機器學習情緒分析
   - 優化風險評估算法

3. **功能擴展**
   - 加入回測功能（Backtest Analyzer）
   - 即時風險監控（Real-time Risk Monitor）
   - 自動執行交易（Auto Trading，需謹慎）

---

## Step 6: 錯誤處理與容錯 Error Handling

### 6.1 常見錯誤處理

在每個 HTTP Request 節點後加入錯誤處理：

**節點類型**: `Error Trigger` (nodes-base.errorTrigger)

**配置**:
```json
{
  "triggerOn": "error"
}
```

**錯誤通知 Node (使用 Bark)**:
```json
{
  "method": "GET",
  "url": "=https://api.day.app/{{ $credentials.bark.deviceKey }}/❌ N8N 錯誤/工作流程: {{ $workflow.name }}%0A節點: {{ $node.name }}%0A錯誤: {{ $json.error.message }}?level=timeSensitive&sound=alarm&group=N8N_Errors",
  "authentication": "none"
}
```

---

### 6.2 重試機制

在關鍵的 HTTP Request 節點中設定重試：

**配置**:
```json
{
  "options": {
    "retry": {
      "maxTries": 3,
      "waitBetweenTries": 1000
    }
  }
}
```

---

## Step 7: 文檔與知識庫 Documentation

### 7.1 建立操作手冊

在 `JT_EA/` 目錄下建立：
- `N8N_OPERATIONS_MANUAL.md` - 操作手冊
- `N8N_TROUBLESHOOTING.md` - 故障排除指南
- `API_INTEGRATION_GUIDE.md` - API 整合指南

---

### 7.2 工作流程版本控制

```bash
# 匯出工作流程
cd ~/Project/Investing/JT_EA/n8n_workflows/
n8n export:workflow --all --output=./

# 提交到 Git
git add .
git commit -m "Update N8N workflows"
git push
```

---

## 附錄 Appendix

### A. Polygon.io API 參考（免費帳號版本）

#### A.1 免費帳號限制總覽

| 項目 | 免費帳號 | 付費帳號 |
|-----|---------|---------|
| API 請求限制 | 5 次/分鐘 | 無限制 |
| 數據延遲 | 15 分鐘 | 即時 |
| WebSocket | 延遲數據 | 即時數據 |
| 技術指標 API | ❌ 不可用 | ✅ 可用 |
| 歷史數據 | ✅ 2 年 | ✅ 完整歷史 |
| 參考數據 | ✅ 可用 | ✅ 可用 |

#### A.2 可用端點列表（免費帳號）

**市場數據 Market Data**:
1. **聚合數據 (Aggregates)** - ✅ 免費可用
   ```
   GET /v2/aggs/ticker/{ticker}/range/{multiplier}/{timespan}/{from}/{to}
   ```
   - 參數：
     * `ticker`: 標的代碼（如 C:EURNZD, X:ETHUSD）
     * `multiplier`: 時間乘數（如 1）
     * `timespan`: 時間單位（minute, hour, day, week, month, quarter, year）
     * `from`: 開始日期（YYYY-MM-DD）
     * `to`: 結束日期（YYYY-MM-DD）
     * `adjusted`: true/false（是否調整）
     * `sort`: asc/desc
     * `limit`: 數量限制（最多 50000）

2. **前日收盤 (Previous Close)** - ✅ 免費可用
   ```
   GET /v2/aggs/ticker/{ticker}/prev
   ```
   - 取得前一個交易日的 OHLCV 數據

3. **市場快照 (Snapshot)** - ✅ 免費可用（延遲數據）
   ```
   GET /v2/snapshot/locale/global/markets/{market_type}/tickers/{ticker}
   ```
   - `market_type`: forex, crypto, stocks

**參考數據 Reference Data**:
1. **所有 Tickers** - ✅ 免費可用
   ```
   GET /v3/reference/tickers
   ```

2. **Ticker 詳細資料** - ✅ 免費可用
   ```
   GET /v3/reference/tickers/{ticker}
   ```

3. **新聞 (News)** - ✅ 免費可用
   ```
   GET /v2/reference/news
   ```
   - 參數：ticker, published_utc, order, limit, sort

4. **股息 (Dividends)** - ✅ 免費可用
   ```
   GET /v3/reference/dividends
   ```

5. **股票分割 (Splits)** - ✅ 免費可用
   ```
   GET /v3/reference/splits
   ```

**不可用端點（需付費）**:
- ❌ 技術指標 API (Technical Indicators)
- ❌ 即時 WebSocket (Real-time WebSocket)
- ❌ 期權數據 (Options Data) - 部分受限

#### A.3 Ticker 格式規範

| 市場類型 | 格式 | 範例 |
|---------|------|------|
| Forex | `C:BASQUOTE` | `C:EURNZD`, `C:GBPSGD`, `C:USDCHF` |
| Crypto | `X:BASQUOTE` | `X:ETHUSD`, `X:BTCUSD` |
| Stocks | `TICKER` | `AAPL`, `MSFT`, `GOOGL` |

#### A.4 API Response 欄位說明

**Aggregates Response**:
```json
{
  "v": 100000,      // Volume（成交量）
  "vw": 1.0234,     // Volume Weighted Average Price（加權平均價）
  "o": 1.0230,      // Open（開盤價）
  "c": 1.0240,      // Close（收盤價）
  "h": 1.0245,      // High（最高價）
  "l": 1.0225,      // Low（最低價）
  "t": 1611082800000, // Timestamp（時間戳記，毫秒）
  "n": 1234         // Number of transactions（交易筆數）
}
```

#### A.5 免費帳號使用建議

1. **請求頻率控制**：
   - 每分鐘最多 5 次請求
   - 在 N8N 中使用 `Wait` 節點或設定延遲
   - 批次處理多個標的時，每個請求間隔至少 12 秒

2. **數據快取策略**：
   - 將取得的數據儲存於本地
   - 避免重複請求相同數據
   - 使用 N8N 的 Cache 功能

3. **錯誤處理**：
   - 429 錯誤（Too Many Requests）：等待 60 秒後重試
   - 實施指數退避策略（Exponential Backoff）

4. **必須自行計算的指標**：
   - ATR (Average True Range)
   - RSI (Relative Strength Index)
   - MACD (Moving Average Convergence Divergence)
   - Bollinger Bands
   - Moving Averages (SMA, EMA)

#### A.6 完整 API 請求範例

**範例 1: 取得 NZDUSD 最近 30 天日線數據**
```bash
curl -X GET "https://api.polygon.io/v2/aggs/ticker/C:NZDUSD/range/1/day/2025-09-24/2025-10-24?adjusted=true&sort=desc&limit=50&apiKey=YOUR_API_KEY"
```

**範例 2: 取得 ETHUSD 前日收盤**
```bash
curl -X GET "https://api.polygon.io/v2/aggs/ticker/X:ETHUSD/prev?adjusted=true&apiKey=YOUR_API_KEY"
```

**範例 3: 取得 Forex 市場新聞**
```bash
curl -X GET "https://api.polygon.io/v2/reference/news?ticker=EURNZD&order=desc&limit=10&sort=published_utc&apiKey=YOUR_API_KEY"
```

**範例 4: 取得 Ticker 詳細資料**
```bash
curl -X GET "https://api.polygon.io/v3/reference/tickers/C:GBPSGD?apiKey=YOUR_API_KEY"
```

---

### B. 技術指標計算公式

**ATR (Average True Range)**:
```
TR = max(High - Low, |High - PrevClose|, |Low - PrevClose|)
ATR = SMA(TR, period)
```

**價格變動率**:
```
Change% = ((CurrentPrice - PreviousPrice) / PreviousPrice) * 100
```

---

### C. 風險等級判定規則

| 風險分數 | 風險等級 | 建議動作 |
|---------|---------|---------|
| 0-2     | LOW     | HOLD    |
| 3-4     | MEDIUM  | ADJUST  |
| 5+      | HIGH    | REVERSE |

**風險分數計算**:
- 波動性 > 2 ATR: +3
- 重大新聞 > 5 則: +2
- 情緒分數 < -5: +2

---

### D. N8N 中的 API 請求頻率控制

由於免費帳號每分鐘只能請求 5 次 Polygon API，需要在工作流程中加入頻率控制。

#### D.1 使用 Wait Node 控制請求間隔

**在 Loop Symbols 內部加入 Wait Node**:

**節點類型**: `Wait` (nodes-base.wait)

**配置**:
```json
{
  "amount": 12,
  "unit": "seconds"
}
```

**工作流程修正**:
```
[Loop Symbols] ───┐
    ↓             │
[Get Market Data] │
    ↓             │
[Wait 12 seconds] │  ← 新增此節點
    ↓             │
[Get News Data]   │
    ↓             │
[Wait 12 seconds] │  ← 新增此節點
    ↓             │
[Calculate ATR]   │
    ↓             │
←───────────────┘
```

#### D.2 使用 Function Node 實施智能延遲

**節點類型**: `Code` (nodes-base.code)

**JavaScript 代碼**:
```javascript
// 計算已使用的請求次數和等待時間
const currentTime = Date.now();
const lastRequestTime = $executionData.lastRequestTime || 0;
const requestCount = $executionData.requestCount || 0;

// 每分鐘最多 5 次請求
const MAX_REQUESTS_PER_MINUTE = 5;
const TIME_WINDOW = 60000; // 60 seconds

// 檢查是否需要等待
if (currentTime - lastRequestTime < TIME_WINDOW && requestCount >= MAX_REQUESTS_PER_MINUTE) {
  const waitTime = TIME_WINDOW - (currentTime - lastRequestTime);
  await new Promise(resolve => setTimeout(resolve, waitTime));
}

// 更新請求計數
if (currentTime - lastRequestTime >= TIME_WINDOW) {
  $executionData.requestCount = 1;
  $executionData.lastRequestTime = currentTime;
} else {
  $executionData.requestCount = (requestCount || 0) + 1;
}

return $input.all();
```

#### D.3 錯誤處理：429 Too Many Requests

在每個 HTTP Request 節點後加入錯誤處理：

**配置**:
```json
{
  "continueOnFail": true,
  "retryOnFail": true,
  "maxTries": 3,
  "waitBetweenTries": 60000
}
```

**錯誤處理 IF Node**:
```json
{
  "conditions": {
    "number": [
      {
        "value1": "={{ $json.statusCode }}",
        "operation": "equal",
        "value2": 429
      }
    ]
  }
}
```

如果是 429 錯誤，等待 60 秒後重試。

---

### E. 資源連結

- **N8N 官方文檔**: https://docs.n8n.io/
- **Polygon.io API 文檔**: https://polygon.io/docs/
  - REST API: https://polygon.io/docs/rest/getting-started
  - Forex Data: https://polygon.io/docs/rest/forex/getting-started
  - Crypto Data: https://polygon.io/docs/rest/crypto/getting-started
- **Polygon.io JavaScript Client**: https://github.com/polygon-io/client-js
- **Finnhub API**: https://finnhub.io/docs/api
- **Bark 通知服務**: 
  - App Store: https://apps.apple.com/us/app/bark-customed-notifications/id1403753865
  - GitHub: https://github.com/Finb/Bark
  - API 文檔: https://bark.day.app/#/tutorial
- **N8N HTTP Request Node**: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/

---

## 實施時間表 Implementation Timeline

| 階段 | 任務 | 預計時間 |
|-----|------|---------|
| 第 1 週 | 環境設定與 API 整合 | 2-3 天 |
| 第 2 週 | 主工作流程開發 | 3-4 天 |
| 第 3 週 | 測試與調整 | 2-3 天 |
| 第 4 週 | 部署與監控 | 1-2 天 |
| 持續 | 優化與維護 | 持續進行 |

---

---

## 快速開始指南 Quick Start Guide

### 步驟 1: 驗證 API 連線

在開始建立工作流程前，先測試 Polygon API 是否正常：

```bash
# 測試 API Key
curl "https://api.polygon.io/v2/aggs/ticker/C:NZDUSD/prev?adjusted=true&apiKey=YOUR_API_KEY"

# 預期回應
{
  "status": "OK",
  "results": [...]
}
```

### 步驟 2: 建立第一個簡單工作流程

在正式建立完整工作流程前，先建立一個簡單的測試工作流程：

**測試工作流程**: `Test_Polygon_API`

1. **Manual Trigger** → 手動觸發
2. **HTTP Request** → 呼叫 Polygon API
3. **Code** → 解析並顯示結果
4. **No Operation** → 輸出結果

### 步驟 3: 漸進式建立主工作流程

不要一次建立所有節點，建議分階段：

**階段 1**: 基礎數據收集（2-3 天）
- Schedule Trigger
- Initialize Variables
- Get Market Data
- Save to File

**階段 2**: 技術分析（2-3 天）
- Calculate ATR
- 其他技術指標

**階段 3**: 新聞與情境分析（2-3 天）
- Get News Data
- Analyze Context
- Generate Recommendation

**階段 4**: 報告生成與通知（1-2 天）
- Generate Report
- Send Telegram Notification

### 步驟 4: 監控與優化

部署後持續監控：
- 檢查執行歷史
- 查看錯誤日誌
- 驗證報告品質
- 調整參數

---

## 重要提醒 Important Notes

### ⚠️ 免費帳號限制
- **每分鐘最多 5 次 API 請求**
- **數據延遲 15 分鐘**
- **必須自行計算所有技術指標**
- 建議在工作流程中加入適當的延遲（Wait 節點）

### ✅ 最佳實踐
1. 使用環境變數儲存 API Keys
2. 實施錯誤處理和重試機制
3. 定期備份工作流程 JSON
4. 記錄所有配置變更
5. 測試後再部署到生產環境

### 📊 預期執行時間
- 5 個標的 × 每個 12 秒延遲 = 約 1 分鐘
- 加上數據處理和報告生成 = 約 2-3 分鐘總執行時間
- 每日一次執行，資源消耗低

---

**文件版本**: 2.0（更新為免費帳號版本）  
**最後更新**: 2025-10-24  
**作者**: JT_EA Team  
**狀態**: 待實施  
**參考文檔**: Polygon.io API Docs (via Context7 MCP)

