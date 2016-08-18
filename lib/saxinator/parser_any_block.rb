require_relative 'choice'
require_relative 'parser_base'

module Saxinator
  class ParserAnyBlock < ::Saxinator::ParserBase
    # combinators
    def try(f = nil, &block)
      raise InvalidParserError, 'Invalid "try" section; please supply a block' unless block_given?

      subroot = Parser.new(&block).root
      # TODO: does not always return result ...
      @stack.push(Choice.new(subroot, return_result: true, f: f))
    end


    private

    def name
      "'any' section"
    end
  end
end