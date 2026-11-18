# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

desc "Start Weabot Ruby"
task :start do
  exec "ruby", File.expand_path("bin/weabot", __dir__), "start"
end

desc "Start Weabot Ruby with Pairing Code: rake 'pairing[6281234567890]'"
task :pairing, [:phone] do |_t, args|
  abort "Usage: bundle exec rake 'pairing[6281234567890]'" if args[:phone].to_s.empty?
  exec "ruby", File.expand_path("bin/weabot", __dir__), "pairing", args[:phone].to_s
end

desc "Install Node.js dependencies for whatsapp-web-ruby bridge"
task :setup_bridge do
  exec "ruby", File.expand_path("bin/weabot", __dir__), "setup-bridge"
end

task default: :test
