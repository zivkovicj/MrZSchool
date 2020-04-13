class AddQuizLockTimeToSeminar < ActiveRecord::Migration[5.0]
  def change
      add_column    :seminars, :quiz_open_times, :string
      add_column     :seminars, :quiz_open_days, :string
  end
end
