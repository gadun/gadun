# ICT_SMC_CRT.mq5

Panduan simbol, label, warna, dan cara membaca indikator **ICT + SMC + CRT all-in-one** (versi 1.01) di chart MetaTrader 5.

> **Penting:** indikator ini alat bantu analisis, bukan jaminan profit. Uji dulu di akun demo dan selalu gunakan manajemen risiko.

## 1. Instalasi singkat

1. Salin `ICT_SMC_CRT.mq5` ke folder `MQL5/Indicators` (MT5: File > Open Data Folder).
2. Buka MetaEditor, kompilasi file (F7).
3. Seret indikator dari jendela Navigator ke chart.
4. Atur `InpGmtOffset` sesuai selisih jam server broker terhadap GMT (misalnya 2 atau 3). Ini penting agar kotak sesi/killzone tepat.

Indikator hanya menganalisis candle yang **sudah close**. Analisis dihitung ulang setiap ada candle baru, sedangkan susunan label dirapikan ulang otomatis saat Anda zoom atau mengubah ukuran jendela.

## 2. Cara membaca label: arah dan warna

- Awalan **Bull** = zona/struktur bullish (arah naik, area permintaan/demand).
- Awalan **Bear** = zona/struktur bearish (arah turun, area penawaran/supply).
- Awalan **i** (iBOS, iCHoCH) = struktur **internal** (kecil). Tanpa awalan = struktur **swing** (besar).
- Awalan timeframe seperti **H4 Bull OB** = zona berasal dari timeframe lebih tinggi (HTF), bukan dari timeframe chart.
- Garis **solid** = zona aktif di timeframe chart. Garis **titik-titik** = zona yang sudah termitigasi atau zona dari HTF.
- Zona aktif di timeframe chart diisi warna (jika `InpFillZones` aktif).
- Teks bisa sedikit bergeser ke atas atau bawah dari level harganya agar tidak bertumpuk dengan teks lain (lihat bagian 9). Gunakan garis/kotak sebagai patokan harga yang tepat, bukan posisi teks.

## 3. Struktur pasar (SMC)

| Label | Warna | Artinya |
|---|---|---|
| **BOS** | Hijau (bullish) / Merah (bearish) | *Break of Structure* swing: candle **close** menembus swing high/low besar searah tren yang sedang berjalan. Konfirmasi tren berlanjut. Garis solid. |
| **CHoCH** | Hijau / Merah | *Change of Character* swing: close menembus swing berlawanan dengan tren sebelumnya. Tanda awal perubahan tren. Garis solid. |
| **iBOS** | Hijau / Merah | BOS pada struktur internal (swing kecil, panjang `InpIntLen`). Garis titik-titik, font lebih kecil. |
| **iCHoCH** | Hijau / Merah | CHoCH pada struktur internal. Sering muncul lebih dulu daripada CHoCH swing sehingga dipakai sebagai sinyal dini. |
| **EQH** | Oranye | *Equal Highs*: dua puncak mikro yang hampir sama tinggi (selisih maksimal `InpEqTolATR` x ATR). Menandakan likuiditas buy-side menumpuk di atasnya. |
| **EQL** | Oranye | *Equal Lows*: dua lembah mikro hampir sama rendah. Likuiditas sell-side menumpuk di bawahnya. |
| **IDM** | Magenta (garis putus-putus) | *Inducement*: low mikro (saat struktur internal bullish) atau high mikro (saat bearish) yang berhasil diambil harga. Sering dianggap jebakan sebelum pergerakan sebenarnya. |
| **x BSL** | Oranye tua | *Buy-Side Liquidity* tersapu: harga menembus swing high lalu close kembali di bawahnya. Condong ke bias **bearish**. Muncul di ujung high. |
| **x SSL** | Oranye tua | *Sell-Side Liquidity* tersapu: harga menembus swing low lalu close kembali di atasnya. Condong ke bias **bullish**. Muncul di ujung low. |
| **Strong High / Weak High** | Perak | Label pada swing high terakhir. Dalam tren bullish high disebut *Weak High* (target likuiditas), dalam tren bearish disebut *Strong High* (penahan tren). |
| **Strong Low / Weak Low** | Perak | Label pada swing low terakhir. Tren bullish: *Strong Low*. Tren bearish: *Weak Low*. |

