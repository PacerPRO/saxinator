require 'spec_helper'
require './lib/saxinator/parsing'

module Saxinator
  RSpec.describe Sequence do
    include Parsing

    subject(:state_machine) {
      RET_seq(
        RET_elt('td', RET_text('hi')),
        RET_elt('td', RET_text('there'))
      ) { |x| x.join(' ') }
    }

    context 'empty string' do
      let(:string) { '' }

      it { expect { state_machine.parse(string) }.to raise_exception(ParseFailureException) }
    end

    context 'first element not matched' do
      let(:string) { '<td>hey</td><td>there</td>' }

      it { expect { state_machine.parse(string) }.to raise_exception(ParseFailureException) }
    end

    context 'second element not matched' do
      let(:string) { '<td>hi</td><td>Steve</td>' }

      it { expect { state_machine.parse(string) }.to raise_exception(ParseFailureException) }
    end

    context 'match' do
      let(:string) { '<td>hi</td><td>there</td>' }

      it { expect(state_machine.parse(string)).to eq('hi there') }
    end

    context 'matching 0 elements' do
      subject(:state_machine) { seq() }

      context 'empty string' do
        let(:string) { '' }

        it { expect(state_machine.parse(string)).to eq(nil) }
      end

      context 'non-empty string' do
        let(:string) { '<td></td>' }

        it { expect { state_machine.parse(string) }.to raise_exception(ParseFailureException) }
      end
    end
  end
end