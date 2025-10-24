# Investment Tools Catalog

This catalog lists all active investment tools and strategies in this repository.

---

## Active Tools

### 1. JT_EA - Daily Bias Monitor System
- **Path**: `/JT_EA/`
- **Type**: Forex Trading Strategy with AI Monitoring
- **Owner**: Wing Chan
- **Status**: ✅ Active / In Production
- **Market**: Forex & Crypto
- **Description**: Automated daily bias monitoring system for multiple forex pairs (EURNZD, GBPSGD, NZDUSD, USDCHF) and ETHUSD. Uses N8N workflow to collect market data, analyze context, and generate decision recommendations.
- **Key Features**:
  - Daily automated monitoring (runs at HKT 00:00-01:00)
  - Integrates with Polygon.io for market data
  - Bark notifications for daily reports
  - AI-powered decision recommendations
- **Documentation**:
  - [`JT_EA/N8N_DESIGN_PLAN.md`](JT_EA/N8N_DESIGN_PLAN.md) - Complete N8N workflow design
  - [`JT_EA/PRINCIPLES.md`](JT_EA/PRINCIPLES.md) - Strategy principles
  - [`JT_EA/agents.md`](JT_EA/agents.md) - AI agents configuration
  - [`JT_EA/context.md`](JT_EA/context.md) - Manual directives
- **Created**: 2024
- **Last Updated**: 2025-10

---

### 2. TV_Screener - TradingView Forex Screener Auto Export
- **Path**: `/TV_Screener/`
- **Type**: Data Scraping & Monitoring Tool
- **Owner**: Wing Chan
- **Status**: 📝 Design Phase
- **Market**: Forex
- **Description**: Automated system to scrape and monitor TradingView Forex Screener technical ratings. Solves the limitation of free TradingView accounts not being able to export screener data.
- **Key Features**:
  - Automated web scraping using Firecrawl API (every 2 hours)
  - Technical rating change detection (Strong Buy/Buy/Neutral/Sell/Strong Sell)
  - Data storage in Google Sheets (Latest/History/Changes_Log)
  - Bark push notifications for rating changes
  - Zero-cost operation (all free tiers)
- **Documentation**:
  - [`TV_Screener/N8N_DESIGN_PLAN.md`](TV_Screener/N8N_DESIGN_PLAN.md) - Complete N8N workflow design
  - [`TV_Screener/PRINCIPLES.md`](TV_Screener/PRINCIPLES.md) - Strategy rationale
  - [`TV_Screener/README.md`](TV_Screener/README.md) - Quick start guide
  - [`TV_Screener/context.md`](TV_Screener/context.md) - Brief context
  - [`TV_Screener/metadata.yaml`](TV_Screener/metadata.yaml) - Project metadata
- **Created**: 2025-10-24
- **Last Updated**: 2025-10-24

---

## Tool Status Definitions

| Status | Description |
|--------|-------------|
| ✅ Active / In Production | Tool is deployed and running in production |
| 🚧 In Development | Tool is being actively developed |
| 📝 Design Phase | Design documents completed, awaiting implementation |
| ⏸️ Paused | Development paused temporarily |
| 🗄️ Archived | Tool is no longer maintained but kept for reference |
| 🧪 Testing | Tool is in testing phase |

---

## Repository Structure

Each tool follows a standardized structure:

```
TOOL_NAME/
├── README.md              # Quick start guide and overview
├── PRINCIPLES.md          # Strategy rationale and core concepts
├── N8N_DESIGN_PLAN.md    # N8N workflow design (if applicable)
├── context.md             # Brief context summary
├── metadata.yaml          # Project metadata
├── agents.md              # AI agents configuration (if applicable)
├── lib/                   # Reusable code components
├── signals/               # Signal generation logic
├── backtests/             # Backtesting results and scripts
└── daily_reports/         # Generated reports (if applicable)
```

---

## Shared Resources

### `/shared/`
Common utilities and components shared across multiple tools.

### Repository-Level Files
- [`AGENTS.md`](AGENTS.md) - Global AI agents configuration
- [`TOOL_PRINCIPLES_TEMPLATE.md`](TOOL_PRINCIPLES_TEMPLATE.md) - Template for creating PRINCIPLES.md
- `CATALOG.md` - This file

---

## Adding a New Tool

When adding a new investment tool to this repository:

1. **Create Directory**: Create a new top-level folder with a descriptive name (e.g., `FX_Arbitrage/`)
2. **Use Template**: Copy and fill out `TOOL_PRINCIPLES_TEMPLATE.md` as `PRINCIPLES.md`
3. **Core Files**: Create at minimum:
   - `README.md` - Overview and quick start
   - `PRINCIPLES.md` - Strategy rationale
   - `context.md` - Brief summary
   - `metadata.yaml` - Structured metadata
4. **Update Catalog**: Add entry to this `CATALOG.md` file
5. **Documentation**: If using N8N, create `N8N_DESIGN_PLAN.md`
6. **Testing**: Include test results or backtests in `backtests/` folder

---

## Performance Tracking

| Tool | Status | Market | Instruments | Last Review | Performance |
|------|--------|--------|-------------|-------------|-------------|
| JT_EA | ✅ Active | Forex & Crypto | EURNZD, GBPSGD, NZDUSD, USDCHF, ETHUSD | 2025-10 | Manual bias directives in effect |
| TV_Screener | 📝 Design | Forex | All TradingView Forex pairs | 2025-10-24 | N/A (not yet deployed) |

---

## Maintenance Schedule

### Daily
- Monitor JT_EA daily reports
- Check Bark notifications for TV_Screener rating changes (when deployed)

### Weekly
- Review JT_EA performance vs manual directives
- Verify TV_Screener data updates (when deployed)

### Monthly
- Review JT_EA bias directives, adjust if needed
- Clean TV_Screener History sheet (when deployed)
- Check API usage for all tools

### Quarterly
- Comprehensive review of all active tools
- Update documentation if strategies change
- Backtest and validate signal accuracy

---

**Catalog Version**: v1.0  
**Last Updated**: 2025-10-24  
**Maintained By**: Wing Chan

