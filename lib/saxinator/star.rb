require_relative 'combinator'

module Saxinator
  class Star < ::Saxinator::Combinator
    def initialize(child, return_result: false, &block)
      super
      @child         = child
      @child_results = []
    end

    def initialize_parse(parser)
      push(parser, @child, true) # child is allowed to fail
    end

    def continue(parser, result)
      # child parse succeeded; record result and keep going
      @child_results.push(result) unless result.nil?

      @child.reset
      push(parser, @child, true) # child is allowed to fail
    end

    def child_failed(parser)
      # child parse failed
      # return results collected
      finish(parser, @child_results)
    end
  end
end