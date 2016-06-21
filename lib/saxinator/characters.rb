require_relative 'character_block'
require_relative 'combinator'

module Saxinator
  class Characters < ::Saxinator::Combinator
    def initialize(regex, return_result: false, &block)
      super
      @regex  = regex
      @buffer = ''
    end


    def initialize_parse(parser)
      push_new_child(parser)
    end

    def continue(parser, result)
      @buffer += result
      push_new_child(parser)
    end

    def child_failed(parser)
      match_results = @buffer.match(@regex)
      raise ParseFailureException, "Failed to match #{@regex}; characters = #{@buffer}" unless match_results

      finish(parser, match_results)
    end

    private

    def push_new_child(parser)
      # child will get a block of characters, or raise on failure
      push(parser, CharacterBlock.new(return_result: true, &:itself), true)
    end
  end
end