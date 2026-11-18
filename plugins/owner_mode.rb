# frozen_string_literal: true

WeabotRuby.define_plugin "owner_mode" do
  category_tag "Owner"
  @owner_only = true

  on_commands "self", "public" do |ctx|
    new_mode = ctx.command == "self" ? :self : :public
    ctx.config.mode = new_mode
    ctx.db.set_setting("bot_mode", new_mode.to_s)
    ctx.reply("Mode bot diubah ke *#{new_mode.to_s.upcase}* dan disimpan.")
  end
end
