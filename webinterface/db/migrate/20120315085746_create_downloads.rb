class CreateDownloads < ActiveRecord::Migration
  def change
    create_table :downloads do |t|
      t.string :name
      t.string :size
      t.references :run

      t.timestamps
    end
    add_index :downloads, :run_id
  end
end
