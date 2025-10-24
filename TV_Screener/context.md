# Context – TradingView Forex Screener Auto Export

This tool automates the extraction and monitoring of TradingView Forex Screener technical ratings for free-tier users.

## Overview
- **Purpose**: Bypass TradingView's export limitation for free users by automatically scraping and storing forex technical ratings
- **Execution**: N8N workflow runs every 2 hours (configurable)
- **Data Flow**: Firecrawl API → Parse & Compare → Google Sheets + Bark Notifications

## Key Components
- **Data Source**: TradingView Forex Screener (https://www.tradingview.com/forex-screener/)
- **Scraping**: Firecrawl AI-powered web scraping with JSON schema extraction
- **Storage**: Google Sheets (3-tier structure: Latest / History / Changes_Log)
- **Alerting**: Bark push notifications on iOS when technical_rating changes

## Monitored Data
- **Symbol Name**: Forex pair identifier (e.g., EURUSD, GBPUSD)
- **Technical Rating**: Strong Buy | Buy | Neutral | Sell | Strong Sell

## Change Detection Logic
System compares current scrape with previous data in "Latest" sheet:
- **Change detected** → Send Bark notification + Log to Changes_Log
- **No change** → Update Latest + Append to History only

## Cost Structure
- **Total Cost**: $0/month (using free tiers)
  - Firecrawl: 500 req/month (using ~360)
  - Google Sheets: Unlimited (standard use)
  - Bark: Free
  - N8N: Self-hosted (free)

## Operational Notes
- Execution frequency: Every 2 hours (360 requests/month)
- Suitable for: Trend tracking, signal confirmation, historical analysis
- Not suitable for: Real-time scalping, high-frequency trading signals
- Dependencies: Stable Firecrawl service + TradingView page structure

## Review Cadence
- Daily: Monitor Bark notifications for rating changes
- Weekly: Verify Latest sheet updates
- Monthly: Check API usage, clean old History data
- Quarterly: Test workflow integrity, validate data accuracy

## Related Documentation
- `N8N_DESIGN_PLAN.md` - Complete workflow design and configuration
- `PRINCIPLES.md` - Strategy rationale and limitations
- `README.md` - Quick start guide

