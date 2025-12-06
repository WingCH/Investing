
# 📈 MT4 自動同步交易記錄到 Google Sheets (完整教學)

這份教學將指導你如何設置一個全自動系統，將 MetaTrader 4 (MT4) 的持倉單、現價、浮動盈虧等數據，實時同步到你的 Google Sheets。

---

## ✅ 事前準備
1. 一個 Google 帳號。
2. 電腦版 MT4 終端機 (已登入交易帳號)。
3. 此教學提供的兩段代碼 (GAS 和 MQL4)。

---

## 第一部分：設置 Google Sheets (雲端接收端)

### 1. 建立試算表
1. 打開 [Google Sheets](https://docs.google.com/spreadsheets/)，建立一個新的試算表。
2. 將試算表命名為 `MT4 Live Monitor` (或你喜歡的名字)。
3. **重要：** 在 **第一行 (Row 1)** 設定標題欄，請嚴格依照以下順序填入：
   
   | A | B | C | D | E | F | G | H | I |
   | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
   | **Ticket** | **Symbol** | **Type** | **Lots** | **Open Price** | **Current Price** | **Profit (USD)** | **Open Time** | **Last Update** |

### 2. 設置 Apps Script
1. 在試算表上方選單，點擊 **擴充功能 (Extensions)** > **Apps Script**。
2. 刪除編輯器內所有預設代碼。
3. 複製並貼上以下 **GAS 代碼**：

```javascript
//=== MT4 Sync Service (Final Version) ===
const SHEET_NAME = "Sheet1"; // 請確認你的分頁名稱

function doPost(e) {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
    
    // 1. 獲取內容
    var raw = "";
    if (e.postData && e.postData.contents) {
      raw = e.postData.contents.trim();
    }
    
    // 2. 檢查清空指令
    // 兼容 URL 參數或 Body 內容指令
    if (e.parameter.ticket === "CLEAR_ALL_DATA_PLEASE" || raw.indexOf("ticket=CLEAR_ALL_DATA_PLEASE") === 0) {
      // 保留第一行標題，清空 A2 之後的所有內容
      sheet.getRange("A2:I20000").clearContent(); 
      return ContentService.createTextOutput("cleared");
    }

    if (raw === "") return ContentService.createTextOutput("empty");

    // 3. 處理數據 (過濾空白行，防止錯誤)
    const lines = raw.split("\n").filter(line => line.trim() !== "");
    
    if (lines.length === 0) return ContentService.createTextOutput("no valid lines");

    const rows = lines.map(line => line.split("\t"));

    // 4. 寫入數據
    if (rows.length > 0) {
      sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, rows[0].length).setValues(rows);
    }

    return ContentService.createTextOutput("batch ok - " + rows.length + " rows");

  } catch (err) {
    return ContentService.createTextOutput("error: " + err.toString());
  }
}
````

### 3\. 部署 (最重要的一步！)

1.  點擊右上角藍色的 **部署 (Deploy)** 按鈕 \> **新增部署 (New deployment)**。
2.  點擊左側齒輪圖示，選擇 **網頁應用程式 (Web app)**。
3.  設定如下：
      * **說明 (Description)：** MT4 Sync
      * **執行身份 (Execute as)：** 我 (Me)
      * **誰可以存取 (Who has access)：** **任何擁有 Google 帳戶的使用者 (Anyone with Google account)** 或 **任何人 (Anyone)**。
      * *(注意：為了 MT4 能順利寫入，建議選「任何人」或是確保你授權正確)*
4.  點擊 **部署 (Deploy)**。
5.  **複製生成的「網頁應用程式網址」 (Web App URL)**。
      * *網址格式應為 `https://script.google.com/macros/s/..../exec`*

-----

## 第二部分：設置 MT4 環境 (允許聯網)

為了讓 EA 能發送數據到 Google，必須將 Google 的網址加入白名單。

1.  打開 MT4，點擊上方選單 **工具 (Tools)** \> **選項 (Options)** (或按 `Ctrl+O`)。
2.  切換到 **智能交易系統 (Expert Advisors)** 分頁。
3.  勾選最下方的 **允許為列出的 URL 進行 WebRequest (Allow WebRequest for listed URL)**。
4.  點擊下方的綠色 `+` 號，貼上此網址：
    `https://script.google.com`
5.  按 **確定 (OK)**。

-----

## 第三部分：安裝與運行 EA

### 1\. 創建 EA

1.  在 MT4 按 `F4` 打開 **MetaEditor**。
2.  點擊 **New** \> **Expert Advisor (template)** \> 下一步 \> 命名為 `Google_Sync_Pro` \> 完成。
3.  刪除裡面所有代碼，複製並貼上以下 **MQL4 代碼**：

<!-- end list -->

```cpp
//+------------------------------------------------------------------+
//|             MT4 -> Google Sheets (Professional Version)          |
//|             Features: Auto-sync, Net Profit, Last Update Time    |
//+------------------------------------------------------------------+
#property strict

// --- Input Parameters ---
input string Google_URL    = "PASTE_YOUR_URL_HERE"; 
input int    Sync_Interval = 1800;  // Update interval in seconds (1800 = 30 mins)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // 1. Execute synchronization immediately upon startup
   OnTimer();
   
   // 2. Set timer for subsequent updates
   EventSetTimer(Sync_Interval);
   
   Print("System started. Sync interval set to: ", Sync_Interval, " seconds.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer function (Main Logic)                                      |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Check if URL is valid
   if(StringFind(Google_URL, "http") == -1)
   {
      Print("Error: Invalid URL. Please check 'Google_URL' in Expert Inputs.");
      return;
   }

   // --- Step 1: Send Clear Command ---
   // Append command to URL parameters for GAS compatibility
   string url_clear = Google_URL + "?ticket=CLEAR_ALL_DATA_PLEASE";
   char post_dummy[], res_data[]; string headers;
   
   // Send request to clear old data
   WebRequest("POST", url_clear, NULL, 5000, post_dummy, res_data, headers);
   
   // If no open orders, stop here
   if(OrdersTotal() == 0) 
   { 
      Print("No open orders. Sheet cleared."); 
      return; 
   }
   
   // --- Step 2: Build Data Payload ---
   string payload = "";
   // Get local system time for the 'Last Update' column
   string update_time = TimeToString(TimeLocal(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         int d = (int)MarketInfo(OrderSymbol(), MODE_DIGITS);
         
         string type = (OrderType() == OP_BUY) ? "BUY" : "SELL";
         if(OrderType() > 1) type = "PENDING"; 
         
         // Construct data line (Tab-separated)
         // Fields: Ticket | Symbol | Type | Lots | OpenPrice | CurrentPrice | NetProfit | OpenTime | LastUpdate
         string line = 
            (string)OrderTicket() + "\t" +
            OrderSymbol() + "\t" +
            type + "\t" +
            DoubleToString(OrderLots(), 2) + "\t" +
            DoubleToString(OrderOpenPrice(), d) + "\t" +
            DoubleToString(OrderClosePrice(), d) + "\t" +     // Current Price (ClosePrice for open orders)
            DoubleToString(OrderProfit() + OrderSwap() + OrderCommission(), 2) + "\t" + // Net Profit (Profit+Swap+Comm)
            TimeToString(OrderOpenTime(), TIME_DATE|TIME_MINUTES|TIME_SECONDS) + "\t" +
            update_time; // Stamp current time on every row
            
         payload += line + "\n";
      }
   }
   
   // --- Step 3: Send Data to Google Sheet ---
   char post_data[];
   StringToCharArray(payload, post_data, 0, WHOLE_ARRAY, CP_UTF8);
   
   int res = WebRequest("POST", Google_URL, NULL, 10000, post_data, res_data, headers);
   
   if(res != 200) 
      Print("Sync failed. Error Code: ", res);
   else 
      Print("Success! Updated ", OrdersTotal(), " orders. (Timestamp: ", update_time, ")");
}
```

4.  點擊上方 **Compile (編寫)** 按鈕，確保沒有錯誤 (0 Errors)。

### 2\. 啟動 EA

1.  回到 MT4 主介面，在左側導航欄 (Navigator) 找到 `Google_Sync_Pro`。
2.  將它拖曳到任意一個圖表上。
3.  在彈出的視窗中：
      * **一般 (Common)** 分頁：勾選 **允許實時交易 (Allow live trading)** (雖然此 EA 不下單，但這是讓 EA 運作的開關)。
      * **輸入參數 (Inputs)** 分頁：找到 `Google_URL` 欄位，**貼上你在第一部分複製的 Google Apps Script 網址**。
4.  點擊 **確定 (OK)**。

-----

## 第四部分：驗證與監控

1.  **查看 MT4 記錄：** 點擊下方終端機的 **智能交易系統 (Experts)** 分頁。你應該會看到類似 `Success! Updated X orders.` 的訊息。
2.  **查看 Google Sheet：** 你的持倉單應該已經出現在表格中，並且最後一欄 `Last Update` 會顯示電腦當前的時間。

### 💡 常見問題 FAQ

  * **Q: 為什麼顯示 Error 4060？**
      * A: 你忘記在 MT4 選項中添加 `https://script.google.com` 到白名單了。
  * **Q: 為什麼 Google Sheet 只有標題沒有數據？**
      * A: 請檢查你的 `Google_URL` 是否完整複製，並且 Apps Script 的部署權限是否設為「任何人」(Anyone)。
  * **Q: 我更新了 GAS 代碼，為什麼還是舊的？**
      * A: GAS 更新後必須按 **部署 (Deploy)** \> **管理部署 (Manage deployments)** \> **編輯 (鉛筆)** \> **新版本 (New version)** \> **部署**，才會生效。

<!-- end list -->