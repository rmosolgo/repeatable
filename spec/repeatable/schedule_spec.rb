require 'spec_helper'

module Repeatable
  describe Schedule do
    let(:simple_range) { { range_in_year: { start_month: 10, end_month: 12 } } }
    let(:set_expression) do
      {
        union: [
          { day_in_month: { day: 23 } },
          { range_in_year: { start_month: 10, end_month: 12 } }
        ]
      }
    end
    let(:nested_set_expression) do
      {
        intersection: [
          {
            union: [
              { day_in_month: { day: 23 } },
              { day_in_month: { day: 24 } }
            ]
          },
          { range_in_year: { start_month: 10, end_month: 12 } }
        ]
      }
    end

    subject { described_class.new(args) }

    describe '#occurrences' do
      let(:args) { simple_range }

      context 'with convertible non-Date arguments' do
        expected_results = [
          Date.new(2015, 11, 30),
          Date.new(2015, 12, 1),
          Date.new(2015, 12, 2),
        ]
        argument_pairs = [
          ['2015-11-30', '2015-12-2'],
          [DateTime.new(2015, 11, 30), DateTime.new(2015, 12, 2)],
        ]

        argument_pairs.each do |args|
          it "can handle #{args.first.class} arguments" do
            expect(subject.occurrences(*args)).to eq(expected_results)
          end
        end
      end

      context 'with non convertible arguments' do
        it 'raises an exception' do
          expect { subject.occurrences('asdf', 'xyz') }.to raise_error(TypeError)
        end
      end

      context 'simple range expression' do
        it 'returns all matching dates within the range given' do
          expect(
            subject.occurrences(Date.new(2015, 11, 28), Date.new(2015, 12, 3))
          ).to eq(
            [
              Date.new(2015, 11, 28),
              Date.new(2015, 11, 29),
              Date.new(2015, 11, 30),
              Date.new(2015, 12, 1),
              Date.new(2015, 12, 2),
              Date.new(2015, 12, 3),
            ]
          )
        end
      end

      context 'set expression' do
        let(:args) { set_expression }

        it 'returns all matching dates within the range given' do
          expect(
            subject.occurrences(Date.new(2015, 8, 1), Date.new(2015, 10, 3))
          ).to eq(
            [
              Date.new(2015, 8, 23),
              Date.new(2015, 9, 23),
              Date.new(2015, 10, 1),
              Date.new(2015, 10, 2),
              Date.new(2015, 10, 3),
            ]
          )
        end
      end

      context 'nested set expression' do
        let(:args) { nested_set_expression }

        it 'returns all matching dates within the range given' do
          expect(
            subject.occurrences(Date.new(2015, 10, 30), Date.new(2016, 1, 30))
          ).to eq(
            [
              Date.new(2015, 11, 23),
              Date.new(2015, 11, 24),
              Date.new(2015, 12, 23),
              Date.new(2015, 12, 24),
            ]
          )
        end
      end
    end

    describe '#next_occurrence' do
      let(:args) { simple_range }

      context 'with convertible non-Date argument' do
        expected_result = Date.new(2015, 10, 1)
        arguments = ['2015-1-1', DateTime.new(2015, 1, 1)]

        arguments.each do |arg|
          it "can handle #{arg.class} argument" do
            expect(subject.next_occurrence(arg)).to eq(expected_result)
          end
        end
      end

      context 'with non convertible argument' do
        it 'raises an exception' do
          expect { subject.next_occurrence('asdf') }.to raise_error(TypeError)
        end
      end

      context 'simple range expression' do
        it 'returns the next occurrence matching the range' do
          expect(subject.next_occurrence(Date.new(2015, 1, 1))).to eq(Date.new(2015, 10, 1))
        end
      end

      context 'set expression' do
        let(:args) { set_expression }

        it 'returns the next occurrence that matches the full expression' do
          expect(subject.next_occurrence(Date.new(2015, 9, 2))).to eq(Date.new(2015, 9, 23))
        end
      end

      context 'nested set expression' do
        let(:args) { nested_set_expression }

        it 'returns the next occurrence that matches the full expression' do
          expect(subject.next_occurrence(Date.new(2015, 9, 2))).to eq(Date.new(2015, 10, 23))
        end
      end
    end

    describe '#occuring?' do
      let(:args) { simple_range }

      context 'with convertible non-Date argument' do
        arguments = ['2015-10-1', DateTime.new(2015, 10, 1)]

        arguments.each do |arg|
          it "can handle #{arg.class} argument" do
            expect(subject.occurring?(arg)).to eq(true)
          end
        end
      end

      context 'with non convertible argument' do
        it 'raises an exception' do
          expect { subject.occurring?('asdf') }.to raise_error(TypeError)
        end
      end

      context 'simple range expression' do
        it 'returns true for dates within the range' do
          expect(subject.occurring?(Date.new(2015, 10, 1))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 11, 15))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 12, 31))).to eq(true)
        end

        it 'returns false for dates outside of the range' do
          expect(subject.occurring?(Date.new(2015, 9, 30))).to eq(false)
          expect(subject.occurring?(Date.new(2015, 2, 23))).to eq(false)
        end
      end

      context 'set expression' do
        let(:args) { set_expression }

        it 'returns true for dates that match the full expression' do
          expect(subject.occurring?(Date.new(2015, 9, 23))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 10, 2))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 10, 23))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 11, 3))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 11, 23))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 12, 23))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 12, 24))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 1, 23))).to eq(true)
        end

        it 'returns true for dates that do not match the full expression' do
          expect(subject.occurring?(Date.new(2015, 9, 2))).to eq(false)
          expect(subject.occurring?(Date.new(2015, 1, 2))).to eq(false)
        end
      end

      context 'nested set expression' do
        let(:args) { nested_set_expression }

        it 'returns true for dates that match the full expression' do
          expect(subject.occurring?(Date.new(2015, 10, 23))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 11, 23))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 12, 23))).to eq(true)
          expect(subject.occurring?(Date.new(2015, 12, 24))).to eq(true)
        end

        it 'returns true for dates that do not match the full expression' do
          expect(subject.occurring?(Date.new(2015, 9, 23))).to eq(false)
          expect(subject.occurring?(Date.new(2015, 10, 2))).to eq(false)
          expect(subject.occurring?(Date.new(2015, 12, 25))).to eq(false)
          expect(subject.occurring?(Date.new(2015, 1, 23))).to eq(false)
        end
      end
    end

    describe '#initialize' do
      context 'invalid argument format' do
        context 'multiple keys in outer hash' do
          let(:args) do
            {
              day_in_month: { day: 23 },
              range_in_year: { start_month: 10, end_month: 12 }
            }
          end

          it 'raises an invalid expression error' do
            expect { subject }.to raise_error(RuntimeError).with_message(/Invalid expression/)
          end
        end

        context 'multiple keys in inner hash' do
          let(:args) do
            {
              union: [
                day_in_month: { day: 23 },
                range_in_year: { start_month: 10, end_month: 12 }
              ]
            }
          end

          it 'raises an invalid expression error' do
            expect { subject }.to raise_error(RuntimeError).with_message(/Invalid expression/)
          end
        end

        context 'key does not match existing class' do
          let(:args) { { asdf: { foo: 'bar' } } }

          it 'raises an unknown mapping error' do
            expect { subject }.to raise_error(RuntimeError).with_message(/Unknown mapping/)
          end
        end
      end
    end
  end
end