require_relative 'state_machine'
require_relative 'sequence'

module Saxinator
  class Element < ::Saxinator::Combinator
    def initialize(tag_name, *children, return_result: false, f: nil, &block)
      super
      @children      = [*children]
      @tag_name      = tag_name
      @child_results = nil
    end


    def start_element(state_machine, name, attrs = [])
      unless name == @tag_name
        raise ParseFailureException, "Expected <#{@tag_name}>, got <#{name}> instead; attributes = #{attrs}"
      end

      push(state_machine, Sequence.new(*@children, return_result: @return_result, &:itself), false) unless @children.empty?
    end

    def end_element(state_machine, name)
      unless name == @tag_name
        raise ParseFailureException, "Expected </#{@tag_name}>, got </#{name}> instead"
      end

      finish(state_machine, @child_results)
    end


    def continue(_state_machine, result)
      @child_results = result
    end
  end
end