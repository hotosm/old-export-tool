# == Schema Information
#
# Table name: jobs
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  latmin     :float
#  latmax     :float
#  lonmin     :float
#  lonmax     :float
#  created_at :datetime
#  updated_at :datetime
#

class Job < ActiveRecord::Base
   attr_accessible :name, :description, :latmin, :latmax, :lonmin, :lonmax
   has_many :runs, :dependent => :destroy
   has_many :tags, :dependent => :destroy
   after_create :create_run
   default_scope :order => 'jobs.created_at DESC'

   validates :name, 
      :presence => true,
      :length => {:maximum => 256}

   validates :latmin, 
      :presence => true, 
      :numericality => true

   validates :latmax, 
      :presence => true, 
      :numericality => true

   validates :lonmin, 
      :presence => true, 
      :numericality => true
   
   validates :lonmax, 
      :presence => true, 
      :numericality => true

private
   def create_run
      run = Run.new
      run.state = 'new'
      run.job_id = self.id
      run.save!
   end
            
end
