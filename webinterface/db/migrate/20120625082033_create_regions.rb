class CreateRegions < ActiveRecord::Migration
  def change
    create_table :regions do |t|
      t.string   :internal_name
      t.string   :name
      t.float    :left
      t.float    :bottom
      t.float    :right
      t.float    :top

      t.timestamps
    end
  end
end
