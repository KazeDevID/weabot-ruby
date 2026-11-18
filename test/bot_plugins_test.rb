# frozen_string_literal: true

require "fileutils"
require_relative "test_helper"

class BotPluginsTest < Minitest::Test
  def setup
    @tmp_dir = File.join("/tmp", "weabot_ruby_test_#{Process.pid}_#{rand(10_000)}")
    FileUtils.mkdir_p(@tmp_dir)
    @config = WeabotRuby::Config.new(
      bot_name: "TestBot",
      prefix: "!",
      owners: ["628111111111"],
      transport_mode: :memory,
      api_enabled: false,
      per_jid_interval: 0.01,
      db_path: File.join(@tmp_dir, "db.json")
    )
    @bot = WeabotRuby::Bot.new(@config)
    @bot.dispatcher.start
    @bot.socket.connect
  end

  def teardown
    @bot.stop
    FileUtils.rm_rf(@tmp_dir)
  end

  def emit_text(from:, text:, id: "M_#{rand(10_000)}", push_name: "Tester", participant: nil)
    key = { "remoteJid" => from, "id" => id, "fromMe" => false }
    key["participant"] = participant if participant
    @bot.handle_messages_upsert(
      "messages" => [
        {
          "key" => key,
          "pushName" => push_name,
          "message" => { "conversation" => text }
        }
      ]
    )
  end

  def emit_button(from:, button_id:, id: "B_#{rand(10_000)}")
    @bot.handle_messages_upsert(
      "messages" => [
        {
          "key" => { "remoteJid" => from, "id" => id, "fromMe" => false },
          "pushName" => "Tester",
          "message" => {
            "buttonsResponseMessage" => {
              "selectedButtonId" => button_id,
              "selectedDisplayText" => button_id
            }
          }
        }
      ]
    )
  end

  def sent_messages
    @bot.socket.adapter.sent_messages
  end

  def test_menu_ping_calc_and_interactive_demos
    emit_text(from: "628222222222@s.whatsapp.net", text: "!menu")
    emit_text(from: "628222222222@s.whatsapp.net", text: "!ping")
    emit_text(from: "628222222222@s.whatsapp.net", text: "!calc (100 * 3) + 45")
    emit_text(from: "628222222222@s.whatsapp.net", text: "!carousel")
    emit_text(from: "628222222222@s.whatsapp.net", text: "!flow")
    emit_text(from: "628222222222@s.whatsapp.net", text: "!rich")
    emit_button(from: "628222222222@s.whatsapp.net", button_id: "menu_demo_button")

    assert_equal 7, sent_messages.size
    assert_equal "Hasil: *345*", sent_messages[2][:content][:text]
    assert sent_messages[3][:content].dig(:viewOnceMessage, :message, :interactiveMessage, :carouselMessage)
    assert sent_messages[5][:content].dig(:botForwardedMessage, :message, :richResponseMessage)
  end

  def test_owner_guard_self_mode_and_broadcast_queue
    # Non-owner cannot trigger owner-only broadcast
    emit_text(from: "628222222222@s.whatsapp.net", text: "!broadcast Hello")
    assert_includes sent_messages.last[:content][:text], "hanya tersedia untuk Owner"

    # Seed another user via normal message
    emit_text(from: "628333333333@s.whatsapp.net", text: "!ping")
    before = sent_messages.size

    # Owner triggers broadcast via rate-limited Dispatcher
    emit_text(from: "628111111111@s.whatsapp.net", text: "!broadcast Update sistem")
    @bot.dispatcher.wait_until_empty(timeout: 5)
    assert_equal before + 3, sent_messages.size # 1 confirmation + 2 target users

    # Owner switches to self mode; non-owner messages are ignored
    emit_text(from: "628111111111@s.whatsapp.net", text: "!self")
    count_after_self = sent_messages.size
    emit_text(from: "628222222222@s.whatsapp.net", text: "!ping")
    assert_equal count_after_self, sent_messages.size

    # Owner can hot-reload plugins
    emit_text(from: "628111111111@s.whatsapp.net", text: "!reload")
    assert_includes sent_messages.last[:content][:text], "me-reload"
  end

  def test_group_only_guard
    emit_text(from: "628222222222@s.whatsapp.net", text: "!groupinfo")
    assert_includes sent_messages.last[:content][:text], "di dalam Grup"

    emit_text(
      from: "120363000123@g.us",
      participant: "628222222222@s.whatsapp.net",
      text: "!groupinfo"
    )
    assert_includes sent_messages.last[:content][:text], "Mock Group"
  end
end
