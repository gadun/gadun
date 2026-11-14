<div align="center">
  
  <!-- Pastikan file gadun.svg berada di folder yang sama dengan README.md, atau sesuaikan path-nya (misal: ./assets/gadun.svg) -->
  <img src="./gadun.svg" alt="Gadung Logo" width="160" height="auto" />

  <h1>GADUNG</h1>
  <h3>Gudang Mesin Uang Masa Depan</h3>
  <p><b>Next-Generation Algorithmic Trading Ecosystem: MetaTrader 5 (MQL5) × Artificial Intelligence</b></p>

  <p>
    <img src="https://img.shields.io/badge/Status-Active_Development-emerald?style=for-the-badge" alt="Status" />
    <img src="https://img.shields.io/badge/Platform-MetaTrader_5-blue?style=for-the-badge" alt="Platform" />
    <img src="https://img.shields.io/badge/AI_Engine-ONNX_%7C_Python-amber?style=for-the-badge" alt="AI Engine" />
    <img src="https://img.shields.io/badge/Market-XAUUSD_%26_Major_Pairs-gold?style=for-the-badge" alt="Focus" />
  </p>

</div>

---

## 📖 Mengenal Gadung

**Gadung (Gudang Mesin Uang Masa Depan)** adalah proyek ekosistem *automated trading* modern yang menggabungkan kecepatan eksekusi **Expert Advisor (EA) MetaTrader 5** dengan kecerdasan adaptif **Artificial Intelligence (AI)**. 

Berbeda dengan robot trading konvensional yang hanya mengandalkan indikator teknikal statis dan rentan hancur saat struktur pasar berubah, **Gadung** dirancang dengan pendekatan **Multi-Layer Risk Management** serta klasifikasi rezim pasar berbasis *Machine Learning*. Setiap "mesin" di dalam gudang ini memprioritaskan ketahanan ekuitas (*capital preservation*), eksekusi presisi, dan pertumbuhan terukur melalui sistem replikasi unit.

### 🎨 Filosofi Identitas (`gadun.svg`)
Logo dan identitas **Gadung** merepresentasikan sinergi antara **brankas penyimpanan yang kokoh (Gudang)**, **presisi mekanis algoritma (Mesin)**, dan **visi teknologi masa depan (AI)**. Simbol ini menjadi penanda standar kualitas bahwa setiap EA yang masuk ke dalam ekosistem Gadung telah melewati uji ketahanan data dan manajemen risiko yang ketat.

---

## ⚡ Fitur Utama & Keunggulan Arsitektur

* 🧠 **AI Market Regime Filter:** Mendeteksi kondisi pasar secara *real-time* (*Trending*, *Ranging/Sideways*, atau *High Volatility*) untuk mengaktifkan modul strategi yang paling relevan.
* 🛡️ **Multi-Layer Risk Framework:** Dilengkapi pengaman berlapis mulai dari *Dynamic Stop Loss*, *Daily Drawdown Warning Threshold*, hingga *Hard Equity Stop* (batas maksimal penurunan harian absolut) untuk mencegah *margin call*.
* ⚙️ **Hybrid & Native ONNX Execution:** Mendukung integrasi model AI langsung di dalam file `.ex5` (via ONNX) untuk eksekusi *zero-latency*, maupun koneksi *cloud API* untuk pembaruan data sentimen makro.
* 📰 **High-Impact News Shield:** Menghentikan pembukaan posisi baru secara otomatis sebelum dan sesudah rilis berita ekonomi berdampak tinggi (NFP, CPI, FOMC).
* 📊 **Real-Time Telemetry & Web Dashboard:** Terintegrasi dengan *website* pusat dan notifikasi **Telegram Bot** untuk pemantauan ekuitas, performa harian, serta status mesin secara transparan.

---

## 🏗️ Arsitektur Sistem

```text
+-----------------------------------------------------------------------+
|                        EKOSISTEM GADUNG                               |
+-----------------------------------------------------------------------+
                                   |
       +---------------------------+---------------------------+
       |                                                       |
       v                                                       v
+--------------+                                       +---------------+
| AI & ML Core | ---> [ Ekstraksi Model ONNX / API ] ->| Engine EA MT5 |
| (Python Lab) |                                       |    (MQL5)     |
+--------------+                                       +---------------+
  - Training Data Tick 99.9%                             - Eksekusi Order Presisi
  - Klasifikasi Volatilitas                              - Multi-Layer Risk Guard
  - Optimasi Parameter                                   - Unit Scaling System
                                                               |
                                                               v
                                                       +---------------+
                                                       | Web & Monitor |
                                                       +---------------+
                                                         - Live Roadmap & Stats
                                                         - Myfxbook / MQL5 Sync
                                                         - Telegram Bot Alert

```

---

## 🗺️ Peta Jalan Pengembangan (Project Roadmap)

Peta jalan ini menjadi panduan utama pengembangan ekosistem **Gadung** dan ditampilkan secara publik di *website* resmi:

