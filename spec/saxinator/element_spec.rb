require 'spec_helper'
require './lib/saxinator/parsing'

module Saxinator
  RSpec.describe Element do
    include Parsing

    let(:tag_name)    { 'table'           }
    subject(:element) { RET_elt(tag_name) }

    context 'parsing fails' do
      it 'raises exception on start tag of wrong type' do
        expect { subject.parse('<tbody>') }.to raise_exception(ParseFailureException)
      end

      it 'raises exception on characters' do
        expect { subject.parse('Hello there') }.to raise_exception(ParseFailureException)
      end

      it 'raises exception on end tag of wrong type' do
        expect { subject.parse('</tbody>') }.to raise_exception(Nokogiri::XML::SyntaxError)
      end
    end

    context 'parsing succeeds' do
      let(:string) { '<table width="90%" height="100%"></table>' }

      it 'does not raise an exception' do
        expect { subject.parse(string) }.not_to raise_exception
      end

      context 'a block was provided' do
        it 'passes child result to the provided block' do
          r = false

          element = RET_elt(tag_name) { |child_result| r = child_result }
          element.parse(string)

          # child result defaults to nil (since we provided no child combinator)
          expect(r).to be_nil
        end
      end

      context 'it has a child state machine' do
        let(:tag_name) { 'td'                              }
        let(:string)   { '<td>I have a brown chicken</td>' }

        it 'also passes result of child parse to the provided block' do
          r_child = nil
          r       = nil

          child_combinator = RET_text(/(\w+)\s+chicken/) do |match_data|
            r_child = match_data[1]
          end

          element = RET_elt(tag_name, child_combinator) do |child_result|
            r = "I have a #{child_result} turkey"
          end

          element.parse(string)

          expect(r_child).to eq('brown')
          expect(r).to eq('I have a brown turkey')
        end
      end

      context 'it has multiple child state machines' do
        let(:string) { '<td><b>Hello</b>. I have a brown chicken</td>' }

        it 'passes results of child parses to the provided block, ignoring nils' do
          r = nil

          element =
            RET_elt('td',
              elt('b', text(/Hello/)),
              RET_text(/(\w+)\s+chicken/) { |x| x[1] }
            ) { |x| r = "I have a #{x.first} turkey"; x.first }

          expect(element.parse(string)).to eq('brown')
          expect(r).to eq('I have a brown turkey')
        end
      end
    end
  end
end