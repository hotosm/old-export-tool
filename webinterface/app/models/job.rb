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
   attr_accessible :name, :description, :latmin, :latmax, :lonmin, :lonmax, :region_id, :visible, :user_id
   has_many :runs, :dependent => :destroy
   has_many :tags, :dependent => :destroy
   belongs_to :region
   belongs_to :user
   validate :check_region

   has_and_belongs_to_many :uploads

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

   validates :region_id, :presence => true
   
   validates :user_id, :presence => true


   # maximum of (latmax-latmin) * (lonmax-lonmin)
   BBOX_MAX = 100

   # pagination count per page
   PPAGE = 200
   
   # jobs (owner and visible)
   def self.jobs_owner_visible ppage, uid
      jobs = Job.includes(:region, :user).where("user_id = ? and visible = ?", uid, true).paginate(:page => ppage, :per_page => Job::PPAGE)
   end

   # jobs (owner and not visible)
   def self.jobs_owner_notvisible ppage, uid
      jobs = Job.includes(:region, :user).where("user_id = ?", uid).paginate(:page => ppage, :per_page => Job::PPAGE)
   end

   # jobs (not owner and visible)   
   def self.jobs_notowner_visible ppage
      jobs = Job.includes(:region, :user).where("visible = ?", true).paginate(:page => ppage, :per_page => Job::PPAGE)
   end

   # all jobs (includes not owner and not visible jobs)
   def self.jobs_notowner_notvisible ppage
      jobs = Job.includes(:region, :user).paginate(:page => ppage, :per_page => Job::PPAGE)
   end

private
   def check_region

      if (!self.lonmin.is_a?(Numeric))
         errors.add(:lonmin, I18n.t('jobs.errors.no_valid_region'))
         return true
      elsif (!self.lonmax.is_a?(Numeric))
         errors.add(:lonmax, I18n.t('jobs.errors.no_valid_region'))
         return true
      elsif (!self.latmin.is_a?(Numeric))
         errors.add(:latmin, I18n.t('jobs.errors.no_valid_region'))
         return true
      elsif (!self.latmax.is_a?(Numeric))
         errors.add(:latmax, I18n.t('jobs.errors.no_valid_region'))
         return true
      end

      check_bbox_max
      check_area_in_region

   end


   def check_area_in_region

      select = "select * from regions 
         where polygon && st_setsrid(st_makebox2d(st_point(#{self.lonmin}, #{self.latmin}), st_point(#{self.lonmax}, #{self.latmax})), 4326) 
         order by st_area(st_intersection(polygon, st_setsrid(st_makebox2d(st_point(#{self.lonmin}, #{self.latmin}), st_point(#{self.lonmax}, #{self.latmax})),4326))) desc 
         limit 1;"

      region = ActiveRecord::Base.connection.select_one(select)

      if (region.is_a? Hash)
         self.region_id = region['id']
      else
      	 errors.add(:lonmin, I18n.t('jobs.errors.no_valid_region'))
         
         if Region.all.count==0
            #should only happen during a fresh install
            errors.add(:lonmin, I18n.t('jobs.errors.no_regions_defined'))
         end
      end
   end


   def check_bbox_max
      x = (self.latmax - self.latmin)
      y = (self.lonmax - self.lonmin)
      xx = x*y

      if ( xx > Job::BBOX_MAX) then
         errors.add(:lonmin, I18n.t('jobs.errors.area_too_large'))
      end

      if (self.lonmin < -180 or self.lonmin > 180) then
         errors.add(:lonmin, I18n.t('jobs.errors.out_of_range'))
      end
      if (self.lonmax < -180 or self.lonmax > 180) then
         errors.add(:lonmax, I18n.t('jobs.errors.out_of_range'))
      end
      if (self.latmin < -85 or self.latmin > 85) then
         errors.add(:latmin, I18n.t('jobs.errors.out_of_range'))
      end
      if (self.latmax < -85 or self.latmax > 85) then
         errors.add(:latmax, I18n.t('jobs.errors.out_of_range'))
      end
   end


   def create_run
      run = Run.new
      run.state   = 'new'
      run.job_id  = self.id
      run.user_id = self.user_id
      run.save!
   end
            
end
