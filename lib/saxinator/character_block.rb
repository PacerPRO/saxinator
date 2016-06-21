require_relative 'combinator'

module Saxinator
  class CharacterBlock < ::Saxinator::Combinator
    def initialize(return_result: true, &block)
      super
    end


    def characters(parser, string)
      finish(parser, string) unless string.empty?
    end
  end
end