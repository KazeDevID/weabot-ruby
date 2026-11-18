# frozen_string_literal: true

WeabotRuby.define_plugin "group_admin" do
  category_tag "Group"
  @group_only = true

  on_commands "groupinfo", "kick", "promote", "demote" do |ctx|
    case ctx.command
    when "groupinfo"
      meta = ctx.socket.group_metadata(ctx.jid)
      subject = meta["subject"] || meta[:subject] || "Grup"
      participants = Array(meta["participants"] || meta[:participants])
      ctx.reply("*Info Grup*\n• Nama: #{subject}\n• JID: #{ctx.jid}\n• Anggota: #{participants.size}")
    when "kick", "promote", "demote"
      unless ctx.owner?
        next ctx.reply("Perintah moderasi grup dibatasi untuk Owner bot.")
      end

      target = ctx.args.first
      next ctx.reply("Masukkan nomor target. Contoh: #{ctx.config.prefix}#{ctx.command} 6281234567890") if target.to_s.empty?

      action = ctx.command == "kick" ? "remove" : ctx.command
      ctx.socket.group_participants_update(ctx.jid, [target], action)
      ctx.reply("Berhasil menjalankan *#{action}* pada #{BaileysRec.sanitize_whatsapp_number(target)}.")
    end
  end
end
