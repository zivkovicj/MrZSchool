class AddDescriptionToWorksheet < ActiveRecord::Migration[5.0]
  def change
      add_column  :worksheets, :description, :text
  end
end
