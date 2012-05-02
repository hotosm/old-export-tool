class AddUrlToDownloads < ActiveRecord::Migration
  def change
      add_column :downloads, :url, :text
  end
end
