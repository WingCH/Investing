# JT_EA - MT4 Expert Advisor Strategy

波幅交易自動化策略，專注於高波動外匯貨幣對和加密貨幣。

---

## 📁 目錄結構

```
JT_EA/
├── README.md                 # 本文件 - 總覽
├── PRINCIPLES.md             # 策略核心原理與邏輯
├── context.md                # 當前交易方向與手動指令
├── agents.md                 # AI agents 定義（監控、分析）
├── run_daily_monitor.md      # 每日監控執行指令
└── daily_reports/            # 每日分析報告存檔
    ├── TEMPLATE.md           # 報告模板
    └── [YYYY-MM-DD].md       # 實際日報
```

---

## 🎯 核心文件說明

### PRINCIPLES.md
定義策略的核心原理：
- **還盤策略 (reversal-accumulation)**：最賺錢的核心機制，透過逆向加碼降低成本，等待反彈獲利
- **回調入場 (pullback-entry)**：捕捉超跌反彈機會

### context.md
記錄當前交易決策：
- 目前監控 5 個 symbols，全部為買入方向
- 變更交易方向前必須更新此文件
- 包含 review 週期和風險控制參數

### agents.md
AI 輔助決策系統：
- **Daily Bias Monitor Agent**：每日監控新聞、數據、技術指標
- 自動生成 HOLD/ADJUST/REVERSE 建議
- 風險評估與警報機制

---

## 🚀 快速開始

### 每日監控流程

1. **打開 Cursor 或任何 AI 助手**

2. **複製執行指令**（來自 `run_daily_monitor.md`）：
   ```
   請執行 JT_EA Daily Bias Monitor Agent，監控以下 symbols：
   EURNZD, GBPSGD, NZDUSD, USDCHF, ETHUSD（全部買入方向）
   
   生成今日日報至 JT_EA/daily_reports/[今日日期].md
   ```

3. **檢查生成的報告**
   - 查看每個 symbol 的建議（HOLD/ADJUST/REVERSE）
   - 關注高風險標的
   - 執行 Action Items

4. **更新交易設定**（如需要）
   - 調整 `context.md`
   - 修改 MT4 EA 參數
   - 記錄變更原因

---

## 📊 當前交易部位

| Symbol  | 方向 | 風險等級 | 備註 |
|---------|------|----------|------|
| EURNZD  | 買入 | 待評估   | 歐元/紐元 |
| GBPSGD  | 買入 | 待評估   | 英鎊/新幣 |
| NZDUSD  | 買入 | 待評估   | 紐元/美元 |
| USDCHF  | 買入 | 待評估   | 美元/瑞郎 |
| ETHUSD  | 買入 | 待評估   | 以太坊/美元 |

> 風險等級由 Daily Bias Monitor Agent 每日更新

---

## ⚠️ 風險控制

### 自動觸發條件
- 任何 symbol 超過 **2 ATR** 劇烈波動 → 立即通知
- 央行緊急聲明或利率意外變動 → 立即通知
- 重大地緣政治事件 → 立即通知

### 手動檢查點
- 每日倫敦收市前（香港時間凌晨 12:00-1:00）
- 重大經濟數據發布後
- EA 報告異常虧損時

### 止損原則
- 依據 `PRINCIPLES.md` 中的還盤策略邏輯
- 預設風險控制：[需補充具體數值]
- 最大回撤限制：[需補充具體數值]

---

## 🔧 策略參數（待補充）

```yaml
# 未來可加入具體參數
entry_signals:
  - pullback_threshold: [數值]
  - volume_confirmation: [是/否]

risk_management:
  - max_positions_per_symbol: [數值]
  - pyramid_levels: [數值]
  - stop_loss_atr_multiple: [數值]

reversal_accumulation:
  - grid_spacing: [pips]
  - lot_multiplier: [數值]
  - max_total_lots: [數值]
```

---

## 📈 績效追蹤（待建立）

未來可加入：
- 每月報表
- 勝率統計
- 最大回撤記錄
- 各 symbol 表現對比

---

## 🛠️ 技術架構

- **執行平台**：MetaTrader 4 (MT4)
- **程式語言**：MQL4
- **監控工具**：AI agents (Cursor/Claude)
- **數據源**：Bloomberg, Reuters, TradingView
- **費用**：500 HKD/月

---

## 📝 工作流程

```
每日循環：
1. London Close（00:00-01:00 HKT）
   └─ Daily Bias Monitor 執行
      ├─ 收集新聞與數據
      ├─ 技術分析
      └─ 生成日報

2. 檢查日報
   └─ 有高風險 symbols？
      ├─ 是 → 調整部位/方向
      └─ 否 → 維持運作

3. EA 持續運作
   ├─ 執行 pullback-entry
   ├─ 執行 reversal-accumulation
   └─ 監控止損/獲利

4. 異常事件
   └─ 立即觸發通知
      └─ 手動介入決策
```

---

## 📚 延伸閱讀

- [TOOL_PRINCIPLES_TEMPLATE.md](../TOOL_PRINCIPLES_TEMPLATE.md) - 原始模板
- [AGENTS.md](../AGENTS.md) - Repository 整體指引

---

## 🔄 版本歷史

- **v1.0** - 初始設定，5 個 symbols 全買入方向
- **v1.1** - 加入 Daily Bias Monitor Agent
- **v1.2** - 完善文檔與執行流程

---

## 💡 待辦事項

- [ ] 補充具體策略參數數值
- [ ] 建立績效追蹤系統
- [ ] 設定自動化執行（GitHub Actions 或 Cron）
- [ ] 整合通知渠道（Slack/Telegram）
- [ ] 回測歷史數據驗證參數

---

## 📞 聯絡

策略負責人：[待補充]  
最後更新：2025-10-24

