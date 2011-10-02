module DrinkStats
  module Helpers
    def pretty_date(date, hours=true)
      if !date.is_a?(Fixnum)
        date.strftime("%B %d#{", %Y" if date.year != Date.today.year} #{"%I:%M%p" if hours}")
      else
        "Hour #{date}"
      end
    end

    def debug_mysql(result)
      result.to_a
    end

    def generate_graph_items(arr, key, options={})
      options[:integer] ||= false
      options[:link]    ||= false
      options[:count]   ||= false

      arr.map do |d|
        el = if options[:count]
          "#{d[options[:count]]} - #{d[key]}"
        else
          d[key]
        end

        el = el.to_i if options[:integer]
        el = "#{"/" if options[:link] != ""}#{options[:link]}/#{el}" if options[:link]
        el
      end
    end
  end
end
