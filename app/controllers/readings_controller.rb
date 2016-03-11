class ReadingsController < ApplicationController
  def index
  end

  def search
    sql = "
      SELECT to_char(timestamp, 'HH24MI') as hour_minute, avg(wind_speed) * 1.94384 as avg_knots
      FROM wind_speeds
      WHERE EXTRACT(MONTH FROM timestamp) BETWEEN 5 AND 9
      GROUP BY hour_minute
      ORDER BY hour_minute
    ")
    
    render json: execute(sql)
  end

  private

  def sanitize_sql(sql, values = {})
    ActiveRecord::Base.send(:sanitize_sql, [sql, values], '')
  end

  def execute(sql, values = {})
    ActiveRecord::Base.connection.execute(sanitize_sql(sql, values)).entries
  end
end