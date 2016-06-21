require 'nokogiri'

require_relative 'characters'
require_relative 'choice'
require_relative 'element'
require_relative 'optional'
require_relative 'sequence'
require_relative 'star'

module Saxinator
  module Parsing
    # non-returning elements
    def text(regex, &block)
      Characters.new(regex, &block)
    end

    def elt(tag_name, *children, &block)
      Element.new(tag_name, *children, &block)
    end

    def seq(*es, &block)
      Sequence.new(*es, &block)
    end

    def choice(e, *es, &block)
      Choice.new(e, *es, &block)
    end

    def opt(e, &block)
      Optional.new(e, &block)
    end

    def star(e, &block)
      Star.new(e, &block)
    end

    # elements returning values (use sparingly)
    def RET_text(regex, &block)
      block = proc { |match_data| match_data && (match_data[1] || match_data[0]) } unless block_given?
      Characters.new(regex, return_result: true, &block)
    end

    def RET_elt(tag_name, *children, &block)
      block = :itself unless block_given?
      Element.new(tag_name, *children, return_result: true, &block)
    end

    def RET_seq(*es, &block)
      block = :itself unless block_given?
      Sequence.new(*es, return_result: true, &block)
    end

    def RET_choice(e, *es, &block)
      block = :itself unless block_given?
      Choice.new(e, *es, return_result: true, &block)
    end

    def RET_opt(e, &block)
      block = :itself unless block_given?
      Optional.new(e, return_result: true, &block)
    end

    def RET_star(e, &block)
      block = :itself unless block_given?
      Star.new(e, return_result: true, &block)
    end
  end
end