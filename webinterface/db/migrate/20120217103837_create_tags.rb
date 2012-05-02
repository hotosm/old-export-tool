class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :key
      t.string :geometrytype
      t.boolean :default
      t.references :job

      t.timestamps
    end
    add_index :tags, :job_id
  end
end
