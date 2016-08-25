require 'spec_helper'
require './lib/saxinator/parser'

module Saxinator
  RSpec.describe Parser do
    # TODO?: combinators should allow lambdas taking 0 args ...
    # TODO: *explicitly* test single-argument lambda support for 'tag' combinator ...

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
        subject {
          described_class.new do
            text
          end
        }

        it 'raises an error on start tag' do
          expect { subject.parse('<table>') }.to raise_error(ParseFailureError)
        end

        it 'raises an error on end tag' do
          expect { subject.parse('</table>') }.to raise_error(ParseFailureError)
        end

        it 'parses arbitrary text' do
          expect { subject.parse('some arbitrary text') }.not_to raise_exception
        end
      end

      context 'with string as pattern' do
        subject {
          described_class.new do
            text 'hello'
          end
        }

        it 'raises an error on any other text' do
          expect { subject.parse('chicken') }.to raise_error(ParseFailureError)
          expect { subject.parse('Hello') }.to raise_error(ParseFailureError)
        end

        it 'parses given text' do
          expect { subject.parse('hello') }.not_to raise_exception
        end
      end

      context 'with regex as pattern' do
        subject {
          described_class.new do
            text /^the \w+ is \w+$/
          end
        }

        it 'raises an error on non-matching text' do
          expect { subject.parse('chicken') }.to raise_error(ParseFailureError)
          expect { subject.parse('the table is kind of brown') }.to raise_error(ParseFailureError)
        end

        it 'parses matching text' do
          expect { subject.parse('the table is brown') }.not_to raise_exception
        end
      end

      context 'with a lambda' do
        subject {
          described_class.new do
            text /my favorite color is (\w+)/, -> (matches) { matches[1] }
          end
        }

        it 'returns the expected result' do
          expect(subject.parse('my favorite color is green')).to eq({ values: ['green'] })
        end
      end

      context 'with a lambda returning an array of results' do
        subject {
          described_class.new do
            text /my favorite colors are (\w+) and (\w+)/, -> (matches) { matches.to_a.drop(1) }
          end
        }

        it 'returns the expected result' do
          expect(subject.parse('my favorite colors are red and blue')).to eq({ values: ['red', 'blue'] })
        end
      end
    end

    context 'multiple #text combinators are given' do
      subject {
        described_class.new do
          text(/my favorite color is (\w+), whereas/)
          text(/ your favorite color is (\w+)/)
        end
      }

      # TODO: test parse failure ...

      it 'succeeds on valid content' do
        expect(subject.parse(<<-HTML)).to eq({ values: %w(blue green) })
          my favorite color is blue, whereas your favorite color is green
        HTML
      end

      # TODO: test combinations of modifiers (e.g. 'i' is on one of the patterns but not the other)
      # TODO: test distinct functions on the #text combinators ...
    end


    context 'a single element combinator is given' do
      subject {
        described_class.new do
          tag 'td'
        end
      }

      it 'raises an error on arbitrary text' do
        expect { subject.parse('some arbitrary text') }.to raise_error(ParseFailureError)
      end

      it 'raises an error on tag with wrong name' do
        expect { subject.parse('<table></table>') }.to raise_error(ParseFailureError)
      end

      it 'raises an error on end tag' do
        expect { subject.parse('</td>') }.to raise_error(ParseFailureError)
      end

      it 'parses element with empty body' do
        expect { subject.parse('<td></td>') }.not_to raise_exception
      end

      # TODO: allow tag_name patterns as well, and pass in tag_name to provided lambda ...
      # TODO: test attribute patterns ...

      context 'with a lambda' do
        subject {
          described_class.new do
            tag 'td', -> (_value, attrs) { attrs }
          end
        }

        it 'returns the expected result' do
          expect(subject.parse('<td width=500 height=200></td>')).to eq(
            { 'width' => '500', 'height' => '200', values: [] }
          )
        end
      end

      # TODO: with a lambda and also child results ...
    end

    context 'two combinators are given' do
      subject {
        described_class.new do
          text 'hello'
          tag 'td'
        end
      }

      it 'raises an error on non-matching content' do
        expect { subject.parse('chicken') }.to raise_error(ParseFailureError)
        expect { subject.parse('hello <tr></tr>') }.to raise_error(ParseFailureError)
        expect { subject.parse('hi <td></td>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<td></td> hello') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect { subject.parse('hello <td></td>') }.not_to raise_exception
      end

      context 'lambdas are given' do
        subject {
          described_class.new do
            text 'hello', -> (matches)       { matches[0]     }
            tag 'td',     -> (_value, attrs) { attrs['width'] }
          end
        }

        it 'returns the expected result' do
          expect(subject.parse('hello <td width="400"></td>')).to eq({ values: %w(hello 400) })
        end
      end
    end

    context 'combinators are nested' do
      subject {
        described_class.new do
          tag 'b' do
            text 'hello'
          end
        end
      }

      it 'raises an error on non-matching content' do
        expect { subject.parse('hello') }.to raise_error(ParseFailureError)
        expect { subject.parse('<b>goodbye</b>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<td>hello</td>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<b>hello</td>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<b><b>hello</b></b>') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect { subject.parse('<b>hello</b>') }.not_to raise_exception
      end

      context 'a lambda is given' do
        subject {
          described_class.new do
            tag 'b', -> (value) { value } do
              text 'hello', -> (matches) { matches[0] }
            end
          end
        }

        it 'returns the expected result' do
          expect(subject.parse('<b>hello</b>')).to eq({ values: ['hello'] })
        end
      end
    end

    context 'combinators are nested (complex example)' do
      subject {
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

      it 'raises an error on non-matching content' do
        expect { subject.parse('<tr><td>hello</td><td>there</td></tr>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<tr><td>hello</td></tr>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<tr><b>hello</b><b>goodbye</b></tr>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<table><td>hello</td><td>goodbye</td></table>') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect { subject.parse('<tr><td>hello</td><td>goodbye</td></tr>') }.not_to raise_exception
      end

      context 'lambdas are given' do
        subject {
          described_class.new do
            tag 'tr', -> (result, attrs) { result.merge(attrs) } do
              tag 'td' do
                text 'hello', -> (matches) { matches[0] }
              end
              tag 'td' do
                text 'goodbye', -> (matches) { matches[0] }
              end
            end
          end
        }

        it 'returns the expected result' do
          expect(subject.parse(<<-HTML)).to eq({ 'width' => '100', 'height' => '200', values: %w(hello goodbye) })
            <tr width="100" height="200">
              <td>hello</td>
              <td>goodbye</td>
            </tr>
          HTML
        end
      end
    end

    # TODO: recognize text, optional, text
    # TODO:   (really, just need to recognize text, text) ...
    #         once this is done, get rid of all of the extraneous tag('b', ...) wrappers in the tests ...

    # TODO: allow for a range, e.g. range(1, 5)
    context 'an #optional combinator is given' do
      subject {
        described_class.new do
          tag('b') { text 'hello' }
          optional do
            tag('b') { text 'there' }
          end
          tag('b') { text 'friend' }
        end
      }

      context 'no block is given' do
        it 'raises an error' do
          expect {
            described_class.new do
              optional
            end
          }.to raise_error(InvalidParserError)
        end
      end

      it 'raises an error on non-matching content' do
        expect { subject.parse('<b>hello</b><td>there</td><b>friend</b>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<b>hello</b><b>there</b><b>there</b><b>friend</b') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect { subject.parse('<b>hello</b><b>there</b><b>friend</b>') }.not_to raise_exception
        expect { subject.parse('<b>hello</b><b>friend</b>') }.not_to raise_exception
      end

      context 'there are multiple combinators underneath the #optional combinator' do
        subject {
          described_class.new do
            tag('b') { text 'hello' }
            optional do
              tag('b') { text 'there' }
              tag('b') { text 'my' }
            end
            tag('b') { text 'friend' }
          end
        }

        it 'raises an error on non-matching content' do
          expect { subject.parse('<b>hello</b><b>there</b><b>friend</b>') }.to raise_error(ParseFailureError)
        end

        it 'parses matching content' do
          expect { subject.parse('<b>hello</b><b>there</b><b>my</b><b>friend</b>') }.not_to raise_exception
          expect { subject.parse('<b>hello</b><b>friend</b>') }.not_to raise_exception
        end
      end

      context 'a lambda is given' do
        RSpec.shared_examples '#optional: a lambda is given' do |f|
          subject {
            described_class.new do
              tag('b') { text 'hello', -> (_) { 'not me' } }
              optional f do
                tag('b') { text 'there', -> (_) { 'here I am!' } }
              end
              tag('b') { text 'friend', -> (_) { 'not me either' } }
            end
          }

          it 'returns the expected result' do
            expect(subject.parse('<b>hello</b><b>there</b><b>friend</b>')).to eq(
              { values: ['not me', 'here I am!', 'not me either'] }
            )

            expect(subject.parse('<b>hello</b><b>friend</b>')).to eq({ values: ['not me', 'not me either'] })
          end
        end
      end

      # test with and without lambda argument
      include_examples '#optional: a lambda is given', -> (result) { result }
      include_examples '#optional: a lambda is given', nil
    end

    context 'a #star combinator is given' do
      subject {
        described_class.new do
          tag('b') { text 'hello' }
          star do
            tag('b') { text 'there' }
          end
          tag('b') { text 'friend' }
        end
      }

      context 'no block is given' do
        it 'raises an error' do
          expect {
            described_class.new do
              star
            end
          }.to raise_error(InvalidParserError)
        end
      end

      it 'raises an error on non-matching content' do
        expect { subject.parse('<b>hello</b><td>there</td><b>friend</b>') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect { subject.parse('<b>hello</b><b>there</b><b>there</b><b>friend</b>') }.not_to raise_exception
        expect { subject.parse('<b>hello</b><b>there</b><b>friend</b>') }.not_to raise_exception
        expect { subject.parse('<b>hello</b><b>friend</b>') }.not_to raise_exception
      end

      context 'there are multiple combinators underneath the #star combinator' do
        subject {
          described_class.new do
            tag('b') { text 'hello' }
            star do
              tag('b') { text 'there' }
              tag('b') { text 'my' }
            end
            tag('b') { text 'friend' }
          end
        }

        it 'raises an error on non-matching content' do
          expect { subject.parse('<b>hello</b><b>there</b><b>friend</b>') }.to raise_error(ParseFailureError)
        end

        it 'parses matching content' do
          expect {
            subject.parse('<b>hello</b><b>there</b><b>my</b><b>there</b><b>my</b><b>friend</b>')
          }.not_to raise_exception
          expect { subject.parse('<b>hello</b><b>there</b><b>my</b><b>friend</b>') }.not_to raise_exception
          expect { subject.parse('<b>hello</b><b>friend</b>') }.not_to raise_exception
        end
      end

      context 'a lambda is given' do
        RSpec.shared_examples '#star: a lambda is given' do |f|
          subject {
            described_class.new do
              tag('b') { text 'hello' }
              star f do
                tag('b') { text 'there', -> (_) { 'found me!' } }
              end
              tag('b') { text 'friend' }
            end
          }

          it 'returns the expected result' do
            expect(subject.parse('<b>hello</b><b>there</b><b>there</b><b>friend</b>')).to eq(
              { values: ['found me!', 'found me!'] }
            )
            expect(subject.parse('<b>hello</b><b>there</b><b>friend</b>')).to eq({ values: ['found me!'] })
            expect(subject.parse('<b>hello</b><b>friend</b>')).to eq({ values: [] })
          end
        end

        # test with and without lambda argument
        include_examples '#star: a lambda is given', -> (result) { result }
        include_examples '#star: a lambda is given', nil
      end
    end

    context 'an #any combinator is given' do
      subject {
        described_class.new do
          tag('b') { text 'hello' }
          tag('b') do
            any do
              try { text 'there' }
              try { text 'my'    }
            end
          end
          tag('b') { text 'friend' }
        end
      }

      context 'no block is given' do
        it 'raises an error' do
          expect {
            described_class.new do
              any
            end
          }.to raise_error(InvalidParserError)
        end
      end

      # TODO: what if no "try" sections are given?

      it 'raises an error on non-matching content' do
        expect { subject.parse('<b>hello</b><b>best</b><b>friend</b>') }.to raise_error(ParseFailureError)
        expect { subject.parse('<b>hello</b><b>friend</b>') }.to raise_error(ParseFailureError)
      end

      it 'parses matching content' do
        expect { subject.parse('<b>hello</b><b>there</b><b>friend</b>') }.not_to raise_exception
        expect { subject.parse('<b>hello</b><b>my</b><b>friend</b>') }.not_to raise_exception
      end

      context 'a lambda is given' do
        RSpec.shared_examples '#any: a lambda is given' do |f|
          # TODO: clean up when 'text' returns nil when no lambda given ...
          subject {
            described_class.new do
              tag('b') { text 'hello' }
              tag('b') do
                any f do
                  try { text 'there', -> (matches)  { matches[0] } }
                  try -> (result) { "oh #{result[:values].first}" } do
                    text 'my', -> (matches) { matches[0] }
                  end
                end
              end
              tag('b') { text 'friend' }
            end
          }

          it 'returns the expected result' do
            expect(subject.parse('<b>hello</b><b>there</b><b>friend</b>')).to eq({ values: ['there'] })
            expect(subject.parse('<b>hello</b><b>my</b><b>friend</b>')).to eq({ values: ['oh my'] })
          end
        end

        # test with and without lambda argument
        include_examples '#any: a lambda is given', -> (result) { result }
        include_examples '#any: a lambda is given', nil
      end

      # TODO ...
    end

    context 'default return results' do
      describe '#text' do
        context 'there are no capture groups' do
          subject {
            described_class.new do
              text 'hello'
            end
          }

          it 'returns "nil" result' do
            expect(subject.parse('hello')).to eq({ values: [] })
          end
        end

        context 'there are capture groups' do
          subject {
            described_class.new do
              text /hello (\w+) and (\w+)/
            end
          }

          it 'returns captured results' do
            expect(subject.parse('hello Steve and Jane')).to eq({ values: %w(Steve Jane) })
          end
        end
      end

      describe '#element' do
        subject {
          described_class.new do
            tag 'td' do
              tag('b', -> (result) { result }) { text 'hi',    -> (matches) { matches[0] } }
              tag('b', -> (result) { result }) { text 'there', -> (matches) { matches[0] } }
            end
          end
        }

        it 'returns results of parsing child elements' do
          expect(subject.parse('<td><b>hi</b><b>there</b></td>')).to eq({ values: %w(hi there) })
        end
      end

      describe '#optional' do
        subject {
          described_class.new do
            optional do
              tag('b', -> (result) { result }) { text 'hi', -> (matches) { matches[0] } }
            end
          end
        }

        it 'if the optional element is present, returns results of parsing the optional element' do
          expect(subject.parse('<b>hi</b>')).to eq({ values: ['hi'] })
        end

        it 'if the optional element is absent, returns "nil"' do
          expect(subject.parse('')).to eq({ values: [] })
        end
      end

      describe '#star' do
        subject {
          described_class.new do
            star do
              tag('b', -> (result) { result }) { text 'hi', -> (matches) { matches[0] } }
            end
          end
        }

        it 'returns results of parsing the child elements' do
          expect(subject.parse('<b>hi</b><b>hi</b><b>hi</b><b>hi</b>')).to eq({ values: %w(hi hi hi hi) })
        end
      end

      describe '#any' do
        subject {
          described_class.new do
            any do
              try(-> (result) { result }) {
                tag('b', -> (result) { result }) { text 'first',  -> (matches) { matches[0] } }
              }
              try(-> (result) { result }) {
                tag('b', -> (result) { result }) { text 'second', -> (matches) { matches[0] } }
              }
            end
          end
        }

        it 'returns results of the successfully parsed "try" section' do
          expect(subject.parse('<b>first</b>')).to  eq({ values: ['first']  })
          expect(subject.parse('<b>second</b>')).to eq({ values: ['second'] })
        end
      end
    end

    # TODO: #try, in separate spec for the "#any" parser ...
  end
end
