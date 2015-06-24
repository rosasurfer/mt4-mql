/**
 * Funktionen zur Verwaltung von Dateien im "history"-Verzeichnis.
 */
#import "history.ex4"

   int      HistorySet.Create      (string symbol, string description, int digits);
   int      HistorySet.FindBySymbol(string symbol);
   bool     HistorySet.AddTick     (int hSet, datetime time, double value, int flags=NULL);
   bool     HistorySet.Reset       (int hSet);

   int      HistoryFile.Open           (string symbol, string description, int digits, int timeframe, int mode);
   bool     HistoryFile.Close          (int hFile);
   int      HistoryFile.FindBar        (int hFile, datetime time, bool lpBarExists[]);
   bool     HistoryFile.ReadBar        (int hFile, int offset, datetime time[], double data[]);
   bool     HistoryFile.InsertBar      (int hFile, int offset, datetime time, double data[], int flags=NULL);
   bool     HistoryFile.UpdateBar      (int hFile, int offset, double value);
   bool     HistoryFile.WriteBar       (int hFile, int offset, datetime time, double data[], int flags=NULL);
   bool     HistoryFile.WriteCurrentBar(int hFile, int flags=NULL);
   bool     HistoryFile.WriteTickBar   (int hFile, int flags=NULL);
   bool     HistoryFile.MoveBars       (int hFile, int startOffset, int destOffset);
   bool     HistoryFile.AddTick        (int hFile, datetime time, double value, int flags=NULL);

   string   hf.Name         (int hFile);
   bool     hf.Read         (int hFile);
   bool     hf.Write        (int hFile);
   int      hf.Size         (int hFile);
   int      hf.Bars         (int hFile);
   datetime hf.From         (int hFile);
   datetime hf.To           (int hFile);
   int      hf.Header       (int hFile, int array[]);
   int      hf.Version      (int hFile);
   string   hf.Symbol       (int hFile);
   string   hf.Description  (int hFile);
   int      hf.Period       (int hFile);
   int      hf.Digits       (int hFile);
   int      hf.DbVersion    (int hFile);
   int      hf.PrevDbVersion(int hFile);


   // Library-Management
   bool     history.CloseFiles(bool warn=false);
   int      history.GetLastError();

#import
