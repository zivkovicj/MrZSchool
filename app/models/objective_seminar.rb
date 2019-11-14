class ObjectiveSeminar < ApplicationRecord
    belongs_to :seminar
    belongs_to :objective
    
    attribute :priority, :integer, default: 2
    attribute :pretest, :integer, default: 0
    
    before_create :createScores
    before_create :students_needed_initialize
    
    #def students_in_need
        #objective.objective_students.where(:user => seminar.students).select{|x| !x.passed}.count
    #end
    
    def add_preassigns
        objective.preassigns.each do |preassign|
            seminar.objective_seminars.find_or_create_by(:objective_id => preassign.id)
            seminar.students.each do |student|
                student.objective_students.find_or_create_by(:objective_id => preassign.id)
            end
        end
    end
    
    def new_needed_count
        ObjectiveStudent
            .where(:user => seminar.students, :objective => objective, :ready => true)
            .where("points_all_time < ? OR points_all_time IS NULL", 5)
            .count
    end
    
    def students_needed_initialize
        self.students_needed = new_needed_count
        return true
    end
    
    def students_needed_refresh
        self.update(:students_needed => new_needed_count)
    end
    
    private
        def createScores
            seminar.students.each do |student|
                ObjectiveStudent.find_or_create_by(:user => student, :objective_id => objective.id)
            end
        end
        
        
end
