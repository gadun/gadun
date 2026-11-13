//+------------------------------------------------------------------+
//|                                                  ICT_SMC_CRT.mq5 |
//|  Indikator gabungan ICT + SMC + CRT (all-in-one) untuk MT5       |
//|                                                                  |
//|  BUFFER (untuk dibaca EA lewat iCustom / CopyBuffer):            |
//|   0 = Sinyal BUY  (harga posisi panah, EMPTY_VALUE = tidak ada)  |
//|   1 = Sinyal SELL (harga posisi panah, EMPTY_VALUE = tidak ada)  |
//|   2 = SL untuk BUY    3 = TP untuk BUY                           |
//|   4 = SL untuk SELL   5 = TP untuk SELL                          |
//|   6 = Bias (1 = bullish, -1 = bearish, 0 = netral)               |
//|                                                                  |
//|  Semua sinyal dihitung hanya pada candle yang sudah close.       |
//+------------------------------------------------------------------+
#property copyright "ICT + SMC + CRT"
#property version   "1.00"
#property description "ICT + SMC + CRT all-in-one. Bukan jaminan profit. Uji di demo dulu."
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7

#property indicator_label1  "Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_width1  2
#property indicator_label2  "Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  2

//+------------------------------------------------------------------+
//| Enum                                                             |
//+------------------------------------------------------------------+
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
//| Input                                                            |
//+------------------------------------------------------------------+
input group "=== UMUM ==="
input int    InpMaxBars        = 1500;   // Jumlah bar yang dianalisis
input int    InpAtrPeriod      = 14;     // Periode ATR
input int    InpExtendBars     = 15;     // Perpanjangan objek ke kanan (bar)
input bool   InpShowPanel      = true;   // Tampilkan panel info
input int    InpMaxSigDraw     = 5;      // Jumlah sinyal terakhir yang digambar SL/TP-nya

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

input group "=== SINYAL ==="
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
//| Konstanta                                                        |
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
//| Variabel global                                                  |
//+------------------------------------------------------------------+
CSmc     g_main;
CSmc     g_htf;
bool     g_htfOk=false;
datetime g_lastBar=0;
datetime g_lastAlert=0;
bool     g_alertInit=false;
int      g_oc=0;

double BufBuy[];
double BufSell[];
double BufBuySL[];
double BufBuyTP[];
double BufSellSL[];
double BufSellTP[];
double BufBias[];

//+------------------------------------------------------------------+
//| Fungsi gambar                                                    |
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
   string n=NM("T");
   if(!ObjectCreate(0,n,OBJ_TEXT,0,t,p))
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
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,16);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,28+idx*16);
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
      ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,8);
      ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,22);
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

void DrawAll()
  {
   ObjectsDeleteAll(0,PFX);
   g_oc=0;
   if(g_main.m_n<10)
      return;
   if(InpShowKZ)
      DrawKillzones(g_main);
   if(InpShowLiq)
      DrawLiq(g_main);
   DrawRange(g_main);
   if(InpShowHtfZones && g_htfOk)
      DrawZones(g_htf,true);
   DrawZones(g_main,false);
   DrawLines(g_main);
   if(InpShowCRT)
      DrawCrt(g_main);
   DrawSignals(g_main);
   if(InpShowPanel)
      DrawPanel(g_main);
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
   msg="ICT_SMC_CRT: "+msg;
   if(InpAlertPopup)
      Alert(msg);
   if(InpAlertPush)
      SendNotification(msg);
   if(InpAlertMail)
      SendMail("ICT_SMC_CRT",msg);
  }

//+------------------------------------------------------------------+
//| Event indikator                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,BufBuy,INDICATOR_DATA);
   SetIndexBuffer(1,BufSell,INDICATOR_DATA);
   SetIndexBuffer(2,BufBuySL,INDICATOR_DATA);
   SetIndexBuffer(3,BufBuyTP,INDICATOR_DATA);
   SetIndexBuffer(4,BufSellSL,INDICATOR_DATA);
   SetIndexBuffer(5,BufSellTP,INDICATOR_DATA);
   SetIndexBuffer(6,BufBias,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   string nm[7]={"Buy","Sell","BuySL","BuyTP","SellSL","SellTP","Bias"};
   for(int p=0;p<7;p++)
     {
      PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      PlotIndexSetString(p,PLOT_LABEL,nm[p]);
      if(p>=2)
         PlotIndexSetInteger(p,PLOT_DRAW_TYPE,DRAW_NONE);
     }
   IndicatorSetString(INDICATOR_SHORTNAME,"ICT+SMC+CRT");
   SetupSessions();
   g_lastBar=0;
   g_alertInit=false;
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,PFX);
   ChartRedraw();
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total<100)
      return 0;
   datetime lastT=time[rates_total-1];
   if(prev_calculated>0 && lastT==g_lastBar)
      return rates_total;

   int cnt=MathMin(InpMaxBars,rates_total);
   if(!g_main.Load(_Period,cnt))
      return 0;

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

   //--- salin ke buffer
   for(int k=0;k<rates_total;k++)
     {
      BufBuy[k]=EMPTY_VALUE;
      BufSell[k]=EMPTY_VALUE;
      BufBuySL[k]=EMPTY_VALUE;
      BufBuyTP[k]=EMPTY_VALUE;
      BufSellSL[k]=EMPTY_VALUE;
      BufSellTP[k]=EMPTY_VALUE;
      BufBias[k]=0.0;
     }
   int n=g_main.m_n;
   int off=rates_total-n;
   for(int i=0;i<n;i++)
     {
      int k=off+i;
      if(k<0 || k>=rates_total)
         continue;
      BufBuy[k]=g_main.m_buy[i];
      BufSell[k]=g_main.m_sell[i];
      BufBuySL[k]=g_main.m_buySL[i];
      BufBuyTP[k]=g_main.m_buyTP[i];
      BufSellSL[k]=g_main.m_sellSL[i];
      BufSellTP[k]=g_main.m_sellTP[i];
      BufBias[k]=g_main.m_bias[i];
     }

   DrawAll();
   CheckAlert();
   g_lastBar=lastT;
   return rates_total;
  }
//+------------------------------------------------------------------+
