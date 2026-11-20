//+------------------------------------------------------------------+
//|                                           GrafikTabranij_ICT.mq5 |
//|                                       GUBUK SALDO Copyright 2026 |
//|                                          https://cindo.pages.dev |
//|  Gabungan: EA GT Pesaldo v0.01 + indikator ICT_SMC_CRT v1.01     |
//|  Mesin ICT/SMC/CRT ditanam langsung di dalam EA (satu file).     |
//+------------------------------------------------------------------+
#property copyright   "GUBUK SALDO (c) 2026"
#property link        "https://cindo.pages.dev"
#property version     "0.02"
#property description "EA GT Pesaldo + ICT/SMC/CRT - Komando Profit & Keamanan"
#property description "========================================================"
#property description "Mode 1: Sekuensial Martingale berbasis candle GT Besar (v0.01)."
#property description "Mode 2: Entry dari sinyal ICT + SMC + CRT (SL/TP dari sinyal)."
#property description "Bukan jaminan profit. Uji di akun demo / Strategy Tester dulu."

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Enum & Types                                                     |
//+------------------------------------------------------------------+
enum ENUM_THEME
{
    THEME_ONYX_GOLD,   // Classic Onyx & Gold
    THEME_NEON_BLUE,   // Cyberpunk Cyan
    THEME_MATRIX,      // Retro Green
    THEME_PURE_DARK    // Minimalist Grey
};

enum ENUM_TRADE_MODE
{
    MODE_SEQUENTIAL = 0,  // Sekuensial Martingale (EA v0.01)
    MODE_ICT        = 1   // Sinyal ICT + SMC + CRT
};

enum ENUM_BIAS_MODE
{
   BIAS_CRT_ONLY     = 0,  // CRT saja
   BIAS_HTF_ONLY     = 1,  // Struktur HTF saja
   BIAS_CRT_THEN_HTF = 2,  // CRT dulu, jika tidak ada pakai struktur HTF
   BIAS_BOTH         = 3   // CRT dan struktur HTF harus searah
};

enum ENUM_TP_MODE
{
   TP_LIQUIDITY = 0,       // Likuiditas sisi berlawanan
   TP_CRT50     = 1,       // 50% range CRT
   TP_RR        = 2        // Kelipatan RR
};

//+------------------------------------------------------------------+
//| Input Parameters - EA                                            |
//+------------------------------------------------------------------+

//--- System Information
input string          _s0                  = "================= EA GT TRADING ================="; 
sinput string         Info_System          = "EA GT Pengepul Saldo Dolar + ICT/SMC/CRT"; 
sinput string         Info_Version         = "v0.02 [Gubuk Saldo]"; 
sinput string         Info_Author          = "MOCHAMAD TABRANI";                  
sinput string         Info_Support         = "t.me/jackmusk";   

//--- Dashboard Layout
input string          _s1                  = "================= DASHBOARD GEOMETRY =================";
input int             X_Offset             = 20;       // Horizontal Offset (Pixels)
input int             Y_Offset             = 40;       // Vertical Offset (Pixels)
input int             Panel_Width          = 600;      // Total Dashboard Width

//--- Trading Engine Settings
input string          _s2                  = "================= GRAFIK TABRANIJ ALGO STRATEGY =================";
input ENUM_TRADE_MODE InpMode              = MODE_ICT;      // Mode Trading
input ENUM_TIMEFRAMES InpGTTimeframe       = PERIOD_H1;     // GT Besar Timeframe/durasi (Signal Basis)
input double          InpLot               = 0.01;          // Base Lot Volume
input double          InpMultiplier        = 2.0;           // Martingale Volume Multiplier (mode Sekuensial)
input int             InpMaxSteps          = 5;             // Max Martingale Iterations (mode Sekuensial)
input int             InpTP                = 300;           // Take Profit Distance (Points) - mode Sekuensial
input int             InpSL                = 150;           // Stop Loss Distance (Points) - mode Sekuensial
input int             InpMagic             = 888999;        // Algorithm Serial ID

//--- Pengaturan khusus mode ICT
input string          _s2b                 = "================= MODE ICT: EKSEKUSI =================";
input double          InpIctRiskPct        = 0.0;           // Risiko per trade (% equity), 0 = pakai Base Lot
input int             InpMaxSpreadPts      = 0;             // Max spread (points) untuk entry ICT, 0 = off
input bool            InpIctDraw           = true;          // Gambar objek ICT/SMC/CRT di chart

//--- Theme & Color Settings
input string          _s5                  = "================= UI THEME & PALETTE =================";
input ENUM_THEME      InpTheme             = THEME_ONYX_GOLD;   // Active Visual Theme
input color           Label_Color          = clrGold;           // Primary Label Color
input color           Value_Color          = clrWhite;          // Numerical Value Color
input color           Live_Color           = C'255,225,100';    // Real-time Accent Color

//--- Chart Visualization
input string          _s6                  = "================= CHART VISUALIZATION =================";
input bool            InpShowGTChart       = true;              // Plot GT Mathematical Levels
input int             InpLevelWidth        = 1;                 // Level Line Thickness
input ENUM_LINE_STYLE InpLevelStyle        = STYLE_SOLID;       // Level Line Pattern
input bool            InpShowLabels        = true;              // Display Level Descriptions

//+------------------------------------------------------------------+
//| Input Parameters - ICT / SMC / CRT (dari indikator)              |
//+------------------------------------------------------------------+
input group "=== ICT: UMUM ==="
input int    InpMaxBars        = 1500;   // Jumlah bar yang dianalisis
input int    InpAtrPeriod      = 14;     // Periode ATR
input int    InpExtendBars     = 15;     // Perpanjangan objek ke kanan (bar)
input bool   InpShowPanel      = true;   // Tampilkan panel info ICT (di kanan dashboard)
input int    InpMaxSigDraw     = 5;      // Jumlah sinyal terakhir yang digambar SL/TP-nya
input bool   InpAntiOverlap    = true;   // Cegah teks/label bertumpuk
input int    InpLabelGap       = 2;      // Jarak antar label (piksel)

input group "=== STRUKTUR PASAR (SMC) ==="
input bool   InpShowSwing      = true;   // Tampilkan BOS/CHoCH swing (struktur besar)
input int    InpSwingLen       = 10;     // Panjang swing (candle kiri-kanan)
input bool   InpShowInternal   = true;   // Tampilkan BOS/CHoCH internal (struktur kecil)
input int    InpIntLen         = 3;      // Panjang swing internal
input int    InpMicroLen       = 2;      // Panjang micro-pivot (EQH/EQL dan IDM)
input bool   InpShowEQ         = true;   // Tampilkan EQH/EQL
input double InpEqTolATR       = 0.10;   // Toleransi EQH/EQL (x ATR)
input bool   InpShowSweep      = true;   // Tampilkan liquidity sweep
input bool   InpShowIDM        = true;   // Tampilkan inducement (IDM)
input bool   InpShowStrongWeak = true;   // Tampilkan Strong/Weak High-Low
input int    InpMaxEvents      = 15;     // Maks BOS/CHoCH yang digambar per jenis
input color  InpColStrBull     = clrLimeGreen; // Warna struktur bullish
input color  InpColStrBear     = clrRed;       // Warna struktur bearish

input group "=== ZONA (ICT / SMC) ==="
input bool   InpShowOB         = true;   // Order Block
input bool   InpShowFVG        = true;   // Fair Value Gap
input bool   InpShowBreaker    = true;   // Breaker Block
input bool   InpShowMitig      = true;   // Mitigation Block
input bool   InpShowIFVG       = true;   // Inversion FVG (IFVG)
input bool   InpShowVI         = true;   // Volume Imbalance
input bool   InpShowVoid       = true;   // Liquidity Void
input double InpFvgMinATR      = 0.10;   // Ukuran minimum FVG/VI (x ATR)
input double InpVoidATR        = 2.0;    // Body minimum Liquidity Void (x ATR)
input bool   InpShowMitigated  = false;  // Tampilkan juga zona yang sudah termitigasi
input bool   InpFillZones      = true;   // Isi warna zona
input int    InpMaxZones       = 6;      // Maks zona aktif digambar per jenis
input color  InpColBullOB      = clrSteelBlue;      // Warna OB bullish
input color  InpColBearOB      = clrIndianRed;      // Warna OB bearish
input color  InpColBullFVG     = clrMediumSeaGreen; // Warna FVG bullish
input color  InpColBearFVG     = clrLightCoral;     // Warna FVG bearish
input color  InpColBreaker     = clrGoldenrod;      // Warna Breaker
input color  InpColMitig       = clrOrchid;         // Warna Mitigation Block

input group "=== MULTI-TIMEFRAME (zona HTF di chart kecil) ==="
input bool            InpShowHtfZones   = true;       // Tampilkan OB/FVG/Breaker dari HTF
input ENUM_TIMEFRAMES InpHtf            = PERIOD_H4;  // Timeframe HTF (bias struktur dan zona)
input int             InpHtfSwingLen    = 5;          // Panjang swing HTF
input int             InpHtfMaxZones    = 3;          // Maks zona HTF per jenis

input group "=== CRT (Candle Range Theory) ==="
input bool            InpShowCRT   = true;       // Tampilkan kotak CRT
input ENUM_TIMEFRAMES InpCrtTF     = PERIOD_H4;  // Timeframe candle acuan CRT
input int             InpCrtValid  = 3;          // CRT berlaku berapa candle HTF setelah C2 close
input int             InpCrtBoxes  = 3;          // Jumlah kotak CRT terakhir yang digambar

input group "=== ICT: PD ARRAY, OTE, LIKUIDITAS ==="
input bool   InpShowPD         = true;   // Premium / Discount / Equilibrium
input bool   InpShowOTE        = true;   // Optimal Trade Entry 62%-79%
input bool   InpShowLiq        = true;   // PDH/PDL dan PWH/PWL

input group "=== ICT: KILLZONE & SILVER BULLET (jam GMT) ==="
input bool   InpShowKZ         = true;   // Gambar kotak sesi/killzone
input int    InpKzDays         = 3;      // Berapa hari ke belakang yang digambar
input int    InpGmtOffset      = 0;      // Selisih jam server broker terhadap GMT (contoh: 2 atau 3)
input bool   InpKzAsia         = true;   // Asia
input int    InpAsiaS          = 1;      // Asia mulai (jam GMT)
input int    InpAsiaE          = 5;      // Asia selesai (jam GMT)
input bool   InpKzLondon       = true;   // London
input int    InpLondonS        = 7;      // London mulai
input int    InpLondonE        = 10;     // London selesai
input bool   InpKzNYAM         = true;   // New York AM
input int    InpNYAMS          = 12;     // NY AM mulai
input int    InpNYAME          = 15;     // NY AM selesai
input bool   InpKzLC           = false;  // London Close
input int    InpLCS            = 15;     // London Close mulai
input int    InpLCE            = 17;     // London Close selesai
input bool   InpKzSB           = false;  // Silver Bullet (3 jendela 1 jam)
input int    InpSB1            = 8;      // Silver Bullet 1 mulai (jam GMT)
input int    InpSB2            = 15;     // Silver Bullet 2 mulai
input int    InpSB3            = 19;     // Silver Bullet 3 mulai

input group "=== SINYAL ICT ==="
input ENUM_BIAS_MODE InpBiasMode = BIAS_CRT_THEN_HTF; // Sumber bias
input bool   InpReqSweep       = true;   // Wajib ada liquidity sweep
input bool   InpReqIDM         = false;  // Wajib ada inducement tersapu
input bool   InpReqPD          = true;   // Entri hanya di discount (buy) / premium (sell)
input bool   InpReqKZ          = false;  // Entri hanya di dalam killzone yang aktif
input int    InpSetupBars      = 40;     // Jendela setup: sweep -> BOS/CHoCH (bar)
input int    InpArmExpire      = 100;    // Zona kedaluwarsa setelah n bar
input bool   InpEntryOB        = true;   // Boleh entri di Order Block
input bool   InpEntryFVG       = true;   // Boleh entri di FVG
input bool   InpEntryMitig     = true;   // Boleh entri di Mitigation Block
input bool   InpEntryBreaker   = true;   // Boleh entri di Breaker Block
input double InpSlBufATR       = 0.20;   // Buffer SL (x ATR)
input ENUM_TP_MODE InpTpMode   = TP_LIQUIDITY; // Mode TP
input double InpRR             = 2.0;    // RR cadangan / mode RR
input double InpMinRR          = 1.0;    // RR minimum agar sinyal valid

input group "=== ALERT ==="
input bool   InpAlertPopup     = true;   // Alert popup
input bool   InpAlertPush      = false;  // Push notification
input bool   InpAlertMail      = false;  // Email

//+------------------------------------------------------------------+
//| [2] Global Variables & Konstanta (EA)                            |
//+------------------------------------------------------------------+
double   myPoint;
int      myDigits;
datetime lastBarTime = 0;
CTrade   trade;

// Sequential State Machine (mode Sekuensial)
double   g_lastLot      = 0;  // Volume dari posisi terakhir yang ditutup
int      g_lastDeal      = -1; // Ticket deal terakhir yang telah diproses
bool     g_isFirstTrade = true; // Flag untuk perdagangan pertama

// Status mode ICT
bool     g_ictReady      = false;   // Analisis ICT terakhir berhasil
datetime g_ictAttemptBar = 0;       // Bar terakhir yang sudah dicoba entry

#define PREFIX          "GRAFIK TABRANIJ"
#define COLOR_BG        C'45,45,45'    // Charcoal Grey
#define COLOR_STRIPE    C'35,35,35'    // Darker Grey for stripes
#define COLOR_HDR_BG    C'65,65,65'    // Lighter Slate Grey for headers
#define COLOR_SUCCESS   C'0,255,140'   // Emerald
#define COLOR_DANGER    C'255,80,90'   // Ruby
#define COLOR_SILVER    C'180,180,180' // Muted Silver
#define COLOR_BORDER    C'85,85,85'    // Silver/Grey for borders

#define ROW_H           30
#define FONT_MAIN       "Segoe UI"
#define FONT_SIZE       10
#define COLOR_COUNTDOWN C'255,200,50'   // Amber Gold (Countdown)
#define VIS_PREFIX      "GT_VIS_"

// Global State for UI Tabs
enum ENUM_TABS {
    TAB_DASHBOARD,
    TAB_ABOUT,
    TAB_TRADING,
    TAB_COLORS,
    TAB_VISUAL
};
ENUM_TABS currTab = TAB_DASHBOARD;

// Global Color Theme Variables
color gClrBg, gClrHdr, gClrStripe, gClrLabel, gClrValue, gClrAccent, gClrSuccess, gClrDanger, gClrBorder;

// Runtime Modifiable Settings (Mirrored from Inputs)
ENUM_THEME   extTheme;
bool         extShowGTChart;

// Wall-clock synchronization
long         serverLocalOffset = 0;

//+------------------------------------------------------------------+
//| Konstanta & struct mesin ICT/SMC/CRT                             |
//+------------------------------------------------------------------+
#define PFX     "ICS_"

