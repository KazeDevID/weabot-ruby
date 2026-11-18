# weabot-ruby

Bot WhatsApp modular berbahasa Ruby yang ditenagai oleh [`KazeDevID/whatsapp-web-ruby`](https://github.com/KazeDevID/whatsapp-web-ruby).

Dirancang dengan arsitektur plugin modular (`plugins/*.rb`), konfigurasi non-global (`config/bot.rb`), database JSON atomik (`lib/database.rb`), antrean broadcast anti-ban (`WhatsappWebRuby::Automation::Dispatcher`), serta REST API & Webhook Server (`WhatsappWebRuby::Automation::WebhookServer`).

## Fitur Utama

- **Dual Login WhatsApp Multi-Device**: Scan QR di terminal atau gunakan **Pairing Code 8-karakter**.
- **Mode Fleksibel**: Mendukung `:bridge` (WhatsApp Web Multi-Device), `:cloud_api` (Meta Cloud API pure-Ruby tanpa Node.js), dan `:memory` (simulasi/testing).
- **Modular Plugin Handler (`plugins/*.rb`)**: Mendukung hot-reload dengan `!reload` tanpa memutus koneksi socket.
- **Full `whatsapp-web-ruby` Interactive UI**:
  - `!menu`: Menu simpel per kategori + Single Select Interactive Button.
  - `!demo`, `!otp`, `!carousel`, `!flow`, `!rich`: Showcase lengkap `Button`, `Carousel`, `FlowBuilder` v3.1, `AIRich`, dan OTP Copy Code.
  - `!calc`: Kalkulator matematika aman (recursive-descent parser, tanpa `eval`).
  - `!cloudapi` & `!sanitize`: Konverter payload Meta Cloud API & normalisasi E.164.
  - `!broadcast`: Broadcast antrean rate-limited dengan `idempotency_key`.
  - `!self` / `!public`: Pengaturan akses bot.
  - `!groupinfo`, `!kick`, `!promote`, `!demote`: Moderasi grup.
- **REST API Otomasi Built-in**: Endpoint `/v1/messages/send`, `/v1/messages/interactive`, `/v1/messages/cloud-api`, `/v1/session/pairing-code`, dan `/v1/health` siap pakai pada port `4567`.

## Struktur Direktori

```text
├── bin/weabot              # CLI runner bot
├── config/bot.rb           # Konfigurasi non-global terenkapsulasi
├── lib/
│   ├── bot.rb              # Orkestrator utama WeabotRuby::Bot
│   ├── database.rb         # Penyimpanan JSON atomik (users, chats, settings)
│   └── plugin_manager.rb   # Loader & hot-reloader plugin
├── plugins/                # Plugin modular per fitur
├── test/                   # Minitest suite
├── Dockerfile
└── docker-compose.yml
```

## Instalasi & Menjalankan

```bash
git clone https://github.com/KazeDevID/weabot-ruby.git
cd weabot-ruby
cp .env.example .env
bundle install
```

> **Catatan Termux / Android (`/sdcard`)**: Filesystem `/sdcard` tidak mendukung permission eksekusi (`+x`), sehingga `bundle exec bin/weabot` akan memunculkan `not executable: bin/weabot`. Jalankan selalu dengan `bundle exec ruby bin/weabot ...` (atau `bundle exec ruby start.rb ...`). Untuk performa `npm install` & `bundle install` terbaik di Termux, disarankan clone ke `$HOME/weabot-ruby`.

Install dependensi Node.js pada bridge gem sekali saja (otomatis juga dijalankan saat pertama start jika belum ada):

```bash
bundle exec ruby bin/weabot setup-bridge
```

Jalankan bot dengan QR Code:

```bash
bundle exec ruby bin/weabot start
```

Atau jalankan dengan Pairing Code (tanpa scan QR):

```bash
bundle exec ruby bin/weabot pairing 6281234567890
```

## Pengujian

```bash
bundle exec rake test
```

## Lisensi

MIT License — KazeDevID.
