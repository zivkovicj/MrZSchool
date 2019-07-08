class Riposte < ApplicationRecord
    belongs_to :quiz
    belongs_to :question
    
    serialize :stud_answer
end