#define Z_OB    0
#define Z_FVG   1
#define Z_BRK   2
#define Z_MIT   3
#define Z_IFVG  4
#define Z_VI    5
#define Z_VOID  6

#define L_BOS   0
#define L_CHOCH 1
#define L_EQ    2
#define L_IDM   3
#define L_SWEEP 4

struct SStruct
  {
   int    len;
   double shP;
   double shPrev;
   int    shI;
   int    shPrevI;
   bool   shCross;
   bool   shSwept;
   double slP;
   double slPrev;
   int    slI;
   int    slPrevI;
   bool   slCross;
   bool   slSwept;
   int    trend;
  };

struct SZone
  {
   int    type;
   int    dir;
   int    bar0;
   int    created;
   int    armBar;
   int    mitBar;
   double top;
   double bottom;
   double sweepExt;
   bool   mitigated;
   bool   armed;
   bool   used;
  };

struct SLine
  {
   int    kind;
   int    dir;
   bool   isInt;
   int    bar0;
   int    bar1;
   double price;
  };

struct SCrt
  {
   datetime tC1;
   datetime tConf;
   double   h1;
   double   l1;
   double   ext;
   int      dir;
   bool     dead;
  };

struct SSig
  {
   int    bar;
   int    dir;
   double entry;
   double sl;
   double tp;
  };

//+------------------------------------------------------------------+
//| Sesi / killzone                                                  |
//+------------------------------------------------------------------+
string g_sName[7] = {"Asia","London","NY AM","London Close","SB 1","SB 2","SB 3"};
bool   g_sOn[7];
int    g_sH1[7];
int    g_sH2[7];
color  g_sCol[7];

void SetupSessions()
  {
   g_sOn[0]=InpKzAsia;   g_sH1[0]=InpAsiaS;   g_sH2[0]=InpAsiaE;   g_sCol[0]=clrMediumPurple;
   g_sOn[1]=InpKzLondon; g_sH1[1]=InpLondonS; g_sH2[1]=InpLondonE; g_sCol[1]=clrDodgerBlue;
   g_sOn[2]=InpKzNYAM;   g_sH1[2]=InpNYAMS;   g_sH2[2]=InpNYAME;   g_sCol[2]=clrTomato;
   g_sOn[3]=InpKzLC;     g_sH1[3]=InpLCS;     g_sH2[3]=InpLCE;     g_sCol[3]=clrSienna;
   g_sOn[4]=InpKzSB;     g_sH1[4]=InpSB1;     g_sH2[4]=(InpSB1+1)%24; g_sCol[4]=clrTeal;
   g_sOn[5]=InpKzSB;     g_sH1[5]=InpSB2;     g_sH2[5]=(InpSB2+1)%24; g_sCol[5]=clrTeal;
   g_sOn[6]=InpKzSB;     g_sH1[6]=InpSB3;     g_sH2[6]=(InpSB3+1)%24; g_sCol[6]=clrTeal;
  }

bool InSession(int s,datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t,dt);
   int h=((dt.hour-InpGmtOffset)%24+24)%24;
   int a=g_sH1[s];
   int b=g_sH2[s];
   if(a==b)
      return false;
   if(a<b)
      return (h>=a && h<b);
   return (h>=a || h<b);
  }

bool InKillzone(datetime t)
  {
   bool any=false;
   for(int s=0;s<7;s++)
     {
      if(!g_sOn[s])
         continue;
      any=true;
      if(InSession(s,t))
         return true;
     }
   return (!any);
  }

double PrevLevel(datetime t,ENUM_TIMEFRAMES tf,bool high)
  {
   int sh=iBarShift(_Symbol,tf,t,false);
   if(sh<0)
      return 0.0;
   if(high)
      return iHigh(_Symbol,tf,sh+1);
   return iLow(_Symbol,tf,sh+1);
  }

string TfName(ENUM_TIMEFRAMES tf)
  {
   string s=EnumToString(tf);
   StringReplace(s,"PERIOD_","");
   return s;
  }

