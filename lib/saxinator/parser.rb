require 'nokogiri'

require_relative 'element'
require_relative 'invalid_parser_error'
require_relative 'parse_failure_error'
require_relative 'parse_failure_exception'
require_relative 'parse_failure_nokogiri_error'
require_relative 'sequence'
require_relative 'text'

module Saxinator
  class Parser
    def initialize(&block)
      raise InvalidParserError, 'Invalid parser; please supply a block' unless block_given?
      build_root(&block)
    end

    def parse(html)
      begin
        inner_parse(html)
      rescue Nokogiri::XML::SyntaxError => e
        raise ParseFailureNokogiriError, e.message
      rescue ParseFailureException => e
        raise ParseFailureError, e.message
      end
    end

    # combinators
    def text(pattern = //)
      @stack.push(Text.new(pattern))
    end

    def tag(name)
      # TODO: allow children ...
      @stack.push(Element.new(name))
    end

    private

    # TODO: add delegation - see http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation ...
    def build_root(&block)
      @stack = []
      self.instance_eval(&block)

      build_root_from_stack
    end

    def build_root_from_stack
      case @stack.length
      when 0
        raise InvalidParserError, 'Invalid parser; the supplied block is empty'
      when 1
        @root = @stack.first
      else
        @root = Sequence.new(*@stack)
      end
    end

    def inner_parse(html)
      @root.parse(html)
    end
  end
end