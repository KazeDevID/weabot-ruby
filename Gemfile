# frozen_string_literal: true

source "https://rubygems.org"

if ENV["BAILEYS_REC_PATH"] && !ENV["BAILEYS_REC_PATH"].empty?
  gem "baileys_rec", path: ENV["BAILEYS_REC_PATH"]
else
  gem "baileys_rec", git: "https://github.com/KazeDevID/baileys-rec-rb.git", branch: "main"
end