//+------------------------------------------------------------------+
//| Mesin analisis                                                   |
//+------------------------------------------------------------------+
class CSmc
  {
public:
   ENUM_TIMEFRAMES m_tf;
   ENUM_TIMEFRAMES m_crtTf;
   bool     m_main;
   int      m_n;
   MqlRates m_r[];
   double   m_atr[];
   SStruct  m_sw;
   SStruct  m_in;
   SStruct  m_mi;
   SZone    m_z[];
   int      m_zn;
   SLine    m_l[];
   int      m_ln;
   int      m_trSw[];
   int      m_htfTr[];
   SCrt     m_crt[];
   int      m_crtN;
   int      m_crtPtr;
   int      m_crtCur;
   bool     m_crtOn;
   int      m_crtDir;
   double   m_buy[];
   double   m_sell[];
   double   m_buySL[];
   double   m_buyTP[];
   double   m_sellSL[];
   double   m_sellTP[];
   double   m_bias[];
   SSig     m_sg[];
   int      m_sgN;
   int      m_sweepBullBar;
   int      m_sweepBearBar;
   double   m_sweepBullExt;
   double   m_sweepBearExt;
   int      m_brkBullBar;
   int      m_brkBearBar;
   int      m_idmBullBar;
   int      m_idmBearBar;
   double   m_idmLowP;
   double   m_idmHighP;
   int      m_idmLowI;
   int      m_idmHighI;
   bool     m_idmLowTk;
   bool     m_idmHighTk;
   int      m_biasNow;
   int      m_biasSrc;

   //--- memuat data
   bool Load(ENUM_TIMEFRAMES tf,int cnt)
     {
      m_tf=tf;
      ArraySetAsSeries(m_r,false);
      int got=CopyRates(_Symbol,tf,0,cnt,m_r);
      if(got<50)
         return false;
      m_n=got;
      return true;
     }

   void CalcATR(int per)
     {
      double trv[];
      ArrayResize(trv,m_n);
      ArrayResize(m_atr,m_n);
      double sum=0.0;
      for(int i=0;i<m_n;i++)
        {
         double tr=m_r[i].high-m_r[i].low;
         if(i>0)
           {
            double a=MathAbs(m_r[i].high-m_r[i-1].close);
            double b=MathAbs(m_r[i].low-m_r[i-1].close);
            tr=MathMax(tr,MathMax(a,b));
           }
         trv[i]=tr;
         sum+=tr;
         if(i>=per)
            sum-=trv[i-per];
         int c=(i+1<per)?(i+1):per;
         m_atr[i]=sum/c;
        }
     }

   void ResetStruct(SStruct &s,int len)
     {
      s.len=len;
      s.shP=0.0; s.shPrev=0.0; s.shI=-1; s.shPrevI=-1; s.shCross=true; s.shSwept=true;
      s.slP=0.0; s.slPrev=0.0; s.slI=-1; s.slPrevI=-1; s.slCross=true; s.slSwept=true;
      s.trend=0;
     }

   bool IsPivotHigh(int p,int len)
     {
      double h=m_r[p].high;
      for(int k=p-len;k<=p+len;k++)
        {
         if(k==p)
            continue;
         if(k<p)
           {
            if(m_r[k].high>h)
               return false;
           }
         else
           {
            if(m_r[k].high>=h)
               return false;
           }
        }
      return true;
     }

   bool IsPivotLow(int p,int len)
     {
      double l=m_r[p].low;
      for(int k=p-len;k<=p+len;k++)
        {
         if(k==p)
            continue;
         if(k<p)
           {
            if(m_r[k].low<l)
               return false;
           }
         else
           {
            if(m_r[k].low<=l)
               return false;
           }
        }
      return true;
     }

   void AddZone(int type,int dir,int bar0,double top,double bottom,int created)
     {
      if(type==Z_OB || type==Z_MIT)
        {
         for(int k=m_zn-1;k>=0 && k>=m_zn-80;k--)
           {
            if(m_z[k].type==type && m_z[k].dir==dir && m_z[k].bar0==bar0)
               return;
           }
        }
      if(m_zn>=ArraySize(m_z))
         ArrayResize(m_z,m_zn+256);
      m_z[m_zn].type=type;
      m_z[m_zn].dir=dir;
      m_z[m_zn].bar0=bar0;
      m_z[m_zn].created=created;
      m_z[m_zn].armBar=-1;
      m_z[m_zn].mitBar=-1;
      m_z[m_zn].top=top;
      m_z[m_zn].bottom=bottom;
      m_z[m_zn].sweepExt=0.0;
      m_z[m_zn].mitigated=false;
      m_z[m_zn].armed=false;
      m_z[m_zn].used=false;
      m_zn++;
     }

   void AddLine(int kind,int dir,bool isInt,int b0,int b1,double price)
     {
      if(m_ln>=ArraySize(m_l))
         ArrayResize(m_l,m_ln+256);
      m_l[m_ln].kind=kind;
      m_l[m_ln].dir=dir;
      m_l[m_ln].isInt=isInt;
      m_l[m_ln].bar0=b0;
      m_l[m_ln].bar1=b1;
      m_l[m_ln].price=price;
      m_ln++;
     }

   void AddSig(int bar,int dir,double entry,double sl,double tp)
     {
      if(m_sgN>=ArraySize(m_sg))
         ArrayResize(m_sg,m_sgN+64);
      m_sg[m_sgN].bar=bar;
      m_sg[m_sgN].dir=dir;
      m_sg[m_sgN].entry=entry;
      m_sg[m_sgN].sl=sl;
      m_sg[m_sgN].tp=tp;
      m_sgN++;
     }

   //--- break struktur: buat garis, OB dan Mitigation Block
   void OnBreak(SStruct &s,int i,int dir,bool choch,bool isInt)
     {
      int from=(dir>0)?s.shI:s.slI;
      double lvl=(dir>0)?s.shP:s.slP;
      AddLine(choch?L_CHOCH:L_BOS,dir,isInt,from,i,lvl);
      if(dir>0)
         m_brkBullBar=i;
      else
         m_brkBearBar=i;

      //--- Order Block: candle ekstrem pada leg impuls, lalu cari candle berlawanan terdekat
      int m=-1;
      if(dir>0)
        {
         double mn=DBL_MAX;
         for(int k=from;k<=i;k++)
            if(m_r[k].low<mn){ mn=m_r[k].low; m=k; }
        }
      else
        {
         double mx=-DBL_MAX;
         for(int k=from;k<=i;k++)
            if(m_r[k].high>mx){ mx=m_r[k].high; m=k; }
        }
      if(m>=0)
        {
         int ob=m;
         for(int k=m;k>=MathMax(0,m-3);k--)
           {
            bool opp=(dir>0)?(m_r[k].close<m_r[k].open):(m_r[k].close>m_r[k].open);
            if(opp){ ob=k; break; }
           }
         AddZone(Z_OB,dir,ob,m_r[ob].high,m_r[ob].low,i);
        }

      //--- Mitigation Block: CHoCH setelah swing gagal membuat ekstrem baru
      if(choch)
        {
         if(dir>0 && s.slPrevI>=0 && s.slI>=0 && s.slP>s.slPrev)
           {
            int c=s.slPrevI;
            for(int k=s.slPrevI;k>=MathMax(0,s.slPrevI-5);k--)
               if(m_r[k].close>m_r[k].open){ c=k; break; }
            AddZone(Z_MIT,1,c,m_r[c].high,m_r[c].low,i);
           }
         if(dir<0 && s.shPrevI>=0 && s.shI>=0 && s.shP<s.shPrev)
           {
            int c=s.shPrevI;
            for(int k=s.shPrevI;k>=MathMax(0,s.shPrevI-5);k--)
               if(m_r[k].close<m_r[k].open){ c=k; break; }
            AddZone(Z_MIT,-1,c,m_r[c].high,m_r[c].low,i);
           }
        }
     }

   //--- satu langkah struktur. mode: 0 swing, 1 internal, 2 micro (tanpa break)
   int StepStruct(SStruct &s,int i,int mode)
     {
      int fl=0;
      int p=i-s.len;
      if(p>=s.len)
        {
         if(IsPivotHigh(p,s.len))
           {
            s.shPrev=s.shP; s.shPrevI=s.shI;
            s.shP=m_r[p].high; s.shI=p;
            s.shCross=false; s.shSwept=false;
            fl|=1;
           }
         if(IsPivotLow(p,s.len))
           {
            s.slPrev=s.slP; s.slPrevI=s.slI;
            s.slP=m_r[p].low; s.slI=p;
            s.slCross=false; s.slSwept=false;
            fl|=2;
           }
        }
      if(mode<2)
        {
         double c=m_r[i].close;
         if(s.shI>=0 && !s.shCross && c>s.shP)
           {
            s.shCross=true;
            bool choch=(s.trend==-1);
            s.trend=1;
            OnBreak(s,i,1,choch,(mode==1));
           }
         if(s.slI>=0 && !s.slCross && c<s.slP)
           {
            s.slCross=true;
            bool choch=(s.trend==1);
            s.trend=-1;
            OnBreak(s,i,-1,choch,(mode==1));
           }
        }
      return fl;
     }

   void SweepStruct(SStruct &s,int i)
     {
      double h=m_r[i].high;
      double l=m_r[i].low;
      double c=m_r[i].close;
      if(s.shI>=0 && !s.shCross && !s.shSwept && h>s.shP && c<=s.shP)
        {
         s.shSwept=true;
         bool nw=(m_sweepBearBar!=i);
         m_sweepBearBar=i;
         m_sweepBearExt=(nw)?h:MathMax(m_sweepBearExt,h);
         if(nw)
            AddLine(L_SWEEP,-1,false,i,i,h);
        }
      if(s.slI>=0 && !s.slCross && !s.slSwept && l<s.slP && c>=s.slP)
        {
         s.slSwept=true;
         bool nw=(m_sweepBullBar!=i);
         m_sweepBullBar=i;
         m_sweepBullExt=(nw)?l:MathMin(m_sweepBullExt,l);
         if(nw)
            AddLine(L_SWEEP,1,false,i,i,l);
        }
     }

   //--- CRT
   bool BuildCrt(ENUM_TIMEFRAMES tf,int cnt)
     {
      m_crtTf=tf;
      m_crtN=0;
      m_crtPtr=0;
      m_crtCur=-1;
      ArrayResize(m_crt,0);
      MqlRates c[];
      ArraySetAsSeries(c,false);
      int got=CopyRates(_Symbol,tf,0,cnt,c);
      if(got<5)
         return false;
      int ps=PeriodSeconds(tf);
      for(int j=1;j<got-1;j++)
        {
         double h1=c[j-1].high;
         double l1=c[j-1].low;
         bool sweepH=(c[j].high>h1);
         bool sweepL=(c[j].low<l1);
         if(sweepH==sweepL)
            continue;
         SCrt e;
         e.tC1=c[j-1].time;
         e.tConf=c[j].time+ps;
         e.h1=h1;
         e.l1=l1;
         e.dead=false;
         if(sweepH && c[j].close<h1 && c[j].close>l1)
           {
            e.dir=-1;
            e.ext=c[j].high;
           }
         else if(sweepL && c[j].close>l1 && c[j].close<h1)
           {
            e.dir=1;
            e.ext=c[j].low;
           }
         else
            continue;
         ArrayResize(m_crt,m_crtN+1);
         m_crt[m_crtN]=e;
         m_crtN++;
        }
      return true;
     }

   void ClearHtf()
     {
      ArrayResize(m_htfTr,m_n);
      ArrayInitialize(m_htfTr,0);
     }

   void MapHtf(CSmc &h)
     {
      ArrayResize(m_htfTr,m_n);
      int ps=PeriodSeconds(h.m_tf);
      int j=-1;
      int lim=h.m_n-2;
      for(int i=0;i<m_n;i++)
        {
         datetime t=m_r[i].time;
         while(j+1<=lim && h.m_r[j+1].time+ps<=t)
            j++;
         m_htfTr[i]=(j>=0)?h.m_trSw[j]:0;
        }
     }

   void UpdateCrt(int i)
     {
      datetime t=m_r[i].time;
      while(m_crtPtr<m_crtN && m_crt[m_crtPtr].tConf<=t)
        {
         m_crtCur=m_crtPtr;
         if(m_crt[m_crtCur].dir>0)
           {
            m_sweepBullBar=i;
            m_sweepBullExt=m_crt[m_crtCur].ext;
           }
         else
           {
            m_sweepBearBar=i;
            m_sweepBearExt=m_crt[m_crtCur].ext;
           }
         m_crtPtr++;
        }
      m_crtOn=false;
      m_crtDir=0;
      if(m_crtCur>=0)
        {
         int ps=PeriodSeconds(m_crtTf);
         if(!m_crt[m_crtCur].dead)
           {
            double c=m_r[i].close;
            if(t>=m_crt[m_crtCur].tConf+InpCrtValid*ps)
               m_crt[m_crtCur].dead=true;
            if(m_crt[m_crtCur].dir>0 && (c<m_crt[m_crtCur].ext || m_r[i].high>=m_crt[m_crtCur].h1))
               m_crt[m_crtCur].dead=true;
            if(m_crt[m_crtCur].dir<0 && (c>m_crt[m_crtCur].ext || m_r[i].low<=m_crt[m_crtCur].l1))
               m_crt[m_crtCur].dead=true;
           }
         if(!m_crt[m_crtCur].dead)
           {
            m_crtOn=true;
            m_crtDir=m_crt[m_crtCur].dir;
           }
        }
     }

   int ComputeBias(int i,int &src)
     {
      int crt=m_crtOn?m_crtDir:0;
      int htf=(i<ArraySize(m_htfTr))?m_htfTr[i]:0;
      int b=0;
      src=0;
      if(InpBiasMode==BIAS_CRT_ONLY)
        {
         b=crt;
         src=(b!=0)?1:0;
        }
      else if(InpBiasMode==BIAS_HTF_ONLY)
        {
         b=htf;
         src=(b!=0)?2:0;
        }
      else if(InpBiasMode==BIAS_CRT_THEN_HTF)
        {
         if(crt!=0){ b=crt; src=1; }
         else if(htf!=0){ b=htf; src=2; }
        }
      else
        {
         if(crt!=0 && crt==htf){ b=crt; src=3; }
        }
      return b;
     }

   //--- zona
   void UpdateZones(int i)
     {
      double c=m_r[i].close;
      double h=m_r[i].high;
      double l=m_r[i].low;
      for(int k=0;k<m_zn;k++)
        {
         if(m_z[k].mitigated || m_z[k].created>=i)
            continue;
         int d=m_z[k].dir;
         int ty=m_z[k].type;
         bool closedThru=(d>0)?(c<m_z[k].bottom):(c>m_z[k].top);
         bool wickThru=(d>0)?(l<=m_z[k].bottom):(h>=m_z[k].top);
         if(ty==Z_OB)
           {
            if(closedThru)
              {
               m_z[k].type=Z_BRK;
               m_z[k].dir=-d;
               m_z[k].created=i;
               m_z[k].armed=false;
               m_z[k].used=false;
              }
           }
         else if(ty==Z_BRK || ty==Z_MIT || ty==Z_IFVG)
           {
            if(closedThru)
              {
               m_z[k].mitigated=true;
               m_z[k].mitBar=i;
               m_z[k].armed=false;
              }
           }
         else if(ty==Z_FVG)
           {
            if(closedThru)
              {
               if(InpShowIFVG)
                 {
                  m_z[k].type=Z_IFVG;
                  m_z[k].dir=-d;
                  m_z[k].created=i;
                  m_z[k].armed=false;
                  m_z[k].used=false;
                 }
               else
                 {
                  m_z[k].mitigated=true;
                  m_z[k].mitBar=i;
                  m_z[k].armed=false;
                 }
              }
            else if(wickThru)
              {
               m_z[k].mitigated=true;
               m_z[k].mitBar=i;
               m_z[k].armed=false;
              }
           }
         else if(ty==Z_VI)
           {
            if(wickThru)
              {
               m_z[k].mitigated=true;
               m_z[k].mitBar=i;
              }
           }
         else if(ty==Z_VOID)
           {
            double mid=(m_z[k].top+m_z[k].bottom)/2.0;
            bool fill=(d>0)?(l<=mid):(h>=mid);
            if(fill)
              {
               m_z[k].mitigated=true;
               m_z[k].mitBar=i;
              }
           }
        }
     }

   void DetectZones(int i)
     {
      double a=m_atr[i];
      if(i>=2)
        {
         if(m_r[i].low>m_r[i-2].high && (m_r[i].low-m_r[i-2].high)>=InpFvgMinATR*a)
            AddZone(Z_FVG,1,i-1,m_r[i].low,m_r[i-2].high,i);
         if(m_r[i].high<m_r[i-2].low && (m_r[i-2].low-m_r[i].high)>=InpFvgMinATR*a)
            AddZone(Z_FVG,-1,i-1,m_r[i-2].low,m_r[i].high,i);
        }
      if(i>=1)
        {
         double o=m_r[i].open;
         double c=m_r[i].close;
         double po=m_r[i-1].open;
         double pc=m_r[i-1].close;
         double minGap=MathMax(_Point,0.02*a);
         if(c>o && pc>po && (o-pc)>=minGap && m_r[i].low<=m_r[i-1].high)
            AddZone(Z_VI,1,i-1,o,pc,i);
         if(c<o && pc<po && (pc-o)>=minGap && m_r[i].high>=m_r[i-1].low)
            AddZone(Z_VI,-1,i-1,pc,o,i);
        }
      double body=MathAbs(m_r[i].close-m_r[i].open);
      if(a>0.0 && body>=InpVoidATR*a)
        {
         double t=MathMax(m_r[i].open,m_r[i].close);
         double b=MathMin(m_r[i].open,m_r[i].close);
         AddZone(Z_VOID,(m_r[i].close>m_r[i].open)?1:-1,i,t,b,i);
        }
     }

   //--- sinyal
   void ArmZones(int i,int d,int refBar,bool sw,double ext)
     {
      for(int k=0;k<m_zn;k++)
        {
         if(m_z[k].mitigated || m_z[k].used || m_z[k].armed)
            continue;
         if(m_z[k].dir!=d)
            continue;
         int ty=m_z[k].type;
         bool ok=(ty==Z_OB && InpEntryOB) || (ty==Z_FVG && InpEntryFVG) ||
                 (ty==Z_MIT && InpEntryMitig) || (ty==Z_BRK && InpEntryBreaker);
         if(!ok)
            continue;
         if(m_z[k].created<refBar)
            continue;
         m_z[k].armed=true;
         m_z[k].armBar=i;
         m_z[k].sweepExt=(sw)?ext:0.0;
        }
     }

   double PickTP(int i,int d,double entry,double risk)
     {
      if(InpTpMode==TP_RR)
         return entry+d*InpRR*risk;
      double minDist=InpMinRR*risk;
      if(InpTpMode==TP_CRT50 && m_crtOn && m_crtDir==d)
        {
         double mid=(m_crt[m_crtCur].h1+m_crt[m_crtCur].l1)/2.0;
         if(d*(mid-entry)>=minDist)
            return mid;
         double ex=(d>0)?m_crt[m_crtCur].h1:m_crt[m_crtCur].l1;
         if(d*(ex-entry)>=minDist)
            return ex;
        }
      double cand[6];
      int nc=0;
      datetime t=m_r[i].time;
      if(d>0)
        {
         if(m_in.shI>=0) cand[nc++]=m_in.shP;
         if(m_sw.shI>=0) cand[nc++]=m_sw.shP;
         if(m_crtOn && m_crtDir>0) cand[nc++]=m_crt[m_crtCur].h1;
         cand[nc++]=PrevLevel(t,PERIOD_D1,true);
         cand[nc++]=PrevLevel(t,PERIOD_W1,true);
        }
      else
        {
         if(m_in.slI>=0) cand[nc++]=m_in.slP;
         if(m_sw.slI>=0) cand[nc++]=m_sw.slP;
         if(m_crtOn && m_crtDir<0) cand[nc++]=m_crt[m_crtCur].l1;
         cand[nc++]=PrevLevel(t,PERIOD_D1,false);
         cand[nc++]=PrevLevel(t,PERIOD_W1,false);
        }
      double best=0.0;
      double bestDist=DBL_MAX;
      for(int k=0;k<nc;k++)
        {
         if(cand[k]<=0.0)
            continue;
         double dist=d*(cand[k]-entry);
         if(dist>=minDist && dist<bestDist)
           {
            bestDist=dist;
            best=cand[k];
           }
        }
      if(best>0.0)
         return best;
      return entry+d*InpRR*risk;
     }

   void Trigger(int i,int d,bool eqOk,double eq)
     {
      double atr=m_atr[i];
      for(int k=0;k<m_zn;k++)
        {
         if(!m_z[k].armed || m_z[k].used || m_z[k].mitigated || m_z[k].dir!=d)
            continue;
         if(i-m_z[k].armBar>InpArmExpire)
           {
            m_z[k].armed=false;
            continue;
           }
         if(i<=m_z[k].armBar)
            continue;
         double top=m_z[k].top;
         double bot=m_z[k].bottom;
         bool touch;
         if(d>0)
            touch=(m_r[i].low<=top && m_r[i].close>bot);
         else
            touch=(m_r[i].high>=bot && m_r[i].close<top);
         if(!touch)
            continue;
         if(InpReqKZ && !InKillzone(m_r[i].time))
            continue;
         if(InpReqPD && eqOk)
           {
            double mid=(top+bot)/2.0;
            if(d>0 && mid>=eq)
               continue;
            if(d<0 && mid<=eq)
               continue;
           }
         double entry=m_r[i].close;
         double sl;
         if(d>0)
           {
            sl=bot;
            if(m_z[k].sweepExt>0.0 && m_z[k].sweepExt<sl)
               sl=m_z[k].sweepExt;
            sl-=InpSlBufATR*atr;
           }
         else
           {
            sl=top;
            if(m_z[k].sweepExt>0.0 && m_z[k].sweepExt>sl)
               sl=m_z[k].sweepExt;
            sl+=InpSlBufATR*atr;
           }
         double risk=d*(entry-sl);
         if(risk<=0.0)
            continue;
         double tp=PickTP(i,d,entry,risk);
         double rr=d*(tp-entry)/risk;
         if(rr<InpMinRR)
            continue;
         if(d>0)
           {
            m_buy[i]=m_r[i].low-0.3*atr;
            m_buySL[i]=sl;
            m_buyTP[i]=tp;
           }
         else
           {
            m_sell[i]=m_r[i].high+0.3*atr;
            m_sellSL[i]=sl;
            m_sellTP[i]=tp;
           }
         AddSig(i,d,entry,sl,tp);
         m_z[k].used=true;
         m_z[k].armed=false;
         break;
        }
     }

   void CheckSignals(int i)
     {
      int src=0;
      int b=ComputeBias(i,src);
      m_bias[i]=b;
      if(b==0)
         return;
      bool eqOk=(m_sw.shI>=0 && m_sw.slI>=0 && m_sw.shP>m_sw.slP);
      double eq=eqOk?(m_sw.shP+m_sw.slP)/2.0:0.0;
      int d=b;
      int swBar=(d>0)?m_sweepBullBar:m_sweepBearBar;
      double swExt=(d>0)?m_sweepBullExt:m_sweepBearExt;
      int brkBar=(d>0)?m_brkBullBar:m_brkBearBar;
      int idmBar=(d>0)?m_idmBullBar:m_idmBearBar;
      bool sw=(swBar>=0 && i-swBar<=InpSetupBars);
      bool ok=true;
      if(InpReqSweep && !sw)
         ok=false;
      if(ok && InpReqIDM && !(idmBar>=0 && i-idmBar<=InpSetupBars))
         ok=false;
      int refBar=(sw)?swBar:(i-InpSetupBars);
      if(ok && !(brkBar>=0 && brkBar>=refBar && i-brkBar<=InpSetupBars))
         ok=false;
      if(ok)
         ArmZones(i,d,refBar,sw,swExt);
      Trigger(i,d,eqOk,eq);
     }

   //--- satu bar
   void Step(int i)
     {
      if(m_main)
         UpdateCrt(i);

      int f1=StepStruct(m_sw,i,0);
      int f2=StepStruct(m_in,i,1);
      int f3=StepStruct(m_mi,i,2);
      m_trSw[i]=m_sw.trend;

      //--- EQH / EQL dari micro-pivot
      if((f3&1)!=0 && m_mi.shPrevI>=0 && (m_mi.shI-m_mi.shPrevI)<=100)
        {
         if(MathAbs(m_mi.shP-m_mi.shPrev)<=InpEqTolATR*m_atr[m_mi.shI])
            AddLine(L_EQ,1,false,m_mi.shPrevI,m_mi.shI,(m_mi.shP+m_mi.shPrev)/2.0);
        }
      if((f3&2)!=0 && m_mi.slPrevI>=0 && (m_mi.slI-m_mi.slPrevI)<=100)
        {
         if(MathAbs(m_mi.slP-m_mi.slPrev)<=InpEqTolATR*m_atr[m_mi.slI])
            AddLine(L_EQ,-1,false,m_mi.slPrevI,m_mi.slI,(m_mi.slP+m_mi.slPrev)/2.0);
        }

      //--- Inducement (IDM)
      if(m_main)
        {
         if((f3&2)!=0 && m_in.trend==1)
           {
            m_idmLowP=m_mi.slP; m_idmLowI=m_mi.slI; m_idmLowTk=false;
           }
         if((f3&1)!=0 && m_in.trend==-1)
           {
            m_idmHighP=m_mi.shP; m_idmHighI=m_mi.shI; m_idmHighTk=false;
           }
         if(m_idmLowI>=0 && !m_idmLowTk && m_r[i].low<m_idmLowP)
           {
            m_idmLowTk=true;
            m_idmBullBar=i;
            AddLine(L_IDM,1,false,m_idmLowI,i,m_idmLowP);
           }
         if(m_idmHighI>=0 && !m_idmHighTk && m_r[i].high>m_idmHighP)
           {
            m_idmHighTk=true;
            m_idmBearBar=i;
            AddLine(L_IDM,-1,false,m_idmHighI,i,m_idmHighP);
           }
        }

      //--- Liquidity sweep
      SweepStruct(m_in,i);
      SweepStruct(m_sw,i);

      //--- zona baru
      DetectZones(i);

      //--- sinyal
      if(m_main)
         CheckSignals(i);

      //--- update zona (mitigasi / breaker / IFVG)
      UpdateZones(i);
     }

   void Run(bool isMain,int swLen,int inLen,int miLen,int atrP)
     {
      m_main=isMain;
      CalcATR(atrP);
      ResetStruct(m_sw,swLen);
      ResetStruct(m_in,inLen);
      ResetStruct(m_mi,miLen);
      m_zn=0;
      m_ln=0;
      m_sgN=0;
      ArrayResize(m_z,0);
      ArrayResize(m_l,0);
      ArrayResize(m_sg,0);
      ArrayResize(m_trSw,m_n);
      ArrayInitialize(m_trSw,0);
      ArrayResize(m_buy,m_n);    ArrayInitialize(m_buy,EMPTY_VALUE);
      ArrayResize(m_sell,m_n);   ArrayInitialize(m_sell,EMPTY_VALUE);
      ArrayResize(m_buySL,m_n);  ArrayInitialize(m_buySL,EMPTY_VALUE);
      ArrayResize(m_buyTP,m_n);  ArrayInitialize(m_buyTP,EMPTY_VALUE);
      ArrayResize(m_sellSL,m_n); ArrayInitialize(m_sellSL,EMPTY_VALUE);
      ArrayResize(m_sellTP,m_n); ArrayInitialize(m_sellTP,EMPTY_VALUE);
      ArrayResize(m_bias,m_n);   ArrayInitialize(m_bias,0.0);
      m_sweepBullBar=-1; m_sweepBearBar=-1;
      m_sweepBullExt=0.0; m_sweepBearExt=0.0;
      m_brkBullBar=-1; m_brkBearBar=-1;
      m_idmBullBar=-1; m_idmBearBar=-1;
      m_idmLowP=0.0; m_idmHighP=0.0;
      m_idmLowI=-1; m_idmHighI=-1;
      m_idmLowTk=true; m_idmHighTk=true;
      m_crtPtr=0;
      m_crtCur=-1;
      m_crtOn=false;
      m_crtDir=0;
      m_biasNow=0;
      m_biasSrc=0;
      for(int i=0;i<m_n-1;i++)
         Step(i);
      if(m_main)
        {
         int src=0;
         m_biasNow=ComputeBias(m_n-1,src);
         m_biasSrc=src;
         m_bias[m_n-1]=m_biasNow;
        }
     }
  };

