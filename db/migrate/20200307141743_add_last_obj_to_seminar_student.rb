class AddLastObjToSeminarStudent < ActiveRecord::Migration[5.0]
  def change
      add_column    :seminar_students, :last_obj, :integer
  end
end
