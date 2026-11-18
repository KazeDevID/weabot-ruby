# frozen_string_literal: true

require "baileys_rec"

module WeabotRuby
  # Non-global immutable/encapsulated bot configuration.
  class Config
    attr_accessor :bot_name, :prefix, :mode, :owners, :transport_mode,
                  :auth_folder, :pairing_number, :print_qr,
                  :per_jid_interval, :max_retry_attempts,
                  :api_enabled, :api_host, :api_port, :api_key,
                  :webhook_url, :webhook_secret,
                  :phone_number_id, :access_token, :db_path, :plugins_dir

    def initialize(overrides = {})
      @bot_name = env_or("BOT_NAME", "Weabot Ruby", overrides[:bot_name])
      @prefix = env_or("BOT_PREFIX", "!", overrides[:prefix])
      @mode = env_or("BOT_MODE", "public", overrides[:mode]).to_sym
      @owners = parse_owners(overrides[:owners] || ENV.fetch("OWNER_NUMBERS", "6281234567890"))
      @transport_mode = env_or("TRANSPORT_MODE", "bridge", overrides[:transport_mode]).to_sym
      @auth_folder = env_or("AUTH_FOLDER", "./auth_info", overrides[:auth_folder])
      @pairing_number = env_or("PAIRING_NUMBER", "", overrides[:pairing_number])
      @print_qr = overrides.key?(:print_qr) ? overrides[:print_qr] : ENV.fetch("PRINT_QR", "true") == "true"
      @per_jid_interval = (overrides[:per_jid_interval] || ENV.fetch("PER_JID_INTERVAL", "1.2")).to_f
      @max_retry_attempts = (overrides[:max_retry_attempts] || ENV.fetch("MAX_RETRY_ATTEMPTS", "3")).to_i
      @api_enabled = overrides.key?(:api_enabled) ? overrides[:api_enabled] : ENV.fetch("API_ENABLED", "true") == "true"
      @api_host = env_or("API_HOST", "0.0.0.0", overrides[:api_host])
      @api_port = (overrides[:api_port] || ENV.fetch("API_PORT", "4567")).to_i
      @api_key = env_or("API_KEY", "", overrides[:api_key])
      @webhook_url = env_or("WEBHOOK_URL", "", overrides[:webhook_url])
      @webhook_secret = env_or("WEBHOOK_SECRET", "", overrides[:webhook_secret])
      @phone_number_id = env_or("WHATSAPP_PHONE_NUMBER_ID", "", overrides[:phone_number_id])
      @access_token = env_or("WHATSAPP_ACCESS_TOKEN", "", overrides[:access_token])
      @db_path = overrides[:db_path] || File.expand_path("../data/database.json", __dir__)
      @plugins_dir = overrides[:plugins_dir] || File.expand_path("../plugins", __dir__)
    end

    def owner?(jid_or_phone)
      clean = BaileysRec.sanitize_whatsapp_number(jid_or_phone)
      @owners.include?(clean)
    end

    private

    def env_or(key, default, override)
      return override unless override.nil?

      val = ENV[key]
      (val.nil? || val.empty?) ? default : val
    end

    def parse_owners(raw)
      list = raw.is_a?(Array) ? raw : raw.to_s.split(",")
      list.map { |item| BaileysRec.sanitize_whatsapp_number(item) }.reject(&:empty?).uniq
    end
  end
end
