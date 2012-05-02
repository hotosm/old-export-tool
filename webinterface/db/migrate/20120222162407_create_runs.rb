class CreateRuns < ActiveRecord::Migration
  def change
    create_table :runs do |t|
      t.string :state
      t.string :downloadlink
      t.string :comment
      t.references :job

      t.timestamps
    end
    add_index :runs, :job_id
  end
end
