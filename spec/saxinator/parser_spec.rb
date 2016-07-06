require 'spec_helper'
require './lib/saxinator/parser'

module Saxinator
  RSpec.describe Parser do
    context 'no block is supplied on creation' do
      it 'raises an error' do
        expect { described_class.new }.to raise_error(InvalidParserError)
      end
    end

    # TODO: test with empty block ...
    # TODO: create combinators ...
    # TODO: test string and io both ...
    context 'a single #text combinator is given' do
      context 'with no pattern' do
        subject(:parser) {
          described_class.new do
            text
          end
        }

        it 'raises exception on start tag' do
          expect { subject.parse('<table>') }.to raise_error(ParseFailureError)
        end

        it 'raises exception on end tag' do
          expect { subject.parse('</table>') }.to raise_error(ParseFailureNokogiriError)
        end

        it 'parses arbitrary text' do
          expect(subject.parse('some arbitrary text')).to be_nil
        end
      end

      context 'with string as pattern' do
        subject(:parser) {
          described_class.new do
            text 'hello'
          end
        }

        it 'raises exception on any other text' do
          expect { subject.parse('chicken') }.to raise_error(ParseFailureError)
          expect { subject.parse('Hello') }.to raise_error(ParseFailureError)
        end

        it 'parses given text' do
          expect(subject.parse('hello')).to be_nil
        end
      end

      context 'with regex as pattern' do
        subject(:parser) {
          described_class.new do
            text /^the \w+ is \w+$/
          end
        }

        it 'raises exception on non-matching text' do
          expect { subject.parse('chicken') }.to raise_error(ParseFailureError)
          expect { subject.parse('the table is kind of brown') }.to raise_error(ParseFailureError)
        end

        it 'parses matching text' do
          expect(subject.parse('the table is brown')).to be_nil
        end
      end
    end

    context 'a single element combinator is given' do
      subject(:parser) {
        described_class.new do
          tag 'td'
        end
      }

      it 'raises exception on arbitrary text' do
        expect { subject.parse('some arbitrary text') }.to raise_error(ParseFailureError)
      end

      it 'raises exception on tag with wrong name' do
        expect { subject.parse('<table></table>') }.to raise_error(ParseFailureError)
      end

      it 'raises exception on end tag' do
        expect { subject.parse('</td>') }.to raise_error(ParseFailureNokogiriError)
      end

      it 'parses element with empty body' do
        expect(subject.parse('<td></td>')).to be_nil
      end

      # TODO: test attribute patterns ...
    end
  end
end
