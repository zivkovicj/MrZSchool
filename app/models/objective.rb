class Objective < ApplicationRecord
    has_many    :objective_students, dependent: :destroy
    has_many    :objective_seminars, dependent: :destroy
    has_many    :seminars, through: :objective_seminars
    has_many    :preconditions, class_name: "Precondition",
                                foreign_key: "mainassign_id",
                                dependent: :destroy
    has_many    :mainconditions, class_name: "Precondition",
                                foreign_key: "preassign_id",
                                dependent: :destroy
    has_many    :preassigns, through: :preconditions, as: :mainassign, source: :preassign
    has_many    :mainassigns, through: :mainconditions, as: :preassign, source: :mainassign
    has_many    :label_objectives, dependent: :destroy
    has_many    :labels, through: :label_objectives
    has_many    :objective_worksheets, dependent: :destroy
    has_many    :worksheets, through: :objective_worksheets
    has_many    :questions, through: :labels
    has_many    :teams, dependent: :destroy
    has_many    :quizzes, dependent: :destroy
    has_many    :ripostes, dependent: :destroy
    
    belongs_to  :user
    belongs_to  :topic
    delegate    :domain, :to => :topic, :allow_nil => false
    
    attribute   :extent, :string, default: "private"
    
    validates   :name, presence: true, length: { maximum: 40 }
    
    include ModelMethods
    
    def full_name
        name[0,30] 
    end
    
    def priority_in(seminar)
        objective_seminars.find_by(:seminar => seminar).priority
    end
    
    def topic_and_number
        "#{topic.name} #{objective_number}"
    end
end
