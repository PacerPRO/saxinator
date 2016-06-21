require_relative 'combinator'

module Saxinator
  class Sequence < ::Saxinator::Combinator
    def initialize(*children, return_result: false, &block)
      super
      @children         = [*children]
      @multiple_results = @children.length > 1
      @child_results    = []
    end


    def initialize_parse(parser)
      shift_next_child(parser)
    end

    def continue(parser, result)
      @child_results.push(result) unless result.nil?
      shift_next_child(parser)
    end

    private

    def shift_next_child(parser)
      if @children.empty?
        finish(parser, @multiple_results ? @child_results : @child_results.first)
      else
        push(parser, @children.shift, false)
      end
    end
  end
end