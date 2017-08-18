class ChangeIntegerLimitInUsers < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :user_number, :integer, limit: 4
  end
end