class Download < ActiveRecord::Base
  belongs_to :run

  validates :run_id, :presence => true
end
