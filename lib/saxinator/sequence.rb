require_relative 'combinator'

module Saxinator
  class Sequence < ::Saxinator::Combinator
    def initialize(*children, return_result: false, f: nil)
      super
      @children      = [*children]
      @child_results = []
    end


    def initialize_parse(state_machine)
      shift_next_child(state_machine)
    end

    def continue(state_machine, result)
      @child_results.push(result) unless result.nil?
      shift_next_child(state_machine)
    end


    private

    def shift_next_child(state_machine)
      if @children.empty?
        finish(state_machine, ResultHash.sum(@child_results))
      else
        next_child = @children.shift
        if next_child.is_a?(Text) && @children.first.is_a?(Text)
          shift_multi_text(state_machine, next_child)
        else
          push(state_machine, next_child, false)
        end
      end
    end

    def shift_multi_text(state_machine, next_child)
      texts = [next_child, @children.shift]
      while @children.first.is_a?(Text)
        texts.push(@children.shift)
      end

      push(state_machine, Text.new_multi_text(texts), false)
    end
  end
end