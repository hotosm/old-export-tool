class AddRegionToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :region_id, :integer

  end
end
