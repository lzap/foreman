class AddTextToReports < ActiveRecord::Migration[5.2]
  def change
    add_column :reports, :body, :json, :default => {}
    remove_column :reports, :created_at, :datetime
    remove_column :reports, :updated_at, :datetime
    remove_column :reports, :metrics, :text
  end
end
