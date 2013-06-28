class AddVisibleToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :visible, :boolean, :default => true
    execute("update jobs set visible = true")
  end
end
