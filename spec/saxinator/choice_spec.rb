require 'spec_helper'
require './lib/saxinator/parsing'

module Saxinator
  RSpec.describe Choice do
    include Parsing

    subject(:parser) { RET_choice(RET_text('hi'), RET_text('hello'), RET_text('hey')) }

    context 'first choice is taken' do
      let(:string) { 'hi' }

      it { expect(parser.parse(string)).to eq('hi') }
    end

    context 'a later choice is taken' do
      let(:string) { 'hey' }

      it { expect(parser.parse(string)).to eq('hey') }
    end

    context 'all choices fail' do
      let(:string) { 'hola' }

      it { expect { parser.parse(string) }.to raise_exception(ParseFailureException) }
    end
  end
end