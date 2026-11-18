# frozen_string_literal: true

WeabotRuby.define_plugin "tools_calc" do
  category_tag "Tools"

  # Safe recursive-descent arithmetic evaluator (no Ruby eval).
  unless defined?(SafeMathParser)
    class SafeMathParser
      def initialize(expr)
        @tokens = expr.scan(/\d+(?:\.\d+)?|[+\-*\/%()]/)
        @pos = 0
      end

      def evaluate
        raise ArgumentError, "Ekspresi kosong" if @tokens.empty?

        val = parse_expr
        raise ArgumentError, "Token tidak valid" if @pos < @tokens.size

        val
      end

      private

      def parse_expr
        left = parse_term
        while %w[+ -].include?(peek)
          op = consume
          right = parse_term
          left = op == "+" ? left + right : left - right
        end
        left
      end

      def parse_term
        left = parse_factor
        while %w[* / %].include?(peek)
          op = consume
          right = parse_factor
          raise ZeroDivisionError, "Pembagian dengan nol" if %w[/ %].include?(op) && right.zero?

          left = case op
                 when "*" then left * right
                 when "/" then left.to_f / right
                 else left % right
                 end
        end
        left
      end

      def parse_factor
        if peek == "("
          consume
          val = parse_expr
          raise ArgumentError, "Kurung tutup hilang" unless consume == ")"

          return val
        end

        if peek == "-"
          consume
          return -parse_factor
        end

        tok = consume
        raise ArgumentError, "Angka diharapkan" unless tok&.match?(/\A\d+(?:\.\d+)?\z/)

        tok.include?(".") ? tok.to_f : tok.to_i
      end

      def peek = @tokens[@pos]
      def consume = (@tokens[@pos].tap { @pos += 1 })
    end
  end

  on_commands "calc", "hitung" do |ctx|
    if ctx.text.empty?
      next ctx.reply("Contoh: #{ctx.config.prefix}calc (125 * 4) + 50")
    end

    unless ctx.text.match?(/\A[\d\s+\-*\/%().]+\z/)
      next ctx.reply("Karakter tidak diizinkan. Gunakan angka dan operator + - * / % ( ).")
    end

    result = SafeMathParser.new(ctx.text).evaluate
    formatted = result.is_a?(Float) && (result % 1).zero? ? result.to_i : result
    ctx.reply("Hasil: *#{formatted}*")
  rescue StandardError => e
    ctx.reply("Gagal menghitung: #{e.message}")
  end
end
