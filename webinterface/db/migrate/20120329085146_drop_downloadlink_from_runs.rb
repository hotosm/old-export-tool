class DropDownloadlinkFromRuns < ActiveRecord::Migration
  def change
    remove_column :runs, :downloadlink
  end
end
