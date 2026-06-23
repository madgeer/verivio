# Sprint Plan (Compressed) — VERITY

> Dokumen ini merencanakan pengerjaan VERITY secara padat agar selesai dalam rentang waktu **23 Juni – 24 Juli 2026** (sekitar 4.5 minggu).
> Diperbarui: 2026-06-23

---

## Ringkasan Timeline (23 Juni - 24 Juli 2026)

| Fase / Sprint | Fokus Utama | Durasi | Rentang Tanggal |
|---|---|---|---|
| **Sprint 1** | Backend Setup & Core Verification API (Claim & Evidence) | 1 Minggu | 23 Jun - 29 Jun |
| **Sprint 2** | Advanced Backend Services (Consensus, Blind Spot, Citation) | 1 Minggu | 30 Jun - 6 Jul |
| **Sprint 3** | Flutter Mobile App Shell & UI Implementation | 1 Minggu | 7 Jul - 13 Jul |
| **Sprint 4** | API Integration & Mobile Logic | 1 Minggu | 14 Jul - 20 Jul |
| **Fase Rilis** | QA, Bug Fixing, Polish & Deployment | 4 Hari | 21 Jul - 24 Jul |

---

## Detail Pengerjaan

### Sprint 1: Backend Setup & Core API (23 Jun - 29 Jun)
* **Tujuan**: Membangun fondasi server Node.js/TS dan merampungkan pipeline ekstraksi klaim & pencarian bukti.
* **Tasks**:
  * [ ] Setup repo backend, TypeScript, Express, Jest, linting, dan dotenv.
  * [ ] Integrasi OpenAI API untuk **Claim Service** (memecah jawaban AI menjadi klaim terpisah).
  * [ ] Integrasi OpenAlex API untuk **Evidence Service** (mencari jurnal/paper akademik yang relevan).
  * [ ] Endpoint MVP `POST /api/v1/verify` (merespons klaim dan metadata paper).

### Sprint 2: Advanced Backend Services (30 Jun - 6 Jul)
* **Tujuan**: Menyelesaikan semua sisa logic di backend agar API berstatus Feature-Complete.
* **Tasks**:
  * [ ] Implementasi **Consensus Service** menggunakan LLM untuk mengklasifikasi paper (Support/Neutral/Oppose).
  * [ ] Implementasi **Blind Spot Service** dengan menganalisis persebaran geografis penulis/institusi paper.
  * [ ] Implementasi **Citation Service** (otomatisasi format sitasi APA, MLA, IEEE).
  * [ ] End-to-end integration test untuk endpoint `/api/v1/verify` agar mengembalikan full JSON response.

### Sprint 3: Flutter App Shell & UI (7 Jul - 13 Jul)
* **Tujuan**: Membangun visual interface di mobile yang selaras dengan mockup HTML.
* **Tasks**:
  * [ ] Inisialisasi project Flutter & setup environment/design system (colors, fonts, spacing).
  * [ ] Implementasi Screen 1: AI Platform Selector.
  * [ ] Implementasi Screen 2: ChatGPT Chat Interface (dengan floating "Verify" button).
  * [ ] Implementasi Screen 3: Overlay Panel / Bottom Sheet untuk menampilkan hasil verifikasi.

### Sprint 4: API Integration & Mobile Logic (14 Jul - 20 Jul)
* **Tujuan**: Menghubungkan frontend Flutter dengan API Backend dan mengelola state aplikasi.
* **Tasks**:
  * [ ] Setup HTTP Client & Riverpod/Bloc untuk state management.
  * [ ] Integrasikan tombol "Verify" ke endpoint `POST /api/v1/verify`.
  * [ ] Implementasi loading/shimmer state selama proses verifikasi (karena target response <10 detik).
  * [ ] Tampilkan hasil klasifikasi klaim, grafik consensus meter, list blind spot, dan salin sitasi ke clipboard.

### Fase Rilis: QA, Polish & Deploy (21 Jul - 24 Jul)
* **Tujuan**: Deployment aplikasi dan backend agar siap ditunjukkan/didemokan.
* **Tasks**:
  * [ ] Optimasi performa (parallel execution `Promise.all` di backend untuk pencarian paper).
  * [ ] Deploy backend ke Railway/Render.
  * [ ] Build APK release Android.
  * [ ] Final testing dan perbaikan bug krusial.

---

## Catatan Penyesuaian
* **Penyederhanaan Database**: PostgreSQL yang awalnya direncanakan untuk history disimpan untuk fase post-MVP. Aplikasi saat ini fokus ke fungsionalitas real-time (stateless).
* **Paralelisasi Tugas**: Jika dikerjakan secara tim, Sprint 1-2 (backend) dan Sprint 3 (frontend) bisa berjalan secara paralel untuk mempercepat timeline.
