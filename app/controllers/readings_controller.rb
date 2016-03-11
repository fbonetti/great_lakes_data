class ReadingsController < ApplicationController
  def index
  end

  def search
    sql = "
      SELECT to_char(timestamp, 'HH24MI') as hour_minute, avg(wind_speed) * 1.94384 as avg_knots
      FROM readings
      WHERE EXTRACT(MONTH FROM timestamp) BETWEEN 5 AND 9
      GROUP BY hour_minute
      ORDER BY hour_minute
    "

    results = select_rows(sql).map do |row|
      [row[0], row[1].to_f]
    end
    
    render json: results
  end

  private

  def sanitize_sql(sql, values = {})
    ActiveRecord::Base.send(:sanitize_sql, [sql, values], '')
  end

  def select_rows(sql, values = {})
    ActiveRecord::Base.connection.select_rows(sanitize_sql(sql, values)).entries
  end
end