class AddUserToJobs < ActiveRecord::Migration
  def change
    add_column :jobs,    :user_id, :integer
    add_column :runs,    :user_id, :integer
    add_column :uploads, :user_id, :integer
  end
end
