# frozen_string_literal: true

WeabotRuby.define_plugin "interactive_demo" do
  category_tag "Interactive"

  on_commands "demo", "otp", "carousel", "flow", "rich" do |ctx|
    case ctx.command
    when "otp"
      code = format("%06d", rand(100_000..999_999))
      ctx.button_builder
         .set_title("Verifikasi Keamanan")
         .set_body("Kode OTP Anda adalah *#{code}*. Berlaku 5 menit.")
         .set_footer("Jangan bagikan kode ini")
         .add_otp(code, "Salin Kode OTP")
         .send(ctx.jid)
    when "carousel"
      card1 = ctx.button_builder
                 .set_title("Nike Air Zoom")
                 .set_body("Sepatu lari ringan generasi terbaru.")
                 .add_reply("Pesan Sekarang", "buy_nike")
                 .add_url("Detail", "https://example.com/nike")
      card2 = ctx.button_builder
                 .set_title("Sony WH-1000XM5")
                 .set_body("Headphone wireless noise canceling.")
                 .add_reply("Pesan Sekarang", "buy_sony")
                 .add_url("Detail", "https://example.com/sony")
      ctx.carousel_builder
         .set_title("Promo Mingguan")
         .set_body("Geser kartu produk di bawah ini:")
         .add_card([card1, card2])
         .send(ctx.jid)
    when "flow"
      flow = BaileysRec::FlowBuilder.new("order_form_v3", "Form Pemesanan")
                                    .add_screen("ORDER_1", "Data Pembeli")
                                    .add_text_input("customer_name", "Nama Penerima", required: true)
                                    .add_dropdown("courier", "Kurir", %w[JNE J&T SiCepat])
                                    .add_footer("Lanjutkan", "complete")
      btn = flow.to_flow_button("Isi Form Order", "tok_order")
      ctx.button_builder
         .set_title("Checkout Cepat")
         .set_body("Lengkapi alamat pengiriman lewat WhatsApp Flow v3:")
         .add_button("flow", btn[:buttonParamsJson])
         .send(ctx.jid)
    when "rich"
      ctx.rich_builder
         .add_text("Dokumentasi cepat [baileys_rec](https://github.com/KazeDevID/baileys-rec-rb):")
         .add_code("ruby", "BaileysRec::Button.new(sock).set_title('Hi').add_otp('123456').send(jid)")
         .add_table(["Fitur", "Nama | Status", "Button | Siap;;Carousel | Siap;;Flow v3 | Siap"])
         .send(ctx.jid)
    else
      ctx.button_builder
         .set_title("Demo #{ctx.config.bot_name}")
         .set_body("Pilih komponen interaktif untuk diuji:")
         .add_reply("Kirim OTP", "demo_trigger_otp")
         .add_location_request("Bagikan Lokasi")
         .add_pix_payment("pix@weabot.dev", 5000, "Weabot Store", "Demo Pembayaran")
         .send(ctx.jid)
    end
  end

  on_buttons "buy_*", "plan_*", "demo_trigger_otp" do |ctx|
    if ctx.button_id == "demo_trigger_otp"
      ctx.button_builder
         .set_title("Kode Verifikasi")
         .set_body("Kode demo: *774920*")
         .add_otp("774920", "Salin 774920")
         .send(ctx.jid)
    else
      ctx.reply("Permintaan *#{ctx.button_id}* dicatat ke antrean otomatis.")
    end
  end
end
