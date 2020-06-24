class Seminar < ApplicationRecord
  
  has_many    :seminar_teachers, dependent: :destroy
  has_many    :teachers, through: :seminar_teachers, :source => :user
  has_many    :seminar_students, dependent: :destroy
  has_many    :students, through: :seminar_students, :source => :user
  has_many    :objective_seminars, dependent: :destroy
  has_many    :objectives, through: :objective_seminars
  has_many    :consultancies, dependent: :destroy
  has_many    :teams, through: :consultancies
  belongs_to  :school
  belongs_to  :owner, :class_name => "User"
  
  validates :name, presence: true, length: { maximum: 40 }

  
  serialize :quiz_open_times
  serialize :quiz_open_days
  
  attribute :term, :integer, default: 1
  attribute :columns, :integer, default: 3
  attribute :quiz_open_times, :string, default: [0,1380]
  attribute :quiz_open_days, :string, default: [0,1,2,3,4,5,6]
  
  include ModelMethods

  
  def obj_studs_for_seminar
    ObjectiveStudent.where(:objective => objectives, :user => students)
  end
  
  def shouldShowConsultLink
    students.count > 1 and objectives.count > 0
  end
  
  def objs_above_zero_priority
    objective_seminars.where("priority > ?", 0).map(&:objective)
  end
  
  def ripostes_to_grade
    Riposte.where(:objective => objectives, :user => students, :graded => 0)
  end
  
  def set_grading_needed
    self.update(:grading_needed => (ripostes_to_grade.count > 0))
  end
  
end
