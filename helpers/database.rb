require 'mysql2'
require 'yaml'

module DrinkStats
  class Database

    @@exclude_list = ["'longusername'", "'sean'", "'openhouse'", "'yinyang'", "'thunderdome'"]

    def initialize
      # Read and symbolize the keys
      config = YAML.load_file('config/database.yml')
      config = config.inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }

      @connection ||=  Mysql2::Client.new(config)
    end

    def get_results_for_overall
      {
        :top_drinks          => top_drinks,
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
	query("SELECT COUNT(drop_log.item_id) AS item_count, item_name FROM drop_log JOIN drink_items ON drop_log.item_id = drink_items.item_id #{user_where_clause(username)} GROUP BY drop_log.item_id ORDER BY item_count DESC LIMIT 10")
  	#query("SELECT COUNT(slot) as slot_count, slot FROM drop_log #{user_where_clause(username)}  GROUP BY slot ORDER BY slot_count DESC LIMIT 10")
    end

    def top_ten_users(options={})
      
	if options[:all_time]
     		query("SELECT COUNT(*) as row_count, username FROM drop_log WHERE username NOT IN (#{@@exclude_list.join(',')}) GROUP BY username ORDER BY row_count DESC LIMIT 10")
	else
		where_clause = case
        		when options[:all_time]
                		""
                     	when options[:year]
                       		"WHERE YEAR(time) = '#{options[:year]}'"
                    	else
                       		"WHERE YEAR(time) = YEAR(CURDATE())"
                     	end
	      query("SELECT COUNT(*) as row_count, username FROM drop_log #{where_clause} AND username NOT IN (#{@@exclude_list.join(',')}) GROUP BY username ORDER BY row_count DESC LIMIT 10")
	end
    end

    def recent_drops(username=nil)
      query("SELECT * FROM drop_log  JOIN drink_items ON drop_log.item_id = drink_items.item_id JOIN machines ON drop_log.machine_id = machines.machine_id #{user_where_clause(username)} ORDER BY time DESC LIMIT 10")
    end

    def top_users_per_drink(item)
	query("SELECT COUNT( * ) AS row_count, username, slot FROM drop_log JOIN drink_items ON drop_log.item_id = drink_items.item_id WHERE drink_items.item_name = '#{escape(item)}' AND drop_log.username NOT IN (#{@@exclude_list.join(',')}) GROUP BY drop_log.username ORDER BY row_count DESC LIMIT 10")
    end

    def top_spenders
      query("SELECT username, SUM(ABS(amount)) as row_count FROM money_log WHERE reason='drop' AND username NOT IN (#{@@exclude_list.join(',')}) GROUP BY username ORDER BY row_count DESC LIMIT 10")
    end

    def spent_per_user(username)
      query("SELECT username, SUM(ABS(amount)) as sum_amount FROM money_log WHERE username ='#{escape(username)}' AND reason='drop' GROUP BY username")
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
