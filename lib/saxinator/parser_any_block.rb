require_relative 'choice'
require_relative 'parser_base'

module Saxinator
  class ParserAnyBlock < ::Saxinator::ParserBase
    # combinators
    def try(&block)
      raise InvalidParserError, 'Invalid "try" section; please supply a block' unless block_given?

      subroot = Parser.new(&block).root
      @stack.push(Choice.new(subroot))
    end


    private

    def name
      "'any' section"
    end
  end
end