//+------------------------------------------------------------------+
//| Variabel global mesin ICT                                        |
//+------------------------------------------------------------------+
CSmc     g_main;
CSmc     g_htf;
bool     g_htfOk=false;
datetime g_lastBar=0;
datetime g_lastAlert=0;
bool     g_alertInit=false;
int      g_oc=0;

//--- status layar (untuk menyusun ulang label saat zoom / ubah ukuran)
int      g_scale=-1;
double   g_span=0.0;
int      g_hpx=0;
ulong    g_lastRedraw=0;

//--- posisi panel info ICT (di kanan dashboard EA)
int PanelX() { return X_Offset + Panel_Width + 10; }
int PanelY() { return Y_Offset; }

//+------------------------------------------------------------------+
//| Manajer tabrakan teks (koordinat piksel)                         |
//+------------------------------------------------------------------+
struct SBox
  {
   int x1;
   int y1;
   int x2;
   int y2;
  };

SBox g_box[];
int  g_boxN=0;

void AddBox(int x1,int y1,int x2,int y2)
  {
   if(g_boxN>=ArraySize(g_box))
      ArrayResize(g_box,g_boxN+256);
   g_box[g_boxN].x1=x1;
   g_box[g_boxN].y1=y1;
   g_box[g_boxN].x2=x2;
   g_box[g_boxN].y2=y2;
   g_boxN++;
  }

bool HitBox(int x1,int y1,int x2,int y2)
  {
   for(int k=0;k<g_boxN;k++)
     {
      if(x1<g_box[k].x2 && x2>g_box[k].x1 && y1<g_box[k].y2 && y2>g_box[k].y1)
         return true;
     }
   return false;
  }

//--- geser harga teks ke atas/bawah sampai tidak menabrak teks lain
void AvoidOverlap(datetime t,double &p,string txt,int fs,ENUM_ANCHOR_POINT a)
  {
   if(!InpAntiOverlap)
      return;
   int x=0;
   int y=0;
   if(!ChartTimePriceToXY(0,0,t,p,x,y))
      return;
   int w=(int)(StringLen(txt)*fs*0.70)+4;
   int h=(int)(fs*1.8)+2;
   bool center=(a==ANCHOR_LOWER || a==ANCHOR_UPPER || a==ANCHOR_CENTER);
   bool right =(a==ANCHOR_RIGHT || a==ANCHOR_RIGHT_LOWER || a==ANCHOR_RIGHT_UPPER);
   bool up    =(a==ANCHOR_LOWER || a==ANCHOR_LEFT_LOWER || a==ANCHOR_RIGHT_LOWER);
   bool mid   =(a==ANCHOR_LEFT || a==ANCHOR_RIGHT || a==ANCHOR_CENTER);
   int x1=center?(x-w/2):(right?(x-w):x);
   int x2=x1+w;
   int step=h+InpLabelGap;
   int dy=0;
   int y1=0;
   for(int n=0;n<25;n++)
     {
      int ys=y+dy;
      y1=up?(ys-h):(mid?(ys-h/2):ys);
      if(!HitBox(x1,y1,x2,y1+h))
         break;
      dy+=up?-step:step;
     }
   AddBox(x1,y1,x2,y1+h);
   if(dy!=0)
     {
      int sub=0;
      datetime tt=0;
      double pp=0.0;
      if(ChartXYToTimePrice(0,x,y+dy,sub,tt,pp))
         p=pp;
     }
  }

//+------------------------------------------------------------------+
//| Fungsi gambar ICT                                                |
//+------------------------------------------------------------------+
string NM(string tag)
  {
   g_oc++;
   return PFX+tag+"_"+IntegerToString(g_oc);
  }

void DRect(datetime t1,double p1,datetime t2,double p2,color c,bool fill,ENUM_LINE_STYLE st,int w)
  {
   string n=NM("R");
   if(!ObjectCreate(0,n,OBJ_RECTANGLE,0,t1,p1,t2,p2))
      return;
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_FILL,fill);
   ObjectSetInteger(0,n,OBJPROP_STYLE,st);
   ObjectSetInteger(0,n,OBJPROP_WIDTH,w);
   ObjectSetInteger(0,n,OBJPROP_BACK,true);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
  }

void DLine(datetime t1,double p1,datetime t2,double p2,color c,ENUM_LINE_STYLE st,int w)
  {
   string n=NM("L");
   if(!ObjectCreate(0,n,OBJ_TREND,0,t1,p1,t2,p2))
      return;
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_STYLE,st);
   ObjectSetInteger(0,n,OBJPROP_WIDTH,w);
   ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,n,OBJPROP_BACK,false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
  }

void DText(datetime t,double p,string txt,color c,int fs,ENUM_ANCHOR_POINT a)
  {
   double pp=p;
   AvoidOverlap(t,pp,txt,fs,a);
   string n=NM("T");
   if(!ObjectCreate(0,n,OBJ_TEXT,0,t,pp))
      return;
   ObjectSetString(0,n,OBJPROP_TEXT,txt);
   ObjectSetString(0,n,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,fs);
   ObjectSetInteger(0,n,OBJPROP_ANCHOR,a);
   ObjectSetInteger(0,n,OBJPROP_BACK,false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
  }

string ZoneName(int ty,int d)
  {
   string s=(d>0)?"Bull ":"Bear ";
   if(ty==Z_OB)   return s+"OB";
   if(ty==Z_FVG)  return s+"FVG";
   if(ty==Z_BRK)  return s+"Breaker";
   if(ty==Z_MIT)  return s+"MB";
   if(ty==Z_IFVG) return s+"IFVG";
   if(ty==Z_VI)   return s+"VI";
   return s+"Void";
  }

color ZoneColor(int ty,int d)
  {
   if(ty==Z_OB)   return (d>0)?InpColBullOB:InpColBearOB;
   if(ty==Z_FVG)  return (d>0)?InpColBullFVG:InpColBearFVG;
   if(ty==Z_BRK)  return InpColBreaker;
   if(ty==Z_MIT)  return InpColMitig;
   if(ty==Z_IFVG) return clrMediumPurple;
   if(ty==Z_VI)   return clrSlateGray;
   return clrDimGray;
  }

bool ZoneEnabled(int ty,bool htf)
  {
   if(htf)
      return ((ty==Z_OB && InpShowOB) || (ty==Z_FVG && InpShowFVG) || (ty==Z_BRK && InpShowBreaker));
   if(ty==Z_OB)   return InpShowOB;
   if(ty==Z_FVG)  return InpShowFVG;
   if(ty==Z_BRK)  return InpShowBreaker;
   if(ty==Z_MIT)  return InpShowMitig;
   if(ty==Z_IFVG) return InpShowIFVG;
   if(ty==Z_VI)   return InpShowVI;
   if(ty==Z_VOID) return InpShowVoid;
   return false;
  }

void DrawZones(CSmc &m,bool htf)
  {
   datetime tEnd=m.m_r[m.m_n-1].time+PeriodSeconds()*InpExtendBars;
   int cnt[7];
   int cm[7];
   ArrayInitialize(cnt,0);
   ArrayInitialize(cm,0);
   int mx=htf?InpHtfMaxZones:InpMaxZones;
   string pre=htf?(TfName(m.m_tf)+" "):"";
   for(int k=m.m_zn-1;k>=0;k--)
     {
      int ty=m.m_z[k].type;
      if(!ZoneEnabled(ty,htf))
         continue;
      bool mit=m.m_z[k].mitigated;
      if(mit)
        {
         if(!InpShowMitigated || cm[ty]>=3)
            continue;
         cm[ty]++;
        }
      else
        {
         if(cnt[ty]>=mx)
            continue;
         cnt[ty]++;
        }
      int d=m.m_z[k].dir;
      datetime t1=m.m_r[m.m_z[k].bar0].time;
      datetime t2=mit?m.m_r[m.m_z[k].mitBar].time:tEnd;
      color c=ZoneColor(ty,d);
      double top=m.m_z[k].top;
      double bot=m.m_z[k].bottom;
      bool fill=(InpFillZones && !mit && !htf);
      DRect(t1,top,t2,bot,c,fill,(mit||htf)?STYLE_DOT:STYLE_SOLID,1);
      if(ty==Z_FVG || ty==Z_IFVG || ty==Z_VOID)
         DLine(t1,(top+bot)/2.0,t2,(top+bot)/2.0,clrGray,STYLE_DOT,1);
      DText(t1,top,pre+ZoneName(ty,d),c,7,ANCHOR_LEFT_LOWER);
     }
  }

void DrawLines(CSmc &m)
  {
   int cS=0;
   int cI=0;
   int cQ=0;
   int cD=0;
   int cW=0;
   for(int k=m.m_ln-1;k>=0;k--)
     {
      int kd=m.m_l[k].kind;
      int d=m.m_l[k].dir;
      datetime t0=m.m_r[m.m_l[k].bar0].time;
      datetime t1=m.m_r[m.m_l[k].bar1].time;
      datetime tm=t0+(t1-t0)/2;
      double p=m.m_l[k].price;
      if(kd==L_BOS || kd==L_CHOCH)
        {
         bool it=m.m_l[k].isInt;
         if(it)
           {
            if(!InpShowInternal || cI>=InpMaxEvents)
               continue;
            cI++;
           }
         else
           {
            if(!InpShowSwing || cS>=InpMaxEvents)
               continue;
            cS++;
           }
         color c=(d>0)?InpColStrBull:InpColStrBear;
         string tx=(it?"i":"")+((kd==L_CHOCH)?"CHoCH":"BOS");
         DLine(t0,p,t1,p,c,it?STYLE_DOT:STYLE_SOLID,1);
         DText(tm,p,tx,c,it?7:8,(d>0)?ANCHOR_LOWER:ANCHOR_UPPER);
        }
      else if(kd==L_EQ)
        {
         if(!InpShowEQ || cQ>=6)
            continue;
         cQ++;
         DLine(t0,p,t1,p,clrOrange,STYLE_SOLID,1);
         DText(tm,p,(d>0)?"EQH":"EQL",clrOrange,7,(d>0)?ANCHOR_LOWER:ANCHOR_UPPER);
        }
      else if(kd==L_IDM)
        {
         if(!InpShowIDM || cD>=6)
            continue;
         cD++;
         DLine(t0,p,t1,p,clrMagenta,STYLE_DASH,1);
         DText(tm,p,"IDM",clrMagenta,7,(d>0)?ANCHOR_UPPER:ANCHOR_LOWER);
        }
      else if(kd==L_SWEEP)
        {
         if(!InpShowSweep || cW>=8)
            continue;
         cW++;
         DText(t0,p,(d<0)?"x BSL":"x SSL",clrDarkOrange,8,(d<0)?ANCHOR_LOWER:ANCHOR_UPPER);
        }
     }
  }

void DrawRange(CSmc &m)
  {
   if(m.m_sw.shI<0 || m.m_sw.slI<0)
      return;
   double top=m.m_sw.shP;
   double bot=m.m_sw.slP;
   if(top<=bot)
      return;
   int i0=MathMin(m.m_sw.shI,m.m_sw.slI);
   int i1=MathMax(m.m_sw.shI,m.m_sw.slI);
   datetime t0=m.m_r[i0].time;
   datetime tA=m.m_r[i1].time;
   datetime tE=m.m_r[m.m_n-1].time+PeriodSeconds()*InpExtendBars;
   double eq=(top+bot)/2.0;
   double rng=top-bot;
   if(InpShowPD)
     {
      DRect(t0,top,tE,eq,clrFireBrick,false,STYLE_DOT,1);
      DRect(t0,eq,tE,bot,clrSeaGreen,false,STYLE_DOT,1);
      DLine(t0,eq,tE,eq,clrGray,STYLE_DASH,1);
      DText(tE,top,"Premium",clrFireBrick,8,ANCHOR_LEFT);
      DText(tE,eq,"EQ 50%",clrGray,8,ANCHOR_LEFT);
      DText(tE,bot,"Discount",clrSeaGreen,8,ANCHOR_LEFT);
     }
   if(InpShowOTE)
     {
      double a;
      double b;
      if(m.m_sw.trend>=0)
        {
         a=top-0.62*rng;
         b=top-0.79*rng;
        }
      else
        {
         a=bot+0.62*rng;
         b=bot+0.79*rng;
        }
      DRect(tA,a,tE,b,clrGold,false,STYLE_SOLID,1);
      DText(tE,(a+b)/2.0,"OTE",clrGold,8,ANCHOR_LEFT);
     }
   if(InpShowStrongWeak && m.m_sw.trend!=0)
     {
      string hs=(m.m_sw.trend>0)?"Weak High":"Strong High";
      string ls=(m.m_sw.trend>0)?"Strong Low":"Weak Low";
      DText(m.m_r[m.m_sw.shI].time,top,hs,clrSilver,7,ANCHOR_LEFT_LOWER);
      DText(m.m_r[m.m_sw.slI].time,bot,ls,clrSilver,7,ANCHOR_LEFT_UPPER);
     }
  }

void DrawLiq(CSmc &m)
  {
   datetime tE=m.m_r[m.m_n-1].time+PeriodSeconds()*InpExtendBars;
   double v;
   datetime t;
   v=iHigh(_Symbol,PERIOD_D1,1); t=iTime(_Symbol,PERIOD_D1,1);
   if(v>0.0 && t>0)
     { DLine(t,v,tE,v,clrSilver,STYLE_DASHDOT,1); DText(tE,v,"PDH",clrSilver,8,ANCHOR_LEFT); }
   v=iLow(_Symbol,PERIOD_D1,1); t=iTime(_Symbol,PERIOD_D1,1);
   if(v>0.0 && t>0)
     { DLine(t,v,tE,v,clrSilver,STYLE_DASHDOT,1); DText(tE,v,"PDL",clrSilver,8,ANCHOR_LEFT); }
   v=iHigh(_Symbol,PERIOD_W1,1); t=iTime(_Symbol,PERIOD_W1,1);
   if(v>0.0 && t>0)
     { DLine(t,v,tE,v,clrGold,STYLE_DASHDOT,1); DText(tE,v,"PWH",clrGold,8,ANCHOR_LEFT); }
   v=iLow(_Symbol,PERIOD_W1,1); t=iTime(_Symbol,PERIOD_W1,1);
   if(v>0.0 && t>0)
     { DLine(t,v,tE,v,clrGold,STYLE_DASHDOT,1); DText(tE,v,"PWL",clrGold,8,ANCHOR_LEFT); }
  }

void DrawCrt(CSmc &m)
  {
   int ps=PeriodSeconds(InpCrtTF);
   int c=0;
   for(int k=m.m_crtN-1;k>=0 && c<InpCrtBoxes;k--,c++)
     {
      datetime t1=m.m_crt[k].tC1;
      datetime t2=m.m_crt[k].tConf;
      double h1=m.m_crt[k].h1;
      double l1=m.m_crt[k].l1;
      double mid=(h1+l1)/2.0;
      DRect(t1,h1,t2,l1,clrGoldenrod,false,STYLE_SOLID,1);
      DLine(t1,mid,t2+ps,mid,clrGoldenrod,STYLE_DOT,1);
      DLine(t2-ps,m.m_crt[k].ext,t2,m.m_crt[k].ext,clrOrange,STYLE_SOLID,2);
      string tx=((m.m_crt[k].dir>0)?"CRT Bull ":"CRT Bear ")+TfName(InpCrtTF);
      DText(t1,h1,tx,clrGoldenrod,8,ANCHOR_LEFT_LOWER);
     }
  }

void DrawKillzones(CSmc &m)
  {
   datetime tLast=m.m_r[m.m_n-1].time;
   datetime tMin=tLast-(datetime)(InpKzDays*86400);
   int ps=PeriodSeconds();
   int start=0;
   for(int i=0;i<m.m_n;i++)
     {
      if(m.m_r[i].time>=tMin)
        {
         start=i;
         break;
        }
     }
   for(int s=0;s<7;s++)
     {
      if(!g_sOn[s])
         continue;
      bool in=false;
      double hi=0.0;
      double lo=0.0;
      datetime ts=0;
      datetime te=0;
      for(int i=start;i<m.m_n;i++)
        {
         bool x=InSession(s,m.m_r[i].time);
         if(x)
           {
            if(!in)
              {
               in=true;
               hi=m.m_r[i].high;
               lo=m.m_r[i].low;
               ts=m.m_r[i].time;
              }
            else
              {
               hi=MathMax(hi,m.m_r[i].high);
               lo=MathMin(lo,m.m_r[i].low);
              }
            te=m.m_r[i].time+ps;
           }
         if(in && (!x || i==m.m_n-1))
           {
            DRect(ts,hi,te,lo,g_sCol[s],false,STYLE_DOT,1);
            DText(ts,hi,g_sName[s],g_sCol[s],7,ANCHOR_LEFT_LOWER);
            in=false;
           }
        }
     }
  }

void DrawSignals(CSmc &m)
  {
   int c=0;
   for(int k=m.m_sgN-1;k>=0 && c<InpMaxSigDraw;k--,c++)
     {
      datetime t=m.m_r[m.m_sg[k].bar].time;
      datetime t2=t+PeriodSeconds()*InpExtendBars;
      double sl=m.m_sg[k].sl;
      double tp=m.m_sg[k].tp;
      DLine(t,sl,t2,sl,clrRed,STYLE_DASH,1);
      DLine(t,tp,t2,tp,clrLime,STYLE_DASH,1);
      DText(t2,sl,"SL "+DoubleToString(sl,_Digits),clrRed,8,ANCHOR_LEFT);
      DText(t2,tp,"TP "+DoubleToString(tp,_Digits),clrLime,8,ANCHOR_LEFT);
     }
  }

string TrendStr(int t)
  {
   if(t>0) return "Bull";
   if(t<0) return "Bear";
   return "-";
  }

void PanelRow(int idx,string txt,color c)
  {
   string n=PFX+"P"+IntegerToString(idx);
   if(!ObjectCreate(0,n,OBJ_LABEL,0,0,0))
      return;
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,PanelX()+8);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,PanelY()+6+idx*16);
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,n,OBJPROP_FONT,"Arial");
   ObjectSetString(0,n,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
  }

