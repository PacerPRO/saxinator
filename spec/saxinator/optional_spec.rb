require 'spec_helper'
require './lib/saxinator/parsing'

module Saxinator
  RSpec.describe Optional do
    include Parsing

    subject(:state_machine) {
      RET_elt('tr',
        RET_elt('td', RET_text(/Hi/)),
        RET_opt(RET_elt('td', RET_text(/t(here)/))),
        RET_elt('td', RET_text(/friend/))
      ) { |x| [x].flatten.join(' ') }
    }

    context 'optional element is matched' do
      let(:string) { '<tr><td>Hi</td><td>there</td><td>friend</td></tr>' }

      it 'parses and returns the value if set up to do so' do
        expect(state_machine.parse(string)).to eq('Hi here friend')
      end
    end

    context 'optional element is not matched' do
      let(:string) { '<tr><td>Hi</td><td>friend</td></tr>' }

      it 'parses' do
        expect(state_machine.parse(string)).to eq('Hi friend')
      end
    end
  end
end