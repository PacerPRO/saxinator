require_relative 'parser'
require_relative 'sequence'

module Saxinator
  class Element < ::Saxinator::Combinator
    def initialize(tag_name, *children, return_result: false, &block)
      super
      @children      = [*children]
      @tag_name      = tag_name
      @child_results = nil
    end


    def start_element(parser, name, attrs = [])
      unless name == @tag_name
        raise ParseFailureException, "Expected <#{@tag_name}>, got <#{name}> instead; attributes = #{attrs}"
      end

      push(parser, Sequence.new(*@children, return_result: @return_result, &:itself), false) unless @children.empty?
    end

    def end_element(parser, name)
      unless name == @tag_name
        raise ParseFailureException, "Expected </#{@tag_name}>, got </#{name}> instead"
      end

      finish(parser, @child_results)
    end


    def continue(_parser, result)
      @child_results = result
    end
  end
end