void DrawPanel(CSmc &m)
  {
   string bg=PFX+"PBG";
   if(ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0))
     {
      ObjectSetInteger(0,bg,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,PanelX());
      ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,PanelY());
      ObjectSetInteger(0,bg,OBJPROP_XSIZE,270);
      ObjectSetInteger(0,bg,OBJPROP_YSIZE,6*16+14);
      ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,C'20,22,30');
      ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,bg,OBJPROP_COLOR,clrDimGray);
      ObjectSetInteger(0,bg,OBJPROP_BACK,false);
      ObjectSetInteger(0,bg,OBJPROP_SELECTABLE,false);
     }
   //--- bias
   string bs="NETRAL";
   color bc=clrSilver;
   if(m.m_biasNow>0){ bs="BULLISH"; bc=clrLime; }
   if(m.m_biasNow<0){ bs="BEARISH"; bc=clrTomato; }
   string src="";
   if(m.m_biasSrc==1) src=" (CRT)";
   if(m.m_biasSrc==2) src=" (HTF)";
   if(m.m_biasSrc==3) src=" (CRT+HTF)";
   //--- sesi
   string ss="";
   datetime tn=m.m_r[m.m_n-1].time;
   for(int s=0;s<7;s++)
     {
      if(g_sOn[s] && InSession(s,tn))
        {
         if(ss!="")
            ss+=", ";
         ss+=g_sName[s];
        }
     }
   if(ss=="")
      ss="-";
   //--- sinyal terakhir
   string sg="-";
   if(m.m_sgN>0)
     {
      int k=m.m_sgN-1;
      sg=((m.m_sg[k].dir>0)?"BUY ":"SELL ")+TimeToString(m.m_r[m.m_sg[k].bar].time,TIME_DATE|TIME_MINUTES);
     }
   //--- CRT
   string cr="-";
   if(m.m_crtOn)
      cr=(m.m_crtDir>0)?"Bullish aktif":"Bearish aktif";

   PanelRow(0,"ICT | SMC | CRT",clrWhite);
   PanelRow(1,"Bias: "+bs+src,bc);
   PanelRow(2,"CRT ("+TfName(InpCrtTF)+"): "+cr,clrSilver);
   PanelRow(3,"Struktur: Swing "+TrendStr(m.m_sw.trend)+" | Int "+TrendStr(m.m_in.trend),clrSilver);
   PanelRow(4,"Sesi: "+ss,clrSilver);
   PanelRow(5,"Sinyal: "+sg,clrYellow);
  }

//--- apakah gambar ICT boleh dibuat (dimatikan di tester non-visual agar cepat)
bool IctDrawEnabled()
  {
   if(!InpIctDraw)
      return false;
   if(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE))
      return false;
   return true;
  }

//--- urutan gambar = prioritas posisi label.
//--- yang digambar lebih dulu tetap di tempatnya, yang belakangan bergeser.
void DrawAll()
  {
   ObjectsDeleteAll(0,PFX);
   g_oc=0;
   g_boxN=0;
   if(g_main.m_n<10)
      return;

   //--- area panel info dianggap terisi supaya teks tidak menimpanya
   if(InpShowPanel)
      AddBox(PanelX(),PanelY(),PanelX()+270,PanelY()+6*16+14);

   DrawSignals(g_main);
   if(InpShowCRT)
      DrawCrt(g_main);
   DrawLines(g_main);
   DrawRange(g_main);
   if(InpShowLiq)
      DrawLiq(g_main);
   DrawZones(g_main,false);
   if(InpShowHtfZones && g_htfOk)
      DrawZones(g_htf,true);
   if(InpShowKZ)
      DrawKillzones(g_main);
   if(InpShowPanel)
      DrawPanel(g_main);

   g_scale=(int)ChartGetInteger(0,CHART_SCALE);
   g_span=ChartGetDouble(0,CHART_PRICE_MAX)-ChartGetDouble(0,CHART_PRICE_MIN);
   g_hpx=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Alert                                                            |
//+------------------------------------------------------------------+
void CheckAlert()
  {
   int n=g_main.m_n;
   if(n<3)
      return;
   datetime tb=g_main.m_r[n-2].time;
   if(!g_alertInit)
     {
      g_alertInit=true;
      g_lastAlert=tb;
      return;
     }
   if(tb==g_lastAlert)
      return;
   g_lastAlert=tb;
   string msg="";
   if(g_main.m_buy[n-2]!=EMPTY_VALUE)
      msg="BUY "+_Symbol+" "+TfName(_Period)+" SL "+DoubleToString(g_main.m_buySL[n-2],_Digits)+" TP "+DoubleToString(g_main.m_buyTP[n-2],_Digits);
   if(g_main.m_sell[n-2]!=EMPTY_VALUE)
      msg="SELL "+_Symbol+" "+TfName(_Period)+" SL "+DoubleToString(g_main.m_sellSL[n-2],_Digits)+" TP "+DoubleToString(g_main.m_sellTP[n-2],_Digits);
   if(msg=="")
      return;
   msg="GT_ICT: "+msg;
   if(InpAlertPopup)
      Alert(msg);
   if(InpAlertPush)
      SendNotification(msg);
   if(InpAlertMail)
      SendMail("GT_ICT",msg);
  }

//+------------------------------------------------------------------+
//| Jalankan seluruh analisis ICT (dipanggil sekali per bar baru)    |
//+------------------------------------------------------------------+
bool RunIct()
  {
   int bars=Bars(_Symbol,_Period);
   if(bars<100)
      return false;
   int cnt=MathMin(InpMaxBars,bars);
   if(!g_main.Load(_Period,cnt))
      return false;

   //--- HTF (bias struktur dan zona)
   g_htfOk=g_htf.Load(InpHtf,500);
   if(g_htfOk)
      g_htf.Run(false,InpHtfSwingLen,InpIntLen,InpMicroLen,InpAtrPeriod);

   //--- CRT dan pemetaan bias HTF ke bar chart
   g_main.BuildCrt(InpCrtTF,500);
   if(g_htfOk)
      g_main.MapHtf(g_htf);
   else
      g_main.ClearHtf();

   //--- analisis utama
   g_main.Run(true,InpSwingLen,InpIntLen,InpMicroLen,InpAtrPeriod);

   if(IctDrawEnabled())
      DrawAll();
   CheckAlert();
   return true;
  }

//--- dipanggil dari OnTick: analisis ulang hanya saat bar baru terbentuk
void IctOnTick()
  {
   if(InpMode!=MODE_ICT && !InpIctDraw)
      return;
   datetime cur=iTime(_Symbol,PERIOD_CURRENT,0);
   if(cur==0)
      return;
   if(cur==g_lastBar && g_ictReady)
      return;
   g_lastBar=cur;
   g_ictReady=RunIct();
  }

//--- susun ulang label saat zoom / ukuran jendela / skala harga berubah
void IctOnChartChange()
  {
   if(!InpAntiOverlap || !IctDrawEnabled() || !g_ictReady)
      return;
   if(g_main.m_n<10)
      return;
   int sc=(int)ChartGetInteger(0,CHART_SCALE);
   int hp=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   double span=ChartGetDouble(0,CHART_PRICE_MAX)-ChartGetDouble(0,CHART_PRICE_MIN);
   bool chg=(sc!=g_scale || hp!=g_hpx || g_span<=0.0 || MathAbs(span-g_span)/g_span>0.02);
   if(!chg)
      return;
   ulong now=GetTickCount64();
   if(now-g_lastRedraw<400)
      return;
   g_lastRedraw=now;
   DrawAll();
  }

//+------------------------------------------------------------------+
//| Tema                                                             |
//+------------------------------------------------------------------+
void ApplyTheme()
{
   switch(extTheme)
   {
      case THEME_NEON_BLUE:
         gClrBg      = C'5,15,25';
         gClrHdr     = C'20,40,60';
         gClrStripe  = C'10,25,45';
         gClrLabel   = clrCyan;
         gClrValue   = clrWhite;
         gClrAccent  = clrDeepSkyBlue;
         gClrSuccess = clrSpringGreen;
         gClrDanger  = clrDeepPink;
         gClrBorder  = C'20,50,80';
         break;
      case THEME_MATRIX:
         gClrBg      = C'0,10,0';
         gClrHdr     = C'0,30,0';
         gClrStripe  = C'5,20,5';
         gClrLabel   = clrLimeGreen;
         gClrValue   = clrLime;
         gClrAccent  = clrGreen;
         gClrSuccess = clrWhite;
         gClrDanger  = clrRed;
         gClrBorder  = C'0,40,0';
         break;
      case THEME_PURE_DARK:
         gClrBg      = C'15,15,15';
         gClrHdr     = C'25,25,25';
         gClrStripe  = C'20,20,20';
         gClrLabel   = clrLightGray;
         gClrValue   = clrWhite;
         gClrAccent  = clrGray;
         gClrSuccess = clrAliceBlue;
         gClrDanger  = clrIndianRed;
         gClrBorder  = C'35,35,35';
         break;
      case THEME_ONYX_GOLD:
      default:
         gClrBg      = COLOR_BG;
         gClrHdr     = COLOR_HDR_BG;
         gClrStripe  = COLOR_STRIPE;
         gClrLabel   = Label_Color;
         gClrValue   = Value_Color;
         gClrAccent  = clrGold;
         gClrSuccess = COLOR_SUCCESS;
         gClrDanger  = COLOR_DANGER;
         gClrBorder  = COLOR_BORDER;
         break;
   }
}

//+------------------------------------------------------------------+
//| [3] Expert initialization function                               |
//+------------------------------------------------------------------+
int OnInit()
{
   myPoint  = _Point;
   myDigits = _Digits;
   
   string themeGV = PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_THEME";
   if(GlobalVariableCheck(themeGV))
      extTheme = (ENUM_THEME)GlobalVariableGet(themeGV);
   else
      extTheme = InpTheme;
      
   string showChartGV = PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_SHOWCHART";
   if(GlobalVariableCheck(showChartGV))
      extShowGTChart = (bool)GlobalVariableGet(showChartGV);
   else
      extShowGTChart = InpShowGTChart;
   
   serverLocalOffset = (long)TimeCurrent() - (long)TimeLocal();

   ApplyTheme();
   DeleteAllObjects();

   if(!CreateDashboard())
   {
      Print("Gagal membuat Quad-Bar Dashboard.");
      return(INIT_FAILED);
   }

   trade.SetExpertMagicNumber(InpMagic);

   // Reset status mesin ICT
   SetupSessions();
   g_lastBar       = 0;
   g_alertInit     = false;
   g_scale         = -1;
   g_span          = 0.0;
   g_hpx           = 0;
   g_lastRedraw    = 0;
   g_ictReady      = false;
   g_ictAttemptBar = 0;

   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{ 
   EventKillTimer(); 
   DeleteAllObjects(); 
   DeleteVisualization(); 
   ObjectsDeleteAll(0, PFX);
   
   if(reason == REASON_REMOVE || reason == REASON_CLOSE)
   {
      string themeGV = PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_THEME";
      string showChartGV = PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_SHOWCHART";
      GlobalVariableDel(themeGV);
      GlobalVariableDel(showChartGV);
   }
   ChartRedraw();
}

void OnTick()                    
{ 
   UpdateGUILabels(); 
   IctOnTick();              // analisis ICT/SMC/CRT (hanya saat bar baru)
   ExecuteTradingLogic();
   if(extShowGTChart) DrawGTLevels();
}

void OnTimer()                   { UpdateCountdown(); }

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      IctOnChartChange();
      return;
   }

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == PREFIX + "TAB_DB") { currTab = TAB_DASHBOARD; ResetDashboard(); }
      else if(sparam == PREFIX + "TAB_AB") { currTab = TAB_ABOUT;     ResetDashboard(); }
      else if(sparam == PREFIX + "TAB_TR") { currTab = TAB_TRADING;   ResetDashboard(); }
      else if(sparam == PREFIX + "TAB_CL") { currTab = TAB_COLORS;    ResetDashboard(); }
      else if(sparam == PREFIX + "TAB_VS") { currTab = TAB_VISUAL;    ResetDashboard(); }
      
      else if(sparam == PREFIX + "THM_ONYX")  
      { 
         extTheme = THEME_ONYX_GOLD; 
         GlobalVariableSet(PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_THEME", extTheme);
         ApplyTheme(); 
         ResetDashboard(); 
      }
      else if(sparam == PREFIX + "THM_NEON")  
      { 
         extTheme = THEME_NEON_BLUE; 
         GlobalVariableSet(PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_THEME", extTheme);
         ApplyTheme(); 
         ResetDashboard(); 
      }
      else if(sparam == PREFIX + "THM_MATRIX") 
      { 
         extTheme = THEME_MATRIX;    
         GlobalVariableSet(PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_THEME", extTheme);
         ApplyTheme(); 
         ResetDashboard(); 
      }
      else if(sparam == PREFIX + "THM_DARK")   
      { 
         extTheme = THEME_PURE_DARK;  
         GlobalVariableSet(PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_THEME", extTheme);
         ApplyTheme(); 
         ResetDashboard(); 
      }
      
      else if(sparam == PREFIX + "TOG_CHART") 
      { 
         extShowGTChart = !extShowGTChart; 
         GlobalVariableSet(PREFIX + "_" + _Symbol + "_" + IntegerToString(InpMagic) + "_SHOWCHART", extShowGTChart);
         if(!extShowGTChart) DeleteVisualization(); 
         ResetDashboard(); 
      }
   }
}


bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| [6] GUI Functions                                                |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, PREFIX) == 0) ObjectDelete(0, name);
   }
}

