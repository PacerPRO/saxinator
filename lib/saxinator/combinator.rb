module Saxinator
  class Combinator
    def initialize(*args, return_result: false, &block)
      @args          = args
      @return_result = return_result
      @block         = block
    end


    def reset
      @args.each { |arg| arg.reset if arg.is_a?(Combinator) }
      initialize(*@args, return_result: @return_result, &@block)
    end


    def start_element(_parser, name, attrs = [])
      raise ParseFailureException, "Unexpected: <#{name.inspect}>; attributes = #{attrs.inspect}"
    end

    def characters(_parser, string)
      #raise ParseFailureException, "Unexpected character data: #{string.inspect}"
    end

    def end_element(_parser, name)
      raise ParseFailureException, "Unexpected: </#{name.inspect}>"
    end

    def end_document(_parser)
      raise ParseFailureException, 'Unexpected end of document'
    end


    def initialize_parse(_parser)
      # by default, do nothing
    end

    def push(parser, child_combinator, can_fail)
      unless self.respond_to?(:continue)
        raise ParseFailureException, "Combinator called 'push', but does not implement 'continue': #{self.inspect}"
      end

      parser.push(child_combinator, can_fail)
    end

    def finish(parser, result)
      # return nil if there is no block; prevents work from being done unless explicit
      parser.pop(@return_result && @block ? @block.call(result) : nil)
    end

    def child_failed(_parser)
      raise ParseFailureException, "Child failed to parse, but this combinator cannot recover: #{self.inspect}"
    end


    def parse(html)
      Parser.new(self).parse(html)
    end
  end
end