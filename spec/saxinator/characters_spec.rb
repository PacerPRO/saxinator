require 'spec_helper'
require './lib/saxinator/parsing'

module Saxinator
  RSpec.describe Characters do
    include Parsing

    let(:regex)          { /(\w+)\s+chicken/ }
    subject(:characters) { RET_text(regex)   }

    context 'parsing fails' do
      it 'raises exception on start tag' do
        expect { subject.parse('<table>') }.to raise_exception(ParseFailureException)
      end

      it 'raises exception on end tag' do
        expect { subject.parse('</table>') }.to raise_exception(Nokogiri::XML::SyntaxError)
      end

      it 'raises exception if characters do not match regex' do
        expect { subject.parse('I have a turkey') }.to raise_exception(ParseFailureException)
      end
    end

    context 'parsing succeeds' do
      let(:string) { 'I have a brown chicken' }

      it 'does not raise an exception' do
        expect { subject.parse(string) }.not_to raise_exception
      end

      context 'a block was provided' do
        it 'passes match data to the provided block' do
          r = nil

          characters = RET_text(regex) { |match_data| r = match_data[1] }
          characters.parse(string)

          expect(r).to eq('brown')
        end
      end
    end

    context 'very large blob of text' do
      let(:regex)  { 'The End' }
      let(:string) {
        <<-HTML
        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor
        incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
        exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute
        irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.

        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor
        incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
        exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute
        irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.

        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor
        incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
        exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute
        irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.

        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor
        incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
        exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute
        irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.

        The End
        HTML
      }

      it 'works' do
        # make sure it get the text all the way up to the last word
        expect(subject.parse(string)).to eq('The End')
      end
    end
  end
end