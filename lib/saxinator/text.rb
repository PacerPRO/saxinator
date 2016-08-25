require_relative 'character_block'
require_relative 'combinator'

module Saxinator
  class Text < ::Saxinator::Combinator
    attr_reader :pattern, :f

    def initialize(pattern, return_result: false, f: nil)
      super
      @pattern = pattern
      @buffer  = ''
    end


    def initialize_parse(state_machine)
      push_new_child(state_machine)
    end

    # result should be in form { values: [x] }
    #   where x is a string
    def continue(state_machine, result)
      # TODO?: this might be a bit slow; CharacterBlock always returns string; ResultHash may be overkill ...
      @buffer += result.inner_value[:values].last
      push_new_child(state_machine)
    end

    def child_failed(state_machine)
      matches = @buffer.match(@pattern)
      unless matches
        pattern_string = @pattern.is_a?(String) ? %{"#{@pattern}"} : @pattern.to_s
        raise ParseFailureException, %{Failed to match #{pattern_string}; characters = "#{@buffer}"}
      end

      finish(state_machine, matches)
    end


    def self.new_multi_text(texts)
      # TODO: don't just return first text - actually combine them ...
      combined_pattern = texts.map(&:pattern).join

      # TODO: pass f; don't always assume return_result is true ...
      # TODO?: intersperse whitespace ...
      Text.new(combined_pattern, return_result: true)
    end


    private

    def push_new_child(state_machine)
      # child will get a block of characters, or raise on failure
      push(state_machine, CharacterBlock.new(return_result: true, f: -> (x) { x }), true)
    end

    # override of base method to return text matched by capture groups
    def default_f(matches)
      ResultHash.sum(matches.captures.map { |s| ResultHash.new(s) })
    end
  end
end