Catatan:

- Tren diperbarui hanya saat candle close menembus level, sehingga sumbu (wick) saja tidak menghasilkan BOS/CHoCH.
- Break pertama setelah indikator dimuat selalu dihitung BOS, karena belum ada tren sebelumnya.
- Label BOS/CHoCH bullish ditaruh di atas garis, bearish di bawah garis.

## 4. Zona (ICT / SMC)

| Label | Artinya | Cara terbentuk | Perubahan status |
|---|---|---|---|
| **Bull OB** | *Order Block* bullish: area permintaan. | Saat terjadi break bullish, diambil candle terendah pada leg impuls, lalu dicari candle bearish terdekat (maksimal 3 candle ke belakang). | Jika candle close di bawah dasar zona, berubah menjadi **Bear Breaker**. |
| **Bear OB** | *Order Block* bearish: area penawaran. | Kebalikan dari Bull OB (candle bullish terdekat pada leg turun). | Jika close di atas puncak zona, berubah menjadi **Bull Breaker**. |
| **Bull Breaker** | *Breaker Block* bullish: bekas Bear OB yang gagal bertahan lalu menjadi support. | Bear OB ditembus close ke atas. | Jika close di bawah dasar zona, zona dianggap termitigasi (selesai). |
| **Bear Breaker** | *Breaker Block* bearish: bekas Bull OB yang gagal lalu menjadi resistance. | Bull OB ditembus close ke bawah. | Jika close di atas puncak zona, zona termitigasi. |
| **Bull FVG / Bear FVG** | *Fair Value Gap*: celah harga tiga candle yang belum terisi. Bull = celah naik, Bear = celah turun. | Low candle ke-3 di atas high candle ke-1 (bull), atau sebaliknya (bear). Ukuran minimal `InpFvgMinATR` x ATR. Garis tengah titik-titik = *Consequent Encroachment* (50% FVG). | Sumbu (wick) yang menyentuh sisi jauh zona = termitigasi. Close menembus zona = berubah menjadi **IFVG**. |
| **Bull IFVG / Bear IFVG** | *Inversion FVG*: FVG yang ditembus close lalu berbalik fungsi. **Bear IFVG** adalah bekas Bull FVG yang ditembus ke bawah (kini jadi resistance); **Bull IFVG** adalah bekas Bear FVG yang ditembus ke atas (kini jadi support). | FVG ditembus close (hanya jika `InpShowIFVG` aktif). | Close menembus lagi ke arah berlawanan = termitigasi. |
| **Bull MB / Bear MB** | *Mitigation Block*: zona dari candle sekitar swing sebelumnya yang muncul saat CHoCH, ketika swing gagal membuat ekstrem baru. | Pada CHoCH dengan low/high yang tidak membuat ekstrem baru, diambil candle searah dekat swing sebelumnya. | Close menembus sisi jauh zona = termitigasi. |
| **Bull VI / Bear VI** | *Volume Imbalance*: celah antara open candle sekarang dan close candle sebelumnya (badan tidak bersambung), tetapi sumbu masih saling tumpang tindih. | Dua candle searah dengan celah badan minimal 0.02 x ATR. | Sumbu menyentuh sisi jauh zona = termitigasi. |
| **Bull Void / Bear Void** | *Liquidity Void*: candle impuls dengan badan besar (minimal `InpVoidATR` x ATR). Garis tengah titik-titik menunjukkan titik 50%. | Badan candle melebihi ambang. | Harga mengisi sampai titik tengah = termitigasi. |

Semua zona memakai warna dari input (OB, FVG, Breaker, MB) atau warna tetap (IFVG ungu, VI abu-abu, Void abu-abu gelap). Zona yang sudah termitigasi hanya digambar jika `InpShowMitigated` aktif.

## 5. ICT: PD Array, OTE, dan likuiditas