void DeleteVisualization()
{
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, VIS_PREFIX) == 0) ObjectDelete(0, name);
   }
}

void DrawGTLevels()
{
   double open  = iOpen(_Symbol, PERIOD_CURRENT, 0);
   double close = iClose(_Symbol, PERIOD_CURRENT, 0);
   double high  = iHigh(_Symbol, PERIOD_CURRENT, 0);
   double low   = iLow(_Symbol, PERIOD_CURRENT, 0);
   
   if(open == 0) return;

   double bH = MathMax(open, close), bL = MathMin(open, close);
   
   DrawHLine(VIS_PREFIX + "Tinggi", high,  gClrAccent, STYLE_DOT);
   DrawHLine(VIS_PREFIX + "Rendah", low,   gClrAccent, STYLE_DOT);
   DrawHLine(VIS_PREFIX + "Atas",   bH,    gClrLabel,  STYLE_SOLID);
   DrawHLine(VIS_PREFIX + "Bawah",  bL,    gClrLabel,  STYLE_SOLID);
   DrawHLine(VIS_PREFIX + "Awal",   open,  clrSilver,  STYLE_DASH);
   DrawHLine(VIS_PREFIX + "Inti",   close, gClrValue,  STYLE_SOLID, 2);
}

void DrawHLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width = 1)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   else
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
      
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, InpLevelStyle == STYLE_SOLID ? style : InpLevelStyle);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width == 1 ? InpLevelWidth : width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   if(InpShowLabels)
      ObjectSetString(0, name, OBJPROP_TEXT, " " + StringSubstr(name, StringLen(VIS_PREFIX)));
   else
      ObjectSetString(0, name, OBJPROP_TEXT, "");
}

bool CreateRect(string name, int x, int y, int w, int h, color bg, color border = clrNONE)
{
   if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) return false;
   ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,       h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   if(border != clrNONE) ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BACK,        false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   return true;
}

bool CreateLabel(string name, int x, int y, string text, color clr, int size = FONT_SIZE, string font = FONT_MAIN, ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER)
{
   if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) return false;
   ObjectSetInteger(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT,       text);
   ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  size);
   ObjectSetString(0, name, OBJPROP_FONT,       font);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,    anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   return true;
}

void CreateQuadBarRow(string prefix, int y, string label)
{
   int midY      = y + ROW_H / 2;  // Vertical center of row (true centering)
   int dataStart = 90;
   int colW      = (Panel_Width - dataStart) / 4;
   
   // Label column (left-aligned, vertically centered)
   CreateLabel(prefix + "_lbl", X_Offset + 20, midY, label, gClrLabel, 9, FONT_MAIN, ANCHOR_LEFT);
   
   // 4 Value Columns (Horizontally AND Vertically centered within column)
   CreateLabel(prefix + "_v3", X_Offset + dataStart + (int)(colW * 0.5), midY, "-", gClrValue,  9, FONT_MAIN, ANCHOR_CENTER);
   CreateLabel(prefix + "_v2", X_Offset + dataStart + (int)(colW * 1.5), midY, "-", gClrValue,  9, FONT_MAIN, ANCHOR_CENTER);
   CreateLabel(prefix + "_v1", X_Offset + dataStart + (int)(colW * 2.5), midY, "-", gClrValue,  9, FONT_MAIN, ANCHOR_CENTER);
   CreateLabel(prefix + "_v0", X_Offset + dataStart + (int)(colW * 3.5), midY, "-", gClrAccent, 9, FONT_MAIN, ANCHOR_CENTER);
}

void ResetDashboard() { DeleteAllObjects(); CreateDashboard(); }

bool CreateDashboard()
{
   int y = Y_Offset;
   int totalH = (currTab == TAB_DASHBOARD) ? 525 : 410;

   CreateRect(PREFIX + "Main", X_Offset, y, Panel_Width, totalH, gClrBg, gClrBorder);
   CreateCornerBrackets(X_Offset - 2, y - 2, Panel_Width + 4, totalH + 4, 15, gClrAccent);
   
   int tabW = (Panel_Width - 20) / 5;
   int tabX = X_Offset + 10;
   int tabY = y + 10;
   
   CreateTabButton(PREFIX + "TAB_DB", tabX + (tabW/2),         tabY, tabW, 25, "DASHBOARD", currTab == TAB_DASHBOARD);
   CreateTabButton(PREFIX + "TAB_AB", tabX + (tabW + tabW/2),  tabY, tabW, 25, "ABOUT",     currTab == TAB_ABOUT);
   CreateTabButton(PREFIX + "TAB_TR", tabX + (tabW*2 + tabW/2),tabY, tabW, 25, "TRADING",   currTab == TAB_TRADING);
   CreateTabButton(PREFIX + "TAB_CL", tabX + (tabW*3 + tabW/2),tabY, tabW, 25, "COLORS",    currTab == TAB_COLORS);
   CreateTabButton(PREFIX + "TAB_VS", tabX + (tabW*4 + tabW/2),tabY, tabW, 25, "VISUAL",    currTab == TAB_VISUAL);

   y += 45;
   
   if(currTab == TAB_DASHBOARD) CreateDashboardTab(y);
   else if(currTab == TAB_ABOUT) CreateAboutTab(y);
   else if(currTab == TAB_TRADING) CreateTradingTab(y);
   else if(currTab == TAB_COLORS) CreateColorsTab(y);
   else if(currTab == TAB_VISUAL) CreateVisualTab(y);

   ChartRedraw();
   return true;
}

void CreateDashboardTab(int y)
{
   // Header Area
   int centerX = X_Offset + (Panel_Width / 2);
   CreateRect(PREFIX + "Hdr", X_Offset + 4, y, Panel_Width - 8, 45, gClrHdr);
   CreateLabel(PREFIX + "Title", centerX, y + 22, "Genesis Riwayat Angka Faktual Informasi Keuangan", gClrAccent, 12, FONT_MAIN, ANCHOR_CENTER);
   y += 50;
   
   // Column Titles
   int dataStart = 90;
   int colW      = (Panel_Width - dataStart) / 4;
   CreateLabel(PREFIX + "C3", X_Offset + dataStart + (int)(colW * 0.5), y, "[ GT3 ]",    clrAqua,    8, FONT_MAIN, ANCHOR_UPPER);
   CreateLabel(PREFIX + "C2", X_Offset + dataStart + (int)(colW * 1.5), y, "[ GT2 ]",    clrAqua,    8, FONT_MAIN, ANCHOR_UPPER);
   CreateLabel(PREFIX + "C1", X_Offset + dataStart + (int)(colW * 2.5), y, "[ GT1 ]",    clrAqua,    8, FONT_MAIN, ANCHOR_UPPER);
   CreateLabel(PREFIX + "C0", X_Offset + dataStart + (int)(colW * 3.5), y, "[ GT LIVE ]",gClrAccent, 8, FONT_MAIN, ANCHOR_UPPER);
   CreateLabel(PREFIX + "CountdownIcon", X_Offset + dataStart + (int)(colW * 3.5) - 32, y + 24, "p", COLOR_COUNTDOWN, 9, "Webdings", ANCHOR_UPPER);
   CreateLabel(PREFIX + "Countdown",     X_Offset + dataStart + (int)(colW * 3.5) + 8,  y + 23, "00:00:00", COLOR_COUNTDOWN, 8, FONT_MAIN, ANCHOR_UPPER);
   y += 40;

   // Draw grid
   int y_start = y;
   int y_end   = y_start + 8 * ROW_H;
   
   // Vertical lines
   CreateRect(PREFIX + "Grid_V_Label", X_Offset + dataStart, y_start, 1, y_end - y_start, gClrBorder);
   for(int i = 1; i <= 4; i++)
      CreateRect(PREFIX + "Grid_V_" + IntegerToString(i), X_Offset + dataStart + colW * i, y_start, 1, y_end - y_start, gClrBorder);
   
   // Horizontal lines
   for(int i = 0; i <= 8; i++)
      CreateRect(PREFIX + "Grid_H_" + IntegerToString(i), X_Offset + 4, y_start + i * ROW_H, Panel_Width - 8, 1, gClrBorder);

   CreateQuadBarRow(PREFIX + "R_OH",    y, "Tinggi");    y += ROW_H;
   CreateQuadBarRow(PREFIX + "R_CH",    y, "Atas");      y += ROW_H;
   CreateQuadBarRow(PREFIX + "R_CL",    y, "Bawah");     y += ROW_H;
   CreateQuadBarRow(PREFIX + "R_OL",    y, "Rendah");    y += ROW_H;
   CreateQuadBarRow(PREFIX + "R_Awal",  y, "Awal");      y += ROW_H;
   CreateQuadBarRow(PREFIX + "R_OC",    y, "Neto");      y += ROW_H;
   CreateQuadBarRow(PREFIX + "R_LH",    y, "Inti");      y += ROW_H;
   CreateQuadBarRow(PREFIX + "R_Range", y, "Julat");     y += ROW_H + 5;

   UpdateInfoSectionOnDashboard(y);
}

void UpdateInfoSectionOnDashboard(int y)
{
   CreateRect(PREFIX + "InfoBg", X_Offset + 4, y, Panel_Width - 8, 135, gClrStripe);
   int infoY = y + 10;
   
   CreateLabel(PREFIX + "Acc_Bal",    X_Offset + 20,              infoY, "Saldo:",    gClrLabel, 8);
   CreateLabel(PREFIX + "Acc_BalVal", X_Offset + 130,             infoY, "0.00",      gClrValue, 8);
   CreateLabel(PREFIX + "Acc_Eq",     X_Offset + Panel_Width/2,   infoY, "Equity:",   gClrLabel, 8);
   CreateLabel(PREFIX + "Acc_EqVal",  X_Offset + Panel_Width - 20,infoY, "0.00",      gClrValue, 8, FONT_MAIN, ANCHOR_RIGHT_UPPER);
   
   infoY += 22;
   CreateLabel(PREFIX + "Sym_Spread",    X_Offset + 20,              infoY, "Spread:",    gClrLabel, 8);
   CreateLabel(PREFIX + "Sym_SpreadVal", X_Offset + 130,             infoY, "0",          gClrValue, 8);
   CreateLabel(PREFIX + "Sym_PL",        X_Offset + Panel_Width/2,   infoY, "Symbol P/L:",gClrLabel, 8);
   CreateLabel(PREFIX + "Sym_PLVal",     X_Offset + Panel_Width - 20,infoY, "0.00",       gClrAccent,8, FONT_MAIN, ANCHOR_RIGHT_UPPER);

   infoY += 22;
   CreateLabel(PREFIX + "Sym_BuyExp",    X_Offset + 20,              infoY, "Buy Exp:",    gClrLabel, 8);
   CreateLabel(PREFIX + "Sym_BuyExpVal", X_Offset + 130,             infoY, "0.00 Lots",  gClrValue, 8);
   CreateLabel(PREFIX + "Acc_ML",        X_Offset + Panel_Width/2,   infoY, "Margin Level:",gClrLabel,8);
   CreateLabel(PREFIX + "Acc_MLVal",     X_Offset + Panel_Width - 20,infoY, "0.00%",       gClrValue, 8, FONT_MAIN, ANCHOR_RIGHT_UPPER);

   infoY += 22;
   CreateLabel(PREFIX + "Sym_SellExp",    X_Offset + 20,              infoY, "Sell Exp:",  gClrLabel, 8);
   CreateLabel(PREFIX + "Sym_SellExpVal", X_Offset + 130,             infoY, "0.00 Lots",  gClrValue, 8);
   CreateLabel(PREFIX + "Acc_SOEq",       X_Offset + Panel_Width/2,   infoY, "Eq to SO:",  gClrLabel, 8);
   CreateLabel(PREFIX + "Acc_SOEqVal",    X_Offset + Panel_Width - 20,infoY, "0.00",        gClrValue, 8, FONT_MAIN, ANCHOR_RIGHT_UPPER);

   infoY += 22;
   CreateLabel(PREFIX + "Sym_SOPrice",    X_Offset + 20,              infoY, "SO Price:",  gClrLabel, 8);
   CreateLabel(PREFIX + "Sym_SOPriceVal", X_Offset + 130,             infoY, "-",           gClrValue, 8);
   CreateLabel(PREFIX + "Sym_SOPts",      X_Offset + Panel_Width/2,   infoY, "Pts to SO:", gClrLabel, 8);
   CreateLabel(PREFIX + "Sym_SOPtsVal",   X_Offset + Panel_Width - 20,infoY, "0 pts",       gClrValue, 8, FONT_MAIN, ANCHOR_RIGHT_UPPER);
}

