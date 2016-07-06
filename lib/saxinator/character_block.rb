require_relative 'combinator'

module Saxinator
  class CharacterBlock < ::Saxinator::Combinator
    def initialize(return_result: true, &block)
      super
    end


    def characters(state_machine, string)
      finish(state_machine, string) unless string.empty?
    end
  end
end