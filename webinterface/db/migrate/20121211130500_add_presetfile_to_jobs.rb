class AddPresetfileToJobs < ActiveRecord::Migration
   def change
      add_column :jobs, :presetfile, :string
      execute("update jobs set presetfile = 'old'")
  end
end
