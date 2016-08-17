require_relative 'combinator'

module Saxinator
  class Star < ::Saxinator::Combinator
    def initialize(child, return_result: false, f: nil, &block)
      super
      @child         = child
      @child_results = []
    end

    def initialize_parse(state_machine)
      push(state_machine, @child, true) # child is allowed to fail
    end

    def continue(state_machine, result)
      # child parse succeeded; record result and keep going
      @child_results.push(result) unless result.nil?

      @child.reset
      push(state_machine, @child, true) # child is allowed to fail
    end

    def child_failed(state_machine)
      # child parse failed
      # return results collected
      finish(state_machine, @child_results)
    end
  end
end