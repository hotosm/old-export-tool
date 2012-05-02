class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :name
      t.float :latmin
      t.float :latmax
      t.float :lonmin
      t.float :lonmax

      t.timestamps
    end
  end
end