void CreateAboutTab(int y)
{
   int contentX = X_Offset + 20;
   int contentW = Panel_Width - 40;
   CreateRect(PREFIX + "AboutBg", X_Offset + 4, y, Panel_Width - 8, 340, gClrStripe);
   
   int lineY = y + 20;
   CreateLabel(PREFIX + "Ab_Title", contentX, lineY, "UNTUK MENJADI BAHAGIA DALAM TRADING", gClrAccent, 11);
   lineY += 30;
   CreateLabel(PREFIX + "Ab_Desc1", contentX, lineY, "Anda harus menghilangkan dua hal:", clrWhite, 9);
   lineY += 20;
   CreateLabel(PREFIX + "Ab_Desc2", contentX, lineY, "Ketakutan akan masa depan yang buruk dan kenangan akan masa lalu yang buruk", clrWhite, 9);
   
   lineY += 40;
   CreateLabel(PREFIX + "Ab_DevLabel", contentX, lineY, "Developed by:", gClrLabel, 8);
   CreateLabel(PREFIX + "Ab_DevVal",   contentX + 120, lineY, "MOCHAMAD TABRANI", gClrValue, 8);
   lineY += 20;
   CreateLabel(PREFIX + "Ab_VerLabel", contentX, lineY, "Version:", gClrLabel, 8);
   CreateLabel(PREFIX + "Ab_VerVal",   contentX + 120, lineY, "0.02 Professional + ICT/SMC/CRT", gClrValue, 8);
   lineY += 20;
   CreateLabel(PREFIX + "Ab_Method",   contentX, lineY, "Methodology:", gClrLabel, 8);
   CreateLabel(PREFIX + "Ab_MethodVal",contentX + 120, lineY, "Grafik Tabranij (GT) + ICT / SMC / CRT", gClrValue, 8);
   
   lineY += 50;
   CreateRect(PREFIX + "Ab_Box", contentX, lineY, contentW, 100, gClrBg, clrSilver);
   CreateLabel(PREFIX + "Ab_Status",  contentX + 10, lineY + 10, "STATUS SISTEM: OPERASIONAL", gClrSuccess, 9);
   CreateLabel(PREFIX + "Ab_Lince",   contentX + 10, lineY + 30, "License: RINGIN BAMBU Juli 2026", clrSilver, 8);
   CreateLabel(PREFIX + "Ab_Support", contentX + 10, lineY + 70, "Support: mql5.com/getbos | t.me/ringinbambu", gClrAccent, 8);
}

void CreateTradingTab(int y)
{
   CreateRect(PREFIX + "TradBg", X_Offset + 4, y, Panel_Width - 8, 340, gClrStripe);
   int lineY = y + 20;
   int contentX = X_Offset + 20;
   
   CreateLabel(PREFIX + "Tr_Title", contentX, lineY, "RINGKASAN PENGATURAN ALGORITMA", gClrAccent, 10);
   lineY += 40;
   
   string modeTxt = (InpMode == MODE_ICT) ? "ICT / SMC / CRT" : "Sekuensial Martingale";
   CreateLabel(PREFIX + "Tr_ModeL", contentX, lineY, "Mode:", gClrLabel, 9);
   CreateLabel(PREFIX + "Tr_ModeV", contentX + 150, lineY, modeTxt, gClrAccent, 9);
   lineY += 25;
   CreateLabel(PREFIX + "Tr_StratL", contentX, lineY, "Durasi GT:", gClrLabel, 9);
   CreateLabel(PREFIX + "Tr_StratV", contentX + 150, lineY, EnumToString(InpGTTimeframe), gClrValue, 9);
   lineY += 25;
   CreateLabel(PREFIX + "Tr_LotL", contentX, lineY, "Volume:", gClrLabel, 9);
   string lotTxt = DoubleToString(InpLot, 2);
   if(InpMode == MODE_ICT && InpIctRiskPct > 0) lotTxt = DoubleToString(InpIctRiskPct, 1) + "% risiko / trade";
   CreateLabel(PREFIX + "Tr_LotV", contentX + 150, lineY, lotTxt, gClrValue, 9);
   lineY += 25;
   CreateLabel(PREFIX + "Tr_StepL", contentX, lineY, "Martingale x:", gClrLabel, 9);
   CreateLabel(PREFIX + "Tr_StepV", contentX + 150, lineY, DoubleToString(InpMultiplier, 1) + "x / Max " + IntegerToString(InpMaxSteps), gClrValue, 9);
   lineY += 25;
   CreateLabel(PREFIX + "Tr_TPL", contentX, lineY, "TP / SL:", gClrLabel, 9);
   string tpslTxt = (InpMode == MODE_ICT) ? "dari sinyal ICT" : (IntegerToString(InpTP) + " / " + IntegerToString(InpSL) + " pts");
   CreateLabel(PREFIX + "Tr_TPV", contentX + 150, lineY, tpslTxt, gClrValue, 9);
   lineY += 25;
   CreateLabel(PREFIX + "Tr_IctL", contentX, lineY, "ICT HTF / CRT:", gClrLabel, 9);
   CreateLabel(PREFIX + "Tr_IctV", contentX + 150, lineY, TfName(InpHtf) + " / " + TfName(InpCrtTF) + " | RR min " + DoubleToString(InpMinRR, 1), gClrValue, 9);
   
   lineY += 50;
   CreateLabel(PREFIX + "Tr_Note",  contentX, lineY, "Catatan: Untuk mengubah nilai ini, silakan gunakan standar", clrSilver, 8);
   lineY += 15;
   CreateLabel(PREFIX + "Tr_Note2", contentX, lineY, "Expert Advisor Properties (F7 -> Inputs).", clrSilver, 8);
}

void CreateColorsTab(int y)
{
   CreateRect(PREFIX + "ColBg", X_Offset + 4, y, Panel_Width - 8, 340, gClrStripe);
   int lineY = y + 20;
   int centerX = X_Offset + Panel_Width/2;
   
   CreateLabel(PREFIX + "Cl_Title", centerX, lineY, "PILIH TAMPILAN TEMA", gClrAccent, 11, FONT_MAIN, ANCHOR_CENTER);
   lineY += 50;
   
   int btnW = 180, btnH = 35;
   CreateButton(PREFIX + "THM_ONYX",   centerX, lineY, btnW, btnH, "ONYX & GOLD",   clrWhite, C'35,35,35');
   lineY += 50;
   CreateButton(PREFIX + "THM_NEON",   centerX, lineY, btnW, btnH, "NEON BLUE",     clrWhite, C'20,40,60');
   lineY += 50;
   CreateButton(PREFIX + "THM_MATRIX", centerX, lineY, btnW, btnH, "RETRO MATRIX",  clrWhite, C'10,50,10');
   
   lineY += 60;
   CreateLabel(PREFIX + "Cl_Note", centerX, lineY, "Perubahan tema yang langsung diterapkan di semua tab.", clrSilver, 8, FONT_MAIN, ANCHOR_CENTER);
}

void CreateVisualTab(int y)
{
   CreateRect(PREFIX + "VisBg", X_Offset + 4, y, Panel_Width - 8, 340, gClrStripe);
   int lineY = y + 20;
   int centerX = X_Offset + Panel_Width/2;
   
   CreateLabel(PREFIX + "Vs_Title", centerX, lineY, "PENGATURAN TAMPILAN GT", gClrAccent, 11, FONT_MAIN, ANCHOR_CENTER);
   lineY += 60;
   
   string toggleText = extShowGTChart ? "MENONAKTIFKAN LEVEL GT" : "MENGAKTIFKAN LEVEL GT";
   color  toggleBg   = extShowGTChart ? gClrDanger : gClrSuccess;
   
   CreateButton(PREFIX + "TOG_CHART", centerX, lineY, 220, 40, toggleText, clrWhite, toggleBg);
   
   lineY += 80;
   CreateLabel(PREFIX + "Vs_Desc",  centerX, lineY, "Mengaktifkan/menonaktifkan tampilan garis GT secara langsung", clrWhite, 9, FONT_MAIN, ANCHOR_CENTER);
   lineY += 20;
   CreateLabel(PREFIX + "Vs_Desc2", centerX, lineY, "(Tinggi, Rendah, Awal, Inti) di grafik tabranij.", clrWhite, 9, FONT_MAIN, ANCHOR_CENTER);
}

bool CreateTabButton(string name, int x, int y, int w, int h, string text, bool active)
{
   if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0)) return false;
   ObjectSetInteger(0, name, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,    x - (w/2));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,        w - 4);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,        h);
   ObjectSetString(0, name,  OBJPROP_TEXT,         text);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,      8);
   ObjectSetInteger(0, name, OBJPROP_COLOR,         active ? clrWhite : clrSilver);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,       active ? gClrAccent : gClrHdr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR,  active ? clrWhite : clrDimGray);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,    false);
   return true;
}

bool CreateButton(string name, int x, int y, int w, int h, string text, color txtClr, color bgClr)
{
   if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0)) return false;
   ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,   x - (w/2));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,   y - (h/2));
   ObjectSetInteger(0, name, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,       h);
   ObjectSetString(0, name,  OBJPROP_TEXT,        text);
   ObjectSetInteger(0, name, OBJPROP_COLOR,       txtClr);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     bgClr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR,clrSilver);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    8);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   return true;
}

void CreateCornerBrackets(int x, int y, int w, int h, int size, color clr)
{
   CreateRect(PREFIX+"TL1", x, y, size, 2, clr);           CreateRect(PREFIX+"TL2", x, y, 2, size, clr);
   CreateRect(PREFIX+"TR1", x + w - size, y, size, 2, clr);CreateRect(PREFIX+"TR2", x + w - 2, y, 2, size, clr);
   CreateRect(PREFIX+"BL1", x, y + h - 2, size, 2, clr);   CreateRect(PREFIX+"BL2", x, y + h - size, 2, size, clr);
   CreateRect(PREFIX+"BR1", x + w - size, y + h - 2, size, 2, clr); CreateRect(PREFIX+"BR2", x + w - 2, y + h - size, 2, size, clr);
}

//+------------------------------------------------------------------+
//| [7] Logic Functions                                              |
//+------------------------------------------------------------------+
void UpdateGUILabels()
{
   UpdateBarData(3, "_v3", gClrValue);
   UpdateBarData(2, "_v2", gClrValue);
   UpdateBarData(1, "_v1", gClrValue);
   UpdateBarData(0, "_v0", gClrAccent);
   
   UpdateInfoSection();
   ChartRedraw();
}

void UpdateInfoSection()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   int    spread  = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   
   double symbolPL = 0;
   double buyLots = 0, sellLots = 0;
   double buyPriceSum = 0, sellPriceSum = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            double lots  = PositionGetDouble(POSITION_VOLUME);
            double price = PositionGetDouble(POSITION_PRICE_OPEN);
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            
            if(posType == POSITION_TYPE_BUY)  { buyLots  += lots; buyPriceSum  += price * lots; }
            else if(posType == POSITION_TYPE_SELL) { sellLots += lots; sellPriceSum += price * lots; }
               
            symbolPL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION);
         }
      }
   }
   
   double avgBuyPrice  = (buyLots  > 0) ? buyPriceSum  / buyLots  : 0;
   double avgSellPrice = (sellLots > 0) ? sellPriceSum / sellLots : 0;
   
   SetVal(PREFIX + "Acc_BalVal",   DoubleToString(balance, 2), gClrValue);
   SetVal(PREFIX + "Acc_EqVal",    DoubleToString(equity,  2), gClrValue);
   SetVal(PREFIX + "Sym_SpreadVal",IntegerToString(spread),    gClrValue);

   double netLots        = buyLots - sellLots;
   double tickSize       = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue      = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double pointValuePerLot = (tickSize > 0) ? tickValue * (myPoint / tickSize) : myPoint;
   double pointValueTotal  = MathAbs(netLots) * pointValuePerLot;
   double ptsFloating = (pointValueTotal > 0) ? symbolPL / pointValueTotal : 0;

   string plStr;
   color  plColor = gClrValue;
   
   if(symbolPL > 0.005)
   {
      plColor = gClrSuccess;
      plStr = (pointValueTotal > 0)
         ? StringFormat("▲ +%.2f (+%d pts)", symbolPL, (int)MathRound(ptsFloating))
         : StringFormat("▲ +%.2f (Hedged)", symbolPL);
   }
   else if(symbolPL < -0.005)
   {
      plColor = gClrDanger;
      plStr = (pointValueTotal > 0)
         ? StringFormat("▼ %.2f (%d pts)", symbolPL, (int)MathRound(ptsFloating))
         : StringFormat("▼ %.2f (Hedged)", symbolPL);
   }
   else { plColor = gClrValue; plStr = "0.00 (0 pts)"; }
   SetVal(PREFIX + "Sym_PLVal", plStr, plColor);

   double margin      = AccountInfoDouble(ACCOUNT_MARGIN);
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   double stopOutLevel= AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
   long   stopOutMode = AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);

   string buyExpStr = "0.00 Lots", sellExpStr = "0.00 Lots";
   string ptsToSOStr = "-", eqToSOStr = "-";
   string marginLevelStr = "0.00%", stopOutPriceStr = "-";
   color  riskColor = gClrValue;

   int    dispDigits    = (myDigits > 4) ? 4 : myDigits;
   if(buyLots  > 0) buyExpStr  = StringFormat("%.2f @ %s ▲", buyLots,  DoubleToString(avgBuyPrice,  dispDigits));
   if(sellLots > 0) sellExpStr = StringFormat("%.2f @ %s ▼", sellLots, DoubleToString(avgSellPrice, dispDigits));

   if(buyLots > 0 || sellLots > 0)
   {
      if(margin > 0)
      {
         marginLevelStr = StringFormat("%.1f%% (SO: %.1f%%)", marginLevel, stopOutLevel);
         if(marginLevel < 150.0) riskColor = gClrDanger;
         else if(marginLevel < 300.0) riskColor = clrOrange;

         double equitySO  = (stopOutMode == ACCOUNT_STOPOUT_MODE_PERCENT) ? (stopOutLevel * margin) / 100.0 : stopOutLevel;
         double equityToSO = equity - equitySO;
         eqToSOStr = DoubleToString(equityToSO, 2);

         if(pointValueTotal > 0)
         {
            double ptsToSO = equityToSO / pointValueTotal;
            ptsToSOStr = StringFormat("%d pts", (int)MathMax(0, MathRound(ptsToSO)));
            double stopOutPrice = (netLots > 0)
               ? SymbolInfoDouble(_Symbol, SYMBOL_BID) - ptsToSO * myPoint
               : SymbolInfoDouble(_Symbol, SYMBOL_ASK) + ptsToSO * myPoint;
            stopOutPriceStr = DoubleToString(stopOutPrice, dispDigits);
         }
         else { ptsToSOStr = "Hedged"; stopOutPriceStr = "Hedged"; }
      }
   }

   SetVal(PREFIX + "Sym_BuyExpVal",  buyExpStr,      buyLots  > 0 ? gClrSuccess : gClrValue);
   SetVal(PREFIX + "Sym_SellExpVal", sellExpStr,     sellLots > 0 ? gClrDanger  : gClrValue);
   SetVal(PREFIX + "Acc_MLVal",      marginLevelStr, riskColor);
   SetVal(PREFIX + "Acc_SOEqVal",    eqToSOStr,      riskColor);
   SetVal(PREFIX + "Sym_SOPriceVal", stopOutPriceStr,riskColor);
   SetVal(PREFIX + "Sym_SOPtsVal",   ptsToSOStr,     riskColor);
}

