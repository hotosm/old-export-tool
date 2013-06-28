class CreateJobsUploads < ActiveRecord::Migration
  def change
    create_table :jobs_uploads, :id => false do |t|
      t.integer :job_id
      t.integer :upload_id
    end
  end
end
