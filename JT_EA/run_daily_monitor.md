# Daily Bias Monitor - 執行指令

## 快速執行（複製以下指令給 AI）

```
請執行 JT_EA Daily Bias Monitor Agent：

1. 今天日期：[自動填入今日日期 YYYY-MM-DD]

2. 監控以下五個 symbols 的最新情況：
   - EURNZD（買入方向）
   - GBPSGD（買入方向）
   - NZDUSD（買入方向）
   - USDCHF（買入方向）
   - ETHUSD（買入方向）

3. 執行任務：
   a) 搜尋過去 24 小時相關的財經新聞和經濟數據
   b) 獲取技術指標更新（ATR、MA、RSI）
   c) 分析每個 symbol 是否需要：HOLD（維持）/ ADJUST（調整）/ REVERSE（反轉）
   d) 評估風險等級：低/中/高

4. 生成完整日報並保存至：
   JT_EA/daily_reports/[今日日期].md
   
5. 如有高風險 symbol，請特別標注並說明原因。

參考：agents.md 中的 Daily Bias Monitor Agent 定義
模板：daily_reports/TEMPLATE.md
```

---

## 手動執行步驟（詳細版）

### Step 1: 準備工作
- 確認今日日期
- 檢查是否有重大已知事件（央行會議、重要數據發布）

### Step 2: 數據收集

對每個 symbol 收集：

#### EURNZD
- [ ] 歐元區新聞（ECB、經濟數據）
- [ ] 紐西蘭新聞（RBNZ、商品價格）
- [ ] 技術面數據

#### GBPSGD
- [ ] 英國新聞（BoE、經濟數據）
- [ ] 新加坡新聞（MAS、貿易數據）
- [ ] 技術面數據

#### NZDUSD
- [ ] 紐西蘭新聞
- [ ] 美國新聞（Fed、經濟數據）
- [ ] 技術面數據

#### USDCHF
- [ ] 美國新聞
- [ ] 瑞士新聞（SNB）
- [ ] 避險情緒指標
- [ ] 技術面數據

#### ETHUSD
- [ ] 以太坊網絡/開發新聞
- [ ] 加密貨幣監管消息
- [ ] DeFi/NFT 市場動態
- [ ] 技術面數據

### Step 3: 分析與決策

使用決策樹：
```
對每個 symbol：
├─ 有重大利空消息？
│  ├─ 是 → 考慮 ADJUST 或 REVERSE
│  └─ 否 → 繼續
├─ 技術面破位？
│  ├─ 是 → 考慮 ADJUST
│  └─ 否 → 繼續
├─ ATR 大幅增加（風險升高）？
│  ├─ 是 → 考慮 ADJUST（收緊止損）
│  └─ 否 → HOLD
└─ 結論：HOLD / ADJUST / REVERSE
```

### Step 4: 生成報告

1. 複製 `daily_reports/TEMPLATE.md`
2. 填入今日日期
3. 填入所有分析結果
4. 保存為 `daily_reports/YYYY-MM-DD.md`

### Step 5: 執行建議

如有 ADJUST 或 REVERSE 建議：
1. 更新 `context.md` 中的 manual directives
2. 調整 MT4 EA 設定
3. 記錄變更原因

---

## 使用 Cursor AI 自動執行

1. 打開 Cursor
2. 在聊天視窗貼上「快速執行」區塊的指令
3. AI 會自動：
   - 使用 web_search 工具搜尋新聞
   - 分析數據
   - 生成報告文件
4. 檢查生成的報告並執行建議

---

## 設定自動化（進階）

### 使用 GitHub Actions（未來擴展）

可以設定每日自動執行：
- 定時觸發（如每日 00:00 UTC）
- 調用 API 獲取數據
- 生成報告並提交至 repo
- 發送通知到 Slack/Telegram

### 使用 Cron Job（本地）

```bash
# 每日 00:00 執行
0 0 * * * cd /Users/wingchan/Project/Investing/JT_EA && [執行腳本]
```

---

## 常見問題 FAQ

**Q: 如果某天沒有重要新聞怎麼辦？**  
A: 仍然生成報告，標註「無重大變化」，維持 HOLD 建議。

**Q: 多個 symbols 都是高風險怎麼辦？**  
A: 考慮整體減倉，或暫停 EA 直到風險降低。

**Q: ETHUSD 波動特別大，如何處理？**  
A: 加密貨幣波動較大是正常的，除非出現監管黑天鵝或技術面崩潰，否則可以容忍更大的 ATR。

---

## 聯絡與支援

如有問題或需要調整 agent 參數，請更新 `agents.md` 或聯絡策略負責人。

