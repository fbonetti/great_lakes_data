class ReadingsController < ApplicationController
  def index
  end

  def search
    sql = "
      SELECT to_char(timestamp, 'YYYY-MM-DD') as date, avg(wind_speed) * 1.94384 as avg_knots
      FROM readings
      WHERE EXTRACT(MONTH FROM timestamp) BETWEEN 5 AND 9
      AND station_id = :station_id
      GROUP BY date
      ORDER BY date
    "

    results = select_rows(sql, station_id: params[:station_id]).map do |row|
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