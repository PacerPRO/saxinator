require_relative 'combinator'

module Saxinator
  class Optional < ::Saxinator::Combinator
    def initialize(child, return_result: false, &block)
      super
      @child = child
    end


    def initialize_parse(parser)
      push(parser, @child, true) # attempt to parse child
    end

    def start_element(parser, name, attrs = [])
      @child.start_element(parser, name, attrs)
    end

    def end_element(parser, name)
      @child.end_element(parser, name)
    end

    def continue(parser, result)
      # child parse succeeded; we succeed as well
      finish(parser, result)
    end

    def child_failed(parser)
      # child parse failed
      # this is no problem
      finish(parser, nil)
    end
  end
end