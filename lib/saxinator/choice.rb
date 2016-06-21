require_relative 'combinator'

module Saxinator
  class Choice < ::Saxinator::Combinator
    def initialize(child, *more_children, return_result: false, &block)
      super
      @children = [child, *more_children]
    end


    def initialize_parse(parser)
      push(parser, @children.shift, true) # child is allowed to fail
    end

    def continue(parser, result)
      # child succeeded
      finish(parser, result)
    end

    def child_failed(parser)
      if @children.length > 0
        push(parser, @children.shift, true) # child is allowed to fail
      else
        raise ParseFailureException, "Choice: parsing failed for all choices: #{self.inspect}"
      end
    end
  end
end