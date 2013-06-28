class RemoveBboxFromRegions < ActiveRecord::Migration
   def up
      remove_column :regions, :left
      remove_column :regions, :bottom
      remove_column :regions, :right
      remove_column :regions, :top
      
      add_column :regions, :polygon, :polygon, :srid => 4326
   end

  def down
      add_column :regions, :left, :float
      add_column :regions, :bottom, :float
      add_column :regions, :right, :float
      add_column :regions, :top, :float

      remove_column :regions, :polygon
  end
end
