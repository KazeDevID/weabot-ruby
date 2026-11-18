# frozen_string_literal: true

WeabotRuby.define_plugin "owner_reload" do
  category_tag "Owner"
  @owner_only = true

  on_commands "reload" do |ctx|
    loaded = ctx.bot.reload_plugins!
    ctx.reply("Berhasil me-reload *#{loaded.size}* plugin tanpa restart koneksi.")
  end
end
