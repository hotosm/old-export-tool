class DeviseAddSuspendableUser < ActiveRecord::Migration
  def self.up
    add_column :users, :suspended_at,      :datetime,  :null => true, :default => nil
    add_column :users, :suspension_reason, :string,    :null => true, :default => nil
  end
  
  def self.down
    remove_column :users, :suspended_at
    remove_column :users, :suspension_reason
  end
end
