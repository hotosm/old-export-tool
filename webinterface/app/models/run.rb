#
#  state has distinct values
#
#  new:      run has been created but nothing done yet
#  running:  run is in work by backend
#  error:    run has finished with error
#  success:  run has finished successfully

class Run < ActiveRecord::Base
   attr_accessible :state, :job_id, :comment
   belongs_to :job
   has_many :downloads, :dependent => :destroy
   default_scope :order => 'runs.created_at DESC' # newest first

   validates :state, 
      :presence => true,
      :inclusion => { :in => ["new", "running", "error", "success"] }

   validates :job_id, :presence => true
   
end
