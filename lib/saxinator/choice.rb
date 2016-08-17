require_relative 'combinator'

module Saxinator
  class Choice < ::Saxinator::Combinator
    def initialize(child, *more_children, return_result: false, f: nil)
      super
      @children = [child, *more_children]
    end


    def initialize_parse(state_machine)
      push(state_machine, @children.shift, true) # child is allowed to fail
    end

    def continue(state_machine, result)
      # child succeeded
      finish(state_machine, result)
    end

    def child_failed(state_machine)
      if @children.length > 0
        push(state_machine, @children.shift, true) # child is allowed to fail
      else
        raise ParseFailureException, "Choice: parsing failed for all choices: #{self.inspect}"
      end
    end
  end
end