void UpdateBarData(int shift, string suffix, color baseClr)
{
   double open  = iOpen(_Symbol,  PERIOD_CURRENT, shift);
   double close = iClose(_Symbol, PERIOD_CURRENT, shift);
   double high  = iHigh(_Symbol,  PERIOD_CURRENT, shift);
   double low   = iLow(_Symbol,   PERIOD_CURRENT, shift);
   
   if(open == 0) return;

   int    oc = (int)((close - open) / myPoint);
   int    lh = (int)((high  - low)  / myPoint);
   double bH = MathMax(open, close), bL = MathMin(open, close);
   int    ch = (int)((high - bH) / myPoint);
   int    cl = (int)((bL  - low) / myPoint);

   SetVal(PREFIX + "R_OH"    + suffix, DoubleToString(high,  myDigits), baseClr);
   SetVal(PREFIX + "R_CH"    + suffix, StringFormat("%d", ch),          baseClr);
   SetVal(PREFIX + "R_CL"    + suffix, StringFormat("%d", cl),          baseClr);
   SetVal(PREFIX + "R_OL"    + suffix, DoubleToString(low,   myDigits), baseClr);
   SetVal(PREFIX + "R_Awal"  + suffix, DoubleToString(open,  myDigits), baseClr);
   string ocStr = oc >= 0 ? StringFormat("%d ▲", oc) : StringFormat("%d ▼", -oc);
   SetVal(PREFIX + "R_OC"    + suffix, ocStr, oc >= 0 ? gClrSuccess : gClrDanger);
   SetVal(PREFIX + "R_LH"    + suffix, DoubleToString(close, myDigits), baseClr);
   SetVal(PREFIX + "R_Range" + suffix, StringFormat("%d", lh),          baseClr);
}

void SetVal(string name, string txt, color clr)
{
   ObjectSetString(0,  name, OBJPROP_TEXT,  txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| [8] Countdown Timer                                              |
//+------------------------------------------------------------------+
void UpdateCountdown()
{
   ENUM_TIMEFRAMES tf = Period();
   int periodSeconds  = PeriodSeconds(tf);
   
   datetime serverTimeLive = (datetime)((long)TimeLocal() + serverLocalOffset);
   datetime barOpenTime    = iTime(_Symbol, tf, 0);
   int elapsed   = (int)(serverTimeLive - barOpenTime);
   int remaining = periodSeconds - elapsed;
   if(remaining < 0) remaining = 0;
   
   int hours   = remaining / 3600;
   int minutes = (remaining % 3600) / 60;
   int seconds = remaining % 60;
   
   string countdownText = (hours > 0)
      ? StringFormat("%02d:%02d:%02d", hours, minutes, seconds)
      : StringFormat("%02d:%02d", minutes, seconds);
   
   color cdColor;
   if(remaining <= 10)
      cdColor = clrRed;
   else if(remaining <= 60)
   {
      color rainbow[] = {clrCyan, clrMagenta, clrYellow, clrLime, clrOrange, clrWhite, clrRed, clrBlue, clrGreen, clrAqua};
      cdColor = rainbow[seconds % ArraySize(rainbow)];
   }
   else
      cdColor = COLOR_COUNTDOWN;
   
   SetVal(PREFIX + "CountdownIcon", "p", cdColor);
   SetVal(PREFIX + "Countdown",     countdownText, cdColor);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| [9] EA Trading Logic                                             |
//+------------------------------------------------------------------+
int CountMyPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == (long)InpMagic)
            count++;
   }
   return count;
}

ulong GetLastClosedDeal(double &outProfit, ENUM_POSITION_TYPE &outType)
{
   HistorySelect(TimeCurrent() - 7*24*3600, TimeCurrent());
   int total = HistoryDealsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC)  != (long)InpMagic) continue;
      if(HistoryDealGetString(ticket,  DEAL_SYMBOL) != _Symbol) continue;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;
      
      outProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                + HistoryDealGetDouble(ticket, DEAL_SWAP)
                + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      
      ENUM_DEAL_TYPE dtype = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
      outType = (dtype == DEAL_TYPE_SELL) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
      return ticket;
   }
   return 0;
}

// Order dengan SL/TP tetap dalam points (mode Sekuensial, sama seperti v0.01)
bool PlaceOrder(ENUM_POSITION_TYPE type, double lot, string comment)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double price, sl, tp;
   bool result = false;
   
   if(type == POSITION_TYPE_BUY)
   {
      price  = ask;
      sl     = (InpSL > 0) ? NormalizeDouble(price - InpSL * myPoint, myDigits) : 0;
      tp     = (InpTP > 0) ? NormalizeDouble(price + InpTP * myPoint, myDigits) : 0;
      result = trade.Buy(lot, _Symbol, price, sl, tp, comment);
   }
   else
   {
      price  = bid;
      sl     = (InpSL > 0) ? NormalizeDouble(price + InpSL * myPoint, myDigits) : 0;
      tp     = (InpTP > 0) ? NormalizeDouble(price - InpTP * myPoint, myDigits) : 0;
      result = trade.Sell(lot, _Symbol, price, sl, tp, comment);
   }
   
   if(result)
      Print("GT EA: Order [", (type == POSITION_TYPE_BUY ? "BUY" : "SELL"), "] Lot:", DoubleToString(lot,2), " | ", comment);
   else
      Print("GT EA: Order FAILED - ", trade.ResultRetcodeDescription());
   
   return result;
}

// Order dengan SL/TP berupa harga (mode ICT)
bool PlaceOrderEx(ENUM_POSITION_TYPE type, double lot, double sl, double tp, string comment)
{
   double price  = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                               : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool result = false;
   sl = NormalizeDouble(sl, myDigits);
   tp = NormalizeDouble(tp, myDigits);
   
   if(type == POSITION_TYPE_BUY)
      result = trade.Buy(lot, _Symbol, price, sl, tp, comment);
   else
      result = trade.Sell(lot, _Symbol, price, sl, tp, comment);
   
   if(result)
      Print("GT ICT: Order [", (type == POSITION_TYPE_BUY ? "BUY" : "SELL"), "] Lot:", DoubleToString(lot,2),
            " SL:", DoubleToString(sl, myDigits), " TP:", DoubleToString(tp, myDigits), " | ", comment);
   else
      Print("GT ICT: Order FAILED - ", trade.ResultRetcodeDescription());
   
   return result;
}

// Normalisasi lot ke batas dan step broker (pembulatan ke bawah)
double NormLotDown(double lot)
{
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(stepLot <= 0) stepLot = 0.01;
   int lotDigits = (int)MathMax(0, MathCeil(-MathLog10(stepLot) - 1e-9));
   lot = MathFloor(lot / stepLot + 1e-9) * stepLot;
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);
   return NormalizeDouble(lot, lotDigits);
}

// Lot untuk mode ICT: Base Lot, atau berdasarkan % risiko dan jarak SL
double IctLot(double slDist)
{
   double lot = InpLot;
   if(InpIctRiskPct > 0 && slDist > 0)
   {
      double risk     = AccountInfoDouble(ACCOUNT_EQUITY) * InpIctRiskPct / 100.0;
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize > 0 && tickVal > 0)
      {
         double lossPerLot = slDist / tickSize * tickVal;
         if(lossPerLot > 0) lot = risk / lossPerLot;
      }
   }
   return NormLotDown(lot);
}

//--- MODE ICT: entry dari sinyal pada candle yang baru close
void ExecuteIct()
{
   if(!g_ictReady) return;
   int n = g_main.m_n;
   if(n < 5) return;
   
   int    dir = 0;
   double sl = 0, tp = 0;
   if(g_main.m_buy[n-2] != EMPTY_VALUE)
   {
      dir = 1;
      sl  = g_main.m_buySL[n-2];
      tp  = g_main.m_buyTP[n-2];
   }
   else if(g_main.m_sell[n-2] != EMPTY_VALUE)
   {
      dir = -1;
      sl  = g_main.m_sellSL[n-2];
      tp  = g_main.m_sellTP[n-2];
   }
   if(dir == 0) return;
   
   // satu kali percobaan per bar (cegah entry ulang pada sinyal yang sama)
   datetime curBar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(curBar == g_ictAttemptBar) return;
   g_ictAttemptBar = curBar;
   
   if(CountMyPositions() > 0) return;
   
   if(InpMaxSpreadPts > 0)
   {
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(spread > InpMaxSpreadPts)
      {
         Print("GT ICT: Spread ", spread, " > ", InpMaxSpreadPts, " - sinyal dilewati.");
         return;
      }
   }
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minDist = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * myPoint;
   
   ENUM_POSITION_TYPE type = (dir > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   double entry = (dir > 0) ? ask : bid;
   
   // SL/TP harus masih valid terhadap harga sekarang
   if(dir > 0)
   {
      if(sl >= bid - minDist || tp <= ask + minDist)
      {
         Print("GT ICT: SL/TP BUY tidak valid terhadap harga sekarang - sinyal dilewati.");
         return;
      }
   }
   else
   {
      if(sl <= ask + minDist || tp >= bid - minDist)
      {
         Print("GT ICT: SL/TP SELL tidak valid terhadap harga sekarang - sinyal dilewati.");
         return;
      }
   }
   
   double lot = IctLot(MathAbs(entry - sl));
   PlaceOrderEx(type, lot, sl, tp, "GT ICT " + (dir > 0 ? "BUY" : "SELL"));
}

//--- MODE SEKUENSIAL: logika EA v0.01 (tidak diubah)
void ExecuteSequential()
{
   if(CountMyPositions() > 0) return;
   
   double lastProfit = 0;
   ENUM_POSITION_TYPE lastType = POSITION_TYPE_BUY;
   ulong lastDealTicket = GetLastClosedDeal(lastProfit, lastType);
   
   double nextLot;
   ENUM_POSITION_TYPE nextType;
   int lossStreak = 0;
   
   if(lastDealTicket == 0 || lastDealTicket == (ulong)g_lastDeal)
   {
      double lastOpen  = iOpen(_Symbol,  InpGTTimeframe, 1);
      double lastClose = iClose(_Symbol, InpGTTimeframe, 1);
      if(lastOpen == 0 || lastClose == 0) return;
      if(!g_isFirstTrade) return;
      
      if(lastClose > lastOpen)       nextType = POSITION_TYPE_BUY;
      else if(lastClose < lastOpen)  nextType = POSITION_TYPE_SELL;
      else return;
      
      nextLot = InpLot;
      g_isFirstTrade = false;
   }
   else
   {
      if(lastDealTicket == (ulong)g_lastDeal) return;
      g_lastDeal = (int)lastDealTicket;
      
      HistorySelect(TimeCurrent() - 30*24*3600, TimeCurrent());
      int total = HistoryDealsTotal();
      double runLot = InpLot;
      
      for(int i = total - 1; i >= 0; i--)
      {
         ulong tk = HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(tk, DEAL_MAGIC)  != (long)InpMagic) continue;
         if(HistoryDealGetString(tk,  DEAL_SYMBOL) != _Symbol) continue;
         ENUM_DEAL_ENTRY ent = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(tk, DEAL_ENTRY);
         if(ent != DEAL_ENTRY_OUT && ent != DEAL_ENTRY_INOUT) continue;
         
         double p = HistoryDealGetDouble(tk, DEAL_PROFIT)
                  + HistoryDealGetDouble(tk, DEAL_SWAP)
                  + HistoryDealGetDouble(tk, DEAL_COMMISSION);
         if(p < 0) { lossStreak++; if(lossStreak >= InpMaxSteps) break; }
         else break;
      }
      
      if(lastProfit >= 0)
      {
         nextType = lastType;
         nextLot  = InpLot;
      }
      else
      {
         nextType = (lastType == POSITION_TYPE_BUY) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
         if(lossStreak > 0 && lossStreak < InpMaxSteps)
            nextLot = NormalizeDouble(InpLot * MathPow(InpMultiplier, lossStreak), 2);
         else
         {
            nextLot = InpLot;
            Print("GT EA: Max Martingale Steps reached - resetting to base lot.");
         }
      }
   }
   
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   nextLot = MathMax(nextLot, minLot);
   nextLot = NormalizeDouble(MathRound(nextLot / stepLot) * stepLot, 2);
   
   string comment = StringFormat("GT|Step%d|Lot%.2f", lossStreak, nextLot);
   PlaceOrder(nextType, nextLot, comment);
}

void ExecuteTradingLogic()
{
   if(InpMode == MODE_ICT)
      ExecuteIct();
   else
      ExecuteSequential();
}

//+------------------------------------------------------------------+
//| [10] Close All Positions                                         |
//+------------------------------------------------------------------+
void CloseAllPositions(bool pos, bool pend)
{
   if(pos)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == (long)InpMagic)
               trade.PositionClose(ticket);
      }
   }
   if(pend)
   {
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(OrderSelect(ticket))
            if(OrderGetString(ORDER_SYMBOL) == _Symbol && 
               OrderGetInteger(ORDER_MAGIC) == (long)InpMagic)
               trade.OrderDelete(ticket);
      }
   }
}
//+------------------------------------------------------------------+
