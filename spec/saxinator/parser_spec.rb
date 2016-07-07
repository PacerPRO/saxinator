require 'spec_helper'
require './lib/saxinator/parser'

module Saxinator
  RSpec.describe Parser do
    context 'no block is supplied on creation' do
      it 'raises an error' do
        expect { described_class.new }.to raise_error(InvalidParserError)
      end
    end

    context 'an empty block is supplied on creation' do
      it 'raises an error' do
        expect {
          described_class.new do
            # empty block
          end
        }.to raise_error(InvalidParserError)
      end
    end

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
        expect { subject.parse('</td>') }.to raise_error(ParseFailureError)
      end

      it 'parses element with empty body' do
        expect(subject.parse('<td></td>')).to be_nil
      end

      # TODO: test attribute patterns, non-empty blocks ...
    end

    context 'two combinators are given' do
      subject(:parser) {
        described_class.new do
          text 'hello'
          tag 'td'
        end
      }

      it 'raises exception on non-matching content' do
        expect { subject.parse('chicken') }.to raise_error(ParseFailureError)
        expect { subject.parse('hello <tr></tr>') }.to raise_error(ParseFailureError)
        expect { subject.parse('hi <td></td>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<td></td> hello') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect(subject.parse('hello <td></td>')).to be_nil
      end
    end

    context 'combinators are nested' do
      subject(:parser) {
        described_class.new do
          tag 'b' do
            text 'hello'
          end
        end
      }

      it 'raises exception on non-matching content' do
        expect { subject.parse('hello') }.to raise_error(ParseFailureError)
        expect { subject.parse('<b>goodbye</b>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<td>hello</td>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<b>hello</td>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<b><b>hello</b></b>') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect(subject.parse('<b>hello</b>')).to be_nil
      end
    end

    context 'combinators are nested (complex example)' do
      subject(:parser) {
        described_class.new do
          tag 'tr' do
            tag 'td' do
              text 'hello'
            end
            tag 'td' do
              text 'goodbye'
            end
          end
        end
      }

      it 'raises exception on non-matching content' do
        expect { subject.parse('<tr><td>hello</td><td>there</td></tr>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<tr><td>hello</td></tr>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<tr><b>hello</b><b>goodbye</b></tr>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<table><td>hello</td><td>goodbye</td></table>') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect(subject.parse('<tr><td>hello</td><td>goodbye</td></tr>')).to be_nil
      end
    end
  end
end
