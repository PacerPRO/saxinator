require_relative 'character_block'
require_relative 'combinator'

module Saxinator
  class Text < ::Saxinator::Combinator
    def initialize(regex, return_result: false, &block)
      super
      @regex  = regex
      @buffer = ''
    end


    def initialize_parse(state_machine)
      push_new_child(state_machine)
    end

    def continue(state_machine, result)
      @buffer += result
      push_new_child(state_machine)
    end

    def child_failed(state_machine)
      match_results = @buffer.match(@regex)
      raise ParseFailureException, "Failed to match #{@regex}; characters = #{@buffer}" unless match_results

      finish(state_machine, match_results)
    end

    private

    def push_new_child(state_machine)
      # child will get a block of characters, or raise on failure
      push(state_machine, CharacterBlock.new(return_result: true, &:itself), true)
    end
  end
end