# TODO: comment this file ...
module Saxinator
  # ...
  class ResultHash
    attr_reader :inner_value

    # ...
    def initialize(base_value)
      @inner_value =
        case base_value
        when nil
          { values: [] }
        when Array
          { values: base_value }
        when Hash
          { values: [] }.merge(base_value)
        else
          { values: [base_value] }
        end
    end

    # ...
    def +(other)
      values_result = self.inner_value[:values] + other.inner_value[:values]
      r = self.inner_value.merge(other.inner_value).merge({ values: values_result })

      self.class.from_inner_value(r)
    end

    private

    def self.from_inner_value(inner_value)
      r = ResultHash.new(nil)
      r.instance_eval { @inner_value = inner_value }

      r
    end
  end
end