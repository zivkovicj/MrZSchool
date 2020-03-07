class AddColumnsToSeminar < ActiveRecord::Migration[5.0]
  def change
      add_column :seminars, :columns, :integer
  end
end
