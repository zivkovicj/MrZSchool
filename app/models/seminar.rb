class Seminar < ApplicationRecord
  
  has_many    :seminar_teachers, dependent: :destroy
  has_many    :teachers, through: :seminar_teachers, :source => :user
  has_many    :seminar_students, dependent: :destroy
  has_many    :students, through: :seminar_students, :source => :user
  has_many    :objective_seminars, dependent: :destroy
  has_many    :objectives, through: :objective_seminars
  has_many    :consultancies, dependent: :destroy
  has_many    :teams, through: :consultancies
  has_many    :goal_students, dependent: :destroy
  belongs_to  :school
  belongs_to  :owner, :class_name => "User"
  
  validates :name, presence: true, length: { maximum: 40 }
  validates :consultantThreshold, presence: true, numericality: { only_integer: true }

  serialize :checkpoint_due_dates
  
  def self.due_date_array
    [
      [0],
      [0, "06/05/2019","06/05/2019","06/05/2019","06/05/2019"],
      [0, "06/05/2019","06/05/2019","06/05/2019","06/05/2019"],
      [0, "06/05/2019","06/05/2019","06/05/2019","06/05/2019"],
      [0, "06/05/2019","06/05/2019","06/05/2019","06/05/2019"]
    ]
  end
     
  attribute :checkpoint_due_dates, :text, default: self.due_date_array
  attribute :consultantThreshold, :integer, default: 7
  attribute :term, :integer, default: 1
  attribute :which_checkpoint, :integer, default: 0
  attribute :default_buck_increment, :integer, default: 5
  
  include ModelMethods
  
  def commodities_for_seminar
    Commodity.where(:user => self.teachers)
  end
  
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
  
  def set_random_goals
    self.students.each do |stud|
      stud.goal_students.each do |gs|
        if rand(2) == 1
          gs.update(:goal => Goal.all[rand(Goal.count)])
        end
      end
    end
  end
end
