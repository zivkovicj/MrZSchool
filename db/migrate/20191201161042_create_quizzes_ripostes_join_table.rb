class CreateQuizzesRipostesJoinTable < ActiveRecord::Migration[5.0]
  def change
      create_join_table :quizzes, :ripostes
      add_reference :ripostes, :user, foreign_key: true
      add_reference :ripostes, :objective, foreign_key: true
      add_column    :labels, :grade_type, :string
  end
end
