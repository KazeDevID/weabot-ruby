# frozen_string_literal: true

source "https://rubygems.org"

local_path = ENV["WHATSAPP_WEB_RUBY_PATH"] || ENV["BAILEYS_REC_PATH"]
if local_path && !local_path.empty?
  gem "whatsapp-web-ruby", path: local_path
else
  gem "whatsapp-web-ruby", git: "https://github.com/KazeDevID/whatsapp-web-ruby.git", branch: "main"
end
