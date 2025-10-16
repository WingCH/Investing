# JT_EA 基本原理 / Principles

## 概覽 Overview
- **工具名稱 Tool Name**：JT_EA
- **策略類型 Strategy Type**：MT4 Expert Advisor（波幅交易）
- **目標市場 Target Market**：外匯高波動貨幣對（例：USD/JPY）
- **使用頻率/週期 Cadence**：持續自動運作；月費 500 HKD

## 核心原理 Core Thesis
透過不斷建立與平倉部位以捕捉短期波幅。若判斷價格將上漲，會在現價買入並設定獲利目標，達價就平倉並重新建倉；若價格往下走，EA 會在下跌過程中逐步加碼，等待反彈時再回補以鎖定利潤。策略假設：短期波動最終回歸均衡，可利用震盪區間反覆收割價差。