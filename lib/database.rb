# frozen_string_literal: true

require "json"
require "fileutils"

module WeabotRuby
  # Thread-safe atomic JSON persistence for users, chats, settings, and bot stats.
  class Database
    attr_reader :path

    def initialize(path)
      @path = File.expand_path(path)
      @mutex = Mutex.new
      FileUtils.mkdir_p(File.dirname(@path))
      @data = load_from_disk
    end

    def user(jid)
      key = BaileysRec::Utils::Jid.jid_normalized_user(jid)
      @mutex.synchronize do
        @data["users"][key] ||= {
          "jid" => key,
          "name" => "",
          "hits" => 0,
          "banned" => false,
          "first_seen" => Time.now.to_i,
          "last_seen" => Time.now.to_i
        }
      end
    end

    def touch_user(jid, push_name = "")
      key = BaileysRec::Utils::Jid.jid_normalized_user(jid)
      @mutex.synchronize do
        entry = (@data["users"][key] ||= {
          "jid" => key,
          "name" => push_name.to_s,
          "hits" => 0,
          "banned" => false,
          "first_seen" => Time.now.to_i
        })
        entry["name"] = push_name.to_s unless push_name.to_s.empty?
        entry["hits"] = entry["hits"].to_i + 1
        entry["last_seen"] = Time.now.to_i
        @data["stats"]["messages_in"] = @data["stats"]["messages_in"].to_i + 1
        entry
      end
    end

    def known_user_jids
      @mutex.synchronize { @data["users"].keys.dup }
    end

    def chat(jid)
      key = jid.to_s
      @mutex.synchronize do
        @data["chats"][key] ||= {
          "jid" => key,
          "welcome" => false,
          "muted" => false
        }
      end
    end

    def setting(key, default = nil)
      @mutex.synchronize { @data["settings"].fetch(key.to_s, default) }
    end

    def set_setting(key, value)
      @mutex.synchronize do
        @data["settings"][key.to_s] = value
      end
      save!
    end

    def stats
      @mutex.synchronize do
        @data["stats"].merge(
          "users_count" => @data["users"].size,
          "chats_count" => @data["chats"].size
        )
      end
    end

    def save!
      @mutex.synchronize do
        tmp = "#{@path}.tmp.#{Process.pid}"
        File.write(tmp, JSON.pretty_generate(@data), encoding: "UTF-8")
        File.rename(tmp, @path)
      end
    end

    private

    def load_from_disk
      base = { "users" => {}, "chats" => {}, "settings" => {}, "stats" => { "messages_in" => 0 } }
      return base unless File.exist?(@path)

      parsed = JSON.parse(File.read(@path, encoding: "UTF-8"))
      base.merge(parsed)
    rescue JSON::ParserError
      base
    end
  end
end
