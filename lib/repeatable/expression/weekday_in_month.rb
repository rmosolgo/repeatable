module Repeatable
  module Expression
    class WeekdayInMonth < Date
      def initialize(weekday:, count:)
        @weekday = weekday
        @count = count
      end

      def include?(date)
        day_matches?(date) && week_matches?(date)
      end

      private

      attr_reader :weekday, :count

      def day_matches?(date)
        date.wday == weekday
      end

      def week_matches?(date)
        week_in_month(date.day) == count
      end

      def week_in_month(day)
        ((day - 1) / 7) + 1
      end
    end
  end
end
