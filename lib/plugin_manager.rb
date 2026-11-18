# frozen_string_literal: true

module WeabotRuby
  # Execution context passed to every plugin handler.
  class PluginContext
    attr_reader :bot, :socket, :config, :db, :dispatcher, :message, :command, :args, :text

    def initialize(bot:, message:, command: nil, args: [], text: "")
      @bot = bot
      @socket = bot.socket
      @config = bot.config
      @db = bot.db
      @dispatcher = bot.dispatcher
      @message = message
      @command = command
      @args = args
      @text = text
    end

    def jid
      @message[:from]
    end

    def sender
      @message[:sender]
    end

    def push_name
      @message[:push_name]
    end

    def group?
      @message[:is_group]
    end

    def button_id
      @message.dig(:interactive, :id)
    end

    def owner?
      @config.owner?(sender) ||
        @config.owner?(@message[:sender_alt]) ||
        (@message[:from_me] && @config.allow_from_me)
    end

    def reply(content, options = {})
      payload = content.is_a?(String) ? { text: content } : content
      @socket.send_message(jid, payload, options)
    end

    def enqueue_reply(content, idempotency_key: nil, priority: :normal)
      payload = content.is_a?(String) ? { text: content } : content
      @dispatcher.enqueue(
        jid: jid,
        content: payload,
        idempotency_key: idempotency_key,
        priority: priority
      )
    end

    def button_builder
      BaileysRec::Button.new(@socket)
    end

    def carousel_builder
      BaileysRec::Carousel.new(@socket)
    end

    def rich_builder
      BaileysRec::AIRich.new(@socket)
    end
  end

  # DSL definition for a single modular plugin.
  class PluginDefinition
    attr_accessor :name, :category, :commands, :button_patterns,
                  :owner_only, :group_only, :private_only, :handler, :button_handler

    def initialize(name)
      @name = name.to_s
      @category = "General"
      @commands = []
      @button_patterns = []
      @owner_only = false
      @group_only = false
      @private_only = false
      @handler = nil
      @button_handler = nil
    end

    def category_tag(cat)
      @category = cat.to_s
    end

    def on_commands(*cmds, &block)
      @commands.concat(cmds.flatten.map { |c| c.to_s.downcase })
      @handler = block if block_given?
    end

    def on_buttons(*patterns, &block)
      @button_patterns.concat(patterns.flatten)
      @button_handler = block if block_given?
    end
  end

  # Modular plugin loader & hot-reloader inspired by wabot-aq / baileys-rec-bot.
  class PluginManager
    attr_reader :plugins, :plugins_dir

    def initialize(plugins_dir)
      @plugins_dir = File.expand_path(plugins_dir)
      @mutex = Mutex.new
      @plugins = []
      @registry_for_load = nil
    end

    def load_all!
      @mutex.synchronize do
        loaded = []
        @registry_for_load = loaded

        Dir.glob(File.join(@plugins_dir, "*.rb")).sort.each do |file|
          load file
        end

        @plugins = loaded
        @registry_for_load = nil
        @plugins
      end
    end

    def register(name, &block)
      definition = PluginDefinition.new(name)
      definition.instance_eval(&block)
      target = @registry_for_load || @plugins
      target << definition
      definition
    end

    def categories
      @mutex.synchronize do
        grouped = Hash.new { |h, k| h[k] = [] }
        @plugins.each do |p|
          grouped[p.category].concat(p.commands)
        end
        grouped.transform_values(&:uniq)
      end
    end

    def dispatch(bot, serialized_msg)
      body = serialized_msg[:body].to_s.strip
      btn_id = serialized_msg.dig(:interactive, :id).to_s
      prefix = bot.config.prefix

      if !btn_id.empty?
        plugin = find_button_plugin(btn_id)
        if plugin
          ctx = PluginContext.new(bot: bot, message: serialized_msg, command: btn_id)
          return execute_plugin(plugin, ctx, use_button_handler: true)
        end
      end

      return nil unless body.start_with?(prefix)

      raw_cmd = body[prefix.length..].to_s.strip
      return nil if raw_cmd.empty?

      parts = raw_cmd.split(/\s+/)
      cmd = parts.first.downcase
      args = parts[1..] || []
      text = raw_cmd[parts.first.length..].to_s.strip

      plugin = find_command_plugin(cmd)
      return nil unless plugin

      ctx = PluginContext.new(bot: bot, message: serialized_msg, command: cmd, args: args, text: text)
      execute_plugin(plugin, ctx, use_button_handler: false)
    end

    private

    def find_command_plugin(cmd)
      @mutex.synchronize { @plugins.find { |p| p.commands.include?(cmd) } }
    end

    def find_button_plugin(btn_id)
      @mutex.synchronize do
        @plugins.find do |p|
          p.button_patterns.any? do |pat|
            pat.is_a?(Regexp) ? btn_id.match?(pat) : File.fnmatch?(pat.to_s, btn_id)
          end
        end
      end
    end

    def execute_plugin(plugin, ctx, use_button_handler:)
      if plugin.owner_only && !ctx.owner?
        return ctx.reply("Perintah ini hanya tersedia untuk Owner bot.")
      end
      if plugin.group_only && !ctx.group?
        return ctx.reply("Perintah ini hanya dapat digunakan di dalam Grup.")
      end
      if plugin.private_only && ctx.group?
        return ctx.reply("Perintah ini hanya dapat digunakan di chat pribadi.")
      end

      if use_button_handler && plugin.button_handler
        plugin.button_handler.call(ctx)
      elsif plugin.handler
        plugin.handler.call(ctx)
      end
    end
  end

  # Top-level DSL helper used by files inside `plugins/*.rb`.
  def self.current_plugin_manager=(mgr)
    @current_plugin_manager = mgr
  end

  def self.current_plugin_manager
    @current_plugin_manager
  end

  def self.define_plugin(name, &block)
    raise "No active PluginManager during plugin load" unless @current_plugin_manager

    @current_plugin_manager.register(name, &block)
  end
end