### 🟢 Fase 1: Fondasi & Riset Inti (*The Blueprint*)

* [x] Perancangan identitas visual (`gadun.svg`), arsitektur dasar EA MT5, dan manajemen risiko berlapis.
* [ ] Pengumpulan dan pembersihan data *tick* historis (fokus utama: **XAUUSD**).
* [ ] Pembuatan *Landing Page* Website Gadung v1.0 beserta komponen *Interactive Roadmap*.
* [ ] Integrasi sistem notifikasi dasar ke Telegram untuk pemantauan eksekusi.

### 🟡 Fase 2: Integrasi AI & Validasi (*The Brain*)

* [ ] Pelatihan model *Machine Learning* untuk filter tren dan volatilitas sesi pasar.
* [ ] Implementasi model **ONNX** ke dalam kode utama MQL5.
* [ ] *Stress-testing* menggunakan *99.9% Real Tick Data* dengan simulasi *slippage* & *spread* variabel.
* [ ] Pembuktian *Forward Test* di akun *Live* yang terhubung ke analitik publik (Myfxbook / MQL5).

### 🔵 Fase 3: Infrastruktur Gudang & Keamanan (*The Vault*)

* [ ] Pengembangan sistem lisensi akun MT5 berbasis *cloud* untuk proteksi distribusi EA.
* [ ] Peluncuran *Dashboard* Performa *Real-Time* di *website* Gadung.
* [ ] *Closed Beta Testing* bersama tim dan komunitas inti dengan skema replikasi unit.
* [ ] Penyusunan buku panduan operasional dan manajemen risiko standar pengguna.

### 🟣 Fase 4: Ekspansi & Otomasi Penuh (*Future Scaling*)

* [ ] Diversifikasi mesin di dalam Gudang (*Gold Scalper Engine*, *Intraday Swing AI*, *Low-DD Engine*).
* [ ] Otomasi *pipeline re-training* model AI berkala mengikuti perubahan dinamika pasar.
* [ ] Pembukaan akses publik, portal anggota, dan integrasi sistem *Copy-Trading* terpusat.

---

## 📂 Struktur Repositori

```bash
gadung/
├── 📄 gadun.svg             # Logo & identitas visual utama Gadung
├── 📄 README.md             # Dokumentasi utama proyek Gadung
├── 📁 ea-mt5/               # Source code MQL5 (.mq5, Include, Libraries)
│   ├── Experts/             # File utama Expert Advisor Gadung
│   ├── Include/             # Modul Risk Management, Trailing, & ONNX Wrapper
│   └── Models/              # File model AI (.onnx) siap pakai
├── 📁 ai-research/          # Script Python untuk olah data & training model ML
│   ├── notebooks/           # Eksperimen Jupyter Notebook
│   └── train_onnx.py        # Script konversi model ke format ONNX
└── 📁 web-portal/           # Source code Website & Peta Jalan (Cloudflare Pages)
    ├── index.html           # Halaman utama & Interactive Roadmap
    └── assets/              # CSS, JS, dan salinan gadun.svg untuk web

```

---

## 🛠️ Tumpukan Teknologi (Tech Stack)

* **Trading Platform & Execution:** MetaTrader 5 (MQL5)
* **Artificial Intelligence & Data:** Python, Scikit-Learn / PyTorch, ONNX Runtime
* **Web & Deployment:** HTML5, TailwindCSS / Modern JS, Cloudflare Pages
* **Monitoring & Automation:** Telegram Bot API, Myfxbook Analytics

---

## ⚠️ Peringatan Risiko (Risk Disclaimer)

Perdagangan instrumen keuangan dengan *leverage* tinggi (termasuk Forex dan Komoditas seperti XAUUSD) memiliki tingkat risiko yang tinggi dan mungkin tidak cocok untuk semua investor. Kinerja masa lalu dari **EA Gadung** (baik melalui *backtest* maupun *forward test*) tidak menjamin hasil yang identik di masa depan. Selalu gunakan dana dingin (*risk capital*) dan patuhi aturan batas risiko harian yang telah ditetapkan di dalam sistem.

---

---

### 📌 Catatan Penting untuk File `gadun.svg`:

1. **Lokasi File:** Kode di atas mengasumsikan file `gadun.svg` diletakkan sejajar (satu folder) dengan `README.md`. Jika Anda menyimpannya di dalam folder (misalnya `assets/gadun.svg`), cukup ubah bagian `src="./gadun.svg"` menjadi `src="./assets/gadun.svg"`.
2. **Penggunaan di Website:** Karena formatnya sudah `.svg` (vektor), file `gadun.svg` ini juga sangat ideal untuk langsung dipakai sebagai **Favicon** (ikon tab browser) dan logo **Navbar** pada *website* peta jalan Gadung nanti tanpa pecah di ukuran layar berapa pun.

Apakah sekarang kita lanjut membuat halaman *website* (`index.html`) lengkap dengan logo `gadun.svg` dan tampilan **Peta Jalan (Roadmap)** interaktifnya?
