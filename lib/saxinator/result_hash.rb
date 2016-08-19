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
        when ResultHash
          base_value.inner_value
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

    def self.sum(result_hashes)
      result_hashes.length > 0 ? result_hashes.reduce(:+) : ResultHash.new(nil)
    end

    private

    def self.from_inner_value(inner_value)
      r = ResultHash(nil)
      r.instance_eval { @inner_value = inner_value }

      r
    end
  end
end

# ...
# TODO: any way to somehow put this in the Saxinator module but still be able to call it without using fully
#       qualified name?
def ResultHash(base_value)
  base_value.is_a?(::Saxinator::ResultHash) ? base_value : ::Saxinator::ResultHash.new(base_value)
end