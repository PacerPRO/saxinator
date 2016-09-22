require 'spec_helper'
require './lib/saxinator/utils'

module Saxinator
  RSpec.describe Utils do
    describe 'matching separately fails' do
      let(:patterns) { [/[\w\s]*/, /tall/] }
      let(:s)        { 'I am tall'  }

      it 'the combined pattern succeeds' do
        expect(s.match(patterns.join)).not_to be_nil
      end

      it 'sequential matching fails' do
        m = s.match(patterns[0])
        expect(m[0]).to_not be_nil

        i = m[0].length
        expect(i).to eq(s.length)

        expect(s.match(patterns[1], i)).to be_nil
      end
    end

    describe '.multimatch' do
      let(:result) { described_class.multimatch(s, patterns) }

      context 'no patterns' do
        let(:patterns) { []            }
        let(:s)        { 'some string' }

        it 'fails' do
          expect(result).to be_nil
        end
      end

      context 'single pattern' do
        let(:patterns) { [/I am (\w+) (\w+)/] }

        context 'non-matching string' do
          let(:s) { 'There is a dog over there' }

          it { expect(result).to be_nil }
        end

        context 'matching string' do
          let(:s) { 'I am very tall' }

          it do
            expect(result).to match([MatchData])

            expect(result[0].length).to eq(3)
            expect(result[0][1]).to eq('very')
            expect(result[0][2]).to eq('tall')
          end
        end
      end

      context 'multiple patterns' do
        let(:patterns) { [
          /I am (?<a>\w+)/,
          / (?<b>\w+) /,
          /for a (\w+)/
        ] }

        # TODO: failure ...

        context 'matching string' do
          let(:s) { 'I am very slow for a cheetah' }

          it do
            expect(result).to match([MatchData, MatchData, MatchData])

            expect(result[0].length).to eq(2)
            expect(result[0][1]).to eq('very')

            expect(result[1].length).to eq(2)
            expect(result[1][1]).to eq('slow')

            expect(result[2].length).to eq(2)
            expect(result[2][1]).to eq('cheetah')
          end
        end

        # TODO: complex example ...
      end
    end

    describe '.delimited_match' do
      let(:patterns) { [
        /(?<a>\w+) is (?<b>\w+)/,
        / (?<b>\w+) /,
        /for a (\w+) (\w+) from/,
        / (\w+), (\w+)/
      ] }
      let(:s)        { 'John is very slow for a purple cheetah from Madrid, Spain' }
      let(:matches)  { described_class.delimited_match(s, patterns)                }
      let(:results)  { matches.names.zip(matches.to_a.drop(1))                     }

      it do
        expect(matches).to match(MatchData)

        expect(results.length).to eq(11)

        expect(matches[0]).to  eq(          'John is very slow for a purple cheetah from Madrid, Spain' )
        expect(results[0]).to  eq(['__0',   'John is very'                                             ])
        expect(results[1]).to  eq(['_0-a',  'John'                                                     ])
        expect(results[2]).to  eq(['_0-b',  'very'                                                     ])
        expect(results[3]).to  eq(['__1',   ' slow '                                                   ])
        expect(results[4]).to  eq(['_1-b',  'slow'                                                     ])
        expect(results[5]).to  eq(['__2',   'for a purple cheetah from'                                ])
        expect(results[6]).to  eq(['_2-_0', 'purple'                                                   ])
        expect(results[7]).to  eq(['_2-_1', 'cheetah'                                                  ])
        expect(results[8]).to  eq(['__3',   ' Madrid, Spain'                                           ])
        expect(results[9]).to  eq(['_3-_0', 'Madrid'                                                   ])
        expect(results[10]).to eq(['_3-_1', 'Spain'                                                    ])
      end
    end

    describe '.get_combined_pattern' do
      let(:result)   { described_class.get_combined_pattern(patterns) }
      let(:patterns) { [
        'my (\w+) is (?<name>\w+) under a (\w+)',
        '(?<sentence>my ((?<trait>\w+) (?<verb>\w+) (\w+)))',
        'and my bird is (\w+)'
      ] }

      it do
        expect(result).to eq(
          '(?-mix:(?<__0>my (?<_0-_0>\w+) is (?<_0-name>\w+) under a (?<_0-_1>\w+)))'\
          '(?-mix:(?<__1>(?<_1-sentence>my (?<_1-_0>(?<_1-trait>\w+) (?<_1-verb>\w+) (?<_1-_1>\w+)))))'\
          '(?-mix:(?<__2>and my bird is (?<_2-_0>\w+)))'
        )
      end
    end

    describe '.rename_all_groups' do
      let(:result) { described_class.rename_all_groups(patterns) }

      context do
        let(:patterns) { [
          'my (\w+) is (?<name>\w+) under a (\w+)',
          '(?<sentence>my ((?<trait>\w+) (?<verb>\w+) (\w+)))',
          'and my bird is (\w+)'
        ] }

        it do
          expect(result).to eq([
            'my (?<_0-_0>\w+) is (?<_0-name>\w+) under a (?<_0-_1>\w+)',
            '(?<_1-sentence>my (?<_1-_0>(?<_1-trait>\w+) (?<_1-verb>\w+) (?<_1-_1>\w+)))',
            'and my bird is (?<_2-_0>\w+)'
          ])
        end
      end
    end

    # TODO: support and preserver patterns like (?-mix ...
    describe '.rename_groups' do
      let(:result) { described_class.rename_groups(pattern, index) }
      let(:index)  { 0                                             }

      context 'no un-named groups' do
        let(:pattern) { 'my name is (?<name>\w+)' }

        it 'returns the original pattern with index as prefix' do
          expect(result).to eq('my name is (?<_0-name>\w+)')
        end

        context 'non-zero index' do
          let(:index) { 5 }

          it 'returns the original pattern with index as prefix' do
            expect(result).to eq('my name is (?<_5-name>\w+)')
          end
        end
      end

      context 'only un-named groups' do
        let(:pattern) { 'my (\w+) is (\w+)' }

        it 'names the groups' do
          expect(result).to eq('my (?<_0-_0>\w+) is (?<_0-_1>\w+)')
        end
      end

      context 'mix of un-named and named groups' do
        let(:pattern) { 'my (?<trait>\w+) is (\w+)' }

        it 'names the un-named groups only' do
          expect(result).to eq('my (?<_0-trait>\w+) is (?<_0-_0>\w+)')
        end
      end

      context 'mix of un-named and named groups, with nesting' do
        let(:pattern) { '(?<sentence>my ((?<trait>\w+) (?<verb>\w+) (\w+)))' }

        it 'names the un-named groups only' do
          expect(result).to eq('(?<_0-sentence>my (?<_0-_0>(?<_0-trait>\w+) (?<_0-verb>\w+) (?<_0-_1>\w+)))')
        end
      end

      context 'using a non-zero index' do
        let(:result)  { described_class.rename_groups(pattern, 3)            }
        let(:pattern) { '(?<sentence>my ((?<trait>\w+) (?<verb>\w+) (\w+)))' }

        it 'names the un-named groups only' do
          expect(result).to eq('(?<_3-sentence>my (?<_3-_0>(?<_3-trait>\w+) (?<_3-verb>\w+) (?<_3-_1>\w+)))')
        end
      end

      context 'pattern has exclamation marks' do
        let(:result)  { described_class.rename_groups(pattern, 0)             }
        let(:pattern) { '(?!<sentence>my ((?<trait>\w+) (?<verb>\w+) (\w+)))' }

        it 'preserves exclamation marks' do
          expect(result).to eq('(?!<_0-sentence>my (?<_0-_0>(?<_0-trait>\w+) (?<_0-verb>\w+) (?<_0-_1>\w+)))')
        end
      end

      # TODO: ignore (?: ...)
      context 'some parenthetical groups are of the form (?: ...)' do
        let(:result)  { described_class.rename_groups(pattern, 0)               }
        let(:pattern) { '(?<sentence>:my ((?<trait>\w+) (?<verb>\w+) (?:\w+)))' }

        it 'does not name groups of the form (?: ... )' do
          expect(result).to eq('(?<_0-sentence>my (?<_0-_0>(?<_0-trait>\w+) (?<_0-verb>\w+) (?:\w+)))')
        end
      end

      # TODO: ignore (? ...)
    end

    describe '.wrap_major_groups' do
      let(:result) { described_class.wrap_major_groups(patterns) }

      context do
        let(:patterns) { ['this', ' is', ' a pattern'] }

        it do
          expect(result).to eq(['(?<__0>this)', '(?<__1> is)', '(?<__2> a pattern)'].map { |s| Regexp.new(s) })
        end
      end

      context do
        let(:patterns) { [/(?:this) (is) (?<a>a)/i, /(?!<b>pattern)/m] }

        it do
          expect(result).to eq(['(?<__0>(?i-mx:(?:this) (is) (?<a>a)))', '(?<__1>(?m-ix:(?!<b>pattern)))']
            .map { |s| Regexp.new(s) })
        end
      end
    end

    # describe '.extract_results' do
    #   let(:result) { described_class.extract_results(matches) }
    #
    #   context 'single match group' do
    #     let(:matches) {
    #
    #     }
    #   end
    # end
  end
end