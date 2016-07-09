require 'nokogiri'

require_relative 'element'
require_relative 'invalid_parser_error'
require_relative 'optional'
require_relative 'parse_failure_error'
require_relative 'parse_failure_exception'
require_relative 'parse_failure_nokogiri_error'
require_relative 'parser_any_block'
require_relative 'parser_base'
require_relative 'sequence'
require_relative 'star'
require_relative 'text'

module Saxinator
  class Parser < ::Saxinator::ParserBase
    # combinators
    def text(pattern = //)
      @stack.push(Text.new(pattern))
    end

    # TODO?: make non-recursive to guard against stack overflow ...
    def tag(name, &block)
      if block_given?
        # TODO: get the children of the Sequence object at the root ...
        subroot = Parser.new(&block).root
        @stack.push(Element.new(name, subroot))
      else
        @stack.push(Element.new(name))
      end
    end

    def optional(&block)
      raise InvalidParserError, 'Invalid "optional" element; please supply a block' unless block_given?

      subroot = Parser.new(&block).root
      @stack.push(Optional.new(subroot))
    end

    def star(&block)
      raise InvalidParserError, 'Invalid "star" element; please supply a block' unless block_given?

      subroot = Parser.new(&block).root
      @stack.push(Star.new(subroot))
    end

    def any(&block)
      subroot = ParserAnyBlock.new(Choice, &block).root
      @stack.push(subroot)
    end
  end
end