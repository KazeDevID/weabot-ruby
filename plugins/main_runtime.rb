# frozen_string_literal: true

WeabotRuby.define_plugin "main_runtime" do
  category_tag "Main"

  on_commands "runtime", "stats" do |ctx|
    uptime = (Time.now - ctx.bot.started_at).to_i
    hours = uptime / 3600
    mins = (uptime % 3600) / 60
    secs = uptime % 60
    db_stats = ctx.db.stats
    q_stats = ctx.dispatcher.stats

    ctx.reply(
      "*Statistik #{ctx.config.bot_name}*\n" \
      "• Uptime: #{hours}j #{mins}m #{secs}d\n" \
      "• Mode: #{ctx.config.mode} (#{ctx.config.transport_mode})\n" \
      "• Total User: #{db_stats['users_count']}\n" \
      "• Pesan Masuk: #{db_stats['messages_in']}\n" \
      "• Queue Terkirim: #{q_stats[:sent]} | Retry: #{q_stats[:retried]}"
    )
  end
end
