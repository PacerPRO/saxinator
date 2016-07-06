require 'nokogiri'

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
      # TODO: add delegation - see http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation ...
      @root = self.instance_eval(&block)
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
      # TODO: test @root before assigning ...
      @root = Text.new(pattern)
    end

    private

    def inner_parse(html)
      @root.parse(html)
    end
  end
end