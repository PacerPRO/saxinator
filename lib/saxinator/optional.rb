require_relative 'combinator'

module Saxinator
  class Optional < ::Saxinator::Combinator
    def initialize(child, return_result: false, &block)
      super
      @child = child
    end


    def initialize_parse(state_machine)
      push(state_machine, @child, true) # attempt to parse child
    end

    def continue(state_machine, result)
      # child parse succeeded; we succeed as well
      finish(state_machine, result)
    end

    def child_failed(state_machine)
      # child parse failed
      # this is no problem
      finish(state_machine, nil)
    end
  end
end