FROM ruby:3.2-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends git curl ca-certificates gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Rakefile ./
RUN bundle install

# Install Node bridge dependencies from bundled whatsapp-web-ruby gem
RUN BRIDGE_DIR=$(bundle exec ruby -e 'puts File.expand_path("whatsapp_web_ruby/bridge", File.dirname(Gem.loaded_specs["whatsapp-web-ruby"].full_require_paths.first))') && \
    if [ -d "$BRIDGE_DIR" ]; then cd "$BRIDGE_DIR" && npm install --omit=dev; fi

COPY . .
RUN chmod +x bin/weabot

EXPOSE 4567
CMD ["bundle", "exec", "bin/weabot", "start"]
