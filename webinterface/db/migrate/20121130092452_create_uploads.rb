class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.string :name
      t.string :filename
      t.string :uptype
      t.boolean :visibility

      t.timestamps
    end
  end
end
