# frozen_string_literal: true

require "json"

WeabotRuby.define_plugin "tools_cloudapi" do
  category_tag "Tools"

  on_commands "sanitize", "cloudapi" do |ctx|
    if ctx.command == "sanitize"
      if ctx.text.empty?
        next ctx.reply("Contoh: #{ctx.config.prefix}sanitize +62 812-3456-7890")
      end

      clean = BaileysRec.sanitize_whatsapp_number(ctx.text)
      next ctx.reply("Normalisasi E.164: `#{clean}`\nJID: `#{clean}@s.whatsapp.net`")
    end

    if ctx.text.empty?
      next ctx.reply("Kirim JSON Meta Cloud API setelah perintah #{ctx.config.prefix}cloudapi")
    end

    payload = JSON.parse(ctx.text)
    converted = BaileysRec.from_cloud_api_message(payload)
    ctx.reply("```json\n#{JSON.pretty_generate(converted)}\n```")
  rescue JSON::ParserError => e
    ctx.reply("JSON tidak valid: #{e.message}")
  end
end
