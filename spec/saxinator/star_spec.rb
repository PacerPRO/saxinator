require 'spec_helper'
require './lib/saxinator/parsing'

module Saxinator
  RSpec.describe Star do
    include Parsing

    subject(:parser) {
      RET_elt('tr',
        RET_star(RET_elt('td', RET_text(/(\w+)\s*fish/))),
        RET_elt('td', RET_text(/chicken/))
      ) { |x| [x].flatten.join(' ') }
    }

    context 'no match' do
      let(:string) { '<tr><td>blue trout</td><td>goose</td></tr>' }

      it { expect { parser.parse(string) }.to raise_exception(ParseFailureException) }
    end

    context 'matched zero times' do
      let(:string) { '<tr><td>chicken</td></tr>' }

      it { expect(parser.parse(string)).to eq('chicken') }
    end

    context 'matched one time' do
      let(:string) { '<tr><td>blue fish</td><td>chicken</td></tr>' }

      it { expect(parser.parse(string)).to eq('blue chicken') }
    end

    context 'matched multiple times' do
      let(:string) { '<tr><td>red fish</td><td>blue fish</td><td>chicken</td></tr>' }

      it { expect(parser.parse(string)).to eq('red blue chicken') }
    end
  end
end