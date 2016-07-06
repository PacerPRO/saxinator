require_relative 'character_block'
require_relative 'combinator'

module Saxinator
  class Text < ::Saxinator::Combinator
    def initialize(pattern, return_result: false, &block)
      super
      @pattern = pattern
      @buffer  = ''
    end


    def initialize_parse(state_machine)
      push_new_child(state_machine)
    end

    def continue(state_machine, result)
      @buffer += result
      push_new_child(state_machine)
    end

    def child_failed(state_machine)
      match_results = @buffer.match(@pattern)
      unless match_results
        pattern_string = @pattern.is_a?(String) ? %{"#{@pattern}"} : @pattern.to_s
        raise ParseFailureException, %{Failed to match #{pattern_string}; characters = "#{@buffer}"}
      end

      finish(state_machine, match_results)
    end

    private

    def push_new_child(state_machine)
      # child will get a block of characters, or raise on failure
      push(state_machine, CharacterBlock.new(return_result: true, &:itself), true)
    end
  end
end