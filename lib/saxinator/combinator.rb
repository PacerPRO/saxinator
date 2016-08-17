require_relative 'result_hash'
require_relative 'state_machine'

module Saxinator
  class Combinator
    def initialize(*args, return_result: false, f: nil, &block)
      @args          = args
      @return_result = return_result
      @f             = f
      @block         = block
    end


    def reset
      @args.each { |arg| arg.reset if arg.is_a?(Combinator) }
      initialize(*@args, return_result: @return_result, f: @f, &@block)
    end


    def start_element(_state_machine, name, attrs = [])
      raise ParseFailureException, "Unexpected: <#{name.inspect}>; attributes = #{attrs.inspect}"
    end

    def characters(_state_machine, string)
      #raise ParseFailureException, "Unexpected character data: #{string.inspect}"
    end

    def end_element(_state_machine, name)
      raise ParseFailureException, "Unexpected: </#{name.inspect}>"
    end

    def end_document(_state_machine)
      raise ParseFailureException, 'Unexpected end of document'
    end


    def initialize_parse(_state_machine)
      # by default, do nothing
    end

    def push(state_machine, child_combinator, can_fail)
      unless self.respond_to?(:continue)
        raise ParseFailureException, "Combinator called 'push', but does not implement 'continue': #{self.inspect}"
      end

      state_machine.push(child_combinator, can_fail)
    end

    def finish(state_machine, result)
      # return nil if there is no function; prevents work from being done unless explicit
      state_machine.pop(@return_result && @f ? ResultHash.new(@f.call(result)) : nil)
    end

    def child_failed(_state_machine)
      raise ParseFailureException, "Child failed to parse, but this combinator cannot recover: #{self.inspect}"
    end


    def parse(html)
      reset
      StateMachine.new(self).parse(html)
    end
  end
end