module Saxinator
  class ParserBase
    def initialize(wrapper_klass=Sequence, &block)
      raise InvalidParserError, "Invalid #{name}; please supply a block" unless block_given?
      @wrapper_klass = wrapper_klass
      build_root(&block)
    end

    def parse(html)
      begin
        inner_parse(html)
      rescue Nokogiri::XML::SyntaxError => e
        raise ParseFailureNokogiriError, e.message
      rescue ParseFailureException => e
        raise ParseFailureError, e.message
      end
    end


    protected

    def root
      @root
    end


    private

    def name
      'parser'
    end

    # TODO: add delegation - see http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation ...
    def build_root(&block)
      @stack = []
      self.instance_eval(&block)

      build_root_from_stack
    end

    def build_root_from_stack
      case @stack.length
      when 0
        raise InvalidParserError, 'Invalid parser; the supplied block is empty'
      when 1
        @root = @stack.first
      else
        # TODO: don't always require returning result ...
        @root = @wrapper_klass.new(*@stack, return_result: true, f: ->(x) { x })
      end
    end

    def inner_parse(html)
      r = @root.parse(html)
      r ? r.inner_value : nil
    end
  end
end