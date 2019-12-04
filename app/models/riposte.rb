class Riposte < ApplicationRecord
    has_and_belongs_to_many :quizzes
    belongs_to :question
    belongs_to :user
    belongs_to :objective
    
    serialize :stud_answer
end
