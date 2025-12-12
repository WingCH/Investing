//+------------------------------------------------------------------+
//|                                                 AI_ScreenShot.mq4|
//|                                                       Gemini AI  |
//|                                                                  |
//| DESCRIPTION:                                                     |
//| 1. Targeted Screenshot: Captures the LEFT side (Panel Area).     |
//| 2. Size: 500x700 pixels (Configurable).                          |
//| 3. Alignment: ALIGN_LEFT (Crucial for panels on the left side).  |
//| 4. Target EA: Strictly looks for "JT EA".                        |
//| 5. Output: MQL4/Files/AI_Snapshots/YYYY.MM.DD_HH-MM/             |
//+------------------------------------------------------------------+
#property copyright "Gemini AI"
#property link      "https://www.google.com"
#property version   "1.11"
#property strict
#property show_inputs 

// --- Import Windows System Function ---
#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

// --- Settings ---
string Target_EA_Name = "JT EA";   // Hardcoded EA Name

// ★ Updated Size for Panel
input int ImageWidth  = 500;  // Width
input int ImageHeight = 700;  // Height

// --- Global Arrays ---
string processedSymbols[]; 
int    symbolCounts[];     

void OnStart()
{
   // 1. Setup Folder Paths
   string parentFolder = "AI_Snapshots";
   string timeSubFolder = TimeToString(TimeLocal(), TIME_DATE|TIME_MINUTES);
   StringReplace(timeSubFolder, ":", "-"); 
   StringReplace(timeSubFolder, " ", "_"); 
   string finalPath = parentFolder + "\\" + timeSubFolder;

   long currChart = ChartFirst(); 
   int totalCount = 0;
   int skippedCount = 0;

   ArrayResize(processedSymbols, 0);
   ArrayResize(symbolCounts, 0);

   Print("--- Start Task: Capturing LEFT Panel (500x700) for [" + Target_EA_Name + "] ---");

   while(currChart != -1) 
   {
      string symbol = ChartSymbol(currChart);
      string attachedEA = ChartGetString(currChart, CHART_EXPERT_NAME);
      
      // Filter: Only process if "JT EA" is attached
      if(attachedEA != Target_EA_Name)
      {
         Print("Skipped: " + symbol + " (EA is: " + (attachedEA=="" ? "None" : attachedEA) + ")");
         skippedCount++;
         currChart = ChartNext(currChart); 
         continue; 
      }

      // Auto-Numbering Logic
      int index = -1;
      for(int i = 0; i < ArraySize(processedSymbols); i++) {
         if(processedSymbols[i] == symbol) { index = i; break; }
      }

      int currentCount = 1;
      if(index == -1) {
         int newSize = ArraySize(processedSymbols) + 1;
         ArrayResize(processedSymbols, newSize);
         ArrayResize(symbolCounts, newSize);
         processedSymbols[newSize - 1] = symbol;
         symbolCounts[newSize - 1] = 1;
         currentCount = 1;
      } else {
         symbolCounts[index]++;
         currentCount = symbolCounts[index];
      }

      // Filename
      string filename = finalPath + "\\" + symbol + "_" + IntegerToString(currentCount) + ".png";

      // --- Capture Logic (CHANGED TO LEFT) ---
      // Uses ALIGN_LEFT to capture the leftmost pixels (where your panel is)
      if(ChartScreenShot(currChart, filename, ImageWidth, ImageHeight, ALIGN_LEFT)) {
         totalCount++;
         Print("Captured Left Panel: " + symbol);
      } else {
         Print("Failed: " + symbol);
      }

      currChart = ChartNext(currChart); 
   }
   
   // Completion Message
   if(totalCount == 0) {
      MessageBox("No charts found running '" + Target_EA_Name + "'!", "Task Failed");
   }
   else {
      string msg = "Captured: " + IntegerToString(totalCount) + " Left Panels (500x700).\n";
      msg += "Saved to: " + finalPath + "\n\n";
      msg += "Open folder now?";
      
      if(MessageBox(msg, "Task Completed", MB_YESNO | MB_ICONQUESTION) == IDYES) {
         string dataPath = TerminalInfoString(TERMINAL_DATA_PATH);
         string fullPath = dataPath + "\\MQL4\\Files\\" + finalPath;
         ShellExecuteW(0, "open", fullPath, "", "", 1);
      }
   }
}
//+------------------------------------------------------------------+