| Label | Artinya |
|---|---|
| **Premium** | Setengah atas range swing terakhir (merah tua). Area mahal: lebih baik untuk mencari **SELL**. |
| **EQ 50%** | Garis *Equilibrium*, titik tengah range swing (abu-abu putus-putus). |
| **Discount** | Setengah bawah range swing (hijau laut). Area murah: lebih baik untuk mencari **BUY**. |
| **OTE** | *Optimal Trade Entry*: kotak emas di level retracement 62% sampai 79% dari range swing. Pada tren bullish diukur dari atas ke bawah, pada tren bearish dari bawah ke atas. |
| **PDH / PDL** | *Previous Day High / Low*: high dan low hari sebelumnya (garis perak titik-garis). Target likuiditas harian. |
| **PWH / PWL** | *Previous Week High / Low*: high dan low minggu sebelumnya (garis emas titik-garis). Target likuiditas mingguan. |

## 6. CRT (Candle Range Theory)

| Simbol | Artinya |
|---|---|
| **Kotak emas gelap (goldenrod)** | Range candle acuan **C1** pada timeframe `InpCrtTF` (default H4), diperpanjang sampai C2 selesai (close). |
| **Garis titik-titik di tengah kotak** | Level 50% dari range C1. Bisa dipakai sebagai target (mode TP `TP_CRT50`). |
| **Garis oranye tebal pendek** | Ujung sapuan (*sweep*) oleh candle **C2**. Dipakai juga sebagai batas SL. |
| **CRT Bull H4** | C2 menyapu di bawah low C1, lalu close kembali ke dalam range C1. Bias **bullish**, target ke atas menuju range C1. |
| **CRT Bear H4** | C2 menyapu di atas high C1, lalu close kembali ke dalam range C1. Bias **bearish**, target ke bawah. |

CRT dianggap berlaku selama `InpCrtValid` candle HTF setelah C2 close. CRT dinyatakan gugur (*dead*) bila harga close melewati ujung sapuan, atau harga mencapai sisi berlawanan dari range C1.

## 7. Killzone dan sesi (jam GMT)

Kotak titik-titik menandai high-low harga selama sesi. Nama sesi tertulis di pojok kiri atas kotak. Hanya `InpKzDays` hari terakhir yang digambar.

| Label | Warna | Jam default (GMT) |
|---|---|---|
| **Asia** | Ungu | 01 - 05 |
| **London** | Biru | 07 - 10 |
| **NY AM** | Merah tomat | 12 - 15 |
| **London Close** | Cokelat | 15 - 17 (nonaktif default) |
| **SB 1 / SB 2 / SB 3** | Hijau kebiruan | *Silver Bullet*, jendela 1 jam mulai jam 08, 15, 19 (nonaktif default) |

Jika `InpReqKZ` aktif, sinyal hanya dikeluarkan saat harga berada di dalam salah satu sesi yang diaktifkan.

## 8. Sinyal, SL, TP, dan panel

### Simbol sinyal

| Simbol | Artinya |
|---|---|
| **Panah hijau ke atas** (di bawah candle) | Sinyal **BUY**. |
| **Panah merah ke bawah** (di atas candle) | Sinyal **SELL**. |
| **Garis merah putus-putus + teks `SL harga`** | Stop loss sinyal. |
| **Garis hijau putus-putus + teks `TP harga`** | Take profit sinyal. |

Hanya `InpMaxSigDraw` sinyal terakhir yang digambar SL/TP-nya.

### Logika sinyal (ringkas)

1. **Bias** ditentukan oleh `InpBiasMode`: CRT saja, struktur HTF saja, CRT lalu HTF, atau keduanya harus searah.
2. Bila `InpReqSweep` aktif, harus ada *liquidity sweep* (atau sapuan CRT) dalam `InpSetupBars` candle terakhir. Bila `InpReqIDM` aktif, harus ada inducement tersapu.
3. Harus ada BOS/CHoCH searah bias setelah sapuan tersebut.
4. Zona yang terbentuk setelahnya (OB, FVG, MB, Breaker, sesuai input `InpEntry...`) menjadi **siap (armed)**, berlaku sampai `InpArmExpire` candle.
5. Sinyal keluar saat candle menyentuh zona siap dan close di dalam/di atas zona yang sesuai. Jika `InpReqPD` aktif, buy hanya di discount dan sell hanya di premium.
6. **SL** di sisi jauh zona atau ujung sapuan, ditambah buffer `InpSlBufATR` x ATR.
7. **TP** mengikuti `InpTpMode` (likuiditas terdekat, 50% CRT, atau kelipatan RR). Sinyal dibuang jika RR di bawah `InpMinRR`.

