class SeminarStudent < ApplicationRecord
    belongs_to :user
    belongs_to :seminar
    
    after_create  :add_student_stuff

    validates :user_id, presence: true
    validates :seminar_id, presence: true
    
    serialize :stars_used_toward_grade
    
    attribute :pref_request, :integer, :default => 0
    attribute :present, :boolean, :default => true
    attribute :stars_used_toward_grade, :text, :default => [0,0,0,0]
    
    include ModelMethods
    
    # Not used right now
    #def set_last_consultant_day(date_of_consultancy)
        #new_date = date_of_consultancy - self.pref_request.to_i.days
        #self.update(:last_consultant_day => new_date)
    #end

    
    private
        def add_student_stuff
            new_student_goals
            new_student_scores
            new_student_pretest_keys
            self.update(:last_consultant_day => Date.today)
        end
        
        def new_student_goals
            4.times do |n|
                term_num = n + 1
                user.goal_students.create(:seminar_id => seminar.id, :term => term_num)
            end
        end
        
        def new_student_pretest_keys
            seminar.objective_seminars.where(:pretest => 1).each do |os|
                this_obj_stud = user.objective_students.find_by(:objective => os.objective)
                this_obj_stud.update(:pretest_keys => 2) unless this_obj_stud.passed_with_100
            end
        end
    
        def new_student_scores
            seminar.objectives.each_with_index do |obj, index|
                ObjectiveStudent.find_or_create_by(:user => user, :objective => obj)
            end
        end
        
        
end
