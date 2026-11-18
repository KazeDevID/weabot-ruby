# frozen_string_literal: true

require "baileys_rec"
require_relative "../config/bot"
require_relative "database"
require_relative "plugin_manager"

module WeabotRuby
  # Main WeabotRuby Orchestrator powering WhatsApp Multi-Device, Cloud API,
  # Plugin Dispatch, Rate-Limited Queue, and REST API WebhookServer.
  class Bot
    attr_reader :config, :db, :socket, :dispatcher, :plugin_manager, :webhook_server, :started_at

    def initialize(config = Config.new, socket_adapter: nil)
      @config = config
      @db = Database.new(@config.db_path)
      @started_at = Time.now

      persisted_mode = @db.setting("bot_mode")
      @config.mode = persisted_mode.to_sym if persisted_mode

      @socket = BaileysRec.make_wa_socket(
        mode: @config.transport_mode,
        auth_folder: @config.auth_folder,
        print_qr_in_terminal: @config.print_qr && @config.pairing_number.empty?,
        phone_number_id: @config.phone_number_id,
        access_token: @config.access_token,
        adapter: socket_adapter
      )

      @dispatcher = BaileysRec::Automation::Dispatcher.new(
        socket: @socket,
        per_jid_interval: @config.per_jid_interval,
        max_attempts: @config.max_retry_attempts,
        on_dead_letter: ->(job, err) { warn "[WeabotRuby] Dead-letter job #{job.id} (#{job.jid}): #{err.message}" }
      )

      @plugin_manager = PluginManager.new(@config.plugins_dir)
      reload_plugins!

      @webhook_server = if @config.api_enabled
                          BaileysRec::Automation::WebhookServer.new(
                            socket: @socket,
                            dispatcher: @dispatcher,
                            host: @config.api_host,
                            port: @config.api_port,
                            api_key: @config.api_key,
                            webhook_url: @config.webhook_url.empty? ? nil : @config.webhook_url,
                            webhook_secret: @config.webhook_secret.empty? ? nil : @config.webhook_secret
                          )
                        end
    end

    def reload_plugins!
      WeabotRuby.current_plugin_manager = @plugin_manager
      @plugin_manager.load_all!
    ensure
      WeabotRuby.current_plugin_manager = nil
    end

    def start(blocking: true)
      attach_socket_events
      @dispatcher.start
      @socket.connect

      if @config.transport_mode == :bridge && !@config.pairing_number.empty?
        request_pairing!(@config.pairing_number)
      end

      @webhook_server&.start(blocking: false)

      if blocking
        trap("INT") { shutdown_and_exit }
        trap("TERM") { shutdown_and_exit }
        sleep
      end
      self
    end

    def stop
      @webhook_server&.stop
      @dispatcher.stop(drain: true)
      @db.save!
      @socket.end_connection
    end

    def request_pairing!(phone_number)
      Thread.new do
        sleep 2.0
        res = @socket.request_pairing_code(phone_number)
        puts "[WeabotRuby] Pairing Code (#{res['phoneNumber']}): #{res['code']}"
      rescue StandardError => e
        warn "[WeabotRuby] Failed requesting pairing code: #{e.message}"
      end
    end

    def handle_messages_upsert(upsert)
      messages = upsert.is_a?(Hash) ? (upsert["messages"] || upsert[:messages] || []) : Array(upsert)
      messages.each do |raw|
        msg = BaileysRec.serialize_message(raw)
        next unless msg
        next if msg[:from_me]
        next if @config.mode == :self && !@config.owner?(msg[:sender])

        @db.touch_user(msg[:sender], msg[:push_name])
        @plugin_manager.dispatch(self, msg)
      end
    rescue StandardError => e
      warn "[WeabotRuby] Error dispatching message: #{e.class} - #{e.message}"
    end

    private

    def attach_socket_events
      @socket.ev.on(:connection_update) do |update|
        conn = update.is_a?(Hash) ? (update["connection"] || update[:connection]) : nil
        puts "[WeabotRuby] Connection update: #{conn}" if conn
      end

      @socket.ev.on(:messages_upsert) do |upsert|
        handle_messages_upsert(upsert)
      end
    end

    def shutdown_and_exit
      puts "\n[WeabotRuby] Shutting down gracefully..."
      stop
      exit(0)
    end
  end
end
