%%{
  machine graphql_lexer;

  IDENTIFIER =    [_A-Za-z][_0-9A-Za-z]*;
  NEWLINE =       [\c\r\n];
  BLANK   =       [, \t]+;
  COMMENT =       '#' [^\n\r]*;
  INT =           '-'? ('0'|[1-9][0-9]*);
  FLOAT_DECIMAL = '.'[0-9]+;
  FLOAT_EXP =     ('e' | 'E')?('+' | '-')?[0-9]+;
  FLOAT =         INT FLOAT_DECIMAL? FLOAT_EXP?;
  ON =            'on';
  FRAGMENT =      'fragment';
  TRUE =          'true';
  FALSE =         'false';
  RCURLY =        '{';
  LCURLY =        '}';
  RPAREN =        '(';
  LPAREN =        ')';
  RBRACKET =      '[';
  LBRACKET =      ']';
  COLON =         ':';
  QUOTE =         '"';
  ESCAPED_QUOTE = '\\"';
  STRING_CHAR =   (ESCAPED_QUOTE | ^'"');
  VAR_SIGN =      '$';
  DIR_SIGN =      '@';
  ELLIPSIS =      '...';
  EQUALS =        '=';
  BANG =          '!';

  QUOTED_STRING = QUOTE STRING_CHAR* QUOTE;

  main := |*
    INT           => { emit_token.call(:INT) };
    FLOAT         => { emit_token.call(:FLOAT) };
    ON            => { emit_token.call(:ON) };
    FRAGMENT      => { emit_token.call(:FRAGMENT) };
    TRUE          => { emit_token.call(:TRUE) };
    FALSE         => { emit_token.call(:FALSE) };
    RCURLY        => { emit_token.call(:RCURLY) };
    LCURLY        => { emit_token.call(:LCURLY) };
    RPAREN        => { emit_token.call(:RPAREN) };
    LPAREN        => { emit_token.call(:LPAREN) };
    RBRACKET      => { emit_token.call(:RBRACKET) };
    LBRACKET      => { emit_token.call(:LBRACKET) };
    COLON         => { emit_token.call(:COLON) };
    QUOTED_STRING => { emit_string(ts + 1, te - 1, meta) };
    VAR_SIGN      => { emit_token.call(:VAR_SIGN) };
    DIR_SIGN      => { emit_token.call(:DIR_SIGN) };
    ELLIPSIS      => { emit_token.call(:ELLIPSIS) };
    EQUALS        => { emit_token.call(:EQUALS) };
    BANG          => { emit_token.call(:BANG) };
    IDENTIFIER    => { emit_token.call(:IDENTIFIER) };

    NEWLINE => {
      meta[:line] += 1
      meta[:col] = 1
    };

    BLANK   => { meta[:col] += te - ts };
    COMMENT => { meta[:col] += te - ts };

  *|;
}%%


module GraphQL
  module Language
    module Lexer
      def self.tokenize(query_string)
        run_lexer(query_string)
      end

      # Replace any escaped unicode or whitespace with the _actual_ characters
      # To avoid allocating more strings, this modifies the string passed into it
      def self.replace_escaped_characters_in_place(raw_string)
        raw_string.gsub!(ESCAPES, ESCAPES_REPLACE)
        raw_string.gsub!(UTF_8, &UTF_8_REPLACE)
        nil
      end

      private

      %% write data;

      def self.run_lexer(query_string)
        data = query_string.unpack("c*")
        eof = data.length

        meta = {
          line: 1,
          col: 1,
          data: data,
          tokens: []
        }

        %% write init;

        emit_token = -> (name) {
          emit(name, ts, te, meta)
        }

        %% write exec;

        meta[:tokens]
      end

      def self.emit(token_name, ts, te, meta)
        meta[:tokens] << GraphQL::Language::Token.new(
          name: token_name,
          value: meta[:data][ts...te].pack("c*"),
          line: meta[:line],
          col: meta[:col],
        )
        # Bump the column counter for the next token
        meta[:col] += te - ts
      end

      ESCAPES = /\\["\\\/bfnrt]/
      ESCAPES_REPLACE = {
        '\\"' => '"',
        "\\\\" => "\\",
        "\\/" => '/',
        "\\b" => "\b",
        "\\f" => "\f",
        "\\n" => "\n",
        "\\r" => "\r",
        "\\t" => "\t",
      }

      UTF_8 = /\\u[\dAa-f]{4}/i
      UTF_8_REPLACE = -> (m) { [m[-4..-1].to_i(16)].pack('U'.freeze) }

      def self.emit_string(ts, te, meta)
        value = meta[:data][ts...te].pack("c*").force_encoding("UTF-8")
        replace_escaped_characters_in_place(value)

        meta[:tokens] << GraphQL::Language::Token.new(
          name: :STRING,
          value: value,
          line: meta[:line],
          col: meta[:col],
        )
        meta[:col] += te - ts
      end
    end
  end
end
