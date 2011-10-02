require 'mysql2'
module DrinkStats
  class Database
    def initialize
      @connection ||=  Mysql2::Client.new(:host => "127.0.0.1", :username => "drink_read", :password => "drink_read", :port=>3307, :database=>"drink")
    end

    def get_results_for_overall
      {
        :top_drinks          =>top_drinks,
        :top_users_this_year => top_ten_users,
        :top_users_all_time  => top_ten_users(:all_time => true),
        :recent_drops        => recent_drops,
        :popular_days        => popular_days,
        :top_spenders        => top_spenders,
        :popular_hours       => popular_hours
      }
    end

    def get_results_for_user(username)
      recent = recent_drops(username)
      return nil if recent.to_a.empty?
      {
        :top_drinks    => top_drinks(username),
        :recent_drops  => recent,
        :popular_days  => popular_days(username),
        :spent         => spent_per_user(username),
        :popular_hours => popular_hours(username)
      }
    end

    def top_drinks(username=nil)
      query("SELECT COUNT(slot) as slot_count, slot FROM drop_log #{user_where_clause(username)}  GROUP BY slot ORDER BY slot_count DESC LIMIT 10")
    end

    def top_ten_users(options={})
      where_clause = case
                     when options[:all_time]
                       ""
                     when options[:year]
                       "WHERE YEAR(time) = '#{options[:year]}'"
                     else
                       "WHERE YEAR(time) = YEAR(CURDATE())"
                     end

      query("SELECT COUNT(*) as row_count, username FROM drop_log #{where_clause} GROUP BY username ORDER BY row_count DESC LIMIT 10")
    end

    def recent_drops(username=nil)
      query("SELECT * FROM drop_log #{user_where_clause(username)} ORDER BY time DESC LIMIT 10")
    end

    def top_users_per_drink(item)
      query("SELECT COUNT(*) as row_count, username, slot FROM drop_log WHERE slot='#{escape(item)}' GROUP BY username ORDER BY row_count DESC LIMIT 10")
    end

    def top_spenders
      exclude_list = ["'longusername'", "'sean'", "'openhouse'", "'yinyang'", "'thunderdome'"]
      query("SELECT username, SUM(ABS(amount)) as row_count FROM money_log WHERE direction='out' AND username NOT IN (#{exclude_list.join(',')}) GROUP BY username ORDER BY row_count DESC LIMIT 10")
    end

    def spent_per_user(username)
      query("SELECT username, SUM(ABS(amount)) as sum_amount FROM money_log WHERE username ='#{escape(username)}' AND direction='out' GROUP BY username")
    end

    def popular_days(username=nil)
      results = query("SELECT WEEKDAY(time) as time, COUNT(*) as row_count FROM drop_log #{user_where_clause(username)} GROUP BY WEEKDAY(time) ORDER BY row_count DESC LIMIT 10")

      days = [0]*7
      for item in results
        days[item["time"]] = item["row_count"]
      end
      days
    end

    def popular_hours(username=nil)
      results = query("SELECT COUNT(*) as row_count, HOUR(time) as time FROM drop_log #{user_where_clause(username)} GROUP BY HOUR(time) ORDER BY row_count DESC")

      hours = [0]*24
      for item in results
        hours[item["time"]] = item["row_count"]
      end
      hours
    end

    private 
    def escape(str)
      @connection.escape(str)
    end

    def query(sql)
      @connection.query(sql)
    end

    def user_where_clause(username)
      (username) ? "WHERE username = '#{escape(username)}'" : ""
    end

  end
end
