# frozen_string_literal: true

WeabotRuby.define_plugin "main_ping" do
  category_tag "Main"

  on_commands "ping", "speed" do |ctx|
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    stats = ctx.dispatcher.stats
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round(2)

    ctx.reply(
      "*Pong!*\n" \
      "• Response: #{elapsed_ms} ms\n" \
      "• Ruby: #{RUBY_VERSION}\n" \
      "• whatsapp-web-ruby: #{WhatsappWebRuby::VERSION}\n" \
      "• Queue Sent: #{stats[:sent]} | Pending: #{ctx.dispatcher.pending_count}"
    )
  end

  on_buttons "quick_ping" do |ctx|
    ctx.reply("Pong dari tombol interaktif!")
  end
end
