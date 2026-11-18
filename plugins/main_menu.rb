# frozen_string_literal: true

WeabotRuby.define_plugin "main_menu" do
  category_tag "Main"

  on_commands "menu", "help" do |ctx|
    categories = ctx.bot.plugin_manager.categories
    prefix = ctx.config.prefix

    lines = categories.map do |cat, cmds|
      formatted = cmds.map { |c| "• #{prefix}#{c}" }.join("\n")
      "*[ #{cat} ]*\n#{formatted}"
    end

    body = <<~TEXT.strip
      Halo #{ctx.push_name.empty? ? 'kak' : ctx.push_name}, ini daftar perintah *#{ctx.config.bot_name}*:

      #{lines.join("\n\n")}
    TEXT

    builder = ctx.button_builder
                 .set_title(ctx.config.bot_name)
                 .set_subtitle("Mode: #{ctx.config.mode.to_s.upcase}")
                 .set_body(body)
                 .set_footer("Powered by whatsapp-web-ruby Ruby v#{WhatsappWebRuby::VERSION}")
                 .add_selection("Pilih Demo Fitur")
                 .make_section("Showcase whatsapp-web-ruby", "Populer")
                 .make_row("Button & OTP", "Demo Interactive Button", "Lihat tombol Reply, URL, dan OTP", "menu_demo_button")
                 .make_row("Carousel", "Demo Swipeable Carousel", "Lihat kartu produk geser", "menu_demo_carousel")
                 .make_row("Flow v3.1", "Demo WhatsApp Flow", "Form interaktif Flow v3.1", "menu_demo_flow")
                 .make_row("AI Rich", "Demo Rich Message", "Code block & tabel markdown", "menu_demo_rich")
                 .add_url("GitHub Repo", "https://github.com/KazeDevID/weabot-ruby")

    builder.send(ctx.jid)
  end

  on_buttons "menu_demo_*" do |ctx|
    case ctx.button_id
    when "menu_demo_button"
      ctx.button_builder
         .set_title("Interactive NativeFlow")
         .set_body("Contoh tombol OTP, URL, dan Quick Reply.")
         .add_otp("829104", "Salin Kode OTP")
         .add_reply("Ping Bot", "quick_ping")
         .add_url("Library Ruby", "https://github.com/KazeDevID/whatsapp-web-ruby")
         .send(ctx.jid)
    when "menu_demo_carousel"
      c1 = ctx.button_builder.set_title("Paket Starter").set_body("1 Worker + REST API").add_reply("Pilih Starter", "plan_starter")
      c2 = ctx.button_builder.set_title("Paket Pro").set_body("Rate-Limited Queue + Webhook").add_reply("Pilih Pro", "plan_pro")
      ctx.carousel_builder
         .set_title("Katalog Paket")
         .set_body("Geser untuk melihat pilihan paket:")
         .add_card([c1, c2])
         .send(ctx.jid)
    when "menu_demo_flow"
      flow = WhatsappWebRuby::FlowBuilder.new("weabot_feedback_v3", "Form Feedback")
                                    .add_screen("FEEDBACK_1", "Penilaian Layanan")
                                    .add_text_input("nama", "Nama Lengkap", required: true)
                                    .add_dropdown("rating", "Rating", %w[Sangat\ Puas Puas Cukup])
                                    .add_footer("Kirim", "complete")
      btn = flow.to_flow_button("Buka Form Flow v3", "tok_menu")
      ctx.button_builder
         .set_title("WhatsApp Flow v3.1")
         .set_body("Klik tombol di bawah untuk membuka form:")
         .add_button("flow", btn[:buttonParamsJson])
         .send(ctx.jid)
    when "menu_demo_rich"
      ctx.rich_builder
         .add_text("Contoh pesan *AI Rich* dengan [Docs](https://github.com/KazeDevID/whatsapp-web-ruby):")
         .add_code("ruby", "sock = WhatsappWebRuby.make_wa_socket(mode: :bridge)\nsock.send_message(jid, { text: 'Halo' })")
         .add_table(["Status Bot", "Modul | Status", "Router | Aktif;;Dispatcher | Aktif"])
         .send(ctx.jid)
    end
  end
end
