class AddShuffleToQuestion < ActiveRecord::Migration[5.0]
  def change
      add_column  :questions, :shuffle, :boolean
  end
end
