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
        # TODO: what if @child_results.empty? ...
        finish(state_machine, @child_results.reduce(:+))
      else
        push(state_machine, @children.shift, false)
      end
    end
  end
end