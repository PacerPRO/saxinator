require 'spec_helper'
require './lib/saxinator/result_hash'

module Saxinator
  RSpec.describe ResultHash do
    describe '#initialize' do
      subject { ResultHash.new(base_value) }

      context 'base value is nil' do
        let(:base_value) { nil }

        it { expect(subject.inner_value).to eq({ values: [] }) }
      end

      context 'base value is an arbitrary value' do
        let(:base_value) { 1 }

        it { expect(subject.inner_value).to eq({ values: [1] }) }
      end

      context 'base value is an array' do
        let(:base_value) { [1, 'two'] }

        it { expect(subject.inner_value).to eq({ values: [1, 'two'] }) }
      end

      context 'base value is a hash' do
        context 'base value has no "values" key' do
          let(:base_value) { { a: 1, b: 'two', values: [] } }

          it { expect(subject.inner_value).to eq({ a: 1, b: 'two', values: [] }) }
        end

        context 'base value has a "values" key' do
          let(:base_value) { { a: 1, b: 'two', values: ['three', 4] } }

          it { expect(subject.inner_value).to eq({ a: 1, b: 'two', values: ['three', 4] }) }
        end
      end

      context 'base value is itself a ResultHash' do
        let(:base_value) { ResultHash.new({ a: 1, b: 'two', values: [] }) }

        it { expect(subject.inner_value).to eq(base_value.inner_value) }
      end
    end

    describe '#+' do
      let(:x_result) { ResultHash.from_inner_value(x) }
      let(:y_result) { ResultHash.from_inner_value(y) }

      subject { (x_result + y_result).inner_value }

      context 'values: no, assignments: no' do
        let(:x) { { values: [] } }
        let(:y) { { values: [] } }

        it { expect(subject).to eq({ values: [] }) }
      end

      context 'values: yes, assignments: no' do
        let(:x) { { values: [1, 'two']  } }
        let(:y) { { values: [3, 'four'] } }

        it { expect(subject).to eq({ values: [1, 'two', 3, 'four'] }) }
      end

      context 'values: no, assignments: yes' do
        let(:x) { { a: 1, b: 2, values: []           } }
        let(:y) { { a: 'one', c: 'three', values: [] } }

        it { expect(subject).to eq({ a: 'one', b: 2, c: 'three', values: [] }) }
      end

      context 'values: yes, assignments: yes' do
        let(:x) { { a: 1, b: 2, values: ['a', 2, 'c']         } }
        let(:y) { { a: 'one', c: 'three', values: [4, 'e', 5] } }

        it { expect(subject).to eq({ a: 'one', b: 2, c: 'three', values: ['a', 2, 'c', 4, 'e', 5] }) }
      end
    end
  end
end
