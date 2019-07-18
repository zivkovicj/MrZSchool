class AddCatchyNameToObjectives < ActiveRecord::Migration[5.0]
  def change
    add_column  :objectives, :catchy_name, :string
    add_column  :objectives, :objective_number, :integer
    add_column  :objectives, :grade_level, :integer
    add_reference :objectives, :topic, foreign_key: true
  end
end
