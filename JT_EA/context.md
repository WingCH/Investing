# Context – JT_EA Strategy

This document captures the discretionary directives that sit on top of the automated JT_EA execution stack.

- **Manual control surface**: Decide which FX symbols the algo should bias long or short; sizing and order lifecycle remain programmatic.
- **Active manual directives**:
  - `EURNZD` — buy bias in effect
  - `GBPSGD` — buy bias in effect
  - `NZDUSD` — buy bias in effect
  - `USDCHF` — buy bias in effect
  - `ETHUSD` — buy bias in effect
- **Change protocol**: Update this list before toggling the corresponding flag in automation code to preserve decision traceability.
- **Review cadence**: Reconfirm directives at each London close or sooner if risk dashboard flags divergence beyond 1 ATR from baseline expectations.
- **AI monitoring**: Daily Bias Monitor Agent (詳見 `agents.md`) 每日自動分析新聞、經濟數據與技術指標，生成決策建議報告於 `daily_reports/` 目錄。
