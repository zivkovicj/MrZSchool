class AddGradeTypeToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column  :questions, :grade_type, :string
    add_column  :ripostes, :graded, :integer
    add_column  :quizzes, :needs_grading, :boolean
    add_column  :seminars, :grading_needed, :boolean
  end
end