### Panel info (pojok kiri atas)

| Baris | Isi |
|---|---|
| **ICT \| SMC \| CRT** | Judul panel. |
| **Bias** | BULLISH / BEARISH / NETRAL, beserta sumber bias: (CRT), (HTF), atau (CRT+HTF). |
| **CRT (timeframe)** | Bullish aktif / Bearish aktif / tanda minus bila tidak ada CRT berlaku. |
| **Struktur** | Tren swing dan tren internal saat ini (Bull / Bear / minus). |
| **Sesi** | Sesi yang sedang berjalan pada candle terakhir. |
| **Sinyal** | Sinyal terakhir (BUY/SELL beserta waktunya). |

## 9. Anti-tumpuk label (baru di v1.01)

Saat banyak sinyal ICT, SMC, dan CRT muncul bersamaan, teks sering menumpuk di titik yang sama, terutama di sisi kanan (Premium, EQ, OTE, PDH, SL, TP). Versi ini menghitung kotak piksel tiap teks dan menggeser teks yang bertabrakan ke atas atau bawah.

- Urutan prioritas (yang pertama tidak bergeser): SL/TP, CRT, BOS/CHoCH dan label struktur, Premium/EQ/OTE, PDH/PDL/PWH/PWL, zona, lalu sesi.
- Area panel info dihindari oleh teks lain.
- Susunan label dihitung ulang otomatis saat zoom, ubah ukuran jendela, atau skala harga berubah.
- Atur lewat `InpAntiOverlap` (aktif/nonaktif) dan `InpLabelGap` (jarak antar teks dalam piksel).
- Bila masih terlalu rapat: naikkan `InpLabelGap`, atau kurangi `InpMaxZones`, `InpMaxEvents`, dan `InpMaxSigDraw`.

## 10. Buffer untuk EA (iCustom / CopyBuffer)

| Buffer | Isi |
|---|---|
| 0 | Harga posisi panah BUY (`EMPTY_VALUE` jika tidak ada). |
| 1 | Harga posisi panah SELL (`EMPTY_VALUE` jika tidak ada). |
| 2 | SL untuk BUY. |
| 3 | TP untuk BUY. |
| 4 | SL untuk SELL. |
| 5 | TP untuk SELL. |
| 6 | Bias: 1 = bullish, -1 = bearish, 0 = netral. |

Sinyal hanya dihitung pada candle yang sudah close, jadi baca buffer dari bar index 1 (candle terakhir yang sudah selesai) untuk menghindari sinyal yang berubah.

## 11. Alert

- `InpAlertPopup`: popup di MT5.
- `InpAlertPush`: notifikasi push ke aplikasi MT5 di ponsel (perlu MetaQuotes ID di pengaturan).
- `InpAlertMail`: email (perlu pengaturan email di MT5).

Isi alert: arah, simbol, timeframe, SL, dan TP.

## 12. Pemecahan masalah

| Masalah | Solusi |
|---|---|
| Kotak sesi tidak sesuai jam | Atur `InpGmtOffset` sesuai jam server broker. |
| Tidak ada sinyal sama sekali | Longgarkan filter: matikan `InpReqKZ`, `InpReqIDM`, atau `InpReqPD`; naikkan `InpSetupBars`; turunkan `InpMinRR`. |
| Chart terlalu penuh | Matikan jenis zona yang tidak dipakai (VI, Void, IFVG), atau kurangi `InpMaxZones` dan `InpMaxEvents`. |
| Zona HTF tidak muncul | Pastikan data timeframe `InpHtf` sudah termuat (buka chart H4 sebentar), lalu muat ulang indikator. |
| Indikator lambat | Turunkan `InpMaxBars` (default 1500). |
| Teks masih menumpuk | Naikkan `InpLabelGap`, atau perbesar jarak antar label dengan mengurangi jumlah objek yang ditampilkan. |

## 13. Disclaimer

Indikator ini hanya alat bantu analisis teknikal dan bukan nasihat keuangan. Trading forex, emas, dan CFD berisiko tinggi. Hasil masa lalu tidak menjamin hasil di masa depan.
