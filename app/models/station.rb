class Station < ActiveRecord::Base
  has_many :readings
end
