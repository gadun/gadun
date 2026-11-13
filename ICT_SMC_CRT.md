# ICT + SMC + CRT All-in-One Indicator (MT5)

Indikator custom MetaTrader 5 yang menggabungkan konsep **ICT (Inner Circle Trader)**, **SMC (Smart Money Concepts)**, dan **CRT (Candle Range Theory)** dalam satu file: `ICT_SMC_CRT.mq5`.

> **Disclaimer:** indikator ini hanya mengotomatiskan aturan visual. Ia tidak menjamin profit. Penandaan zona dalam ICT/SMC bersifat subjektif, jadi hasilnya bergantung pada parameter. Uji di data historis dan akun demo sebelum dipakai di akun real.

---

## Daftar Isi

1. [Instalasi](#1-instalasi)
2. [Fitur](#2-fitur)
3. [Cara Membaca Chart](#3-cara-membaca-chart)
4. [Logika Sinyal](#4-logika-sinyal)
5. [Parameter](#5-parameter)
6. [Buffer untuk EA](#6-buffer-untuk-ea)
7. [Rekomendasi Pengaturan Awal](#7-rekomendasi-pengaturan-awal)
8. [Anti-Repaint dan Batasan](#8-anti-repaint-dan-batasan)
9. [Pemecahan Masalah](#9-pemecahan-masalah)

---

## 1. Instalasi

1. Di MT5, buka **File > Open Data Folder**.
2. Salin `ICT_SMC_CRT.mq5` ke folder `MQL5/Indicators`.
3. Buka file di **MetaEditor** lalu tekan **F7** (Compile).
4. Di MT5, pasang indikator lewat **Insert > Indicators > Custom > ICT_SMC_CRT**, atau seret dari panel Navigator.

**Persiapan data:** indikator memakai data H4 (HTF dan CRT), D1, dan W1 (level PDH/PDL/PWH/PWL). Buka sekali chart H4, D1, dan W1 pada simbol yang sama supaya riwayatnya terunduh. Jika tidak, zona HTF atau level harian/mingguan bisa belum muncul.

---

## 2. Fitur

### SMC (Smart Money Concepts)

| Fitur | Keterangan |
|---|---|
| Struktur Swing | BOS dan CHoCH berdasarkan swing besar (`InpSwingLen`) |
| Struktur Internal | BOS dan CHoCH kecil (`InpIntLen`), diberi awalan `i` (iBOS, iCHoCH) |
| EQH / EQL | Equal highs/lows dari micro-pivot dalam toleransi ATR |
| Liquidity Sweep | Wick menembus level swing lalu close kembali di dalam, ditandai `x BSL` atau `x SSL` |
| Inducement (IDM) | Micro-swing yang tersapu setelah struktur berubah |
| Strong / Weak High-Low | Label pada swing terakhir sesuai arah tren swing |
| Order Block (OB) | Candle berlawanan terdekat pada leg impuls yang menghasilkan BOS/CHoCH |
| Breaker Block | OB yang gagal (close menembus sisi seberang), arahnya dibalik |
| Mitigation Block | Dibuat saat CHoCH terjadi setelah swing gagal membuat ekstrem baru |
| FVG | Celah tiga candle, lengkap dengan garis tengah (Consequent Encroachment) |

### ICT

| Fitur | Keterangan |
|---|---|
| Premium / Discount | Dua area dari range swing terakhir, dengan garis Equilibrium 50% |
| OTE | Zona Optimal Trade Entry 62%-79% |
| Liquidity Level | PDH, PDL (hari sebelumnya) dan PWH, PWL (minggu sebelumnya) |
| Killzone | Kotak high-low sesi Asia, London, NY AM, London Close |
| Silver Bullet | Tiga jendela 1 jam (opsional) |
| IFVG | FVG yang ditutup menembus sisi seberang, arahnya dibalik |
| Volume Imbalance | Celah antar-body candle searah dengan wick yang tetap tumpang tindih |
| Liquidity Void | Candle dengan body besar (sekian kali ATR), area body dianggap void |

### CRT (Candle Range Theory)

- Candle acuan **C1** pada timeframe `InpCrtTF` (bawaan H4).
- **C2** menyapu satu sisi C1 lalu **close kembali di dalam range** C1.
- Bias mengikuti arah sapuan: sapu low menghasilkan bullish, sapu high menghasilkan bearish.
- CRT berhenti berlaku jika: melewati `InpCrtValid` candle HTF, harga close melewati ekstrem sapuan C2, atau target sisi seberang C1 tercapai.

### Multi-Timeframe

- OB, FVG, dan Breaker dari timeframe `InpHtf` (bawaan H4) digambar di chart kecil, berbingkai putus-putus dan berawalan nama timeframe (misalnya `H4 Bull OB`).
- Tren struktur swing HTF ikut menjadi sumber bias.

### Sinyal dan Alat Bantu

- Panah **BUY** (hijau) dan **SELL** (merah).
- Garis **SL** (merah putus-putus) dan **TP** (hijau putus-putus) beserta harganya.
- **Panel info** di pojok kiri atas: bias, status CRT, tren struktur, sesi aktif, dan sinyal terakhir.
- **Alert** popup, push notification, dan email.

---

## 3. Cara Membaca Chart

| Tampilan | Arti |
|---|---|
| Garis solid hijau/merah berlabel `BOS` / `CHoCH` | Struktur swing (bullish hijau, bearish merah) |
| Garis titik-titik berlabel `iBOS` / `iCHoCH` | Struktur internal |
| Garis oranye `EQH` / `EQL` | Equal highs/lows (kumpulan likuiditas) |
| Garis magenta putus-putus `IDM` | Inducement tersapu |
| Teks `x BSL` / `x SSL` | Sweep likuiditas sisi atas (buy-side) / sisi bawah (sell-side) |
| Kotak berisi `Bull OB` / `Bear OB` | Order Block |
| Kotak berisi `Bull FVG` / `Bear FVG` + garis tengah | Fair Value Gap |
| Kotak `Breaker`, `MB`, `IFVG`, `VI`, `Void` | Breaker, Mitigation Block, IFVG, Volume Imbalance, Liquidity Void |
| Kotak merah titik-titik `Premium`, hijau `Discount`, garis abu `EQ 50%` | Area PD dari swing terakhir |
| Kotak emas `OTE` | Zona 62%-79% |
| Kotak emas `CRT Bull H4` / `CRT Bear H4` + garis titik tengah | Range candle acuan CRT; garis oranye tebal = ekstrem sapuan C2 |
| Garis `PDH` `PDL` `PWH` `PWL` | Level likuiditas harian dan mingguan |
| Kotak berwarna berlabel `Asia`, `London`, `NY AM`, ... | Rentang high-low selama sesi/killzone |

Zona yang sudah termitigasi disembunyikan, kecuali `InpShowMitigated` diaktifkan.

---

## 4. Logika Sinyal

Sinyal **BUY** muncul bila semua syarat berikut terpenuhi (SELL adalah kebalikannya):

1. **Bias bullish** dari CRT dan/atau struktur HTF, sesuai `InpBiasMode`.
2. **Liquidity sweep sisi bawah** terjadi dalam `InpSetupBars` bar terakhir. Sapuan bisa berasal dari swing, swing internal, atau CRT.
3. **BOS/CHoCH bullish** terjadi setelah sapuan tersebut (juga dalam `InpSetupBars`).
4. *(Opsional)* **IDM tersapu** (`InpReqIDM`).
5. Zona entri yang dibuat setelah sapuan (OB, FVG, Mitigation Block, atau Breaker bullish) **"dipersenjatai"**, lalu harga **kembali menyentuh zona** dan close tidak menembus sisi bawah zona.
6. *(Opsional)* Titik tengah zona berada di **discount** (`InpReqPD`).
7. *(Opsional)* Candle berada di dalam **killzone** aktif (`InpReqKZ`).
8. **RR minimal** terpenuhi (`InpMinRR`).

**Stop Loss:** di bawah zona entri atau di bawah ekstrem sapuan (yang lebih jauh), ditambah buffer `InpSlBufATR` x ATR.

**Take Profit** (`InpTpMode`):

- `TP_LIQUIDITY`: level likuiditas terdekat di sisi berlawanan yang memenuhi RR minimum, dari kandidat high swing internal, high swing besar, sisi atas CRT, PDH, dan PWH. Jika tidak ada, dipakai kelipatan `InpRR`.
- `TP_CRT50`: 50% range CRT, atau sisi seberang CRT bila 50% terlalu dekat. Jika CRT tidak aktif, kembali ke logika likuiditas.
- `TP_RR`: kelipatan `InpRR` dari jarak SL.

Setiap zona hanya menghasilkan satu sinyal, dan zona kedaluwarsa setelah `InpArmExpire` bar.

---

## 5. Parameter

### Umum

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpMaxBars` | 1500 | Jumlah bar yang dianalisis (lebih besar = lebih lambat) |
| `InpAtrPeriod` | 14 | Periode ATR |
| `InpExtendBars` | 15 | Perpanjangan objek ke kanan (bar) |
| `InpShowPanel` | true | Panel info |
| `InpMaxSigDraw` | 5 | Jumlah sinyal terakhir yang digambar SL/TP-nya |

### Struktur Pasar (SMC)

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpShowSwing` / `InpSwingLen` | true / 10 | Tampilkan struktur swing / panjang swing |
| `InpShowInternal` / `InpIntLen` | true / 3 | Tampilkan struktur internal / panjang swing internal |
| `InpMicroLen` | 2 | Panjang micro-pivot untuk EQH/EQL dan IDM |
| `InpShowEQ` / `InpEqTolATR` | true / 0.10 | Tampilkan EQH/EQL / toleransi (x ATR) |
| `InpShowSweep` | true | Tampilkan sweep |
| `InpShowIDM` | true | Tampilkan inducement |
| `InpShowStrongWeak` | true | Label Strong/Weak High-Low |
| `InpMaxEvents` | 15 | Maks BOS/CHoCH yang digambar per jenis |
| `InpColStrBull` / `InpColStrBear` | LimeGreen / Red | Warna struktur |

### Zona

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpShowOB`, `InpShowFVG`, `InpShowBreaker`, `InpShowMitig`, `InpShowIFVG`, `InpShowVI`, `InpShowVoid` | true | Aktif/nonaktif tiap jenis zona |
| `InpFvgMinATR` | 0.10 | Ukuran minimum FVG (x ATR) |
| `InpVoidATR` | 2.0 | Body minimum Liquidity Void (x ATR) |
| `InpShowMitigated` | false | Tampilkan juga zona yang sudah termitigasi |
| `InpFillZones` | true | Isi warna zona |
| `InpMaxZones` | 6 | Maks zona aktif digambar per jenis |
| `InpColBullOB`, `InpColBearOB`, `InpColBullFVG`, `InpColBearFVG`, `InpColBreaker`, `InpColMitig` | lihat kode | Warna zona |

### Multi-Timeframe

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpShowHtfZones` | true | Tampilkan zona HTF |
| `InpHtf` | H4 | Timeframe HTF untuk bias struktur dan zona |
| `InpHtfSwingLen` | 5 | Panjang swing HTF |
| `InpHtfMaxZones` | 3 | Maks zona HTF per jenis |

### CRT

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpShowCRT` | true | Tampilkan kotak CRT |
| `InpCrtTF` | H4 | Timeframe candle acuan |
| `InpCrtValid` | 3 | CRT berlaku berapa candle HTF setelah C2 close |
| `InpCrtBoxes` | 3 | Jumlah kotak CRT terakhir yang digambar |

### ICT: PD Array, OTE, Likuiditas

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpShowPD` | true | Premium / Discount / EQ |
| `InpShowOTE` | true | Zona OTE |
| `InpShowLiq` | true | PDH/PDL dan PWH/PWL |

### ICT: Killzone dan Silver Bullet (jam GMT)

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpShowKZ` | true | Gambar kotak sesi |
| `InpKzDays` | 3 | Berapa hari ke belakang yang digambar |
| `InpGmtOffset` | 0 | **Selisih jam server broker terhadap GMT** (contoh: 2 atau 3). Wajib disesuaikan |
| `InpKzAsia`, `InpAsiaS`, `InpAsiaE` | true, 1, 5 | Asia |
| `InpKzLondon`, `InpLondonS`, `InpLondonE` | true, 7, 10 | London |
| `InpKzNYAM`, `InpNYAMS`, `InpNYAME` | true, 12, 15 | New York AM |
| `InpKzLC`, `InpLCS`, `InpLCE` | false, 15, 17 | London Close |
| `InpKzSB`, `InpSB1`, `InpSB2`, `InpSB3` | false, 8, 15, 19 | Silver Bullet (jam mulai tiap jendela, durasi 1 jam) |

Catatan:

- Jam bawaan mengacu waktu New York musim dingin (EST). Saat DST Amerika Serikat, geser sekitar 1 jam lebih awal.
- Cara mencari `InpGmtOffset`: bandingkan jam server di Market Watch dengan jam GMT. Selisihnya adalah nilai yang diisi.
- Kotak killzone hanya bermakna di timeframe H1 ke bawah.

### Sinyal

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpBiasMode` | CRT dulu, lalu HTF | Sumber bias: CRT saja / HTF saja / CRT dulu lalu HTF / keduanya harus searah |
| `InpReqSweep` | true | Wajib ada liquidity sweep |
| `InpReqIDM` | false | Wajib ada inducement tersapu |
| `InpReqPD` | true | Buy hanya di discount, sell hanya di premium |
| `InpReqKZ` | false | Entri hanya dalam killzone aktif |
| `InpSetupBars` | 40 | Jendela waktu sweep ke BOS/CHoCH (bar) |
| `InpArmExpire` | 100 | Zona kedaluwarsa setelah n bar |
| `InpEntryOB`, `InpEntryFVG`, `InpEntryMitig`, `InpEntryBreaker` | true | Jenis zona yang boleh dipakai entri |
| `InpSlBufATR` | 0.20 | Buffer SL (x ATR) |
| `InpTpMode` | Likuiditas | Mode TP |
| `InpRR` | 2.0 | RR cadangan / mode RR |
| `InpMinRR` | 1.0 | RR minimum agar sinyal valid |

### Alert

| Parameter | Bawaan | Fungsi |
|---|---|---|
| `InpAlertPopup` | true | Alert popup |
| `InpAlertPush` | false | Push notification (perlu setup MetaQuotes ID) |
| `InpAlertMail` | false | Email (perlu setup email di MT5) |

Alert dikirim satu kali saat candle baru dibuka, untuk sinyal pada candle yang baru saja close.

---

## 6. Buffer untuk EA

| Indeks | Isi |
|---|---|
| 0 | Sinyal BUY (harga posisi panah; `EMPTY_VALUE` = tidak ada) |
| 1 | Sinyal SELL (harga posisi panah; `EMPTY_VALUE` = tidak ada) |
| 2 | SL untuk BUY |
| 3 | TP untuk BUY |
| 4 | SL untuk SELL |
| 5 | TP untuk SELL |
| 6 | Bias: `1` bullish, `-1` bearish, `0` netral |

Contoh membaca sinyal dari EA (memakai input bawaan):

```mql5
int h = iCustom(_Symbol, _Period, "ICT_SMC_CRT");

double buy[], sell[], sl[], tp[];
ArraySetAsSeries(buy,  true);
ArraySetAsSeries(sell, true);
ArraySetAsSeries(sl,   true);
ArraySetAsSeries(tp,   true);

// shift 1 = candle terakhir yang sudah close
CopyBuffer(h, 0, 1, 1, buy);
CopyBuffer(h, 1, 1, 1, sell);

if(buy[0] != EMPTY_VALUE)
  {
   CopyBuffer(h, 2, 1, 1, sl);
   CopyBuffer(h, 3, 1, 1, tp);
   // buka posisi BUY dengan sl[0] dan tp[0]
  }
if(sell[0] != EMPTY_VALUE)
  {
   CopyBuffer(h, 4, 1, 1, sl);
   CopyBuffer(h, 5, 1, 1, tp);
   // buka posisi SELL dengan sl[0] dan tp[0]
  }
```

Catatan:

- Buat handle `iCustom` sekali di `OnInit`, bukan di setiap tick.
- Jika ingin mengubah input lewat `iCustom`, semua parameter harus diisi berurutan sesuai daftar input di indikator.
- Nilai buffer 0 dan 1 adalah posisi panah (sedikit di luar candle), bukan harga entri. Gunakan harga market atau close candle sebagai entri.
- Selalu uji di Strategy Tester sebelum dipakai.

---

## 7. Rekomendasi Pengaturan Awal

**Scalping XAUUSD (M5-M15)**

- `InpHtf` = H1 atau H4, `InpCrtTF` = H1 atau H4.
- `InpGmtOffset` sesuai broker, `InpReqKZ` = true (London dan NY AM).
- `InpMinRR` = 1.5.

**Intraday (M15-H1)**

- Pakai pengaturan bawaan, lalu naikkan `InpSwingLen` ke 12-15 jika struktur terlalu ramai.

**Sinyal lebih selektif**

- `InpBiasMode` = CRT dan HTF searah, `InpReqIDM` = true, `InpMinRR` = 2.

**Chart terlalu penuh**

- Kecilkan `InpMaxZones` dan `InpMaxEvents`.
- Matikan `InpShowVI`, `InpShowVoid`, `InpShowIFVG`, dan `InpShowMitig`.
- Nonaktifkan `InpShowInternal`.

---

## 8. Anti-Repaint dan Batasan

- Perhitungan dilakukan ulang setiap **candle baru dibuka**, dari `InpMaxBars` bar terakhir. Sinyal dan zona pada candle yang sudah close tidak berubah antar-tick.
- Swing baru terkonfirmasi setelah N candle ditutup (N = panjang swing). Artinya struktur selalu terdeteksi dengan jeda, bukan di titik ekstremnya.
- Bias HTF dan CRT hanya memakai candle HTF yang **sudah close**.
- Perubahan parameter atau penggantian timeframe memicu perhitungan ulang penuh.
- Beberapa definisi disederhanakan agar dapat dikodekan secara objektif: Mitigation Block, Liquidity Void, dan Volume Imbalance. Hasilnya bisa berbeda dari tafsiran trader lain.
- Volume Imbalance jarang muncul pada instrumen dengan harga yang hampir kontinu (misalnya emas dan forex).
- Terlalu banyak syarat aktif membuat sinyal jarang. Terlalu sedikit syarat membuat sinyal palsu bertambah.

---

## 9. Pemecahan Masalah

| Masalah | Penyebab dan solusi |
|---|---|
| Tidak ada sinyal | Syarat terlalu ketat. Coba matikan `InpReqPD`, turunkan `InpMinRR`, atau ubah `InpBiasMode` menjadi CRT dulu lalu HTF |
| Zona HTF atau PDH/PWH tidak muncul | Riwayat H4/D1/W1 belum terunduh. Buka chart timeframe tersebut sekali |
| Kotak killzone meleset jamnya | Atur `InpGmtOffset` sesuai broker, dan sesuaikan jam saat DST |
| Panel atau objek tidak muncul | Pastikan `InpShowPanel` aktif dan chart memiliki cukup bar (minimal 100) |
| Chart lambat | Turunkan `InpMaxBars` (misalnya 800) dan batasi jumlah zona yang digambar |
| Ingin menghapus semua objek | Lepas indikator dari chart; semua objek berawalan `ICS_` ikut dihapus |
| EA tidak membaca buffer | Pastikan nama file pada `iCustom` benar (`ICT_SMC_CRT`) dan baca candle dengan shift 1 |
