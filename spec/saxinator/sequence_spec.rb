require 'spec_helper'
require './lib/saxinator/parsing'

module Saxinator
  RSpec.describe Sequence do
    include Parsing

    subject(:parser) {
      RET_seq(
        RET_elt('td', RET_text('hi')),
        RET_elt('td', RET_text('there'))
      ) { |x| x.join(' ') }
    }

    context 'empty string' do
      let(:string) { '' }

      it { expect { parser.parse(string) }.to raise_exception(ParseFailureException) }
    end

    context 'first element not matched' do
      let(:string) { '<td>hey</td><td>there</td>' }

      it { expect { parser.parse(string) }.to raise_exception(ParseFailureException) }
    end

    context 'second element not matched' do
      let(:string) { '<td>hi</td><td>Steve</td>' }

      it { expect { parser.parse(string) }.to raise_exception(ParseFailureException) }
    end

    context 'match' do
      let(:string) { '<td>hi</td><td>there</td>' }

      it { expect(parser.parse(string)).to eq('hi there') }
    end

    context 'matching 0 elements' do
      subject(:parser) { seq() }

      context 'empty string' do
        let(:string) { '' }

        it { expect(parser.parse(string)).to eq(nil) }
      end

      context 'non-empty string' do
        let(:string) { '<td></td>' }

        it { expect { parser.parse(string) }.to raise_exception(ParseFailureException) }
      end
    end
  end
end