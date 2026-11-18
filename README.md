# weabot-ruby

Bot WhatsApp modular berbahasa Ruby yang ditenagai oleh [`KazeDevID/baileys-rec-rb`](https://github.com/KazeDevID/baileys-rec-rb) — versi Ruby dari `baileys-rec`.

Dirancang dengan arsitektur plugin modular (`plugins/*.rb`), konfigurasi non-global (`config/bot.rb`), database JSON atomik (`lib/database.rb`), antrean broadcast anti-ban (`BaileysRec::Automation::Dispatcher`), serta REST API & Webhook Server (`BaileysRec::Automation::WebhookServer`).

## Fitur Utama

- **Dual Login WhatsApp Multi-Device**: Scan QR di terminal atau gunakan **Pairing Code 8-karakter**.
- **Mode Fleksibel**: Mendukung `:bridge` (WhatsApp Web Multi-Device), `:cloud_api` (Meta Cloud API pure-Ruby tanpa Node.js), dan `:memory` (simulasi/testing).
- **Modular Plugin Handler (`plugins/*.rb`)**: Mendukung hot-reload dengan `!reload` tanpa memutus koneksi socket.
- **Full `baileys_rec` Interactive UI**:
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

Jika menggunakan mode `:bridge` (WhatsApp Multi-Device), install dependensi Node.js pada bridge gem sekali saja:

```bash
BRIDGE_DIR=$(bundle exec ruby -e 'puts File.expand_path("baileys_rec/bridge", File.dirname(Gem.loaded_specs["baileys_rec"].full_require_paths.first))')
cd "$BRIDGE_DIR" && npm install --omit=dev
```

Jalankan bot dengan QR Code:

```bash
bundle exec bin/weabot start
```

Atau jalankan dengan Pairing Code (tanpa scan QR):

```bash
bundle exec bin/weabot pairing 6281234567890
```

## Pengujian

```bash
bundle exec rake test
```

## Lisensi

MIT License — KazeDevID.
