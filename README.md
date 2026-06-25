# Verivio - Lapisan Verifikasi Sains untuk Asisten AI

Verivio adalah aplikasi inovatif yang bertindak sebagai lapisan audit ilmiah untuk asisten AI (seperti ChatGPT, Gemini, Claude, dan DeepSeek). Aplikasi ini dapat memecah respons AI menjadi klaim-klaim individual, melacak bukti riset akademis pendukung, menghitung persentase tingkat konsensus ilmiah, menganalisis bias sebaran geografis dari institusi penulis jurnal (blind spot), serta menyalin format sitasi standar (APA, MLA, IEEE) secara instan.

---

## 📂 Struktur Proyek

Proyek ini terbagi menjadi 3 direktori utama:
1. **`frontend/`**: Mockup statis dalam bentuk HTML, CSS, dan Javascript sebagai referensi desain awal.
2. **`backend/`**: Server API berbasis **TypeScript & Express** yang menghubungkan aplikasi ke model **Gemini (gemini-2.5-flash)** untuk ekstraksi klaim secara dinamis serta pengolahan data referensi sains.
3. **`mobile/`**: Aplikasi client berbasis **Flutter** yang mendukung kompilasi Web (dengan fallback chat simulator) dan Mobile APK/iOS (dengan integrasi situs web AI asli via WebView).

---

## ⚙️ Cara Kerja Aplikasi

1. **Pilih AI**: Pengguna memilih platform AI pada tampilan awal (ChatGPT, Gemini, Claude, atau DeepSeek).
2. **Arahkan ke Web AI**: 
   - **Di HP/APK**: Aplikasi akan membuka situs web asli dari AI tersebut secara langsung di dalam aplikasi menggunakan WebView.
   - **Di Web Browser**: Karena keterbatasan keamanan browser (kebijakan CORS/X-Frame-Options dari ChatGPT/Gemini), aplikasi otomatis menggunakan *fallback* berupa simulasi chat interaktif.
3. **Tombol Verify Mengambang**: Tombol **Verify** berwarna ungu akan muncul mengambang di layar chat web AI tersebut.
4. **Verifikasi Jawaban**: Setelah AI memberikan jawaban, pengguna menekan tombol **Verify**.
5. **Kembali ke Aplikasi**: Tombol mengambang menghilang dan lembar panel hasil audit (Verify Drawer) muncul menyajikan 5 fitur verifikasi dinamis:
   - **Claim Extractor**: Memecah jawaban AI menjadi poin-poin klaim faktual.
   - **Evidence Finder**: Mencari referensi jurnal ilmiah terkait di katalog akademik (OpenAlex).
   - **Consensus Meter**: Mengukur seberapa kuat dukungan sains terhadap klaim tersebut (Support, Neutral, atau Oppose).
   - **Blind Spot Alert**: Menganalisis sebaran wilayah asal institusi penerbit jurnal untuk mendeteksi bias geografis.
   - **Ready-to-Cite**: Menyediakan sitasi siap pakai berformat APA, MLA, atau IEEE secara otomatis.

---

## 🚀 Panduan Memulai & Menjalankan Aplikasi

### 1. Menjalankan Server Backend

Sebelum menjalankan aplikasi client, server backend harus aktif untuk melayani API.

1. Buka terminal (CMD / PowerShell) dan masuk ke direktori backend:
   ```bash
   cd D:\Kuliah\biskom\verity\backend
   ```
2. Instal dependensi Node.js:
   ```bash
   npm install
   ```
3. *(Opsional)* Konfigurasi API Key Gemini:
   - Buat file `.env` di dalam folder `backend/`.
   - Tambahkan baris berikut:
     ```env
     GEMINI_API_KEY=isi_dengan_api_key_gemini_kamu
     ```
   - *Catatan: Jika Anda tidak memasukkan API Key, backend akan otomatis menggunakan mode fallback cerdas agar aplikasi tetap berjalan dinamis tanpa crash.*
4. Jalankan server:
   ```bash
   npm start
   ```
   Server backend akan berjalan di **`http://localhost:5000`**.

