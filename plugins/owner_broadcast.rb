# frozen_string_literal: true

WeabotRuby.define_plugin "owner_broadcast" do
  category_tag "Owner"
  @owner_only = true

  on_commands "broadcast", "bc" do |ctx|
    if ctx.text.empty?
      next ctx.reply("Contoh: #{ctx.config.prefix}broadcast Promo akhir pekan aktif sekarang!")
    end

    targets = ctx.db.known_user_jids.reject { |j| j == BaileysRec::Utils::Jid.jid_normalized_user(ctx.sender) }
    if targets.empty?
      next ctx.reply("Belum ada user lain di database untuk di-broadcast.")
    end

    batch_id = "bc-#{Time.now.to_i}"
    targets.each_with_index do |target_jid, idx|
      ctx.dispatcher.enqueue(
        jid: target_jid,
        content: {
          text: "*[Broadcast #{ctx.config.bot_name}]*\n\n#{ctx.text}"
        },
        idempotency_key: "#{batch_id}-#{idx}"
      )
    end

    ctx.reply("Menambahkan *#{targets.size}* pesan ke antrean Dispatcher (rate-limit #{ctx.config.per_jid_interval}s/JID).")
  end
end
