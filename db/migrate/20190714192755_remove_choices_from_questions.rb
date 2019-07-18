class RemoveChoicesFromQuestions < ActiveRecord::Migration[5.0]
  def change
    remove_column    :questions, :choice_0
    remove_column    :questions, :choice_1
    remove_column    :questions, :choice_2
    remove_column    :questions, :choice_3
    remove_column    :questions, :choice_4
    remove_column    :questions, :choice_5
  end
end