---

### 2. Mencoba Jalur Web Browser (Web Mode - Tercepat)

Server backend telah dikonfigurasi untuk menyajikan aset web Flutter secara statis. Anda tidak perlu menyalakan Flutter di terminal Anda untuk mencobanya:

1. Pastikan server backend Anda sudah menyala (`npm start` di folder backend).
2. Buka web browser (seperti Google Chrome), lalu akses tautan:
   ```url
   http://localhost:5000
   ```
3. Selamat mencoba! Anda bisa memilih platform AI, bercakap-cakap secara dinamis, dan melakukan verifikasi.

---

### 3. Mencoba Jalur Emulator HP / HP Fisik (WebView Situs AI Asli)

Untuk menguji fitur WebView yang memuat situs web asli dari ChatGPT, Gemini, Claude, dll:

#### **Pilihan A: Menggunakan Emulator Android (HP Virtual)**
1. Buka **Android Studio**.
2. Buka **Device Manager** (ikon HP kecil di kanan atas atau via menu `Tools` -> `Device Manager`).
3. Jalankan salah satu emulator HP virtual dengan menekan tombol **Play (segitiga hijau)**.
4. Buka terminal baru di VS Code, masuk ke direktori mobile:
   ```bash
   cd D:\Kuliah\biskom\verity\mobile
   ```
5. Jalankan perintah kompilasi Flutter:
   ```bash
   flutter run
   ```
6. Terminal akan menampilkan daftar perangkat yang aktif. Pilih nomor opsi yang mewakili emulator Android (biasanya tertulis nama `emulator-5554` atau sejenisnya).

#### **Pilihan B: Menggunakan HP Android Fisik**
1. **Aktifkan Opsi Pengembang**: Masuk ke *Pengaturan HP* -> *Tentang Ponsel* -> ketuk *Nomor Bentukan (Build Number)* sebanyak 7 kali.
2. **Aktifkan USB Debugging**: Masuk ke *Pengaturan HP* -> *Sistem* -> *Opsi Pengembang* -> aktifkan tombol *USB Debugging*.
3. Hubungkan HP ke laptop menggunakan kabel data USB.
4. Ubah preferensi koneksi USB HP Anda ke mode **Transfer File (MTP)**, lalu pilih **Izinkan** saat muncul peringatan izin debug USB di layar HP.
5. Konfigurasi IP komputer Anda di Flutter agar HP fisik dapat terhubung dengan backend lokal laptop:
   - Cari tahu IP lokal laptop Anda (melalui perintah `ipconfig` di CMD, misal: `192.168.1.15`).
   - Buka file [api_service.dart](file:///D:/Kuliah/biskom/verity/mobile/lib/services/api_service.dart) di folder `mobile/lib/services/`.
   - Ubah baris ke-20: `'http://localhost:5000/api/v1'` menjadi IP lokal laptop Anda, misal: `'http://192.168.1.15:5000/api/v1'`.
6. Buka terminal di folder `mobile` dan jalankan:
   ```bash
   flutter run
   ```
7. Pilih nomor opsi perangkat HP Android Anda yang terdeteksi.

---

## 🛠️ Pemecahan Masalah (Troubleshooting)

* **Tombol Verify Mengambang tidak mendeteksi teks jawaban secara otomatis di HP:**
  Beberapa perubahan struktur DOM pada situs web ChatGPT/Gemini asli dapat membuat ekstraktor JavaScript tidak menemukan elemen teks. Aplikasi telah dilengkapi dengan sistem proteksi *dialog pop-up* input. Cukup salin (*copy*) teks jawaban AI secara manual, lalu tempel (*paste*) ke dalam kotak dialog verifikasi yang muncul di aplikasi.
* **HP tidak terdeteksi saat dicolokkan ke laptop:**
  Pastikan kabel USB yang digunakan adalah kabel data bawaan pabrik (bukan kabel cas biasa), dan pastikan opsi *USB Debugging* di menu opsi pengembang HP dalam posisi aktif. Gunakan perintah `adb devices` di terminal untuk melihat status koneksi perangkat.
