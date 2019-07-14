class AddChoicesToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column  :questions, :choices, :text
  end
end
