# JT_EA AI Agents

本文件定義支援 JT_EA 策略的 AI agents，用於自動化監控、分析和決策支援。

---

## Daily Bias Monitor Agent

**目的 Purpose**：每日監控現有交易方向的有效性，及時發現需要調整或停止的訊號。

**運作週期 Schedule**：每日一次，建議於倫敦收市前執行（約香港時間凌晨 12:00-1:00）

**監控標的 Monitored Symbols**：
- EURNZD（歐元/紐西蘭元）— 當前方向：買入
- GBPSGD（英鎊/新加坡元）— 當前方向：買入
- NZDUSD（紐西蘭元/美元）— 當前方向：買入
- USDCHF（美元/瑞士法郎）— 當前方向：買入
- ETHUSD（以太坊/美元）— 當前方向：買入

### 執行步驟 Workflow

1. **數據收集 Data Collection**
   - 搜尋過去 24 小時內與各標的相關的財經新聞
   - 獲取相關經濟數據發布（如利率決議、CPI、GDP、就業數據）
   - 檢索技術指標更新（ATR、移動平均線、RSI）
     * 使用 `get_aggs` 取得日線/小時線數據計算 ATR
     * 使用 `get_previous_close_agg` 對比前日收盤
   - 監控相關央行政策聲明或重大事件
   - **MCP 工具使用範例**:
     ```
     # 取得 NZDUSD 最近 30 天的日線數據
     get_aggs(ticker="C:NZDUSD", multiplier=1, timespan="day", from="2025-09-24", to="2025-10-24")
     
     # 取得 ETHUSD 即時市場快照
     get_snapshot_ticker(market_type="crypto", ticker="X:ETHUSD")
     
     # 取得所有標的的最新價格
     get_last_trade(ticker="C:EURNZD")
     get_last_trade(ticker="C:GBPSGD")
     get_last_trade(ticker="C:USDCHF")
     ```

2. **情境分析 Context Analysis**
   - 識別可能逆轉方向的重大因素：
     * 央行政策轉向
     * 地緣政治衝擊
     * 經濟數據顯著超預期
     * 技術面破位（突破關鍵支撐/阻力）
   - 評估每個 symbol 的風險等級：低/中/高

3. **決策建議 Decision Recommendations**
   
   對每個 symbol 生成以下三種建議之一：
   
   - **維持 HOLD**：無重大訊號，繼續執行當前 bias
   - **調整 ADJUST**：
     * 建議動作：減倉 / 收緊止損 / 暫停新倉
     * 理由：列出具體風險因素
   - **反轉 REVERSE**：
     * 建議動作：平倉並考慮反向部位
     * 理由：列出關鍵轉折證據

4. **輸出格式 Output Format**

生成日報於 `JT_EA/daily_reports/YYYY-MM-DD.md`，包含：

```markdown
# Daily Bias Review - [日期]

## Executive Summary
[總體市場環境概述，2-3 句]

## Symbol Analysis

### EURNZD
- **當前方向**: 買入 (Buy Bias)
- **建議動作**: [HOLD/ADJUST/REVERSE]
- **風險等級**: [低/中/高]
- **關鍵因素**:
  - [新聞/數據要點 1]
  - [新聞/數據要點 2]
- **技術面**:
  - ATR: [數值] (波動性評估)
  - 價格 vs MA: [位置關係]
- **結論**: [1-2 句總結]

[重複其他四個 symbols...]

## Action Items
- [ ] [需要執行的具體動作]
- [ ] [需要追蹤的事件]

## Risk Dashboard
- 高風險 symbol 數量: X/5
- 需要立即關注: [列出 symbols]
```

### 數據源建議 Data Sources

#### 即時市場數據 (透過 MCP)
- **Polygon.io MCP Server**: 已整合的即時金融數據 API
  - Forex pairs: EURNZD, GBPSGD, NZDUSD, USDCHF
  - Crypto: ETHUSD
  - 可用工具:
    * `get_aggs` - 取得 OHLC 聚合數據（日線、小時線等）
    * `get_snapshot_ticker` - 取得即時市場快照
    * `get_last_trade` - 最新交易價格
    * `get_last_quote` - 最新報價（買賣價差）
    * `list_trades` - 歷史交易數據
    * `get_previous_close_agg` - 前一日收盤數據

#### 新聞與經濟數據
- **新聞**: Bloomberg, Reuters, ForexLive, CoinDesk (for ETHUSD)
- **經濟數據**: TradingEconomics, Investing.com Calendar
- **技術分析補充**: TradingView, MT4 平台數據
- **央行**: ECB, RBNZ, BoE, MAS, SNB, Fed 官網

### 觸發警報條件 Alert Triggers

立即通知（不等每日報告）的情況：
- 任何 symbol 超過 2 ATR 的劇烈波動
- 央行緊急聲明或利率意外變動
- 重大地緣政治事件（戰爭、制裁、政變）
- 技術面破位且成交量放大

### 整合方式 Integration

- **自動化**: 可使用 cron job 或 GitHub Actions 觸發
- **手動觸發**: 於 Cursor/IDE 中使用 agent 指令執行
- **通知渠道**: Slack/Telegram/Email（根據需要配置）

---

## 未來擴展 Future Agents

- **Backtest Analyzer**: 自動回測參數優化
- **Risk Monitor**: 即時監控帳戶風險指標
- **News Sentiment**: 新聞情緒分析與量化評分

---

## MCP 工具配置 MCP Tools Setup

### Polygon.io 設定

1. **取得 API Key**:
   - 前往 [Polygon.io](https://polygon.io/) 註冊帳戶
   - 從控制台取得 API key
   - 免費方案提供延遲數據，付費方案提供即時數據

2. **更新配置**:
   - 編輯 `~/.cursor/mcp.json`
   - 找到 `polygon` 區塊
   - 將 `YOUR_POLYGON_API_KEY_HERE` 替換為實際的 API key

3. **重啟 Cursor**:
   - 完成設定後重啟 Cursor 以載入 MCP 服務器

### Polygon.io Ticker 格式

- **Forex**: `C:BASQUOTE` (例如 `C:EURNZD`, `C:GBPSGD`, `C:NZDUSD`, `C:USDCHF`)
- **Crypto**: `X:BASQUOTE` (例如 `X:ETHUSD`, `X:BTCUSD`)
- **Stocks**: 直接使用 ticker (例如 `AAPL`, `MSFT`)

### 常用查詢範例

```python
# 查詢日線數據（計算 ATR）
get_aggs(
    ticker="C:NZDUSD", 
    multiplier=1, 
    timespan="day", 
    from_="2025-09-01", 
    to="2025-10-24",
    limit=50
)

# 查詢小時線數據（短期波動分析）
get_aggs(
    ticker="X:ETHUSD",
    multiplier=1,
    timespan="hour",
    from_="2025-10-23",
    to="2025-10-24"
)

# 取得市場快照（即時狀態）
get_snapshot_ticker(market_type="forex", ticker="C:EURNZD")

# 取得前一日收盤數據
get_previous_close_agg(ticker="C:GBPSGD")
```

### 注意事項

- 免費帳戶有 API 呼叫次數限制
- Forex 數據在週末可能不更新
- Crypto 市場 24/7 運作
- 建議在執行 agent 前測試 API 連線

